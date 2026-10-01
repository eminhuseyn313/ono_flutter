import 'package:supabase_flutter/supabase_flutter.dart';
import 'blueprint_gateway.dart';

/// Production implementation that stores blueprints in Supabase and
/// generates them via an Edge Function that calls the Claude API.
///
/// Actual `blueprints` table:
///   id (uuid PK), user_id (uuid FK users), archetype_id (uuid FK archetypes),
///   created_at (timestamptz), professional/style/body/intellect/social (jsonb),
///   assessment_id (uuid FK assessments), version (int default 1),
///   source (text 'static'|'ai'), is_active (bool default true),
///   lanes (jsonb default '[]'), milestones (jsonb default '[]'),
///   title (text), summary (text)
///
/// Actual `archetypes` table:
///   id (uuid PK), name (text), description (text), domains (text[]),
///   image_url (text)
///
/// Edge Function `generate-blueprint` — accepts { archetypeId, assessmentAnswers }
/// and returns the generated blueprint JSON.
class SupabaseBlueprintGateway implements BlueprintGateway {
  final SupabaseClient _client;

  SupabaseBlueprintGateway(this._client);

  @override
  Future<Blueprint> generateBlueprint({
    required String archetypeId,
    required Map<int, int> assessmentAnswers,
  }) async {
    try {
      // Call the Edge Function that wraps the Claude API
      final response = await _client.functions.invoke(
        'generate-blueprint',
        body: {
          'archetypeId': archetypeId,
          'assessmentAnswers':
              assessmentAnswers.map((k, v) => MapEntry(k.toString(), v)),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return _parseBlueprintFromEdgeFunction(data);
    } catch (e) {
      throw Exception('Failed to generate blueprint: $e');
    }
  }

  @override
  Future<Blueprint?> loadBlueprint(String userId) async {
    try {
      final data = await _client
          .from('blueprints')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (data == null) return null;
      return _parseBlueprintFromDb(data);
    } catch (e) {
      throw Exception('Failed to load blueprint: $e');
    }
  }

  @override
  Future<void> saveBlueprint(String userId, Blueprint blueprint) async {
    try {
      // Deactivate any existing blueprints for this user
      await _client
          .from('blueprints')
          .update({'is_active': false})
          .eq('user_id', userId);

      // Look up the archetype UUID from the name/slug
      final archetypeUuid = await _resolveArchetypeId(blueprint.archetypeId);

      // Insert the new active blueprint
      await _client.from('blueprints').insert({
        'user_id': userId,
        'archetype_id': archetypeUuid,
        'title': blueprint.title,
        'summary': blueprint.summary,
        'source': 'ai',
        'version': 1,
        'is_active': true,
        'lanes': blueprint.lanes
            .map((lane) => {
                  'id': lane.id,
                  'name': lane.name,
                  'description': lane.description,
                  'actions': lane.actions
                      .map((a) => {
                            'id': a.id,
                            'title': a.title,
                            'subtitle': a.subtitle,
                            'laneId': a.laneId,
                            'durationMinutes': a.durationMinutes,
                            'orderIndex': a.orderIndex,
                          })
                      .toList(),
                })
            .toList(),
      });
    } catch (e) {
      throw Exception('Failed to save blueprint: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Resolve an archetype slug (e.g. 'executive') to its UUID in the
  /// archetypes table. Returns null if not found — the column is nullable.
  Future<String?> _resolveArchetypeId(String archetypeSlug) async {
    try {
      final data = await _client
          .from('archetypes')
          .select('id')
          .ilike('name', '%$archetypeSlug%')
          .maybeSingle();

      return data?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Parse a blueprint from the Edge Function response.
  /// The Edge Function returns the Claude-generated JSON directly.
  Blueprint _parseBlueprintFromEdgeFunction(Map<String, dynamic> data) {
    final lanesRaw = data['lanes'] as List? ?? [];
    return Blueprint(
      archetypeId: data['archetypeId'] as String? ?? '',
      title: data['title'] as String? ?? 'Your Blueprint',
      summary: data['summary'] as String? ?? '',
      lanes: _parseLanes(lanesRaw),
      generatedAt: DateTime.tryParse(
              data['generated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Parse a blueprint from a database row.
  Blueprint _parseBlueprintFromDb(Map<String, dynamic> data) {
    final lanesRaw = data['lanes'] as List? ?? [];
    return Blueprint(
      // Store the archetype UUID as archetypeId — the domain model
      // uses it as an opaque string identifier.
      archetypeId: data['archetype_id']?.toString() ?? '',
      title: data['title'] as String? ?? 'Your Blueprint',
      summary: data['summary'] as String? ?? '',
      lanes: _parseLanes(lanesRaw),
      generatedAt: DateTime.tryParse(
              data['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  List<BlueprintLane> _parseLanes(List<dynamic> lanesRaw) {
    return lanesRaw.map((laneMap) {
      final l = laneMap as Map<String, dynamic>;
      final actionsRaw = l['actions'] as List? ?? [];
      return BlueprintLane(
        id: l['id'] as String,
        name: l['name'] as String,
        description: l['description'] as String? ?? '',
        actions: actionsRaw.map((aMap) {
          final a = aMap as Map<String, dynamic>;
          return BlueprintAction(
            id: a['id'] as String,
            title: a['title'] as String,
            subtitle: a['subtitle'] as String?,
            laneId: a['laneId'] as String? ?? l['id'] as String,
            durationMinutes: a['durationMinutes'] as int? ?? 15,
            orderIndex: a['orderIndex'] as int? ?? 0,
          );
        }).toList(),
      );
    }).toList();
  }
}

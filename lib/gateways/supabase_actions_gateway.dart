import 'package:supabase_flutter/supabase_flutter.dart';
import 'actions_gateway.dart';

/// Production implementation using the existing Supabase schema.
///
/// Existing `daily_actions` table:
///   id (uuid PK), user_id (uuid FK users), blueprint_id (uuid FK blueprints),
///   action_date (date), domain (text), action (text), completed (bool),
///   completed_at (timestamptz), lane (text), title (text),
///   description (text), subtitle (text), order_index (int), created_at
///
/// Existing `streaks` table:
///   user_id (uuid PK), current_streak (int), longest_streak (int),
///   last_active (date), last_completed_date (date), updated_at
class SupabaseActionsGateway implements ActionsGateway {
  final SupabaseClient _client;

  SupabaseActionsGateway(this._client);

  @override
  Future<List<DailyAction>> loadTodayActions(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final data = await _client
          .from('daily_actions')
          .select()
          .eq('user_id', userId)
          .eq('action_date', today)
          .order('order_index');

      return (data as List).map((row) {
        return DailyAction(
          id: row['id'] as String,
          title: row['title'] as String? ?? row['action'] as String? ?? '',
          subtitle: row['subtitle'] as String? ?? row['description'] as String?,
          lane: row['lane'] as String? ?? row['domain'] as String? ?? 'mind',
          completed: row['completed'] as bool? ?? false,
          orderIndex: row['order_index'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load today actions: $e');
    }
  }

  @override
  Future<void> toggleAction(
      String userId, String actionId, bool completed) async {
    try {
      await _client.from('daily_actions').update({
        'completed': completed,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      }).eq('id', actionId);

      // Streak + lane scores are updated automatically by DB triggers
    } catch (e) {
      throw Exception('Failed to toggle action: $e');
    }
  }

  @override
  Future<int> loadStreak(String userId) async {
    try {
      final data = await _client
          .from('streaks')
          .select('current_streak')
          .eq('user_id', userId)
          .maybeSingle();

      return data?['current_streak'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<DayRecord>> loadHistory(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = from.toIso8601String().substring(0, 10);
      final toStr = to.toIso8601String().substring(0, 10);

      final data = await _client
          .from('daily_actions')
          .select('action_date, completed')
          .eq('user_id', userId)
          .gte('action_date', fromStr)
          .lte('action_date', toStr);

      // Group by date
      final Map<String, List<bool>> byDate = {};
      for (final row in data as List) {
        final date = row['action_date'] as String;
        byDate.putIfAbsent(date, () => []);
        byDate[date]!.add(row['completed'] as bool? ?? false);
      }

      final records = <DayRecord>[];
      var current = from;
      while (!current.isAfter(to)) {
        final dateStr = current.toIso8601String().substring(0, 10);
        final dayActions = byDate[dateStr] ?? [];
        records.add(DayRecord(
          date: current,
          completedCount: dayActions.where((c) => c).length,
          totalCount: dayActions.length,
        ));
        current = current.add(const Duration(days: 1));
      }

      return records;
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }

}

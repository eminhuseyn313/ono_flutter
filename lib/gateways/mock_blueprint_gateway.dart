import 'blueprint_gateway.dart';

/// Offline mock that returns a static blueprint — no Claude API key needed.
/// Simulates a short delay to mimic network latency.
class MockBlueprintGateway implements BlueprintGateway {
  Blueprint? _saved;

  @override
  Future<Blueprint> generateBlueprint({
    required String archetypeId,
    required Map<int, int> assessmentAnswers,
  }) async {
    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 2));

    return Blueprint(
      archetypeId: archetypeId,
      title: _titleFor(archetypeId),
      summary: _summaryFor(archetypeId),
      lanes: _lanesFor(archetypeId),
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<Blueprint?> loadBlueprint(String userId) async {
    return _saved;
  }

  @override
  Future<void> saveBlueprint(String userId, Blueprint blueprint) async {
    _saved = blueprint;
  }

  // ── Static data for each archetype ──────────────────────────────────────

  String _titleFor(String id) {
    switch (id) {
      case 'executive':
        return 'The Executive Edge';
      case 'athlete':
        return 'Peak Performance Protocol';
      case 'creative':
        return 'The Creative Catalyst';
      case 'entrepreneur':
        return 'Builder\'s Blueprint';
      case 'gentleman':
        return 'The Modern Gentleman';
      default:
        return 'Your Personal Blueprint';
    }
  }

  String _summaryFor(String id) {
    switch (id) {
      case 'executive':
        return 'A focused plan to sharpen your leadership, decision-making, and presence.';
      case 'athlete':
        return 'Train your mind and body for peak performance on and off the field.';
      case 'creative':
        return 'Cultivate your creative energy while building discipline and resilience.';
      case 'entrepreneur':
        return 'Build the habits that turn ambition into execution and ideas into reality.';
      case 'gentleman':
        return 'Develop presence, social intelligence, and refined personal standards.';
      default:
        return 'A balanced growth plan across mind, body, social skills, and personal mastery.';
    }
  }

  List<BlueprintLane> _lanesFor(String archetypeId) {
    return [
      BlueprintLane(
        id: 'mind',
        name: 'Mind',
        description: 'Mental clarity, focus, and emotional intelligence',
        actions: [
          BlueprintAction(
            id: '${archetypeId}_mind_1',
            title: '10-minute morning meditation',
            subtitle: 'Start with guided breathing',
            laneId: 'mind',
            durationMinutes: 10,
            orderIndex: 0,
          ),
          BlueprintAction(
            id: '${archetypeId}_mind_2',
            title: 'Journal 3 intentions for the day',
            subtitle: 'Be specific and actionable',
            laneId: 'mind',
            durationMinutes: 5,
            orderIndex: 1,
          ),
        ],
      ),
      BlueprintLane(
        id: 'body',
        name: 'Body',
        description: 'Physical strength, energy, and discipline',
        actions: [
          BlueprintAction(
            id: '${archetypeId}_body_1',
            title: '30-minute workout',
            subtitle: 'Strength or cardio — alternate days',
            laneId: 'body',
            durationMinutes: 30,
            orderIndex: 0,
          ),
          BlueprintAction(
            id: '${archetypeId}_body_2',
            title: 'Cold shower (2 min)',
            subtitle: 'Build mental toughness',
            laneId: 'body',
            durationMinutes: 2,
            orderIndex: 1,
          ),
        ],
      ),
      BlueprintLane(
        id: 'social',
        name: 'Social',
        description: 'Communication, relationships, and leadership',
        actions: [
          BlueprintAction(
            id: '${archetypeId}_social_1',
            title: 'Reach out to one person',
            subtitle: 'Text, call, or meet — be intentional',
            laneId: 'social',
            durationMinutes: 10,
            orderIndex: 0,
          ),
        ],
      ),
      BlueprintLane(
        id: 'skill',
        name: 'Skill',
        description: 'Personal mastery and continuous learning',
        actions: [
          BlueprintAction(
            id: '${archetypeId}_skill_1',
            title: 'Read 15 pages',
            subtitle: 'Non-fiction or skill-building',
            laneId: 'skill',
            durationMinutes: 20,
            orderIndex: 0,
          ),
          BlueprintAction(
            id: '${archetypeId}_skill_2',
            title: 'Practice one skill for 15 min',
            subtitle: 'Coding, public speaking, writing, etc.',
            laneId: 'skill',
            durationMinutes: 15,
            orderIndex: 1,
          ),
        ],
      ),
    ];
  }
}

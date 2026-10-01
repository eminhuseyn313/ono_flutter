/// Abstraction over AI blueprint generation (Claude API in production).
abstract class BlueprintGateway {
  /// Generate a personalised blueprint based on archetype + assessment answers.
  /// Returns a structured Blueprint with daily actions across lanes.
  Future<Blueprint> generateBlueprint({
    required String archetypeId,
    required Map<int, int> assessmentAnswers,
  });

  /// Load a previously saved blueprint.
  Future<Blueprint?> loadBlueprint(String userId);

  /// Save / cache a generated blueprint.
  Future<void> saveBlueprint(String userId, Blueprint blueprint);
}

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

/// The AI-generated personal transformation plan.
class Blueprint {
  final String archetypeId;
  final String title;
  final String summary;
  final List<BlueprintLane> lanes;
  final DateTime generatedAt;

  const Blueprint({
    required this.archetypeId,
    required this.title,
    required this.summary,
    required this.lanes,
    required this.generatedAt,
  });

  /// Flattened list of all daily actions across every lane.
  List<BlueprintAction> get allActions =>
      lanes.expand((lane) => lane.actions).toList();

  /// Number of actions per day.
  int get dailyActionCount => allActions.length;
}

/// One growth lane in the blueprint (e.g. Mind, Body, Social, Skill).
class BlueprintLane {
  final String id; // e.g. 'mind', 'body', 'social', 'skill'
  final String name; // e.g. 'Mind', 'Body'
  final String description;
  final List<BlueprintAction> actions;

  const BlueprintLane({
    required this.id,
    required this.name,
    required this.description,
    required this.actions,
  });
}

/// A single recommended daily action within a lane.
class BlueprintAction {
  final String id;
  final String title;
  final String? subtitle;
  final String laneId;
  final int durationMinutes;
  final int orderIndex;

  const BlueprintAction({
    required this.id,
    required this.title,
    this.subtitle,
    required this.laneId,
    this.durationMinutes = 15,
    this.orderIndex = 0,
  });
}

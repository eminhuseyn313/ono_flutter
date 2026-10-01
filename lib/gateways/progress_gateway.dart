/// Abstraction over progress/analytics persistence (Supabase in production).
abstract class ProgressGateway {
  /// Load lane scores (0.0–1.0) for each growth lane.
  Future<Map<String, double>> loadLaneScores(String userId);

  /// Load weekly snapshots for chart display.
  Future<List<WeeklySnapshot>> loadWeeklySnapshots(
    String userId, {
    required int weeks,
  });

  /// Save updated lane scores after daily recalculation.
  Future<void> saveLaneScores(String userId, Map<String, double> scores);
}

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

/// A snapshot of the user's progress for one week.
class WeeklySnapshot {
  final DateTime weekStart;
  final Map<String, double> laneScores;
  final double overallScore;
  final int actionsCompleted;
  final int actionsTotal;

  const WeeklySnapshot({
    required this.weekStart,
    required this.laneScores,
    required this.overallScore,
    required this.actionsCompleted,
    required this.actionsTotal,
  });

  double get completionRate =>
      actionsTotal == 0 ? 0.0 : actionsCompleted / actionsTotal;
}

/// Overall growth summary shown on the Progress tab.
class GrowthSummary {
  final Map<String, double> laneScores;
  final double overallScore;
  final int currentStreak;
  final int totalDaysActive;

  const GrowthSummary({
    required this.laneScores,
    required this.overallScore,
    required this.currentStreak,
    required this.totalDaysActive,
  });
}

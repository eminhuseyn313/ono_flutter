import 'progress_gateway.dart';

/// Offline mock for development — returns sample progress data.
class MockProgressGateway implements ProgressGateway {
  Map<String, double> _scores = {
    'mind': 0.45,
    'body': 0.30,
    'social': 0.20,
    'skill': 0.35,
  };

  @override
  Future<Map<String, double>> loadLaneScores(String userId) async {
    return Map.of(_scores);
  }

  @override
  Future<List<WeeklySnapshot>> loadWeeklySnapshots(
    String userId, {
    required int weeks,
  }) async {
    // Generate sample weekly data showing gradual improvement
    return List.generate(weeks, (i) {
      final weekStart = DateTime.now().subtract(Duration(days: (weeks - i) * 7));
      final factor = 0.3 + (i / weeks) * 0.4; // 0.3 → 0.7 over time
      return WeeklySnapshot(
        weekStart: weekStart,
        laneScores: {
          'mind': (factor + 0.1).clamp(0.0, 1.0),
          'body': (factor - 0.05).clamp(0.0, 1.0),
          'social': (factor - 0.1).clamp(0.0, 1.0),
          'skill': factor.clamp(0.0, 1.0),
        },
        overallScore: factor,
        actionsCompleted: (factor * 28).round(),
        actionsTotal: 28,
      );
    });
  }

  @override
  Future<void> saveLaneScores(
      String userId, Map<String, double> scores) async {
    _scores = Map.of(scores);
  }
}

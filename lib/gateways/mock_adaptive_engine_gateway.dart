import '../models/adaptive_engine.dart';
import 'adaptive_engine_gateway.dart';

class MockAdaptiveEngineGateway implements AdaptiveEngineGateway {
  // Simulated persisted state
  final Map<String, DifficultyLevel> _laneLevels = {
    'mind': DifficultyLevel.intermediate,
    'body': DifficultyLevel.beginner,
    'social': DifficultyLevel.intermediate,
    'skill': DifficultyLevel.advanced,
  };

  bool _autoAdjust = true;

  final List<DifficultyAdjustment> _appliedHistory = [
    DifficultyAdjustment(
      lane: 'skill',
      currentLevel: DifficultyLevel.intermediate,
      recommendedLevel: DifficultyLevel.advanced,
      reason: 'Completion rate 92% over 14 days with high self-assessment.',
      recommendedAt: DateTime.now().subtract(const Duration(days: 5)),
      isApplied: true,
    ),
    DifficultyAdjustment(
      lane: 'mind',
      currentLevel: DifficultyLevel.beginner,
      recommendedLevel: DifficultyLevel.intermediate,
      reason: 'Consistent 7-day streak and 80%+ completion.',
      recommendedAt: DateTime.now().subtract(const Duration(days: 12)),
      isApplied: true,
    ),
  ];

  @override
  Future<AdaptiveState> loadState(String arcId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final performance = <String, LanePerformance>{
      'mind': const LanePerformance(
        lane: 'mind',
        completionRate: 0.78,
        streakDays: 11,
        averageScore: 0.72,
        totalActions: 45,
        completedActions: 35,
      ),
      'body': const LanePerformance(
        lane: 'body',
        completionRate: 0.35,
        streakDays: 2,
        averageScore: 0.40,
        totalActions: 20,
        completedActions: 7,
      ),
      'social': const LanePerformance(
        lane: 'social',
        completionRate: 0.88,
        streakDays: 9,
        averageScore: 0.82,
        totalActions: 32,
        completedActions: 28,
      ),
      'skill': const LanePerformance(
        lane: 'skill',
        completionRate: 0.91,
        streakDays: 14,
        averageScore: 0.85,
        totalActions: 55,
        completedActions: 50,
      ),
    };

    // Generate pending adjustments based on performance
    final pending = <DifficultyAdjustment>[];

    // Social is excelling → recommend level up
    if (performance['social']!.isExcelling &&
        _laneLevels['social'] != DifficultyLevel.elite) {
      pending.add(DifficultyAdjustment(
        lane: 'social',
        currentLevel: _laneLevels['social']!,
        recommendedLevel: DifficultyLevel.values[
            (_laneLevels['social']!.index + 1).clamp(0, 3)],
        reason:
            '88% completion rate with 82% self-assessment over 9-day streak.',
        recommendedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ));
    }

    // Skill is excelling → recommend level up
    if (performance['skill']!.isExcelling &&
        _laneLevels['skill'] != DifficultyLevel.elite) {
      pending.add(DifficultyAdjustment(
        lane: 'skill',
        currentLevel: _laneLevels['skill']!,
        recommendedLevel: DifficultyLevel.values[
            (_laneLevels['skill']!.index + 1).clamp(0, 3)],
        reason:
            '91% completion with 85% scores — consistently exceeding targets.',
        recommendedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ));
    }

    // Body is struggling → recommend ease
    if (performance['body']!.isStruggling &&
        _laneLevels['body'] != DifficultyLevel.beginner) {
      pending.add(DifficultyAdjustment(
        lane: 'body',
        currentLevel: _laneLevels['body']!,
        recommendedLevel: DifficultyLevel.values[
            (_laneLevels['body']!.index - 1).clamp(0, 3)],
        reason: 'Only 35% completion — consider reducing intensity.',
        recommendedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ));
    }

    return AdaptiveState(
      arcId: arcId,
      laneLevels: Map.from(_laneLevels),
      lanePerformance: performance,
      pendingAdjustments: pending,
      appliedHistory: List.from(_appliedHistory),
      autoAdjustEnabled: _autoAdjust,
    );
  }

  @override
  Future<void> applyAdjustment(
      String arcId, DifficultyAdjustment adjustment) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _laneLevels[adjustment.lane] = adjustment.recommendedLevel;
    _appliedHistory.insert(0, adjustment.copyWith(isApplied: true));
  }

  @override
  Future<void> setAutoAdjust(String arcId, bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _autoAdjust = enabled;
  }

  @override
  Future<void> setLaneLevel(
      String arcId, String lane, DifficultyLevel level) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _laneLevels[lane] = level;
  }
}

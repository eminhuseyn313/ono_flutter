/// Adaptive Engine — adjusts journey difficulty based on user performance,
/// self-assessment scores, and behavioral patterns.

/// The current difficulty level for a journey.
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  elite,
}

extension DifficultyLevelExt on DifficultyLevel {
  String get label => switch (this) {
        DifficultyLevel.beginner => 'Beginner',
        DifficultyLevel.intermediate => 'Intermediate',
        DifficultyLevel.advanced => 'Advanced',
        DifficultyLevel.elite => 'Elite',
      };

  String get emoji => switch (this) {
        DifficultyLevel.beginner => '🌱',
        DifficultyLevel.intermediate => '🌿',
        DifficultyLevel.advanced => '🔥',
        DifficultyLevel.elite => '⚡',
      };

  /// Multiplier for action intensity (e.g. reps, duration, pages).
  double get intensityMultiplier => switch (this) {
        DifficultyLevel.beginner => 0.5,
        DifficultyLevel.intermediate => 1.0,
        DifficultyLevel.advanced => 1.5,
        DifficultyLevel.elite => 2.0,
      };

  /// Index for comparison.
  int get index => DifficultyLevel.values.indexOf(this);
}

/// Performance metrics for a single lane over a time window.
class LanePerformance {
  final String lane;
  final double completionRate; // 0–1
  final int streakDays;
  final double averageScore; // 0–1 from self-assessments
  final int totalActions;
  final int completedActions;

  const LanePerformance({
    required this.lane,
    required this.completionRate,
    required this.streakDays,
    required this.averageScore,
    required this.totalActions,
    required this.completedActions,
  });

  /// Whether the user is "crushing" this lane (ready to level up).
  bool get isExcelling => completionRate > 0.85 && averageScore > 0.75;

  /// Whether the user is struggling (should ease off).
  bool get isStruggling => completionRate < 0.4 || averageScore < 0.35;

  LanePerformance copyWith({
    String? lane,
    double? completionRate,
    int? streakDays,
    double? averageScore,
    int? totalActions,
    int? completedActions,
  }) =>
      LanePerformance(
        lane: lane ?? this.lane,
        completionRate: completionRate ?? this.completionRate,
        streakDays: streakDays ?? this.streakDays,
        averageScore: averageScore ?? this.averageScore,
        totalActions: totalActions ?? this.totalActions,
        completedActions: completedActions ?? this.completedActions,
      );

  Map<String, dynamic> toJson() => {
        'lane': lane,
        'completionRate': completionRate,
        'streakDays': streakDays,
        'averageScore': averageScore,
        'totalActions': totalActions,
        'completedActions': completedActions,
      };

  factory LanePerformance.fromJson(Map<String, dynamic> json) =>
      LanePerformance(
        lane: json['lane'] as String,
        completionRate: (json['completionRate'] as num).toDouble(),
        streakDays: json['streakDays'] as int,
        averageScore: (json['averageScore'] as num).toDouble(),
        totalActions: json['totalActions'] as int,
        completedActions: json['completedActions'] as int,
      );
}

/// A recommended difficulty adjustment for a lane.
class DifficultyAdjustment {
  final String lane;
  final DifficultyLevel currentLevel;
  final DifficultyLevel recommendedLevel;
  final String reason;
  final DateTime recommendedAt;
  final bool isApplied;

  const DifficultyAdjustment({
    required this.lane,
    required this.currentLevel,
    required this.recommendedLevel,
    required this.reason,
    required this.recommendedAt,
    this.isApplied = false,
  });

  bool get isIncrease =>
      recommendedLevel.index > currentLevel.index;

  bool get isDecrease =>
      recommendedLevel.index < currentLevel.index;

  bool get isNoChange => recommendedLevel == currentLevel;

  DifficultyAdjustment copyWith({
    String? lane,
    DifficultyLevel? currentLevel,
    DifficultyLevel? recommendedLevel,
    String? reason,
    DateTime? recommendedAt,
    bool? isApplied,
  }) =>
      DifficultyAdjustment(
        lane: lane ?? this.lane,
        currentLevel: currentLevel ?? this.currentLevel,
        recommendedLevel: recommendedLevel ?? this.recommendedLevel,
        reason: reason ?? this.reason,
        recommendedAt: recommendedAt ?? this.recommendedAt,
        isApplied: isApplied ?? this.isApplied,
      );

  Map<String, dynamic> toJson() => {
        'lane': lane,
        'currentLevel': currentLevel.name,
        'recommendedLevel': recommendedLevel.name,
        'reason': reason,
        'recommendedAt': recommendedAt.toIso8601String(),
        'isApplied': isApplied,
      };

  factory DifficultyAdjustment.fromJson(Map<String, dynamic> json) =>
      DifficultyAdjustment(
        lane: json['lane'] as String,
        currentLevel: DifficultyLevel.values.byName(
            json['currentLevel'] as String),
        recommendedLevel: DifficultyLevel.values.byName(
            json['recommendedLevel'] as String),
        reason: json['reason'] as String,
        recommendedAt: DateTime.parse(json['recommendedAt'] as String),
        isApplied: json['isApplied'] as bool? ?? false,
      );
}

/// Full adaptive state for a user's active journey.
class AdaptiveState {
  final String arcId;
  final Map<String, DifficultyLevel> laneLevels; // lane → current level
  final Map<String, LanePerformance> lanePerformance;
  final List<DifficultyAdjustment> pendingAdjustments;
  final List<DifficultyAdjustment> appliedHistory;
  final bool autoAdjustEnabled;

  const AdaptiveState({
    required this.arcId,
    required this.laneLevels,
    required this.lanePerformance,
    required this.pendingAdjustments,
    required this.appliedHistory,
    required this.autoAdjustEnabled,
  });

  /// Overall difficulty across all lanes.
  DifficultyLevel get overallLevel {
    if (laneLevels.isEmpty) return DifficultyLevel.beginner;
    final avg = laneLevels.values
            .map((l) => l.index)
            .reduce((a, b) => a + b) /
        laneLevels.length;
    return DifficultyLevel.values[avg.round().clamp(0, 3)];
  }

  /// Number of lanes that need attention (struggling).
  int get lanesNeedingHelp =>
      lanePerformance.values.where((p) => p.isStruggling).length;

  /// Number of lanes ready to level up.
  int get lanesReadyToAdvance =>
      lanePerformance.values.where((p) => p.isExcelling).length;

  AdaptiveState copyWith({
    String? arcId,
    Map<String, DifficultyLevel>? laneLevels,
    Map<String, LanePerformance>? lanePerformance,
    List<DifficultyAdjustment>? pendingAdjustments,
    List<DifficultyAdjustment>? appliedHistory,
    bool? autoAdjustEnabled,
  }) =>
      AdaptiveState(
        arcId: arcId ?? this.arcId,
        laneLevels: laneLevels ?? this.laneLevels,
        lanePerformance: lanePerformance ?? this.lanePerformance,
        pendingAdjustments: pendingAdjustments ?? this.pendingAdjustments,
        appliedHistory: appliedHistory ?? this.appliedHistory,
        autoAdjustEnabled: autoAdjustEnabled ?? this.autoAdjustEnabled,
      );

  Map<String, dynamic> toJson() => {
        'arcId': arcId,
        'laneLevels':
            laneLevels.map((k, v) => MapEntry(k, v.name)),
        'lanePerformance':
            lanePerformance.map((k, v) => MapEntry(k, v.toJson())),
        'pendingAdjustments':
            pendingAdjustments.map((a) => a.toJson()).toList(),
        'appliedHistory': appliedHistory.map((a) => a.toJson()).toList(),
        'autoAdjustEnabled': autoAdjustEnabled,
      };

  factory AdaptiveState.fromJson(Map<String, dynamic> json) => AdaptiveState(
        arcId: json['arcId'] as String,
        laneLevels: (json['laneLevels'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, DifficultyLevel.values.byName(v as String)),
        ),
        lanePerformance:
            (json['lanePerformance'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
              k, LanePerformance.fromJson(v as Map<String, dynamic>)),
        ),
        pendingAdjustments: (json['pendingAdjustments'] as List)
            .map((e) =>
                DifficultyAdjustment.fromJson(e as Map<String, dynamic>))
            .toList(),
        appliedHistory: (json['appliedHistory'] as List)
            .map((e) =>
                DifficultyAdjustment.fromJson(e as Map<String, dynamic>))
            .toList(),
        autoAdjustEnabled: json['autoAdjustEnabled'] as bool,
      );
}

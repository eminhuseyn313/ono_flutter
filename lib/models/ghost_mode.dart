/// Data models for the Ghost Mode feature.
///
/// Ghost Mode lets users compete against their past self by comparing
/// the current week's progress with a "ghost" snapshot from the previous week.

class GhostSnapshot {
  final DateTime weekStart;
  final Map<String, double> laneScores;
  final int actionsCompleted;
  final int actionsTotal;
  final double overallScore;

  const GhostSnapshot({
    required this.weekStart,
    required this.laneScores,
    required this.actionsCompleted,
    required this.actionsTotal,
    required this.overallScore,
  });

  GhostSnapshot copyWith({
    DateTime? weekStart,
    Map<String, double>? laneScores,
    int? actionsCompleted,
    int? actionsTotal,
    double? overallScore,
  }) {
    return GhostSnapshot(
      weekStart: weekStart ?? this.weekStart,
      laneScores: laneScores ?? this.laneScores,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      actionsTotal: actionsTotal ?? this.actionsTotal,
      overallScore: overallScore ?? this.overallScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'laneScores': laneScores,
      'actionsCompleted': actionsCompleted,
      'actionsTotal': actionsTotal,
      'overallScore': overallScore,
    };
  }

  factory GhostSnapshot.fromJson(Map<String, dynamic> json) {
    return GhostSnapshot(
      weekStart: DateTime.parse(json['weekStart'] as String),
      laneScores: Map<String, double>.from(json['laneScores'] as Map),
      actionsCompleted: json['actionsCompleted'] as int,
      actionsTotal: json['actionsTotal'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
    );
  }
}

class GhostComparison {
  final GhostSnapshot current;
  final GhostSnapshot ghost;

  const GhostComparison({
    required this.current,
    required this.ghost,
  });

  /// Delta per lane: positive means current is ahead of ghost.
  Map<String, double> get laneDeltas {
    final deltas = <String, double>{};
    for (final lane in current.laneScores.keys) {
      final currentScore = current.laneScores[lane] ?? 0.0;
      final ghostScore = ghost.laneScores[lane] ?? 0.0;
      deltas[lane] = currentScore - ghostScore;
    }
    return deltas;
  }

  /// Overall delta: positive means current is ahead of ghost.
  double get overallDelta => current.overallScore - ghost.overallScore;

  /// Whether the current snapshot is beating the ghost overall.
  bool get isBeatingGhostOverall => current.overallScore > ghost.overallScore;

  /// Whether the current snapshot is beating the ghost in a specific lane.
  bool isBeatingGhostInLane(String lane) {
    final currentScore = current.laneScores[lane] ?? 0.0;
    final ghostScore = ghost.laneScores[lane] ?? 0.0;
    return currentScore > ghostScore;
  }

  /// List of lane names where current is beating the ghost.
  List<String> get lanesBeatingGhost {
    return current.laneScores.keys
        .where((lane) => isBeatingGhostInLane(lane))
        .toList();
  }

  GhostComparison copyWith({
    GhostSnapshot? current,
    GhostSnapshot? ghost,
  }) {
    return GhostComparison(
      current: current ?? this.current,
      ghost: ghost ?? this.ghost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current.toJson(),
      'ghost': ghost.toJson(),
    };
  }

  factory GhostComparison.fromJson(Map<String, dynamic> json) {
    return GhostComparison(
      current:
          GhostSnapshot.fromJson(json['current'] as Map<String, dynamic>),
      ghost: GhostSnapshot.fromJson(json['ghost'] as Map<String, dynamic>),
    );
  }
}

class WeeklyGhostChallenge {
  final bool isActive;
  final int targetBeatCount;
  final int actualBeatCount;
  final List<String> lanesBeaten;

  const WeeklyGhostChallenge({
    required this.isActive,
    required this.targetBeatCount,
    required this.actualBeatCount,
    required this.lanesBeaten,
  });

  /// Whether the user has met or exceeded the target.
  bool get isCompleted => actualBeatCount >= targetBeatCount;

  /// Progress as a fraction between 0.0 and 1.0.
  double get progress =>
      targetBeatCount > 0 ? (actualBeatCount / targetBeatCount).clamp(0.0, 1.0) : 0.0;

  WeeklyGhostChallenge copyWith({
    bool? isActive,
    int? targetBeatCount,
    int? actualBeatCount,
    List<String>? lanesBeaten,
  }) {
    return WeeklyGhostChallenge(
      isActive: isActive ?? this.isActive,
      targetBeatCount: targetBeatCount ?? this.targetBeatCount,
      actualBeatCount: actualBeatCount ?? this.actualBeatCount,
      lanesBeaten: lanesBeaten ?? this.lanesBeaten,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'targetBeatCount': targetBeatCount,
      'actualBeatCount': actualBeatCount,
      'lanesBeaten': lanesBeaten,
    };
  }

  factory WeeklyGhostChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyGhostChallenge(
      isActive: json['isActive'] as bool,
      targetBeatCount: json['targetBeatCount'] as int,
      actualBeatCount: json['actualBeatCount'] as int,
      lanesBeaten: List<String>.from(json['lanesBeaten'] as List),
    );
  }
}

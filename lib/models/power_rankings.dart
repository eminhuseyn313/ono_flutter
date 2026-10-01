import 'package:flutter/material.dart';

enum RankTrend {
  up,
  down,
  stable,
  newEntry;

  String get displayName {
    switch (this) {
      case RankTrend.up:
        return 'Trending Up';
      case RankTrend.down:
        return 'Trending Down';
      case RankTrend.stable:
        return 'Stable';
      case RankTrend.newEntry:
        return 'New Entry';
    }
  }

  IconData get icon {
    switch (this) {
      case RankTrend.up:
        return Icons.trending_up;
      case RankTrend.down:
        return Icons.trending_down;
      case RankTrend.stable:
        return Icons.trending_flat;
      case RankTrend.newEntry:
        return Icons.fiber_new;
    }
  }

  Color get color {
    switch (this) {
      case RankTrend.up:
        return const Color(0xFF7DB495);
      case RankTrend.down:
        return const Color(0xFFE0605A);
      case RankTrend.stable:
        return const Color(0xFF8E8A82);
      case RankTrend.newEntry:
        return const Color(0xFF7C9CC4);
    }
  }

  String toJson() => name;

  static RankTrend fromJson(String value) {
    switch (value) {
      case 'newEntry':
        return RankTrend.newEntry;
      default:
        return RankTrend.values.firstWhere((e) => e.name == value);
    }
  }
}

enum PerformanceTier {
  elite,
  strong,
  growing,
  needsWork,
  inactive;

  String get displayName {
    switch (this) {
      case PerformanceTier.elite:
        return 'Elite';
      case PerformanceTier.strong:
        return 'Strong';
      case PerformanceTier.growing:
        return 'Growing';
      case PerformanceTier.needsWork:
        return 'Needs Work';
      case PerformanceTier.inactive:
        return 'Inactive';
    }
  }

  Color get color {
    switch (this) {
      case PerformanceTier.elite:
        return const Color(0xFFC8894A);
      case PerformanceTier.strong:
        return const Color(0xFF7DB495);
      case PerformanceTier.growing:
        return const Color(0xFF7C9CC4);
      case PerformanceTier.needsWork:
        return const Color(0xFFE2B354);
      case PerformanceTier.inactive:
        return const Color(0xFF8E8A82);
    }
  }

  Color get glowColor {
    switch (this) {
      case PerformanceTier.elite:
        return const Color(0xFFC8894A).withValues(alpha: 0.4);
      case PerformanceTier.strong:
        return const Color(0xFF7DB495).withValues(alpha: 0.4);
      case PerformanceTier.growing:
        return const Color(0xFF7C9CC4).withValues(alpha: 0.4);
      case PerformanceTier.needsWork:
        return const Color(0xFFE2B354).withValues(alpha: 0.4);
      case PerformanceTier.inactive:
        return const Color(0xFF8E8A82).withValues(alpha: 0.4);
    }
  }

  int get minimumScore {
    switch (this) {
      case PerformanceTier.elite:
        return 85;
      case PerformanceTier.strong:
        return 70;
      case PerformanceTier.growing:
        return 50;
      case PerformanceTier.needsWork:
        return 30;
      case PerformanceTier.inactive:
        return 0;
    }
  }

  String get emoji {
    switch (this) {
      case PerformanceTier.elite:
        return '👑';
      case PerformanceTier.strong:
        return '💪';
      case PerformanceTier.growing:
        return '🌱';
      case PerformanceTier.needsWork:
        return '⚡';
      case PerformanceTier.inactive:
        return '💤';
    }
  }

  static PerformanceTier fromScore(int score) {
    if (score >= 85) return PerformanceTier.elite;
    if (score >= 70) return PerformanceTier.strong;
    if (score >= 50) return PerformanceTier.growing;
    if (score >= 30) return PerformanceTier.needsWork;
    return PerformanceTier.inactive;
  }

  String toJson() => name;

  static PerformanceTier fromJson(String value) {
    switch (value) {
      case 'needsWork':
        return PerformanceTier.needsWork;
      default:
        return PerformanceTier.values.firstWhere((e) => e.name == value);
    }
  }
}

class LaneRanking {
  final String lane;
  final int score;
  final int previousScore;
  final int rank;
  final int previousRank;
  final RankTrend trend;
  final int streakDays;
  final double completionRate;
  final String topAction;
  final String improvementTip;

  const LaneRanking({
    required this.lane,
    required this.score,
    required this.previousScore,
    required this.rank,
    required this.previousRank,
    required this.trend,
    required this.streakDays,
    required this.completionRate,
    required this.topAction,
    required this.improvementTip,
  });

  int get scoreDelta => score - previousScore;
  int get rankDelta => previousRank - rank;

  String get laneEmoji {
    switch (lane.toLowerCase()) {
      case 'mind':
        return '🧠';
      case 'body':
        return '💪';
      case 'social':
        return '🤝';
      case 'skill':
        return '🎯';
      default:
        return '⭐';
    }
  }

  Color get laneColor {
    switch (lane.toLowerCase()) {
      case 'mind':
        return const Color(0xFFC8894A);
      case 'body':
        return const Color(0xFF7C9CC4);
      case 'social':
        return const Color(0xFF7DB495);
      case 'skill':
        return const Color(0xFFE2B354);
      default:
        return const Color(0xFF8E8A82);
    }
  }

  Color get laneColorDark {
    switch (lane.toLowerCase()) {
      case 'mind':
        return const Color(0xFF4A2F18);
      case 'body':
        return const Color(0xFF164E63);
      case 'social':
        return const Color(0xFF064E3B);
      case 'skill':
        return const Color(0xFF78350F);
      default:
        return const Color(0xFF374151);
    }
  }

  LaneRanking copyWith({
    String? lane,
    int? score,
    int? previousScore,
    int? rank,
    int? previousRank,
    RankTrend? trend,
    int? streakDays,
    double? completionRate,
    String? topAction,
    String? improvementTip,
  }) {
    return LaneRanking(
      lane: lane ?? this.lane,
      score: score ?? this.score,
      previousScore: previousScore ?? this.previousScore,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
      trend: trend ?? this.trend,
      streakDays: streakDays ?? this.streakDays,
      completionRate: completionRate ?? this.completionRate,
      topAction: topAction ?? this.topAction,
      improvementTip: improvementTip ?? this.improvementTip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lane': lane,
      'score': score,
      'previousScore': previousScore,
      'rank': rank,
      'previousRank': previousRank,
      'trend': trend.toJson(),
      'streakDays': streakDays,
      'completionRate': completionRate,
      'topAction': topAction,
      'improvementTip': improvementTip,
    };
  }

  factory LaneRanking.fromJson(Map<String, dynamic> json) {
    return LaneRanking(
      lane: json['lane'] as String,
      score: json['score'] as int,
      previousScore: json['previousScore'] as int,
      rank: json['rank'] as int,
      previousRank: json['previousRank'] as int,
      trend: RankTrend.fromJson(json['trend'] as String),
      streakDays: json['streakDays'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      topAction: json['topAction'] as String,
      improvementTip: json['improvementTip'] as String,
    );
  }
}

class WeeklyDigest {
  final String id;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int overallScore;
  final int previousOverallScore;
  final PerformanceTier tier;
  final List<LaneRanking> laneRankings;
  final List<String> highlights;
  final int totalActionsCompleted;
  final int totalXpEarned;
  final int weekNumber;

  const WeeklyDigest({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.overallScore,
    required this.previousOverallScore,
    required this.tier,
    required this.laneRankings,
    required this.highlights,
    required this.totalActionsCompleted,
    required this.totalXpEarned,
    required this.weekNumber,
  });

  int get scoreDelta => overallScore - previousOverallScore;
  bool get isImproved => overallScore > previousOverallScore;

  LaneRanking get strongestLane =>
      laneRankings.reduce((a, b) => a.score > b.score ? a : b);

  LaneRanking get weakestLane =>
      laneRankings.reduce((a, b) => a.score < b.score ? a : b);

  LaneRanking? get mostImprovedLane {
    final improved = laneRankings.where((l) => l.scoreDelta > 0).toList();
    if (improved.isEmpty) return null;
    return improved.reduce((a, b) => a.scoreDelta > b.scoreDelta ? a : b);
  }

  WeeklyDigest copyWith({
    String? id,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    int? overallScore,
    int? previousOverallScore,
    PerformanceTier? tier,
    List<LaneRanking>? laneRankings,
    List<String>? highlights,
    int? totalActionsCompleted,
    int? totalXpEarned,
    int? weekNumber,
  }) {
    return WeeklyDigest(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      overallScore: overallScore ?? this.overallScore,
      previousOverallScore: previousOverallScore ?? this.previousOverallScore,
      tier: tier ?? this.tier,
      laneRankings: laneRankings ?? this.laneRankings,
      highlights: highlights ?? this.highlights,
      totalActionsCompleted: totalActionsCompleted ?? this.totalActionsCompleted,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'overallScore': overallScore,
      'previousOverallScore': previousOverallScore,
      'tier': tier.toJson(),
      'laneRankings': laneRankings.map((l) => l.toJson()).toList(),
      'highlights': highlights,
      'totalActionsCompleted': totalActionsCompleted,
      'totalXpEarned': totalXpEarned,
      'weekNumber': weekNumber,
    };
  }

  factory WeeklyDigest.fromJson(Map<String, dynamic> json) {
    return WeeklyDigest(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      overallScore: json['overallScore'] as int,
      previousOverallScore: json['previousOverallScore'] as int,
      tier: PerformanceTier.fromJson(json['tier'] as String),
      laneRankings: (json['laneRankings'] as List)
          .map((l) => LaneRanking.fromJson(l as Map<String, dynamic>))
          .toList(),
      highlights: (json['highlights'] as List).cast<String>(),
      totalActionsCompleted: json['totalActionsCompleted'] as int,
      totalXpEarned: json['totalXpEarned'] as int,
      weekNumber: json['weekNumber'] as int,
    );
  }
}

class RankingHistory {
  final DateTime week;
  final int overallScore;
  final Map<String, int> laneScores;

  const RankingHistory({
    required this.week,
    required this.overallScore,
    required this.laneScores,
  });

  RankingHistory copyWith({
    DateTime? week,
    int? overallScore,
    Map<String, int>? laneScores,
  }) {
    return RankingHistory(
      week: week ?? this.week,
      overallScore: overallScore ?? this.overallScore,
      laneScores: laneScores ?? this.laneScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week.toIso8601String(),
      'overallScore': overallScore,
      'laneScores': laneScores,
    };
  }

  factory RankingHistory.fromJson(Map<String, dynamic> json) {
    return RankingHistory(
      week: DateTime.parse(json['week'] as String),
      overallScore: json['overallScore'] as int,
      laneScores: (json['laneScores'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int)),
    );
  }
}

class PowerRankingsStats {
  final PerformanceTier currentTier;
  final PerformanceTier bestTier;
  final double averageOverallScore;
  final int totalWeeksTracked;
  final int bestWeekScore;
  final int worstWeekScore;
  final String mostImprovedLane;
  final String strongestLane;
  final String weakestLane;
  final List<RankingHistory> weeklyHistory;

  const PowerRankingsStats({
    required this.currentTier,
    required this.bestTier,
    required this.averageOverallScore,
    required this.totalWeeksTracked,
    required this.bestWeekScore,
    required this.worstWeekScore,
    required this.mostImprovedLane,
    required this.strongestLane,
    required this.weakestLane,
    required this.weeklyHistory,
  });

  PowerRankingsStats copyWith({
    PerformanceTier? currentTier,
    PerformanceTier? bestTier,
    double? averageOverallScore,
    int? totalWeeksTracked,
    int? bestWeekScore,
    int? worstWeekScore,
    String? mostImprovedLane,
    String? strongestLane,
    String? weakestLane,
    List<RankingHistory>? weeklyHistory,
  }) {
    return PowerRankingsStats(
      currentTier: currentTier ?? this.currentTier,
      bestTier: bestTier ?? this.bestTier,
      averageOverallScore: averageOverallScore ?? this.averageOverallScore,
      totalWeeksTracked: totalWeeksTracked ?? this.totalWeeksTracked,
      bestWeekScore: bestWeekScore ?? this.bestWeekScore,
      worstWeekScore: worstWeekScore ?? this.worstWeekScore,
      mostImprovedLane: mostImprovedLane ?? this.mostImprovedLane,
      strongestLane: strongestLane ?? this.strongestLane,
      weakestLane: weakestLane ?? this.weakestLane,
      weeklyHistory: weeklyHistory ?? this.weeklyHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTier': currentTier.toJson(),
      'bestTier': bestTier.toJson(),
      'averageOverallScore': averageOverallScore,
      'totalWeeksTracked': totalWeeksTracked,
      'bestWeekScore': bestWeekScore,
      'worstWeekScore': worstWeekScore,
      'mostImprovedLane': mostImprovedLane,
      'strongestLane': strongestLane,
      'weakestLane': weakestLane,
      'weeklyHistory': weeklyHistory.map((h) => h.toJson()).toList(),
    };
  }

  factory PowerRankingsStats.fromJson(Map<String, dynamic> json) {
    return PowerRankingsStats(
      currentTier: PerformanceTier.fromJson(json['currentTier'] as String),
      bestTier: PerformanceTier.fromJson(json['bestTier'] as String),
      averageOverallScore: (json['averageOverallScore'] as num).toDouble(),
      totalWeeksTracked: json['totalWeeksTracked'] as int,
      bestWeekScore: json['bestWeekScore'] as int,
      worstWeekScore: json['worstWeekScore'] as int,
      mostImprovedLane: json['mostImprovedLane'] as String,
      strongestLane: json['strongestLane'] as String,
      weakestLane: json['weakestLane'] as String,
      weeklyHistory: (json['weeklyHistory'] as List)
          .map((h) => RankingHistory.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecapCard {
  final String id;
  final WeeklyDigest weekDigest;
  final DateTime generatedAt;
  final String shareText;

  const RecapCard({
    required this.id,
    required this.weekDigest,
    required this.generatedAt,
    required this.shareText,
  });

  RecapCard copyWith({
    String? id,
    WeeklyDigest? weekDigest,
    DateTime? generatedAt,
    String? shareText,
  }) {
    return RecapCard(
      id: id ?? this.id,
      weekDigest: weekDigest ?? this.weekDigest,
      generatedAt: generatedAt ?? this.generatedAt,
      shareText: shareText ?? this.shareText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekDigest': weekDigest.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
      'shareText': shareText,
    };
  }

  factory RecapCard.fromJson(Map<String, dynamic> json) {
    return RecapCard(
      id: json['id'] as String,
      weekDigest:
          WeeklyDigest.fromJson(json['weekDigest'] as Map<String, dynamic>),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      shareText: json['shareText'] as String,
    );
  }
}

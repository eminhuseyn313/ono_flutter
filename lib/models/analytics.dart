enum AnalyticsPeriod { week, month, quarter, year }

class DataPoint {
  final DateTime date;
  final double value;

  const DataPoint({
    required this.date,
    required this.value,
  });

  DataPoint copyWith({
    DateTime? date,
    double? value,
  }) {
    return DataPoint(
      date: date ?? this.date,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class LaneAnalytics {
  final String laneName;
  final int colorValue;
  final int iconCodePoint;
  final double currentScore;
  final double previousScore;
  final List<DataPoint> history;
  final int actionsCompleted;
  final int totalTimeMinutes;
  final double trend;

  const LaneAnalytics({
    required this.laneName,
    required this.colorValue,
    required this.iconCodePoint,
    required this.currentScore,
    required this.previousScore,
    required this.history,
    required this.actionsCompleted,
    required this.totalTimeMinutes,
    required this.trend,
  });

  double get trendPercent =>
      previousScore > 0 ? ((currentScore - previousScore) / previousScore) * 100 : 0;

  LaneAnalytics copyWith({
    String? laneName,
    int? colorValue,
    int? iconCodePoint,
    double? currentScore,
    double? previousScore,
    List<DataPoint>? history,
    int? actionsCompleted,
    int? totalTimeMinutes,
    double? trend,
  }) {
    return LaneAnalytics(
      laneName: laneName ?? this.laneName,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      currentScore: currentScore ?? this.currentScore,
      previousScore: previousScore ?? this.previousScore,
      history: history ?? this.history,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      trend: trend ?? this.trend,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'laneName': laneName,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'currentScore': currentScore,
      'previousScore': previousScore,
      'history': history.map((dp) => dp.toJson()).toList(),
      'actionsCompleted': actionsCompleted,
      'totalTimeMinutes': totalTimeMinutes,
      'trend': trend,
    };
  }

  factory LaneAnalytics.fromJson(Map<String, dynamic> json) {
    return LaneAnalytics(
      laneName: json['laneName'] as String,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      currentScore: (json['currentScore'] as num).toDouble(),
      previousScore: (json['previousScore'] as num).toDouble(),
      history: (json['history'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      actionsCompleted: json['actionsCompleted'] as int,
      totalTimeMinutes: json['totalTimeMinutes'] as int,
      trend: (json['trend'] as num).toDouble(),
    );
  }
}

class StreakAnalytics {
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final List<DataPoint> weeklyStreaks;
  final Map<int, bool> last30Days;

  const StreakAnalytics({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.weeklyStreaks,
    required this.last30Days,
  });

  StreakAnalytics copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalActiveDays,
    List<DataPoint>? weeklyStreaks,
    Map<int, bool>? last30Days,
  }) {
    return StreakAnalytics(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      weeklyStreaks: weeklyStreaks ?? this.weeklyStreaks,
      last30Days: last30Days ?? this.last30Days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalActiveDays': totalActiveDays,
      'weeklyStreaks': weeklyStreaks.map((dp) => dp.toJson()).toList(),
      'last30Days': last30Days.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory StreakAnalytics.fromJson(Map<String, dynamic> json) {
    return StreakAnalytics(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      totalActiveDays: json['totalActiveDays'] as int,
      weeklyStreaks: (json['weeklyStreaks'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      last30Days: (json['last30Days'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as bool)),
    );
  }
}

class XpAnalytics {
  final int totalXp;
  final int currentLevel;
  final String levelName;
  final double progressToNext;
  final List<DataPoint> xpHistory;
  final int avgDailyXp;
  final int bestDayXp;
  final DateTime bestDayDate;

  const XpAnalytics({
    required this.totalXp,
    required this.currentLevel,
    required this.levelName,
    required this.progressToNext,
    required this.xpHistory,
    required this.avgDailyXp,
    required this.bestDayXp,
    required this.bestDayDate,
  });

  XpAnalytics copyWith({
    int? totalXp,
    int? currentLevel,
    String? levelName,
    double? progressToNext,
    List<DataPoint>? xpHistory,
    int? avgDailyXp,
    int? bestDayXp,
    DateTime? bestDayDate,
  }) {
    return XpAnalytics(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      levelName: levelName ?? this.levelName,
      progressToNext: progressToNext ?? this.progressToNext,
      xpHistory: xpHistory ?? this.xpHistory,
      avgDailyXp: avgDailyXp ?? this.avgDailyXp,
      bestDayXp: bestDayXp ?? this.bestDayXp,
      bestDayDate: bestDayDate ?? this.bestDayDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'currentLevel': currentLevel,
      'levelName': levelName,
      'progressToNext': progressToNext,
      'xpHistory': xpHistory.map((dp) => dp.toJson()).toList(),
      'avgDailyXp': avgDailyXp,
      'bestDayXp': bestDayXp,
      'bestDayDate': bestDayDate.toIso8601String(),
    };
  }

  factory XpAnalytics.fromJson(Map<String, dynamic> json) {
    return XpAnalytics(
      totalXp: json['totalXp'] as int,
      currentLevel: json['currentLevel'] as int,
      levelName: json['levelName'] as String,
      progressToNext: (json['progressToNext'] as num).toDouble(),
      xpHistory: (json['xpHistory'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgDailyXp: json['avgDailyXp'] as int,
      bestDayXp: json['bestDayXp'] as int,
      bestDayDate: DateTime.parse(json['bestDayDate'] as String),
    );
  }
}

class AnalyticsSummary {
  final List<LaneAnalytics> lanes;
  final StreakAnalytics streaks;
  final XpAnalytics xp;
  final int totalActions;
  final int totalJournals;
  final int totalReflections;
  final double overallScore;
  final AnalyticsPeriod period;

  const AnalyticsSummary({
    required this.lanes,
    required this.streaks,
    required this.xp,
    required this.totalActions,
    required this.totalJournals,
    required this.totalReflections,
    required this.overallScore,
    required this.period,
  });

  AnalyticsSummary copyWith({
    List<LaneAnalytics>? lanes,
    StreakAnalytics? streaks,
    XpAnalytics? xp,
    int? totalActions,
    int? totalJournals,
    int? totalReflections,
    double? overallScore,
    AnalyticsPeriod? period,
  }) {
    return AnalyticsSummary(
      lanes: lanes ?? this.lanes,
      streaks: streaks ?? this.streaks,
      xp: xp ?? this.xp,
      totalActions: totalActions ?? this.totalActions,
      totalJournals: totalJournals ?? this.totalJournals,
      totalReflections: totalReflections ?? this.totalReflections,
      overallScore: overallScore ?? this.overallScore,
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lanes': lanes.map((l) => l.toJson()).toList(),
      'streaks': streaks.toJson(),
      'xp': xp.toJson(),
      'totalActions': totalActions,
      'totalJournals': totalJournals,
      'totalReflections': totalReflections,
      'overallScore': overallScore,
      'period': period.name,
    };
  }

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      lanes: (json['lanes'] as List<dynamic>)
          .map((e) => LaneAnalytics.fromJson(e as Map<String, dynamic>))
          .toList(),
      streaks:
          StreakAnalytics.fromJson(json['streaks'] as Map<String, dynamic>),
      xp: XpAnalytics.fromJson(json['xp'] as Map<String, dynamic>),
      totalActions: json['totalActions'] as int,
      totalJournals: json['totalJournals'] as int,
      totalReflections: json['totalReflections'] as int,
      overallScore: (json['overallScore'] as num).toDouble(),
      period: AnalyticsPeriod.values.byName(json['period'] as String),
    );
  }
}

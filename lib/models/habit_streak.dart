enum StreakIntensity { none, low, medium, high, extreme }

class DayActivity {
  final DateTime date;
  final int actionsCompleted;
  final StreakIntensity intensity;
  final bool isStreakDay;
  final List<String> completedLanes;

  const DayActivity({
    required this.date,
    required this.actionsCompleted,
    required this.intensity,
    required this.isStreakDay,
    required this.completedLanes,
  });

  DayActivity copyWith({
    DateTime? date,
    int? actionsCompleted,
    StreakIntensity? intensity,
    bool? isStreakDay,
    List<String>? completedLanes,
  }) {
    return DayActivity(
      date: date ?? this.date,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      intensity: intensity ?? this.intensity,
      isStreakDay: isStreakDay ?? this.isStreakDay,
      completedLanes: completedLanes ?? this.completedLanes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'actionsCompleted': actionsCompleted,
        'intensity': intensity.index,
        'isStreakDay': isStreakDay,
        'completedLanes': completedLanes,
      };

  factory DayActivity.fromJson(Map<String, dynamic> json) => DayActivity(
        date: DateTime.parse(json['date'] as String),
        actionsCompleted: json['actionsCompleted'] as int,
        intensity: StreakIntensity.values[json['intensity'] as int],
        isStreakDay: json['isStreakDay'] as bool,
        completedLanes: List<String>.from(json['completedLanes'] as List),
      );
}

class HabitStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime longestStreakStart;
  final DateTime longestStreakEnd;
  final int totalActiveDays;
  final int totalActions;
  final double averageActionsPerDay;
  final Map<String, int> laneStreaks;

  const HabitStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.longestStreakStart,
    required this.longestStreakEnd,
    required this.totalActiveDays,
    required this.totalActions,
    required this.averageActionsPerDay,
    required this.laneStreaks,
  });

  HabitStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? longestStreakStart,
    DateTime? longestStreakEnd,
    int? totalActiveDays,
    int? totalActions,
    double? averageActionsPerDay,
    Map<String, int>? laneStreaks,
  }) {
    return HabitStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      longestStreakStart: longestStreakStart ?? this.longestStreakStart,
      longestStreakEnd: longestStreakEnd ?? this.longestStreakEnd,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      totalActions: totalActions ?? this.totalActions,
      averageActionsPerDay: averageActionsPerDay ?? this.averageActionsPerDay,
      laneStreaks: laneStreaks ?? this.laneStreaks,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'longestStreakStart': longestStreakStart.toIso8601String(),
        'longestStreakEnd': longestStreakEnd.toIso8601String(),
        'totalActiveDays': totalActiveDays,
        'totalActions': totalActions,
        'averageActionsPerDay': averageActionsPerDay,
        'laneStreaks': laneStreaks,
      };

  factory HabitStreak.fromJson(Map<String, dynamic> json) => HabitStreak(
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        longestStreakStart: DateTime.parse(json['longestStreakStart'] as String),
        longestStreakEnd: DateTime.parse(json['longestStreakEnd'] as String),
        totalActiveDays: json['totalActiveDays'] as int,
        totalActions: json['totalActions'] as int,
        averageActionsPerDay: (json['averageActionsPerDay'] as num).toDouble(),
        laneStreaks: Map<String, int>.from(json['laneStreaks'] as Map),
      );
}

class FreezeToken {
  final String id;
  final bool isUsed;
  final DateTime? usedDate;
  final DateTime earnedDate;

  const FreezeToken({
    required this.id,
    required this.isUsed,
    this.usedDate,
    required this.earnedDate,
  });

  FreezeToken copyWith({
    String? id,
    bool? isUsed,
    DateTime? usedDate,
    DateTime? earnedDate,
  }) {
    return FreezeToken(
      id: id ?? this.id,
      isUsed: isUsed ?? this.isUsed,
      usedDate: usedDate ?? this.usedDate,
      earnedDate: earnedDate ?? this.earnedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUsed': isUsed,
        'usedDate': usedDate?.toIso8601String(),
        'earnedDate': earnedDate.toIso8601String(),
      };

  factory FreezeToken.fromJson(Map<String, dynamic> json) => FreezeToken(
        id: json['id'] as String,
        isUsed: json['isUsed'] as bool,
        usedDate: json['usedDate'] != null
            ? DateTime.parse(json['usedDate'] as String)
            : null,
        earnedDate: DateTime.parse(json['earnedDate'] as String),
      );
}

class StreakMilestone {
  final int days;
  final String title;
  final String description;
  final int iconCodePoint;
  final bool isReached;
  final DateTime? reachedDate;

  const StreakMilestone({
    required this.days,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.isReached,
    this.reachedDate,
  });

  StreakMilestone copyWith({
    int? days,
    String? title,
    String? description,
    int? iconCodePoint,
    bool? isReached,
    DateTime? reachedDate,
  }) {
    return StreakMilestone(
      days: days ?? this.days,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isReached: isReached ?? this.isReached,
      reachedDate: reachedDate ?? this.reachedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'days': days,
        'title': title,
        'description': description,
        'iconCodePoint': iconCodePoint,
        'isReached': isReached,
        'reachedDate': reachedDate?.toIso8601String(),
      };

  factory StreakMilestone.fromJson(Map<String, dynamic> json) =>
      StreakMilestone(
        days: json['days'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        iconCodePoint: json['iconCodePoint'] as int,
        isReached: json['isReached'] as bool,
        reachedDate: json['reachedDate'] != null
            ? DateTime.parse(json['reachedDate'] as String)
            : null,
      );
}

class StreakData {
  final HabitStreak streak;
  final List<DayActivity> calendarDays;
  final List<FreezeToken> freezeTokens;
  final List<StreakMilestone> milestones;
  final int freezeTokensAvailable;
  final int freezeTokensUsed;

  const StreakData({
    required this.streak,
    required this.calendarDays,
    required this.freezeTokens,
    required this.milestones,
    required this.freezeTokensAvailable,
    required this.freezeTokensUsed,
  });

  StreakData copyWith({
    HabitStreak? streak,
    List<DayActivity>? calendarDays,
    List<FreezeToken>? freezeTokens,
    List<StreakMilestone>? milestones,
    int? freezeTokensAvailable,
    int? freezeTokensUsed,
  }) {
    return StreakData(
      streak: streak ?? this.streak,
      calendarDays: calendarDays ?? this.calendarDays,
      freezeTokens: freezeTokens ?? this.freezeTokens,
      milestones: milestones ?? this.milestones,
      freezeTokensAvailable:
          freezeTokensAvailable ?? this.freezeTokensAvailable,
      freezeTokensUsed: freezeTokensUsed ?? this.freezeTokensUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'streak': streak.toJson(),
        'calendarDays': calendarDays.map((d) => d.toJson()).toList(),
        'freezeTokens': freezeTokens.map((t) => t.toJson()).toList(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'freezeTokensAvailable': freezeTokensAvailable,
        'freezeTokensUsed': freezeTokensUsed,
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        streak: HabitStreak.fromJson(json['streak'] as Map<String, dynamic>),
        calendarDays: (json['calendarDays'] as List)
            .map((d) => DayActivity.fromJson(d as Map<String, dynamic>))
            .toList(),
        freezeTokens: (json['freezeTokens'] as List)
            .map((t) => FreezeToken.fromJson(t as Map<String, dynamic>))
            .toList(),
        milestones: (json['milestones'] as List)
            .map((m) => StreakMilestone.fromJson(m as Map<String, dynamic>))
            .toList(),
        freezeTokensAvailable: json['freezeTokensAvailable'] as int,
        freezeTokensUsed: json['freezeTokensUsed'] as int,
      );
}

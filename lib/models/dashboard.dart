import 'package:flutter/material.dart';

/// Dashboard summary model containing the user's overall status and stats.
class DashboardSummary {
  final String greeting;
  final DateTime todayDate;
  final int streakDays;
  final int totalXp;
  final int level;
  final String levelTitle;
  final double progressToNext;
  final int todayTasksCompleted;
  final int todayTasksTotal;
  final int weeklyScore;
  final String motivationalQuote;
  final String quoteAuthor;

  const DashboardSummary({
    required this.greeting,
    required this.todayDate,
    required this.streakDays,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.progressToNext,
    required this.todayTasksCompleted,
    required this.todayTasksTotal,
    required this.weeklyScore,
    required this.motivationalQuote,
    required this.quoteAuthor,
  });

  DashboardSummary copyWith({
    String? greeting,
    DateTime? todayDate,
    int? streakDays,
    int? totalXp,
    int? level,
    String? levelTitle,
    double? progressToNext,
    int? todayTasksCompleted,
    int? todayTasksTotal,
    int? weeklyScore,
    String? motivationalQuote,
    String? quoteAuthor,
  }) {
    return DashboardSummary(
      greeting: greeting ?? this.greeting,
      todayDate: todayDate ?? this.todayDate,
      streakDays: streakDays ?? this.streakDays,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      progressToNext: progressToNext ?? this.progressToNext,
      todayTasksCompleted: todayTasksCompleted ?? this.todayTasksCompleted,
      todayTasksTotal: todayTasksTotal ?? this.todayTasksTotal,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      quoteAuthor: quoteAuthor ?? this.quoteAuthor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'greeting': greeting,
      'todayDate': todayDate.toIso8601String(),
      'streakDays': streakDays,
      'totalXp': totalXp,
      'level': level,
      'levelTitle': levelTitle,
      'progressToNext': progressToNext,
      'todayTasksCompleted': todayTasksCompleted,
      'todayTasksTotal': todayTasksTotal,
      'weeklyScore': weeklyScore,
      'motivationalQuote': motivationalQuote,
      'quoteAuthor': quoteAuthor,
    };
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      greeting: json['greeting'] as String,
      todayDate: DateTime.parse(json['todayDate'] as String),
      streakDays: json['streakDays'] as int,
      totalXp: json['totalXp'] as int,
      level: json['level'] as int,
      levelTitle: json['levelTitle'] as String,
      progressToNext: (json['progressToNext'] as num).toDouble(),
      todayTasksCompleted: json['todayTasksCompleted'] as int,
      todayTasksTotal: json['todayTasksTotal'] as int,
      weeklyScore: json['weeklyScore'] as int,
      motivationalQuote: json['motivationalQuote'] as String,
      quoteAuthor: json['quoteAuthor'] as String,
    );
  }

  @override
  String toString() {
    return 'DashboardSummary(greeting: $greeting, level: $level "$levelTitle", '
        'xp: $totalXp, streak: $streakDays, tasks: $todayTasksCompleted/$todayTasksTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardSummary &&
        other.greeting == greeting &&
        other.todayDate == todayDate &&
        other.streakDays == streakDays &&
        other.totalXp == totalXp &&
        other.level == level &&
        other.levelTitle == levelTitle &&
        other.progressToNext == progressToNext &&
        other.todayTasksCompleted == todayTasksCompleted &&
        other.todayTasksTotal == todayTasksTotal &&
        other.weeklyScore == weeklyScore &&
        other.motivationalQuote == motivationalQuote &&
        other.quoteAuthor == quoteAuthor;
  }

  @override
  int get hashCode {
    return Object.hash(
      greeting,
      todayDate,
      streakDays,
      totalXp,
      level,
      levelTitle,
      progressToNext,
      todayTasksCompleted,
      todayTasksTotal,
      weeklyScore,
      motivationalQuote,
      quoteAuthor,
    );
  }
}

/// Quick access item for navigating to app features from the dashboard.
class QuickAccessItem {
  final String id;
  final String title;
  final String subtitle;
  final int iconCodePoint;
  final String route;
  final int colorValue;
  final int badgeCount;
  final bool isNew;

  const QuickAccessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconCodePoint,
    required this.route,
    required this.colorValue,
    this.badgeCount = 0,
    this.isNew = false,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  QuickAccessItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? iconCodePoint,
    String? route,
    int? colorValue,
    int? badgeCount,
    bool? isNew,
  }) {
    return QuickAccessItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      route: route ?? this.route,
      colorValue: colorValue ?? this.colorValue,
      badgeCount: badgeCount ?? this.badgeCount,
      isNew: isNew ?? this.isNew,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': iconCodePoint,
      'route': route,
      'colorValue': colorValue,
      'badgeCount': badgeCount,
      'isNew': isNew,
    };
  }

  factory QuickAccessItem.fromJson(Map<String, dynamic> json) {
    return QuickAccessItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      route: json['route'] as String,
      colorValue: json['colorValue'] as int,
      badgeCount: json['badgeCount'] as int? ?? 0,
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'QuickAccessItem(id: $id, title: $title, route: $route, '
        'badge: $badgeCount, isNew: $isNew)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickAccessItem &&
        other.id == id &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.iconCodePoint == iconCodePoint &&
        other.route == route &&
        other.colorValue == colorValue &&
        other.badgeCount == badgeCount &&
        other.isNew == isNew;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      subtitle,
      iconCodePoint,
      route,
      colorValue,
      badgeCount,
      isNew,
    );
  }
}

/// Daily highlight item for streak milestones, level ups, reminders, etc.
class DailyHighlight {
  final String id;
  final String type;
  final String title;
  final String description;
  final int iconCodePoint;
  final int colorValue;
  final String? actionRoute;

  const DailyHighlight({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.iconCodePoint,
    required this.colorValue,
    this.actionRoute,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  /// Valid types for daily highlights.
  static const List<String> validTypes = [
    'streak',
    'levelUp',
    'milestone',
    'reminder',
  ];

  DailyHighlight copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    String? actionRoute,
  }) {
    return DailyHighlight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'actionRoute': actionRoute,
    };
  }

  factory DailyHighlight.fromJson(Map<String, dynamic> json) {
    return DailyHighlight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      actionRoute: json['actionRoute'] as String?,
    );
  }

  @override
  String toString() {
    return 'DailyHighlight(id: $id, type: $type, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyHighlight &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.iconCodePoint == iconCodePoint &&
        other.colorValue == colorValue &&
        other.actionRoute == actionRoute;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      description,
      iconCodePoint,
      colorValue,
      actionRoute,
    );
  }
}

/// Lane summary showing progress in each life domain.
class LaneSummary {
  final String lane;
  final int score;
  final String trend;
  final int tasksToday;
  final int colorValue;

  const LaneSummary({
    required this.lane,
    required this.score,
    required this.trend,
    required this.tasksToday,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  /// Valid trend values.
  static const List<String> validTrends = ['up', 'down', 'stable'];

  LaneSummary copyWith({
    String? lane,
    int? score,
    String? trend,
    int? tasksToday,
    int? colorValue,
  }) {
    return LaneSummary(
      lane: lane ?? this.lane,
      score: score ?? this.score,
      trend: trend ?? this.trend,
      tasksToday: tasksToday ?? this.tasksToday,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lane': lane,
      'score': score,
      'trend': trend,
      'tasksToday': tasksToday,
      'colorValue': colorValue,
    };
  }

  factory LaneSummary.fromJson(Map<String, dynamic> json) {
    return LaneSummary(
      lane: json['lane'] as String,
      score: json['score'] as int,
      trend: json['trend'] as String,
      tasksToday: json['tasksToday'] as int,
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  String toString() {
    return 'LaneSummary(lane: $lane, score: $score, trend: $trend, '
        'tasks: $tasksToday)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaneSummary &&
        other.lane == lane &&
        other.score == score &&
        other.trend == trend &&
        other.tasksToday == tasksToday &&
        other.colorValue == colorValue;
  }

  @override
  int get hashCode {
    return Object.hash(lane, score, trend, tasksToday, colorValue);
  }
}

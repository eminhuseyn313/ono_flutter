enum InsightType {
  pattern,
  nudge,
  tip,
  celebration,
  warning;

  String get label {
    switch (this) {
      case InsightType.pattern:
        return 'Pattern';
      case InsightType.nudge:
        return 'Nudge';
      case InsightType.tip:
        return 'Tip';
      case InsightType.celebration:
        return 'Celebration';
      case InsightType.warning:
        return 'Warning';
    }
  }

  int get iconCodePoint {
    switch (this) {
      case InsightType.pattern:
        return 0xf06bb; // Icons.insights
      case InsightType.nudge:
        return 0xe52f; // Icons.touch_app
      case InsightType.tip:
        return 0xe3e7; // Icons.lightbulb
      case InsightType.celebration:
        return 0xe1f6; // Icons.celebration
      case InsightType.warning:
        return 0xe002; // Icons.warning_amber
    }
  }

  int get colorValue {
    switch (this) {
      case InsightType.pattern:
        return 0xFFC8894A;
      case InsightType.nudge:
        return 0xFF7C9CC4;
      case InsightType.tip:
        return 0xFFE2B354;
      case InsightType.celebration:
        return 0xFF7DB495;
      case InsightType.warning:
        return 0xFFE0605A;
    }
  }
}

enum CoachTone {
  motivational,
  analytical,
  gentle,
  challenging;

  String get label {
    switch (this) {
      case CoachTone.motivational:
        return 'Motivational';
      case CoachTone.analytical:
        return 'Analytical';
      case CoachTone.gentle:
        return 'Gentle';
      case CoachTone.challenging:
        return 'Challenging';
    }
  }
}

class CoachInsight {
  final String id;
  final InsightType type;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;
  final String? relatedLane;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  const CoachInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
    this.relatedLane,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  CoachInsight copyWith({
    String? id,
    InsightType? type,
    String? title,
    String? message,
    String? actionLabel,
    String? actionRoute,
    String? relatedLane,
    DateTime? createdAt,
    bool? isRead,
    bool? isDismissed,
  }) {
    return CoachInsight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      relatedLane: relatedLane ?? this.relatedLane,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'action_label': actionLabel,
        'action_route': actionRoute,
        'related_lane': relatedLane,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'is_dismissed': isDismissed,
      };

  factory CoachInsight.fromJson(Map<String, dynamic> json) => CoachInsight(
        id: json['id'] as String,
        type: InsightType.values.firstWhere((e) => e.name == json['type']),
        title: json['title'] as String,
        message: json['message'] as String,
        actionLabel: json['action_label'] as String?,
        actionRoute: json['action_route'] as String?,
        relatedLane: json['related_lane'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        isDismissed: json['is_dismissed'] as bool? ?? false,
      );
}

class DailyCoachTip {
  final String id;
  final String title;
  final String content;
  final String lane;
  final int laneColorValue;
  final DateTime date;
  final bool isBookmarked;

  const DailyCoachTip({
    required this.id,
    required this.title,
    required this.content,
    required this.lane,
    required this.laneColorValue,
    required this.date,
    this.isBookmarked = false,
  });

  DailyCoachTip copyWith({
    String? id,
    String? title,
    String? content,
    String? lane,
    int? laneColorValue,
    DateTime? date,
    bool? isBookmarked,
  }) {
    return DailyCoachTip(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      lane: lane ?? this.lane,
      laneColorValue: laneColorValue ?? this.laneColorValue,
      date: date ?? this.date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'lane': lane,
        'lane_color_value': laneColorValue,
        'date': date.toIso8601String(),
        'is_bookmarked': isBookmarked,
      };

  factory DailyCoachTip.fromJson(Map<String, dynamic> json) => DailyCoachTip(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        lane: json['lane'] as String,
        laneColorValue: json['lane_color_value'] as int,
        date: DateTime.parse(json['date'] as String),
        isBookmarked: json['is_bookmarked'] as bool? ?? false,
      );
}

class CoachData {
  final List<CoachInsight> insights;
  final DailyCoachTip dailyTip;
  final CoachTone preferredTone;
  final int streakDays;
  final double overallScore;
  final Map<String, double> laneScores;

  const CoachData({
    required this.insights,
    required this.dailyTip,
    required this.preferredTone,
    required this.streakDays,
    required this.overallScore,
    required this.laneScores,
  });

  CoachData copyWith({
    List<CoachInsight>? insights,
    DailyCoachTip? dailyTip,
    CoachTone? preferredTone,
    int? streakDays,
    double? overallScore,
    Map<String, double>? laneScores,
  }) {
    return CoachData(
      insights: insights ?? this.insights,
      dailyTip: dailyTip ?? this.dailyTip,
      preferredTone: preferredTone ?? this.preferredTone,
      streakDays: streakDays ?? this.streakDays,
      overallScore: overallScore ?? this.overallScore,
      laneScores: laneScores ?? this.laneScores,
    );
  }
}

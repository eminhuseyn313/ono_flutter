import 'package:flutter/foundation.dart';

enum GoalStatus {
  not_started,
  in_progress,
  achieved,
  paused;

  String get label {
    switch (this) {
      case GoalStatus.not_started:
        return 'Not Started';
      case GoalStatus.in_progress:
        return 'In Progress';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.paused:
        return 'Paused';
    }
  }

  String toJson() => name;

  static GoalStatus fromJson(String json) =>
      GoalStatus.values.firstWhere((e) => e.name == json);
}

enum GoalTimeframe {
  week,
  month,
  quarter,
  year,
  lifetime;

  String get label {
    switch (this) {
      case GoalTimeframe.week:
        return 'This Week';
      case GoalTimeframe.month:
        return 'This Month';
      case GoalTimeframe.quarter:
        return 'This Quarter';
      case GoalTimeframe.year:
        return 'This Year';
      case GoalTimeframe.lifetime:
        return 'Lifetime';
    }
  }

  String toJson() => name;

  static GoalTimeframe fromJson(String json) =>
      GoalTimeframe.values.firstWhere((e) => e.name == json);
}

enum VisionCategory {
  mind,
  body,
  social,
  skill,
  life;

  String get label {
    switch (this) {
      case VisionCategory.mind:
        return 'Mind';
      case VisionCategory.body:
        return 'Body';
      case VisionCategory.social:
        return 'Social';
      case VisionCategory.skill:
        return 'Skill';
      case VisionCategory.life:
        return 'Life';
    }
  }

  String get emoji {
    switch (this) {
      case VisionCategory.mind:
        return '🧠';
      case VisionCategory.body:
        return '💪';
      case VisionCategory.social:
        return '🤝';
      case VisionCategory.skill:
        return '⚡';
      case VisionCategory.life:
        return '🌟';
    }
  }

  int get colorValue {
    switch (this) {
      case VisionCategory.mind:
        return 0xFF8B5CF6;
      case VisionCategory.body:
        return 0xFF22D3EE;
      case VisionCategory.social:
        return 0xFF34D399;
      case VisionCategory.skill:
        return 0xFFF59E0B;
      case VisionCategory.life:
        return 0xFFEF4444;
    }
  }

  String toJson() => name;

  static VisionCategory fromJson(String json) =>
      VisionCategory.values.firstWhere((e) => e.name == json);
}

class Milestone {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final int order;

  const Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    required this.order,
  });

  Milestone copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    int? order,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
    };
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      order: json['order'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Milestone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VisionGoal {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final VisionCategory category;
  final GoalStatus status;
  final GoalTimeframe timeframe;
  final DateTime? targetDate;
  final double progress;
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime? achievedAt;
  final String affirmation;

  const VisionGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.status = GoalStatus.not_started,
    required this.timeframe,
    this.targetDate,
    this.progress = 0.0,
    this.milestones = const [],
    required this.createdAt,
    this.achievedAt,
    this.affirmation = '',
  });

  int get completedMilestones =>
      milestones.where((m) => m.isCompleted).length;

  int get totalMilestones => milestones.length;

  double get milestoneProgress =>
      totalMilestones > 0 ? completedMilestones / totalMilestones : 0.0;

  bool get isOverdue =>
      targetDate != null &&
      DateTime.now().isAfter(targetDate!) &&
      status != GoalStatus.achieved;

  VisionGoal copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    VisionCategory? category,
    GoalStatus? status,
    GoalTimeframe? timeframe,
    DateTime? targetDate,
    double? progress,
    List<Milestone>? milestones,
    DateTime? createdAt,
    DateTime? achievedAt,
    String? affirmation,
  }) {
    return VisionGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      status: status ?? this.status,
      timeframe: timeframe ?? this.timeframe,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      milestones: milestones ?? this.milestones,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
      affirmation: affirmation ?? this.affirmation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'category': category.toJson(),
      'status': status.toJson(),
      'timeframe': timeframe.toJson(),
      'targetDate': targetDate?.toIso8601String(),
      'progress': progress,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'achievedAt': achievedAt?.toIso8601String(),
      'affirmation': affirmation,
    };
  }

  factory VisionGoal.fromJson(Map<String, dynamic> json) {
    return VisionGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: VisionCategory.fromJson(json['category'] as String),
      status: GoalStatus.fromJson(json['status'] as String),
      timeframe: GoalTimeframe.fromJson(json['timeframe'] as String),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      progress: (json['progress'] as num).toDouble(),
      milestones: (json['milestones'] as List<dynamic>)
          .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      achievedAt: json['achievedAt'] != null
          ? DateTime.parse(json['achievedAt'] as String)
          : null,
      affirmation: json['affirmation'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VisionSnapshot {
  final String id;
  final DateTime date;
  final int goalsTotal;
  final int goalsAchieved;
  final Map<VisionCategory, double> categoryBreakdown;
  final String notes;

  const VisionSnapshot({
    required this.id,
    required this.date,
    required this.goalsTotal,
    required this.goalsAchieved,
    this.categoryBreakdown = const {},
    this.notes = '',
  });

  double get achievementRate =>
      goalsTotal > 0 ? goalsAchieved / goalsTotal : 0.0;

  VisionSnapshot copyWith({
    String? id,
    DateTime? date,
    int? goalsTotal,
    int? goalsAchieved,
    Map<VisionCategory, double>? categoryBreakdown,
    String? notes,
  }) {
    return VisionSnapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      goalsTotal: goalsTotal ?? this.goalsTotal,
      goalsAchieved: goalsAchieved ?? this.goalsAchieved,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'goalsTotal': goalsTotal,
      'goalsAchieved': goalsAchieved,
      'categoryBreakdown': categoryBreakdown
          .map((key, value) => MapEntry(key.toJson(), value)),
      'notes': notes,
    };
  }

  factory VisionSnapshot.fromJson(Map<String, dynamic> json) {
    return VisionSnapshot(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      goalsTotal: json['goalsTotal'] as int,
      goalsAchieved: json['goalsAchieved'] as int,
      categoryBreakdown:
          (json['categoryBreakdown'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          VisionCategory.fromJson(key),
          (value as num).toDouble(),
        ),
      ),
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionSnapshot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VisionBoardStats {
  final int totalGoals;
  final int achievedGoals;
  final int inProgressGoals;
  final double achievementRate;
  final int longestGoalStreak;
  final Map<VisionCategory, double> categoryProgress;

  const VisionBoardStats({
    this.totalGoals = 0,
    this.achievedGoals = 0,
    this.inProgressGoals = 0,
    this.achievementRate = 0.0,
    this.longestGoalStreak = 0,
    this.categoryProgress = const {},
  });

  VisionBoardStats copyWith({
    int? totalGoals,
    int? achievedGoals,
    int? inProgressGoals,
    double? achievementRate,
    int? longestGoalStreak,
    Map<VisionCategory, double>? categoryProgress,
  }) {
    return VisionBoardStats(
      totalGoals: totalGoals ?? this.totalGoals,
      achievedGoals: achievedGoals ?? this.achievedGoals,
      inProgressGoals: inProgressGoals ?? this.inProgressGoals,
      achievementRate: achievementRate ?? this.achievementRate,
      longestGoalStreak: longestGoalStreak ?? this.longestGoalStreak,
      categoryProgress: categoryProgress ?? this.categoryProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGoals': totalGoals,
      'achievedGoals': achievedGoals,
      'inProgressGoals': inProgressGoals,
      'achievementRate': achievementRate,
      'longestGoalStreak': longestGoalStreak,
      'categoryProgress': categoryProgress
          .map((key, value) => MapEntry(key.toJson(), value)),
    };
  }

  factory VisionBoardStats.fromJson(Map<String, dynamic> json) {
    return VisionBoardStats(
      totalGoals: json['totalGoals'] as int? ?? 0,
      achievedGoals: json['achievedGoals'] as int? ?? 0,
      inProgressGoals: json['inProgressGoals'] as int? ?? 0,
      achievementRate: (json['achievementRate'] as num?)?.toDouble() ?? 0.0,
      longestGoalStreak: json['longestGoalStreak'] as int? ?? 0,
      categoryProgress:
          (json['categoryProgress'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(
                  VisionCategory.fromJson(key),
                  (value as num).toDouble(),
                ),
              ) ??
              {},
    );
  }
}

class VisionQuote {
  final String id;
  final String text;
  final String author;
  final VisionCategory category;

  const VisionQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
  });

  VisionQuote copyWith({
    String? id,
    String? text,
    String? author,
    VisionCategory? category,
  }) {
    return VisionQuote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category.toJson(),
    };
  }

  factory VisionQuote.fromJson(Map<String, dynamic> json) {
    return VisionQuote(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String,
      category: VisionCategory.fromJson(json['category'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionQuote &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

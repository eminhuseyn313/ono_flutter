enum ReviewMood { terrible, bad, neutral, good, amazing }

class WeeklyWin {
  final String id;
  final String title;
  final String? description;
  final String lane;
  final DateTime date;

  const WeeklyWin({
    required this.id,
    required this.title,
    this.description,
    required this.lane,
    required this.date,
  });

  WeeklyWin copyWith({
    String? id,
    String? title,
    String? description,
    String? lane,
    DateTime? date,
  }) {
    return WeeklyWin(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lane: lane ?? this.lane,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lane': lane,
      'date': date.toIso8601String(),
    };
  }

  factory WeeklyWin.fromJson(Map<String, dynamic> json) {
    return WeeklyWin(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lane: json['lane'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class WeeklyLesson {
  final String id;
  final String content;
  final String category;
  final bool isActionable;

  const WeeklyLesson({
    required this.id,
    required this.content,
    required this.category,
    required this.isActionable,
  });

  WeeklyLesson copyWith({
    String? id,
    String? content,
    String? category,
    bool? isActionable,
  }) {
    return WeeklyLesson(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      isActionable: isActionable ?? this.isActionable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'isActionable': isActionable,
    };
  }

  factory WeeklyLesson.fromJson(Map<String, dynamic> json) {
    return WeeklyLesson(
      id: json['id'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      isActionable: json['isActionable'] as bool,
    );
  }
}

class LaneReviewScore {
  final String laneName;
  final int colorValue;
  final int iconCodePoint;
  final double score;
  final int actionsCompleted;
  final String highlight;

  const LaneReviewScore({
    required this.laneName,
    required this.colorValue,
    required this.iconCodePoint,
    required this.score,
    required this.actionsCompleted,
    required this.highlight,
  });

  LaneReviewScore copyWith({
    String? laneName,
    int? colorValue,
    int? iconCodePoint,
    double? score,
    int? actionsCompleted,
    String? highlight,
  }) {
    return LaneReviewScore(
      laneName: laneName ?? this.laneName,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      score: score ?? this.score,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      highlight: highlight ?? this.highlight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'laneName': laneName,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'score': score,
      'actionsCompleted': actionsCompleted,
      'highlight': highlight,
    };
  }

  factory LaneReviewScore.fromJson(Map<String, dynamic> json) {
    return LaneReviewScore(
      laneName: json['laneName'] as String,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      score: (json['score'] as num).toDouble(),
      actionsCompleted: json['actionsCompleted'] as int,
      highlight: json['highlight'] as String,
    );
  }
}

class WeeklyGoal {
  final String id;
  final String title;
  final String lane;
  final bool isCompleted;
  final int priority;

  const WeeklyGoal({
    required this.id,
    required this.title,
    required this.lane,
    required this.isCompleted,
    required this.priority,
  });

  WeeklyGoal copyWith({
    String? id,
    String? title,
    String? lane,
    bool? isCompleted,
    int? priority,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lane': lane,
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      lane: json['lane'] as String,
      isCompleted: json['isCompleted'] as bool,
      priority: json['priority'] as int,
    );
  }
}

class WeeklyReviewData {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final ReviewMood mood;
  final List<WeeklyWin> wins;
  final List<WeeklyLesson> lessons;
  final List<LaneReviewScore> laneScores;
  final List<WeeklyGoal> nextWeekGoals;
  final String? reflectionNote;
  final int overallRating;
  final bool isCompleted;
  final DateTime? completedAt;

  const WeeklyReviewData({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.mood,
    required this.wins,
    required this.lessons,
    required this.laneScores,
    required this.nextWeekGoals,
    this.reflectionNote,
    required this.overallRating,
    required this.isCompleted,
    this.completedAt,
  });

  WeeklyReviewData copyWith({
    String? id,
    DateTime? weekStart,
    DateTime? weekEnd,
    ReviewMood? mood,
    List<WeeklyWin>? wins,
    List<WeeklyLesson>? lessons,
    List<LaneReviewScore>? laneScores,
    List<WeeklyGoal>? nextWeekGoals,
    String? reflectionNote,
    int? overallRating,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return WeeklyReviewData(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      mood: mood ?? this.mood,
      wins: wins ?? this.wins,
      lessons: lessons ?? this.lessons,
      laneScores: laneScores ?? this.laneScores,
      nextWeekGoals: nextWeekGoals ?? this.nextWeekGoals,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      overallRating: overallRating ?? this.overallRating,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'mood': mood.name,
      'wins': wins.map((w) => w.toJson()).toList(),
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'laneScores': laneScores.map((s) => s.toJson()).toList(),
      'nextWeekGoals': nextWeekGoals.map((g) => g.toJson()).toList(),
      'reflectionNote': reflectionNote,
      'overallRating': overallRating,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory WeeklyReviewData.fromJson(Map<String, dynamic> json) {
    return WeeklyReviewData(
      id: json['id'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      mood: ReviewMood.values.firstWhere(
        (m) => m.name == json['mood'],
        orElse: () => ReviewMood.neutral,
      ),
      wins: (json['wins'] as List<dynamic>)
          .map((w) => WeeklyWin.fromJson(w as Map<String, dynamic>))
          .toList(),
      lessons: (json['lessons'] as List<dynamic>)
          .map((l) => WeeklyLesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      laneScores: (json['laneScores'] as List<dynamic>)
          .map((s) => LaneReviewScore.fromJson(s as Map<String, dynamic>))
          .toList(),
      nextWeekGoals: (json['nextWeekGoals'] as List<dynamic>)
          .map((g) => WeeklyGoal.fromJson(g as Map<String, dynamic>))
          .toList(),
      reflectionNote: json['reflectionNote'] as String?,
      overallRating: json['overallRating'] as int,
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class ReviewHistory {
  final List<WeeklyReviewData> pastReviews;
  final int totalReviewsCompleted;
  final double averageRating;
  final int currentReviewStreak;

  const ReviewHistory({
    required this.pastReviews,
    required this.totalReviewsCompleted,
    required this.averageRating,
    required this.currentReviewStreak,
  });

  ReviewHistory copyWith({
    List<WeeklyReviewData>? pastReviews,
    int? totalReviewsCompleted,
    double? averageRating,
    int? currentReviewStreak,
  }) {
    return ReviewHistory(
      pastReviews: pastReviews ?? this.pastReviews,
      totalReviewsCompleted:
          totalReviewsCompleted ?? this.totalReviewsCompleted,
      averageRating: averageRating ?? this.averageRating,
      currentReviewStreak: currentReviewStreak ?? this.currentReviewStreak,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pastReviews': pastReviews.map((r) => r.toJson()).toList(),
      'totalReviewsCompleted': totalReviewsCompleted,
      'averageRating': averageRating,
      'currentReviewStreak': currentReviewStreak,
    };
  }

  factory ReviewHistory.fromJson(Map<String, dynamic> json) {
    return ReviewHistory(
      pastReviews: (json['pastReviews'] as List<dynamic>)
          .map((r) => WeeklyReviewData.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalReviewsCompleted: json['totalReviewsCompleted'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      currentReviewStreak: json['currentReviewStreak'] as int,
    );
  }
}

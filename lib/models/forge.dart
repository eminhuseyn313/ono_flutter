// models/forge.dart — Forge v2 (backward-compatible expansion)

enum ForgeBlockType {
  text,
  scenario,
  timedExercise,
  multipleChoice,
  reflection,
  keyTakeaway,
  // v2 additions
  audio,
  worksheet,
  checklist,
  quote,
}

enum RecommendationBasis {
  laneScore,
  completionHistory,
  roleModelAffinity,
  popular,
}

class ForgeBlock {
  final String id;
  final ForgeBlockType type;
  final String? title;
  final String? content;
  final List<String>? choices;
  final int? correctChoice;
  final String? explanation;
  final int? durationSeconds;
  final String? instruction;
  final List<String>? options;
  final int? correctOption;
  // v2 additions
  final String? audioUrl;
  final String? transcript;
  final List<String>? checklistItems;
  final List<bool>? checklistChecked;
  final String? quoteAuthor;
  final List<String>? worksheetBlanks;
  final List<String>? worksheetAnswers;

  const ForgeBlock({
    required this.id,
    required this.type,
    this.title,
    this.content,
    this.choices,
    this.correctChoice,
    this.explanation,
    this.durationSeconds,
    this.instruction,
    this.options,
    this.correctOption,
    this.audioUrl,
    this.transcript,
    this.checklistItems,
    this.checklistChecked,
    this.quoteAuthor,
    this.worksheetBlanks,
    this.worksheetAnswers,
  });

  ForgeBlock copyWith({
    String? id,
    ForgeBlockType? type,
    String? title,
    String? content,
    List<String>? choices,
    int? correctChoice,
    String? explanation,
    int? durationSeconds,
    String? instruction,
    List<String>? options,
    int? correctOption,
    String? audioUrl,
    String? transcript,
    List<String>? checklistItems,
    List<bool>? checklistChecked,
    String? quoteAuthor,
    List<String>? worksheetBlanks,
    List<String>? worksheetAnswers,
  }) {
    return ForgeBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      choices: choices ?? this.choices,
      correctChoice: correctChoice ?? this.correctChoice,
      explanation: explanation ?? this.explanation,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      instruction: instruction ?? this.instruction,
      options: options ?? this.options,
      correctOption: correctOption ?? this.correctOption,
      audioUrl: audioUrl ?? this.audioUrl,
      transcript: transcript ?? this.transcript,
      checklistItems: checklistItems ?? this.checklistItems,
      checklistChecked: checklistChecked ?? this.checklistChecked,
      quoteAuthor: quoteAuthor ?? this.quoteAuthor,
      worksheetBlanks: worksheetBlanks ?? this.worksheetBlanks,
      worksheetAnswers: worksheetAnswers ?? this.worksheetAnswers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'choices': choices,
      'correctChoice': correctChoice,
      'explanation': explanation,
      'durationSeconds': durationSeconds,
      'instruction': instruction,
      'options': options,
      'correctOption': correctOption,
      'audioUrl': audioUrl,
      'transcript': transcript,
      'checklistItems': checklistItems,
      'checklistChecked': checklistChecked,
      'quoteAuthor': quoteAuthor,
      'worksheetBlanks': worksheetBlanks,
      'worksheetAnswers': worksheetAnswers,
    };
  }

  factory ForgeBlock.fromJson(Map<String, dynamic> json) {
    return ForgeBlock(
      id: json['id'] as String,
      type: ForgeBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ForgeBlockType.text,
      ),
      title: json['title'] as String?,
      content: json['content'] as String?,
      choices: (json['choices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctChoice: json['correctChoice'] as int?,
      explanation: json['explanation'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      instruction: json['instruction'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctOption: json['correctOption'] as int?,
      audioUrl: json['audioUrl'] as String?,
      transcript: json['transcript'] as String?,
      checklistItems: (json['checklistItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      checklistChecked: (json['checklistChecked'] as List<dynamic>?)
          ?.map((e) => e as bool)
          .toList(),
      quoteAuthor: json['quoteAuthor'] as String?,
      worksheetBlanks: (json['worksheetBlanks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      worksheetAnswers: (json['worksheetAnswers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

class ForgeLesson {
  final String id;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final List<ForgeBlock> blocks;
  final bool isCompleted;

  const ForgeLesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.blocks,
    this.isCompleted = false,
  });

  ForgeLesson copyWith({
    String? id,
    String? title,
    String? summary,
    int? estimatedMinutes,
    List<ForgeBlock>? blocks,
    bool? isCompleted,
  }) {
    return ForgeLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      blocks: blocks ?? this.blocks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'estimatedMinutes': estimatedMinutes,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory ForgeLesson.fromJson(Map<String, dynamic> json) {
    return ForgeLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      blocks: (json['blocks'] as List<dynamic>)
          .map((b) => ForgeBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class ForgeCourse {
  final String id;
  final String title;
  final String description;
  final String roleModelId;
  final String roleModelName;
  final String roleModelEmoji;
  final String lane;
  final List<ForgeLesson> lessons;
  final int totalMinutes;
  // v2 additions
  final String difficulty;
  final List<String> prerequisites;
  final double rating;
  final int enrolledCount;

  const ForgeCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.roleModelId,
    required this.roleModelName,
    required this.roleModelEmoji,
    required this.lane,
    required this.lessons,
    required this.totalMinutes,
    this.difficulty = 'beginner',
    this.prerequisites = const [],
    this.rating = 0.0,
    this.enrolledCount = 0,
  });

  // v1-compatible convenience getters
  int get lessonCount => lessons.length;
  int get completedCount => lessons.where((l) => l.isCompleted).length;
  double get progress =>
      lessonCount == 0 ? 0 : completedCount / lessonCount;
  bool get isComplete => completedCount == lessonCount;

  ForgeCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? roleModelId,
    String? roleModelName,
    String? roleModelEmoji,
    String? lane,
    List<ForgeLesson>? lessons,
    int? totalMinutes,
    String? difficulty,
    List<String>? prerequisites,
    double? rating,
    int? enrolledCount,
  }) {
    return ForgeCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      roleModelId: roleModelId ?? this.roleModelId,
      roleModelName: roleModelName ?? this.roleModelName,
      roleModelEmoji: roleModelEmoji ?? this.roleModelEmoji,
      lane: lane ?? this.lane,
      lessons: lessons ?? this.lessons,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      difficulty: difficulty ?? this.difficulty,
      prerequisites: prerequisites ?? this.prerequisites,
      rating: rating ?? this.rating,
      enrolledCount: enrolledCount ?? this.enrolledCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'roleModelId': roleModelId,
      'roleModelName': roleModelName,
      'roleModelEmoji': roleModelEmoji,
      'lane': lane,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'totalMinutes': totalMinutes,
      'difficulty': difficulty,
      'prerequisites': prerequisites,
      'rating': rating,
      'enrolledCount': enrolledCount,
    };
  }

  factory ForgeCourse.fromJson(Map<String, dynamic> json) {
    return ForgeCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      roleModelId: json['roleModelId'] as String,
      roleModelName: json['roleModelName'] as String,
      roleModelEmoji: json['roleModelEmoji'] as String,
      lane: json['lane'] as String,
      lessons: (json['lessons'] as List<dynamic>)
          .map((l) => ForgeLesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      totalMinutes: json['totalMinutes'] as int,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      enrolledCount: json['enrolledCount'] as int? ?? 0,
    );
  }
}

class ForgeLaneStats {
  final String lane;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int minutesSpent;
  final double averageScore;
  final String strongestTopic;
  final String weakestTopic;

  const ForgeLaneStats({
    required this.lane,
    required this.coursesCompleted,
    required this.lessonsCompleted,
    required this.minutesSpent,
    required this.averageScore,
    required this.strongestTopic,
    required this.weakestTopic,
  });

  ForgeLaneStats copyWith({
    String? lane,
    int? coursesCompleted,
    int? lessonsCompleted,
    int? minutesSpent,
    double? averageScore,
    String? strongestTopic,
    String? weakestTopic,
  }) {
    return ForgeLaneStats(
      lane: lane ?? this.lane,
      coursesCompleted: coursesCompleted ?? this.coursesCompleted,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      minutesSpent: minutesSpent ?? this.minutesSpent,
      averageScore: averageScore ?? this.averageScore,
      strongestTopic: strongestTopic ?? this.strongestTopic,
      weakestTopic: weakestTopic ?? this.weakestTopic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lane': lane,
      'coursesCompleted': coursesCompleted,
      'lessonsCompleted': lessonsCompleted,
      'minutesSpent': minutesSpent,
      'averageScore': averageScore,
      'strongestTopic': strongestTopic,
      'weakestTopic': weakestTopic,
    };
  }

  factory ForgeLaneStats.fromJson(Map<String, dynamic> json) {
    return ForgeLaneStats(
      lane: json['lane'] as String,
      coursesCompleted: json['coursesCompleted'] as int,
      lessonsCompleted: json['lessonsCompleted'] as int,
      minutesSpent: json['minutesSpent'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      strongestTopic: json['strongestTopic'] as String,
      weakestTopic: json['weakestTopic'] as String,
    );
  }
}

class ForgeRecommendation {
  final String courseId;
  final String reason;
  final double matchScore;
  final RecommendationBasis basedOn;

  const ForgeRecommendation({
    required this.courseId,
    required this.reason,
    required this.matchScore,
    required this.basedOn,
  });

  ForgeRecommendation copyWith({
    String? courseId,
    String? reason,
    double? matchScore,
    RecommendationBasis? basedOn,
  }) {
    return ForgeRecommendation(
      courseId: courseId ?? this.courseId,
      reason: reason ?? this.reason,
      matchScore: matchScore ?? this.matchScore,
      basedOn: basedOn ?? this.basedOn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'reason': reason,
      'matchScore': matchScore,
      'basedOn': basedOn.name,
    };
  }

  factory ForgeRecommendation.fromJson(Map<String, dynamic> json) {
    return ForgeRecommendation(
      courseId: json['courseId'] as String,
      reason: json['reason'] as String,
      matchScore: (json['matchScore'] as num).toDouble(),
      basedOn: RecommendationBasis.values.firstWhere(
        (e) => e.name == json['basedOn'],
        orElse: () => RecommendationBasis.popular,
      ),
    );
  }
}

class ForgeProgress {
  final int totalCourses;
  final int completedCourses;
  final int totalLessons;
  final int completedLessons;
  final int totalMinutesSpent;
  // v2 additions
  final Map<String, ForgeLaneStats> laneStats;
  final int currentStreak;
  final DateTime? lastCompletedAt;

  const ForgeProgress({
    required this.totalCourses,
    required this.completedCourses,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalMinutesSpent,
    this.laneStats = const {},
    this.currentStreak = 0,
    this.lastCompletedAt,
  });

  ForgeProgress copyWith({
    int? totalCourses,
    int? completedCourses,
    int? totalLessons,
    int? completedLessons,
    int? totalMinutesSpent,
    Map<String, ForgeLaneStats>? laneStats,
    int? currentStreak,
    DateTime? lastCompletedAt,
  }) {
    return ForgeProgress(
      totalCourses: totalCourses ?? this.totalCourses,
      completedCourses: completedCourses ?? this.completedCourses,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      totalMinutesSpent: totalMinutesSpent ?? this.totalMinutesSpent,
      laneStats: laneStats ?? this.laneStats,
      currentStreak: currentStreak ?? this.currentStreak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'totalMinutesSpent': totalMinutesSpent,
      'laneStats':
          laneStats.map((key, value) => MapEntry(key, value.toJson())),
      'currentStreak': currentStreak,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    };
  }

  double get lessonProgress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  double get courseProgress =>
      totalCourses == 0 ? 0 : completedCourses / totalCourses;

  factory ForgeProgress.fromJson(Map<String, dynamic> json) {
    final laneStatsMap = <String, ForgeLaneStats>{};
    if (json['laneStats'] != null) {
      (json['laneStats'] as Map<String, dynamic>).forEach((key, value) {
        laneStatsMap[key] =
            ForgeLaneStats.fromJson(value as Map<String, dynamic>);
      });
    }
    return ForgeProgress(
      totalCourses: json['totalCourses'] as int,
      completedCourses: json['completedCourses'] as int,
      totalLessons: json['totalLessons'] as int,
      completedLessons: json['completedLessons'] as int,
      totalMinutesSpent: json['totalMinutesSpent'] as int,
      laneStats: laneStatsMap,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'] as String)
          : null,
    );
  }
}

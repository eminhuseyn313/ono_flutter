enum CheckinMood {
  terrible,
  low,
  neutral,
  good,
  great,
  amazing;

  String get label {
    switch (this) {
      case CheckinMood.terrible:
        return 'Terrible';
      case CheckinMood.low:
        return 'Low';
      case CheckinMood.neutral:
        return 'Neutral';
      case CheckinMood.good:
        return 'Good';
      case CheckinMood.great:
        return 'Great';
      case CheckinMood.amazing:
        return 'Amazing';
    }
  }

  String get emoji {
    switch (this) {
      case CheckinMood.terrible:
        return '😞';
      case CheckinMood.low:
        return '😔';
      case CheckinMood.neutral:
        return '😐';
      case CheckinMood.good:
        return '🙂';
      case CheckinMood.great:
        return '😊';
      case CheckinMood.amazing:
        return '🔥';
    }
  }

  int get colorValue {
    switch (this) {
      case CheckinMood.terrible:
        return 0xFFE0605A;
      case CheckinMood.low:
        return 0xFFD9774A;
      case CheckinMood.neutral:
        return 0xFFE8C46A;
      case CheckinMood.good:
        return 0xFF7DB495;
      case CheckinMood.great:
        return 0xFF7C9CC4;
      case CheckinMood.amazing:
        return 0xFFC8894A;
    }
  }
}

enum CheckinTime {
  morning,
  evening;

  String get label {
    switch (this) {
      case CheckinTime.morning:
        return 'Morning';
      case CheckinTime.evening:
        return 'Evening';
    }
  }
}

enum FocusArea {
  mind,
  body,
  social,
  skill;

  String get label {
    switch (this) {
      case FocusArea.mind:
        return 'Mind';
      case FocusArea.body:
        return 'Body';
      case FocusArea.social:
        return 'Social';
      case FocusArea.skill:
        return 'Skill';
    }
  }

  int get colorValue {
    switch (this) {
      case FocusArea.mind:
        return 0xFFC8894A;
      case FocusArea.body:
        return 0xFF7C9CC4;
      case FocusArea.social:
        return 0xFF7DB495;
      case FocusArea.skill:
        return 0xFFE2B354;
    }
  }

  int get iconCodePoint {
    switch (this) {
      case FocusArea.mind:
        return 0xf0513; // Icons.psychology
      case FocusArea.body:
        return 0xe39e; // Icons.fitness_center
      case FocusArea.social:
        return 0xe7ef; // Icons.people
      case FocusArea.skill:
        return 0xe65e; // Icons.auto_awesome
    }
  }
}

class DailyCheckin {
  final String id;
  final DateTime date;
  final CheckinMood? morningMood;
  final double? energyLevel; // 0.0 - 1.0
  final List<String> gratitudes;
  final String? intention;
  final FocusArea? primaryFocus;
  final bool morningComplete;
  final String? eveningReflection;
  final double? dayRating; // 0.0 - 5.0
  final CheckinMood? eveningMood;
  final bool eveningComplete;
  final DateTime? morningCompletedAt;
  final DateTime? eveningCompletedAt;

  const DailyCheckin({
    required this.id,
    required this.date,
    this.morningMood,
    this.energyLevel,
    this.gratitudes = const [],
    this.intention,
    this.primaryFocus,
    this.morningComplete = false,
    this.eveningReflection,
    this.dayRating,
    this.eveningMood,
    this.eveningComplete = false,
    this.morningCompletedAt,
    this.eveningCompletedAt,
  });

  DailyCheckin copyWith({
    String? id,
    DateTime? date,
    CheckinMood? morningMood,
    double? energyLevel,
    List<String>? gratitudes,
    String? intention,
    FocusArea? primaryFocus,
    bool? morningComplete,
    String? eveningReflection,
    double? dayRating,
    CheckinMood? eveningMood,
    bool? eveningComplete,
    DateTime? morningCompletedAt,
    DateTime? eveningCompletedAt,
  }) {
    return DailyCheckin(
      id: id ?? this.id,
      date: date ?? this.date,
      morningMood: morningMood ?? this.morningMood,
      energyLevel: energyLevel ?? this.energyLevel,
      gratitudes: gratitudes ?? this.gratitudes,
      intention: intention ?? this.intention,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      morningComplete: morningComplete ?? this.morningComplete,
      eveningReflection: eveningReflection ?? this.eveningReflection,
      dayRating: dayRating ?? this.dayRating,
      eveningMood: eveningMood ?? this.eveningMood,
      eveningComplete: eveningComplete ?? this.eveningComplete,
      morningCompletedAt: morningCompletedAt ?? this.morningCompletedAt,
      eveningCompletedAt: eveningCompletedAt ?? this.eveningCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'morning_mood': morningMood?.name,
      'energy_level': energyLevel,
      'gratitudes': gratitudes,
      'intention': intention,
      'primary_focus': primaryFocus?.name,
      'morning_complete': morningComplete,
      'evening_reflection': eveningReflection,
      'day_rating': dayRating,
      'evening_mood': eveningMood?.name,
      'evening_complete': eveningComplete,
      'morning_completed_at': morningCompletedAt?.toIso8601String(),
      'evening_completed_at': eveningCompletedAt?.toIso8601String(),
    };
  }

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      morningMood: json['morning_mood'] != null
          ? CheckinMood.values.firstWhere((e) => e.name == json['morning_mood'])
          : null,
      energyLevel: (json['energy_level'] as num?)?.toDouble(),
      gratitudes: (json['gratitudes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      intention: json['intention'] as String?,
      primaryFocus: json['primary_focus'] != null
          ? FocusArea.values.firstWhere((e) => e.name == json['primary_focus'])
          : null,
      morningComplete: json['morning_complete'] as bool? ?? false,
      eveningReflection: json['evening_reflection'] as String?,
      dayRating: (json['day_rating'] as num?)?.toDouble(),
      eveningMood: json['evening_mood'] != null
          ? CheckinMood.values.firstWhere((e) => e.name == json['evening_mood'])
          : null,
      eveningComplete: json['evening_complete'] as bool? ?? false,
      morningCompletedAt: json['morning_completed_at'] != null
          ? DateTime.parse(json['morning_completed_at'] as String)
          : null,
      eveningCompletedAt: json['evening_completed_at'] != null
          ? DateTime.parse(json['evening_completed_at'] as String)
          : null,
    );
  }
}

class CheckinHistory {
  final List<DailyCheckin> recentCheckins;
  final int morningStreak;
  final int eveningStreak;
  final double averageMood;
  final int totalCheckins;

  const CheckinHistory({
    required this.recentCheckins,
    required this.morningStreak,
    required this.eveningStreak,
    required this.averageMood,
    required this.totalCheckins,
  });

  CheckinHistory copyWith({
    List<DailyCheckin>? recentCheckins,
    int? morningStreak,
    int? eveningStreak,
    double? averageMood,
    int? totalCheckins,
  }) {
    return CheckinHistory(
      recentCheckins: recentCheckins ?? this.recentCheckins,
      morningStreak: morningStreak ?? this.morningStreak,
      eveningStreak: eveningStreak ?? this.eveningStreak,
      averageMood: averageMood ?? this.averageMood,
      totalCheckins: totalCheckins ?? this.totalCheckins,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recent_checkins': recentCheckins.map((c) => c.toJson()).toList(),
      'morning_streak': morningStreak,
      'evening_streak': eveningStreak,
      'average_mood': averageMood,
      'total_checkins': totalCheckins,
    };
  }

  factory CheckinHistory.fromJson(Map<String, dynamic> json) {
    return CheckinHistory(
      recentCheckins: (json['recent_checkins'] as List<dynamic>)
          .map((e) => DailyCheckin.fromJson(e as Map<String, dynamic>))
          .toList(),
      morningStreak: json['morning_streak'] as int,
      eveningStreak: json['evening_streak'] as int,
      averageMood: (json['average_mood'] as num).toDouble(),
      totalCheckins: json['total_checkins'] as int,
    );
  }
}

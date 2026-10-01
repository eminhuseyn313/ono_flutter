import 'package:flutter/material.dart';

/// Onboarding models for the ONO multi-step onboarding flow.
///
/// Covers step tracking, lane preferences, goals, schedule preferences,
/// and the aggregate onboarding profile.

enum OnboardingStep {
  welcome,
  laneSelection,
  goalSetting,
  scheduleSetup,
  tutorial,
  complete;

  String get label {
    switch (this) {
      case OnboardingStep.welcome:
        return 'Welcome';
      case OnboardingStep.laneSelection:
        return 'Lanes';
      case OnboardingStep.goalSetting:
        return 'Goals';
      case OnboardingStep.scheduleSetup:
        return 'Schedule';
      case OnboardingStep.tutorial:
        return 'Ready';
      case OnboardingStep.complete:
        return 'Complete';
    }
  }

  int get stepIndex {
    switch (this) {
      case OnboardingStep.welcome:
        return 0;
      case OnboardingStep.laneSelection:
        return 1;
      case OnboardingStep.goalSetting:
        return 2;
      case OnboardingStep.scheduleSetup:
        return 3;
      case OnboardingStep.tutorial:
        return 4;
      case OnboardingStep.complete:
        return 5;
    }
  }

  static OnboardingStep fromString(String value) {
    return OnboardingStep.values.firstWhere(
      (step) => step.name == value,
      orElse: () => OnboardingStep.welcome,
    );
  }

  /// The 5 visible steps in the onboarding flow (excludes complete).
  static List<OnboardingStep> get visibleSteps => [
        OnboardingStep.welcome,
        OnboardingStep.laneSelection,
        OnboardingStep.goalSetting,
        OnboardingStep.scheduleSetup,
        OnboardingStep.tutorial,
      ];
}

class LanePreference {
  final String laneId;
  final int priority;
  final double weeklyGoalHours;

  const LanePreference({
    required this.laneId,
    required this.priority,
    this.weeklyGoalHours = 3.0,
  });

  LanePreference copyWith({
    String? laneId,
    int? priority,
    double? weeklyGoalHours,
  }) {
    return LanePreference(
      laneId: laneId ?? this.laneId,
      priority: priority ?? this.priority,
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'laneId': laneId,
      'priority': priority,
      'weeklyGoalHours': weeklyGoalHours,
    };
  }

  factory LanePreference.fromJson(Map<String, dynamic> json) {
    return LanePreference(
      laneId: json['laneId'] as String,
      priority: json['priority'] as int,
      weeklyGoalHours: (json['weeklyGoalHours'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanePreference &&
          runtimeType == other.runtimeType &&
          laneId == other.laneId &&
          priority == other.priority &&
          weeklyGoalHours == other.weeklyGoalHours;

  @override
  int get hashCode => Object.hash(laneId, priority, weeklyGoalHours);

  @override
  String toString() =>
      'LanePreference(laneId: $laneId, priority: $priority, weeklyGoalHours: $weeklyGoalHours)';
}

class OnboardingGoal {
  final String id;
  final String title;
  final String lane;
  final DateTime? targetDate;
  final String description;

  const OnboardingGoal({
    required this.id,
    required this.title,
    required this.lane,
    this.targetDate,
    this.description = '',
  });

  OnboardingGoal copyWith({
    String? id,
    String? title,
    String? lane,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? description,
  }) {
    return OnboardingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lane': lane,
      'targetDate': targetDate?.toIso8601String(),
      'description': description,
    };
  }

  factory OnboardingGoal.fromJson(Map<String, dynamic> json) {
    return OnboardingGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      lane: json['lane'] as String,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      description: json['description'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          lane == other.lane &&
          targetDate == other.targetDate &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, title, lane, targetDate, description);

  @override
  String toString() =>
      'OnboardingGoal(id: $id, title: $title, lane: $lane, targetDate: $targetDate)';
}

class SchedulePreference {
  final String wakeUpTime;
  final String bedTime;
  final int preferredSessionLength;
  final List<int> activeDays;

  const SchedulePreference({
    this.wakeUpTime = '07:00',
    this.bedTime = '23:00',
    this.preferredSessionLength = 30,
    this.activeDays = const [0, 1, 2, 3, 4],
  });

  SchedulePreference copyWith({
    String? wakeUpTime,
    String? bedTime,
    int? preferredSessionLength,
    List<int>? activeDays,
  }) {
    return SchedulePreference(
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      bedTime: bedTime ?? this.bedTime,
      preferredSessionLength:
          preferredSessionLength ?? this.preferredSessionLength,
      activeDays: activeDays ?? this.activeDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wakeUpTime': wakeUpTime,
      'bedTime': bedTime,
      'preferredSessionLength': preferredSessionLength,
      'activeDays': activeDays,
    };
  }

  factory SchedulePreference.fromJson(Map<String, dynamic> json) {
    return SchedulePreference(
      wakeUpTime: json['wakeUpTime'] as String? ?? '07:00',
      bedTime: json['bedTime'] as String? ?? '23:00',
      preferredSessionLength:
          json['preferredSessionLength'] as int? ?? 30,
      activeDays: (json['activeDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [0, 1, 2, 3, 4],
    );
  }

  /// Returns the day name abbreviation for a given day index (0=Mon..6=Sun).
  static String dayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day.clamp(0, 6)];
  }

  /// Returns the full day name for a given day index.
  static String dayFullName(int day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[day.clamp(0, 6)];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchedulePreference &&
          runtimeType == other.runtimeType &&
          wakeUpTime == other.wakeUpTime &&
          bedTime == other.bedTime &&
          preferredSessionLength == other.preferredSessionLength &&
          _listEquals(activeDays, other.activeDays);

  @override
  int get hashCode =>
      Object.hash(wakeUpTime, bedTime, preferredSessionLength, activeDays.length);

  @override
  String toString() =>
      'SchedulePreference(wake: $wakeUpTime, bed: $bedTime, session: ${preferredSessionLength}min, days: $activeDays)';
}

class OnboardingProfile {
  final String name;
  final int? age;
  final String motivation;
  final List<LanePreference> lanePreferences;
  final List<OnboardingGoal> goals;
  final SchedulePreference? schedule;
  final Set<OnboardingStep> completedSteps;

  const OnboardingProfile({
    this.name = '',
    this.age,
    this.motivation = '',
    this.lanePreferences = const [],
    this.goals = const [],
    this.schedule,
    this.completedSteps = const {},
  });

  OnboardingProfile copyWith({
    String? name,
    int? age,
    bool clearAge = false,
    String? motivation,
    List<LanePreference>? lanePreferences,
    List<OnboardingGoal>? goals,
    SchedulePreference? schedule,
    bool clearSchedule = false,
    Set<OnboardingStep>? completedSteps,
  }) {
    return OnboardingProfile(
      name: name ?? this.name,
      age: clearAge ? null : (age ?? this.age),
      motivation: motivation ?? this.motivation,
      lanePreferences: lanePreferences ?? this.lanePreferences,
      goals: goals ?? this.goals,
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'motivation': motivation,
      'lanePreferences': lanePreferences.map((lp) => lp.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'schedule': schedule?.toJson(),
      'completedSteps':
          completedSteps.map((s) => s.name).toList(),
    };
  }

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      name: json['name'] as String? ?? '',
      age: json['age'] as int?,
      motivation: json['motivation'] as String? ?? '',
      lanePreferences: (json['lanePreferences'] as List<dynamic>?)
              ?.map((e) => LanePreference.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => OnboardingGoal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      schedule: json['schedule'] != null
          ? SchedulePreference.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      completedSteps: (json['completedSteps'] as List<dynamic>?)
              ?.map((e) => OnboardingStep.fromString(e as String))
              .toSet() ??
          const {},
    );
  }

  /// Whether basic profile info (name) has been provided.
  bool get hasBasicInfo => name.trim().isNotEmpty;

  /// Whether lane preferences have been set.
  bool get hasLanePreferences => lanePreferences.isNotEmpty;

  /// Whether at least one goal has been set.
  bool get hasGoals => goals.isNotEmpty;

  /// Whether schedule has been configured.
  bool get hasSchedule => schedule != null;

  /// Completion percentage (0.0 to 1.0) based on completed steps.
  double get completionProgress {
    final totalSteps = OnboardingStep.visibleSteps.length;
    if (totalSteps == 0) return 0.0;
    return completedSteps
            .where((s) => OnboardingStep.visibleSteps.contains(s))
            .length /
        totalSteps;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age &&
          motivation == other.motivation;

  @override
  int get hashCode => Object.hash(name, age, motivation);

  @override
  String toString() =>
      'OnboardingProfile(name: $name, motivation: $motivation, lanes: ${lanePreferences.length}, goals: ${goals.length})';
}

/// Default lane configurations used throughout onboarding.
class OnboardingLanes {
  static const List<Map<String, dynamic>> defaults = [
    {
      'id': 'mind',
      'name': 'Mind',
      'description': 'Meditation, journaling, focus & mental clarity',
      'icon': 'psychology',
    },
    {
      'id': 'body',
      'name': 'Body',
      'description': 'Workouts, nutrition, sleep & physical health',
      'icon': 'fitness_center',
    },
    {
      'id': 'social',
      'name': 'Social',
      'description': 'Communication, networking & relationships',
      'icon': 'groups',
    },
    {
      'id': 'skill',
      'name': 'Skill',
      'description': 'Learning, career growth & creative projects',
      'icon': 'auto_awesome',
    },
  ];

  static Color colorForLane(String laneId) {
    switch (laneId) {
      case 'mind':
        return const Color(0xFF8B5CF6);
      case 'body':
        return const Color(0xFF22D3EE);
      case 'social':
        return const Color(0xFF34D399);
      case 'skill':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  static IconData iconForLane(String laneId) {
    switch (laneId) {
      case 'mind':
        return Icons.psychology;
      case 'body':
        return Icons.fitness_center;
      case 'social':
        return Icons.groups;
      case 'skill':
        return Icons.auto_awesome;
      default:
        return Icons.circle;
    }
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

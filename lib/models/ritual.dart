import 'package:flutter/material.dart';
import '../time.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum RitualType { morning, evening }

enum RitualLane { mind, body, social, skill }

// ---------------------------------------------------------------------------
// RitualStep
// ---------------------------------------------------------------------------

class RitualStep {
  final String id;
  final String title;
  final String subtitle;
  final RitualLane lane;
  final int durationSeconds;
  final IconData iconData;
  final String instruction;
  final bool isOptional;

  const RitualStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lane,
    required this.durationSeconds,
    required this.iconData,
    required this.instruction,
    this.isOptional = false,
  });

  RitualStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    RitualLane? lane,
    int? durationSeconds,
    IconData? iconData,
    String? instruction,
    bool? isOptional,
  }) {
    return RitualStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      lane: lane ?? this.lane,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      iconData: iconData ?? this.iconData,
      instruction: instruction ?? this.instruction,
      isOptional: isOptional ?? this.isOptional,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'lane': lane.name,
        'durationSeconds': durationSeconds,
        'iconCodePoint': iconData.codePoint,
        'iconFontFamily': iconData.fontFamily,
        'instruction': instruction,
        'isOptional': isOptional,
      };

  factory RitualStep.fromJson(Map<String, dynamic> json) => RitualStep(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        lane: RitualLane.values.byName(json['lane'] as String),
        durationSeconds: json['durationSeconds'] as int,
        // Icons must be compile-time constants for icon tree-shaking, so
        // stored steps map back to one of the ritual icons by code point.
        iconData: _ritualIcons.firstWhere(
            (i) => i.codePoint == json['iconCodePoint'],
            orElse: () => Icons.self_improvement),
        instruction: json['instruction'] as String,
        isOptional: json['isOptional'] as bool? ?? false,
      );
}

const _ritualIcons = [
  Icons.water_drop,
  Icons.auto_stories,
  Icons.flag_outlined,
  Icons.self_improvement,
  Icons.record_voice_over,
];

// ---------------------------------------------------------------------------
// Ritual
// ---------------------------------------------------------------------------

class Ritual {
  final String id;
  final String userId;
  final RitualType type;
  final List<RitualStep> steps;
  final TimeOfDay preferredTime;
  final bool isActive;
  final DateTime createdAt;

  const Ritual({
    required this.id,
    required this.userId,
    required this.type,
    required this.steps,
    required this.preferredTime,
    required this.isActive,
    required this.createdAt,
  });

  int get totalDurationSeconds =>
      steps.fold(0, (sum, s) => sum + s.durationSeconds);

  Ritual copyWith({
    String? id,
    String? userId,
    RitualType? type,
    List<RitualStep>? steps,
    TimeOfDay? preferredTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Ritual(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      preferredTime: preferredTime ?? this.preferredTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'preferredTimeHour': preferredTime.hour,
        'preferredTimeMinute': preferredTime.minute,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Ritual.fromJson(Map<String, dynamic> json) => Ritual(
        id: json['id'] as String,
        userId: json['userId'] as String,
        type: RitualType.values.byName(json['type'] as String),
        steps: (json['steps'] as List)
            .map((s) => RitualStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        preferredTime: TimeOfDay(
          hour: json['preferredTimeHour'] as int,
          minute: json['preferredTimeMinute'] as int,
        ),
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// RitualSession
// ---------------------------------------------------------------------------

class RitualSession {
  final String id;
  final String ritualId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<String> stepsCompleted;
  final Duration totalDuration;

  const RitualSession({
    required this.id,
    required this.ritualId,
    required this.startedAt,
    this.completedAt,
    required this.stepsCompleted,
    required this.totalDuration,
  });

  bool get isComplete => completedAt != null;

  double completionRate(int totalSteps) {
    if (totalSteps == 0) return 0.0;
    return stepsCompleted.length / totalSteps;
  }

  RitualSession copyWith({
    String? id,
    String? ritualId,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? stepsCompleted,
    Duration? totalDuration,
  }) {
    return RitualSession(
      id: id ?? this.id,
      ritualId: ritualId ?? this.ritualId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ritualId': ritualId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'stepsCompleted': stepsCompleted,
        'totalDurationMs': totalDuration.inMilliseconds,
      };

  factory RitualSession.fromJson(Map<String, dynamic> json) => RitualSession(
        id: json['id'] as String,
        ritualId: json['ritualId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        stepsCompleted: List<String>.from(json['stepsCompleted'] as List),
        totalDuration:
            Duration(milliseconds: json['totalDurationMs'] as int),
      );
}

// ---------------------------------------------------------------------------
// Prebuilt rituals
// ---------------------------------------------------------------------------

class PrebuiltRituals {
  static Ritual morning(String userId) => Ritual(
        id: 'ritual_morning_default',
        userId: userId,
        type: RitualType.morning,
        steps: const [
          RitualStep(
            id: 'morning_01_affirmation',
            title: 'Affirmation',
            subtitle: 'Set your mindset',
            lane: RitualLane.mind,
            durationSeconds: 60,
            iconData: Icons.self_improvement,
            instruction:
                'Close your eyes and repeat your personal affirmation three '
                'times. Feel each word resonate. You are capable, focused, and '
                'ready for this day.',
          ),
          RitualStep(
            id: 'morning_02_movement',
            title: 'Movement',
            subtitle: 'Wake your body',
            lane: RitualLane.body,
            durationSeconds: 120,
            iconData: Icons.directions_run,
            instruction:
                'Stretch your arms overhead, roll your shoulders back, and do '
                '10 gentle squats. Shake out any stiffness. Let your body know '
                'the day has begun.',
          ),
          RitualStep(
            id: 'morning_03_mind_primer',
            title: 'Mind Primer',
            subtitle: 'Spark curiosity',
            lane: RitualLane.skill,
            durationSeconds: 90,
            iconData: Icons.lightbulb_outline,
            instruction:
                'Read one page of a book, listen to a short podcast clip, or '
                'review a flashcard. Prime your brain with a small burst of '
                'learning to carry into the day.',
          ),
          RitualStep(
            id: 'morning_04_intention',
            title: 'Intention Setting',
            subtitle: 'Choose your focus',
            lane: RitualLane.mind,
            durationSeconds: 60,
            iconData: Icons.flag_outlined,
            instruction:
                'Pick one clear intention for today. Not a to-do, but a way '
                'of being — patient, bold, present. Write it down or hold it '
                'in your mind.',
          ),
          RitualStep(
            id: 'morning_05_gratitude',
            title: 'Gratitude',
            subtitle: 'Appreciate what is',
            lane: RitualLane.social,
            durationSeconds: 60,
            iconData: Icons.favorite_outline,
            instruction:
                'Think of three things you are grateful for right now. One '
                'about yourself, one about someone you love, and one about '
                'the world around you.',
          ),
        ],
        preferredTime: const TimeOfDay(hour: 7, minute: 0),
        isActive: true,
        createdAt: timeNow(),
      );

  static Ritual evening(String userId) => Ritual(
        id: 'ritual_evening_default',
        userId: userId,
        type: RitualType.evening,
        steps: const [
          RitualStep(
            id: 'evening_01_gratitude',
            title: 'Gratitude',
            subtitle: 'Acknowledge the good',
            lane: RitualLane.social,
            durationSeconds: 60,
            iconData: Icons.favorite_outline,
            instruction:
                'Recall three good moments from today. They can be small — a '
                'kind word, a warm meal, a task completed. Let the feeling '
                'of appreciation settle in.',
          ),
          RitualStep(
            id: 'evening_02_reflection',
            title: 'Reflection',
            subtitle: 'Review your day',
            lane: RitualLane.mind,
            durationSeconds: 90,
            iconData: Icons.auto_stories,
            instruction:
                'Walk through your day in your mind. What went well? What '
                'would you do differently? No judgment — just gentle '
                'observation. Growth lives in reflection.',
          ),
          RitualStep(
            id: 'evening_03_tomorrow_prep',
            title: 'Tomorrow Prep',
            subtitle: 'Plan ahead',
            lane: RitualLane.skill,
            durationSeconds: 90,
            iconData: Icons.checklist,
            instruction:
                'Write down your top three priorities for tomorrow. Lay out '
                'anything you need — clothes, bag, keys. A prepared evening '
                'makes a calm morning.',
          ),
          RitualStep(
            id: 'evening_04_wind_down',
            title: 'Wind-Down',
            subtitle: 'Release tension',
            lane: RitualLane.body,
            durationSeconds: 120,
            iconData: Icons.spa,
            instruction:
                'Do a slow body scan from head to toe. Breathe deeply, '
                'relax each muscle group. Let your shoulders drop, unclench '
                'your jaw, soften your eyes.',
          ),
          RitualStep(
            id: 'evening_05_sleep_intention',
            title: 'Sleep Intention',
            subtitle: 'Drift with purpose',
            lane: RitualLane.mind,
            durationSeconds: 60,
            iconData: Icons.nightlight_round,
            instruction:
                'Set a gentle intention for sleep. "I will rest deeply and '
                'wake refreshed." Place your phone down, close your eyes, '
                'and let the day go.',
          ),
        ],
        preferredTime: const TimeOfDay(hour: 22, minute: 0),
        isActive: true,
        createdAt: timeNow(),
      );
}

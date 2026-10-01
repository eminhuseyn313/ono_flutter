import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ArcLayer — the five transformation dimensions
// ---------------------------------------------------------------------------

enum ArcLayer { identity, habit, knowledge, challenge, reflection }

extension ArcLayerX on ArcLayer {
  String get emoji {
    switch (this) {
      case ArcLayer.identity:
        return '🪞';
      case ArcLayer.habit:
        return '🔥';
      case ArcLayer.knowledge:
        return '📚';
      case ArcLayer.challenge:
        return '⚔️';
      case ArcLayer.reflection:
        return '🌊';
    }
  }

  String get label {
    switch (this) {
      case ArcLayer.identity:
        return 'Identity';
      case ArcLayer.habit:
        return 'Habit';
      case ArcLayer.knowledge:
        return 'Knowledge';
      case ArcLayer.challenge:
        return 'Challenge';
      case ArcLayer.reflection:
        return 'Reflection';
    }
  }

  String get description {
    switch (this) {
      case ArcLayer.identity:
        return 'Who are you becoming? Affirmations and role model connection.';
      case ArcLayer.habit:
        return 'Daily actions and streak building that compound over time.';
      case ArcLayer.knowledge:
        return 'Learning content, reading, and micro-lessons to sharpen your mind.';
      case ArcLayer.challenge:
        return 'Push beyond your comfort zone with escalating difficulty.';
      case ArcLayer.reflection:
        return 'Journaling, self-assessment, and looking back at your growth.';
    }
  }

  Color get color {
    switch (this) {
      case ArcLayer.identity:
        return const Color(0xFFC8894A);
      case ArcLayer.habit:
        return const Color(0xFFD9774A);
      case ArcLayer.knowledge:
        return const Color(0xFF6A89B0);
      case ArcLayer.challenge:
        return const Color(0xFFE0605A);
      case ArcLayer.reflection:
        return const Color(0xFF6FA386);
    }
  }

  Color get dimColor => color.withValues(alpha: 0.3);

  Color get glowColor => color.withValues(alpha: 0.15);

  /// Hex string representation (without alpha).
  String get hexColor {
    switch (this) {
      case ArcLayer.identity:
        return '#8B5CF6';
      case ArcLayer.habit:
        return '#F97316';
      case ArcLayer.knowledge:
        return '#06B6D4';
      case ArcLayer.challenge:
        return '#EF4444';
      case ArcLayer.reflection:
        return '#10B981';
    }
  }
}

// ---------------------------------------------------------------------------
// ArcStep — a single action within a Becoming Arc
// ---------------------------------------------------------------------------

class ArcStep {
  final String id;
  final ArcLayer layer;
  final String title;
  final String description;
  final int dayNumber;
  final int difficulty;
  final bool isRequired;
  final String? actionPrompt;
  final Duration estimatedDuration;

  const ArcStep({
    required this.id,
    required this.layer,
    required this.title,
    required this.description,
    required this.dayNumber,
    this.difficulty = 1,
    this.isRequired = true,
    this.actionPrompt,
    this.estimatedDuration = const Duration(minutes: 10),
  }) : assert(difficulty >= 1 && difficulty <= 5);

  Map<String, dynamic> toJson() => {
        'id': id,
        'layer': layer.name,
        'title': title,
        'description': description,
        'dayNumber': dayNumber,
        'difficulty': difficulty,
        'isRequired': isRequired,
        'actionPrompt': actionPrompt,
        'estimatedDurationMinutes': estimatedDuration.inMinutes,
      };

  factory ArcStep.fromJson(Map<String, dynamic> json) => ArcStep(
        id: json['id'] as String,
        layer: ArcLayer.values.byName(json['layer'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        dayNumber: json['dayNumber'] as int,
        difficulty: json['difficulty'] as int? ?? 1,
        isRequired: json['isRequired'] as bool? ?? true,
        actionPrompt: json['actionPrompt'] as String?,
        estimatedDuration:
            Duration(minutes: json['estimatedDurationMinutes'] as int? ?? 10),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ArcStep && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ArcStep($id, day $dayNumber, ${layer.label})';
}

// ---------------------------------------------------------------------------
// BecomingArc — a 30-day transformation journey layered over a Journey
// ---------------------------------------------------------------------------

class BecomingArc {
  final String id;
  final String journeyId;
  final String title;
  final String description;
  final List<ArcStep> steps;
  final int totalDays;

  const BecomingArc({
    required this.id,
    required this.journeyId,
    required this.title,
    required this.description,
    required this.steps,
    this.totalDays = 30,
  });

  /// Steps scheduled for a given day.
  List<ArcStep> stepsForDay(int day) =>
      steps.where((s) => s.dayNumber == day).toList();

  /// All steps belonging to a specific layer.
  List<ArcStep> stepsForLayer(ArcLayer layer) =>
      steps.where((s) => s.layer == layer).toList();

  /// Unique layers that have at least one step.
  Set<ArcLayer> get activeLayers => steps.map((s) => s.layer).toSet();

  Map<String, dynamic> toJson() => {
        'id': id,
        'journeyId': journeyId,
        'title': title,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'totalDays': totalDays,
      };

  factory BecomingArc.fromJson(Map<String, dynamic> json) => BecomingArc(
        id: json['id'] as String,
        journeyId: json['journeyId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => ArcStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalDays: json['totalDays'] as int? ?? 30,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BecomingArc && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BecomingArc($id, ${steps.length} steps, $totalDays d)';
}

// ---------------------------------------------------------------------------
// SelfAssessment — periodic self-rating taken on milestone days
// ---------------------------------------------------------------------------

class SelfAssessment {
  final String id;
  final int dayNumber;
  final DateTime takenAt;
  final Map<ArcLayer, int> scores;
  final String? freeformNote;

  const SelfAssessment({
    required this.id,
    required this.dayNumber,
    required this.takenAt,
    required this.scores,
    this.freeformNote,
  });

  SelfAssessment copyWith({
    String? id,
    int? dayNumber,
    DateTime? takenAt,
    Map<ArcLayer, int>? scores,
    String? freeformNote,
  }) =>
      SelfAssessment(
        id: id ?? this.id,
        dayNumber: dayNumber ?? this.dayNumber,
        takenAt: takenAt ?? this.takenAt,
        scores: scores ?? this.scores,
        freeformNote: freeformNote ?? this.freeformNote,
      );

  /// Average score across all layers (1-10 scale).
  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.values.reduce((a, b) => a + b) / scores.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayNumber': dayNumber,
        'takenAt': takenAt.toIso8601String(),
        'scores': scores.map((k, v) => MapEntry(k.name, v)),
        'freeformNote': freeformNote,
      };

  factory SelfAssessment.fromJson(Map<String, dynamic> json) => SelfAssessment(
        id: json['id'] as String,
        dayNumber: json['dayNumber'] as int,
        takenAt: DateTime.parse(json['takenAt'] as String),
        scores: (json['scores'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(ArcLayer.values.byName(k), v as int),
        ),
        freeformNote: json['freeformNote'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SelfAssessment && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SelfAssessment($id, day $dayNumber, avg ${averageScore.toStringAsFixed(1)})';
}

// ---------------------------------------------------------------------------
// UserArcProgress — tracks a user's state within a Becoming Arc
// ---------------------------------------------------------------------------

class UserArcProgress {
  final String id;
  final String userId;
  final String arcId;
  final int currentDay;
  final Map<String, bool> completedSteps;
  final Map<ArcLayer, double> layerScores;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<SelfAssessment> assessments;

  const UserArcProgress({
    required this.id,
    required this.userId,
    required this.arcId,
    this.currentDay = 1,
    this.completedSteps = const {},
    this.layerScores = const {},
    required this.startedAt,
    this.completedAt,
    this.assessments = const [],
  });

  UserArcProgress copyWith({
    String? id,
    String? userId,
    String? arcId,
    int? currentDay,
    Map<String, bool>? completedSteps,
    Map<ArcLayer, double>? layerScores,
    DateTime? startedAt,
    DateTime? completedAt,
    List<SelfAssessment>? assessments,
  }) =>
      UserArcProgress(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        arcId: arcId ?? this.arcId,
        currentDay: currentDay ?? this.currentDay,
        completedSteps: completedSteps ?? this.completedSteps,
        layerScores: layerScores ?? this.layerScores,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        assessments: assessments ?? this.assessments,
      );

  /// Overall progress as a 0.0 – 1.0 fraction.
  double get overallProgress {
    if (completedSteps.isEmpty) return 0;
    final done = completedSteps.values.where((v) => v).length;
    return done / completedSteps.length;
  }

  /// Whether every required step has been completed.
  bool get isComplete => completedAt != null;

  /// Number of steps finished.
  int get completedStepCount =>
      completedSteps.values.where((v) => v).length;

  /// Number of elapsed days since start (clamped to 1+).
  int get elapsedDays {
    final diff = DateTime.now().difference(startedAt).inDays;
    return diff < 1 ? 1 : diff;
  }

  /// Progress for a single layer (falls back to 0).
  double layerProgress(ArcLayer layer) => layerScores[layer] ?? 0.0;

  /// The next assessment milestone day (1, 15, or 30) or null if all taken.
  int? get nextAssessmentDay {
    const milestones = [1, 15, 30];
    final taken = assessments.map((a) => a.dayNumber).toSet();
    for (final m in milestones) {
      if (!taken.contains(m) && currentDay >= m) return m;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'arcId': arcId,
        'currentDay': currentDay,
        'completedSteps': completedSteps,
        'layerScores': layerScores.map((k, v) => MapEntry(k.name, v)),
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'assessments': assessments.map((a) => a.toJson()).toList(),
      };

  factory UserArcProgress.fromJson(Map<String, dynamic> json) =>
      UserArcProgress(
        id: json['id'] as String,
        userId: json['userId'] as String,
        arcId: json['arcId'] as String,
        currentDay: json['currentDay'] as int? ?? 1,
        completedSteps:
            Map<String, bool>.from(json['completedSteps'] as Map? ?? {}),
        layerScores:
            (json['layerScores'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            ArcLayer.values.byName(k),
            (v as num).toDouble(),
          ),
        ),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        assessments: (json['assessments'] as List<dynamic>?)
                ?.map((e) => SelfAssessment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserArcProgress && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserArcProgress($id, day $currentDay, '
      '${(overallProgress * 100).toStringAsFixed(0)}%)';
}

// ---------------------------------------------------------------------------
// Pre-built arcs — one per flagship journey
// ---------------------------------------------------------------------------

class PrebuiltArcs {
  PrebuiltArcs._();

  // -------------------------------------------------------------------------
  // Kobe Bryant — Mamba Mentality
  // -------------------------------------------------------------------------
  static const kobeArc = BecomingArc(
    id: 'arc_kobe_mamba',
    journeyId: 'journey_kobe',
    title: 'Mamba Mentality',
    description:
        'Channel Kobe\'s relentless work ethic, obsessive preparation, '
        'and killer instinct into every area of your life.',
    totalDays: 30,
    steps: [
      // — Day 1: kickoff across layers —
      ArcStep(
        id: 'kobe_id_01',
        layer: ArcLayer.identity,
        title: 'Define Your Mamba Identity',
        description:
            'Write down the version of yourself you are building toward. '
            'What does your "Mamba Mentality" look like in your field?',
        dayNumber: 1,
        difficulty: 1,
        actionPrompt: 'Write a one-paragraph identity statement.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'kobe_ref_01',
        layer: ArcLayer.reflection,
        title: 'Baseline Self-Assessment',
        description:
            'Rate yourself honestly across all five layers before the journey '
            'begins. This is your starting snapshot.',
        dayNumber: 1,
        difficulty: 1,
        actionPrompt: 'Complete the Day-1 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // — Days 2-5 —
      ArcStep(
        id: 'kobe_hab_01',
        layer: ArcLayer.habit,
        title: 'Wake Up Before Everyone',
        description:
            'Kobe was in the gym at 4 AM. Set your alarm 1 hour earlier '
            'than usual and use that time for focused work.',
        dayNumber: 2,
        difficulty: 2,
        actionPrompt: 'Set your alarm and log your wake-up time.',
        estimatedDuration: Duration(minutes: 5),
      ),
      ArcStep(
        id: 'kobe_kn_01',
        layer: ArcLayer.knowledge,
        title: 'Study the Greats',
        description:
            'Read about or watch one interview with someone at the top of '
            'your craft. Note three techniques they use.',
        dayNumber: 3,
        difficulty: 1,
        actionPrompt: 'Log three techniques you learned.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'kobe_ch_01',
        layer: ArcLayer.challenge,
        title: 'Double Your Reps',
        description:
            'Whatever your main practice session looks like, do twice the '
            'volume today. Push through the discomfort.',
        dayNumber: 4,
        difficulty: 3,
        actionPrompt: 'Record what you doubled and how it felt.',
        estimatedDuration: Duration(minutes: 45),
      ),
      ArcStep(
        id: 'kobe_id_02',
        layer: ArcLayer.identity,
        title: 'Morning Affirmation Ritual',
        description:
            'Speak your identity statement aloud each morning this week. '
            'Repetition wires belief.',
        dayNumber: 5,
        difficulty: 1,
        actionPrompt: 'Confirm you spoke your affirmation aloud.',
        estimatedDuration: Duration(minutes: 5),
      ),

      // — Days 6-10 —
      ArcStep(
        id: 'kobe_hab_02',
        layer: ArcLayer.habit,
        title: 'Film Study Session',
        description:
            'Kobe watched film obsessively. Spend 20 minutes reviewing '
            'your own recent work and noting weak spots.',
        dayNumber: 7,
        difficulty: 2,
        actionPrompt: 'List three weak spots you identified.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'kobe_kn_02',
        layer: ArcLayer.knowledge,
        title: 'Cross-Domain Learning',
        description:
            'Kobe studied sharks, Mozart, and military strategy. Read '
            'something outside your field and extract one transferable idea.',
        dayNumber: 8,
        difficulty: 2,
        actionPrompt: 'Write down the cross-domain insight.',
        estimatedDuration: Duration(minutes: 25),
      ),
      ArcStep(
        id: 'kobe_ch_02',
        layer: ArcLayer.challenge,
        title: 'Cold Exposure',
        description:
            'End your shower with 90 seconds of cold water. Mental '
            'toughness starts with small discomforts.',
        dayNumber: 9,
        difficulty: 2,
        actionPrompt: 'Log the duration of your cold exposure.',
        estimatedDuration: Duration(minutes: 5),
      ),
      ArcStep(
        id: 'kobe_ref_02',
        layer: ArcLayer.reflection,
        title: 'Week-1 Journal',
        description:
            'Reflect on your first week. What surprised you? Where did you '
            'resist? Where did you break through?',
        dayNumber: 10,
        difficulty: 1,
        actionPrompt: 'Write a half-page journal entry.',
        estimatedDuration: Duration(minutes: 15),
      ),

      // — Days 11-15 —
      ArcStep(
        id: 'kobe_id_03',
        layer: ArcLayer.identity,
        title: 'Eliminate One Distraction',
        description:
            'Identify your biggest time-waster and cut it for the rest '
            'of this arc. Kobe said no to everything that wasn\'t basketball.',
        dayNumber: 12,
        difficulty: 3,
        actionPrompt: 'Name the distraction and delete or block it.',
        estimatedDuration: Duration(minutes: 10),
      ),
      ArcStep(
        id: 'kobe_hab_03',
        layer: ArcLayer.habit,
        title: 'Stack a Second Session',
        description:
            'Add a second focused work block to your day. Even 30 minutes '
            'compounds over weeks.',
        dayNumber: 13,
        difficulty: 3,
        actionPrompt: 'Log the time and focus of your second session.',
        estimatedDuration: Duration(minutes: 30),
      ),
      ArcStep(
        id: 'kobe_ch_03',
        layer: ArcLayer.challenge,
        title: 'Public Performance',
        description:
            'Do your craft in front of others — present, perform, compete. '
            'Pressure reveals and refines.',
        dayNumber: 14,
        difficulty: 4,
        actionPrompt: 'Describe the experience and what you learned.',
        estimatedDuration: Duration(minutes: 60),
      ),
      ArcStep(
        id: 'kobe_ref_03',
        layer: ArcLayer.reflection,
        title: 'Mid-Arc Assessment',
        description:
            'Take the Day-15 self-assessment. Compare with Day 1.',
        dayNumber: 15,
        difficulty: 1,
        actionPrompt: 'Complete the Day-15 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // — Days 16-25 —
      ArcStep(
        id: 'kobe_kn_03',
        layer: ArcLayer.knowledge,
        title: 'Teach Someone',
        description:
            'The best way to learn is to teach. Explain a concept from your '
            'craft to someone who knows less than you.',
        dayNumber: 18,
        difficulty: 2,
        actionPrompt: 'Who did you teach and what did you explain?',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'kobe_ch_04',
        layer: ArcLayer.challenge,
        title: 'Simulate Failure',
        description:
            'Put yourself in a scenario where you will likely fail. '
            'Kobe practiced shots he couldn\'t make — yet.',
        dayNumber: 22,
        difficulty: 4,
        actionPrompt: 'Describe the scenario and what failure taught you.',
        estimatedDuration: Duration(minutes: 30),
      ),
      ArcStep(
        id: 'kobe_hab_04',
        layer: ArcLayer.habit,
        title: 'Recovery Protocol',
        description:
            'Elite performers recover like pros. Build a 20-minute wind-down '
            'routine: stretch, breathe, review tomorrow\'s plan.',
        dayNumber: 24,
        difficulty: 2,
        actionPrompt: 'Log your recovery routine steps.',
        estimatedDuration: Duration(minutes: 20),
      ),

      // — Days 26-30: crescendo —
      ArcStep(
        id: 'kobe_id_04',
        layer: ArcLayer.identity,
        title: 'Rewrite Your Identity Statement',
        description:
            'Revisit your Day-1 identity statement. Rewrite it with '
            'everything you have learned about yourself.',
        dayNumber: 27,
        difficulty: 2,
        actionPrompt: 'Write your updated identity statement.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'kobe_ch_05',
        layer: ArcLayer.challenge,
        title: 'The 81-Point Day',
        description:
            'Go all-out. Dedicate an entire day to your craft — maximum '
            'effort, zero distractions, Mamba mode.',
        dayNumber: 28,
        difficulty: 5,
        actionPrompt: 'Describe your 81-point day in detail.',
        estimatedDuration: Duration(minutes: 480),
      ),
      ArcStep(
        id: 'kobe_ref_04',
        layer: ArcLayer.reflection,
        title: 'Final Self-Assessment',
        description:
            'Complete the Day-30 assessment. See how far you have come.',
        dayNumber: 30,
        difficulty: 1,
        actionPrompt: 'Complete the Day-30 self-assessment.',
        estimatedDuration: Duration(minutes: 15),
      ),
    ],
  );

  // -------------------------------------------------------------------------
  // David Goggins — Uncommon Amongst Uncommon
  // -------------------------------------------------------------------------
  static const gogginsArc = BecomingArc(
    id: 'arc_goggins_uncommon',
    journeyId: 'journey_goggins',
    title: 'Uncommon Amongst Uncommon',
    description:
        'Callous your mind, embrace suffering, and unlock the 40%% rule. '
        'Goggins-level mental fortitude in 30 days.',
    totalDays: 30,
    steps: [
      // Day 1
      ArcStep(
        id: 'gog_id_01',
        layer: ArcLayer.identity,
        title: 'The Accountability Mirror',
        description:
            'Write Post-it notes of hard truths about yourself and stick '
            'them on your mirror. Face who you are right now.',
        dayNumber: 1,
        difficulty: 2,
        actionPrompt: 'List at least five truths on your mirror.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_ref_01',
        layer: ArcLayer.reflection,
        title: 'Baseline Check-In',
        description: 'Complete the Day-1 self-assessment honestly.',
        dayNumber: 1,
        difficulty: 1,
        actionPrompt: 'Complete the Day-1 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // Days 2-7
      ArcStep(
        id: 'gog_hab_01',
        layer: ArcLayer.habit,
        title: 'Run a Mile Every Morning',
        description:
            'No excuses. Lace up and run one mile before anything else. '
            'Rain, snow, tired — it doesn\'t matter.',
        dayNumber: 2,
        difficulty: 2,
        actionPrompt: 'Log your run time.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'gog_kn_01',
        layer: ArcLayer.knowledge,
        title: 'The 40% Rule',
        description:
            'Read about the 40%% rule: when your mind says you are done, '
            'you are only at 40%%. Journal about a time this was true for you.',
        dayNumber: 3,
        difficulty: 1,
        actionPrompt: 'Write about a time you had more left in the tank.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'gog_ch_01',
        layer: ArcLayer.challenge,
        title: 'Do What You Hate',
        description:
            'Pick the task you have been avoiding the most. Do it first '
            'thing. Goggins runs toward suffering.',
        dayNumber: 5,
        difficulty: 3,
        actionPrompt: 'Name the task and confirm you completed it.',
        estimatedDuration: Duration(minutes: 30),
      ),
      ArcStep(
        id: 'gog_id_02',
        layer: ArcLayer.identity,
        title: 'Cookie Jar',
        description:
            'List every hard thing you have ever overcome. This is your '
            'cookie jar — pull from it when things get tough.',
        dayNumber: 6,
        difficulty: 1,
        actionPrompt: 'Write at least ten past victories.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_ref_02',
        layer: ArcLayer.reflection,
        title: 'Week-1 Suffering Log',
        description:
            'Write about every moment this week where you wanted to quit. '
            'What kept you going?',
        dayNumber: 7,
        difficulty: 1,
        actionPrompt: 'Write a detailed suffering log.',
        estimatedDuration: Duration(minutes: 15),
      ),

      // Days 8-14
      ArcStep(
        id: 'gog_hab_02',
        layer: ArcLayer.habit,
        title: 'Add 100 Push-Ups',
        description:
            'On top of your morning run, do 100 push-ups throughout the day. '
            'Break them into sets if needed.',
        dayNumber: 9,
        difficulty: 3,
        actionPrompt: 'Log your total push-ups and sets.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_kn_02',
        layer: ArcLayer.knowledge,
        title: 'Study Mental Toughness Research',
        description:
            'Read one article or chapter on the psychology of grit and '
            'resilience. Note three scientific findings.',
        dayNumber: 10,
        difficulty: 1,
        actionPrompt: 'List three findings from your reading.',
        estimatedDuration: Duration(minutes: 25),
      ),
      ArcStep(
        id: 'gog_ch_02',
        layer: ArcLayer.challenge,
        title: '5K Without Stopping',
        description:
            'Run or walk a 5K without stopping. Time yourself. This is '
            'your benchmark.',
        dayNumber: 12,
        difficulty: 3,
        actionPrompt: 'Log your 5K time.',
        estimatedDuration: Duration(minutes: 40),
      ),
      ArcStep(
        id: 'gog_ref_03',
        layer: ArcLayer.reflection,
        title: 'Mid-Arc Assessment',
        description:
            'Take the Day-15 self-assessment and compare with Day 1.',
        dayNumber: 15,
        difficulty: 1,
        actionPrompt: 'Complete the Day-15 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // Days 16-25
      ArcStep(
        id: 'gog_id_03',
        layer: ArcLayer.identity,
        title: 'Rewrite Your Story',
        description:
            'Write a new narrative about who you are. Not where you came '
            'from — where you are going.',
        dayNumber: 17,
        difficulty: 2,
        actionPrompt: 'Write your new story in one page.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_ch_03',
        layer: ArcLayer.challenge,
        title: 'The Impossible Task',
        description:
            'Attempt something you believe you cannot do. A longer run, '
            'a harder problem, a bigger ask. Fail forward.',
        dayNumber: 20,
        difficulty: 4,
        actionPrompt: 'Describe the attempt and the outcome.',
        estimatedDuration: Duration(minutes: 60),
      ),
      ArcStep(
        id: 'gog_kn_03',
        layer: ArcLayer.knowledge,
        title: 'Learn From a Warrior',
        description:
            'Study a military leader or endurance athlete. Extract three '
            'principles you can apply to your own life.',
        dayNumber: 22,
        difficulty: 2,
        actionPrompt: 'List the three principles.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_hab_03',
        layer: ArcLayer.habit,
        title: 'No Comfort for 24 Hours',
        description:
            'No social media, no junk food, no entertainment. Just work, '
            'training, and silence for a full day.',
        dayNumber: 25,
        difficulty: 4,
        actionPrompt: 'Log everything you did and did not do.',
        estimatedDuration: Duration(minutes: 5),
      ),

      // Days 26-30
      ArcStep(
        id: 'gog_ch_04',
        layer: ArcLayer.challenge,
        title: 'Beat Your 5K',
        description:
            'Run or walk the 5K again. Beat your Day-12 time. Prove you '
            'have grown.',
        dayNumber: 28,
        difficulty: 4,
        actionPrompt: 'Log your new 5K time.',
        estimatedDuration: Duration(minutes: 40),
      ),
      ArcStep(
        id: 'gog_id_04',
        layer: ArcLayer.identity,
        title: 'Who\'s Going to Carry the Boats?',
        description:
            'Write a letter to the person you were on Day 1 from the '
            'person you are now.',
        dayNumber: 29,
        difficulty: 2,
        actionPrompt: 'Write the letter.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'gog_ref_04',
        layer: ArcLayer.reflection,
        title: 'Final Self-Assessment',
        description:
            'Complete the Day-30 assessment. Measure the distance traveled.',
        dayNumber: 30,
        difficulty: 1,
        actionPrompt: 'Complete the Day-30 self-assessment.',
        estimatedDuration: Duration(minutes: 15),
      ),
    ],
  );

  // -------------------------------------------------------------------------
  // Marcus Aurelius — The Philosopher King
  // -------------------------------------------------------------------------
  static const aureliusArc = BecomingArc(
    id: 'arc_aurelius_philosopher',
    journeyId: 'journey_aurelius',
    title: 'The Philosopher King',
    description:
        'Master your mind through Stoic discipline, reflective journaling, '
        'and deliberate virtue. Rule yourself first.',
    totalDays: 30,
    steps: [
      // Day 1
      ArcStep(
        id: 'aur_id_01',
        layer: ArcLayer.identity,
        title: 'Choose Your Virtues',
        description:
            'Marcus lived by four virtues: wisdom, courage, justice, '
            'temperance. Pick four guiding virtues for your own life.',
        dayNumber: 1,
        difficulty: 1,
        actionPrompt: 'Write down your four virtues and why each matters.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'aur_ref_01',
        layer: ArcLayer.reflection,
        title: 'Baseline Self-Assessment',
        description: 'Complete the Day-1 self-assessment.',
        dayNumber: 1,
        difficulty: 1,
        actionPrompt: 'Complete the Day-1 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // Days 2-7
      ArcStep(
        id: 'aur_hab_01',
        layer: ArcLayer.habit,
        title: 'Morning Premeditatio',
        description:
            'Each morning, spend five minutes visualizing the obstacles '
            'you may face today and how you will respond with virtue.',
        dayNumber: 2,
        difficulty: 1,
        actionPrompt: 'Describe three obstacles you visualized.',
        estimatedDuration: Duration(minutes: 10),
      ),
      ArcStep(
        id: 'aur_kn_01',
        layer: ArcLayer.knowledge,
        title: 'Read Meditations Book I',
        description:
            'Read Book I of Marcus Aurelius\' Meditations. Note three '
            'lessons that resonate with your life right now.',
        dayNumber: 3,
        difficulty: 1,
        actionPrompt: 'List three lessons and why they resonate.',
        estimatedDuration: Duration(minutes: 25),
      ),
      ArcStep(
        id: 'aur_ch_01',
        layer: ArcLayer.challenge,
        title: 'Voluntary Discomfort',
        description:
            'Skip a meal, sleep on the floor, or take a cold shower. '
            'Practice needing less than you have.',
        dayNumber: 5,
        difficulty: 2,
        actionPrompt: 'Describe the discomfort you chose and what you noticed.',
        estimatedDuration: Duration(minutes: 5),
      ),
      ArcStep(
        id: 'aur_ref_02',
        layer: ArcLayer.reflection,
        title: 'Evening Review',
        description:
            'Before sleep, review your day through the lens of your four '
            'virtues. Where did you live up? Where did you fall short?',
        dayNumber: 7,
        difficulty: 1,
        actionPrompt: 'Write a virtue-based evening review.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // Days 8-14
      ArcStep(
        id: 'aur_id_02',
        layer: ArcLayer.identity,
        title: 'Memento Mori',
        description:
            'Meditate on your mortality for five minutes. How does '
            'awareness of death sharpen how you want to live?',
        dayNumber: 8,
        difficulty: 2,
        actionPrompt: 'Write what this meditation revealed.',
        estimatedDuration: Duration(minutes: 10),
      ),
      ArcStep(
        id: 'aur_kn_02',
        layer: ArcLayer.knowledge,
        title: 'Study Epictetus\' Dichotomy of Control',
        description:
            'Read about the dichotomy of control. List five things in '
            'your life that are within your control and five that are not.',
        dayNumber: 10,
        difficulty: 1,
        actionPrompt: 'Create your two-column control list.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'aur_hab_02',
        layer: ArcLayer.habit,
        title: 'Journaling Practice',
        description:
            'Write one page each evening — raw thoughts, unfiltered. '
            'Marcus wrote the Meditations for himself, not an audience.',
        dayNumber: 11,
        difficulty: 1,
        actionPrompt: 'Write one full page in your journal.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'aur_ch_02',
        layer: ArcLayer.challenge,
        title: 'Respond, Don\'t React',
        description:
            'The next time someone frustrates you today, pause for ten '
            'seconds before responding. Choose reason over emotion.',
        dayNumber: 13,
        difficulty: 3,
        actionPrompt: 'Describe the situation and your deliberate response.',
        estimatedDuration: Duration(minutes: 5),
      ),
      ArcStep(
        id: 'aur_ref_03',
        layer: ArcLayer.reflection,
        title: 'Mid-Arc Assessment',
        description: 'Take the Day-15 self-assessment. Compare with Day 1.',
        dayNumber: 15,
        difficulty: 1,
        actionPrompt: 'Complete the Day-15 self-assessment.',
        estimatedDuration: Duration(minutes: 10),
      ),

      // Days 16-25
      ArcStep(
        id: 'aur_id_03',
        layer: ArcLayer.identity,
        title: 'Amor Fati',
        description:
            'Write about a past setback. Reframe it: how did it serve '
            'your growth? Love your fate — all of it.',
        dayNumber: 18,
        difficulty: 2,
        actionPrompt: 'Reframe one setback as a gift.',
        estimatedDuration: Duration(minutes: 15),
      ),
      ArcStep(
        id: 'aur_kn_03',
        layer: ArcLayer.knowledge,
        title: 'Seneca on Time',
        description:
            'Read Seneca\'s "On the Shortness of Life." Extract three '
            'ideas about how you can reclaim wasted time.',
        dayNumber: 20,
        difficulty: 2,
        actionPrompt: 'List three time-reclaiming ideas.',
        estimatedDuration: Duration(minutes: 25),
      ),
      ArcStep(
        id: 'aur_ch_03',
        layer: ArcLayer.challenge,
        title: 'A Day of Silence',
        description:
            'Speak only when spoken to for an entire day. Observe how much '
            'noise you usually add to the world.',
        dayNumber: 22,
        difficulty: 4,
        actionPrompt: 'Reflect on what silence taught you.',
        estimatedDuration: Duration(minutes: 5),
      ),
      ArcStep(
        id: 'aur_hab_03',
        layer: ArcLayer.habit,
        title: 'Gratitude Inventory',
        description:
            'Each morning, write three things you are genuinely grateful '
            'for. Not platitudes — specific, real things.',
        dayNumber: 24,
        difficulty: 1,
        actionPrompt: 'List today\'s three gratitudes.',
        estimatedDuration: Duration(minutes: 5),
      ),

      // Days 26-30
      ArcStep(
        id: 'aur_ch_04',
        layer: ArcLayer.challenge,
        title: 'Forgive Someone',
        description:
            'Think of someone who wronged you. Write a letter of '
            'forgiveness — you never have to send it.',
        dayNumber: 27,
        difficulty: 4,
        actionPrompt: 'Write the forgiveness letter.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'aur_id_04',
        layer: ArcLayer.identity,
        title: 'Your Meditations',
        description:
            'Write your own page of Meditations — maxims for the person '
            'you are becoming.',
        dayNumber: 29,
        difficulty: 2,
        actionPrompt: 'Write at least ten personal maxims.',
        estimatedDuration: Duration(minutes: 20),
      ),
      ArcStep(
        id: 'aur_ref_04',
        layer: ArcLayer.reflection,
        title: 'Final Self-Assessment',
        description:
            'Complete the Day-30 assessment. Measure inner growth.',
        dayNumber: 30,
        difficulty: 1,
        actionPrompt: 'Complete the Day-30 self-assessment.',
        estimatedDuration: Duration(minutes: 15),
      ),
    ],
  );

  /// All pre-built arcs indexed by arc id.
  static const Map<String, BecomingArc> byId = {
    'arc_kobe_mamba': kobeArc,
    'arc_goggins_uncommon': gogginsArc,
    'arc_aurelius_philosopher': aureliusArc,
  };

  /// All pre-built arcs indexed by journey id.
  static const Map<String, BecomingArc> byJourneyId = {
    'journey_kobe': kobeArc,
    'journey_goggins': gogginsArc,
    'journey_aurelius': aureliusArc,
  };

  /// All pre-built arcs as an unmodifiable list.
  static const List<BecomingArc> all = [kobeArc, gogginsArc, aureliusArc];
}

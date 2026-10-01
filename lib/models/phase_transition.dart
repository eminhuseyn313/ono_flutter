import 'package:flutter/material.dart';

import '../models/becoming_arc.dart';

// ---------------------------------------------------------------------------
// PhaseTransition — payload for the celebration screen
// ---------------------------------------------------------------------------

class PhaseTransition {
  final int fromPhase;
  final int toPhase;
  final String arcId;
  final DateTime unlockedAt;
  final String milestoneTitle;
  final String milestoneDescription;
  final List<String> rewards;

  const PhaseTransition({
    required this.fromPhase,
    required this.toPhase,
    required this.arcId,
    required this.unlockedAt,
    required this.milestoneTitle,
    required this.milestoneDescription,
    this.rewards = const [],
  });

  Map<String, dynamic> toJson() => {
        'fromPhase': fromPhase,
        'toPhase': toPhase,
        'arcId': arcId,
        'unlockedAt': unlockedAt.toIso8601String(),
        'milestoneTitle': milestoneTitle,
        'milestoneDescription': milestoneDescription,
        'rewards': rewards,
      };

  factory PhaseTransition.fromJson(Map<String, dynamic> json) =>
      PhaseTransition(
        fromPhase: json['fromPhase'] as int,
        toPhase: json['toPhase'] as int,
        arcId: json['arcId'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        milestoneTitle: json['milestoneTitle'] as String,
        milestoneDescription: json['milestoneDescription'] as String,
        rewards: List<String>.from(json['rewards'] as List? ?? []),
      );
}

// ---------------------------------------------------------------------------
// ArcPhaseInfo — metadata for one of the three arc phases
// ---------------------------------------------------------------------------

class ArcPhaseInfo {
  final int phaseNumber;
  final String title;
  final String dayRange;
  final String description;
  final Color themeColor;

  const ArcPhaseInfo({
    required this.phaseNumber,
    required this.title,
    required this.dayRange,
    required this.description,
    required this.themeColor,
  });

  /// All three phases in a 30-day Becoming Arc.
  static const List<ArcPhaseInfo> phases = [
    ArcPhaseInfo(
      phaseNumber: 1,
      title: 'Foundation',
      dayRange: '1-10',
      description:
          'Lay the groundwork. Build awareness, set intentions, and '
          'establish the daily rhythms that will carry you forward.',
      themeColor: Color(0xFF8B5CF6), // purple — identity / start
    ),
    ArcPhaseInfo(
      phaseNumber: 2,
      title: 'Growth',
      dayRange: '11-20',
      description:
          'Intensify your practice. Challenge yourself, deepen knowledge, '
          'and turn early habits into unshakeable patterns.',
      themeColor: Color(0xFF06B6D4), // cyan — knowledge / expansion
    ),
    ArcPhaseInfo(
      phaseNumber: 3,
      title: 'Mastery',
      dayRange: '21-30',
      description:
          'Push to the peak. Integrate all layers, face your hardest '
          'challenges, and solidify the person you have become.',
      themeColor: Color(0xFFF97316), // orange — habit / fire
    ),
  ];

  /// Returns the [ArcPhaseInfo] for a given 1-based [day] (clamped to 1–30).
  static ArcPhaseInfo phaseForDay(int day) {
    if (day <= 10) return phases[0];
    if (day <= 20) return phases[1];
    return phases[2];
  }

  /// Returns the 1-based phase number for a given [day].
  static int phaseNumberForDay(int day) => phaseForDay(day).phaseNumber;
}

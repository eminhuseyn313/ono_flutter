import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The six lifetime tiers of the Legacy Score system.
///
/// Score never decreases, so a user's tier is a one-way ratchet forward.
enum LegacyTier {
  initiate,
  apprentice,
  warrior,
  master,
  legend,
  legacy,
}

/// Static metadata (name, description, bounds, color) for each [LegacyTier].
extension LegacyTierData on LegacyTier {
  String get label {
    switch (this) {
      case LegacyTier.initiate:
        return 'Initiate';
      case LegacyTier.apprentice:
        return 'Apprentice';
      case LegacyTier.warrior:
        return 'Warrior';
      case LegacyTier.master:
        return 'Master';
      case LegacyTier.legend:
        return 'Legend';
      case LegacyTier.legacy:
        return 'Legacy';
    }
  }

  String get description {
    switch (this) {
      case LegacyTier.initiate:
        return 'The journey begins';
      case LegacyTier.apprentice:
        return 'Building the foundation';
      case LegacyTier.warrior:
        return 'Discipline is becoming habit';
      case LegacyTier.master:
        return "You're uncommon among uncommon";
      case LegacyTier.legend:
        return 'Your transformation inspires others';
      case LegacyTier.legacy:
        return "You've invested more in yourself than 99.9% of people";
    }
  }

  String get emoji {
    switch (this) {
      case LegacyTier.initiate:
        return '🌱';
      case LegacyTier.apprentice:
        return '🔨';
      case LegacyTier.warrior:
        return '⚔️';
      case LegacyTier.master:
        return '🎯';
      case LegacyTier.legend:
        return '🔥';
      case LegacyTier.legacy:
        return '👑';
    }
  }

  int get minScore {
    switch (this) {
      case LegacyTier.initiate:
        return 0;
      case LegacyTier.apprentice:
        return 101;
      case LegacyTier.warrior:
        return 501;
      case LegacyTier.master:
        return 1501;
      case LegacyTier.legend:
        return 5001;
      case LegacyTier.legacy:
        return 15001;
    }
  }

  /// Inclusive upper bound; `null` for the top tier (unbounded).
  int? get maxScore {
    switch (this) {
      case LegacyTier.initiate:
        return 100;
      case LegacyTier.apprentice:
        return 500;
      case LegacyTier.warrior:
        return 1500;
      case LegacyTier.master:
        return 5000;
      case LegacyTier.legend:
        return 15000;
      case LegacyTier.legacy:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case LegacyTier.initiate:
        return AppColors.grey;
      case LegacyTier.apprentice:
        return AppColors.cyan;
      case LegacyTier.warrior:
        return AppColors.green;
      case LegacyTier.master:
        return AppColors.purple;
      case LegacyTier.legend:
        return AppColors.purpleSoft;
      case LegacyTier.legacy:
        return AppColors.warning;
    }
  }

  /// The tier that follows this one, or `null` if this is the highest tier.
  LegacyTier? get next {
    final values = LegacyTier.values;
    final index = values.indexOf(this);
    if (index == values.length - 1) return null;
    return values[index + 1];
  }

  /// Resolve the tier for a given lifetime score.
  static LegacyTier forScore(int score) {
    for (final tier in LegacyTier.values.reversed) {
      if (score >= tier.minScore) return tier;
    }
    return LegacyTier.initiate;
  }
}

/// A user's lifetime Legacy Score — never decreases.
class LegacyScore {
  final String userId;
  final int totalScore;
  final LegacyTier currentTier;
  final DateTime updatedAt;

  const LegacyScore({
    required this.userId,
    required this.totalScore,
    required this.currentTier,
    required this.updatedAt,
  });

  /// Progress toward the next tier, 0.0-1.0. 1.0 (maxed) at the top tier.
  double get progressToNextTier {
    final next = currentTier.next;
    if (next == null) return 1.0;
    final span = next.minScore - currentTier.minScore;
    if (span <= 0) return 1.0;
    final progressed = totalScore - currentTier.minScore;
    return (progressed / span).clamp(0.0, 1.0);
  }

  /// Points remaining to unlock the next tier, or 0 at the top tier.
  int get pointsToNextTier {
    final next = currentTier.next;
    if (next == null) return 0;
    return (next.minScore - totalScore).clamp(0, next.minScore);
  }

  LegacyScore copyWith({
    String? userId,
    int? totalScore,
    LegacyTier? currentTier,
    DateTime? updatedAt,
  }) {
    return LegacyScore(
      userId: userId ?? this.userId,
      totalScore: totalScore ?? this.totalScore,
      currentTier: currentTier ?? this.currentTier,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalScore': totalScore,
      'currentTier': currentTier.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LegacyScore.fromJson(Map<String, dynamic> json) {
    return LegacyScore(
      userId: json['userId'] as String,
      totalScore: json['totalScore'] as int,
      currentTier: LegacyTier.values.firstWhere(
        (t) => t.name == json['currentTier'],
        orElse: () => LegacyTier.initiate,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() =>
      'LegacyScore(userId: $userId, score: $totalScore, tier: ${currentTier.label})';
}

/// Defines how many points a given action type is worth.
class ActionWeight {
  final String actionType;
  final int points;
  final String label;

  const ActionWeight({
    required this.actionType,
    required this.points,
    required this.label,
  });

  /// Canonical weights for every known action type.
  static const Map<String, ActionWeight> catalog = {
    'meditation_10min': ActionWeight(
      actionType: 'meditation_10min',
      points: 15,
      label: '10-Min Meditation',
    ),
    'pushups_50': ActionWeight(
      actionType: 'pushups_50',
      points: 10,
      label: '50 Push-Ups',
    ),
    'read_30min': ActionWeight(
      actionType: 'read_30min',
      points: 20,
      label: '30-Min Reading',
    ),
    'social_connection': ActionWeight(
      actionType: 'social_connection',
      points: 12,
      label: 'Social Connection',
    ),
    'skill_practice': ActionWeight(
      actionType: 'skill_practice',
      points: 18,
      label: 'Skill Practice',
    ),
    'journal_entry': ActionWeight(
      actionType: 'journal_entry',
      points: 8,
      label: 'Journal Entry',
    ),
  };

  /// Default weight applied to any unrecognized action type.
  static const ActionWeight fallback = ActionWeight(
    actionType: 'default',
    points: 5,
    label: 'Action',
  );

  static ActionWeight resolve(String actionType) {
    return catalog[actionType] ?? fallback;
  }
}

/// One entry in a user's point-earning history — an action that scored points.
class LegacyScoreEvent {
  final String id;
  final String actionType;
  final String label;
  final int points;
  final DateTime earnedAt;

  const LegacyScoreEvent({
    required this.id,
    required this.actionType,
    required this.label,
    required this.points,
    required this.earnedAt,
  });
}

/// A score-threshold reward the user unlocks along their lifetime journey.
class LegacyMilestone {
  final int scoreThreshold;
  final String title;
  final String description;
  final bool isUnlocked;

  const LegacyMilestone({
    required this.scoreThreshold,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  LegacyMilestone copyWith({
    int? scoreThreshold,
    String? title,
    String? description,
    bool? isUnlocked,
  }) {
    return LegacyMilestone(
      scoreThreshold: scoreThreshold ?? this.scoreThreshold,
      title: title ?? this.title,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  /// The three canonical milestones defined by the Legacy Score spec.
  static List<LegacyMilestone> defaults({int currentScore = 0}) {
    const definitions = [
      (threshold: 1000, title: 'Special Theme', description: 'Unlock an exclusive app theme'),
      (threshold: 5000, title: 'Mentor Mode', description: 'Unlock the Mentor Mode badge'),
      (threshold: 10000, title: 'Custom Badge', description: 'Unlock a custom profile badge'),
    ];
    return definitions
        .map((d) => LegacyMilestone(
              scoreThreshold: d.threshold,
              title: d.title,
              description: d.description,
              isUnlocked: currentScore >= d.threshold,
            ))
        .toList();
  }
}

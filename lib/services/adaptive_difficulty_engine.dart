import 'dart:math';

import '../models/becoming_arc.dart';

// ---------------------------------------------------------------------------
// Intensity levels for adaptive difficulty
// ---------------------------------------------------------------------------

enum StepIntensity { easy, medium, hard, extreme }

extension StepIntensityX on StepIntensity {
  String get label {
    switch (this) {
      case StepIntensity.easy:
        return 'Easy';
      case StepIntensity.medium:
        return 'Medium';
      case StepIntensity.hard:
        return 'Hard';
      case StepIntensity.extreme:
        return 'Extreme';
    }
  }

  /// 1-based index for dot indicators.
  int get dotCount {
    switch (this) {
      case StepIntensity.easy:
        return 1;
      case StepIntensity.medium:
        return 2;
      case StepIntensity.hard:
        return 3;
      case StepIntensity.extreme:
        return 4;
    }
  }
}

// ---------------------------------------------------------------------------
// DifficultyAdjustment — the result of an adaptive assessment
// ---------------------------------------------------------------------------

class DifficultyAdjustment {
  /// Recommended intensity per layer.
  final Map<ArcLayer, StepIntensity> recommendedIntensity;

  /// The layer that needs the most attention, or null if balanced.
  final ArcLayer? focusLayer;

  /// A short motivational string for the user.
  final String motivationalMessage;

  /// Whether the user has earned a streak bonus (7+ consecutive days).
  final bool streakBonus;

  const DifficultyAdjustment({
    required this.recommendedIntensity,
    this.focusLayer,
    required this.motivationalMessage,
    this.streakBonus = false,
  });

  /// Convenience: the intensity for a given layer, defaulting to medium.
  StepIntensity intensityFor(ArcLayer layer) =>
      recommendedIntensity[layer] ?? StepIntensity.medium;
}

// ---------------------------------------------------------------------------
// AdaptiveDifficultyEngine — stateless utility service
// ---------------------------------------------------------------------------

class AdaptiveDifficultyEngine {
  const AdaptiveDifficultyEngine._();

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /// Analyses the user's [progress] against the arc's [steps] and returns a
  /// [DifficultyAdjustment] with per-layer intensity recommendations, an
  /// optional focus layer, and a motivational message.
  static DifficultyAdjustment assess(
    UserArcProgress progress,
    List<ArcStep> steps,
  ) {
    final layerRates = _completionRatePerLayer(progress, steps);
    final intensityMap = <ArcLayer, StepIntensity>{};
    ArcLayer? focus;
    double lowestRate = double.infinity;

    for (final entry in layerRates.entries) {
      final layer = entry.key;
      final rate = entry.value;

      intensityMap[layer] = _intensityFromRate(rate);

      if (rate < lowestRate) {
        lowestRate = rate;
        focus = layer;
      }
    }

    // Only flag a focus layer when it is significantly behind the average.
    final avgRate = layerRates.isEmpty
        ? 0.0
        : layerRates.values.reduce((a, b) => a + b) / layerRates.length;

    if (focus != null && (avgRate - lowestRate).abs() < 0.15) {
      // All layers are within 15 pp — no single layer needs a boost.
      focus = null;
    }

    final streakBonus = _hasStreakBonus(progress);

    final message = focus != null
        ? getMotivationalMessage(focus, lowestRate)
        : _overallMotivationalMessage(avgRate, streakBonus);

    return DifficultyAdjustment(
      recommendedIntensity: intensityMap,
      focusLayer: focus,
      motivationalMessage: message,
      streakBonus: streakBonus,
    );
  }

  /// Returns a motivational message tailored to a [layer] and its
  /// [completionRate] (0.0 – 1.0).
  static String getMotivationalMessage(
    ArcLayer layer,
    double completionRate,
  ) {
    final pct = (completionRate * 100).round();

    if (completionRate >= 0.85) {
      switch (layer) {
        case ArcLayer.identity:
          return 'Your sense of self is razor-sharp. Time to raise the bar.';
        case ArcLayer.habit:
          return 'Your habits are locked in. Let\'s make them unbreakable.';
        case ArcLayer.knowledge:
          return 'Knowledge is power — and you\'re fully charged.';
        case ArcLayer.challenge:
          return 'You eat challenges for breakfast. Ready for the next level?';
        case ArcLayer.reflection:
          return 'Deep self-awareness unlocked. Keep sharpening the mirror.';
      }
    }

    if (completionRate < 0.40) {
      switch (layer) {
        case ArcLayer.identity:
          return 'Your identity layer needs attention — who you become starts here.';
        case ArcLayer.habit:
          return 'Small habits, big results. Let\'s rebuild momentum at $pct%.';
        case ArcLayer.knowledge:
          return 'Feed your mind — knowledge is lagging at $pct%. One lesson at a time.';
        case ArcLayer.challenge:
          return 'Comfort is the enemy. Push into your challenge layer at $pct%.';
        case ArcLayer.reflection:
          return 'Pause and look inward — reflection is only at $pct%.';
      }
    }

    // Mid-range (40-84 %)
    switch (layer) {
      case ArcLayer.identity:
        return 'Identity at $pct% — keep defining who you are becoming.';
      case ArcLayer.habit:
        return 'Habits at $pct% — consistency compounds. Stay the course.';
      case ArcLayer.knowledge:
        return 'Knowledge at $pct% — every lesson gets you closer.';
      case ArcLayer.challenge:
        return 'Challenges at $pct% — lean into the discomfort.';
      case ArcLayer.reflection:
        return 'Reflection at $pct% — the examined life is winning.';
    }
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  /// Computes the completion rate (0.0 – 1.0) for each layer using only
  /// steps whose [dayNumber] falls within the trailing 7-day window
  /// relative to [progress.currentDay].
  static Map<ArcLayer, double> _completionRatePerLayer(
    UserArcProgress progress,
    List<ArcStep> steps,
  ) {
    final windowStart = max(1, progress.currentDay - 6);
    final windowEnd = progress.currentDay;

    final result = <ArcLayer, double>{};

    for (final layer in ArcLayer.values) {
      final windowSteps = steps
          .where((s) =>
              s.layer == layer &&
              s.dayNumber >= windowStart &&
              s.dayNumber <= windowEnd)
          .toList();

      if (windowSteps.isEmpty) {
        // Fall back to the overall layer score when no steps land in the window.
        result[layer] = progress.layerProgress(layer);
        continue;
      }

      final done =
          windowSteps.where((s) => progress.completedSteps[s.id] == true).length;
      result[layer] = done / windowSteps.length;
    }

    return result;
  }

  /// Maps a completion rate to the recommended [StepIntensity].
  static StepIntensity _intensityFromRate(double rate) {
    if (rate < 0.40) return StepIntensity.easy;
    if (rate < 0.65) return StepIntensity.medium;
    if (rate < 0.85) return StepIntensity.hard;
    return StepIntensity.extreme;
  }

  /// A streak bonus is awarded when the user has been active for 7+
  /// consecutive days (approximated by currentDay >= 7 and overall
  /// progress keeping pace).
  static bool _hasStreakBonus(UserArcProgress progress) {
    if (progress.currentDay < 7) return false;
    // Heuristic: at least 60 % overall completion through the window.
    return progress.overallProgress >= 0.60;
  }

  /// Overall message when no single layer is lagging.
  static String _overallMotivationalMessage(double avgRate, bool streak) {
    if (streak) {
      return 'Streak bonus active! Your consistency is paying off.';
    }
    if (avgRate >= 0.85) {
      return 'Outstanding — you\'re crushing every layer. Keep this energy.';
    }
    if (avgRate >= 0.65) {
      return 'Solid progress across the board. Push a little harder today.';
    }
    if (avgRate >= 0.40) {
      return 'You\'re building momentum. Every step counts.';
    }
    return 'The journey starts with showing up. Let\'s get moving.';
  }
}

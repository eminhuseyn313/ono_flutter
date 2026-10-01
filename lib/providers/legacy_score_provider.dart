import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../gateways/legacy_score_gateway.dart';
import '../models/legacy_score.dart';

/// ChangeNotifier that manages Legacy Score state: current score, tier,
/// milestones, score history, animated point increments, and tier-up
/// detection for driving the [TierUpCelebration] overlay.
class LegacyScoreProvider extends ChangeNotifier {
  final LegacyScoreGateway _gateway;

  LegacyScoreProvider({required LegacyScoreGateway gateway})
      : _gateway = gateway;

  LegacyScore? _score;
  List<LegacyMilestone> _milestones = const [];
  List<LegacyScoreEvent> _history = const [];

  bool _loading = false;
  String? _error;

  /// Animated display score — ticks up toward [totalScore] on change so the
  /// UI can show a smooth count-up instead of snapping.
  int _displayScore = 0;
  Timer? _animationTimer;

  /// Set by [addPoints] when the tier changes as a result of new points.
  /// Consumers (e.g. the screen hosting [TierUpCelebration]) should read
  /// this once and call [acknowledgeTierUp] to clear it.
  LegacyTier? _pendingTierUp;

  LegacyScore? get score => _score;
  int get totalScore => _score?.totalScore ?? 0;
  int get displayScore => _displayScore;
  LegacyTier get tier => _score?.currentTier ?? LegacyTier.initiate;
  List<LegacyMilestone> get milestones => List.unmodifiable(_milestones);
  List<LegacyScoreEvent> get history => List.unmodifiable(_history);
  bool get loading => _loading;
  String? get error => _error;
  LegacyTier? get pendingTierUp => _pendingTierUp;

  double get progressToNextTier => _score?.progressToNextTier ?? 0.0;
  int get pointsToNextTier => _score?.pointsToNextTier ?? 0;

  /// Most recent point-earning events, capped to the last 10 for UI lists.
  List<LegacyScoreEvent> get recentEvents => _history.take(10).toList();

  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadScore(userId),
        _gateway.loadMilestones(userId),
        _gateway.loadScoreHistory(userId),
      ]);

      _score = results[0] as LegacyScore;
      _milestones = results[1] as List<LegacyMilestone>;
      _history = results[2] as List<LegacyScoreEvent>;
      _loading = false;
      _animateDisplayScoreTo(_score!.totalScore, from: 0);
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add points for a completed action, animating the score up and
  /// surfacing a tier-up event if the new total crosses a tier boundary.
  Future<void> addPoints(String userId, String actionType) async {
    final weight = ActionWeight.resolve(actionType);
    final previousTier = tier;
    final previousTotal = totalScore;

    try {
      final updated = await _gateway.addPoints(
        userId,
        actionType,
        weight.points,
      );
      _score = updated;

      // Re-fetch milestones/history so newly-unlocked milestones and the
      // new event show up immediately.
      final results = await Future.wait([
        _gateway.loadMilestones(userId),
        _gateway.loadScoreHistory(userId),
      ]);
      _milestones = results[0] as List<LegacyMilestone>;
      _history = results[1] as List<LegacyScoreEvent>;

      _animateDisplayScoreTo(updated.totalScore, from: previousTotal);

      if (updated.currentTier != previousTier) {
        _pendingTierUp = updated.currentTier;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clears the pending tier-up flag once the celebration UI has consumed it.
  void acknowledgeTierUp() {
    if (_pendingTierUp == null) return;
    _pendingTierUp = null;
    notifyListeners();
  }

  void _animateDisplayScoreTo(int target, {required int from}) {
    _animationTimer?.cancel();

    if (target == from) {
      _displayScore = target;
      return;
    }

    const duration = Duration(milliseconds: 900);
    const frameInterval = Duration(milliseconds: 16);
    final totalFrames = (duration.inMilliseconds / frameInterval.inMilliseconds)
        .round()
        .clamp(1, 1000);
    var frame = 0;

    _displayScore = from;
    _animationTimer = Timer.periodic(frameInterval, (timer) {
      frame++;
      final t = (frame / totalFrames).clamp(0.0, 1.0);
      // easeOutCubic
      final eased = 1 - math.pow(1 - t, 3);
      _displayScore = (from + (target - from) * eased).round();
      notifyListeners();

      if (frame >= totalFrames) {
        _displayScore = target;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }
}

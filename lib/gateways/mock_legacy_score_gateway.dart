import 'dart:math';

import '../models/legacy_score.dart';
import 'legacy_score_gateway.dart';

/// In-memory mock implementation of [LegacyScoreGateway].
///
/// Seeds each new user at ~750 points (Warrior tier) with a sample history
/// so Sprint 2 screens have realistic data to render against.
class MockLegacyScoreGateway implements LegacyScoreGateway {
  final Map<String, LegacyScore> _scores = {};
  final Map<String, List<LegacyScoreEvent>> _history = {};
  int _eventSeq = 0;

  static const int _seedScore = 750;

  void _seedIfNeeded(String userId) {
    if (_scores.containsKey(userId)) return;

    final now = DateTime.now();
    final seedEvents = <LegacyScoreEvent>[
      _event('read_30min', now.subtract(const Duration(days: 12))),
      _event('meditation_10min', now.subtract(const Duration(days: 11))),
      _event('journal_entry', now.subtract(const Duration(days: 10))),
      _event('pushups_50', now.subtract(const Duration(days: 8))),
      _event('skill_practice', now.subtract(const Duration(days: 7))),
      _event('social_connection', now.subtract(const Duration(days: 6))),
      _event('read_30min', now.subtract(const Duration(days: 5))),
      _event('meditation_10min', now.subtract(const Duration(days: 4))),
      _event('skill_practice', now.subtract(const Duration(days: 3))),
      _event('journal_entry', now.subtract(const Duration(days: 2))),
      _event('pushups_50', now.subtract(const Duration(days: 1))),
      _event('read_30min', now.subtract(const Duration(hours: 6))),
    ];

    // Scale the seed history so it roughly sums toward the seed score, then
    // top up with a synthetic "earlier progress" event to land exactly on it.
    final seededTotal = seedEvents.fold<int>(0, (sum, e) => sum + e.points);
    final backfill = max(0, _seedScore - seededTotal);
    final events = <LegacyScoreEvent>[
      LegacyScoreEvent(
        id: 'evt_seed_backfill',
        actionType: 'default',
        label: 'Early progress',
        points: backfill,
        earnedAt: now.subtract(const Duration(days: 30)),
      ),
      ...seedEvents,
    ];

    final total = events.fold<int>(0, (sum, e) => sum + e.points);

    _history[userId] = events.reversed.toList(); // most recent first
    _scores[userId] = LegacyScore(
      userId: userId,
      totalScore: total,
      currentTier: LegacyTierData.forScore(total),
      updatedAt: now,
    );
  }

  LegacyScoreEvent _event(String actionType, DateTime at) {
    final weight = ActionWeight.resolve(actionType);
    _eventSeq++;
    return LegacyScoreEvent(
      id: 'evt_seed_$_eventSeq',
      actionType: actionType,
      label: weight.label,
      points: weight.points,
      earnedAt: at,
    );
  }

  @override
  Future<LegacyScore> loadScore(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _seedIfNeeded(userId);
    return _scores[userId]!;
  }

  @override
  Future<LegacyScore> addPoints(
    String userId,
    String actionType,
    int points,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _seedIfNeeded(userId);

    final current = _scores[userId]!;
    // Score can only ever go up: guard against a negative/zero point value.
    final safePoints = points > 0 ? points : 0;
    final newTotal = current.totalScore + safePoints;

    final updated = current.copyWith(
      totalScore: newTotal,
      currentTier: LegacyTierData.forScore(newTotal),
      updatedAt: DateTime.now(),
    );
    _scores[userId] = updated;

    if (safePoints > 0) {
      final weight = ActionWeight.resolve(actionType);
      _eventSeq++;
      final event = LegacyScoreEvent(
        id: 'evt_$_eventSeq',
        actionType: actionType,
        label: weight.label.isNotEmpty ? weight.label : actionType,
        points: safePoints,
        earnedAt: DateTime.now(),
      );
      _history.putIfAbsent(userId, () => []).insert(0, event);
    }

    return updated;
  }

  @override
  Future<List<LegacyMilestone>> loadMilestones(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _seedIfNeeded(userId);
    final score = _scores[userId]!.totalScore;
    return LegacyMilestone.defaults(currentScore: score);
  }

  @override
  Future<List<LegacyScoreEvent>> loadScoreHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _seedIfNeeded(userId);
    return List.unmodifiable(_history[userId] ?? const []);
  }
}

import 'dart:math';

import '../data/emin_personal_content.dart';
import '../models/ritual.dart';
import 'ritual_gateway.dart';

/// In-memory mock implementation of [RitualGateway].
///
/// Seeds with prebuilt morning and evening rituals and 5 completed sessions
/// spread across the last week.
class MockRitualGateway implements RitualGateway {
  final Map<String, Ritual> _rituals = {};
  final List<RitualSession> _sessions = [];
  int _nextSessionId = 100;

  static const String _defaultUserId = 'user_001';

  MockRitualGateway() {
    _seed();
  }

  void _seed() {
    final morning = PrebuiltRituals.morning(_defaultUserId)
        .copyWith(steps: eminMorningRitual);
    final evening = PrebuiltRituals.evening(_defaultUserId);
    _rituals[morning.id] = morning;
    _rituals[evening.id] = evening;

    final now = DateTime.now();
    final random = Random(42);

    // 5 completed sessions over the last week
    for (int i = 0; i < 5; i++) {
      final daysAgo = i + 1;
      final isEven = i.isEven;
      final ritual = isEven ? morning : evening;
      final started = DateTime(
        now.year,
        now.month,
        now.day - daysAgo,
        isEven ? 7 : 22,
        random.nextInt(15),
      );
      final stepsCompleted =
          ritual.steps.map((s) => s.id).toList();
      final totalSec = ritual.totalDurationSeconds +
          random.nextInt(30); // slight variance
      final completed = started.add(Duration(seconds: totalSec));

      _sessions.add(RitualSession(
        id: 'session_seed_$i',
        ritualId: ritual.id,
        startedAt: started,
        completedAt: completed,
        stepsCompleted: stepsCompleted,
        totalDuration: Duration(seconds: totalSec),
      ));
    }
  }

  Future<void> _simulateLatency() =>
      Future.delayed(const Duration(milliseconds: 180));

  @override
  Future<List<Ritual>> loadRituals(String userId) async {
    await _simulateLatency();
    // Single-user mock: hand the seeded rituals to whoever signs in.
    for (final entry in _rituals.entries.toList()) {
      if (entry.value.userId == _defaultUserId) {
        _rituals[entry.key] = entry.value.copyWith(userId: userId);
      }
    }
    return _rituals.values
        .where((r) => r.userId == userId)
        .toList();
  }

  @override
  Future<Ritual?> loadRitual(String ritualId) async {
    await _simulateLatency();
    return _rituals[ritualId];
  }

  @override
  Future<void> saveRitual(Ritual ritual) async {
    await _simulateLatency();
    _rituals[ritual.id] = ritual;
  }

  @override
  Future<void> deleteRitual(String ritualId) async {
    await _simulateLatency();
    _rituals.remove(ritualId);
  }

  @override
  Future<RitualSession> startSession(String ritualId) async {
    await _simulateLatency();
    final session = RitualSession(
      id: 'session_${_nextSessionId++}',
      ritualId: ritualId,
      startedAt: DateTime.now(),
      stepsCompleted: const [],
      totalDuration: Duration.zero,
    );
    _sessions.add(session);
    return session;
  }

  @override
  Future<void> completeSession(RitualSession session) async {
    await _simulateLatency();
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
    } else {
      _sessions.add(session);
    }
  }

  @override
  Future<List<RitualSession>> loadSessionHistory(
    String ritualId, {
    int limit = 30,
  }) async {
    await _simulateLatency();
    final filtered = _sessions
        .where((s) => s.ritualId == ritualId && s.completedAt != null)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return filtered.take(limit).toList();
  }
}

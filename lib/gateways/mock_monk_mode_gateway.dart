import 'dart:math';

import '../models/monk_session.dart';
import 'monk_mode_gateway.dart';

/// In-memory mock gateway for Monk Mode, seeded with a sample session
/// history so the provider/UI has realistic data to render against
/// during development.
class MockMonkModeGateway implements MonkModeGateway {
  final Map<String, List<MonkSession>> _historyByUser = {};

  MockMonkModeGateway() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rand = Random(7);

    final sample = <MonkSession>[];
    // Build a short streak ending yesterday, plus some older sparse history.
    final streakDurations = [10, 5, 15, 5, 20];
    for (var i = 0; i < streakDurations.length; i++) {
      final day = today.subtract(Duration(days: i + 1));
      sample.add(
        MonkSession(
          id: 'seed-streak-$i',
          userId: 'demo-user',
          durationMinutes: streakDurations[i],
          completedAt: day.add(Duration(hours: 7 + rand.nextInt(12))),
          breathCycles: (streakDurations[i] * 60) ~/ 12,
          wasInterrupted: false,
        ),
      );
    }
    // Some older, sparser history.
    for (var i = 0; i < 6; i++) {
      final day = today.subtract(Duration(days: 10 + i * 4));
      final duration = [2, 5, 10, 30, 15, 5][i];
      sample.add(
        MonkSession(
          id: 'seed-older-$i',
          userId: 'demo-user',
          durationMinutes: duration,
          completedAt: day.add(Duration(hours: 8 + rand.nextInt(10))),
          breathCycles: (duration * 60) ~/ 12,
          wasInterrupted: i == 2, // one interrupted session for realism
        ),
      );
    }

    sample.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    _historyByUser['demo-user'] = sample;
  }

  List<MonkSession> _historyFor(String userId) {
    return _historyByUser.putIfAbsent(userId, () => <MonkSession>[]);
  }

  @override
  Future<MonkModeStats> loadStats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MonkModeStats.fromHistory(_historyFor(userId));
  }

  @override
  Future<void> saveSession(String userId, MonkSession session) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final history = _historyFor(userId);
    history.insert(0, session);
  }

  @override
  Future<List<MonkSession>> loadHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final history = List<MonkSession>.from(_historyFor(userId));
    history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return history;
  }
}

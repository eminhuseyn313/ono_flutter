import 'dart:math';

import '../models/ghost_mode.dart';
import 'ghost_mode_gateway.dart';

/// In-memory mock gateway with seeded ghost data for development.
class MockGhostModeGateway implements GhostModeGateway {
  final List<GhostSnapshot> _snapshots;
  WeeklyGhostChallenge _challenge;

  MockGhostModeGateway()
      : _snapshots = _buildSeededSnapshots(),
        _challenge = const WeeklyGhostChallenge(
          isActive: true,
          targetBeatCount: 3,
          actualBeatCount: 2,
          lanesBeaten: ['Mind', 'Skill'],
        );

  // -- GhostModeGateway implementation ----------------------------------------

  @override
  Future<GhostSnapshot> loadCurrentWeekSnapshot() async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    return _snapshots.first; // most recent = current week
  }

  @override
  Future<GhostSnapshot> loadPreviousWeekSnapshot() async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    return _snapshots[1]; // second most recent = ghost week
  }

  @override
  Future<List<GhostSnapshot>> loadGhostHistory(int weeks) async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    final count = weeks.clamp(0, _snapshots.length);
    return List.unmodifiable(_snapshots.take(count));
  }

  @override
  Future<void> saveSnapshot(GhostSnapshot snapshot) async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    _snapshots.insert(0, snapshot);
  }

  @override
  Future<WeeklyGhostChallenge> getWeeklyChallenge() async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    return _challenge;
  }

  @override
  Future<WeeklyGhostChallenge> completeWeeklyChallenge() async {
    await Future.delayed(
        Duration(milliseconds: 150 + Random().nextInt(101)));
    _challenge = _challenge.copyWith(
      isActive: false,
      actualBeatCount: _challenge.targetBeatCount,
      lanesBeaten: ['Mind', 'Body', 'Social', 'Skill'],
    );
    return _challenge;
  }

  // -- Seeded data ------------------------------------------------------------

  static List<GhostSnapshot> _buildSeededSnapshots() {
    final now = DateTime.now();
    // Align to Monday of this week.
    final todayWeekday = now.weekday; // 1 = Monday
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: todayWeekday - 1));

    return [
      // Week 0 — current week (partially done).
      GhostSnapshot(
        weekStart: monday,
        laneScores: const {
          'Mind': 0.70,
          'Body': 0.60,
          'Social': 0.55,
          'Skill': 0.75,
        },
        actionsCompleted: 13,
        actionsTotal: 20,
        overallScore: 0.65,
      ),
      // Week -1 — previous week (the ghost).
      GhostSnapshot(
        weekStart: monday.subtract(const Duration(days: 7)),
        laneScores: const {
          'Mind': 0.55,
          'Body': 0.65,
          'Social': 0.45,
          'Skill': 0.55,
        },
        actionsCompleted: 11,
        actionsTotal: 20,
        overallScore: 0.55,
      ),
      // Week -2
      GhostSnapshot(
        weekStart: monday.subtract(const Duration(days: 14)),
        laneScores: const {
          'Mind': 0.50,
          'Body': 0.55,
          'Social': 0.40,
          'Skill': 0.50,
        },
        actionsCompleted: 10,
        actionsTotal: 20,
        overallScore: 0.49,
      ),
      // Week -3
      GhostSnapshot(
        weekStart: monday.subtract(const Duration(days: 21)),
        laneScores: const {
          'Mind': 0.45,
          'Body': 0.50,
          'Social': 0.35,
          'Skill': 0.45,
        },
        actionsCompleted: 9,
        actionsTotal: 20,
        overallScore: 0.44,
      ),
    ];
  }
}

import '../models/time_capsule.dart';
import 'time_capsule_gateway.dart';

class MockTimeCapsuleGateway implements TimeCapsuleGateway {
  final List<TimeCapsule> _capsules = [];
  bool _initialized = false;
  int _nextId = 4;

  void _seedData(String userId) {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();

    _capsules.addAll([
      // Locked: 60 days from now
      TimeCapsule(
        id: '1',
        userId: userId,
        message:
            'Hey future me — if you\'re reading this, you made it through the '
            'grind. Remember how hard today felt? Remember the doubt? You pushed '
            'through it. I hope you\'re proud of who you\'ve become. Keep going, '
            'king. The best is still ahead.',
        lane: 'mind',
        createdAt: now,
        unlockAt: now.add(const Duration(days: 60)),
        mood: '🔥',
      ),

      // Unlocked but not opened: created 31 days ago, unlocked yesterday
      TimeCapsule(
        id: '2',
        userId: userId,
        message:
            'Writing this on a random Tuesday night. Things are messy right now '
            'but I started showing up — gym 4x this week, journaling every morning. '
            'Future me, I bet you\'re way stronger now. Don\'t forget where you '
            'started. That guy believed in you when nobody else did.',
        lane: 'body',
        createdAt: now.subtract(const Duration(days: 31)),
        unlockAt: now.subtract(const Duration(days: 1)),
        mood: '😊',
      ),

      // Already opened: created 90 days ago
      TimeCapsule(
        id: '3',
        userId: userId,
        message:
            'I just had the worst conversation of my life. Said things I regret. '
            'But I\'m writing this because I know I\'ll learn from it. Future me — '
            'did you apologize? Did you grow? I know you did. You always figure '
            'it out eventually.',
        lane: 'social',
        createdAt: now.subtract(const Duration(days: 90)),
        unlockAt: now.subtract(const Duration(days: 30)),
        isOpened: true,
        openedAt: now.subtract(const Duration(days: 29)),
        mood: '👑',
      ),
    ]);
  }

  @override
  Future<List<TimeCapsule>> loadCapsules(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _seedData(userId);
    return List.unmodifiable(
      _capsules.where((c) => c.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<TimeCapsule> createCapsule(
    String userId, {
    required String message,
    String? lane,
    required DateTime unlockAt,
    String? mood,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final capsule = TimeCapsule(
      id: (_nextId++).toString(),
      userId: userId,
      message: message,
      lane: lane,
      createdAt: DateTime.now(),
      unlockAt: unlockAt,
      mood: mood,
    );

    _capsules.add(capsule);
    return capsule;
  }

  @override
  Future<void> openCapsule(String userId, String capsuleId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _capsules.indexWhere(
      (c) => c.id == capsuleId && c.userId == userId,
    );
    if (index == -1) {
      throw Exception('Capsule not found');
    }

    final capsule = _capsules[index];
    if (!capsule.isUnlocked) {
      throw Exception('Capsule is still locked');
    }

    _capsules[index] = capsule.copyWith(
      isOpened: true,
      openedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteCapsule(String userId, String capsuleId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final removed = _capsules.removeWhere(
      (c) => c.id == capsuleId && c.userId == userId,
    );
  }
}

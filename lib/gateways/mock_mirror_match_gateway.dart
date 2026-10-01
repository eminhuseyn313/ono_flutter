import '../models/mirror_match.dart';
import 'mirror_match_gateway.dart';

class MockMirrorMatchGateway implements MirrorMatchGateway {
  // ── Seeded trajectory for the mirror (60 days of data) ──
  static List<TrajectoryPoint> _buildMirrorTrajectory() {
    final points = <TrajectoryPoint>[];
    for (var d = 1; d <= 60; d++) {
      // Gradual upward trend with realistic dips
      final progress = d / 60;
      final dip = (d % 7 == 0) ? -0.05 : 0.0; // weekly dips
      points.add(TrajectoryPoint(
        dayNumber: d,
        mindScore: 0.25 + progress * 0.50 + dip,
        bodyScore: 0.30 + progress * 0.45 + dip,
        socialScore: 0.20 + progress * 0.40 + dip,
        skillScore: 0.22 + progress * 0.48 + dip,
      ));
    }
    return points;
  }

  // ── Seeded trajectory for "me" (30 days of data) ──
  static List<TrajectoryPoint> _buildMyTrajectory() {
    final points = <TrajectoryPoint>[];
    for (var d = 1; d <= 30; d++) {
      final progress = d / 60; // same scale as mirror
      final dip = (d % 5 == 0) ? -0.03 : 0.0;
      points.add(TrajectoryPoint(
        dayNumber: d,
        mindScore: 0.24 + progress * 0.52 + dip,
        bodyScore: 0.28 + progress * 0.47 + dip,
        socialScore: 0.19 + progress * 0.42 + dip,
        skillScore: 0.23 + progress * 0.44 + dip,
      ));
    }
    return points;
  }

  static final _mirrorProfile = MirrorProfile(
    id: 'mirror_001',
    alias: 'Shadow Walker #47',
    emoji: '🪞',
    daysAhead: 30,
    similarityScore: 0.92,
    trajectory: _buildMirrorTrajectory(),
    strongestLane: 'mind',
    currentStreak: 42,
    legacyScore: 2850,
  );

  final _messages = <MirrorMessage>[
    MirrorMessage(
      id: 'msg_1',
      senderId: 'mirror_001',
      text: 'Keep going — Day 30 was a turning point for me. '
          'Everything clicked after that.',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MirrorMessage(
      id: 'msg_2',
      senderId: 'me',
      text: 'Thanks! How did you stay consistent with the Mind lane?',
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    MirrorMessage(
      id: 'msg_3',
      senderId: 'mirror_001',
      text: 'I paired every reading session with my morning coffee. '
          'Made it automatic instead of a choice.',
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
    ),
  ];

  int _msgCounter = 4;

  @override
  Future<MirrorMatchData> loadMatchData() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MirrorMatchData(
      status: MirrorMatchStatus.matched,
      mirror: _mirrorProfile,
      myTrajectory: _buildMyTrajectory(),
      messages: List.unmodifiable(_messages),
      chatUnlocked: true,
    );
  }

  @override
  Future<MirrorProfile?> findMatch() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _mirrorProfile;
  }

  @override
  Future<List<MirrorMessage>> loadMessages(String mirrorId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_messages);
  }

  @override
  Future<MirrorMessage> sendMessage(String mirrorId, String text) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final msg = MirrorMessage(
      id: 'msg_${_msgCounter++}',
      senderId: 'me',
      text: text,
      sentAt: DateTime.now(),
    );
    _messages.add(msg);

    // Auto-reply after a delay (simulated)
    Future.delayed(const Duration(seconds: 1), () {
      _messages.add(MirrorMessage(
        id: 'msg_${_msgCounter++}',
        senderId: mirrorId,
        text: _autoReplies[_msgCounter % _autoReplies.length],
        sentAt: DateTime.now(),
      ));
    });

    return msg;
  }

  @override
  Future<void> dismissMatch(String mirrorId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  static const _autoReplies = [
    'That resonates — I struggled with the same thing around your stage.',
    'You\'re on the right path. Trust the process.',
    'One thing that helped me: focus on consistency, not intensity.',
    'The hardest part is already behind you — showing up.',
    'I remember Day 15 being tough. It gets easier, I promise.',
    'Body lane was my weak point too. Small daily wins compound.',
  ];
}

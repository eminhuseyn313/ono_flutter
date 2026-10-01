import '../models/community_challenge.dart';
import 'community_challenge_gateway.dart';

class MockCommunityChallengeGateway implements CommunityChallengeGateway {
  List<CommunityChallenge> _challenges = [];

  final _participants = const [
    ChallengeParticipant(
      id: 'p1',
      name: 'Alex K.',
      avatarInitial: 'A',
      avatarColorValue: 0xFFC8894A,
      progress: 0.92,
      score: 920,
    ),
    ChallengeParticipant(
      id: 'p2',
      name: 'Jordan M.',
      avatarInitial: 'J',
      avatarColorValue: 0xFF7C9CC4,
      progress: 0.85,
      score: 850,
    ),
    ChallengeParticipant(
      id: 'p3',
      name: 'Ryan T.',
      avatarInitial: 'R',
      avatarColorValue: 0xFF7DB495,
      progress: 0.78,
      score: 780,
    ),
    ChallengeParticipant(
      id: 'p4',
      name: 'Chris B.',
      avatarInitial: 'C',
      avatarColorValue: 0xFFE2B354,
      progress: 0.72,
      score: 720,
    ),
    ChallengeParticipant(
      id: 'p5',
      name: 'David L.',
      avatarInitial: 'D',
      avatarColorValue: 0xFFE0605A,
      progress: 0.65,
      score: 650,
    ),
  ];

  List<CommunityChallenge> _generateChallenges() {
    final now = DateTime.now();
    return [
      CommunityChallenge(
        id: 'ch_1',
        title: '7-Day Meditation Streak',
        description: 'Meditate for at least 10 minutes every day for 7 consecutive days. Build the habit that transforms your mind.',
        lane: 'Mind',
        laneColorValue: 0xFFC8894A,
        status: ChallengeStatus.active,
        type: ChallengeType.weekly,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        participantCount: 234,
        topParticipants: _participants.take(3).toList(),
        isJoined: true,
        myProgress: 0.43,
        myRank: 12,
        reward: '150 XP + Mindful Warrior Badge',
        targetValue: 7,
        targetUnit: 'days',
      ),
      CommunityChallenge(
        id: 'ch_2',
        title: '100 Push-ups Challenge',
        description: 'Complete 100 push-ups total across the week. Break them into sets however you like — just get it done.',
        lane: 'Body',
        laneColorValue: 0xFF7C9CC4,
        status: ChallengeStatus.active,
        type: ChallengeType.weekly,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        participantCount: 189,
        topParticipants: _participants.sublist(1, 4),
        isJoined: true,
        myProgress: 0.62,
        myRank: 8,
        reward: '200 XP + Iron Will Badge',
        targetValue: 100,
        targetUnit: 'push-ups',
      ),
      CommunityChallenge(
        id: 'ch_3',
        title: 'Reach Out to 5 People',
        description: 'Send a meaningful message or have a real conversation with 5 different people this week. Build your tribe.',
        lane: 'Social',
        laneColorValue: 0xFF7DB495,
        status: ChallengeStatus.active,
        type: ChallengeType.weekly,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 6)),
        participantCount: 156,
        topParticipants: _participants.sublist(2, 5),
        isJoined: false,
        myProgress: 0.0,
        myRank: 0,
        reward: '175 XP + Connector Badge',
        targetValue: 5,
        targetUnit: 'conversations',
      ),
      CommunityChallenge(
        id: 'ch_4',
        title: '30 Days of Learning',
        description: 'Spend at least 20 minutes each day learning a new skill. Read, watch tutorials, practice — level up every day.',
        lane: 'Skill',
        laneColorValue: 0xFFE2B354,
        status: ChallengeStatus.active,
        type: ChallengeType.monthly,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        participantCount: 312,
        topParticipants: _participants,
        isJoined: true,
        myProgress: 0.33,
        myRank: 25,
        reward: '500 XP + Knowledge Seeker Badge',
        targetValue: 30,
        targetUnit: 'days',
      ),
      CommunityChallenge(
        id: 'ch_5',
        title: 'Cold Shower Week',
        description: 'Start each morning with a 2-minute cold shower. Build discipline and resilience, one shiver at a time.',
        lane: 'Body',
        laneColorValue: 0xFF7C9CC4,
        status: ChallengeStatus.upcoming,
        type: ChallengeType.weekly,
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 10)),
        participantCount: 78,
        topParticipants: [],
        isJoined: false,
        myProgress: 0.0,
        myRank: 0,
        reward: '200 XP + Ice King Badge',
        targetValue: 7,
        targetUnit: 'showers',
      ),
      CommunityChallenge(
        id: 'ch_6',
        title: 'Gratitude Journal Sprint',
        description: 'Write 3 things you are grateful for every day for 5 days. Simple but powerful.',
        lane: 'Mind',
        laneColorValue: 0xFFC8894A,
        status: ChallengeStatus.completed,
        type: ChallengeType.weekly,
        startDate: now.subtract(const Duration(days: 12)),
        endDate: now.subtract(const Duration(days: 5)),
        participantCount: 267,
        topParticipants: _participants.take(3).toList(),
        isJoined: true,
        myProgress: 1.0,
        myRank: 5,
        reward: '150 XP + Grateful Heart Badge',
        targetValue: 5,
        targetUnit: 'days',
      ),
    ];
  }

  @override
  Future<ChallengeData> loadChallenges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _challenges = _generateChallenges();
    final active =
        _challenges.where((c) => c.status == ChallengeStatus.active).length;
    final completed =
        _challenges.where((c) => c.status == ChallengeStatus.completed).length;
    return ChallengeData(
      challenges: _challenges,
      totalParticipants: 891,
      activeChallenges: active,
      completedChallenges: completed,
    );
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _challenges = _challenges.map((c) {
      if (c.id == challengeId) {
        return c.copyWith(
          isJoined: true,
          participantCount: c.participantCount + 1,
        );
      }
      return c;
    }).toList();
  }

  @override
  Future<void> leaveChallenge(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _challenges = _challenges.map((c) {
      if (c.id == challengeId) {
        return c.copyWith(
          isJoined: false,
          participantCount: c.participantCount - 1,
          myProgress: 0.0,
          myRank: 0,
        );
      }
      return c;
    }).toList();
  }

  @override
  Future<void> updateProgress(String challengeId, double progress) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _challenges = _challenges.map((c) {
      if (c.id == challengeId) {
        return c.copyWith(myProgress: progress);
      }
      return c;
    }).toList();
  }

  @override
  Future<List<ChallengeParticipant>> loadLeaderboard(
      String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _participants;
  }
}

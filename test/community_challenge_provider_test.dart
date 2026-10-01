import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/community_challenge_gateway.dart';
import 'package:ono/models/community_challenge.dart';
import 'package:ono/providers/community_challenge_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockCommunityChallengeGateway implements CommunityChallengeGateway {
  ChallengeData? data;
  Exception? loadError;
  Exception? joinError;
  final List<String> joinedIds = [];
  final List<String> leftIds = [];
  List<ChallengeParticipant> leaderboardResult = [];

  @override
  Future<ChallengeData> loadChallenges() async {
    if (loadError != null) throw loadError!;
    return data!;
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    if (joinError != null) throw joinError!;
    joinedIds.add(challengeId);
  }

  @override
  Future<void> leaveChallenge(String challengeId) async {
    leftIds.add(challengeId);
  }

  @override
  Future<void> updateProgress(String challengeId, double progress) async {}

  @override
  Future<List<ChallengeParticipant>> loadLeaderboard(
      String challengeId) async {
    return leaderboardResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
CommunityChallenge _challenge({
  String id = 'ch1',
  ChallengeStatus status = ChallengeStatus.active,
  ChallengeType type = ChallengeType.weekly,
  bool isJoined = false,
  int participantCount = 100,
  double myProgress = 0.0,
  int myRank = 0,
}) =>
    CommunityChallenge(
      id: id,
      title: 'Test Challenge',
      description: 'Description',
      lane: 'Mind',
      laneColorValue: 0xFF8B5CF6,
      status: status,
      type: type,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
      participantCount: participantCount,
      isJoined: isJoined,
      myProgress: myProgress,
      myRank: myRank,
      reward: '100 XP',
      targetValue: 7,
      targetUnit: 'days',
    );

ChallengeData _challengeData({List<CommunityChallenge>? challenges}) {
  final list = challenges ??
      [
        _challenge(id: 'ch1', status: ChallengeStatus.active, isJoined: true),
        _challenge(id: 'ch2', status: ChallengeStatus.active),
        _challenge(id: 'ch3', status: ChallengeStatus.upcoming),
        _challenge(id: 'ch4', status: ChallengeStatus.completed, isJoined: true),
      ];
  return ChallengeData(
    challenges: list,
    totalParticipants: 500,
    activeChallenges: list.where((c) => c.status == ChallengeStatus.active).length,
    completedChallenges:
        list.where((c) => c.status == ChallengeStatus.completed).length,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockCommunityChallengeGateway gateway;
  late CommunityChallengeProvider provider;

  setUp(() {
    gateway = MockCommunityChallengeGateway();
    provider = CommunityChallengeProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('empty before load', () {
      expect(provider.challengeData, isNull);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.activeChallenges, isEmpty);
      expect(provider.upcomingChallenges, isEmpty);
      expect(provider.completedChallenges, isEmpty);
      expect(provider.myChallenges, isEmpty);
      expect(provider.leaderboard, isEmpty);
    });
  });

  // -- Load challenges -----------------------------------------------------

  group('loadChallenges', () {
    test('loads all challenges', () async {
      gateway.data = _challengeData();

      await provider.loadChallenges();

      expect(provider.challengeData, isNotNull);
      expect(provider.challengeData!.totalParticipants, 500);
      expect(provider.isLoading, false);
    });

    test('sets isLoading during fetch', () async {
      gateway.data = _challengeData();

      bool wasLoading = false;
      provider.addListener(() {
        if (provider.isLoading) wasLoading = true;
      });

      await provider.loadChallenges();

      expect(wasLoading, true);
    });

    test('load error sets error message', () async {
      gateway.loadError = Exception('offline');

      await provider.loadChallenges();

      expect(provider.challengeData, isNull);
      expect(provider.error, isNotNull);
    });
  });

  // -- Filtered lists ------------------------------------------------------

  group('filtered lists', () {
    test('activeChallenges returns active only', () async {
      gateway.data = _challengeData();
      await provider.loadChallenges();

      expect(provider.activeChallenges.length, 2);
      expect(
          provider.activeChallenges
              .every((c) => c.status == ChallengeStatus.active),
          true);
    });

    test('upcomingChallenges returns upcoming only', () async {
      gateway.data = _challengeData();
      await provider.loadChallenges();

      expect(provider.upcomingChallenges.length, 1);
      expect(provider.upcomingChallenges.first.id, 'ch3');
    });

    test('completedChallenges returns completed only', () async {
      gateway.data = _challengeData();
      await provider.loadChallenges();

      expect(provider.completedChallenges.length, 1);
      expect(provider.completedChallenges.first.id, 'ch4');
    });

    test('myChallenges returns joined only', () async {
      gateway.data = _challengeData();
      await provider.loadChallenges();

      expect(provider.myChallenges.length, 2);
      expect(provider.myChallenges.every((c) => c.isJoined), true);
    });
  });

  // -- Join challenge ------------------------------------------------------

  group('joinChallenge', () {
    test('joins and updates local state', () async {
      gateway.data = _challengeData(challenges: [
        _challenge(id: 'ch1', isJoined: false, participantCount: 50),
      ]);
      await provider.loadChallenges();

      await provider.joinChallenge('ch1');

      expect(gateway.joinedIds, ['ch1']);
      final ch = provider.challengeData!.challenges.first;
      expect(ch.isJoined, true);
      expect(ch.participantCount, 51);
    });

    test('join error sets error', () async {
      gateway.data = _challengeData(challenges: [
        _challenge(id: 'ch1', isJoined: false),
      ]);
      await provider.loadChallenges();
      gateway.joinError = Exception('rate limit');

      await provider.joinChallenge('ch1');

      expect(provider.error, isNotNull);
    });
  });

  // -- Leave challenge -----------------------------------------------------

  group('leaveChallenge', () {
    test('leaves and resets progress/rank', () async {
      gateway.data = _challengeData(challenges: [
        _challenge(
          id: 'ch1',
          isJoined: true,
          participantCount: 50,
          myProgress: 0.6,
          myRank: 12,
        ),
      ]);
      await provider.loadChallenges();

      await provider.leaveChallenge('ch1');

      expect(gateway.leftIds, ['ch1']);
      final ch = provider.challengeData!.challenges.first;
      expect(ch.isJoined, false);
      expect(ch.participantCount, 49);
      expect(ch.myProgress, 0.0);
      expect(ch.myRank, 0);
    });
  });

  // -- Leaderboard ---------------------------------------------------------

  group('loadLeaderboard', () {
    test('loads and exposes participants', () async {
      gateway.data = _challengeData();
      gateway.leaderboardResult = [
        const ChallengeParticipant(
          id: 'p1',
          name: 'Alex',
          avatarInitial: 'A',
          avatarColorValue: 0xFF34D399,
          progress: 0.9,
          score: 450,
        ),
        const ChallengeParticipant(
          id: 'p2',
          name: 'Jordan',
          avatarInitial: 'J',
          avatarColorValue: 0xFF22D3EE,
          progress: 0.8,
          score: 380,
        ),
      ];
      await provider.loadChallenges();

      await provider.loadLeaderboard('ch1');

      expect(provider.leaderboard.length, 2);
      expect(provider.leaderboard.first.name, 'Alex');
      expect(provider.leaderboard.first.score, 450);
    });
  });

  // -- Model serialization -------------------------------------------------

  group('CommunityChallenge toJson/fromJson', () {
    test('round-trips correctly', () {
      final original = _challenge(id: 'x1', isJoined: true, myRank: 5);
      final json = original.toJson();
      final restored = CommunityChallenge.fromJson(json);

      expect(restored.id, 'x1');
      expect(restored.isJoined, true);
      expect(restored.myRank, 5);
      expect(restored.status, ChallengeStatus.active);
      expect(restored.type, ChallengeType.weekly);
      expect(restored.reward, '100 XP');
    });
  });

  group('ChallengeParticipant toJson/fromJson', () {
    test('round-trips correctly', () {
      const original = ChallengeParticipant(
        id: 'p1',
        name: 'Test',
        avatarInitial: 'T',
        avatarColorValue: 0xFF8B5CF6,
        progress: 0.5,
        score: 200,
      );
      final json = original.toJson();
      final restored = ChallengeParticipant.fromJson(json);

      expect(restored.id, 'p1');
      expect(restored.name, 'Test');
      expect(restored.score, 200);
    });
  });

  // -- daysRemaining -------------------------------------------------------

  group('daysRemaining', () {
    test('returns 0 for past end date', () {
      final past = _challenge().copyWith(
        endDate: DateTime(2020, 1, 1),
      );
      expect(past.daysRemaining, 0);
    });

    test('returns positive for future end date', () {
      final future = _challenge().copyWith(
        endDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(future.daysRemaining, greaterThanOrEqualTo(9));
    });
  });
}

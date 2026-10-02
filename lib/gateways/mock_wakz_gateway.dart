// gateways/mock_wakz_gateway.dart
// Mock implementation of WakzGateway with rich test data

import '../models/wakz_challenge.dart';
import 'wakz_gateway.dart';

class MockWakzGateway implements WakzGateway {
  final List<WakzChallenge> _availableChallenges = [
    WakzChallenge(
      id: 'ch_001',
      title: '50 Pushup Challenge',
      description: 'Complete 50 pushups today and snap a photo of your workout space.',
      type: ChallengeType.daily,
      category: ChallengeCategory.fitness,
      verificationType: VerificationType.photo,
      targetCount: 50,
      deadline: DateTime.now().add(const Duration(hours: 18)),
      lane: 'body',
    ),
    WakzChallenge(
      id: 'ch_002',
      title: 'Read 30 Pages',
      description: 'Read 30 pages of any book and take a photo of the page you stopped at.',
      type: ChallengeType.daily,
      category: ChallengeCategory.reading,
      verificationType: VerificationType.photo,
      targetCount: 30,
      deadline: DateTime.now().add(const Duration(hours: 20)),
      lane: 'mind',
    ),
    WakzChallenge(
      id: 'ch_003',
      title: '10-Min Meditation',
      description: 'Sit quietly for 10 minutes of mindful meditation.',
      type: ChallengeType.daily,
      category: ChallengeCategory.meditation,
      verificationType: VerificationType.honor,
      targetCount: 10,
      deadline: DateTime.now().add(const Duration(hours: 22)),
      lane: 'soul',
    ),
    WakzChallenge(
      id: 'ch_004',
      title: 'Compliment 3 Strangers',
      description: 'Give a genuine compliment to 3 strangers and take a selfie with one.',
      type: ChallengeType.daily,
      category: ChallengeCategory.social,
      verificationType: VerificationType.selfie,
      targetCount: 3,
      deadline: DateTime.now().add(const Duration(hours: 16)),
      lane: 'soul',
    ),
    WakzChallenge(
      id: 'ch_005',
      title: '5K Steps Before Noon',
      description: 'Walk 5,000 steps before noon. Screenshot your step counter.',
      type: ChallengeType.daily,
      category: ChallengeCategory.fitness,
      verificationType: VerificationType.screenshot,
      targetCount: 5000,
      deadline: DateTime.now().add(const Duration(hours: 6)),
      lane: 'body',
    ),
    WakzChallenge(
      id: 'ch_006',
      title: 'Sketch Something New',
      description: 'Draw or sketch anything creative for 15 minutes. Photo your art.',
      type: ChallengeType.daily,
      category: ChallengeCategory.creative,
      verificationType: VerificationType.photo,
      targetCount: 1,
      deadline: DateTime.now().add(const Duration(hours: 14)),
      lane: 'mind',
    ),
    WakzChallenge(
      id: 'ch_007',
      title: 'Learn 20 New Words',
      description: 'Study 20 vocabulary words in a new language this week.',
      type: ChallengeType.weekly,
      category: ChallengeCategory.skill,
      verificationType: VerificationType.screenshot,
      targetCount: 20,
      deadline: DateTime.now().add(const Duration(days: 5)),
      lane: 'mind',
    ),
    WakzChallenge(
      id: 'ch_008',
      title: 'Cook a New Recipe',
      description: 'Prepare a recipe you have never made before. Photo the finished dish.',
      type: ChallengeType.weekly,
      category: ChallengeCategory.creative,
      verificationType: VerificationType.photo,
      targetCount: 1,
      deadline: DateTime.now().add(const Duration(days: 4)),
      lane: 'mind',
    ),
  ];

  final List<WakzChallenge> _activeChallenges = [
    WakzChallenge(
      id: 'ch_active_001',
      title: '50 Pushup Challenge',
      description: 'Complete 50 pushups today and snap a photo of your workout space.',
      type: ChallengeType.daily,
      category: ChallengeCategory.fitness,
      verificationType: VerificationType.photo,
      targetCount: 50,
      currentCount: 35,
      startedAt: DateTime.now().subtract(const Duration(hours: 3)),
      deadline: DateTime.now().add(const Duration(hours: 8)),
      lane: 'body',
    ),
    WakzChallenge(
      id: 'ch_active_002',
      title: 'Read 30 Pages',
      description: 'Read 30 pages of any book and take a photo of the page you stopped at.',
      type: ChallengeType.daily,
      category: ChallengeCategory.reading,
      verificationType: VerificationType.photo,
      targetCount: 30,
      currentCount: 12,
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      deadline: DateTime.now().add(const Duration(hours: 14)),
      lane: 'mind',
    ),
    WakzChallenge(
      id: 'ch_active_003',
      title: 'Learn 20 New Words',
      description: 'Study 20 vocabulary words in a new language this week.',
      type: ChallengeType.weekly,
      category: ChallengeCategory.skill,
      verificationType: VerificationType.screenshot,
      targetCount: 20,
      currentCount: 14,
      startedAt: DateTime.now().subtract(const Duration(days: 3)),
      deadline: DateTime.now().add(const Duration(days: 4)),
      lane: 'mind',
    ),
  ];

  final List<ChallengeBattle> _activeBattles = [
    ChallengeBattle(
      id: 'battle_001',
      challengeId: 'ch_001',
      opponentName: 'ShadowFox',
      opponentEmoji: '\u{1F98A}',
      opponentProgress: 28,
      myProgress: 35,
      targetCount: 50,
      startedAt: DateTime.now().subtract(const Duration(hours: 4)),
      endsAt: DateTime.now().add(const Duration(hours: 8)),
    ),
    ChallengeBattle(
      id: 'battle_002',
      challengeId: 'ch_002',
      opponentName: 'NightOwl',
      opponentEmoji: '\u{1F989}',
      opponentProgress: 22,
      myProgress: 12,
      targetCount: 30,
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      endsAt: DateTime.now().add(const Duration(hours: 10)),
    ),
  ];

  final List<CommunityProof> _communityFeed = [
    CommunityProof(
      id: 'proof_001',
      challengeId: 'ch_001',
      anonymousName: 'MightyPanda',
      avatarEmoji: '\u{1F43C}',
      proofDescription: 'Smashed 50 pushups before breakfast! Arms are jelly but worth it.',
      verifiedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      lane: 'body',
      likesCount: 12,
      isLiked: false,
    ),
    CommunityProof(
      id: 'proof_002',
      challengeId: 'ch_002',
      anonymousName: 'CozyKoala',
      avatarEmoji: '\u{1F428}',
      proofDescription: 'Finished chapter 4 of Atomic Habits. This book is life-changing.',
      verifiedAt: DateTime.now().subtract(const Duration(minutes: 42)),
      lane: 'mind',
      likesCount: 8,
      isLiked: true,
    ),
    CommunityProof(
      id: 'proof_003',
      challengeId: 'ch_003',
      anonymousName: 'ZenTurtle',
      avatarEmoji: '\u{1F422}',
      proofDescription: 'Morning meditation by the window. Feeling centered and calm.',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 1)),
      lane: 'soul',
      likesCount: 21,
      isLiked: false,
    ),
    CommunityProof(
      id: 'proof_004',
      challengeId: 'ch_004',
      anonymousName: 'BraveLion',
      avatarEmoji: '\u{1F981}',
      proofDescription: 'Told the barista they have an amazing smile. Made their day!',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
      lane: 'soul',
      likesCount: 34,
      isLiked: false,
    ),
    CommunityProof(
      id: 'proof_005',
      challengeId: 'ch_006',
      anonymousName: 'PixelWolf',
      avatarEmoji: '\u{1F43A}',
      proofDescription: 'Sketched a cityscape in my new notebook. Not perfect but proud.',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 3)),
      lane: 'mind',
      likesCount: 17,
      isLiked: true,
    ),
    CommunityProof(
      id: 'proof_006',
      challengeId: 'ch_005',
      anonymousName: 'SwiftDeer',
      avatarEmoji: '\u{1F98C}',
      proofDescription: 'Hit 5K steps at 11:47am with a walk around the park. Close call!',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 4)),
      lane: 'body',
      likesCount: 9,
      isLiked: false,
    ),
    CommunityProof(
      id: 'proof_007',
      challengeId: 'ch_007',
      anonymousName: 'CuriousCat',
      avatarEmoji: '\u{1F431}',
      proofDescription: 'Learned 20 Japanese words with Anki. Kanji is tough but fun.',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 5)),
      lane: 'mind',
      likesCount: 14,
      isLiked: false,
    ),
    CommunityProof(
      id: 'proof_008',
      challengeId: 'ch_008',
      anonymousName: 'HappyOtter',
      avatarEmoji: '\u{1F9A6}',
      proofDescription: 'Made pad thai from scratch. My kitchen is a mess but it was delicious.',
      verifiedAt: DateTime.now().subtract(const Duration(hours: 7)),
      lane: 'mind',
      likesCount: 27,
      isLiked: true,
    ),
  ];

  final List<WakzBadge> _allBadges = [
    WakzBadge(
      id: 'badge_001',
      name: 'First Steps',
      emoji: '\u{1F463}',
      description: 'Complete your first challenge',
      earnedAt: DateTime.now().subtract(const Duration(days: 30)),
      category: ChallengeCategory.fitness,
      tier: BadgeTier.bronze,
    ),
    WakzBadge(
      id: 'badge_002',
      name: 'Bookworm',
      emoji: '\u{1F4D6}',
      description: 'Complete 10 reading challenges',
      earnedAt: DateTime.now().subtract(const Duration(days: 20)),
      category: ChallengeCategory.reading,
      tier: BadgeTier.silver,
    ),
    WakzBadge(
      id: 'badge_003',
      name: 'Zen Master',
      emoji: '\u{1F54A}',
      description: 'Meditate for 7 days in a row',
      earnedAt: DateTime.now().subtract(const Duration(days: 14)),
      category: ChallengeCategory.meditation,
      tier: BadgeTier.gold,
    ),
    WakzBadge(
      id: 'badge_004',
      name: 'Battle Ready',
      emoji: '\u{2694}',
      description: 'Win your first battle',
      earnedAt: DateTime.now().subtract(const Duration(days: 10)),
      category: ChallengeCategory.fitness,
      tier: BadgeTier.bronze,
    ),
    WakzBadge(
      id: 'badge_005',
      name: 'Social Butterfly',
      emoji: '\u{1F98B}',
      description: 'Complete 5 social challenges',
      earnedAt: DateTime.now().subtract(const Duration(days: 5)),
      category: ChallengeCategory.social,
      tier: BadgeTier.silver,
    ),
    WakzBadge(
      id: 'badge_006',
      name: 'Iron Will',
      emoji: '\u{1F4AA}',
      description: 'Complete 50 fitness challenges',
      earnedAt: null,
      category: ChallengeCategory.fitness,
      tier: BadgeTier.gold,
    ),
    WakzBadge(
      id: 'badge_007',
      name: 'Creative Genius',
      emoji: '\u{1F3A8}',
      description: 'Complete 20 creative challenges',
      earnedAt: null,
      category: ChallengeCategory.creative,
      tier: BadgeTier.gold,
    ),
    WakzBadge(
      id: 'badge_008',
      name: 'Polyglot',
      emoji: '\u{1F30D}',
      description: 'Learn 100 words in a new language',
      earnedAt: null,
      category: ChallengeCategory.skill,
      tier: BadgeTier.silver,
    ),
  ];

  @override
  Future<List<WakzChallenge>> loadActiveChallenges() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_activeChallenges);
  }

  @override
  Future<List<WakzChallenge>> loadAvailableChallenges() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_availableChallenges);
  }

  @override
  Future<WakzChallenge> startChallenge(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    final challenge = _availableChallenges.firstWhere(
      (c) => c.id == challengeId,
    );
    final started = challenge.copyWith(
      startedAt: DateTime.now(),
    );
    _activeChallenges.add(started);
    return started;
  }

  @override
  Future<WakzChallenge> submitProof(
      String challengeId, String proofPath) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _activeChallenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) {
      throw Exception('Challenge not found: $challengeId');
    }
    final updated = _activeChallenges[index].copyWith(
      isVerified: true,
      proofImagePath: proofPath,
    );
    _activeChallenges[index] = updated;
    return updated;
  }

  @override
  Future<List<CommunityProof>> loadCommunityFeed() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_communityFeed);
  }

  @override
  Future<CommunityProof> likeCommunityProof(String proofId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _communityFeed.indexWhere((p) => p.id == proofId);
    if (index == -1) {
      throw Exception('Proof not found: $proofId');
    }
    final proof = _communityFeed[index];
    final updated = proof.copyWith(
      isLiked: !proof.isLiked,
      likesCount: proof.isLiked ? proof.likesCount - 1 : proof.likesCount + 1,
    );
    _communityFeed[index] = updated;
    return updated;
  }

  @override
  Future<ChallengeBattle> startBattle(
      String challengeId, String opponentType) async {
    await Future.delayed(const Duration(milliseconds: 230));
    final battle = ChallengeBattle(
      id: 'battle_new_${DateTime.now().millisecondsSinceEpoch}',
      challengeId: challengeId,
      opponentName: 'SwiftEagle',
      opponentEmoji: '\u{1F985}',
      opponentProgress: 0,
      myProgress: 0,
      targetCount: 50,
      startedAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(hours: 12)),
    );
    _activeBattles.add(battle);
    return battle;
  }

  @override
  Future<List<ChallengeBattle>> loadActiveBattles() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_activeBattles);
  }

  @override
  Future<WakzStats> loadStats() async {
    await Future.delayed(const Duration(milliseconds: 170));
    return WakzStats(
      totalChallengesCompleted: 47,
      totalVerified: 38,
      currentWinStreak: 5,
      longestWinStreak: 12,
      battlesWon: 18,
      battlesLost: 7,
      badges: _allBadges.where((b) => b.isEarned).toList(),
    );
  }

  @override
  Future<List<WakzBadge>> loadBadges() async {
    await Future.delayed(const Duration(milliseconds: 160));
    return List.unmodifiable(_allBadges);
  }

  @override
  Future<WakzChallenge> completeChallenge(String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _activeChallenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) {
      throw Exception('Challenge not found: $challengeId');
    }
    final updated = _activeChallenges[index].copyWith(
      isCompleted: true,
      currentCount: _activeChallenges[index].targetCount,
    );
    _activeChallenges[index] = updated;
    return updated;
  }
}

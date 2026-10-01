// gateways/mock_trending_gateway.dart — Trending v2 (mock implementation)

import '../models/trending.dart';
import 'trending_gateway.dart';

class MockTrendingGateway implements TrendingGateway {
  final List<String> _activeChallengeIds = [];
  final List<String> _completedChallengeIds = [];
  final List<String> _dismissedProfileIds = [];

  // ── v1 mock profiles ──

  static final _v1Profiles = [
    TrendingProfile(
      id: 'tp-001',
      name: 'Marcus Chen',
      emoji: '🎤',
      title: 'Underground rapper goes platinum overnight',
      trendingReason: TrendingReason.viralMoment,
      reasonText:
          'His freestyle at an open mic was filmed by a stranger and hit 40M views in 48 hours.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-001a',
          title: 'Watch the viral clip',
          description: 'Check out the original freestyle that started it all',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-001b',
          title: 'Listen to debut album',
          description: 'Stream the full project that dropped after the hype',
          lane: 1,
          dayNumber: 2,
        ),
        const TrendingChallenge(
          id: 'mc-001c',
          title: 'Share your take',
          description: 'Post your opinion on the authenticity debate',
          lane: 2,
          dayNumber: 3,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      expiresAt: DateTime.now().add(const Duration(days: 3, hours: 18)),
      tags: ['music', 'hiphop', 'viral'],
      viewCount: 128400,
      engagementScore: 87.5,
      trendScore: 72.0,
    ),
    TrendingProfile(
      id: 'tp-002',
      name: 'Aisha Patel',
      emoji: '🧬',
      title: 'Teen scientist publishes breakthrough gene therapy paper',
      trendingReason: TrendingReason.achievement,
      reasonText:
          'At 17, she co-authored a Nature paper on CRISPR applications for rare diseases.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-002a',
          title: 'Read the summary',
          description: 'A simplified breakdown of the research findings',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-002b',
          title: 'Explore CRISPR basics',
          description: 'Quick primer on the gene-editing technology',
          lane: 2,
          dayNumber: 2,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      expiresAt: DateTime.now().add(const Duration(days: 2, hours: 12)),
      tags: ['science', 'biotech', 'youth'],
      viewCount: 85200,
      engagementScore: 91.3,
      trendScore: 65.0,
    ),
    TrendingProfile(
      id: 'tp-003',
      name: 'Derek "Bones" Williams',
      emoji: '🏀',
      title: 'Former NBA player returns after career-ending injury',
      trendingReason: TrendingReason.comeback,
      reasonText:
          'Told he would never play again after a spinal fracture, he just signed a 10-day contract.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-003a',
          title: 'Watch the comeback reel',
          description: 'His journey from wheelchair to the court',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-003b',
          title: 'Read the interview',
          description: 'ESPN exclusive on his mental health journey',
          lane: 1,
          dayNumber: 2,
        ),
        const TrendingChallenge(
          id: 'mc-003c',
          title: 'Support the foundation',
          description: 'Learn about his spinal injury awareness charity',
          lane: 2,
          dayNumber: 3,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      expiresAt: DateTime.now().add(const Duration(days: 4, hours: 21)),
      tags: ['sports', 'nba', 'comeback', 'inspiration'],
      viewCount: 214300,
      engagementScore: 94.7,
      trendScore: 88.0,
    ),
  ];

  // ── v2 auto-generated profiles ──

  static final _v2AutoProfiles = [
    TrendingProfile(
      id: 'tp-auto-001',
      name: 'Luna Vasquez',
      emoji: '🎨',
      title: 'AI artist sparks museum exhibit controversy',
      trendingReason: TrendingReason.controversy,
      reasonText:
          'Her AI-assisted paintings were accepted into the Louvre\'s emerging artists program, igniting debate.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-auto-001a',
          title: 'View the exhibit',
          description: 'See the pieces that started the debate',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-auto-001b',
          title: 'Read both sides',
          description: 'Arguments for and against AI in fine art',
          lane: 2,
          dayNumber: 2,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 2, hours: 23)),
      tags: ['art', 'AI', 'controversy'],
      viewCount: 67800,
      engagementScore: 78.2,
      isAutoGenerated: true,
      sourceUrl: 'https://twitter.com/artworld/status/example1',
      sourcePlatform: 'twitter',
      trendScore: 82.5,
      lastRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TrendingProfile(
      id: 'tp-auto-002',
      name: 'Kenji Tanaka',
      emoji: '🎮',
      title: 'Speedrunner breaks "impossible" record live on stream',
      trendingReason: TrendingReason.viralMoment,
      reasonText:
          'Completed a blindfolded run of Elden Ring in under 3 hours, shattering the previous record by 45 minutes.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-auto-002a',
          title: 'Watch the highlight',
          description: 'The final boss fight that broke the internet',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-auto-002b',
          title: 'Try the challenge',
          description: 'Attempt the first area blindfolded yourself',
          lane: 2,
          dayNumber: 2,
        ),
        const TrendingChallenge(
          id: 'mc-auto-002c',
          title: 'Follow the journey',
          description: 'His 6-month training documentary',
          lane: 1,
          dayNumber: 3,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      expiresAt: DateTime.now().add(const Duration(days: 3, hours: 11)),
      tags: ['gaming', 'speedrun', 'twitch'],
      viewCount: 342100,
      engagementScore: 96.1,
      isAutoGenerated: true,
      sourceUrl: 'https://youtube.com/watch?v=example2',
      sourcePlatform: 'youtube',
      trendScore: 95.3,
      lastRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TrendingProfile(
      id: 'tp-auto-003',
      name: 'Fatima Al-Rashid',
      emoji: '📱',
      title: 'Solo dev\'s budgeting app hits #1 in 40 countries',
      trendingReason: TrendingReason.inspiration,
      reasonText:
          'Built entirely during her lunch breaks over 8 months, her app unseated a VC-backed competitor.',
      miniChallenges: [
        const TrendingChallenge(
          id: 'mc-auto-003a',
          title: 'Try the app',
          description: 'Download and explore the budgeting features',
          lane: 1,
          dayNumber: 1,
        ),
        const TrendingChallenge(
          id: 'mc-auto-003b',
          title: 'Read her story',
          description: 'The TikTok series documenting her build journey',
          lane: 2,
          dayNumber: 2,
        ),
      ],
      publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      expiresAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
      tags: ['tech', 'indie', 'motivation'],
      viewCount: 198600,
      engagementScore: 89.4,
      isAutoGenerated: true,
      sourceUrl: 'https://tiktok.com/@fatima_codes/video/example3',
      sourcePlatform: 'tiktok',
      trendScore: 78.9,
      lastRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // ── Archive (expired profiles) ──

  static final _archivedProfiles = [
    TrendingProfile(
      id: 'tp-arch-001',
      name: 'Raj Kapoor',
      emoji: '🎬',
      title: 'Bollywood star\'s surprise indie film wins Cannes',
      trendingReason: TrendingReason.achievement,
      reasonText:
          'Left blockbusters to make a \$50K film that won the Palme d\'Or.',
      miniChallenges: const [],
      publishedAt: DateTime(2026, 9, 5),
      expiresAt: DateTime(2026, 9, 10),
      tags: ['film', 'bollywood', 'cannes'],
      viewCount: 312000,
      engagementScore: 92.1,
      isAutoGenerated: true,
      sourcePlatform: 'news',
      trendScore: 90.2,
    ),
    TrendingProfile(
      id: 'tp-arch-002',
      name: 'Sophie Laurent',
      emoji: '🏋️',
      title: 'Paralympic champion breaks Olympic-level record',
      trendingReason: TrendingReason.inspiration,
      reasonText:
          'Her 100m time would have medaled at the last Olympics.',
      miniChallenges: const [],
      publishedAt: DateTime(2026, 9, 3),
      expiresAt: DateTime(2026, 9, 8),
      tags: ['sports', 'paralympics', 'records'],
      viewCount: 456000,
      engagementScore: 97.3,
      trendScore: 93.8,
    ),
    TrendingProfile(
      id: 'tp-arch-003',
      name: 'Tyler Brooks',
      emoji: '🎸',
      title: 'Garage band\'s demo tape found 20 years later goes viral',
      trendingReason: TrendingReason.viralMoment,
      reasonText:
          'A thrift store cassette turned out to be unreleased tracks that sound ahead of their time.',
      miniChallenges: const [],
      publishedAt: DateTime(2026, 9, 1),
      expiresAt: DateTime(2026, 9, 7),
      tags: ['music', 'vintage', 'viral'],
      viewCount: 189000,
      engagementScore: 81.5,
      isAutoGenerated: true,
      sourcePlatform: 'twitter',
      trendScore: 71.4,
    ),
    TrendingProfile(
      id: 'tp-arch-004',
      name: 'Mei-Ling Wu',
      emoji: '🍜',
      title: 'Street food vendor earns Michelin star',
      trendingReason: TrendingReason.achievement,
      reasonText:
          'Her \$3 noodle stall in Taipei became the cheapest Michelin-starred meal in history.',
      miniChallenges: const [],
      publishedAt: DateTime(2026, 8, 28),
      expiresAt: DateTime(2026, 9, 4),
      tags: ['food', 'michelin', 'culture'],
      viewCount: 523000,
      engagementScore: 95.8,
      isAutoGenerated: true,
      sourcePlatform: 'youtube',
      trendScore: 88.7,
    ),
  ];

  // ── All profiles combined ──

  List<TrendingProfile> get _allProfiles => [..._v1Profiles, ..._v2AutoProfiles];

  // ── v1 methods ──

  @override
  Future<TrendingFeed> loadTrendingFeed() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final visible = _allProfiles
        .where((p) => !_dismissedProfileIds.contains(p.id))
        .toList();
    return TrendingFeed(
      profiles: visible,
      lastUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<TrendingProfile> loadProfile(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _allProfiles.firstWhere((p) => p.id == id);
  }

  @override
  Future<void> startChallenge(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _activeChallengeIds.add(profileId);
  }

  @override
  Future<void> completeChallenge(String profileId, String challengeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _completedChallengeIds.add(challengeId);
  }

  @override
  Future<List<TrendingChallenge>> getActiveChallenges() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final challenges = <TrendingChallenge>[];
    for (final profile in _allProfiles) {
      if (_activeChallengeIds.contains(profile.id)) {
        for (final challenge in profile.miniChallenges) {
          challenges.add(
            challenge.copyWith(
              isCompleted: _completedChallengeIds.contains(challenge.id),
            ),
          );
        }
      }
    }
    return challenges;
  }

  @override
  Future<void> dismissProfile(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _dismissedProfileIds.add(id);
  }

  // ── v2 methods ──

  @override
  Future<TrendingPipelineStatus> getPipelineStatus() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return TrendingPipelineStatus(
      lastRunAt: DateTime.now().subtract(const Duration(hours: 2)),
      nextRunAt: DateTime.now().add(const Duration(hours: 10)),
      profilesGenerated: 3,
      profilesPublished: 2,
      isRunning: false,
    );
  }

  @override
  Future<void> refreshFeed() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulates a manual pipeline trigger
  }

  @override
  Future<List<TrendingProfile>> loadArchive() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _archivedProfiles;
  }
}

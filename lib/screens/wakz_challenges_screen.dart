// screens/wakz_challenges_screen.dart
// Main screen for Wakz Social Proof Challenges with tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wakz_challenge.dart';
import '../providers/wakz_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/battle_card.dart';
import '../widgets/wakz_challenge_card.dart';
import '../widgets/community_proof_card.dart';

class WakzChallengesScreen extends StatefulWidget {
  const WakzChallengesScreen({super.key});

  @override
  State<WakzChallengesScreen> createState() => _WakzChallengesScreenState();
}

class _WakzChallengesScreenState extends State<WakzChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<WakzProvider>();
    provider.loadActiveChallenges();
    provider.loadAvailableChallenges();
    provider.loadActiveBattles();
    provider.loadCommunityFeed();
    provider.loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsHero(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(),
                    _buildAvailableTab(),
                    _buildBattlesTab(),
                    _buildCommunityTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wakz Challenges',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Prove it. Share it. Own it.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.purple,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHero() {
    return Consumer<WakzProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purple.withValues(alpha: 0.12),
                AppColors.card,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '\${stats.totalChallengesCompleted}',
                label: 'Completed',
                color: AppColors.purple,
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              _StatItem(
                value: '\${stats.totalVerified}',
                label: 'Verified',
                color: AppColors.cyan,
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
              _StatItem(
                value: '\${stats.currentWinStreak}',
                label: 'Win Streak',
                color: AppColors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.grey,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Available'),
          Tab(text: 'Battles'),
          Tab(text: 'Community'),
        ],
      ),
    );
  }

  // --- Active Tab ---
  Widget _buildActiveTab() {
    return Consumer<WakzProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.activeChallenges.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final challenges = provider.activeChallenges;

        if (challenges.isEmpty) {
          return _buildEmptyState(
            emoji: '\u{1F3AF}',
            title: 'No active challenges',
            subtitle: 'Start a challenge from the Available tab!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return WakzChallengeCard(
              challenge: challenge,
              onSubmitProof: () {
                provider.submitProof(challenge.id, '/mock/proof.jpg');
              },
            );
          },
        );
      },
    );
  }

  // --- Available Tab ---
  Widget _buildAvailableTab() {
    return Consumer<WakzProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.availableChallenges.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final challenges = provider.availableChallenges;

        if (challenges.isEmpty) {
          return _buildEmptyState(
            emoji: '\u{1F50D}',
            title: 'No challenges available',
            subtitle: 'Check back later for new challenges!',
          );
        }

        // Group by category
        final categories = ChallengeCategory.values.where(
          (cat) => challenges.any((c) => c.category == cat),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final category in categories) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Row(
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ...challenges
                  .where((c) => c.category == category)
                  .map(
                    (challenge) => WakzChallengeCard(
                      challenge: challenge,
                      onStart: () {
                        provider.startChallenge(challenge.id);
                      },
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }

  // --- Battles Tab ---
  Widget _buildBattlesTab() {
    return Consumer<WakzProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.activeBattles.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final battles = provider.activeBattles;

        if (battles.isEmpty) {
          return _buildEmptyState(
            emoji: '\u{2694}',
            title: 'No active battles',
            subtitle: 'Challenge someone from an active challenge!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: battles.length,
          itemBuilder: (context, index) {
            return BattleCard(battle: battles[index]);
          },
        );
      },
    );
  }

  // --- Community Tab ---
  Widget _buildCommunityTab() {
    return Consumer<WakzProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.communityFeed.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final feed = provider.communityFeed;

        if (feed.isEmpty) {
          return _buildEmptyState(
            emoji: '\u{1F310}',
            title: 'Community feed is empty',
            subtitle: 'Complete a challenge to show up here!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: feed.length,
          itemBuilder: (context, index) {
            final proof = feed[index];
            return CommunityProofCard(
              proof: proof,
              onLike: () => provider.likeCommunityProof(proof.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/gamification.dart';
import '../models/xp_system.dart';
import '../providers/gamification_provider.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/reward_card.dart';
import '../widgets/leaderboard_row.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<GamificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => provider.loadAll(),
                    child: Text(
                      'Retry',
                      style: TextStyle(color: AppColors.purple),
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildHeader(provider),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabController: _tabController,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(provider: provider),
                  _LeaderboardTab(provider: provider),
                  _RewardsTab(provider: provider),
                  _LogTab(provider: provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(GamificationProvider provider) {
    final profile = provider.profile;
    if (profile == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gamification Hub',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _buildDailyBonusButton(provider),
            ],
          ),
          const SizedBox(height: 20),
          // Level hero
          _buildLevelHero(profile),
          const SizedBox(height: 20),
          // Weekly XP mini chart
          if (provider.breakdown != null)
            _buildWeeklyMiniChart(provider.breakdown!),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDailyBonusButton(GamificationProvider provider) {
    final claimed = provider.dailyBonusClaimed;
    return GestureDetector(
      onTap: claimed
          ? null
          : () async {
              final success = await provider.claimDailyBonus();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('+25 XP Daily Bonus Claimed!'),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: claimed
              ? null
              : const LinearGradient(
                  colors: [AppColors.purple, AppColors.cyan],
                ),
          color: claimed ? AppColors.cardLight : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: claimed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              claimed ? Icons.check_circle : Icons.card_giftcard_rounded,
              color: claimed ? AppColors.grey : AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              claimed ? 'Claimed' : 'Daily Bonus',
              style: TextStyle(
                color: claimed ? AppColors.grey : AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelHero(GamificationProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Level emoji and title
          Text(
            profile.currentLevel.emoji,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            'Level ${profile.currentLevel.level}',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.currentLevel.title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.totalXp} Total XP',
            style: TextStyle(
              color: AppColors.purpleSoft,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // XP progress bar
          XpProgressBar(totalXp: profile.totalXp),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Weekly', '+${profile.weeklyXp}', AppColors.cyan),
              Container(
                width: 1,
                height: 28,
                color: AppColors.divider,
              ),
              _buildStatItem(
                  'Monthly', '+${profile.monthlyXp}', AppColors.green),
              Container(
                width: 1,
                height: 28,
                color: AppColors.divider,
              ),
              _buildStatItem(
                  'Rank', '#${profile.rank}', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyMiniChart(XPBreakdown breakdown) {
    final maxVal = breakdown.byDay.values.isEmpty
        ? 1
        : breakdown.byDay.values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: breakdown.byDay.entries.map((entry) {
                final fraction = entry.value / effectiveMax;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: fraction.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.purple.withValues(alpha: 0.7),
                                    AppColors.cyan,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar Delegate ────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _TabBarDelegate({required this.tabController});

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.grey,
        indicatorColor: AppColors.purple,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Rewards'),
          Tab(text: 'Log'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ─── Overview Tab ────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final GamificationProvider provider;

  const _OverviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (provider.breakdown != null) ...[
          _buildSectionTitle('XP by Source'),
          const SizedBox(height: 12),
          _buildSourceBreakdown(provider.breakdown!),
          const SizedBox(height: 24),
          _buildSectionTitle('XP by Lane'),
          const SizedBox(height: 12),
          _buildLaneCards(provider.breakdown!),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle('Weekly Challenges'),
        const SizedBox(height: 12),
        ...provider.weeklyChallenges.map(_buildChallengeCard),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSourceBreakdown(XPBreakdown breakdown) {
    final sorted = breakdown.bySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isEmpty ? 1 : sorted.first.value;
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: sorted.map((entry) {
          final fraction = entry.value / effectiveMax;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    entry.key.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    entry.key.label,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.purple, AppColors.cyan],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: AppColors.purpleSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLaneCards(XPBreakdown breakdown) {
    const laneEmojis = {
      'Mind': '🧠',
      'Body': '💪',
      'Social': '🤝',
      'Skill': '🛠️',
    };
    const laneColors = {
      'Mind': AppColors.purple,
      'Body': AppColors.green,
      'Social': AppColors.cyan,
      'Skill': AppColors.warning,
    };

    final totalLane = breakdown.byLane.values.fold(0, (a, b) => a + b);
    final effectiveTotal = totalLane == 0 ? 1 : totalLane;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: breakdown.byLane.entries.map((entry) {
        final color = laneColors[entry.key] ?? AppColors.purple;
        final emoji = laneEmojis[entry.key] ?? '⭐';
        final pct = ((entry.value / effectiveTotal) * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.value} XP',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChallengeCard(WeeklyChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: challenge.isCompleted
                      ? AppColors.green.withValues(alpha: 0.15)
                      : AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.isCompleted
                      ? 'Done'
                      : '+${challenge.xpReward} XP',
                  style: TextStyle(
                    color: challenge.isCompleted
                        ? AppColors.green
                        : AppColors.purpleSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.cardLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: challenge.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: challenge.isCompleted
                              ? [AppColors.green, AppColors.green]
                              : [AppColors.purple, AppColors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${challenge.currentCount}/${challenge.targetCount}',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Tab ─────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  final GamificationProvider provider;

  const _LeaderboardTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.leaderboard;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Weekly Leaderboard',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rankings based on weekly XP earned',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) => LeaderboardRow(entry: entry)),
      ],
    );
  }
}

// ─── Rewards Tab ─────────────────────────────────────────────────────

class _RewardsTab extends StatelessWidget {
  final GamificationProvider provider;

  const _RewardsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Category filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(context, null, 'All'),
              ...RewardCategory.values.map(
                (cat) => _buildFilterChip(
                    context, cat, '${cat.emoji} ${cat.label}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rewards grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: provider.rewards.length,
          itemBuilder: (context, index) {
            final reward = provider.rewards[index];
            return RewardCard(
              reward: reward,
              userTotalXp: provider.profile?.totalXp ?? 0,
              onPurchase: () => _handlePurchase(context, reward),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(
      BuildContext context, RewardCategory? category, String label) {
    final isSelected = provider.rewardCategoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setRewardCategoryFilter(category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple.withValues(alpha: 0.2)
                : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.5)
                  : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.purpleSoft : AppColors.grey,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _handlePurchase(BuildContext context, RewardItem reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Unlock ${reward.name}?',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will cost ${reward.xpCost} XP. This action cannot be undone.',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.purchaseReward(reward.id);
            },
            child: Text(
              'Unlock',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Tab ─────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final GamificationProvider provider;

  const _LogTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Source filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSourceChip(context, null, 'All'),
              ...XPSource.values.map(
                (src) => _buildSourceChip(
                    context, src, '${src.emoji} ${src.label}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Transaction list
        ...provider.transactions.map(_buildTransactionRow),
        if (provider.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, color: AppColors.grey, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions found',
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSourceChip(
      BuildContext context, XPSource? source, String label) {
    final isSelected = provider.transactionFilter == source;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setTransactionFilter(source),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple.withValues(alpha: 0.2)
                : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.5)
                  : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.purpleSoft : AppColors.grey,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(XPTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                tx.source.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      tx.source.label,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (tx.lane != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        tx.lane!,
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatTime(tx.earnedAt),
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${tx.amount}',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

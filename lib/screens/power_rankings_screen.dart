import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/power_rankings.dart';
import '../providers/power_rankings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lane_rank_card.dart';
import '../widgets/weekly_score_chart.dart';

class PowerRankingsScreen extends StatefulWidget {
  const PowerRankingsScreen({super.key});

  @override
  State<PowerRankingsScreen> createState() => _PowerRankingsScreenState();
}

class _PowerRankingsScreenState extends State<PowerRankingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroScoreAnimation;
  late final Animation<double> _heroFadeAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _heroScoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _heroFadeAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PowerRankingsProvider>().loadAll().then((_) {
        _heroController.forward();
      });
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PowerRankingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.activeDigest == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.purple,
              ),
            );
          }

          if (provider.error != null && provider.activeDigest == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAll(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final digest = provider.activeDigest;
          if (digest == null) return const SizedBox.shrink();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeekSelector(context, provider, digest),
                      const SizedBox(height: 20),
                      _buildHeroSection(digest),
                      const SizedBox(height: 24),
                      _buildLaneGrid(digest),
                      const SizedBox(height: 24),
                      if (provider.history.isNotEmpty)
                        WeeklyScoreChart(
                          history: provider.history,
                          highlightWeekIndex: provider.history.length - 1,
                        ),
                      const SizedBox(height: 24),
                      _buildHighlightsSection(digest),
                      const SizedBox(height: 24),
                      _buildRecapButton(context, provider, digest),
                      const SizedBox(height: 24),
                      _buildImprovementTips(digest),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, PowerRankingsProvider provider) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      snap: true,
      title: const Text(
        'Power Rankings',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (provider.selectedWeek != null)
          TextButton(
            onPressed: () {
              provider.clearSelectedWeek();
              _heroController.reset();
              _heroController.forward();
            },
            child: const Text(
              'Current Week',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekSelector(
      BuildContext context, PowerRankingsProvider provider, WeeklyDigest digest) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final weekNum = 12 - index;
          final isSelected = digest.weekNumber == weekNum;
          final weekStart = DateTime.now()
              .subtract(Duration(days: DateTime.now().weekday - 1))
              .subtract(Duration(days: 7 * index));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (index == 0) {
                  provider.clearSelectedWeek();
                  provider.loadCurrentDigest();
                } else {
                  provider.loadDigestForWeek(weekStart);
                }
                _heroController.reset();
                _heroController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? AppColors.purple : AppColors.card,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.purple
                        : AppColors.divider.withValues(alpha: 0.5),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  index == 0 ? 'This Week' : 'Week $weekNum',
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.grey,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(WeeklyDigest digest) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                digest.tier.color.withValues(alpha: 0.15),
                AppColors.card,
                AppColors.card,
              ],
            ),
            border: Border.all(
              color: digest.tier.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: digest.tier.color.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedScore(digest),
                  const SizedBox(width: 24),
                  FadeTransition(
                    opacity: _heroFadeAnimation,
                    child: _buildTierBadge(digest),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _heroFadeAnimation,
                child: _buildScoreDelta(digest),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _heroFadeAnimation,
                child: Text(
                  'Week ${digest.weekNumber} Performance',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _heroFadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat(
                      Icons.check_circle_outline,
                      '${digest.totalActionsCompleted}',
                      'Actions',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.divider,
                    ),
                    _buildMiniStat(
                      Icons.stars_rounded,
                      '${digest.totalXpEarned}',
                      'XP Earned',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.divider,
                    ),
                    _buildMiniStat(
                      Icons.local_fire_department_rounded,
                      '${digest.laneRankings.map((l) => l.streakDays).reduce((a, b) => a > b ? a : b)}d',
                      'Best Streak',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedScore(WeeklyDigest digest) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: digest.tier.color
                        .withValues(alpha: 0.2 * _pulseAnimation.value),
                    blurRadius: 30 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: (digest.overallScore / 100) * _heroScoreAnimation.value,
            strokeWidth: 6,
            backgroundColor: AppColors.cardLight,
            valueColor: AlwaysStoppedAnimation<Color>(digest.tier.color),
          ),
        ),
        AnimatedBuilder(
          animation: _heroScoreAnimation,
          builder: (context, child) {
            final displayScore =
                (digest.overallScore * _heroScoreAnimation.value).round();
            return Text(
              '$displayScore',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTierBadge(WeeklyDigest digest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: digest.tier.color.withValues(alpha: 0.15),
            border: Border.all(
              color: digest.tier.color.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: digest.tier.glowColor,
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                digest.tier.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                digest.tier.displayName,
                style: TextStyle(
                  color: digest.tier.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tier',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDelta(WeeklyDigest digest) {
    final delta = digest.scoreDelta;
    final isPositive = delta > 0;
    final color =
        isPositive ? const Color(0xFF34D399) : const Color(0xFFEF4444);
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    if (delta == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_flat, color: AppColors.grey, size: 18),
          const SizedBox(width: 4),
          Text(
            'No change from last week',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}$delta from last week',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.purple, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLaneGrid(WeeklyDigest digest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lane Rankings',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: digest.laneRankings.length,
          itemBuilder: (context, index) {
            return LaneRankCard(ranking: digest.laneRankings[index]);
          },
        ),
      ],
    );
  }

  Widget _buildHighlightsSection(WeeklyDigest digest) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Weekly Highlights',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...digest.highlights.map((highlight) {
            final emoji = _getHighlightEmoji(highlight);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      highlight,
                      style: const TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getHighlightEmoji(String highlight) {
    final lower = highlight.toLowerCase();
    if (lower.contains('streak')) return '🔥';
    if (lower.contains('meditation') || lower.contains('mind')) return '🧘';
    if (lower.contains('forge') || lower.contains('lesson')) return '📚';
    if (lower.contains('check-in') || lower.contains('community')) return '🤝';
    if (lower.contains('elite') || lower.contains('best')) return '🏆';
    if (lower.contains('record') || lower.contains('milestone')) return '⭐';
    if (lower.contains('body') || lower.contains('workout')) return '💪';
    if (lower.contains('skill') || lower.contains('practice')) return '🎯';
    if (lower.contains('score') || lower.contains('tier')) return '📊';
    return '✨';
  }

  Widget _buildRecapButton(
      BuildContext context, PowerRankingsProvider provider, WeeklyDigest digest) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isGeneratingRecap
                ? null
                : () async {
                    await provider.generateRecap();
                    if (provider.recapCard != null && mounted) {
                      _showRecapCardDialog(context, provider.recapCard!);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: provider.isGeneratingRecap
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Recap Card',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showRecapCardDialog(BuildContext context, RecapCard recap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Recap Card',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecapCardPreview(recap),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: recap.shareText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard!'),
                              backgroundColor: AppColors.purple,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded,
                                color: AppColors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Copy Text',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecapCardPreview(RecapCard recap) {
    final digest = recap.weekDigest;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark,
            AppColors.card,
          ],
        ),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ONO Power Rankings',
                style: TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Week ${digest.weekNumber}',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${digest.overallScore}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${digest.tier.emoji} ${digest.tier.displayName}',
                    style: TextStyle(
                      color: digest.tier.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/100 overall',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          ...digest.laneRankings.map((lane) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(lane.laneEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    lane.lane.substring(0, 1).toUpperCase() +
                        lane.lane.substring(1),
                    style: const TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${lane.score}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    lane.trend.icon,
                    color: lane.trend.color,
                    size: 16,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImprovementTips(WeeklyDigest digest) {
    final tipsToShow = digest.laneRankings
        .where((l) => l.score < 85)
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    if (tipsToShow.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Level Up Tips',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tipsToShow.map((lane) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: lane.laneColor.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        lane.laneEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lane.lane.substring(0, 1).toUpperCase()}${lane.lane.substring(1)} (${lane.score}/100)',
                          style: TextStyle(
                            color: lane.laneColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lane.improvementTip,
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

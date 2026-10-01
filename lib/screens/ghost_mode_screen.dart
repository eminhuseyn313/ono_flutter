import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ghost_mode.dart';
import '../providers/ghost_mode_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ghost_comparison_chart.dart';

/// Full-screen Ghost Mode view.
///
/// Sections:
///   1. Hero — "Beat Your Ghost" with animated ghost icon
///   2. Overall comparison card
///   3. Per-lane comparison cards
///   4. Weekly challenge card
///   5. Ghost history mini-charts
class GhostModeScreen extends StatefulWidget {
  const GhostModeScreen({super.key});

  @override
  State<GhostModeScreen> createState() => _GhostModeScreenState();
}

class _GhostModeScreenState extends State<GhostModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ghostBob;

  @override
  void initState() {
    super.initState();
    _ghostBob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Initial data load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GhostModeProvider>().refreshSnapshots();
    });
  }

  @override
  void dispose() {
    _ghostBob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<GhostModeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.comparison == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.errorMessage != null && provider.comparison == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.warning, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshSnapshots(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final comparison = provider.comparison;
          if (comparison == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: () => provider.refreshSnapshots(),
            child: ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 32,
              ),
              children: [
                _HeroSection(bobController: _ghostBob),
                const SizedBox(height: 24),
                _OverallComparisonCard(comparison: comparison),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Lane Breakdown'),
                const SizedBox(height: 12),
                _LaneCards(comparison: comparison),
                const SizedBox(height: 20),
                if (provider.weeklyChallenge != null) ...[
                  _WeeklyChallengeCard(challenge: provider.weeklyChallenge!),
                  const SizedBox(height: 20),
                ],
                if (provider.ghostHistory.length > 1) ...[
                  _SectionTitle(title: 'Ghost History'),
                  const SizedBox(height: 12),
                  _GhostHistoryRow(snapshots: provider.ghostHistory),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// -- Hero Section -------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final AnimationController bobController;

  const _HeroSection({required this.bobController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: bobController,
          builder: (context, child) {
            final offset = Tween<double>(begin: -4, end: 4)
                .animate(CurvedAnimation(
                  parent: bobController,
                  curve: Curves.easeInOut,
                ))
                .value;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.purpleSoft, AppColors.purple],
            ).createShader(bounds),
            child: const Icon(Icons.person_outline, size: 64, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Beat Your Ghost',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Compete against last week\'s you',
          style: TextStyle(color: AppColors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

// -- Overall Comparison Card --------------------------------------------------

class _OverallComparisonCard extends StatelessWidget {
  final GhostComparison comparison;

  const _OverallComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final delta = comparison.overallDelta;
    final isAhead = delta > 0;
    final deltaColor = isAhead ? AppColors.success : AppColors.warning;
    final deltaSign = isAhead ? '+' : '';

    return _GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$deltaSign${(delta * 100).round()}%',
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ScoreCircle(
                label: 'You',
                score: comparison.current.overallScore,
                color: AppColors.purple,
              ),
              const SizedBox(width: 24),
              _ScoreCircle(
                label: 'Ghost',
                score: comparison.ghost.overallScore,
                color: AppColors.purple.withValues(alpha: 0.35),
              ),
              const Spacer(),
              Icon(
                isAhead ? Icons.trending_up : Icons.trending_down,
                color: deltaColor,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 20),
          GhostComparisonChart(comparison: comparison),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreCircle({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score,
                strokeWidth: 5,
                backgroundColor: AppColors.cardLight,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text(
                '${(score * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

// -- Per-Lane Cards -----------------------------------------------------------

class _LaneCards extends StatelessWidget {
  final GhostComparison comparison;

  const _LaneCards({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final lanes = comparison.current.laneScores.keys.toList();
    final deltas = comparison.laneDeltas;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: lanes.length,
      itemBuilder: (context, index) {
        final lane = lanes[index];
        final current = comparison.current.laneScores[lane] ?? 0.0;
        final ghost = comparison.ghost.laneScores[lane] ?? 0.0;
        final delta = deltas[lane] ?? 0.0;
        final isAhead = delta > 0;

        return _GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      lane,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isAhead ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isAhead ? AppColors.success : AppColors.warning,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(current * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Ghost: ${(ghost * 100).round()}%',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              // Mini comparison bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: AppColors.cardLight),
                      FractionallySizedBox(
                        widthFactor: ghost.clamp(0.0, 1.0),
                        child: Container(
                          color: AppColors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: current.clamp(0.0, 1.0),
                        child: Container(
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -- Weekly Challenge Card ----------------------------------------------------

class _WeeklyChallengeCard extends StatelessWidget {
  final WeeklyGhostChallenge challenge;

  const _WeeklyChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progressText =
        '${challenge.actualBeatCount}/${challenge.targetBeatCount}';

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events,
                    color: AppColors.purple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Challenge',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Beat your ghost in $progressText lanes this week',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Done!',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 10,
              backgroundColor: AppColors.cardLight,
              valueColor: AlwaysStoppedAnimation(
                challenge.isCompleted ? AppColors.success : AppColors.purple,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Beaten lane chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: challenge.lanesBeaten.map((lane) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  lane,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -- Ghost History Row --------------------------------------------------------

class _GhostHistoryRow extends StatelessWidget {
  final List<GhostSnapshot> snapshots;

  const _GhostHistoryRow({required this.snapshots});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: snapshots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final snap = snapshots[index];
          return _GhostHistoryMiniCard(snapshot: snap);
        },
      ),
    );
  }
}

class _GhostHistoryMiniCard extends StatelessWidget {
  final GhostSnapshot snapshot;

  const _GhostHistoryMiniCard({required this.snapshot});

  String _weekLabel(DateTime weekStart) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final thisMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: todayWeekday - 1));
    final diff = thisMonday.difference(weekStart).inDays;
    if (diff == 0) return 'This Week';
    if (diff == 7) return 'Last Week';
    return '${diff ~/ 7} Weeks Ago';
  }

  @override
  Widget build(BuildContext context) {
    final lanes = snapshot.laneScores.keys.toList();
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekLabel(snapshot.weekStart),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(snapshot.overallScore * 100).round()}% overall',
              style: const TextStyle(color: AppColors.grey, fontSize: 11),
            ),
            const SizedBox(height: 10),
            // Mini bar chart per lane
            ...lanes.map((lane) {
              final score = snapshot.laneScores[lane] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        lane.substring(0, lane.length.clamp(0, 3)),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 5,
                          child: Stack(
                            children: [
                              Container(color: AppColors.cardLight),
                              FractionallySizedBox(
                                widthFactor: score.clamp(0.0, 1.0),
                                child: Container(color: AppColors.purple),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// -- Section Title ------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// -- Glassmorphic Card --------------------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

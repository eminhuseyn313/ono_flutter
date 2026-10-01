import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/legacy_score.dart';
import '../providers/legacy_score_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tier_progress_bar.dart';
import '../widgets/tier_up_celebration.dart';

/// Full-screen Legacy Score view: hero score + tier badge, a vertical tier
/// journey path, progress-to-next-tier bar, recent point gains, milestone
/// cards, and a score history sparkline.
class LegacyScoreScreen extends StatefulWidget {
  const LegacyScoreScreen({super.key});

  // TODO: replace with real auth user id
  static const userId = 'user_1';

  @override
  State<LegacyScoreScreen> createState() => _LegacyScoreScreenState();
}

class _LegacyScoreScreenState extends State<LegacyScoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _celebrationShowing = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<LegacyScoreProvider>().load(LegacyScoreScreen.userId);
      if (mounted) _entranceController.forward();
      _checkTierUp();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _checkTierUp() {
    if (_celebrationShowing) return;
    final provider = context.read<LegacyScoreProvider>();
    final pending = provider.pendingTierUp;
    if (pending != null) {
      _celebrationShowing = true;
      showTierUpCelebration(context, tier: pending).then((_) {
        _celebrationShowing = false;
        provider.acknowledgeTierUp();
      });
    }
  }

  Animation<double> _staggerFade(int index, int total) {
    final start = (index / total) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _staggerSlide(int index, int total) {
    final start = (index / total) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<LegacyScoreProvider>(
        builder: (context, provider, _) {
          // Fire the celebration if points were added while this screen
          // is already mounted (e.g. via a debug action button).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.pendingTierUp != null) _checkTierUp();
          });

          if (provider.loading && provider.score == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.score == null) {
            return _buildError(provider);
          }

          return Stack(
            children: [
              _buildAmbientGlow(provider.tier.color),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _staggered(0, 7, _buildHeroSection(provider)),
                          const SizedBox(height: 28),
                          _staggered(1, 7, _buildTierJourney(provider)),
                          const SizedBox(height: 28),
                          _staggered(2, 7, _buildSparkline(provider)),
                          const SizedBox(height: 28),
                          _staggered(3, 7, _buildRecentGains(provider)),
                          const SizedBox(height: 28),
                          _staggered(4, 7, _buildMilestones(provider)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _staggered(int index, int total, Widget child) {
    return FadeTransition(
      opacity: _staggerFade(index, total),
      child: SlideTransition(
        position: _staggerSlide(index, total),
        child: child,
      ),
    );
  }

  Widget _buildAmbientGlow(Color tierColor) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tierColor.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background.withValues(alpha: 0.85),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
        ),
      ),
      title: const Text(
        'Legacy Score',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────
  Widget _buildHeroSection(LegacyScoreProvider provider) {
    final tier = provider.tier;
    final tierColor = tier.color;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.20),
            AppColors.card.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(color: tierColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tierColor, tierColor.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tier.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      tier.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${provider.displayScore}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tier.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.95),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              TierProgressBar(
                currentTier: tier,
                progress: provider.progressToNextTier,
                currentScore: provider.totalScore,
              ),
              if (tier.next != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${provider.pointsToNextTier} pts to ${tier.next!.label}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tier journey ─────────────────────────────────────────────────
  Widget _buildTierJourney(LegacyScoreProvider provider) {
    final tiers = LegacyTier.values;
    final currentIndex = tiers.indexOf(provider.tier);

    return _sectionCard(
      title: 'Your Journey',
      icon: Icons.route_rounded,
      child: Column(
        children: List.generate(tiers.length, (i) {
          final t = tiers[i];
          final isPast = i < currentIndex;
          final isCurrent = i == currentIndex;
          final isFuture = i > currentIndex;
          final isLast = i == tiers.length - 1;

          return _tierJourneyRow(
            tier: t,
            isPast: isPast,
            isCurrent: isCurrent,
            isFuture: isFuture,
            isLast: isLast,
          );
        }),
      ),
    );
  }

  Widget _tierJourneyRow({
    required LegacyTier tier,
    required bool isPast,
    required bool isCurrent,
    required bool isFuture,
    required bool isLast,
  }) {
    final color = tier.color;
    final dimAlpha = isFuture ? 0.35 : 1.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: isCurrent ? 40 : 32,
                height: isCurrent ? 40 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isPast || isCurrent)
                      ? color.withValues(alpha: isCurrent ? 0.25 : 0.15)
                      : AppColors.cardLight,
                  border: Border.all(
                    color: (isPast || isCurrent)
                        ? color
                        : AppColors.divider,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tier.emoji,
                    style: TextStyle(fontSize: isCurrent ? 18 : 14),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isPast
                        ? color.withValues(alpha: 0.5)
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: isCurrent ? 4 : 6),
              child: Opacity(
                opacity: dimAlpha,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier.label,
                          style: TextStyle(
                            color: isCurrent ? AppColors.white : AppColors.greyLight,
                            fontSize: isCurrent ? 17 : 15,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CURRENT',
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                        if (isPast) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, size: 14, color: color),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tier.description,
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier.maxScore != null
                          ? '${tier.minScore} – ${tier.maxScore} pts'
                          : '${tier.minScore}+ pts',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sparkline ────────────────────────────────────────────────────
  Widget _buildSparkline(LegacyScoreProvider provider) {
    // Reconstruct a cumulative running total from oldest to newest events.
    final events = provider.history.reversed.toList();
    final points = <double>[];
    var running = 0.0;
    for (final e in events) {
      running += e.points;
      points.add(running);
    }
    if (points.isEmpty) points.add(provider.totalScore.toDouble());

    return _sectionCard(
      title: 'Score History',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 90,
        child: CustomPaint(
          size: Size.infinite,
          painter: _SparklinePainter(
            values: points,
            color: provider.tier.color,
          ),
        ),
      ),
    );
  }

  // ── Recent gains ─────────────────────────────────────────────────
  Widget _buildRecentGains(LegacyScoreProvider provider) {
    final events = provider.recentEvents;

    return _sectionCard(
      title: 'Recent Point Gains',
      icon: Icons.bolt_rounded,
      child: events.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Complete actions to start earning points.',
                style: TextStyle(color: AppColors.grey.withValues(alpha: 0.9), fontSize: 13),
              ),
            )
          : Column(
              children: events.map((e) => _gainRow(e)).toList(),
            ),
    );
  }

  Widget _gainRow(LegacyScoreEvent event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: AppColors.purpleSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatRelativeTime(event.earnedAt),
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${event.points}',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ── Milestones ───────────────────────────────────────────────────
  Widget _buildMilestones(LegacyScoreProvider provider) {
    return _sectionCard(
      title: 'Milestones',
      icon: Icons.emoji_events_rounded,
      child: Column(
        children: provider.milestones.map((m) => _milestoneCard(m)).toList(),
      ),
    );
  }

  Widget _milestoneCard(LegacyMilestone milestone) {
    final unlocked = milestone.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.warning.withValues(alpha: 0.10)
            : AppColors.cardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppColors.warning.withValues(alpha: 0.35)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.card,
              border: Border.all(
                color: unlocked
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.divider,
              ),
            ),
            child: Icon(
              unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
              size: 18,
              color: unlocked ? AppColors.warning : AppColors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    color: unlocked ? AppColors.white : AppColors.greyLight,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.description,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${milestone.scoreThreshold} pts',
                  style: TextStyle(
                    color: unlocked ? AppColors.warning : AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  // ── Shared section wrapper ───────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: AppColors.purpleSoft),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(LegacyScoreProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                provider.load(LegacyScoreScreen.userId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimalist sparkline painter for the score-history section.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1.0 : (maxVal - minVal);

    final stepX = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = values.length > 1 ? i * stepX : size.width / 2;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - (normalized * size.height * 0.85) - 6;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(values.length > 1 ? (values.length - 1) * stepX : size.width / 2, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // End-point glow dot.
    if (values.isNotEmpty) {
      final lastX = values.length > 1 ? (values.length - 1) * stepX : size.width / 2;
      final lastNorm = (values.last - minVal) / range;
      final lastY = size.height - (lastNorm * size.height * 0.85) - 6;

      canvas.drawCircle(
        Offset(lastX, lastY),
        6,
        Paint()..color = color.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        3.5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

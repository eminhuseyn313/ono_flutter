import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/analytics.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lane_progress_chart.dart';
import '../widgets/stat_chart_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAnalytics();
    });
  }

  Future<void> _onRefresh() async {
    await context
        .read<AnalyticsProvider>()
        .loadAnalytics(period: context.read<AnalyticsProvider>().selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.summary == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load analytics',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _onRefresh,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final summary = provider.summary;
          if (summary == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildPeriodSelector(provider),
                const SizedBox(height: 24),
                _buildOverviewSection(summary),
                const SizedBox(height: 24),
                _buildStatCards(summary),
                const SizedBox(height: 24),
                _buildLaneBreakdown(summary, provider),
                const SizedBox(height: 24),
                _buildXpSection(summary.xp),
                const SizedBox(height: 24),
                _buildStreakSection(summary.streaks),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    return Row(
      children: AnalyticsPeriod.values.map((period) {
        final isSelected = provider.selectedPeriod == period;
        final label = switch (period) {
          AnalyticsPeriod.week => 'Week',
          AnalyticsPeriod.month => 'Month',
          AnalyticsPeriod.quarter => 'Quarter',
          AnalyticsPeriod.year => 'Year',
        };

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => provider.changePeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.purple.withValues(alpha: 0.2)
                      : AppColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.purple.withValues(alpha: 0.5)
                        : AppColors.divider.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.purpleSoft : AppColors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewSection(AnalyticsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Score',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _OverallScoreRingPainter(
                score: summary.overallScore,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.overallScore.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(AnalyticsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: StatChartCard(
            title: 'Actions',
            value: '${summary.totalActions}',
            trend: TrendDirection.up,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatChartCard(
            title: 'Journals',
            value: '${summary.totalJournals}',
            trend: TrendDirection.up,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatChartCard(
            title: 'Reflections',
            value: '${summary.totalReflections}',
            trend: TrendDirection.neutral,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildLaneBreakdown(
      AnalyticsSummary summary, AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lane Breakdown',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...summary.lanes.map((lane) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LaneProgressChart(
                lane: lane,
                onTap: () {
                  provider.loadLaneDetail(lane.laneName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Loading ${lane.laneName} details...',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                      backgroundColor: AppColors.card,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }

  Widget _buildXpSection(XpAnalytics xp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Experience',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.purpleDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lv.${xp.currentLevel} ${xp.levelName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP total
          Text(
            '${xp.totalXp} XP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar to next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Level',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    '${(xp.progressToNext * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purpleSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: AppColors.cardLight),
                      FractionallySizedBox(
                        widthFactor: xp.progressToNext,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.purple, AppColors.purpleSoft],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _xpStatItem('Avg Daily', '${xp.avgDailyXp}'),
              Container(
                width: 1,
                height: 30,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _xpStatItem('Best Day', '${xp.bestDayXp}'),
            ],
          ),
          const SizedBox(height: 16),
          // Sparkline
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _XpSparklinePainter(dataPoints: xp.xpHistory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection(StreakAnalytics streaks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streaks',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _streakStatCard(
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.warning,
                  label: 'Current',
                  value: '${streaks.currentStreak}',
                  unit: 'days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _streakStatCard(
                  icon: Icons.emoji_events,
                  iconColor: AppColors.purple,
                  label: 'Longest',
                  value: '${streaks.longestStreak}',
                  unit: 'days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _streakStatCard(
                  icon: Icons.calendar_today,
                  iconColor: AppColors.cyan,
                  label: 'Active',
                  value: '${streaks.totalActiveDays}',
                  unit: 'days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Last 30 Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildHeatmapGrid(streaks.last30Days),
        ],
      ),
    );
  }

  Widget _streakStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(Map<int, bool> last30Days) {
    // 7 columns (Mon-Sun), ~5 rows
    const cols = 7;
    final totalDays = 35; // 5 rows x 7 cols to cover 30 days with padding
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Day labels
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Grid
        ...List.generate(5, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(cols, (col) {
                final dayOffset = row * cols + col;
                // Map grid position to day offset (29 = oldest, 0 = today)
                final actualDay = 29 - dayOffset;
                final isActive = actualDay >= 0 && actualDay < 30
                    ? (last30Days[actualDay] ?? false)
                    : false;
                final isInRange = actualDay >= 0 && actualDay < 30;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isInRange
                              ? Colors.transparent
                              : isActive
                                  ? AppColors.purple.withValues(alpha: 0.8)
                                  : AppColors.cardLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

class _OverallScoreRingPainter extends CustomPainter {
  final double score;

  _OverallScoreRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.cardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score ring
    final scorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          AppColors.purpleDark,
          AppColors.purple,
          AppColors.purpleSoft,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverallScoreRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

class _XpSparklinePainter extends CustomPainter {
  final List<DataPoint> dataPoints;

  _XpSparklinePainter({required this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final values = dataPoints.map((dp) => dp.value).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final linePaint = Paint()
      ..color = AppColors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.purple.withValues(alpha: 0.25),
          AppColors.purple.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / effectiveMax) * (size.height - 4);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw end dot
    final lastX = values.length == 1
        ? size.width / 2
        : size.width;
    final lastY =
        size.height - (values.last / effectiveMax) * (size.height - 4);
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.5,
      Paint()
        ..color = AppColors.purple
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      5.5,
      Paint()
        ..color = AppColors.purple.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _XpSparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}

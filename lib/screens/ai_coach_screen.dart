import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/ai_coach.dart';
import '../providers/ai_coach_provider.dart';
import '../widgets/insight_card.dart';
import '../widgets/coach_tip_card.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiCoachProvider>().loadCoachData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Coach',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<CoachTone>(
            icon: const Icon(Icons.tune, color: AppColors.grey),
            color: AppColors.card,
            onSelected: (tone) {
              context.read<AiCoachProvider>().setPreferredTone(tone);
            },
            itemBuilder: (_) => CoachTone.values
                .map((tone) => PopupMenuItem(
                      value: tone,
                      child: Text(
                        tone.label,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Consumer<AiCoachProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.coachData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.coachData == null) {
            return Center(
              child: Text(
                'No coach data available',
                style: GoogleFonts.plusJakartaSans(color: AppColors.grey),
              ),
            );
          }

          final data = provider.coachData!;

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: () => provider.loadCoachData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall score ring
                  _buildScoreHeader(data),

                  const SizedBox(height: 20),

                  // Daily tip
                  if (provider.dailyTip != null)
                    CoachTipCard(
                      tip: provider.dailyTip!,
                      onBookmark: () => provider.toggleTipBookmark(),
                    ),

                  const SizedBox(height: 24),

                  // Insights section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Smart Insights',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (provider.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.unreadCount} new',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...provider.activeInsights.map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InsightCard(
                          insight: insight,
                          onTap: () => provider.markInsightRead(insight.id),
                          onDismiss: () =>
                              provider.dismissInsight(insight.id),
                          onAction: insight.actionRoute != null
                              ? () => context.push(insight.actionRoute!)
                              : null,
                        ),
                      )),

                  if (provider.activeInsights.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.green, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'New insights will appear as patterns emerge.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreHeader(CoachData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ScoreRingPainter(data.overallScore / 100),
              child: Center(
                child: Text(
                  '${data.overallScore.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Score',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.streakDays}-day streak',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: data.laneScores.entries.map((entry) {
                    final color = _laneColor(entry.key);
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${entry.value.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            entry.key,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _laneColor(String lane) {
    switch (lane) {
      case 'Mind':
        return AppColors.purple;
      case 'Body':
        return AppColors.cyan;
      case 'Social':
        return AppColors.green;
      case 'Skill':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;

  _ScoreRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.cardLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      rect,
      -3.14159 / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.purple, AppColors.cyan],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

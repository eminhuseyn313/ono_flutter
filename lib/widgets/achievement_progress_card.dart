import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';

class AchievementProgressCard extends StatelessWidget {
  final AchievementStats stats;
  final List<Achievement> lockedAchievements;

  const AchievementProgressCard({
    super.key,
    required this.stats,
    required this.lockedAchievements,
  });

  String _categoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return 'Streaks';
      case AchievementCategory.actions:
        return 'Actions';
      case AchievementCategory.lanes:
        return 'Lanes';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  Color _categoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return const Color(0xFFEF4444);
      case AchievementCategory.actions:
        return AppColors.green;
      case AchievementCategory.lanes:
        return AppColors.cyan;
      case AchievementCategory.social:
        return AppColors.purpleSoft;
      case AchievementCategory.milestones:
        return AppColors.warning;
      case AchievementCategory.special:
        return AppColors.purple;
    }
  }

  int _categoryTotal(AchievementCategory category) {
    // Hardcoded totals per category based on our mock data
    switch (category) {
      case AchievementCategory.streak:
        return 3;
      case AchievementCategory.actions:
        return 3;
      case AchievementCategory.lanes:
        return 4;
      case AchievementCategory.social:
        return 2;
      case AchievementCategory.milestones:
        return 2;
      case AchievementCategory.special:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = stats.totalAchievements > 0
        ? stats.unlockedCount / stats.totalAchievements
        : 0.0;

    // Find next achievement (locked, highest progress)
    Achievement? nextAchievement;
    if (lockedAchievements.isNotEmpty) {
      nextAchievement = lockedAchievements.reduce((a, b) =>
          a.progressPercent > b.progressPercent ? a : b);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with circular progress
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: overallProgress,
                    backgroundColor: AppColors.cardLight,
                    progressColor: AppColors.purple,
                    strokeWidth: 6,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(overallProgress * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Stats summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Progress',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.unlockedCount} of ${stats.totalAchievements} achievements unlocked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.totalXpEarned} XP Earned',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Category breakdown
          Text(
            'Category Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.greyLight,
            ),
          ),
          const SizedBox(height: 12),
          ...AchievementCategory.values.map((category) {
            final unlocked = stats.categoryProgress[category] ?? 0;
            final total = _categoryTotal(category);
            final progress = total > 0 ? unlocked / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      _categoryLabel(category),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.cardLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _categoryColor(category),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$unlocked/$total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Next achievement preview
          if (nextAchievement != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: nextAchievement.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      nextAchievement.icon,
                      color: nextAchievement.color.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Up: ${nextAchievement.title}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextAchievement.currentProgress}/${nextAchievement.requiredProgress} - ${(nextAchievement.progressPercent * 100).round()}% complete',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${nextAchievement.xpReward} XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purpleSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

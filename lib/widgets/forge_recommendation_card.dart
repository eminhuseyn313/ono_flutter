// widgets/forge_recommendation_card.dart — Forge Recommendation Card

import 'package:flutter/material.dart';

import '../models/forge.dart';

class ForgeRecommendationCard extends StatelessWidget {
  final ForgeRecommendation recommendation;
  final ForgeCourse? course;
  final VoidCallback? onTap;

  const ForgeRecommendationCard({
    super.key,
    required this.recommendation,
    this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final laneColors = {
      'mind': const Color(0xFFC8894A),
      'body': const Color(0xFF6FA386),
      'social': const Color(0xFF6A89B0),
      'skill': const Color(0xFFE2B354),
    };
    final color = laneColors[course?.lane ?? ''] ?? const Color(0xFFC8894A);

    final basisLabels = {
      RecommendationBasis.laneScore: 'Based on your lane scores',
      RecommendationBasis.completionHistory: 'Based on what you\'ve completed',
      RecommendationBasis.roleModelAffinity: 'From your favorite mentors',
      RecommendationBasis.popular: 'Popular with others',
    };

    final basisIcons = {
      RecommendationBasis.laneScore: Icons.analytics_outlined,
      RecommendationBasis.completionHistory: Icons.history,
      RecommendationBasis.roleModelAffinity: Icons.people_outline,
      RecommendationBasis.popular: Icons.trending_up,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D22) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match score badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(recommendation.matchScore * 100).toStringAsFixed(0)}% match',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (course != null)
                  Text(
                    course!.roleModelEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Course title
            Text(
              course?.title ?? 'Course',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Reason
            Text(
              recommendation.reason,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Basis
            Row(
              children: [
                Icon(
                  basisIcons[recommendation.basedOn] ?? Icons.auto_awesome,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    basisLabels[recommendation.basedOn] ?? '',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Difficulty + duration
            if (course != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _difficultyChip(course!.difficulty, isDark),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${course!.totalMinutes}m',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _difficultyChip(String difficulty, bool isDark) {
    final colors = {
      'beginner': const Color(0xFF6FA386),
      'intermediate': const Color(0xFFE2B354),
      'advanced': const Color(0xFFE0605A),
    };
    final color = colors[difficulty] ?? const Color(0xFFC8894A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty[0].toUpperCase() + difficulty.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

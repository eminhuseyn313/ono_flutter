import 'package:flutter/material.dart';

import '../models/trending.dart';
import '../theme/app_theme.dart';

/// Compact card for the trending feed view.
class TrendingProfileCard extends StatelessWidget {
  final TrendingProfile profile;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const TrendingProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _reasonColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _reasonColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReasonBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Countdown
                      _buildCountdown(),
                      const SizedBox(width: 12),
                      // Progress dots
                      ...List.generate(3, (i) {
                        final completed =
                            i < profile.completedChallenges;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed
                                ? AppColors.green
                                : AppColors.cardLight,
                          ),
                        );
                      }),
                      const Spacer(),
                      // Dismiss
                      GestureDetector(
                        onTap: onDismiss,
                        child: Icon(
                          Icons.close,
                          color: AppColors.grey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _reasonColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${profile.trendingReason.emoji} ${profile.trendingReason.label}',
        style: TextStyle(
          color: _reasonColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    final days = profile.daysRemaining;
    final color = days > 3
        ? AppColors.green
        : days >= 2
            ? AppColors.warning
            : const Color(0xFFE0605A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${days}d left',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _reasonColor => switch (profile.trendingReason) {
        TrendingReason.viralMoment => const Color(0xFFD9774A),
        TrendingReason.achievement => AppColors.warning,
        TrendingReason.comeback => AppColors.green,
        TrendingReason.controversy => const Color(0xFFE040FB),
        TrendingReason.inspiration => AppColors.cyan,
      };
}

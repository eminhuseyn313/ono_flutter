// widgets/wakz_challenge_card.dart
// Reusable Wakz challenge card with progress, verification badge, and actions

import 'package:flutter/material.dart';
import '../models/wakz_challenge.dart';
import '../theme/app_theme.dart';

class WakzChallengeCard extends StatelessWidget {
  final WakzChallenge challenge;
  final VoidCallback? onSubmitProof;
  final VoidCallback? onStart;

  const WakzChallengeCard({
    super.key,
    required this.challenge,
    this.onSubmitProof,
    this.onStart,
  });

  Color _laneColor() {
    switch (challenge.lane) {
      case 'body':
        return AppColors.green;
      case 'mind':
        return AppColors.cyan;
      case 'soul':
        return AppColors.purple;
      default:
        return AppColors.purple;
    }
  }

  String _formatTimeRemaining() {
    final remaining = challenge.timeRemaining;
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays > 0) {
      final hours = remaining.inHours % 24;
      return '${remaining.inDays}d ${hours}h left';
    }
    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes % 60;
      return '${remaining.inHours}h ${minutes}m left';
    }
    return '${remaining.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = _laneColor();
    final isActive = challenge.startedAt != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lane color stripe
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: laneColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: emoji + title + type badge
                Row(
                  children: [
                    Text(
                      challenge.category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            challenge.category.label,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verification type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: laneColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            challenge.verificationType.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            challenge.verificationType.label,
                            style: TextStyle(
                              color: laneColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  challenge.description,
                  style: TextStyle(
                    color: AppColors.greyLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Progress bar (only for active challenges)
                if (isActive) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: challenge.progressPercent,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(laneColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${challenge.currentCount}/${challenge.targetCount}',
                        style: TextStyle(
                          color: laneColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Bottom row: deadline + action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Deadline
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: challenge.isExpired
                              ? const Color(0xFFEF4444)
                              : AppColors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRemaining(),
                          style: TextStyle(
                            color: challenge.isExpired
                                ? const Color(0xFFEF4444)
                                : AppColors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Action button
                    if (isActive && !challenge.isCompleted)
                      _ActionButton(
                        label: challenge.isVerified
                            ? 'Verified'
                            : 'Submit Proof',
                        color: laneColor,
                        isDisabled: challenge.isVerified,
                        onTap: challenge.isVerified ? null : onSubmitProof,
                      )
                    else if (!isActive)
                      _ActionButton(
                        label: 'Start',
                        color: laneColor,
                        onTap: onStart,
                      )
                    else if (challenge.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDisabled ? color.withValues(alpha: 0.5) : color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

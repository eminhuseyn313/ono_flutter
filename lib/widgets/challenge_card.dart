import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/community_challenge.dart';

class ChallengeCard extends StatelessWidget {
  final CommunityChallenge challenge;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
    this.onJoin,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final laneColor = Color(challenge.laneColorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: challenge.isJoined
                ? laneColor.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          boxShadow: challenge.isJoined
              ? [
                  BoxShadow(
                    color: laneColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.emoji_events, color: laneColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          _buildBadge(challenge.lane, laneColor),
                          const SizedBox(width: 6),
                          _buildBadge(challenge.type.label, AppColors.grey),
                          const SizedBox(width: 6),
                          _buildStatusBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              challenge.description,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.greyLight,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Progress (if joined and active)
            if (challenge.isJoined &&
                challenge.status == ChallengeStatus.active) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(challenge.myProgress * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      color: laneColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: challenge.myProgress,
                  backgroundColor: AppColors.cardLight.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(laneColor),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Bottom row
            Row(
              children: [
                // Participant count
                Icon(Icons.people, color: AppColors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participantCount}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                // Time remaining
                Icon(Icons.schedule, color: AppColors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  challenge.status == ChallengeStatus.completed
                      ? 'Ended'
                      : challenge.status == ChallengeStatus.upcoming
                          ? 'Starts in ${challenge.startDate.difference(DateTime.now()).inDays}d'
                          : '${challenge.daysRemaining}d left',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                if (challenge.isJoined && challenge.myRank > 0) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.leaderboard, color: laneColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '#${challenge.myRank}',
                    style: GoogleFonts.plusJakartaSans(
                      color: laneColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                // Join/Leave button
                if (challenge.status != ChallengeStatus.completed)
                  GestureDetector(
                    onTap: challenge.isJoined ? onLeave : onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: challenge.isJoined
                            ? AppColors.card
                            : laneColor,
                        borderRadius: BorderRadius.circular(10),
                        border: challenge.isJoined
                            ? Border.all(color: AppColors.divider)
                            : null,
                      ),
                      child: Text(
                        challenge.isJoined ? 'Leave' : 'Join',
                        style: GoogleFonts.plusJakartaSans(
                          color: challenge.isJoined
                              ? AppColors.grey
                              : AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Reward
            if (challenge.reward.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        challenge.reward,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (challenge.status) {
      case ChallengeStatus.active:
        color = AppColors.green;
        break;
      case ChallengeStatus.upcoming:
        color = AppColors.cyan;
        break;
      case ChallengeStatus.completed:
        color = AppColors.grey;
        break;
    }
    return _buildBadge(challenge.status.label, color);
  }
}

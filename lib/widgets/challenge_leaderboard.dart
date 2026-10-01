import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/community_challenge.dart';

class ChallengeLeaderboard extends StatelessWidget {
  final List<ChallengeParticipant> participants;
  final int myRank;
  final Color accentColor;

  const ChallengeLeaderboard({
    super.key,
    required this.participants,
    this.myRank = 0,
    this.accentColor = AppColors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(Icons.leaderboard, color: AppColors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              'No participants yet',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.leaderboard, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (myRank > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You: #$myRank',
                      style: GoogleFonts.plusJakartaSans(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          // Participants
          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return _buildRow(index + 1, participant);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(int rank, ChallengeParticipant participant) {
    final avatarColor = Color(participant.avatarColorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: rank <= 3
                ? Icon(
                    Icons.emoji_events,
                    color: rank == 1
                        ? const Color(0xFFD9B45E)
                        : rank == 2
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFCD7F32),
                    size: 20,
                  )
                : Text(
                    '#$rank',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: avatarColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                participant.avatarInitial,
                style: GoogleFonts.plusJakartaSans(
                  color: avatarColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              participant.name,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          // Score
          Text(
            '${participant.score}',
            style: GoogleFonts.plusJakartaSans(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'pts',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

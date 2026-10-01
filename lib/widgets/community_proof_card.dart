// widgets/community_proof_card.dart
// Community feed item showing anonymous user proof with likes

import 'package:flutter/material.dart';
import '../models/wakz_challenge.dart';
import '../theme/app_theme.dart';

class CommunityProofCard extends StatelessWidget {
  final CommunityProof proof;
  final VoidCallback? onLike;

  const CommunityProofCard({
    super.key,
    required this.proof,
    this.onLike,
  });

  Color _laneColor() {
    switch (proof.lane) {
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

  String _laneLabel() {
    switch (proof.lane) {
      case 'body':
        return 'Body';
      case 'mind':
        return 'Mind';
      case 'soul':
        return 'Soul';
      default:
        return 'Soul';
    }
  }

  String _formatTimeAgo() {
    final diff = DateTime.now().difference(proof.verifiedAt);
    if (diff.inDays > 0) return '\${diff.inDays}d ago';
    if (diff.inHours > 0) return '\${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '\${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = _laneColor();

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row: avatar + name + lane badge + time
            Row(
              children: [
                // Avatar emoji circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: laneColor.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      proof.avatarEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + verified
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            proof.anonymousName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(),
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lane badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _laneLabel(),
                    style: TextStyle(
                      color: laneColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Proof description
            Text(
              proof.proofDescription,
              style: TextStyle(
                color: AppColors.greyLight,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            // Footer: like button + count
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        proof.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: proof.isLiked
                            ? const Color(0xFFEF4444)
                            : AppColors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\${proof.likesCount}',
                        style: TextStyle(
                          color: proof.isLiked
                              ? const Color(0xFFEF4444)
                              : AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

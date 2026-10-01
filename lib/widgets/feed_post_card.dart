import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/social_feed.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  Color _typeColor() {
    switch (post.type) {
      case PostType.win:
        return AppColors.cyan;
      case PostType.milestone:
        return AppColors.purple;
      case PostType.streak:
        return AppColors.green;
      case PostType.reflection:
        return AppColors.purpleSoft;
      case PostType.challenge:
        return AppColors.warning;
    }
  }

  String _typeLabel() {
    switch (post.type) {
      case PostType.win:
        return 'Win';
      case PostType.milestone:
        return 'Milestone';
      case PostType.streak:
        return 'Streak';
      case PostType.reflection:
        return 'Reflection';
      case PostType.challenge:
        return 'Challenge';
    }
  }

  IconData _typeIcon() {
    switch (post.type) {
      case PostType.win:
        return Icons.emoji_events;
      case PostType.milestone:
        return Icons.flag;
      case PostType.streak:
        return Icons.local_fire_department;
      case PostType.reflection:
        return Icons.auto_stories;
      case PostType.challenge:
        return Icons.bolt;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    post.author.name.isNotEmpty
                        ? post.author.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.author.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Lv${post.author.level}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.purpleSoft,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Post type chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(), color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _typeLabel(),
                        style: GoogleFonts.plusJakartaSans(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // Highlight value
            if (post.highlightValue != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  post.highlightValue!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Like & comment bar
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedByMe
                            ? const Color(0xFFEF4444)
                            : AppColors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likeCount}',
                        style: GoogleFonts.plusJakartaSans(
                          color: post.isLikedByMe
                              ? const Color(0xFFEF4444)
                              : AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: onComment,
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
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

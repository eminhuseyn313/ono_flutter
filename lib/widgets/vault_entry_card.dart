import 'package:flutter/material.dart';
import '../models/vault.dart';
import '../theme/app_theme.dart';

class VaultEntryCard extends StatelessWidget {
  final VaultEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onFavoriteTap;

  const VaultEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onBookmarkTap,
    this.onFavoriteTap,
  });

  Color get _laneColor {
    switch (entry.lane) {
      case 'Mind':
        return AppColors.purple;
      case 'Body':
        return AppColors.green;
      case 'Social':
        return AppColors.cyan;
      case 'Skill':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lane indicator stripe
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _laneColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: mood emoji + title + date
                      Row(
                        children: [
                          Text(
                            entry.mood.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.title,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(entry.createdAt),
                            style: TextStyle(
                              color: AppColors.grey.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Content preview
                      Text(
                        entry.content,
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Bottom row: tags + actions
                      Row(
                        children: [
                          // Tags
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: entry.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          AppColors.divider.withValues(alpha: 0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${tag.emoji} ${tag.label}',
                                    style: TextStyle(
                                      color:
                                          AppColors.grey.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Lane badge
                          if (entry.lane != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _laneColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.lane!,
                                style: TextStyle(
                                  color: _laneColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Bookmark
                          GestureDetector(
                            onTap: onBookmarkTap,
                            child: Icon(
                              entry.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: entry.isBookmarked
                                  ? AppColors.cyan
                                  : AppColors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Favorite
                          GestureDetector(
                            onTap: onFavoriteTap,
                            child: Icon(
                              entry.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: entry.isFavorite
                                  ? const Color(0xFFEF4444)
                                  : AppColors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

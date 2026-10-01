import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/content_library.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;

  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final laneColor = Color(item.laneColorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    IconData(item.type.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: laneColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.author,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: item.isBookmarked ? laneColor : AppColors.grey,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.greyLight,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Bottom row: lane badge, type badge, duration, progress
            Row(
              children: [
                _buildBadge(item.lane, laneColor),
                const SizedBox(width: 6),
                _buildBadge(item.type.label, AppColors.grey),
                const SizedBox(width: 6),
                Icon(Icons.schedule, color: AppColors.grey, size: 13),
                const SizedBox(width: 3),
                Text(
                  '${item.durationMinutes}m',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (item.isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.green, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Done',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (item.progress > 0)
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(item.progress * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            color: laneColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            backgroundColor:
                                AppColors.cardLight.withValues(alpha: 0.5),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(laneColor),
                            minHeight: 3,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
}

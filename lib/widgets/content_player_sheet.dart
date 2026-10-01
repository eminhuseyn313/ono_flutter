import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/content_library.dart';

class ContentPlayerSheet extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onBookmark;
  final VoidCallback? onMarkComplete;

  const ContentPlayerSheet({
    super.key,
    required this.item,
    this.onBookmark,
    this.onMarkComplete,
  });

  static void show(BuildContext context, ContentItem item,
      {VoidCallback? onBookmark, VoidCallback? onMarkComplete}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContentPlayerSheet(
        item: item,
        onBookmark: onBookmark,
        onMarkComplete: onMarkComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = Color(item.laneColorValue);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero area
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              laneColor.withValues(alpha: 0.3),
                              AppColors.purple.withValues(alpha: 0.15),
                              AppColors.card,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: laneColor.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: laneColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconData(item.type.iconCodePoint,
                                  fontFamily: 'MaterialIcons'),
                              color: laneColor,
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title & author
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'by ${item.author}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Meta row
                      Row(
                        children: [
                          _buildMetaChip(
                            IconData(item.type.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            item.type.label,
                            laneColor,
                          ),
                          const SizedBox(width: 8),
                          _buildMetaChip(
                            Icons.schedule,
                            '${item.durationMinutes} min',
                            AppColors.grey,
                          ),
                          const SizedBox(width: 8),
                          _buildMetaChip(
                            Icons.circle,
                            item.lane,
                            laneColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Progress bar (if in progress)
                      if (item.progress > 0 && !item.isCompleted) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(item.progress * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                color: laneColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress,
                            backgroundColor:
                                AppColors.cardLight.withValues(alpha: 0.5),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(laneColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      Text(
                        'About',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.greyLight,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags
                      if (item.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardLight
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: item.isCompleted ? null : onMarkComplete,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: item.isCompleted
                                      ? AppColors.green.withValues(alpha: 0.15)
                                      : laneColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    item.isCompleted
                                        ? 'Completed'
                                        : item.progress > 0
                                            ? 'Continue'
                                            : 'Start',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: item.isCompleted
                                          ? AppColors.green
                                          : AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onBookmark,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Icon(
                                item.isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: item.isBookmarked
                                    ? laneColor
                                    : AppColors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

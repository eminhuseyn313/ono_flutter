import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dashboard.dart';
import '../theme/app_theme.dart';

/// A compact horizontal card displaying a daily highlight item.
///
/// Used in a horizontal scrollable list. Features a colored left border,
/// icon, title, and description. Navigates on tap if an action route exists.
class DailyHighlightCard extends StatelessWidget {
  final DailyHighlight highlight;

  const DailyHighlightCard({
    super.key,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: highlight.actionRoute != null
          ? () => context.push(highlight.actionRoute!)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Colored left accent bar
                Container(
                  width: 4,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: highlight.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: highlight.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            highlight.icon,
                            color: highlight.color,
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                highlight.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                highlight.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.grey,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Arrow if tappable
                        if (highlight.actionRoute != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.grey.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

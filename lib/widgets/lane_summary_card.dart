import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dashboard.dart';
import '../theme/app_theme.dart';

/// A mini glassmorphic card for the 2x2 lane overview grid.
///
/// Displays the lane name, score (large), trend arrow, and a colored
/// top border matching the lane's assigned color.
class LaneSummaryCard extends StatelessWidget {
  final LaneSummary laneSummary;

  const LaneSummaryCard({
    super.key,
    required this.laneSummary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Colored top border
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: laneSummary.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lane name + trend arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            laneSummary.lane,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                              height: 1,
                            ),
                          ),
                          _buildTrendIndicator(),
                        ],
                      ),

                      const Spacer(),

                      // Large score number
                      Text(
                        '${laneSummary.score}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          height: 1,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Tasks today
                      Text(
                        '${laneSummary.tasksToday} tasks today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey,
                          height: 1,
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
    );
  }

  /// Builds a trend arrow indicator with appropriate color.
  Widget _buildTrendIndicator() {
    final IconData trendIcon;
    final Color trendColor;

    switch (laneSummary.trend) {
      case 'up':
        trendIcon = Icons.trending_up_rounded;
        trendColor = AppColors.green;
        break;
      case 'down':
        trendIcon = Icons.trending_down_rounded;
        trendColor = const Color(0xFFEF4444);
        break;
      case 'stable':
      default:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = AppColors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        trendIcon,
        color: trendColor,
        size: 16,
      ),
    );
  }
}

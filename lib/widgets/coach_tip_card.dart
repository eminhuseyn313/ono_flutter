import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/ai_coach.dart';

class CoachTipCard extends StatelessWidget {
  final DailyCoachTip tip;
  final VoidCallback? onBookmark;

  const CoachTipCard({
    super.key,
    required this.tip,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final laneColor = Color(tip.laneColorValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            laneColor.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.08),
            AppColors.card.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: laneColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: laneColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: laneColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: laneColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Tip',
                      style: GoogleFonts.plusJakartaSans(
                        color: laneColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      tip.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onBookmark,
                child: Icon(
                  tip.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: tip.isBookmarked ? laneColor : AppColors.grey,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tip.content,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.greyLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: laneColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tip.lane,
              style: GoogleFonts.plusJakartaSans(
                color: laneColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

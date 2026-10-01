import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weekly_review.dart';
import '../theme/app_theme.dart';

class ReviewGoalCard extends StatelessWidget {
  final WeeklyGoal goal;
  final ValueChanged<bool?>? onCompletionChanged;
  final VoidCallback? onDismissed;

  const ReviewGoalCard({
    super.key,
    required this.goal,
    this.onCompletionChanged,
    this.onDismissed,
  });

  Color _priorityColor() {
    switch (goal.priority) {
      case 1:
        return const Color(0xFFE0605A);
      case 2:
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  String _priorityLabel() {
    switch (goal.priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Color _laneColor() {
    switch (goal.lane) {
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

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();
    final laneColor = _laneColor();

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: goal.isCompleted,
                onChanged: onCompletionChanged,
                activeColor: AppColors.purple,
                checkColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(
                  color: AppColors.grey.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: goal.isCompleted
                          ? AppColors.grey
                          : AppColors.white,
                      decoration: goal.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: laneColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          goal.lane,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: laneColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _priorityLabel(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(goal.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE0605A).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete_outline,
            color: Color(0xFFE0605A),
            size: 22,
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

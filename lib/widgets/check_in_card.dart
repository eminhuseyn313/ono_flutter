// widgets/check_in_card.dart

import 'package:flutter/material.dart';
import '../models/accountability.dart';
import '../theme/app_theme.dart';

class CheckInCard extends StatelessWidget {
  final DailyCheckIn checkIn;
  final String? partnerName;

  const CheckInCard({
    super.key,
    required this.checkIn,
    this.partnerName,
  });

  String _moodEmoji(CheckInMood mood) {
    switch (mood) {
      case CheckInMood.fired:
        return '\u{1F525}';
      case CheckInMood.steady:
        return '\u{1F4AA}';
      case CheckInMood.struggling:
        return '\u{1F62E}‍\u{1F4A8}';
      case CheckInMood.ghosting:
        return '\u{1F47B}';
    }
  }

  String _moodLabel(CheckInMood mood) {
    switch (mood) {
      case CheckInMood.fired:
        return 'Fired Up';
      case CheckInMood.steady:
        return 'Steady';
      case CheckInMood.struggling:
        return 'Struggling';
      case CheckInMood.ghosting:
        return 'Ghosting';
    }
  }

  Color _moodColor(CheckInMood mood) {
    switch (mood) {
      case CheckInMood.fired:
        return const Color(0xFFFF6B35);
      case CheckInMood.steady:
        return AppColors.green;
      case CheckInMood.struggling:
        return AppColors.warning;
      case CheckInMood.ghosting:
        return AppColors.grey;
    }
  }

  String _formatTime(DateTime sentAt) {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _moodColor(checkIn.mood);

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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _moodEmoji(checkIn.mood),
                    style: const TextStyle(fontSize: 20),
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
                            _moodLabel(checkIn.mood),
                            style: TextStyle(
                              color: moodColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (partnerName != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: TextStyle(
                                color: AppColors.grey.withValues(alpha: 0.5),
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              partnerName!,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(checkIn.sentAt),
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleDark.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6B35),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Day ${checkIn.streakDay}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              checkIn.message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.green,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${checkIn.actionsCompleted} actions completed',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (checkIn.partnerResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.purple.withValues(alpha: 0.6),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply_rounded,
                          color: AppColors.purple.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Partner Response',
                          style: TextStyle(
                            color: AppColors.purple.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      checkIn.partnerResponse!,
                      style: const TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

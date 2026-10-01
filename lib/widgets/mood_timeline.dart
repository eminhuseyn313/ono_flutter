import 'package:flutter/material.dart';
import '../models/vault.dart';
import '../theme/app_theme.dart';

class MoodTimeline extends StatefulWidget {
  final List<MoodDataPoint> dataPoints;

  const MoodTimeline({
    super.key,
    required this.dataPoints,
  });

  @override
  State<MoodTimeline> createState() => _MoodTimelineState();
}

class _MoodTimelineState extends State<MoodTimeline> {
  int? _selectedIndex;

  Color _moodColor(VaultMood mood) {
    switch (mood) {
      case VaultMood.onFire:
        return const Color(0xFFE0605A);
      case VaultMood.motivated:
        return AppColors.green;
      case VaultMood.neutral:
        return AppColors.cyan;
      case VaultMood.tired:
        return AppColors.warning;
      case VaultMood.struggling:
        return AppColors.purple;
    }
  }

  double _moodY(VaultMood mood) {
    // Returns a vertical position based on mood level (higher = better mood)
    switch (mood) {
      case VaultMood.onFire:
        return 0.0;
      case VaultMood.motivated:
        return 1.0;
      case VaultMood.neutral:
        return 2.0;
      case VaultMood.tired:
        return 3.0;
      case VaultMood.struggling:
        return 4.0;
    }
  }

  String _formatDay(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                color: AppColors.purple,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Mood Timeline',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Last 30 days',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline chart
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.dataPoints.length, (index) {
                  final point = widget.dataPoints[index];
                  final isSelected = _selectedIndex == index;
                  final isToday = index == widget.dataPoints.length - 1;
                  final dotColor = _moodColor(point.mood);
                  final yPos = _moodY(point.mood);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex =
                            _selectedIndex == index ? null : index;
                      });
                    },
                    child: SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          // Tooltip
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: dotColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _formatDay(point.date),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${point.mood.emoji} ${point.entryCount}',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 30),
                          // Spacer based on mood level
                          SizedBox(height: yPos * 10),
                          // Dot
                          Container(
                            width: isSelected || isToday ? 14 : 10,
                            height: isSelected || isToday ? 14 : 10,
                            decoration: BoxDecoration(
                              color: point.entryCount > 0
                                  ? dotColor
                                  : dotColor.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: isToday
                                  ? Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected || isToday
                                  ? [
                                      BoxShadow(
                                        color: dotColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          // Remaining space
                          SizedBox(height: (4 - yPos) * 10),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: VaultMood.values.map((mood) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _moodColor(mood),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mood.label,
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

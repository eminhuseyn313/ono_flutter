import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/habit_streak.dart';

class StreakCalendar extends StatelessWidget {
  final List<DayActivity> days;

  const StreakCalendar({super.key, required this.days});

  Color _intensityColor(StreakIntensity intensity) {
    switch (intensity) {
      case StreakIntensity.none:
        return AppColors.cardLight;
      case StreakIntensity.low:
        return AppColors.green.withValues(alpha: 0.25);
      case StreakIntensity.medium:
        return AppColors.green.withValues(alpha: 0.5);
      case StreakIntensity.high:
        return AppColors.green.withValues(alpha: 0.75);
      case StreakIntensity.extreme:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    // Build a grid: 7 columns (Mon=0 .. Sun=6), fill from oldest to newest
    final firstDay = days.first.date;
    // Adjust start to Monday
    final startOffset = (firstDay.weekday - 1) % 7;

    // Create cell list with optional nulls for leading blanks
    final cells = <DayActivity?>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add(null);
    }
    cells.addAll(days);

    final weeks = (cells.length / 7).ceil();

    // Collect month labels
    final monthLabels = <int, String>{};
    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      final cellIndex = i + startOffset;
      final weekIndex = cellIndex ~/ 7;
      if (!monthLabels.containsKey(weekIndex) || d.date.day <= 7) {
        if (d.date.day <= 7) {
          monthLabels[weekIndex] = _monthName(d.date.month);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day of week headers
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        SizedBox(
          height: weeks * 18.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels column
              SizedBox(
                width: 28,
                child: Stack(
                  children: monthLabels.entries.map((entry) {
                    return Positioned(
                      top: entry.key * 18.0,
                      left: 0,
                      child: Text(
                        entry.value,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 4),
              // Grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                    childAspectRatio: 1,
                  ),
                  itemCount: weeks * 7,
                  itemBuilder: (context, index) {
                    if (index >= cells.length || cells[index] == null) {
                      return const SizedBox.shrink();
                    }
                    final day = cells[index]!;
                    final color = _intensityColor(day.intensity);

                    return Tooltip(
                      message:
                          '${day.date.month}/${day.date.day}: ${day.actionsCompleted} actions',
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          border: day.isStreakDay &&
                                  day.intensity != StreakIntensity.none
                              ? Border.all(
                                  color: AppColors.green.withValues(alpha: 0.4),
                                  width: 0.5,
                                )
                              : null,
                          boxShadow: day.intensity == StreakIntensity.extreme
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.green.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            ...StreakIntensity.values.map((i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _intensityColor(i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
            const SizedBox(width: 4),
            Text(
              'More',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

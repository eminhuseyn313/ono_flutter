import 'dart:math';

import '../models/habit_streak.dart';
import 'habit_streak_gateway.dart';

class MockHabitStreakGateway implements HabitStreakGateway {
  final _random = Random(42);

  List<DayActivity> _generateCalendarDays() {
    final now = DateTime.now();
    final days = <DayActivity>[];
    final allLanes = ['Mind', 'Body', 'Social', 'Skill'];

    for (int i = 89; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final bool isRecent = i < 14;
      final bool isGap = !isRecent && (i == 20 || i == 35 || i == 52 || i == 68);

      if (isGap) {
        days.add(DayActivity(
          date: date,
          actionsCompleted: 0,
          intensity: StreakIntensity.none,
          isStreakDay: false,
          completedLanes: [],
        ));
        continue;
      }

      int actions;
      StreakIntensity intensity;
      if (isRecent) {
        actions = 3 + _random.nextInt(6);
        intensity = actions >= 7
            ? StreakIntensity.extreme
            : actions >= 5
                ? StreakIntensity.high
                : StreakIntensity.medium;
      } else {
        actions = _random.nextInt(7);
        if (actions == 0) {
          intensity = StreakIntensity.none;
        } else if (actions <= 2) {
          intensity = StreakIntensity.low;
        } else if (actions <= 4) {
          intensity = StreakIntensity.medium;
        } else {
          intensity = StreakIntensity.high;
        }
      }

      final lanesActive = <String>[];
      if (actions > 0) {
        final shuffled = List<String>.from(allLanes)..shuffle(_random);
        final count = min(actions, shuffled.length);
        lanesActive.addAll(shuffled.take(count));
      }

      days.add(DayActivity(
        date: date,
        actionsCompleted: actions,
        intensity: intensity,
        isStreakDay: isRecent || (actions > 0 && !isGap),
        completedLanes: lanesActive,
      ));
    }

    return days;
  }

  @override
  Future<StreakData> loadStreakData() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final calendarDays = _generateCalendarDays();

    return StreakData(
      streak: HabitStreak(
        currentStreak: 14,
        longestStreak: 23,
        longestStreakStart: DateTime(2026, 8, 15),
        longestStreakEnd: DateTime(2026, 9, 6),
        totalActiveDays: 67,
        totalActions: 312,
        averageActionsPerDay: 4.7,
        laneStreaks: {
          'Mind': 14,
          'Body': 10,
          'Social': 7,
          'Skill': 12,
        },
      ),
      calendarDays: calendarDays,
      freezeTokens: [
        FreezeToken(
          id: 'ft_1',
          isUsed: true,
          usedDate: DateTime(2026, 8, 28),
          earnedDate: DateTime(2026, 8, 20),
        ),
        FreezeToken(
          id: 'ft_2',
          isUsed: false,
          earnedDate: DateTime(2026, 9, 1),
        ),
        FreezeToken(
          id: 'ft_3',
          isUsed: false,
          earnedDate: DateTime(2026, 9, 10),
        ),
      ],
      milestones: [
        StreakMilestone(
          days: 3,
          title: '3-Day Start',
          description: 'Complete 3 consecutive days',
          iconCodePoint: 0xe518, // Icons.star
          isReached: true,
          reachedDate: DateTime(2026, 7, 5),
        ),
        StreakMilestone(
          days: 7,
          title: 'Week Warrior',
          description: 'A full week of dedication',
          iconCodePoint: 0xf06bb, // Icons.military_tech
          isReached: true,
          reachedDate: DateTime(2026, 7, 9),
        ),
        StreakMilestone(
          days: 14,
          title: 'Two-Week Titan',
          description: '14 days of relentless effort',
          iconCodePoint: 0xe3e7, // Icons.local_fire_department
          isReached: true,
          reachedDate: DateTime.now(),
        ),
        StreakMilestone(
          days: 30,
          title: 'Monthly Legend',
          description: 'A full month of consistency',
          iconCodePoint: 0xe1f6, // Icons.emoji_events
          isReached: false,
        ),
        StreakMilestone(
          days: 100,
          title: '100-Day Centurion',
          description: 'Elite commitment. 100 days strong.',
          iconCodePoint: 0xe8e8, // Icons.shield
          isReached: false,
        ),
        StreakMilestone(
          days: 365,
          title: 'Year of Greatness',
          description: 'A full year of transformation',
          iconCodePoint: 0xe87d, // Icons.diamond
          isReached: false,
        ),
      ],
      freezeTokensAvailable: 2,
      freezeTokensUsed: 1,
    );
  }

  @override
  Future<StreakData> useFreezeToken(String date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Return updated data as if token was used
    final data = await loadStreakData();
    return data.copyWith(freezeTokensAvailable: data.freezeTokensAvailable - 1);
  }

  @override
  Future<List<DayActivity>> loadMonthData(int year, int month) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final allDays = _generateCalendarDays();
    return allDays
        .where((d) => d.date.year == year && d.date.month == month)
        .toList();
  }

  @override
  Future<List<StreakMilestone>> loadStreakMilestones() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final data = await loadStreakData();
    return data.milestones;
  }
}

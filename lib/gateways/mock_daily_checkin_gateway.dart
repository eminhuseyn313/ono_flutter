import '../models/daily_checkin.dart';
import 'daily_checkin_gateway.dart';

class MockDailyCheckinGateway implements DailyCheckinGateway {
  DailyCheckin? _savedCheckin;

  @override
  Future<DailyCheckin?> loadTodayCheckin() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _savedCheckin;
  }

  @override
  Future<CheckinHistory> loadCheckinHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();
    final checkins = <DailyCheckin>[];

    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      final moodIndex = (i % 4) + 2; // cycles good/great/amazing/terrible+2
      checkins.add(DailyCheckin(
        id: 'checkin_$i',
        date: date,
        morningMood: CheckinMood.values[moodIndex.clamp(0, 5)],
        energyLevel: 0.4 + (i % 3) * 0.2,
        gratitudes: [
          'Grateful for progress on my goals',
          'Had a productive workout',
          if (i % 2 == 0) 'Connected with a friend',
        ],
        intention: 'Focus on ${['deep work', 'fitness', 'learning', 'relationships', 'mindfulness', 'creativity', 'rest'][i % 7]} today',
        primaryFocus: FocusArea.values[i % 4],
        morningComplete: true,
        eveningReflection: i > 1
            ? 'Today was ${['productive', 'challenging', 'great', 'reflective', 'balanced', 'inspiring', 'calm'][i % 7]}. I managed to ${['complete my tasks', 'push through difficulty', 'learn something new', 'help someone', 'stay consistent', 'try a new approach', 'rest properly'][i % 7]}.'
            : null,
        dayRating: 2.5 + (i % 3) * 1.0,
        eveningMood: CheckinMood.values[(moodIndex + 1).clamp(0, 5)],
        eveningComplete: i > 1,
        morningCompletedAt: DateTime(date.year, date.month, date.day, 7, 30),
        eveningCompletedAt:
            i > 1 ? DateTime(date.year, date.month, date.day, 21, 0) : null,
      ));
    }

    return CheckinHistory(
      recentCheckins: checkins,
      morningStreak: 7,
      eveningStreak: 5,
      averageMood: 3.8,
      totalCheckins: 42,
    );
  }

  @override
  Future<DailyCheckin> saveMorningCheckin(DailyCheckin checkin) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _savedCheckin = checkin.copyWith(
      morningComplete: true,
      morningCompletedAt: DateTime.now(),
    );
    return _savedCheckin!;
  }

  @override
  Future<DailyCheckin> saveEveningCheckin(DailyCheckin checkin) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _savedCheckin = checkin.copyWith(
      eveningComplete: true,
      eveningCompletedAt: DateTime.now(),
    );
    return _savedCheckin!;
  }
}

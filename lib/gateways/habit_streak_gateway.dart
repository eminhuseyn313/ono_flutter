import '../models/habit_streak.dart';

abstract class HabitStreakGateway {
  Future<StreakData> loadStreakData();
  Future<StreakData> useFreezeToken(String date);
  Future<List<DayActivity>> loadMonthData(int year, int month);
  Future<List<StreakMilestone>> loadStreakMilestones();
}

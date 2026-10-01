import 'package:flutter/foundation.dart';

import '../gateways/habit_streak_gateway.dart';
import '../models/habit_streak.dart';

class HabitStreakProvider extends ChangeNotifier {
  final HabitStreakGateway _gateway;

  HabitStreakProvider({required HabitStreakGateway gateway}) : _gateway = gateway;

  StreakData? _streakData;
  bool _isLoading = false;
  String? _error;

  StreakData? get streakData => _streakData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentStreak => _streakData?.streak.currentStreak ?? 0;
  int get longestStreak => _streakData?.streak.longestStreak ?? 0;
  int get freezeTokensAvailable => _streakData?.freezeTokensAvailable ?? 0;
  List<StreakMilestone> get milestones => _streakData?.milestones ?? [];

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _streakData = await _gateway.loadStreakData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> useFreezeToken(String date) async {
    if (freezeTokensAvailable <= 0) return;

    try {
      _streakData = await _gateway.useFreezeToken(date);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMonth(int year, int month) async {
    try {
      await _gateway.loadMonthData(year, month);
      // Calendar data is already in streakData.calendarDays for display
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

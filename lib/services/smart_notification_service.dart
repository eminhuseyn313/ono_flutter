import 'dart:math';

import '../models/notification_model.dart';

/// Smart notification timing engine that learns from user behavior
/// to deliver notifications at optimal times.
class SmartNotificationService {
  SmartNotificationService();

  /// Stores timestamps of app opens for the last 14 days.
  final List<DateTime> _appOpenHistory = [];

  static const int _maxHistoryDays = 14;

  /// Records an app-open event for timing analysis.
  void recordAppOpen(DateTime time) {
    _appOpenHistory.add(time);
    _pruneOldEntries();
  }

  /// Removes entries older than [_maxHistoryDays].
  void _pruneOldEntries() {
    final cutoff = DateTime.now().subtract(const Duration(days: _maxHistoryDays));
    _appOpenHistory.removeWhere((t) => t.isBefore(cutoff));
  }

  /// Returns the number of recorded app opens.
  int get historyCount => _appOpenHistory.length;

  /// Calculates the optimal time to send today's notification based on
  /// the user's historical app-open patterns.
  ///
  /// Returns `null` if there is insufficient history (fewer than 3 opens).
  DateTime? getOptimalSendTime() {
    if (_appOpenHistory.length < 3) return null;

    // Bucket opens by hour-of-day and find the peak hour.
    final hourCounts = List<int>.filled(24, 0);
    for (final open in _appOpenHistory) {
      hourCounts[open.hour]++;
    }

    int peakHour = 0;
    int peakCount = 0;
    for (int h = 0; h < 24; h++) {
      if (hourCounts[h] > peakCount) {
        peakCount = hourCounts[h];
        peakHour = h;
      }
    }

    // Calculate the average minute within the peak hour.
    final minutesInPeakHour = _appOpenHistory
        .where((t) => t.hour == peakHour)
        .map((t) => t.minute)
        .toList();

    final avgMinute = minutesInPeakHour.isEmpty
        ? 0
        : (minutesInPeakHour.reduce((a, b) => a + b) / minutesInPeakHour.length).round();

    // Send 15 minutes before the user's typical open time so the
    // notification is waiting when they arrive.
    final now = DateTime.now();
    var optimal = DateTime(now.year, now.month, now.day, peakHour, avgMinute);
    optimal = optimal.subtract(const Duration(minutes: 15));

    // If the optimal time already passed today, return null (skip today).
    if (optimal.isBefore(now)) return null;

    return optimal;
  }

  /// Determines whether right now is a good time to send a notification
  /// based on quiet hours and smart-timing preferences.
  bool shouldSendNow(NotificationPreferences prefs) {
    if (!prefs.enabled) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Respect quiet hours.
    final quietStart = _timeOfDayToMinutes(prefs.quietHoursStart);
    final quietEnd = _timeOfDayToMinutes(prefs.quietHoursEnd);

    if (quietStart <= quietEnd) {
      // Simple range, e.g. 22:00 – 07:00 does NOT apply here.
      if (currentMinutes >= quietStart && currentMinutes < quietEnd) return false;
    } else {
      // Overnight range, e.g. 22:00 – 07:00.
      if (currentMinutes >= quietStart || currentMinutes < quietEnd) return false;
    }

    // When smart timing is enabled, compare against the optimal window.
    if (prefs.smartTiming) {
      final optimal = getOptimalSendTime();
      if (optimal != null) {
        final diffMinutes = (currentMinutes - (optimal.hour * 60 + optimal.minute)).abs();
        // Allow a 30-minute window around the optimal time.
        if (diffMinutes > 30) return false;
      }
    }

    return true;
  }

  /// Selects the most appropriate notification type given the user's
  /// current context.
  ///
  /// Priority order:
  /// 1. Streak at risk → streakRisk
  /// 2. Close to a milestone → milestone
  /// 3. Social proof (when many users are active) → socialProof
  /// 4. Role-model nudge (default fallback) → roleModel
  NotificationType selectNotificationType({
    required int currentStreak,
    required bool completedToday,
    required int daysUntilMilestone,
    required int activeUsersToday,
  }) {
    // A streak is at risk if the user hasn't completed today's action
    // and has an active streak.
    if (!completedToday && currentStreak > 0) {
      return NotificationType.streakRisk;
    }

    // Milestone approaching within 2 days.
    if (daysUntilMilestone <= 2 && daysUntilMilestone > 0) {
      return NotificationType.milestone;
    }

    // Social proof works best when lots of users are active.
    if (activeUsersToday >= 500) {
      return NotificationType.socialProof;
    }

    // Default: a motivational role-model nudge.
    return NotificationType.roleModel;
  }

  /// Converts a "HH:mm" string to minutes since midnight.
  int _timeOfDayToMinutes(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}

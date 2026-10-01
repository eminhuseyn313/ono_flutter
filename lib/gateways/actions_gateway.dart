/// Abstraction over daily-actions persistence (Supabase in production).
abstract class ActionsGateway {
  /// Load today's actions for the user. Returns empty list if none exist.
  Future<List<DailyAction>> loadTodayActions(String userId);

  /// Mark an action as complete or incomplete.
  Future<void> toggleAction(String userId, String actionId, bool completed);

  /// Load the user's current streak (consecutive days with all actions done).
  Future<int> loadStreak(String userId);

  /// Load action history for a date range (for progress charts).
  Future<List<DayRecord>> loadHistory(
    String userId, {
    required DateTime from,
    required DateTime to,
  });
}

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

/// A single action the user should perform today.
class DailyAction {
  final String id;
  final String title;
  final String? subtitle;
  final String lane; // e.g. 'mind', 'body', 'social', 'skill'
  final bool completed;
  final int orderIndex;

  const DailyAction({
    required this.id,
    required this.title,
    this.subtitle,
    required this.lane,
    this.completed = false,
    this.orderIndex = 0,
  });

  DailyAction copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? lane,
    bool? completed,
    int? orderIndex,
  }) {
    return DailyAction(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      lane: lane ?? this.lane,
      completed: completed ?? this.completed,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

/// Summary of one calendar day: how many actions were completed out of total.
class DayRecord {
  final DateTime date;
  final int completedCount;
  final int totalCount;

  const DayRecord({
    required this.date,
    required this.completedCount,
    required this.totalCount,
  });

  double get completionRate =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  bool get allDone => totalCount > 0 && completedCount == totalCount;
}

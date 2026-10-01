/// Data models for Monk Mode — the phone-takeover meditation feature.
library monk_session;

/// A single completed (or interrupted) Monk Mode session.
class MonkSession {
  final String id;
  final String userId;
  final int durationMinutes;
  final DateTime completedAt;
  final int breathCycles;
  final bool wasInterrupted;

  const MonkSession({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.completedAt,
    required this.breathCycles,
    this.wasInterrupted = false,
  });

  MonkSession copyWith({
    String? id,
    String? userId,
    int? durationMinutes,
    DateTime? completedAt,
    int? breathCycles,
    bool? wasInterrupted,
  }) {
    return MonkSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completedAt: completedAt ?? this.completedAt,
      breathCycles: breathCycles ?? this.breathCycles,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
    );
  }

  factory MonkSession.fromJson(Map<String, dynamic> json) {
    return MonkSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      durationMinutes: json['durationMinutes'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      breathCycles: json['breathCycles'] as int,
      wasInterrupted: json['wasInterrupted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'durationMinutes': durationMinutes,
      'completedAt': completedAt.toIso8601String(),
      'breathCycles': breathCycles,
      'wasInterrupted': wasInterrupted,
    };
  }
}

/// Aggregate Monk Mode stats for a user, derived from their session history.
class MonkModeStats {
  final int totalSessions;
  final int totalMinutes;
  final int longestSession;
  final int currentStreak;

  const MonkModeStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.longestSession = 0,
    this.currentStreak = 0,
  });

  static const empty = MonkModeStats();

  MonkModeStats copyWith({
    int? totalSessions,
    int? totalMinutes,
    int? longestSession,
    int? currentStreak,
  }) {
    return MonkModeStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      longestSession: longestSession ?? this.longestSession,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  factory MonkModeStats.fromJson(Map<String, dynamic> json) {
    return MonkModeStats(
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      longestSession: json['longestSession'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'longestSession': longestSession,
      'currentStreak': currentStreak,
    };
  }

  /// Derive stats from a full session history. Used by mock/local
  /// gateways so the numbers stay consistent with saved sessions.
  factory MonkModeStats.fromHistory(List<MonkSession> sessions) {
    if (sessions.isEmpty) return MonkModeStats.empty;

    final completed = sessions.where((s) => !s.wasInterrupted).toList();
    final totalMinutes =
        completed.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final longest = completed.fold<int>(
        0, (max, s) => s.durationMinutes > max ? s.durationMinutes : max);

    // Streak: consecutive calendar days (walking backward from today) with
    // at least one completed session.
    final byDay = <DateTime, bool>{};
    for (final s in completed) {
      final day =
          DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
      byDay[day] = true;
    }
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (byDay[cursor] == true) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return MonkModeStats(
      totalSessions: completed.length,
      totalMinutes: totalMinutes,
      longestSession: longest,
      currentStreak: streak,
    );
  }
}

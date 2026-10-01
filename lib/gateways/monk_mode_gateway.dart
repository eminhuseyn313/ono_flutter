import '../models/monk_session.dart';

/// Abstract data access boundary for Monk Mode. Real implementations
/// (e.g. a Supabase-backed gateway) should conform to this contract;
/// see [MockMonkModeGateway] for the in-memory dev implementation.
abstract class MonkModeGateway {
  /// Loads the aggregate Monk Mode stats for [userId].
  Future<MonkModeStats> loadStats(String userId);

  /// Persists a completed (or interrupted) session for [userId].
  Future<void> saveSession(String userId, MonkSession session);

  /// Loads the full session history for [userId], newest first.
  Future<List<MonkSession>> loadHistory(String userId);
}

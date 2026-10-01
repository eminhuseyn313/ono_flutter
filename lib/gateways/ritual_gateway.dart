import '../models/ritual.dart';

/// Contract for ritual persistence.
abstract class RitualGateway {
  /// Load all rituals for a user.
  Future<List<Ritual>> loadRituals(String userId);

  /// Load a single ritual by id.
  Future<Ritual?> loadRitual(String ritualId);

  /// Create or update a ritual.
  Future<void> saveRitual(Ritual ritual);

  /// Delete a ritual by id.
  Future<void> deleteRitual(String ritualId);

  /// Start a new session and return it.
  Future<RitualSession> startSession(String ritualId);

  /// Persist a completed or in-progress session.
  Future<void> completeSession(RitualSession session);

  /// Load session history for a given ritual (most recent first).
  Future<List<RitualSession>> loadSessionHistory(
    String ritualId, {
    int limit = 30,
  });
}

import '../models/ghost_mode.dart';

/// Contract for loading and saving ghost-mode data.
///
/// Implementations may hit a real backend or return seeded mock data.
abstract class GhostModeGateway {
  /// Load the snapshot for the current (in-progress) week.
  Future<GhostSnapshot> loadCurrentWeekSnapshot();

  /// Load the snapshot for the previous (completed) week — the "ghost."
  Future<GhostSnapshot> loadPreviousWeekSnapshot();

  /// Load a history of snapshots going back [weeks] weeks.
  Future<List<GhostSnapshot>> loadGhostHistory(int weeks);

  /// Persist a snapshot (e.g. at end of week or on manual save).
  Future<void> saveSnapshot(GhostSnapshot snapshot);

  /// Load the active weekly challenge, if any.
  Future<WeeklyGhostChallenge> getWeeklyChallenge();

  /// Mark the weekly challenge as completed and persist the result.
  Future<WeeklyGhostChallenge> completeWeeklyChallenge();
}

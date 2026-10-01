import '../models/council.dart';

abstract class CouncilGateway {
  /// Ask the council a question. [selectedMemberIds] must contain 2-4 member IDs.
  Future<CouncilSession> askCouncil(
    String question,
    List<String> selectedMemberIds,
  );

  /// Load all past council sessions, newest first.
  Future<List<CouncilSession>> loadHistory();

  /// Load a single session by its ID.
  Future<CouncilSession?> loadSession(String id);

  /// Toggle the favorite status of a session. Returns the updated session.
  Future<CouncilSession> toggleFavorite(String sessionId);

  /// Get the current daily quota.
  Future<CouncilQuota> getQuota();
}

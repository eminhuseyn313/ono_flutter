import '../models/legacy_score.dart';

/// Abstract gateway for Legacy Score data operations.
///
/// Legacy Score is a lifetime metric: implementations must guarantee the
/// stored score never decreases, regardless of how points are added.
abstract class LegacyScoreGateway {
  /// Load the current lifetime score for a user.
  Future<LegacyScore> loadScore(String userId);

  /// Record an action and add its points to the user's lifetime score.
  ///
  /// [points] is the resolved point value for [actionType] (see
  /// [ActionWeight.resolve]). Returns the updated [LegacyScore].
  Future<LegacyScore> addPoints(String userId, String actionType, int points);

  /// Load the milestone catalog for a user, reflecting current unlock state.
  Future<List<LegacyMilestone>> loadMilestones(String userId);

  /// Load the chronological history of point-earning events for a user,
  /// most recent first.
  Future<List<LegacyScoreEvent>> loadScoreHistory(String userId);
}

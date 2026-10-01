import '../models/becoming_arc.dart';

/// Abstract gateway defining all data operations for the Becoming Arc feature.
///
/// Implementations may back this with a remote API, local database, or
/// in-memory store (see [MockBecomingArcGateway]).
abstract class BecomingArcGateway {
  /// Returns every available [BecomingArc] the user can start.
  Future<List<BecomingArc>> loadArcs();

  /// Loads a single user's progress for [arcId], or `null` if the user
  /// has not started that arc.
  Future<UserArcProgress?> loadProgress(String userId, String arcId);

  /// Loads all active and completed arc progress records for [userId].
  Future<List<UserArcProgress>> loadAllProgress(String userId);

  /// Persists or updates a [UserArcProgress] record.
  Future<void> saveProgress(String userId, UserArcProgress progress);

  /// Marks a single step as completed within the user's arc progress.
  Future<void> completeStep(String userId, String arcId, String stepId);

  /// Saves a [SelfAssessment] to the user's arc progress.
  Future<void> saveAssessment(
    String userId,
    String arcId,
    SelfAssessment assessment,
  );

  /// Starts a new arc for the user, creating initial [UserArcProgress].
  ///
  /// Throws a [StateError] if the user already has active progress for
  /// this arc.
  Future<UserArcProgress> startArc(String userId, String arcId);
}

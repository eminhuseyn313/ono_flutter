import '../models/community_challenge.dart';

abstract class CommunityChallengeGateway {
  Future<ChallengeData> loadChallenges();
  Future<void> joinChallenge(String challengeId);
  Future<void> leaveChallenge(String challengeId);
  Future<void> updateProgress(String challengeId, double progress);
  Future<List<ChallengeParticipant>> loadLeaderboard(String challengeId);
}

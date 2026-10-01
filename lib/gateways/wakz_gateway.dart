// gateways/wakz_gateway.dart
// Abstract gateway for Wakz Social Proof Challenges

import '../models/wakz_challenge.dart';

abstract class WakzGateway {
  Future<List<WakzChallenge>> loadActiveChallenges();
  Future<List<WakzChallenge>> loadAvailableChallenges();
  Future<WakzChallenge> startChallenge(String challengeId);
  Future<WakzChallenge> submitProof(String challengeId, String proofPath);
  Future<List<CommunityProof>> loadCommunityFeed();
  Future<CommunityProof> likeCommunityProof(String proofId);
  Future<ChallengeBattle> startBattle(
      String challengeId, String opponentType);
  Future<List<ChallengeBattle>> loadActiveBattles();
  Future<WakzStats> loadStats();
  Future<List<WakzBadge>> loadBadges();
  Future<WakzChallenge> completeChallenge(String challengeId);
}

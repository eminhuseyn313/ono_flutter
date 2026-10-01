import '../models/gamification.dart';

abstract class GamificationGateway {
  Future<GamificationProfile> loadProfile();
  Future<List<XPTransaction>> loadTransactions();
  Future<List<LeaderboardEntry>> loadLeaderboard();
  Future<List<RewardItem>> loadRewards();
  Future<List<WeeklyChallenge>> loadWeeklyChallenges();
  Future<XPBreakdown> loadXPBreakdown();
  Future<RewardItem> purchaseReward(String rewardId);
  Future<int> claimDailyBonus();
}

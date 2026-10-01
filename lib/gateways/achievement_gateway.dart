import '../models/achievement.dart';

abstract class AchievementGateway {
  Future<List<Achievement>> loadAchievements();
  Future<AchievementStats> loadAchievementStats();
  Future<Achievement> claimAchievement(String id);
  Future<List<Achievement>> checkForNewAchievements();
}

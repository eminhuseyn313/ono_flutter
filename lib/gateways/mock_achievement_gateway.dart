import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'achievement_gateway.dart';

class MockAchievementGateway implements AchievementGateway {
  List<Achievement> _achievements = [];

  List<Achievement> _buildAchievements() {
    final now = DateTime.now();
    return [
      // Streaks
      Achievement(
        id: 'streak_3day',
        title: '3-Day Warrior',
        description: 'Maintain a 3-day action streak',
        iconCodePoint: Icons.local_fire_department.codePoint,
        colorValue: 0xFFE0605A,
        category: AchievementCategory.streak,
        rarity: AchievementRarity.common,
        requiredProgress: 3,
        currentProgress: 3,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 14)),
        xpReward: 50,
      ),
      Achievement(
        id: 'streak_7day',
        title: 'Week Conqueror',
        description: 'Maintain a 7-day action streak',
        iconCodePoint: Icons.whatshot.codePoint,
        colorValue: 0xFFE2B354,
        category: AchievementCategory.streak,
        rarity: AchievementRarity.rare,
        requiredProgress: 7,
        currentProgress: 7,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 7)),
        xpReward: 150,
      ),
      Achievement(
        id: 'streak_30day',
        title: 'Monthly Legend',
        description: 'Maintain a 30-day action streak',
        iconCodePoint: Icons.military_tech.codePoint,
        colorValue: 0xFFC8894A,
        category: AchievementCategory.streak,
        rarity: AchievementRarity.legendary,
        requiredProgress: 30,
        currentProgress: 18,
        isUnlocked: false,
        xpReward: 500,
      ),
      // Actions
      Achievement(
        id: 'actions_first',
        title: 'First Step',
        description: 'Complete your first action',
        iconCodePoint: Icons.flag.codePoint,
        colorValue: 0xFF7DB495,
        category: AchievementCategory.actions,
        rarity: AchievementRarity.common,
        requiredProgress: 1,
        currentProgress: 1,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 30)),
        xpReward: 25,
      ),
      Achievement(
        id: 'actions_100',
        title: 'Centurion',
        description: 'Complete 100 actions',
        iconCodePoint: Icons.shield.codePoint,
        colorValue: 0xFF7C9CC4,
        category: AchievementCategory.actions,
        rarity: AchievementRarity.epic,
        requiredProgress: 100,
        currentProgress: 100,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 3)),
        xpReward: 300,
      ),
      Achievement(
        id: 'actions_1000',
        title: 'Thousand Strong',
        description: 'Complete 1000 actions',
        iconCodePoint: Icons.emoji_events.codePoint,
        colorValue: 0xFFE2B354,
        category: AchievementCategory.actions,
        rarity: AchievementRarity.legendary,
        requiredProgress: 1000,
        currentProgress: 247,
        isUnlocked: false,
        xpReward: 1000,
      ),
      // Lanes
      Achievement(
        id: 'lane_mind',
        title: 'Mind Explorer',
        description: 'Complete 10 actions in the Mind lane',
        iconCodePoint: Icons.psychology.codePoint,
        colorValue: 0xFFC8894A,
        category: AchievementCategory.lanes,
        rarity: AchievementRarity.rare,
        requiredProgress: 10,
        currentProgress: 10,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 10)),
        xpReward: 100,
      ),
      Achievement(
        id: 'lane_body',
        title: 'Body Builder',
        description: 'Complete 10 actions in the Body lane',
        iconCodePoint: Icons.fitness_center.codePoint,
        colorValue: 0xFF7DB495,
        category: AchievementCategory.lanes,
        rarity: AchievementRarity.rare,
        requiredProgress: 10,
        currentProgress: 10,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 8)),
        xpReward: 100,
      ),
      Achievement(
        id: 'lane_social',
        title: 'Social Connector',
        description: 'Complete 10 actions in the Social lane',
        iconCodePoint: Icons.people.codePoint,
        colorValue: 0xFF7C9CC4,
        category: AchievementCategory.lanes,
        rarity: AchievementRarity.rare,
        requiredProgress: 10,
        currentProgress: 6,
        isUnlocked: false,
        xpReward: 100,
      ),
      Achievement(
        id: 'lane_skill',
        title: 'Skill Sharpener',
        description: 'Complete 10 actions in the Skill lane',
        iconCodePoint: Icons.build.codePoint,
        colorValue: 0xFFE2B354,
        category: AchievementCategory.lanes,
        rarity: AchievementRarity.rare,
        requiredProgress: 10,
        currentProgress: 3,
        isUnlocked: false,
        xpReward: 100,
      ),
      // Social
      Achievement(
        id: 'social_brotherhood',
        title: 'Brotherhood Initiate',
        description: 'Join a brotherhood group',
        iconCodePoint: Icons.group_add.codePoint,
        colorValue: 0xFF7C9CC4,
        category: AchievementCategory.social,
        rarity: AchievementRarity.common,
        requiredProgress: 1,
        currentProgress: 1,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 20)),
        xpReward: 75,
      ),
      Achievement(
        id: 'social_accountability',
        title: 'Accountability Ace',
        description: 'Complete 5 accountability partner check-ins',
        iconCodePoint: Icons.handshake.codePoint,
        colorValue: 0xFFE8C9A3,
        category: AchievementCategory.social,
        rarity: AchievementRarity.epic,
        requiredProgress: 5,
        currentProgress: 2,
        isUnlocked: false,
        xpReward: 200,
      ),
      // Milestones
      Achievement(
        id: 'milestone_level5',
        title: 'Level 5 Warrior',
        description: 'Reach level 5',
        iconCodePoint: Icons.star.codePoint,
        colorValue: 0xFFE2B354,
        category: AchievementCategory.milestones,
        rarity: AchievementRarity.epic,
        requiredProgress: 5,
        currentProgress: 5,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 5)),
        xpReward: 250,
      ),
      Achievement(
        id: 'milestone_xp1000',
        title: 'XP Hunter',
        description: 'Earn 1000 XP total',
        iconCodePoint: Icons.diamond.codePoint,
        colorValue: 0xFFC8894A,
        category: AchievementCategory.milestones,
        rarity: AchievementRarity.rare,
        requiredProgress: 1000,
        currentProgress: 1000,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 4)),
        xpReward: 200,
      ),
      // Special
      Achievement(
        id: 'special_nightowl',
        title: 'Night Owl',
        description: 'Complete an action after midnight',
        iconCodePoint: Icons.nightlight_round.codePoint,
        colorValue: 0xFF4A2F18,
        category: AchievementCategory.special,
        rarity: AchievementRarity.epic,
        requiredProgress: 1,
        currentProgress: 0,
        isUnlocked: false,
        xpReward: 150,
      ),
      Achievement(
        id: 'special_earlybird',
        title: 'Early Bird',
        description: 'Complete an action before 6 AM',
        iconCodePoint: Icons.wb_sunny.codePoint,
        colorValue: 0xFFE2B354,
        category: AchievementCategory.special,
        rarity: AchievementRarity.epic,
        requiredProgress: 1,
        currentProgress: 1,
        isUnlocked: true,
        unlockedAt: now.subtract(const Duration(days: 2)),
        xpReward: 150,
      ),
    ];
  }

  @override
  Future<List<Achievement>> loadAchievements() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _achievements = _buildAchievements();
    return List.unmodifiable(_achievements);
  }

  @override
  Future<AchievementStats> loadAchievementStats() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (_achievements.isEmpty) {
      _achievements = _buildAchievements();
    }
    final unlocked = _achievements.where((a) => a.isUnlocked).toList();
    final categoryProgress = <AchievementCategory, int>{};
    for (final cat in AchievementCategory.values) {
      categoryProgress[cat] =
          _achievements.where((a) => a.category == cat && a.isUnlocked).length;
    }

    final recentlyUnlocked = List<Achievement>.from(unlocked)
      ..sort((a, b) => (b.unlockedAt ?? DateTime(2000))
          .compareTo(a.unlockedAt ?? DateTime(2000)));

    return AchievementStats(
      totalAchievements: _achievements.length,
      unlockedCount: unlocked.length,
      totalXpEarned: 1850,
      categoryProgress: categoryProgress,
      highestRarity: AchievementRarity.epic,
      recentlyUnlocked: recentlyUnlocked.take(5).toList(),
    );
  }

  @override
  Future<Achievement> claimAchievement(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) {
      throw Exception('Achievement not found: $id');
    }
    final claimed = _achievements[index].copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      currentProgress: _achievements[index].requiredProgress,
    );
    _achievements[index] = claimed;
    return claimed;
  }

  @override
  Future<List<Achievement>> checkForNewAchievements() async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Simulate no new achievements found on check
    return [];
  }
}

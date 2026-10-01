import '../models/gamification.dart';
import '../models/xp_system.dart';
import 'gamification_gateway.dart';

class MockGamificationGateway implements GamificationGateway {
  @override
  Future<GamificationProfile> loadProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    const totalXp = 1200;
    return GamificationProfile(
      totalXp: totalXp,
      currentLevel: XpSystem.levelFor(totalXp),
      weeklyXp: 185,
      monthlyXp: 720,
      xpToNext: XpSystem.xpToNextLevel(totalXp),
      progressToNext: XpSystem.progressToNext(totalXp),
      totalRewardsUnlocked: 4,
      rank: 4,
    );
  }

  @override
  Future<List<XPTransaction>> loadTransactions() async {
    await Future.delayed(const Duration(milliseconds: 180));
    final now = DateTime.now();
    return [
      XPTransaction(
        id: 'tx_01',
        source: XPSource.action,
        amount: 15,
        description: 'Completed "Cold shower for 2 minutes"',
        earnedAt: now.subtract(const Duration(minutes: 30)),
        lane: 'Body',
      ),
      XPTransaction(
        id: 'tx_02',
        source: XPSource.journal,
        amount: 20,
        description: 'Wrote evening reflection journal',
        earnedAt: now.subtract(const Duration(hours: 2)),
        lane: 'Mind',
      ),
      XPTransaction(
        id: 'tx_03',
        source: XPSource.ritual,
        amount: 25,
        description: 'Morning ritual completed',
        earnedAt: now.subtract(const Duration(hours: 8)),
      ),
      XPTransaction(
        id: 'tx_04',
        source: XPSource.streak,
        amount: 50,
        description: '3-day streak bonus unlocked',
        earnedAt: now.subtract(const Duration(hours: 10)),
      ),
      XPTransaction(
        id: 'tx_05',
        source: XPSource.challenge,
        amount: 30,
        description: 'Weekly challenge: Read 30 minutes daily',
        earnedAt: now.subtract(const Duration(hours: 14)),
        lane: 'Mind',
      ),
      XPTransaction(
        id: 'tx_06',
        source: XPSource.action,
        amount: 15,
        description: 'Completed "Practice public speaking"',
        earnedAt: now.subtract(const Duration(days: 1)),
        lane: 'Social',
      ),
      XPTransaction(
        id: 'tx_07',
        source: XPSource.battle,
        amount: 40,
        description: 'Won battle: Push-up challenge vs @MarcusK',
        earnedAt: now.subtract(const Duration(days: 1, hours: 3)),
        lane: 'Body',
      ),
      XPTransaction(
        id: 'tx_08',
        source: XPSource.roleModel,
        amount: 10,
        description: 'Read David Goggins profile',
        earnedAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      XPTransaction(
        id: 'tx_09',
        source: XPSource.forge,
        amount: 35,
        description: 'Forge session: Guitar practice 45 min',
        earnedAt: now.subtract(const Duration(days: 1, hours: 8)),
        lane: 'Skill',
      ),
      XPTransaction(
        id: 'tx_10',
        source: XPSource.action,
        amount: 15,
        description: 'Completed "Meditate for 10 minutes"',
        earnedAt: now.subtract(const Duration(days: 2)),
        lane: 'Mind',
      ),
      XPTransaction(
        id: 'tx_11',
        source: XPSource.review,
        amount: 40,
        description: 'Weekly review submitted',
        earnedAt: now.subtract(const Duration(days: 2, hours: 2)),
      ),
      XPTransaction(
        id: 'tx_12',
        source: XPSource.wakz,
        amount: 20,
        description: 'Completed morning Wakz walk',
        earnedAt: now.subtract(const Duration(days: 2, hours: 6)),
        lane: 'Body',
      ),
      XPTransaction(
        id: 'tx_13',
        source: XPSource.journal,
        amount: 20,
        description: 'Gratitude journal entry',
        earnedAt: now.subtract(const Duration(days: 3)),
        lane: 'Mind',
      ),
      XPTransaction(
        id: 'tx_14',
        source: XPSource.action,
        amount: 15,
        description: 'Completed "Network with 1 new person"',
        earnedAt: now.subtract(const Duration(days: 3, hours: 4)),
        lane: 'Social',
      ),
      XPTransaction(
        id: 'tx_15',
        source: XPSource.ritual,
        amount: 25,
        description: 'Morning ritual completed',
        earnedAt: now.subtract(const Duration(days: 3, hours: 8)),
      ),
      XPTransaction(
        id: 'tx_16',
        source: XPSource.streak,
        amount: 120,
        description: '7-day streak bonus unlocked',
        earnedAt: now.subtract(const Duration(days: 4)),
      ),
      XPTransaction(
        id: 'tx_17',
        source: XPSource.challenge,
        amount: 30,
        description: 'Weekly challenge: No social media before noon',
        earnedAt: now.subtract(const Duration(days: 4, hours: 5)),
        lane: 'Mind',
      ),
      XPTransaction(
        id: 'tx_18',
        source: XPSource.forge,
        amount: 35,
        description: 'Forge session: Coding practice 1 hour',
        earnedAt: now.subtract(const Duration(days: 5)),
        lane: 'Skill',
      ),
      XPTransaction(
        id: 'tx_19',
        source: XPSource.action,
        amount: 15,
        description: 'Completed "Run 5K"',
        earnedAt: now.subtract(const Duration(days: 5, hours: 3)),
        lane: 'Body',
      ),
      XPTransaction(
        id: 'tx_20',
        source: XPSource.roleModel,
        amount: 10,
        description: 'Read Jocko Willink profile',
        earnedAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  @override
  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      const LeaderboardEntry(
        rank: 1,
        userId: 'u_01',
        username: 'AlphaGrinder',
        avatar: '🦁',
        totalXp: 3200,
        level: 7,
        weeklyXp: 420,
        streak: 21,
      ),
      const LeaderboardEntry(
        rank: 2,
        userId: 'u_02',
        username: 'IronMindset',
        avatar: '💪',
        totalXp: 2800,
        level: 7,
        weeklyXp: 380,
        streak: 14,
      ),
      const LeaderboardEntry(
        rank: 3,
        userId: 'u_03',
        username: 'ZenWarrior',
        avatar: '🧘',
        totalXp: 2100,
        level: 6,
        weeklyXp: 295,
        streak: 30,
      ),
      const LeaderboardEntry(
        rank: 4,
        userId: 'u_self',
        username: 'You',
        avatar: '😎',
        totalXp: 1200,
        level: 5,
        weeklyXp: 185,
        streak: 7,
        isCurrentUser: true,
      ),
      const LeaderboardEntry(
        rank: 5,
        userId: 'u_05',
        username: 'DisciplineKing',
        avatar: '👑',
        totalXp: 1100,
        level: 5,
        weeklyXp: 170,
        streak: 5,
      ),
      const LeaderboardEntry(
        rank: 6,
        userId: 'u_06',
        username: 'MindBuilder',
        avatar: '🧠',
        totalXp: 950,
        level: 4,
        weeklyXp: 155,
        streak: 10,
      ),
      const LeaderboardEntry(
        rank: 7,
        userId: 'u_07',
        username: 'SteelResolve',
        avatar: '🛡️',
        totalXp: 800,
        level: 4,
        weeklyXp: 140,
        streak: 4,
      ),
      const LeaderboardEntry(
        rank: 8,
        userId: 'u_08',
        username: 'RiseDaily',
        avatar: '🌞',
        totalXp: 620,
        level: 4,
        weeklyXp: 110,
        streak: 8,
      ),
      const LeaderboardEntry(
        rank: 9,
        userId: 'u_09',
        username: 'GrowthHacker',
        avatar: '🚀',
        totalXp: 450,
        level: 3,
        weeklyXp: 85,
        streak: 3,
      ),
      const LeaderboardEntry(
        rank: 10,
        userId: 'u_10',
        username: 'NewBlood',
        avatar: '🔥',
        totalXp: 180,
        level: 2,
        weeklyXp: 60,
        streak: 2,
      ),
    ];
  }

  @override
  Future<List<RewardItem>> loadRewards() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return [
      // Unlocked rewards
      RewardItem(
        id: 'rw_01',
        name: 'Midnight Steel',
        description: 'Dark metallic theme with blue accents',
        emoji: '🌑',
        category: RewardCategory.theme,
        rarity: RewardRarity.common,
        xpCost: 200,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      RewardItem(
        id: 'rw_02',
        name: 'First Blood',
        description: 'Awarded for completing your first action',
        emoji: '🏅',
        category: RewardCategory.badge,
        rarity: RewardRarity.common,
        xpCost: 50,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      RewardItem(
        id: 'rw_03',
        name: 'Streak Starter',
        description: 'Achieved a 3-day streak',
        emoji: '🔥',
        category: RewardCategory.badge,
        rarity: RewardRarity.common,
        xpCost: 100,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      RewardItem(
        id: 'rw_04',
        name: 'The Apprentice',
        description: 'Custom title: displayed on your profile',
        emoji: '🔧',
        category: RewardCategory.title,
        rarity: RewardRarity.rare,
        xpCost: 300,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      // Locked rewards
      const RewardItem(
        id: 'rw_05',
        name: 'Aurora Borealis',
        description: 'Gradient theme inspired by northern lights',
        emoji: '🌌',
        category: RewardCategory.theme,
        rarity: RewardRarity.rare,
        xpCost: 500,
      ),
      const RewardItem(
        id: 'rw_06',
        name: 'Iron Will',
        description: 'Complete 50 actions in Body lane',
        emoji: '💪',
        category: RewardCategory.badge,
        rarity: RewardRarity.rare,
        xpCost: 400,
      ),
      const RewardItem(
        id: 'rw_07',
        name: 'Mind Palace',
        description: 'Write 30 journal entries',
        emoji: '🧠',
        category: RewardCategory.badge,
        rarity: RewardRarity.epic,
        xpCost: 800,
      ),
      const RewardItem(
        id: 'rw_08',
        name: 'The Warrior',
        description: 'Elite title: displayed with golden border',
        emoji: '⚔️',
        category: RewardCategory.title,
        rarity: RewardRarity.epic,
        xpCost: 1000,
      ),
      const RewardItem(
        id: 'rw_09',
        name: 'Phoenix Rising',
        description: 'Legendary theme with fire particle effects',
        emoji: '🔥',
        category: RewardCategory.theme,
        rarity: RewardRarity.legendary,
        xpCost: 2000,
      ),
      const RewardItem(
        id: 'rw_10',
        name: 'Diamond Crown',
        description: 'Animated profile icon with sparkle effect',
        emoji: '💎',
        category: RewardCategory.icon,
        rarity: RewardRarity.legendary,
        xpCost: 1500,
      ),
      const RewardItem(
        id: 'rw_11',
        name: 'Thunder Bolt',
        description: 'Electric icon with pulse animation',
        emoji: '⚡',
        category: RewardCategory.icon,
        rarity: RewardRarity.epic,
        xpCost: 700,
      ),
      const RewardItem(
        id: 'rw_12',
        name: 'The Legend',
        description: 'Supreme title: only for the truly dedicated',
        emoji: '🌟',
        category: RewardCategory.title,
        rarity: RewardRarity.legendary,
        xpCost: 3000,
      ),
    ];
  }

  @override
  Future<List<WeeklyChallenge>> loadWeeklyChallenges() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final deadline = DateTime.now().add(const Duration(days: 3));
    return [
      WeeklyChallenge(
        id: 'wc_01',
        title: 'Action Hero',
        description: 'Complete 10 actions this week',
        xpReward: 100,
        targetCount: 10,
        currentCount: 7,
        deadline: deadline,
      ),
      WeeklyChallenge(
        id: 'wc_02',
        title: 'Journal Master',
        description: 'Write 5 journal entries',
        xpReward: 80,
        targetCount: 5,
        currentCount: 3,
        deadline: deadline,
      ),
      WeeklyChallenge(
        id: 'wc_03',
        title: 'Early Bird',
        description: 'Complete morning ritual 6 days',
        xpReward: 120,
        targetCount: 6,
        currentCount: 6,
        deadline: deadline,
        isCompleted: true,
      ),
    ];
  }

  @override
  Future<XPBreakdown> loadXPBreakdown() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final byDay = <String, int>{};
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayValues = [45, 30, 55, 20, 35, 0, 0];
    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayIndex = (date.weekday - 1) % 7;
      byDay[dayLabels[dayIndex]] = dayValues[i];
    }
    return XPBreakdown(
      bySource: const {
        XPSource.action: 280,
        XPSource.journal: 160,
        XPSource.ritual: 200,
        XPSource.streak: 220,
        XPSource.challenge: 90,
        XPSource.battle: 80,
        XPSource.forge: 70,
        XPSource.wakz: 40,
        XPSource.review: 40,
        XPSource.roleModel: 20,
      },
      byLane: const {
        'Mind': 340,
        'Body': 380,
        'Social': 180,
        'Skill': 300,
      },
      byDay: byDay,
    );
  }

  @override
  Future<RewardItem> purchaseReward(String rewardId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final rewards = await loadRewards();
    final reward = rewards.firstWhere((r) => r.id == rewardId);
    return reward.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  @override
  Future<int> claimDailyBonus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 25;
  }
}

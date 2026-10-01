import 'dart:ui' show Color;
import '../models/xp_system.dart';

// ─── Enums ───────────────────────────────────────────────────────────

enum XPSource {
  action,
  journal,
  ritual,
  streak,
  challenge,
  battle,
  forge,
  wakz,
  review,
  roleModel;

  String get label {
    switch (this) {
      case XPSource.action:
        return 'Action';
      case XPSource.journal:
        return 'Journal';
      case XPSource.ritual:
        return 'Morning Ritual';
      case XPSource.streak:
        return 'Streak Bonus';
      case XPSource.challenge:
        return 'Challenge';
      case XPSource.battle:
        return 'Battle';
      case XPSource.forge:
        return 'Forge';
      case XPSource.wakz:
        return 'Wakz';
      case XPSource.review:
        return 'Weekly Review';
      case XPSource.roleModel:
        return 'Role Model';
    }
  }

  String get emoji {
    switch (this) {
      case XPSource.action:
        return '✅';
      case XPSource.journal:
        return '📓';
      case XPSource.ritual:
        return '🌅';
      case XPSource.streak:
        return '🔥';
      case XPSource.challenge:
        return '🎯';
      case XPSource.battle:
        return '⚔️';
      case XPSource.forge:
        return '🔨';
      case XPSource.wakz:
        return '⚡';
      case XPSource.review:
        return '📊';
      case XPSource.roleModel:
        return '🌟';
    }
  }
}

enum RewardCategory {
  theme,
  badge,
  title,
  icon;

  String get label {
    switch (this) {
      case RewardCategory.theme:
        return 'Themes';
      case RewardCategory.badge:
        return 'Badges';
      case RewardCategory.title:
        return 'Titles';
      case RewardCategory.icon:
        return 'Icons';
    }
  }

  String get emoji {
    switch (this) {
      case RewardCategory.theme:
        return '🎨';
      case RewardCategory.badge:
        return '🏅';
      case RewardCategory.title:
        return '📛';
      case RewardCategory.icon:
        return '✨';
    }
  }
}

enum RewardRarity {
  common,
  rare,
  epic,
  legendary;

  String get label {
    switch (this) {
      case RewardRarity.common:
        return 'Common';
      case RewardRarity.rare:
        return 'Rare';
      case RewardRarity.epic:
        return 'Epic';
      case RewardRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case RewardRarity.common:
        return const Color(0xFF9AA6B2);
      case RewardRarity.rare:
        return const Color(0xFF3B82F6);
      case RewardRarity.epic:
        return const Color(0xFF8B5CF6);
      case RewardRarity.legendary:
        return const Color(0xFFF59E0B);
    }
  }
}

// ─── XPTransaction ───────────────────────────────────────────────────

class XPTransaction {
  final String id;
  final XPSource source;
  final int amount;
  final String description;
  final DateTime earnedAt;
  final String? lane;

  const XPTransaction({
    required this.id,
    required this.source,
    required this.amount,
    required this.description,
    required this.earnedAt,
    this.lane,
  });

  XPTransaction copyWith({
    String? id,
    XPSource? source,
    int? amount,
    String? description,
    DateTime? earnedAt,
    String? lane,
  }) {
    return XPTransaction(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      earnedAt: earnedAt ?? this.earnedAt,
      lane: lane ?? this.lane,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'amount': amount,
      'description': description,
      'earnedAt': earnedAt.toIso8601String(),
      'lane': lane,
    };
  }

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      id: json['id'] as String,
      source: XPSource.values.firstWhere((e) => e.name == json['source']),
      amount: json['amount'] as int,
      description: json['description'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      lane: json['lane'] as String?,
    );
  }
}

// ─── LeaderboardEntry ────────────────────────────────────────────────

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String avatar;
  final int totalXp;
  final int level;
  final int weeklyXp;
  final int streak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.totalXp,
    required this.level,
    required this.weeklyXp,
    required this.streak,
    this.isCurrentUser = false,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? userId,
    String? username,
    String? avatar,
    int? totalXp,
    int? level,
    int? weeklyXp,
    int? streak,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      streak: streak ?? this.streak,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'totalXp': totalXp,
      'level': level,
      'weeklyXp': weeklyXp,
      'streak': streak,
      'isCurrentUser': isCurrentUser,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      totalXp: json['totalXp'] as int,
      level: json['level'] as int,
      weeklyXp: json['weeklyXp'] as int,
      streak: json['streak'] as int,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

// ─── RewardItem ──────────────────────────────────────────────────────

class RewardItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final RewardCategory category;
  final RewardRarity rarity;
  final int xpCost;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? previewData;

  const RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    required this.xpCost,
    this.isUnlocked = false,
    this.unlockedAt,
    this.previewData,
  });

  RewardItem copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    RewardCategory? category,
    RewardRarity? rarity,
    int? xpCost,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? previewData,
  }) {
    return RewardItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      xpCost: xpCost ?? this.xpCost,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      previewData: previewData ?? this.previewData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'category': category.name,
      'rarity': rarity.name,
      'xpCost': xpCost,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'previewData': previewData,
    };
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: RewardCategory.values.firstWhere((e) => e.name == json['category']),
      rarity: RewardRarity.values.firstWhere((e) => e.name == json['rarity']),
      xpCost: json['xpCost'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      previewData: json['previewData'] as String?,
    );
  }
}

// ─── GamificationProfile ────────────────────────────────────────────

class GamificationProfile {
  final int totalXp;
  final XpLevel currentLevel;
  final int weeklyXp;
  final int monthlyXp;
  final int xpToNext;
  final double progressToNext;
  final int totalRewardsUnlocked;
  final int rank;

  const GamificationProfile({
    required this.totalXp,
    required this.currentLevel,
    required this.weeklyXp,
    required this.monthlyXp,
    required this.xpToNext,
    required this.progressToNext,
    required this.totalRewardsUnlocked,
    required this.rank,
  });

  GamificationProfile copyWith({
    int? totalXp,
    XpLevel? currentLevel,
    int? weeklyXp,
    int? monthlyXp,
    int? xpToNext,
    double? progressToNext,
    int? totalRewardsUnlocked,
    int? rank,
  }) {
    return GamificationProfile(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      monthlyXp: monthlyXp ?? this.monthlyXp,
      xpToNext: xpToNext ?? this.xpToNext,
      progressToNext: progressToNext ?? this.progressToNext,
      totalRewardsUnlocked: totalRewardsUnlocked ?? this.totalRewardsUnlocked,
      rank: rank ?? this.rank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'currentLevel': currentLevel.level,
      'weeklyXp': weeklyXp,
      'monthlyXp': monthlyXp,
      'xpToNext': xpToNext,
      'progressToNext': progressToNext,
      'totalRewardsUnlocked': totalRewardsUnlocked,
      'rank': rank,
    };
  }

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    final totalXp = json['totalXp'] as int;
    return GamificationProfile(
      totalXp: totalXp,
      currentLevel: XpSystem.levelFor(totalXp),
      weeklyXp: json['weeklyXp'] as int,
      monthlyXp: json['monthlyXp'] as int,
      xpToNext: XpSystem.xpToNextLevel(totalXp),
      progressToNext: XpSystem.progressToNext(totalXp),
      totalRewardsUnlocked: json['totalRewardsUnlocked'] as int,
      rank: json['rank'] as int,
    );
  }
}

// ─── WeeklyChallenge ─────────────────────────────────────────────────

class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int targetCount;
  final int currentCount;
  final DateTime deadline;
  final bool isCompleted;

  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.targetCount,
    required this.currentCount,
    required this.deadline,
    this.isCompleted = false,
  });

  double get progress =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  WeeklyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    int? xpReward,
    int? targetCount,
    int? currentCount,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return WeeklyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xpReward'] as int,
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

// ─── XPBreakdown ─────────────────────────────────────────────────────

class XPBreakdown {
  final Map<XPSource, int> bySource;
  final Map<String, int> byLane;
  final Map<String, int> byDay;

  const XPBreakdown({
    required this.bySource,
    required this.byLane,
    required this.byDay,
  });

  XPBreakdown copyWith({
    Map<XPSource, int>? bySource,
    Map<String, int>? byLane,
    Map<String, int>? byDay,
  }) {
    return XPBreakdown(
      bySource: bySource ?? this.bySource,
      byLane: byLane ?? this.byLane,
      byDay: byDay ?? this.byDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bySource': bySource.map((k, v) => MapEntry(k.name, v)),
      'byLane': byLane,
      'byDay': byDay,
    };
  }

  factory XPBreakdown.fromJson(Map<String, dynamic> json) {
    final bySourceRaw = json['bySource'] as Map<String, dynamic>;
    final bySource = bySourceRaw.map(
      (k, v) => MapEntry(
        XPSource.values.firstWhere((e) => e.name == k),
        v as int,
      ),
    );
    return XPBreakdown(
      bySource: bySource,
      byLane: Map<String, int>.from(json['byLane'] as Map),
      byDay: Map<String, int>.from(json['byDay'] as Map),
    );
  }
}

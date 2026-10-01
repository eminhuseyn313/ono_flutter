import 'package:flutter/material.dart';

enum AchievementCategory { streak, actions, lanes, social, milestones, special }

enum AchievementRarity { common, rare, epic, legendary }

class Achievement {
  final String id;
  final String title;
  final String description;
  final int iconCodePoint;
  final int colorValue;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int requiredProgress;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.colorValue,
    required this.category,
    required this.rarity,
    required this.requiredProgress,
    required this.currentProgress,
    required this.isUnlocked,
    this.unlockedAt,
    required this.xpReward,
  });

  double get progressPercent =>
      requiredProgress > 0 ? (currentProgress / requiredProgress).clamp(0.0, 1.0) : 0.0;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Color get color => Color(colorValue);

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? requiredProgress,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      requiredProgress: requiredProgress ?? this.requiredProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'category': category.name,
      'rarity': rarity.name,
      'requiredProgress': requiredProgress,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
      ),
      requiredProgress: json['requiredProgress'] as int,
      currentProgress: json['currentProgress'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      xpReward: json['xpReward'] as int,
    );
  }
}

class AchievementStats {
  final int totalAchievements;
  final int unlockedCount;
  final int totalXpEarned;
  final Map<AchievementCategory, int> categoryProgress;
  final AchievementRarity highestRarity;
  final List<Achievement> recentlyUnlocked;

  const AchievementStats({
    required this.totalAchievements,
    required this.unlockedCount,
    required this.totalXpEarned,
    required this.categoryProgress,
    required this.highestRarity,
    required this.recentlyUnlocked,
  });

  AchievementStats copyWith({
    int? totalAchievements,
    int? unlockedCount,
    int? totalXpEarned,
    Map<AchievementCategory, int>? categoryProgress,
    AchievementRarity? highestRarity,
    List<Achievement>? recentlyUnlocked,
  }) {
    return AchievementStats(
      totalAchievements: totalAchievements ?? this.totalAchievements,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      highestRarity: highestRarity ?? this.highestRarity,
      recentlyUnlocked: recentlyUnlocked ?? this.recentlyUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAchievements': totalAchievements,
      'unlockedCount': unlockedCount,
      'totalXpEarned': totalXpEarned,
      'categoryProgress': categoryProgress.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'highestRarity': highestRarity.name,
      'recentlyUnlocked': recentlyUnlocked.map((a) => a.toJson()).toList(),
    };
  }

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      totalAchievements: json['totalAchievements'] as int,
      unlockedCount: json['unlockedCount'] as int,
      totalXpEarned: json['totalXpEarned'] as int,
      categoryProgress: (json['categoryProgress'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          AchievementCategory.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
      highestRarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['highestRarity'],
      ),
      recentlyUnlocked: (json['recentlyUnlocked'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

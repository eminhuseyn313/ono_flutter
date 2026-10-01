import 'package:flutter/material.dart';

enum VaultMood {
  onFire,
  motivated,
  neutral,
  tired,
  struggling;

  String get emoji {
    switch (this) {
      case VaultMood.onFire:
        return '🔥';
      case VaultMood.motivated:
        return '💪';
      case VaultMood.neutral:
        return '😐';
      case VaultMood.tired:
        return '😴';
      case VaultMood.struggling:
        return '😤';
    }
  }

  String get label {
    switch (this) {
      case VaultMood.onFire:
        return 'On Fire';
      case VaultMood.motivated:
        return 'Motivated';
      case VaultMood.neutral:
        return 'Neutral';
      case VaultMood.tired:
        return 'Tired';
      case VaultMood.struggling:
        return 'Struggling';
    }
  }

  int get level {
    switch (this) {
      case VaultMood.onFire:
        return 5;
      case VaultMood.motivated:
        return 4;
      case VaultMood.neutral:
        return 3;
      case VaultMood.tired:
        return 2;
      case VaultMood.struggling:
        return 1;
    }
  }

  Color get color {
    switch (this) {
      case VaultMood.onFire:
        return const Color(0xFFEF4444);
      case VaultMood.motivated:
        return const Color(0xFF34D399);
      case VaultMood.neutral:
        return const Color(0xFF22D3EE);
      case VaultMood.tired:
        return const Color(0xFFF59E0B);
      case VaultMood.struggling:
        return const Color(0xFF8B5CF6);
    }
  }
}

enum VaultTag {
  gratitude,
  lesson,
  win,
  setback,
  idea,
  reflection;

  String get label {
    switch (this) {
      case VaultTag.gratitude:
        return 'Gratitude';
      case VaultTag.lesson:
        return 'Lesson';
      case VaultTag.win:
        return 'Win';
      case VaultTag.setback:
        return 'Setback';
      case VaultTag.idea:
        return 'Idea';
      case VaultTag.reflection:
        return 'Reflection';
    }
  }

  String get emoji {
    switch (this) {
      case VaultTag.gratitude:
        return '🙏';
      case VaultTag.lesson:
        return '📖';
      case VaultTag.win:
        return '🏆';
      case VaultTag.setback:
        return '⚡';
      case VaultTag.idea:
        return '💡';
      case VaultTag.reflection:
        return '🪞';
    }
  }
}

enum InsightType {
  pattern,
  milestone,
  suggestion,
  streak;

  String get label {
    switch (this) {
      case InsightType.pattern:
        return 'Pattern';
      case InsightType.milestone:
        return 'Milestone';
      case InsightType.suggestion:
        return 'Suggestion';
      case InsightType.streak:
        return 'Streak';
    }
  }
}

class VaultEntry {
  final String id;
  final String title;
  final String content;
  final VaultMood mood;
  final List<VaultTag> tags;
  final String? lane;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int wordCount;
  final bool isBookmarked;
  final bool isFavorite;

  const VaultEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    this.lane,
    required this.createdAt,
    required this.updatedAt,
    required this.wordCount,
    this.isBookmarked = false,
    this.isFavorite = false,
  });

  VaultEntry copyWith({
    String? id,
    String? title,
    String? content,
    VaultMood? mood,
    List<VaultTag>? tags,
    String? lane,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCount,
    bool? isBookmarked,
    bool? isFavorite,
  }) {
    return VaultEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      lane: lane ?? this.lane,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood.name,
      'tags': tags.map((t) => t.name).toList(),
      'lane': lane,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'wordCount': wordCount,
      'isBookmarked': isBookmarked,
      'isFavorite': isFavorite,
    };
  }

  factory VaultEntry.fromJson(Map<String, dynamic> json) {
    return VaultEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      mood: VaultMood.values.firstWhere((m) => m.name == json['mood']),
      tags: (json['tags'] as List<dynamic>)
          .map((t) => VaultTag.values.firstWhere((v) => v.name == t))
          .toList(),
      lane: json['lane'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      wordCount: json['wordCount'] as int,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class VaultInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final List<String> relatedEntryIds;
  final DateTime generatedAt;
  final String iconEmoji;

  const VaultInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.relatedEntryIds,
    required this.generatedAt,
    required this.iconEmoji,
  });

  VaultInsight copyWith({
    String? id,
    InsightType? type,
    String? title,
    String? description,
    List<String>? relatedEntryIds,
    DateTime? generatedAt,
    String? iconEmoji,
  }) {
    return VaultInsight(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      relatedEntryIds: relatedEntryIds ?? this.relatedEntryIds,
      generatedAt: generatedAt ?? this.generatedAt,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'relatedEntryIds': relatedEntryIds,
      'generatedAt': generatedAt.toIso8601String(),
      'iconEmoji': iconEmoji,
    };
  }

  factory VaultInsight.fromJson(Map<String, dynamic> json) {
    return VaultInsight(
      id: json['id'] as String,
      type: InsightType.values.firstWhere((t) => t.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      relatedEntryIds: (json['relatedEntryIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      iconEmoji: json['iconEmoji'] as String,
    );
  }
}

class GrowthPattern {
  final String id;
  final String patternName;
  final String description;
  final int frequency;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final double moodCorrelation;
  final String? lane;

  const GrowthPattern({
    required this.id,
    required this.patternName,
    required this.description,
    required this.frequency,
    required this.firstSeen,
    required this.lastSeen,
    required this.moodCorrelation,
    this.lane,
  });

  GrowthPattern copyWith({
    String? id,
    String? patternName,
    String? description,
    int? frequency,
    DateTime? firstSeen,
    DateTime? lastSeen,
    double? moodCorrelation,
    String? lane,
  }) {
    return GrowthPattern(
      id: id ?? this.id,
      patternName: patternName ?? this.patternName,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      moodCorrelation: moodCorrelation ?? this.moodCorrelation,
      lane: lane ?? this.lane,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patternName': patternName,
      'description': description,
      'frequency': frequency,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'moodCorrelation': moodCorrelation,
      'lane': lane,
    };
  }

  factory GrowthPattern.fromJson(Map<String, dynamic> json) {
    return GrowthPattern(
      id: json['id'] as String,
      patternName: json['patternName'] as String,
      description: json['description'] as String,
      frequency: json['frequency'] as int,
      firstSeen: DateTime.parse(json['firstSeen'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      moodCorrelation: (json['moodCorrelation'] as num).toDouble(),
      lane: json['lane'] as String?,
    );
  }
}

class VaultStats {
  final int totalEntries;
  final int totalWords;
  final int currentWritingStreak;
  final int longestWritingStreak;
  final double averageMood;
  final Map<VaultTag, int> topTags;
  final Map<String, int> entriesByMonth;
  final Map<String, int> entriesByLane;

  const VaultStats({
    required this.totalEntries,
    required this.totalWords,
    required this.currentWritingStreak,
    required this.longestWritingStreak,
    required this.averageMood,
    required this.topTags,
    required this.entriesByMonth,
    required this.entriesByLane,
  });

  VaultStats copyWith({
    int? totalEntries,
    int? totalWords,
    int? currentWritingStreak,
    int? longestWritingStreak,
    double? averageMood,
    Map<VaultTag, int>? topTags,
    Map<String, int>? entriesByMonth,
    Map<String, int>? entriesByLane,
  }) {
    return VaultStats(
      totalEntries: totalEntries ?? this.totalEntries,
      totalWords: totalWords ?? this.totalWords,
      currentWritingStreak: currentWritingStreak ?? this.currentWritingStreak,
      longestWritingStreak: longestWritingStreak ?? this.longestWritingStreak,
      averageMood: averageMood ?? this.averageMood,
      topTags: topTags ?? this.topTags,
      entriesByMonth: entriesByMonth ?? this.entriesByMonth,
      entriesByLane: entriesByLane ?? this.entriesByLane,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'totalWords': totalWords,
      'currentWritingStreak': currentWritingStreak,
      'longestWritingStreak': longestWritingStreak,
      'averageMood': averageMood,
      'topTags': topTags.map((k, v) => MapEntry(k.name, v)),
      'entriesByMonth': entriesByMonth,
      'entriesByLane': entriesByLane,
    };
  }

  factory VaultStats.fromJson(Map<String, dynamic> json) {
    return VaultStats(
      totalEntries: json['totalEntries'] as int,
      totalWords: json['totalWords'] as int,
      currentWritingStreak: json['currentWritingStreak'] as int,
      longestWritingStreak: json['longestWritingStreak'] as int,
      averageMood: (json['averageMood'] as num).toDouble(),
      topTags: (json['topTags'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          VaultTag.values.firstWhere((t) => t.name == k),
          v as int,
        ),
      ),
      entriesByMonth: (json['entriesByMonth'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      entriesByLane: (json['entriesByLane'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}

class MoodDataPoint {
  final DateTime date;
  final VaultMood mood;
  final int entryCount;

  const MoodDataPoint({
    required this.date,
    required this.mood,
    required this.entryCount,
  });

  MoodDataPoint copyWith({
    DateTime? date,
    VaultMood? mood,
    int? entryCount,
  }) {
    return MoodDataPoint(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      entryCount: entryCount ?? this.entryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mood': mood.name,
      'entryCount': entryCount,
    };
  }

  factory MoodDataPoint.fromJson(Map<String, dynamic> json) {
    return MoodDataPoint(
      date: DateTime.parse(json['date'] as String),
      mood: VaultMood.values.firstWhere((m) => m.name == json['mood']),
      entryCount: json['entryCount'] as int,
    );
  }
}

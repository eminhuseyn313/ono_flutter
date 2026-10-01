import 'package:flutter/foundation.dart';

/// App-wide settings model for the ONO settings screen.
class AppSettings {
  final String themeMode;
  final String language;
  final bool notificationsEnabled;
  final String dailyReminderTime;
  final bool weeklyDigestEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool privacyMode;
  final bool dataExportRequested;
  final bool analyticsOptIn;

  const AppSettings({
    this.themeMode = 'dark',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.dailyReminderTime = '08:00',
    this.weeklyDigestEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.privacyMode = false,
    this.dataExportRequested = false,
    this.analyticsOptIn = true,
  });

  AppSettings copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    String? dailyReminderTime,
    bool? weeklyDigestEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? privacyMode,
    bool? dataExportRequested,
    bool? analyticsOptIn,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      privacyMode: privacyMode ?? this.privacyMode,
      dataExportRequested: dataExportRequested ?? this.dataExportRequested,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'dailyReminderTime': dailyReminderTime,
      'weeklyDigestEnabled': weeklyDigestEnabled,
      'soundEnabled': soundEnabled,
      'hapticEnabled': hapticEnabled,
      'privacyMode': privacyMode,
      'dataExportRequested': dataExportRequested,
      'analyticsOptIn': analyticsOptIn,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] as String? ?? 'dark',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      dailyReminderTime: json['dailyReminderTime'] as String? ?? '08:00',
      weeklyDigestEnabled: json['weeklyDigestEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      privacyMode: json['privacyMode'] as bool? ?? false,
      dataExportRequested: json['dataExportRequested'] as bool? ?? false,
      analyticsOptIn: json['analyticsOptIn'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.notificationsEnabled == notificationsEnabled &&
        other.dailyReminderTime == dailyReminderTime &&
        other.weeklyDigestEnabled == weeklyDigestEnabled &&
        other.soundEnabled == soundEnabled &&
        other.hapticEnabled == hapticEnabled &&
        other.privacyMode == privacyMode &&
        other.dataExportRequested == dataExportRequested &&
        other.analyticsOptIn == analyticsOptIn;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      language,
      notificationsEnabled,
      dailyReminderTime,
      weeklyDigestEnabled,
      soundEnabled,
      hapticEnabled,
      privacyMode,
      dataExportRequested,
      analyticsOptIn,
    );
  }

  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, language: $language, '
        'notificationsEnabled: $notificationsEnabled, '
        'dailyReminderTime: $dailyReminderTime, '
        'weeklyDigestEnabled: $weeklyDigestEnabled, '
        'soundEnabled: $soundEnabled, hapticEnabled: $hapticEnabled, '
        'privacyMode: $privacyMode, '
        'dataExportRequested: $dataExportRequested, '
        'analyticsOptIn: $analyticsOptIn)';
  }
}

/// Aggregated user statistics displayed in the settings/account section.
class UserStats {
  final int totalXp;
  final int currentLevel;
  final String levelTitle;
  final int streakDays;
  final int totalActionsCompleted;
  final int totalJournalEntries;
  final int totalDaysActive;
  final DateTime memberSince;
  final String favoriteCategory;

  const UserStats({
    required this.totalXp,
    required this.currentLevel,
    required this.levelTitle,
    required this.streakDays,
    required this.totalActionsCompleted,
    required this.totalJournalEntries,
    required this.totalDaysActive,
    required this.memberSince,
    required this.favoriteCategory,
  });

  /// Returns the XP threshold for the current level based on the
  /// existing XpSystem 10-level scale (Rookie -> Transcendent, 0 -> 8000).
  int get currentLevelXpThreshold {
    const thresholds = [0, 100, 300, 600, 1000, 1600, 2400, 3500, 5000, 8000];
    if (currentLevel < 1) return 0;
    if (currentLevel > 10) return 8000;
    return thresholds[currentLevel - 1];
  }

  /// Returns the XP threshold for the next level.
  int get nextLevelXpThreshold {
    const thresholds = [0, 100, 300, 600, 1000, 1600, 2400, 3500, 5000, 8000];
    if (currentLevel >= 10) return 8000;
    return thresholds[currentLevel];
  }

  /// Progress fraction (0.0 - 1.0) toward the next level.
  double get progressToNextLevel {
    if (currentLevel >= 10) return 1.0;
    final base = currentLevelXpThreshold;
    final next = nextLevelXpThreshold;
    final range = next - base;
    if (range <= 0) return 1.0;
    return ((totalXp - base) / range).clamp(0.0, 1.0);
  }

  /// XP remaining until the next level.
  int get xpToNextLevel {
    if (currentLevel >= 10) return 0;
    return nextLevelXpThreshold - totalXp;
  }

  UserStats copyWith({
    int? totalXp,
    int? currentLevel,
    String? levelTitle,
    int? streakDays,
    int? totalActionsCompleted,
    int? totalJournalEntries,
    int? totalDaysActive,
    DateTime? memberSince,
    String? favoriteCategory,
  }) {
    return UserStats(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      levelTitle: levelTitle ?? this.levelTitle,
      streakDays: streakDays ?? this.streakDays,
      totalActionsCompleted:
          totalActionsCompleted ?? this.totalActionsCompleted,
      totalJournalEntries: totalJournalEntries ?? this.totalJournalEntries,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      memberSince: memberSince ?? this.memberSince,
      favoriteCategory: favoriteCategory ?? this.favoriteCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'currentLevel': currentLevel,
      'levelTitle': levelTitle,
      'streakDays': streakDays,
      'totalActionsCompleted': totalActionsCompleted,
      'totalJournalEntries': totalJournalEntries,
      'totalDaysActive': totalDaysActive,
      'memberSince': memberSince.toIso8601String(),
      'favoriteCategory': favoriteCategory,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalXp: json['totalXp'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      levelTitle: json['levelTitle'] as String? ?? 'Rookie',
      streakDays: json['streakDays'] as int? ?? 0,
      totalActionsCompleted: json['totalActionsCompleted'] as int? ?? 0,
      totalJournalEntries: json['totalJournalEntries'] as int? ?? 0,
      totalDaysActive: json['totalDaysActive'] as int? ?? 0,
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'] as String)
          : DateTime.now(),
      favoriteCategory: json['favoriteCategory'] as String? ?? 'General',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats &&
        other.totalXp == totalXp &&
        other.currentLevel == currentLevel &&
        other.levelTitle == levelTitle &&
        other.streakDays == streakDays &&
        other.totalActionsCompleted == totalActionsCompleted &&
        other.totalJournalEntries == totalJournalEntries &&
        other.totalDaysActive == totalDaysActive &&
        other.memberSince == memberSince &&
        other.favoriteCategory == favoriteCategory;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalXp,
      currentLevel,
      levelTitle,
      streakDays,
      totalActionsCompleted,
      totalJournalEntries,
      totalDaysActive,
      memberSince,
      favoriteCategory,
    );
  }

  @override
  String toString() {
    return 'UserStats(totalXp: $totalXp, level: $currentLevel "$levelTitle", '
        'streak: $streakDays, actions: $totalActionsCompleted, '
        'journals: $totalJournalEntries, daysActive: $totalDaysActive, '
        'memberSince: $memberSince, favorite: $favoriteCategory)';
  }
}

/// Metadata about the app build and sync state.
class AppInfo {
  final String version;
  final String buildNumber;
  final DateTime? lastSyncAt;

  const AppInfo({
    required this.version,
    required this.buildNumber,
    this.lastSyncAt,
  });

  AppInfo copyWith({
    String? version,
    String? buildNumber,
    DateTime? lastSyncAt,
  }) {
    return AppInfo(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] as String? ?? '1',
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppInfo &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.lastSyncAt == lastSyncAt;
  }

  @override
  int get hashCode => Object.hash(version, buildNumber, lastSyncAt);

  @override
  String toString() {
    return 'AppInfo(version: $version, build: $buildNumber, '
        'lastSync: $lastSyncAt)';
  }
}

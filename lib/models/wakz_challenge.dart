// models/wakz_challenge.dart
// Wakz Social Proof Challenges — models, enums, data classes

enum ChallengeType {
  daily,
  weekly,
  battle,
  group;

  String get label {
    switch (this) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.battle:
        return 'Battle';
      case ChallengeType.group:
        return 'Group';
    }
  }
}

enum VerificationType {
  photo,
  selfie,
  screenshot,
  honor;

  String get label {
    switch (this) {
      case VerificationType.photo:
        return 'Photo Proof';
      case VerificationType.selfie:
        return 'Selfie Proof';
      case VerificationType.screenshot:
        return 'Screenshot';
      case VerificationType.honor:
        return 'Honor System';
    }
  }

  String get emoji {
    switch (this) {
      case VerificationType.photo:
        return '\u{1F4F8}';
      case VerificationType.selfie:
        return '\u{1F933}';
      case VerificationType.screenshot:
        return '\u{1F4F1}';
      case VerificationType.honor:
        return '\u{1F91D}';
    }
  }

  String get description {
    switch (this) {
      case VerificationType.photo:
        return 'Take a photo as proof of completion';
      case VerificationType.selfie:
        return 'Take a selfie while doing the challenge';
      case VerificationType.screenshot:
        return 'Share a screenshot as evidence';
      case VerificationType.honor:
        return 'Mark complete on the honor system';
    }
  }
}

enum ChallengeCategory {
  fitness,
  reading,
  meditation,
  social,
  skill,
  creative;

  String get emoji {
    switch (this) {
      case ChallengeCategory.fitness:
        return '\u{1F4AA}';
      case ChallengeCategory.reading:
        return '\u{1F4DA}';
      case ChallengeCategory.meditation:
        return '\u{1F9D8}';
      case ChallengeCategory.social:
        return '\u{1F91D}';
      case ChallengeCategory.skill:
        return '\u{1F3AF}';
      case ChallengeCategory.creative:
        return '\u{1F3A8}';
    }
  }

  String get label {
    switch (this) {
      case ChallengeCategory.fitness:
        return 'Fitness';
      case ChallengeCategory.reading:
        return 'Reading';
      case ChallengeCategory.meditation:
        return 'Meditation';
      case ChallengeCategory.social:
        return 'Social';
      case ChallengeCategory.skill:
        return 'Skill';
      case ChallengeCategory.creative:
        return 'Creative';
    }
  }

  String get lane {
    switch (this) {
      case ChallengeCategory.fitness:
        return 'body';
      case ChallengeCategory.reading:
        return 'mind';
      case ChallengeCategory.meditation:
        return 'soul';
      case ChallengeCategory.social:
        return 'soul';
      case ChallengeCategory.skill:
        return 'mind';
      case ChallengeCategory.creative:
        return 'mind';
    }
  }
}

enum BadgeTier {
  bronze,
  silver,
  gold;

  String get label {
    switch (this) {
      case BadgeTier.bronze:
        return 'Bronze';
      case BadgeTier.silver:
        return 'Silver';
      case BadgeTier.gold:
        return 'Gold';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeTier.bronze:
        return '\u{1F949}';
      case BadgeTier.silver:
        return '\u{1F948}';
      case BadgeTier.gold:
        return '\u{1F947}';
    }
  }
}

class WakzChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeCategory category;
  final VerificationType verificationType;
  final int targetCount;
  final int currentCount;
  final DateTime? startedAt;
  final DateTime deadline;
  final bool isCompleted;
  final bool isVerified;
  final String? proofImagePath;
  final String lane;

  const WakzChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.verificationType,
    required this.targetCount,
    this.currentCount = 0,
    this.startedAt,
    required this.deadline,
    this.isCompleted = false,
    this.isVerified = false,
    this.proofImagePath,
    required this.lane,
  });

  double get progressPercent =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  Duration get timeRemaining => deadline.difference(DateTime.now());

  bool get isExpired => DateTime.now().isAfter(deadline);

  WakzChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeCategory? category,
    VerificationType? verificationType,
    int? targetCount,
    int? currentCount,
    DateTime? startedAt,
    DateTime? deadline,
    bool? isCompleted,
    bool? isVerified,
    String? proofImagePath,
    String? lane,
  }) {
    return WakzChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      verificationType: verificationType ?? this.verificationType,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      startedAt: startedAt ?? this.startedAt,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isVerified: isVerified ?? this.isVerified,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      lane: lane ?? this.lane,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name,
      'verificationType': verificationType.name,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'startedAt': startedAt?.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted,
      'isVerified': isVerified,
      'proofImagePath': proofImagePath,
      'lane': lane,
    };
  }

  factory WakzChallenge.fromJson(Map<String, dynamic> json) {
    return WakzChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ChallengeType.values.byName(json['type'] as String),
      category: ChallengeCategory.values.byName(json['category'] as String),
      verificationType:
          VerificationType.values.byName(json['verificationType'] as String),
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int? ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      proofImagePath: json['proofImagePath'] as String?,
      lane: json['lane'] as String,
    );
  }
}

class ChallengeBattle {
  final String id;
  final String challengeId;
  final String opponentName;
  final String opponentEmoji;
  final int opponentProgress;
  final int myProgress;
  final int targetCount;
  final DateTime startedAt;
  final DateTime endsAt;
  final String? winnerId;

  const ChallengeBattle({
    required this.id,
    required this.challengeId,
    required this.opponentName,
    required this.opponentEmoji,
    required this.opponentProgress,
    required this.myProgress,
    required this.targetCount,
    required this.startedAt,
    required this.endsAt,
    this.winnerId,
  });

  bool get isFinished => DateTime.now().isAfter(endsAt) || winnerId != null;

  Duration get timeRemaining => endsAt.difference(DateTime.now());

  double get myProgressPercent =>
      targetCount > 0 ? (myProgress / targetCount).clamp(0.0, 1.0) : 0.0;

  double get opponentProgressPercent =>
      targetCount > 0
          ? (opponentProgress / targetCount).clamp(0.0, 1.0)
          : 0.0;

  ChallengeBattle copyWith({
    String? id,
    String? challengeId,
    String? opponentName,
    String? opponentEmoji,
    int? opponentProgress,
    int? myProgress,
    int? targetCount,
    DateTime? startedAt,
    DateTime? endsAt,
    String? winnerId,
  }) {
    return ChallengeBattle(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      opponentName: opponentName ?? this.opponentName,
      opponentEmoji: opponentEmoji ?? this.opponentEmoji,
      opponentProgress: opponentProgress ?? this.opponentProgress,
      myProgress: myProgress ?? this.myProgress,
      targetCount: targetCount ?? this.targetCount,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'opponentName': opponentName,
      'opponentEmoji': opponentEmoji,
      'opponentProgress': opponentProgress,
      'myProgress': myProgress,
      'targetCount': targetCount,
      'startedAt': startedAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'winnerId': winnerId,
    };
  }

  factory ChallengeBattle.fromJson(Map<String, dynamic> json) {
    return ChallengeBattle(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      opponentName: json['opponentName'] as String,
      opponentEmoji: json['opponentEmoji'] as String,
      opponentProgress: json['opponentProgress'] as int,
      myProgress: json['myProgress'] as int,
      targetCount: json['targetCount'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      winnerId: json['winnerId'] as String?,
    );
  }
}

class CommunityProof {
  final String id;
  final String challengeId;
  final String anonymousName;
  final String avatarEmoji;
  final String proofDescription;
  final DateTime verifiedAt;
  final String lane;
  final int likesCount;
  final bool isLiked;

  const CommunityProof({
    required this.id,
    required this.challengeId,
    required this.anonymousName,
    required this.avatarEmoji,
    required this.proofDescription,
    required this.verifiedAt,
    required this.lane,
    this.likesCount = 0,
    this.isLiked = false,
  });

  CommunityProof copyWith({
    String? id,
    String? challengeId,
    String? anonymousName,
    String? avatarEmoji,
    String? proofDescription,
    DateTime? verifiedAt,
    String? lane,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommunityProof(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      anonymousName: anonymousName ?? this.anonymousName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      proofDescription: proofDescription ?? this.proofDescription,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lane: lane ?? this.lane,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'anonymousName': anonymousName,
      'avatarEmoji': avatarEmoji,
      'proofDescription': proofDescription,
      'verifiedAt': verifiedAt.toIso8601String(),
      'lane': lane,
      'likesCount': likesCount,
      'isLiked': isLiked,
    };
  }

  factory CommunityProof.fromJson(Map<String, dynamic> json) {
    return CommunityProof(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      anonymousName: json['anonymousName'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      proofDescription: json['proofDescription'] as String,
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      lane: json['lane'] as String,
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }
}

class WakzBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime? earnedAt;
  final ChallengeCategory category;
  final BadgeTier tier;

  const WakzBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.earnedAt,
    required this.category,
    required this.tier,
  });

  bool get isEarned => earnedAt != null;

  WakzBadge copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    DateTime? earnedAt,
    ChallengeCategory? category,
    BadgeTier? tier,
  }) {
    return WakzBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      earnedAt: earnedAt ?? this.earnedAt,
      category: category ?? this.category,
      tier: tier ?? this.tier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'earnedAt': earnedAt?.toIso8601String(),
      'category': category.name,
      'tier': tier.name,
    };
  }

  factory WakzBadge.fromJson(Map<String, dynamic> json) {
    return WakzBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      description: json['description'] as String,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'] as String)
          : null,
      category: ChallengeCategory.values.byName(json['category'] as String),
      tier: BadgeTier.values.byName(json['tier'] as String),
    );
  }
}

class WakzStats {
  final int totalChallengesCompleted;
  final int totalVerified;
  final int currentWinStreak;
  final int longestWinStreak;
  final int battlesWon;
  final int battlesLost;
  final List<WakzBadge> badges;

  const WakzStats({
    this.totalChallengesCompleted = 0,
    this.totalVerified = 0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
    this.battlesWon = 0,
    this.battlesLost = 0,
    this.badges = const [],
  });

  double get verificationRate => totalChallengesCompleted > 0
      ? totalVerified / totalChallengesCompleted
      : 0.0;

  WakzStats copyWith({
    int? totalChallengesCompleted,
    int? totalVerified,
    int? currentWinStreak,
    int? longestWinStreak,
    int? battlesWon,
    int? battlesLost,
    List<WakzBadge>? badges,
  }) {
    return WakzStats(
      totalChallengesCompleted:
          totalChallengesCompleted ?? this.totalChallengesCompleted,
      totalVerified: totalVerified ?? this.totalVerified,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      battlesWon: battlesWon ?? this.battlesWon,
      battlesLost: battlesLost ?? this.battlesLost,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChallengesCompleted': totalChallengesCompleted,
      'totalVerified': totalVerified,
      'currentWinStreak': currentWinStreak,
      'longestWinStreak': longestWinStreak,
      'battlesWon': battlesWon,
      'battlesLost': battlesLost,
      'badges': badges.map((b) => b.toJson()).toList(),
    };
  }

  factory WakzStats.fromJson(Map<String, dynamic> json) {
    return WakzStats(
      totalChallengesCompleted: json['totalChallengesCompleted'] as int? ?? 0,
      totalVerified: json['totalVerified'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      longestWinStreak: json['longestWinStreak'] as int? ?? 0,
      battlesWon: json['battlesWon'] as int? ?? 0,
      battlesLost: json['battlesLost'] as int? ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => WakzBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

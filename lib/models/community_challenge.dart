enum ChallengeStatus {
  upcoming,
  active,
  completed;

  String get label {
    switch (this) {
      case ChallengeStatus.upcoming:
        return 'Upcoming';
      case ChallengeStatus.active:
        return 'Active';
      case ChallengeStatus.completed:
        return 'Completed';
    }
  }
}

enum ChallengeType {
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.weekly:
        return 'Weekly';
      case ChallengeType.monthly:
        return 'Monthly';
    }
  }
}

class ChallengeParticipant {
  final String id;
  final String name;
  final String avatarInitial;
  final int avatarColorValue;
  final double progress;
  final int score;

  const ChallengeParticipant({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.avatarColorValue,
    required this.progress,
    required this.score,
  });

  ChallengeParticipant copyWith({
    String? id,
    String? name,
    String? avatarInitial,
    int? avatarColorValue,
    double? progress,
    int? score,
  }) {
    return ChallengeParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      progress: progress ?? this.progress,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_initial': avatarInitial,
        'avatar_color_value': avatarColorValue,
        'progress': progress,
        'score': score,
      };

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      ChallengeParticipant(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarInitial: json['avatar_initial'] as String,
        avatarColorValue: json['avatar_color_value'] as int,
        progress: (json['progress'] as num).toDouble(),
        score: json['score'] as int,
      );
}

class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final String lane;
  final int laneColorValue;
  final ChallengeStatus status;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final List<ChallengeParticipant> topParticipants;
  final bool isJoined;
  final double myProgress;
  final int myRank;
  final String reward;
  final int targetValue;
  final String targetUnit;

  const CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.lane,
    required this.laneColorValue,
    required this.status,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    this.topParticipants = const [],
    this.isJoined = false,
    this.myProgress = 0.0,
    this.myRank = 0,
    required this.reward,
    required this.targetValue,
    required this.targetUnit,
  });

  CommunityChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? lane,
    int? laneColorValue,
    ChallengeStatus? status,
    ChallengeType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? participantCount,
    List<ChallengeParticipant>? topParticipants,
    bool? isJoined,
    double? myProgress,
    int? myRank,
    String? reward,
    int? targetValue,
    String? targetUnit,
  }) {
    return CommunityChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lane: lane ?? this.lane,
      laneColorValue: laneColorValue ?? this.laneColorValue,
      status: status ?? this.status,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participantCount: participantCount ?? this.participantCount,
      topParticipants: topParticipants ?? this.topParticipants,
      isJoined: isJoined ?? this.isJoined,
      myProgress: myProgress ?? this.myProgress,
      myRank: myRank ?? this.myRank,
      reward: reward ?? this.reward,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'lane': lane,
        'lane_color_value': laneColorValue,
        'status': status.name,
        'type': type.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'participant_count': participantCount,
        'top_participants':
            topParticipants.map((p) => p.toJson()).toList(),
        'is_joined': isJoined,
        'my_progress': myProgress,
        'my_rank': myRank,
        'reward': reward,
        'target_value': targetValue,
        'target_unit': targetUnit,
      };

  factory CommunityChallenge.fromJson(Map<String, dynamic> json) =>
      CommunityChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        lane: json['lane'] as String,
        laneColorValue: json['lane_color_value'] as int,
        status: ChallengeStatus.values
            .firstWhere((e) => e.name == json['status']),
        type: ChallengeType.values
            .firstWhere((e) => e.name == json['type']),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        participantCount: json['participant_count'] as int,
        topParticipants: (json['top_participants'] as List<dynamic>?)
                ?.map((p) =>
                    ChallengeParticipant.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        isJoined: json['is_joined'] as bool? ?? false,
        myProgress: (json['my_progress'] as num?)?.toDouble() ?? 0.0,
        myRank: json['my_rank'] as int? ?? 0,
        reward: json['reward'] as String,
        targetValue: json['target_value'] as int,
        targetUnit: json['target_unit'] as String,
      );
}

class ChallengeData {
  final List<CommunityChallenge> challenges;
  final int totalParticipants;
  final int activeChallenges;
  final int completedChallenges;

  const ChallengeData({
    required this.challenges,
    required this.totalParticipants,
    required this.activeChallenges,
    required this.completedChallenges,
  });

  ChallengeData copyWith({
    List<CommunityChallenge>? challenges,
    int? totalParticipants,
    int? activeChallenges,
    int? completedChallenges,
  }) {
    return ChallengeData(
      challenges: challenges ?? this.challenges,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
    );
  }
}

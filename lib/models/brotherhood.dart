enum SquadMessageType {
  encouragement,
  milestone,
  challengeComplete,
  joined,
}

class BrotherhoodMember {
  final String id;
  final String anonymousName;
  final String avatarEmoji;
  final int streakDays;
  final double completionRate;
  final bool isCurrentUser;
  final DateTime lastActiveAt;
  final String? roleModelId;

  const BrotherhoodMember({
    required this.id,
    required this.anonymousName,
    required this.avatarEmoji,
    required this.streakDays,
    required this.completionRate,
    required this.isCurrentUser,
    required this.lastActiveAt,
    this.roleModelId,
  });

  BrotherhoodMember copyWith({
    String? id,
    String? anonymousName,
    String? avatarEmoji,
    int? streakDays,
    double? completionRate,
    bool? isCurrentUser,
    DateTime? lastActiveAt,
    String? roleModelId,
  }) {
    return BrotherhoodMember(
      id: id ?? this.id,
      anonymousName: anonymousName ?? this.anonymousName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      streakDays: streakDays ?? this.streakDays,
      completionRate: completionRate ?? this.completionRate,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      roleModelId: roleModelId ?? this.roleModelId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anonymousName': anonymousName,
      'avatarEmoji': avatarEmoji,
      'streakDays': streakDays,
      'completionRate': completionRate,
      'isCurrentUser': isCurrentUser,
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'roleModelId': roleModelId,
    };
  }

  factory BrotherhoodMember.fromJson(Map<String, dynamic> json) {
    return BrotherhoodMember(
      id: json['id'] as String,
      anonymousName: json['anonymousName'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      streakDays: json['streakDays'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      isCurrentUser: json['isCurrentUser'] as bool,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      roleModelId: json['roleModelId'] as String?,
    );
  }
}

class BrotherhoodSquad {
  final String id;
  final String name;
  final List<BrotherhoodMember> members;
  final DateTime createdAt;
  final String journeyId;
  final int weekNumber;

  const BrotherhoodSquad({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    required this.journeyId,
    required this.weekNumber,
  });

  BrotherhoodSquad copyWith({
    String? id,
    String? name,
    List<BrotherhoodMember>? members,
    DateTime? createdAt,
    String? journeyId,
    int? weekNumber,
  }) {
    return BrotherhoodSquad(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      journeyId: journeyId ?? this.journeyId,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'journeyId': journeyId,
      'weekNumber': weekNumber,
    };
  }

  factory BrotherhoodSquad.fromJson(Map<String, dynamic> json) {
    return BrotherhoodSquad(
      id: json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List)
          .map((m) => BrotherhoodMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      journeyId: json['journeyId'] as String,
      weekNumber: json['weekNumber'] as int,
    );
  }
}

class SquadChallenge {
  final String id;
  final String title;
  final String description;
  final int targetCompletions;
  final int currentCompletions;
  final DateTime deadline;
  final String reward;

  const SquadChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCompletions,
    required this.currentCompletions,
    required this.deadline,
    required this.reward,
  });

  SquadChallenge copyWith({
    String? id,
    String? title,
    String? description,
    int? targetCompletions,
    int? currentCompletions,
    DateTime? deadline,
    String? reward,
  }) {
    return SquadChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCompletions: targetCompletions ?? this.targetCompletions,
      currentCompletions: currentCompletions ?? this.currentCompletions,
      deadline: deadline ?? this.deadline,
      reward: reward ?? this.reward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetCompletions': targetCompletions,
      'currentCompletions': currentCompletions,
      'deadline': deadline.toIso8601String(),
      'reward': reward,
    };
  }

  factory SquadChallenge.fromJson(Map<String, dynamic> json) {
    return SquadChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetCompletions: json['targetCompletions'] as int,
      currentCompletions: json['currentCompletions'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      reward: json['reward'] as String,
    );
  }
}

class SquadMessage {
  final String id;
  final String senderId;
  final String anonymousName;
  final String message;
  final DateTime timestamp;
  final SquadMessageType type;

  const SquadMessage({
    required this.id,
    required this.senderId,
    required this.anonymousName,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  SquadMessage copyWith({
    String? id,
    String? senderId,
    String? anonymousName,
    String? message,
    DateTime? timestamp,
    SquadMessageType? type,
  }) {
    return SquadMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      anonymousName: anonymousName ?? this.anonymousName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'anonymousName': anonymousName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory SquadMessage.fromJson(Map<String, dynamic> json) {
    return SquadMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      anonymousName: json['anonymousName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: SquadMessageType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
    );
  }
}

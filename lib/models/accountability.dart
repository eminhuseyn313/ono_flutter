// models/accountability.dart

enum PartnerStatus { pending, active, paused, ended }

enum CheckInMood { fired, steady, struggling, ghosting }

enum ProofType { photo, text, streak }

class AccountabilityPartner {
  final String id;
  final String odaCode;
  final String partnerName;
  final String partnerAvatar;
  final PartnerStatus status;
  final int sharedStreak;
  final int longestStreak;
  final DateTime startedAt;
  final DateTime? lastCheckInAt;
  final int partnerLevel;
  final int partnerXp;

  const AccountabilityPartner({
    required this.id,
    required this.odaCode,
    required this.partnerName,
    required this.partnerAvatar,
    required this.status,
    required this.sharedStreak,
    required this.longestStreak,
    required this.startedAt,
    this.lastCheckInAt,
    required this.partnerLevel,
    required this.partnerXp,
  });

  AccountabilityPartner copyWith({
    String? id,
    String? odaCode,
    String? partnerName,
    String? partnerAvatar,
    PartnerStatus? status,
    int? sharedStreak,
    int? longestStreak,
    DateTime? startedAt,
    DateTime? lastCheckInAt,
    int? partnerLevel,
    int? partnerXp,
  }) {
    return AccountabilityPartner(
      id: id ?? this.id,
      odaCode: odaCode ?? this.odaCode,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      status: status ?? this.status,
      sharedStreak: sharedStreak ?? this.sharedStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      startedAt: startedAt ?? this.startedAt,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      partnerLevel: partnerLevel ?? this.partnerLevel,
      partnerXp: partnerXp ?? this.partnerXp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odaCode': odaCode,
      'partnerName': partnerName,
      'partnerAvatar': partnerAvatar,
      'status': status.name,
      'sharedStreak': sharedStreak,
      'longestStreak': longestStreak,
      'startedAt': startedAt.toIso8601String(),
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'partnerLevel': partnerLevel,
      'partnerXp': partnerXp,
    };
  }

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) {
    return AccountabilityPartner(
      id: json['id'] as String,
      odaCode: json['odaCode'] as String,
      partnerName: json['partnerName'] as String,
      partnerAvatar: json['partnerAvatar'] as String,
      status: PartnerStatus.values.byName(json['status'] as String),
      sharedStreak: json['sharedStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastCheckInAt: json['lastCheckInAt'] != null
          ? DateTime.parse(json['lastCheckInAt'] as String)
          : null,
      partnerLevel: json['partnerLevel'] as int,
      partnerXp: json['partnerXp'] as int,
    );
  }
}

class PartnerRequest {
  final String id;
  final String fromName;
  final String fromAvatar;
  final int fromLevel;
  final DateTime sentAt;
  final String message;

  const PartnerRequest({
    required this.id,
    required this.fromName,
    required this.fromAvatar,
    required this.fromLevel,
    required this.sentAt,
    required this.message,
  });

  PartnerRequest copyWith({
    String? id,
    String? fromName,
    String? fromAvatar,
    int? fromLevel,
    DateTime? sentAt,
    String? message,
  }) {
    return PartnerRequest(
      id: id ?? this.id,
      fromName: fromName ?? this.fromName,
      fromAvatar: fromAvatar ?? this.fromAvatar,
      fromLevel: fromLevel ?? this.fromLevel,
      sentAt: sentAt ?? this.sentAt,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromName': fromName,
      'fromAvatar': fromAvatar,
      'fromLevel': fromLevel,
      'sentAt': sentAt.toIso8601String(),
      'message': message,
    };
  }

  factory PartnerRequest.fromJson(Map<String, dynamic> json) {
    return PartnerRequest(
      id: json['id'] as String,
      fromName: json['fromName'] as String,
      fromAvatar: json['fromAvatar'] as String,
      fromLevel: json['fromLevel'] as int,
      sentAt: DateTime.parse(json['sentAt'] as String),
      message: json['message'] as String,
    );
  }
}

class SharedProof {
  final String id;
  final String partnerId;
  final String senderName;
  final ProofType proofType;
  final String content;
  final String caption;
  final DateTime sentAt;
  final bool isVerified;

  const SharedProof({
    required this.id,
    required this.partnerId,
    required this.senderName,
    required this.proofType,
    required this.content,
    required this.caption,
    required this.sentAt,
    required this.isVerified,
  });

  SharedProof copyWith({
    String? id,
    String? partnerId,
    String? senderName,
    ProofType? proofType,
    String? content,
    String? caption,
    DateTime? sentAt,
    bool? isVerified,
  }) {
    return SharedProof(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      senderName: senderName ?? this.senderName,
      proofType: proofType ?? this.proofType,
      content: content ?? this.content,
      caption: caption ?? this.caption,
      sentAt: sentAt ?? this.sentAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'senderName': senderName,
      'proofType': proofType.name,
      'content': content,
      'caption': caption,
      'sentAt': sentAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory SharedProof.fromJson(Map<String, dynamic> json) {
    return SharedProof(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String,
      senderName: json['senderName'] as String,
      proofType: ProofType.values.byName(json['proofType'] as String),
      content: json['content'] as String,
      caption: json['caption'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isVerified: json['isVerified'] as bool,
    );
  }
}

class DailyCheckIn {
  final String id;
  final String partnerId;
  final CheckInMood mood;
  final String message;
  final int actionsCompleted;
  final int streakDay;
  final DateTime sentAt;
  final String? partnerResponse;

  const DailyCheckIn({
    required this.id,
    required this.partnerId,
    required this.mood,
    required this.message,
    required this.actionsCompleted,
    required this.streakDay,
    required this.sentAt,
    this.partnerResponse,
  });

  DailyCheckIn copyWith({
    String? id,
    String? partnerId,
    CheckInMood? mood,
    String? message,
    int? actionsCompleted,
    int? streakDay,
    DateTime? sentAt,
    String? partnerResponse,
  }) {
    return DailyCheckIn(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      mood: mood ?? this.mood,
      message: message ?? this.message,
      actionsCompleted: actionsCompleted ?? this.actionsCompleted,
      streakDay: streakDay ?? this.streakDay,
      sentAt: sentAt ?? this.sentAt,
      partnerResponse: partnerResponse ?? this.partnerResponse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'mood': mood.name,
      'message': message,
      'actionsCompleted': actionsCompleted,
      'streakDay': streakDay,
      'sentAt': sentAt.toIso8601String(),
      'partnerResponse': partnerResponse,
    };
  }

  factory DailyCheckIn.fromJson(Map<String, dynamic> json) {
    return DailyCheckIn(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String,
      mood: CheckInMood.values.byName(json['mood'] as String),
      message: json['message'] as String,
      actionsCompleted: json['actionsCompleted'] as int,
      streakDay: json['streakDay'] as int,
      sentAt: DateTime.parse(json['sentAt'] as String),
      partnerResponse: json['partnerResponse'] as String?,
    );
  }
}

class AccountabilityStats {
  final int totalPartners;
  final int activePartners;
  final int longestStreak;
  final int totalCheckIns;
  final int totalProofsShared;
  final double averageMood;

  const AccountabilityStats({
    required this.totalPartners,
    required this.activePartners,
    required this.longestStreak,
    required this.totalCheckIns,
    required this.totalProofsShared,
    required this.averageMood,
  });

  AccountabilityStats copyWith({
    int? totalPartners,
    int? activePartners,
    int? longestStreak,
    int? totalCheckIns,
    int? totalProofsShared,
    double? averageMood,
  }) {
    return AccountabilityStats(
      totalPartners: totalPartners ?? this.totalPartners,
      activePartners: activePartners ?? this.activePartners,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      totalProofsShared: totalProofsShared ?? this.totalProofsShared,
      averageMood: averageMood ?? this.averageMood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPartners': totalPartners,
      'activePartners': activePartners,
      'longestStreak': longestStreak,
      'totalCheckIns': totalCheckIns,
      'totalProofsShared': totalProofsShared,
      'averageMood': averageMood,
    };
  }

  factory AccountabilityStats.fromJson(Map<String, dynamic> json) {
    return AccountabilityStats(
      totalPartners: json['totalPartners'] as int,
      activePartners: json['activePartners'] as int,
      longestStreak: json['longestStreak'] as int,
      totalCheckIns: json['totalCheckIns'] as int,
      totalProofsShared: json['totalProofsShared'] as int,
      averageMood: (json['averageMood'] as num).toDouble(),
    );
  }
}

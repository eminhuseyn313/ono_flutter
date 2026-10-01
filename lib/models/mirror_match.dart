/// Mirror Match — find users with similar starting scores and see their
/// anonymous transformation trajectory as proof that growth is real.

class MirrorMatchStatus {
  const MirrorMatchStatus._();

  static const String searching = 'searching';
  static const String matched = 'matched';
  static const String expired = 'expired';
}

/// A single data-point on a user's transformation trajectory.
class TrajectoryPoint {
  final int dayNumber;
  final double mindScore;
  final double bodyScore;
  final double socialScore;
  final double skillScore;

  const TrajectoryPoint({
    required this.dayNumber,
    required this.mindScore,
    required this.bodyScore,
    required this.socialScore,
    required this.skillScore,
  });

  double get overallScore =>
      (mindScore + bodyScore + socialScore + skillScore) / 4;

  TrajectoryPoint copyWith({
    int? dayNumber,
    double? mindScore,
    double? bodyScore,
    double? socialScore,
    double? skillScore,
  }) =>
      TrajectoryPoint(
        dayNumber: dayNumber ?? this.dayNumber,
        mindScore: mindScore ?? this.mindScore,
        bodyScore: bodyScore ?? this.bodyScore,
        socialScore: socialScore ?? this.socialScore,
        skillScore: skillScore ?? this.skillScore,
      );

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'mindScore': mindScore,
        'bodyScore': bodyScore,
        'socialScore': socialScore,
        'skillScore': skillScore,
      };

  factory TrajectoryPoint.fromJson(Map<String, dynamic> json) =>
      TrajectoryPoint(
        dayNumber: json['dayNumber'] as int,
        mindScore: (json['mindScore'] as num).toDouble(),
        bodyScore: (json['bodyScore'] as num).toDouble(),
        socialScore: (json['socialScore'] as num).toDouble(),
        skillScore: (json['skillScore'] as num).toDouble(),
      );
}

/// An anonymous mirror — someone who started near your scores and is now
/// further along the journey.
class MirrorProfile {
  final String id;
  final String alias; // e.g. "Shadow Walker #47"
  final String emoji; // avatar emoji
  final int daysAhead; // how many days ahead of you
  final double similarityScore; // 0–1, how close your starts were
  final List<TrajectoryPoint> trajectory;
  final String strongestLane; // mind / body / social / skill
  final int currentStreak;
  final int legacyScore;

  const MirrorProfile({
    required this.id,
    required this.alias,
    required this.emoji,
    required this.daysAhead,
    required this.similarityScore,
    required this.trajectory,
    required this.strongestLane,
    required this.currentStreak,
    required this.legacyScore,
  });

  /// Latest overall score from the trajectory.
  double get currentOverall =>
      trajectory.isNotEmpty ? trajectory.last.overallScore : 0;

  /// Growth from first to last trajectory point.
  double get totalGrowth {
    if (trajectory.length < 2) return 0;
    return trajectory.last.overallScore - trajectory.first.overallScore;
  }

  MirrorProfile copyWith({
    String? id,
    String? alias,
    String? emoji,
    int? daysAhead,
    double? similarityScore,
    List<TrajectoryPoint>? trajectory,
    String? strongestLane,
    int? currentStreak,
    int? legacyScore,
  }) =>
      MirrorProfile(
        id: id ?? this.id,
        alias: alias ?? this.alias,
        emoji: emoji ?? this.emoji,
        daysAhead: daysAhead ?? this.daysAhead,
        similarityScore: similarityScore ?? this.similarityScore,
        trajectory: trajectory ?? this.trajectory,
        strongestLane: strongestLane ?? this.strongestLane,
        currentStreak: currentStreak ?? this.currentStreak,
        legacyScore: legacyScore ?? this.legacyScore,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'emoji': emoji,
        'daysAhead': daysAhead,
        'similarityScore': similarityScore,
        'trajectory': trajectory.map((t) => t.toJson()).toList(),
        'strongestLane': strongestLane,
        'currentStreak': currentStreak,
        'legacyScore': legacyScore,
      };

  factory MirrorProfile.fromJson(Map<String, dynamic> json) => MirrorProfile(
        id: json['id'] as String,
        alias: json['alias'] as String,
        emoji: json['emoji'] as String,
        daysAhead: json['daysAhead'] as int,
        similarityScore: (json['similarityScore'] as num).toDouble(),
        trajectory: (json['trajectory'] as List)
            .map((e) => TrajectoryPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        strongestLane: json['strongestLane'] as String,
        currentStreak: json['currentStreak'] as int,
        legacyScore: json['legacyScore'] as int,
      );
}

/// A message in the anonymous 1:1 encouragement chat.
class MirrorMessage {
  final String id;
  final String senderId; // mirror profile id or 'me'
  final String text;
  final DateTime sentAt;

  const MirrorMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  bool get isMe => senderId == 'me';

  MirrorMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? sentAt,
  }) =>
      MirrorMessage(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        text: text ?? this.text,
        sentAt: sentAt ?? this.sentAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory MirrorMessage.fromJson(Map<String, dynamic> json) => MirrorMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}

/// The full mirror-match state for the current user.
class MirrorMatchData {
  final String status; // searching / matched / expired
  final MirrorProfile? mirror;
  final List<TrajectoryPoint> myTrajectory;
  final List<MirrorMessage> messages;
  final bool chatUnlocked; // unlocked after 7+ days matched

  const MirrorMatchData({
    required this.status,
    this.mirror,
    required this.myTrajectory,
    required this.messages,
    required this.chatUnlocked,
  });

  MirrorMatchData copyWith({
    String? status,
    MirrorProfile? mirror,
    List<TrajectoryPoint>? myTrajectory,
    List<MirrorMessage>? messages,
    bool? chatUnlocked,
  }) =>
      MirrorMatchData(
        status: status ?? this.status,
        mirror: mirror ?? this.mirror,
        myTrajectory: myTrajectory ?? this.myTrajectory,
        messages: messages ?? this.messages,
        chatUnlocked: chatUnlocked ?? this.chatUnlocked,
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'mirror': mirror?.toJson(),
        'myTrajectory': myTrajectory.map((t) => t.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'chatUnlocked': chatUnlocked,
      };

  factory MirrorMatchData.fromJson(Map<String, dynamic> json) =>
      MirrorMatchData(
        status: json['status'] as String,
        mirror: json['mirror'] != null
            ? MirrorProfile.fromJson(json['mirror'] as Map<String, dynamic>)
            : null,
        myTrajectory: (json['myTrajectory'] as List)
            .map((e) => TrajectoryPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        messages: (json['messages'] as List)
            .map((e) => MirrorMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        chatUnlocked: json['chatUnlocked'] as bool,
      );
}

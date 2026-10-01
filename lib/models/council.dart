import 'dart:convert';

// ─── ENUMS ──────────────────────────────────────────────────────────────────

enum CouncilTone {
  toughLove,
  philosophical,
  practical,
  scientific,
  motivational;

  String get label {
    switch (this) {
      case CouncilTone.toughLove:
        return 'Tough Love';
      case CouncilTone.philosophical:
        return 'Philosophical';
      case CouncilTone.practical:
        return 'Practical';
      case CouncilTone.scientific:
        return 'Scientific';
      case CouncilTone.motivational:
        return 'Motivational';
    }
  }

  String toJson() => name;

  static CouncilTone fromJson(String json) =>
      CouncilTone.values.firstWhere((e) => e.name == json);
}

// ─── COUNCIL MEMBER ─────────────────────────────────────────────────────────

class CouncilMember {
  final String roleModelId;
  final String name;
  final String title;
  final String philosophy;
  final String avatarEmoji;

  const CouncilMember({
    required this.roleModelId,
    required this.name,
    required this.title,
    required this.philosophy,
    required this.avatarEmoji,
  });

  CouncilMember copyWith({
    String? roleModelId,
    String? name,
    String? title,
    String? philosophy,
    String? avatarEmoji,
  }) {
    return CouncilMember(
      roleModelId: roleModelId ?? this.roleModelId,
      name: name ?? this.name,
      title: title ?? this.title,
      philosophy: philosophy ?? this.philosophy,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, dynamic> toJson() => {
        'roleModelId': roleModelId,
        'name': name,
        'title': title,
        'philosophy': philosophy,
        'avatarEmoji': avatarEmoji,
      };

  factory CouncilMember.fromJson(Map<String, dynamic> json) => CouncilMember(
        roleModelId: json['roleModelId'] as String,
        name: json['name'] as String,
        title: json['title'] as String,
        philosophy: json['philosophy'] as String,
        avatarEmoji: json['avatarEmoji'] as String,
      );

  /// All 10 council members pre-defined.
  static const List<CouncilMember> all = [
    CouncilMember(
      roleModelId: 'kobe',
      name: 'Kobe Bryant',
      title: 'The Mamba',
      philosophy:
          'Obsessive preparation and relentless work ethic separate greatness from talent.',
      avatarEmoji: '🐍',
    ),
    CouncilMember(
      roleModelId: 'goggins',
      name: 'David Goggins',
      title: 'The Hardest Man Alive',
      philosophy:
          'When your mind says you\'re done, you\'re only at 40% of your capacity.',
      avatarEmoji: '🔥',
    ),
    CouncilMember(
      roleModelId: 'aurelius',
      name: 'Marcus Aurelius',
      title: 'The Philosopher King',
      philosophy:
          'Control what you can, accept what you can\'t, and find virtue in every challenge.',
      avatarEmoji: '🏛',
    ),
    CouncilMember(
      roleModelId: 'naval',
      name: 'Naval Ravikant',
      title: 'The Angel Philosopher',
      philosophy:
          'Seek wealth through leverage and specific knowledge, not trading time for money.',
      avatarEmoji: '🧭',
    ),
    CouncilMember(
      roleModelId: 'huberman',
      name: 'Andrew Huberman',
      title: 'The Neuroscientist',
      philosophy:
          'Optimize your biology through science-backed protocols for peak performance.',
      avatarEmoji: '🧬',
    ),
    CouncilMember(
      roleModelId: 'hormozi',
      name: 'Alex Hormozi',
      title: 'The \$100M Entrepreneur',
      philosophy:
          'Volume negates luck. Do more, learn faster, and make irresistible offers.',
      avatarEmoji: '💰',
    ),
    CouncilMember(
      roleModelId: 'cr7',
      name: 'Cristiano Ronaldo',
      title: 'The GOAT Machine',
      philosophy:
          'Talent means nothing without discipline. Outwork everyone, every single day.',
      avatarEmoji: '⚽',
    ),
    CouncilMember(
      roleModelId: 'bruce_lee',
      name: 'Bruce Lee',
      title: 'The Dragon',
      philosophy:
          'Be water. Absorb what is useful, discard what is useless, add what is uniquely your own.',
      avatarEmoji: '🐉',
    ),
    CouncilMember(
      roleModelId: 'arnold',
      name: 'Arnold Schwarzenegger',
      title: 'The Austrian Oak',
      philosophy:
          'Visualize your goal so clearly that the work becomes inevitable.',
      avatarEmoji: '💪',
    ),
    CouncilMember(
      roleModelId: 'jocko',
      name: 'Jocko Willink',
      title: 'The Discipline Commander',
      philosophy:
          'Discipline equals freedom. Extreme ownership of every outcome in your life.',
      avatarEmoji: '🎖',
    ),
  ];

  static CouncilMember? findById(String id) {
    try {
      return all.firstWhere((m) => m.roleModelId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouncilMember && roleModelId == other.roleModelId;

  @override
  int get hashCode => roleModelId.hashCode;
}

// ─── COUNCIL RESPONSE ───────────────────────────────────────────────────────

class CouncilResponse {
  final String memberId;
  final String memberName;
  final String advice;
  final CouncilTone tone;

  const CouncilResponse({
    required this.memberId,
    required this.memberName,
    required this.advice,
    required this.tone,
  });

  CouncilResponse copyWith({
    String? memberId,
    String? memberName,
    String? advice,
    CouncilTone? tone,
  }) {
    return CouncilResponse(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      advice: advice ?? this.advice,
      tone: tone ?? this.tone,
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'advice': advice,
        'tone': tone.toJson(),
      };

  factory CouncilResponse.fromJson(Map<String, dynamic> json) =>
      CouncilResponse(
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        advice: json['advice'] as String,
        tone: CouncilTone.fromJson(json['tone'] as String),
      );
}

// ─── COUNCIL SESSION ────────────────────────────────────────────────────────

class CouncilSession {
  final String id;
  final String question;
  final List<CouncilResponse> responses;
  final DateTime createdAt;
  final bool isFavorited;

  const CouncilSession({
    required this.id,
    required this.question,
    required this.responses,
    required this.createdAt,
    this.isFavorited = false,
  });

  CouncilSession copyWith({
    String? id,
    String? question,
    List<CouncilResponse>? responses,
    DateTime? createdAt,
    bool? isFavorited,
  }) {
    return CouncilSession(
      id: id ?? this.id,
      question: question ?? this.question,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'responses': responses.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isFavorited': isFavorited,
      };

  factory CouncilSession.fromJson(Map<String, dynamic> json) => CouncilSession(
        id: json['id'] as String,
        question: json['question'] as String,
        responses: (json['responses'] as List)
            .map((r) => CouncilResponse.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isFavorited: json['isFavorited'] as bool? ?? false,
      );
}

// ─── COUNCIL QUOTA ──────────────────────────────────────────────────────────

class CouncilQuota {
  final int questionsToday;
  final int maxPerDay;
  final DateTime resetAt;

  const CouncilQuota({
    required this.questionsToday,
    this.maxPerDay = 3,
    required this.resetAt,
  });

  int get remaining => (maxPerDay - questionsToday).clamp(0, maxPerDay);
  bool get canAsk => remaining > 0;

  CouncilQuota copyWith({
    int? questionsToday,
    int? maxPerDay,
    DateTime? resetAt,
  }) {
    return CouncilQuota(
      questionsToday: questionsToday ?? this.questionsToday,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      resetAt: resetAt ?? this.resetAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionsToday': questionsToday,
        'maxPerDay': maxPerDay,
        'resetAt': resetAt.toIso8601String(),
      };

  factory CouncilQuota.fromJson(Map<String, dynamic> json) => CouncilQuota(
        questionsToday: json['questionsToday'] as int,
        maxPerDay: json['maxPerDay'] as int? ?? 3,
        resetAt: DateTime.parse(json['resetAt'] as String),
      );
}

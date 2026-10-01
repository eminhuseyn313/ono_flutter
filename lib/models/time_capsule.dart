import 'dart:convert';

class TimeCapsule {
  final String id;
  final String userId;
  final String message;
  final String? lane;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool isOpened;
  final DateTime? openedAt;
  final String? mood;

  const TimeCapsule({
    required this.id,
    required this.userId,
    required this.message,
    this.lane,
    required this.createdAt,
    required this.unlockAt,
    this.isOpened = false,
    this.openedAt,
    this.mood,
  });

  bool get isUnlocked => DateTime.now().isAfter(unlockAt);

  Duration get timeRemaining {
    final remaining = unlockAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get progress {
    final totalDuration = unlockAt.difference(createdAt).inSeconds;
    if (totalDuration <= 0) return 1.0;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  TimeCapsule copyWith({
    String? id,
    String? userId,
    String? message,
    String? lane,
    DateTime? createdAt,
    DateTime? unlockAt,
    bool? isOpened,
    DateTime? openedAt,
    String? mood,
  }) {
    return TimeCapsule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      lane: lane ?? this.lane,
      createdAt: createdAt ?? this.createdAt,
      unlockAt: unlockAt ?? this.unlockAt,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'lane': lane,
      'createdAt': createdAt.toIso8601String(),
      'unlockAt': unlockAt.toIso8601String(),
      'isOpened': isOpened,
      'openedAt': openedAt?.toIso8601String(),
      'mood': mood,
    };
  }

  factory TimeCapsule.fromJson(Map<String, dynamic> json) {
    return TimeCapsule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      message: json['message'] as String,
      lane: json['lane'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      unlockAt: DateTime.parse(json['unlockAt'] as String),
      isOpened: json['isOpened'] as bool? ?? false,
      openedAt: json['openedAt'] != null
          ? DateTime.parse(json['openedAt'] as String)
          : null,
      mood: json['mood'] as String?,
    );
  }

  @override
  String toString() {
    return 'TimeCapsule(id: $id, mood: $mood, isOpened: $isOpened, '
        'isUnlocked: $isUnlocked, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeCapsule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

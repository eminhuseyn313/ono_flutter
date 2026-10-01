/// Notification types supported by ONO's motivation engine.
enum NotificationType {
  streakRisk,
  roleModel,
  socialProof,
  milestone,
  reminder,
}

extension NotificationTypeX on NotificationType {
  String get storageKey {
    switch (this) {
      case NotificationType.streakRisk:
        return 'streakRisk';
      case NotificationType.roleModel:
        return 'roleModel';
      case NotificationType.socialProof:
        return 'socialProof';
      case NotificationType.milestone:
        return 'milestone';
      case NotificationType.reminder:
        return 'reminder';
    }
  }

  static NotificationType fromStorageKey(String key) {
    switch (key) {
      case 'streakRisk':
        return NotificationType.streakRisk;
      case 'roleModel':
        return NotificationType.roleModel;
      case 'socialProof':
        return NotificationType.socialProof;
      case 'milestone':
        return NotificationType.milestone;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.reminder;
    }
  }

  /// Emoji used as a fallback icon glyph when no explicit icon is set.
  String get emoji {
    switch (this) {
      case NotificationType.streakRisk:
        return '🔥';
      case NotificationType.roleModel:
        return '🧭';
      case NotificationType.socialProof:
        return '⚡';
      case NotificationType.milestone:
        return '🏆';
      case NotificationType.reminder:
        return '⏰';
    }
  }

  String get label {
    switch (this) {
      case NotificationType.streakRisk:
        return 'Streak at risk';
      case NotificationType.roleModel:
        return 'Role model';
      case NotificationType.socialProof:
        return 'Social proof';
      case NotificationType.milestone:
        return 'Milestone';
      case NotificationType.reminder:
        return 'Reminder';
    }
  }
}

/// A single motivational notification, either delivered as a system push
/// or surfaced in-app as a banner / feed item.
class OnoNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? lane; // 'mind', 'body', 'social', 'skill'
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;

  const OnoNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.lane,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  OnoNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? lane,
    DateTime? createdAt,
    bool? isRead,
    String? actionRoute,
  }) {
    return OnoNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      lane: lane ?? this.lane,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.storageKey,
      'title': title,
      'body': body,
      'lane': lane,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
    };
  }

  factory OnoNotification.fromJson(Map<String, dynamic> json) {
    return OnoNotification(
      id: json['id'] as String,
      type: NotificationTypeX.fromStorageKey(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      lane: json['lane'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnoNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OnoNotification(id: $id, type: ${type.storageKey}, title: $title, isRead: $isRead)';
}

/// User-configurable preferences that gate which notifications fire.
class NotificationPreferences {
  final bool enabled;
  final bool streakAlerts;
  final bool milestoneAlerts;
  final bool socialProof;
  final bool roleModelAlerts;

  /// Quiet hours, expressed as hour-of-day in 24h time (0-23).
  final int quietHoursStart;
  final int quietHoursEnd;

  /// When true, delivery time is nudged toward the user's usual
  /// app-open window instead of a fixed schedule.
  final bool smartTiming;

  const NotificationPreferences({
    this.enabled = true,
    this.streakAlerts = true,
    this.milestoneAlerts = true,
    this.socialProof = true,
    this.roleModelAlerts = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.smartTiming = true,
  });

  /// Whether the given hour-of-day (0-23) falls inside quiet hours.
  bool isQuietHour(int hour) {
    if (quietHoursStart == quietHoursEnd) return false;
    if (quietHoursStart < quietHoursEnd) {
      return hour >= quietHoursStart && hour < quietHoursEnd;
    }
    // Wraps past midnight, e.g. 22 -> 7.
    return hour >= quietHoursStart || hour < quietHoursEnd;
  }

  bool isEnabledFor(NotificationType type) {
    if (!enabled) return false;
    switch (type) {
      case NotificationType.streakRisk:
        return streakAlerts;
      case NotificationType.milestone:
        return milestoneAlerts;
      case NotificationType.socialProof:
        return socialProof;
      case NotificationType.roleModel:
        return roleModelAlerts;
      case NotificationType.reminder:
        return enabled;
    }
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? streakAlerts,
    bool? milestoneAlerts,
    bool? socialProof,
    bool? roleModelAlerts,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? smartTiming,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      milestoneAlerts: milestoneAlerts ?? this.milestoneAlerts,
      socialProof: socialProof ?? this.socialProof,
      roleModelAlerts: roleModelAlerts ?? this.roleModelAlerts,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      smartTiming: smartTiming ?? this.smartTiming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'streakAlerts': streakAlerts,
      'milestoneAlerts': milestoneAlerts,
      'socialProof': socialProof,
      'roleModelAlerts': roleModelAlerts,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'smartTiming': smartTiming,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? true,
      streakAlerts: json['streakAlerts'] as bool? ?? true,
      milestoneAlerts: json['milestoneAlerts'] as bool? ?? true,
      socialProof: json['socialProof'] as bool? ?? true,
      roleModelAlerts: json['roleModelAlerts'] as bool? ?? true,
      quietHoursStart: json['quietHoursStart'] as int? ?? 22,
      quietHoursEnd: json['quietHoursEnd'] as int? ?? 7,
      smartTiming: json['smartTiming'] as bool? ?? true,
    );
  }
}

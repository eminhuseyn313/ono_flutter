import 'package:flutter/foundation.dart';

enum PlannerItemType {
  action,
  ritual,
  challenge,
  custom,
  breakTime;

  String get label {
    switch (this) {
      case PlannerItemType.action:
        return 'Action';
      case PlannerItemType.ritual:
        return 'Ritual';
      case PlannerItemType.challenge:
        return 'Challenge';
      case PlannerItemType.custom:
        return 'Custom';
      case PlannerItemType.breakTime:
        return 'Break';
    }
  }

  String toJson() => name;

  static PlannerItemType fromJson(String json) {
    return PlannerItemType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PlannerItemType.custom,
    );
  }
}

enum PlannerPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case PlannerPriority.high:
        return 'High';
      case PlannerPriority.medium:
        return 'Medium';
      case PlannerPriority.low:
        return 'Low';
    }
  }

  int get sortOrder {
    switch (this) {
      case PlannerPriority.high:
        return 0;
      case PlannerPriority.medium:
        return 1;
      case PlannerPriority.low:
        return 2;
    }
  }

  String toJson() => name;

  static PlannerPriority fromJson(String json) {
    return PlannerPriority.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PlannerPriority.medium,
    );
  }
}

enum TimeBlock {
  morning,
  afternoon,
  evening,
  night;

  String get label {
    switch (this) {
      case TimeBlock.morning:
        return 'Morning';
      case TimeBlock.afternoon:
        return 'Afternoon';
      case TimeBlock.evening:
        return 'Evening';
      case TimeBlock.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case TimeBlock.morning:
        return '🌅';
      case TimeBlock.afternoon:
        return '☀️';
      case TimeBlock.evening:
        return '🌆';
      case TimeBlock.night:
        return '🌙';
    }
  }

  String get timeRange {
    switch (this) {
      case TimeBlock.morning:
        return '5:00 AM - 12:00 PM';
      case TimeBlock.afternoon:
        return '12:00 PM - 5:00 PM';
      case TimeBlock.evening:
        return '5:00 PM - 9:00 PM';
      case TimeBlock.night:
        return '9:00 PM - 12:00 AM';
    }
  }

  int get startHour {
    switch (this) {
      case TimeBlock.morning:
        return 5;
      case TimeBlock.afternoon:
        return 12;
      case TimeBlock.evening:
        return 17;
      case TimeBlock.night:
        return 21;
    }
  }

  int get endHour {
    switch (this) {
      case TimeBlock.morning:
        return 12;
      case TimeBlock.afternoon:
        return 17;
      case TimeBlock.evening:
        return 21;
      case TimeBlock.night:
        return 24;
    }
  }

  String toJson() => name;

  static TimeBlock fromJson(String json) {
    return TimeBlock.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TimeBlock.morning,
    );
  }

  static TimeBlock fromHour(int hour) {
    if (hour >= 5 && hour < 12) return TimeBlock.morning;
    if (hour >= 12 && hour < 17) return TimeBlock.afternoon;
    if (hour >= 17 && hour < 21) return TimeBlock.evening;
    return TimeBlock.night;
  }
}

enum ChallengeLane {
  mind,
  body,
  soul,
  discipline;

  String get label {
    switch (this) {
      case ChallengeLane.mind:
        return 'Mind';
      case ChallengeLane.body:
        return 'Body';
      case ChallengeLane.soul:
        return 'Soul';
      case ChallengeLane.discipline:
        return 'Discipline';
    }
  }

  int get colorValue {
    switch (this) {
      case ChallengeLane.mind:
        return 0xFF8B5CF6;
      case ChallengeLane.body:
        return 0xFF22D3EE;
      case ChallengeLane.soul:
        return 0xFF34D399;
      case ChallengeLane.discipline:
        return 0xFFF59E0B;
    }
  }

  String toJson() => name;

  static ChallengeLane fromJson(String json) {
    return ChallengeLane.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ChallengeLane.mind,
    );
  }
}

class PlannerItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final PlannerItemType type;
  final PlannerPriority priority;
  final TimeBlock timeBlock;
  final DateTime? scheduledTime;
  final int durationMinutes;
  final bool isCompleted;
  final ChallengeLane? lane;
  final String? linkedId;
  final String notes;

  const PlannerItem({
    required this.id,
    required this.title,
    this.description = '',
    this.emoji = '📋',
    this.type = PlannerItemType.custom,
    this.priority = PlannerPriority.medium,
    this.timeBlock = TimeBlock.morning,
    this.scheduledTime,
    this.durationMinutes = 30,
    this.isCompleted = false,
    this.lane,
    this.linkedId,
    this.notes = '',
  });

  PlannerItem copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    PlannerItemType? type,
    PlannerPriority? priority,
    TimeBlock? timeBlock,
    DateTime? scheduledTime,
    bool clearScheduledTime = false,
    int? durationMinutes,
    bool? isCompleted,
    ChallengeLane? lane,
    bool clearLane = false,
    String? linkedId,
    bool clearLinkedId = false,
    String? notes,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timeBlock: timeBlock ?? this.timeBlock,
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      lane: clearLane ? null : (lane ?? this.lane),
      linkedId: clearLinkedId ? null : (linkedId ?? this.linkedId),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.toJson(),
      'priority': priority.toJson(),
      'timeBlock': timeBlock.toJson(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'lane': lane?.toJson(),
      'linkedId': linkedId,
      'notes': notes,
    };
  }

  factory PlannerItem.fromJson(Map<String, dynamic> json) {
    return PlannerItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📋',
      type: PlannerItemType.fromJson(json['type'] as String),
      priority: PlannerPriority.fromJson(json['priority'] as String),
      timeBlock: TimeBlock.fromJson(json['timeBlock'] as String),
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lane: json['lane'] != null
          ? ChallengeLane.fromJson(json['lane'] as String)
          : null,
      linkedId: json['linkedId'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  String get formattedTime {
    if (scheduledTime == null) return '';
    final hour = scheduledTime!.hour;
    final minute = scheduledTime!.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannerItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DailyPlan {
  final String id;
  final DateTime date;
  final List<PlannerItem> items;
  final String morningIntention;
  final String? eveningReflection;

  const DailyPlan({
    required this.id,
    required this.date,
    this.items = const [],
    this.morningIntention = '',
    this.eveningReflection,
  });

  double get completionRate {
    if (items.isEmpty) return 0.0;
    final completed = items.where((item) => item.isCompleted).length;
    return completed / items.length;
  }

  int get totalMinutes {
    return items.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  int get completedMinutes {
    return items
        .where((item) => item.isCompleted)
        .fold(0, (sum, item) => sum + item.durationMinutes);
  }

  int get completedCount => items.where((item) => item.isCompleted).length;

  List<PlannerItem> itemsForBlock(TimeBlock block) {
    return items.where((item) => item.timeBlock == block).toList();
  }

  DailyPlan copyWith({
    String? id,
    DateTime? date,
    List<PlannerItem>? items,
    String? morningIntention,
    String? eveningReflection,
    bool clearEveningReflection = false,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      morningIntention: morningIntention ?? this.morningIntention,
      eveningReflection: clearEveningReflection
          ? null
          : (eveningReflection ?? this.eveningReflection),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'morningIntention': morningIntention,
      'eveningReflection': eveningReflection,
    };
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => PlannerItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      morningIntention: json['morningIntention'] as String? ?? '',
      eveningReflection: json['eveningReflection'] as String?,
    );
  }
}

class PlannerTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<PlannerItem> items;
  final bool isDefault;

  const PlannerTemplate({
    required this.id,
    required this.name,
    this.emoji = '📋',
    this.description = '',
    this.items = const [],
    this.isDefault = false,
  });

  PlannerTemplate copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    List<PlannerItem>? items,
    bool? isDefault,
  }) {
    return PlannerTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      items: items ?? this.items,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'isDefault': isDefault,
    };
  }

  factory PlannerTemplate.fromJson(Map<String, dynamic> json) {
    return PlannerTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📋',
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => PlannerItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class PlannerStats {
  final double averageCompletionRate;
  final int totalPlannedDays;
  final int currentPlanStreak;
  final int bestPlanStreak;
  final TimeBlock mostProductiveBlock;
  final double averageItemsPerDay;

  const PlannerStats({
    this.averageCompletionRate = 0.0,
    this.totalPlannedDays = 0,
    this.currentPlanStreak = 0,
    this.bestPlanStreak = 0,
    this.mostProductiveBlock = TimeBlock.morning,
    this.averageItemsPerDay = 0.0,
  });

  String get formattedCompletionRate =>
      '${(averageCompletionRate * 100).round()}%';

  String get formattedAverageItems => averageItemsPerDay.toStringAsFixed(1);

  PlannerStats copyWith({
    double? averageCompletionRate,
    int? totalPlannedDays,
    int? currentPlanStreak,
    int? bestPlanStreak,
    TimeBlock? mostProductiveBlock,
    double? averageItemsPerDay,
  }) {
    return PlannerStats(
      averageCompletionRate: averageCompletionRate ?? this.averageCompletionRate,
      totalPlannedDays: totalPlannedDays ?? this.totalPlannedDays,
      currentPlanStreak: currentPlanStreak ?? this.currentPlanStreak,
      bestPlanStreak: bestPlanStreak ?? this.bestPlanStreak,
      mostProductiveBlock: mostProductiveBlock ?? this.mostProductiveBlock,
      averageItemsPerDay: averageItemsPerDay ?? this.averageItemsPerDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageCompletionRate': averageCompletionRate,
      'totalPlannedDays': totalPlannedDays,
      'currentPlanStreak': currentPlanStreak,
      'bestPlanStreak': bestPlanStreak,
      'mostProductiveBlock': mostProductiveBlock.toJson(),
      'averageItemsPerDay': averageItemsPerDay,
    };
  }

  factory PlannerStats.fromJson(Map<String, dynamic> json) {
    return PlannerStats(
      averageCompletionRate:
          (json['averageCompletionRate'] as num?)?.toDouble() ?? 0.0,
      totalPlannedDays: json['totalPlannedDays'] as int? ?? 0,
      currentPlanStreak: json['currentPlanStreak'] as int? ?? 0,
      bestPlanStreak: json['bestPlanStreak'] as int? ?? 0,
      mostProductiveBlock: json['mostProductiveBlock'] != null
          ? TimeBlock.fromJson(json['mostProductiveBlock'] as String)
          : TimeBlock.morning,
      averageItemsPerDay:
          (json['averageItemsPerDay'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Abstraction over reflection persistence.
abstract class ReflectionsGateway {
  /// Load all reflections for a user, newest first.
  Future<List<Reflection>> loadReflections(String userId);

  /// Load reflections for a specific lane.
  Future<List<Reflection>> loadReflectionsByLane(String userId, String lane);

  /// Save a new reflection.
  Future<Reflection> saveReflection(String userId, {
    required String actionId,
    required String actionTitle,
    required String lane,
    required String note,
    required String prompt,
  });

  /// Delete a reflection.
  Future<void> deleteReflection(String userId, String reflectionId);
}

// ---------------------------------------------------------------------------
// Domain model
// ---------------------------------------------------------------------------

class Reflection {
  final String id;
  final String actionId;
  final String actionTitle;
  final String lane;
  final String note;
  final String prompt;
  final DateTime createdAt;

  const Reflection({
    required this.id,
    required this.actionId,
    required this.actionTitle,
    required this.lane,
    required this.note,
    required this.prompt,
    required this.createdAt,
  });

  Reflection copyWith({
    String? id,
    String? actionId,
    String? actionTitle,
    String? lane,
    String? note,
    String? prompt,
    DateTime? createdAt,
  }) {
    return Reflection(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      actionTitle: actionTitle ?? this.actionTitle,
      lane: lane ?? this.lane,
      note: note ?? this.note,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'action_id': actionId,
    'action_title': actionTitle,
    'lane': lane,
    'note': note,
    'prompt': prompt,
    'created_at': createdAt.toIso8601String(),
  };

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    id: json['id'] as String,
    actionId: json['action_id'] as String,
    actionTitle: json['action_title'] as String,
    lane: json['lane'] as String,
    note: json['note'] as String,
    prompt: json['prompt'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

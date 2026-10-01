/// Which role model is attached to which lane, with activation state.
class ApprenticeBinding {
  final String id;
  final String lane; // 'mind', 'body', 'social', 'skill'
  final String roleModelId;
  final String roleModelName;
  final String roleModelEmoji;
  final bool active;
  final DateTime createdAt;

  const ApprenticeBinding({
    required this.id,
    required this.lane,
    required this.roleModelId,
    required this.roleModelName,
    required this.roleModelEmoji,
    required this.active,
    required this.createdAt,
  });

  ApprenticeBinding copyWith({
    String? id,
    String? lane,
    String? roleModelId,
    String? roleModelName,
    String? roleModelEmoji,
    bool? active,
    DateTime? createdAt,
  }) {
    return ApprenticeBinding(
      id: id ?? this.id,
      lane: lane ?? this.lane,
      roleModelId: roleModelId ?? this.roleModelId,
      roleModelName: roleModelName ?? this.roleModelName,
      roleModelEmoji: roleModelEmoji ?? this.roleModelEmoji,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lane': lane,
      'roleModelId': roleModelId,
      'roleModelName': roleModelName,
      'roleModelEmoji': roleModelEmoji,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ApprenticeBinding.fromJson(Map<String, dynamic> json) {
    return ApprenticeBinding(
      id: json['id'] as String,
      lane: json['lane'] as String,
      roleModelId: json['roleModelId'] as String,
      roleModelName: json['roleModelName'] as String,
      roleModelEmoji: json['roleModelEmoji'] as String,
      active: json['active'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprenticeBinding &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          lane == other.lane &&
          roleModelId == other.roleModelId;

  @override
  int get hashCode => Object.hash(id, lane, roleModelId);

  @override
  String toString() =>
      'ApprenticeBinding(lane: $lane, roleModel: $roleModelName $roleModelEmoji, active: $active)';
}

/// A predefined role model option users can choose from.
class RoleModel {
  final String id;
  final String name;
  final String emoji;
  final String lane;

  const RoleModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lane,
  });
}

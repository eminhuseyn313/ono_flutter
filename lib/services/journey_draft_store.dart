import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class JourneyDraftStore {
  JourneyDraftStore._(this._preferences, this._uuid);

  static const _storageKey = 'ono.journey_draft.v1';

  final SharedPreferences _preferences;
  final Uuid _uuid;

  static Future<JourneyDraftStore> create({Uuid uuid = const Uuid()}) async {
    return JourneyDraftStore._(await SharedPreferences.getInstance(), uuid);
  }

  Future<JourneyDraft?> load() async {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null) return null;
    return JourneyDraft.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  Future<JourneyDraft> saveAssessment({
    required Map<String, int> answers,
    required String archetype,
  }) async {
    final current = await load() ?? JourneyDraft.empty();
    final draft = current.copyWith(
      archetype: archetype,
      assessment: AssessmentDraft(
        id: current.assessment?.id ?? _uuid.v4(),
        version: current.assessment?.version ?? 1,
        answers: answers,
      ),
      syncPending: true,
    );
    await _save(draft);
    return draft;
  }

  Future<JourneyDraft> saveBlueprint({
    required List<dynamic> lanes,
    required List<dynamic> milestones,
    required String archetype,
  }) async {
    final current = await load() ?? JourneyDraft.empty();
    final draft = current.copyWith(
      archetype: archetype,
      blueprint: BlueprintDraft(
        id: current.blueprint?.id ?? _uuid.v4(),
        version: current.blueprint?.version ?? 1,
        lanes: lanes,
        milestones: milestones,
      ),
      syncPending: true,
    );
    await _save(draft);
    return draft;
  }

  Future<JourneyDraft> saveActions(List<DailyActionInput> actions) async {
    final current = await load() ?? JourneyDraft.empty();
    final draft = current.copyWith(
      actions: actions
          .map(
            (action) => DailyActionDraft(
              id: action.id ?? _uuid.v4(),
              actionDate: action.actionDate,
              lane: action.lane,
              title: action.title,
              description: action.description,
              completedAt: action.completedAt,
            ),
          )
          .toList(),
      syncPending: true,
    );
    await _save(draft);
    return draft;
  }

  Future<bool> hasPendingSync() async => (await load())?.syncPending ?? false;

  Future<void> clearAfterSync() => _preferences.remove(_storageKey);

  Future<void> _save(JourneyDraft draft) {
    return _preferences.setString(_storageKey, jsonEncode(draft.toJson()));
  }
}

class JourneyDraft {
  const JourneyDraft({
    required this.schemaVersion,
    required this.syncPending,
    this.archetype,
    this.assessment,
    this.blueprint,
    this.actions = const [],
  });

  factory JourneyDraft.empty() => const JourneyDraft(
        schemaVersion: 1,
        syncPending: false,
      );

  factory JourneyDraft.fromJson(Map<String, dynamic> json) {
    return JourneyDraft(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      syncPending: json['syncPending'] as bool? ?? false,
      archetype: json['archetype'] as String?,
      assessment: json['assessment'] == null
          ? null
          : AssessmentDraft.fromJson(json['assessment'] as Map<String, dynamic>),
      blueprint: json['blueprint'] == null
          ? null
          : BlueprintDraft.fromJson(json['blueprint'] as Map<String, dynamic>),
      actions: (json['actions'] as List<dynamic>? ?? const [])
          .map((action) => DailyActionDraft.fromJson(action as Map<String, dynamic>))
          .toList(),
    );
  }

  final int schemaVersion;
  final bool syncPending;
  final String? archetype;
  final AssessmentDraft? assessment;
  final BlueprintDraft? blueprint;
  final List<DailyActionDraft> actions;

  JourneyDraft copyWith({
    bool? syncPending,
    String? archetype,
    AssessmentDraft? assessment,
    BlueprintDraft? blueprint,
    List<DailyActionDraft>? actions,
  }) {
    return JourneyDraft(
      schemaVersion: schemaVersion,
      syncPending: syncPending ?? this.syncPending,
      archetype: archetype ?? this.archetype,
      assessment: assessment ?? this.assessment,
      blueprint: blueprint ?? this.blueprint,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'syncPending': syncPending,
        'archetype': archetype,
        'assessment': assessment?.toJson(),
        'blueprint': blueprint?.toJson(),
        'actions': actions.map((action) => action.toJson()).toList(),
      };
}

class AssessmentDraft {
  const AssessmentDraft({
    required this.id,
    required this.version,
    required this.answers,
  });

  factory AssessmentDraft.fromJson(Map<String, dynamic> json) => AssessmentDraft(
        id: json['id'] as String,
        version: json['version'] as int,
        answers: (json['answers'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as int),
        ),
      );

  final String id;
  final int version;
  final Map<String, int> answers;

  Map<String, dynamic> toJson() => {'id': id, 'version': version, 'answers': answers};
}

class BlueprintDraft {
  const BlueprintDraft({
    required this.id,
    required this.version,
    required this.lanes,
    required this.milestones,
  });

  factory BlueprintDraft.fromJson(Map<String, dynamic> json) => BlueprintDraft(
        id: json['id'] as String,
        version: json['version'] as int,
        lanes: json['lanes'] as List<dynamic>,
        milestones: json['milestones'] as List<dynamic>,
      );

  final String id;
  final int version;
  final List<dynamic> lanes;
  final List<dynamic> milestones;

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'lanes': lanes,
        'milestones': milestones,
      };
}

class DailyActionDraft {
  const DailyActionDraft({
    required this.id,
    required this.actionDate,
    required this.lane,
    required this.title,
    this.description,
    this.completedAt,
  });

  factory DailyActionDraft.fromJson(Map<String, dynamic> json) => DailyActionDraft(
        id: json['id'] as String,
        actionDate: json['action_date'] as String,
        lane: json['lane'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        completedAt: json['completed_at'] as String?,
      );

  final String id;
  final String actionDate;
  final String lane;
  final String title;
  final String? description;
  final String? completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'action_date': actionDate,
        'lane': lane,
        'title': title,
        'description': description,
        'completed_at': completedAt,
      };
}

class DailyActionInput {
  const DailyActionInput({
    required this.actionDate,
    required this.lane,
    required this.title,
    this.id,
    this.description,
    this.completedAt,
  });

  final String? id;
  final String actionDate;
  final String lane;
  final String title;
  final String? description;
  final String? completedAt;
}

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'journey_draft_store.dart';

abstract interface class JourneyGateway {
  Future<void> upsertProfile({
    required String userId,
    required String timezone,
    required String? archetype,
  });

  Future<void> upsertAssessment({
    required String userId,
    required AssessmentDraft assessment,
  });

  Future<void> upsertBlueprint({
    required String userId,
    required BlueprintDraft blueprint,
    required String? assessmentId,
  });

  Future<void> upsertActions({
    required String userId,
    required List<DailyActionDraft> actions,
  });
}

class SyncAdapter {
  SyncAdapter({
    required JourneyDraftStore store,
    required JourneyGateway gateway,
    Future<String> Function()? timezoneResolver,
  })  : _store = store,
        _gateway = gateway,
        _timezoneResolver = timezoneResolver ?? FlutterTimezone.getLocalTimezone;

  final JourneyDraftStore _store;
  final JourneyGateway _gateway;
  final Future<String> Function() _timezoneResolver;
  Future<void>? _activeSync;

  Future<void> syncPendingGuestJourney(String userId) {
    return _activeSync ??= _sync(userId).whenComplete(() => _activeSync = null);
  }

  Future<void> _sync(String userId) async {
    final draft = await _store.load();
    if (draft == null || !draft.syncPending) return;

    String timezone = 'UTC';
    try {
      timezone = await _timezoneResolver();
    } catch (_) {
      // UTC is an intentional safe fallback for platform timezone failures.
    }

    await _gateway.upsertProfile(
      userId: userId,
      timezone: timezone,
      archetype: draft.archetype,
    );
    if (draft.assessment != null) {
      await _gateway.upsertAssessment(userId: userId, assessment: draft.assessment!);
    }
    if (draft.blueprint != null) {
      await _gateway.upsertBlueprint(
        userId: userId,
        blueprint: draft.blueprint!,
        assessmentId: draft.assessment?.id,
      );
    }
    if (draft.actions.isNotEmpty) {
      await _gateway.upsertActions(userId: userId, actions: draft.actions);
    }

    await _store.clearAfterSync();
  }
}

class SupabaseJourneyGateway implements JourneyGateway {
  SupabaseJourneyGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsertProfile({
    required String userId,
    required String timezone,
    required String? archetype,
  }) {
    return _client.from('profiles').upsert({
      'user_id': userId,
      'timezone': timezone,
      'archetype': archetype,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> upsertAssessment({
    required String userId,
    required AssessmentDraft assessment,
  }) {
    return _client.from('assessments').upsert({
      'id': assessment.id,
      'user_id': userId,
      'version': assessment.version,
      'answers': assessment.answers,
    });
  }

  @override
  Future<void> upsertBlueprint({
    required String userId,
    required BlueprintDraft blueprint,
    required String? assessmentId,
  }) {
    return _client.from('blueprints').upsert({
      'id': blueprint.id,
      'user_id': userId,
      'assessment_id': assessmentId,
      'version': blueprint.version,
      'source': 'static',
      'is_active': true,
      'lanes': blueprint.lanes,
      'milestones': blueprint.milestones,
    });
  }

  @override
  Future<void> upsertActions({
    required String userId,
    required List<DailyActionDraft> actions,
  }) {
    return _client.from('daily_actions').upsert(
          actions
              .map(
                (action) => {
                  'id': action.id,
                  'user_id': userId,
                  'action_date': action.actionDate,
                  'lane': action.lane,
                  'title': action.title,
                  'description': action.description,
                  'completed_at': action.completedAt,
                },
              )
              .toList(),
        );
  }
}

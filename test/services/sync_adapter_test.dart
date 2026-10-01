import 'package:flutter_test/flutter_test.dart';
import 'package:ono/services/journey_draft_store.dart';
import 'package:ono/services/sync_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('writes each journey layer before clearing its draft', () async {
    final store = await JourneyDraftStore.create();
    await store.saveAssessment(
      answers: const {'0': 2},
      archetype: 'entrepreneur',
    );
    await store.saveBlueprint(
      lanes: const [],
      milestones: const [],
      archetype: 'entrepreneur',
    );
    await store.saveActions([
      const DailyActionInput(
        actionDate: '2026-08-16',
        lane: 'Career',
        title: 'Engage with 3 LinkedIn posts',
      ),
    ]);
    final gateway = RecordingGateway();
    final adapter = SyncAdapter(
      store: store,
      gateway: gateway,
      timezoneResolver: () async => 'Asia/Baku',
    );

    await adapter.syncPendingGuestJourney('user-id');

    expect(gateway.calls, ['profile', 'assessment', 'blueprint', 'actions']);
    expect(await store.load(), isNull);
  });

  test('retains the draft when an action upsert fails', () async {
    final store = await JourneyDraftStore.create();
    await store.saveActions([
      const DailyActionInput(
        actionDate: '2026-08-16',
        lane: 'Career',
        title: 'Engage with 3 LinkedIn posts',
      ),
    ]);
    final adapter = SyncAdapter(
      store: store,
      gateway: RecordingGateway(failOn: 'actions'),
      timezoneResolver: () async => 'Asia/Baku',
    );

    await expectLater(
      adapter.syncPendingGuestJourney('user-id'),
      throwsA(isA<StateError>()),
    );

    expect(await store.hasPendingSync(), isTrue);
  });
}

class RecordingGateway implements JourneyGateway {
  RecordingGateway({this.failOn});

  final String? failOn;
  final List<String> calls = [];

  void _record(String operation) {
    calls.add(operation);
    if (operation == failOn) throw StateError('Failed $operation');
  }

  @override
  Future<void> upsertActions({required String userId, required List<DailyActionDraft> actions}) async => _record('actions');

  @override
  Future<void> upsertAssessment({required String userId, required AssessmentDraft assessment}) async => _record('assessment');

  @override
  Future<void> upsertBlueprint({required String userId, required BlueprintDraft blueprint, required String? assessmentId}) async => _record('blueprint');

  @override
  Future<void> upsertProfile({required String userId, required String timezone, required String? archetype}) async => _record('profile');
}

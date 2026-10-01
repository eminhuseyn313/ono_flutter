import 'package:flutter_test/flutter_test.dart';
import 'package:ono/services/journey_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists the same assessment id across reloads', () async {
    final store = await JourneyDraftStore.create();

    final saved = await store.saveAssessment(
      answers: const {'0': 2, '1': 3},
      archetype: 'entrepreneur',
    );

    final reloaded = await JourneyDraftStore.create();
    final draft = await reloaded.load();

    expect(draft, isNotNull);
    expect(draft!.assessment!.id, saved.assessment!.id);
    expect(draft.syncPending, isTrue);
  });

  test('retains pending data until sync is acknowledged', () async {
    final store = await JourneyDraftStore.create();
    await store.saveBlueprint(
      lanes: const [],
      milestones: const [],
      archetype: 'athlete',
    );

    expect(await store.hasPendingSync(), isTrue);

    await store.clearAfterSync();

    expect(await store.load(), isNull);
    expect(await store.hasPendingSync(), isFalse);
  });
}

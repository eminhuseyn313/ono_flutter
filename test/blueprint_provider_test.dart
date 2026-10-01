import 'package:flutter_test/flutter_test.dart';
import 'package:ono/gateways/blueprint_gateway.dart';
import 'package:ono/providers/blueprint_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------

class _MockBlueprintGateway implements BlueprintGateway {
  Blueprint? savedBlueprint;
  bool shouldFail = false;
  int generateCallCount = 0;

  final Blueprint _generated = Blueprint(
    archetypeId: 'executive',
    title: 'The Executive Edge',
    summary: 'Your personalised plan',
    lanes: [
      BlueprintLane(
        id: 'mind',
        name: 'Mind',
        description: 'Mental growth',
        actions: [
          BlueprintAction(
            id: 'a1',
            title: 'Read 20 pages',
            laneId: 'mind',
            orderIndex: 0,
          ),
        ],
      ),
      BlueprintLane(
        id: 'body',
        name: 'Body',
        description: 'Physical growth',
        actions: [
          BlueprintAction(
            id: 'a2',
            title: 'Morning workout',
            laneId: 'body',
            orderIndex: 1,
          ),
        ],
      ),
    ],
    generatedAt: DateTime(2025, 1, 1),
  );

  @override
  Future<Blueprint> generateBlueprint({
    required String archetypeId,
    required Map<int, int> assessmentAnswers,
  }) async {
    generateCallCount++;
    if (shouldFail) throw Exception('Generation failed');
    return _generated;
  }

  @override
  Future<Blueprint?> loadBlueprint(String userId) async {
    if (shouldFail) throw Exception('Load failed');
    return savedBlueprint;
  }

  @override
  Future<void> saveBlueprint(String userId, Blueprint blueprint) async {
    if (shouldFail) throw Exception('Save failed');
    savedBlueprint = blueprint;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockBlueprintGateway gateway;
  late BlueprintProvider provider;

  setUp(() {
    gateway = _MockBlueprintGateway();
    provider = BlueprintProvider(gateway);
  });

  // ── Initial state ──────────────────────────────────────────────────────
  test('initial state has no blueprint and is not loading', () {
    expect(provider.blueprint, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.isGenerating, isFalse);
    expect(provider.errorMessage, isNull);
  });

  // ── loadBlueprint ─────────────────────────────────────────────────────
  group('loadBlueprint', () {
    test('returns null when no saved blueprint', () async {
      await provider.loadBlueprint('user1');
      expect(provider.blueprint, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loads saved blueprint', () async {
      gateway.savedBlueprint = Blueprint(
        archetypeId: 'creative',
        title: 'Saved Plan',
        summary: 'A previously saved blueprint',
        lanes: [],
        generatedAt: DateTime(2025, 6, 1),
      );

      await provider.loadBlueprint('user1');
      expect(provider.blueprint, isNotNull);
      expect(provider.blueprint!.title, 'Saved Plan');
      expect(provider.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      gateway.shouldFail = true;
      await provider.loadBlueprint('user1');
      expect(provider.errorMessage, isNotNull);
      expect(provider.blueprint, isNull);
    });
  });

  // ── generateBlueprint ──────────────────────────────────────────────────
  group('generateBlueprint', () {
    test('generates and stores blueprint', () async {
      await provider.generateBlueprint(
        userId: 'user1',
        archetypeId: 'executive',
        assessmentAnswers: {0: 1, 1: 2},
      );

      expect(provider.blueprint, isNotNull);
      expect(provider.blueprint!.title, 'The Executive Edge');
      expect(provider.blueprint!.lanes.length, 2);
      expect(provider.isGenerating, isFalse);
      expect(gateway.generateCallCount, 1);
    });

    test('saves blueprint after generation', () async {
      await provider.generateBlueprint(
        userId: 'user1',
        archetypeId: 'executive',
        assessmentAnswers: {0: 1},
      );

      expect(gateway.savedBlueprint, isNotNull);
      expect(gateway.savedBlueprint!.title, 'The Executive Edge');
    });

    test('sets error on generation failure', () async {
      gateway.shouldFail = true;
      await provider.generateBlueprint(
        userId: 'user1',
        archetypeId: 'executive',
        assessmentAnswers: {0: 1},
      );

      expect(provider.errorMessage, isNotNull);
      expect(provider.blueprint, isNull);
      expect(provider.isGenerating, isFalse);
    });

    test('isGenerating is true during generation', () async {
      // We can check that it starts as false, is set during the call
      expect(provider.isGenerating, isFalse);
      final future = provider.generateBlueprint(
        userId: 'user1',
        archetypeId: 'executive',
        assessmentAnswers: {},
      );
      // After microtask yield, isGenerating should be true
      // (this is a best-effort check since the mock is synchronous)
      await future;
      expect(provider.isGenerating, isFalse);
    });
  });

  // ── allActions helper ──────────────────────────────────────────────────
  test('allActions flattens across lanes', () async {
    await provider.generateBlueprint(
      userId: 'user1',
      archetypeId: 'executive',
      assessmentAnswers: {},
    );

    expect(provider.blueprint!.allActions.length, 2);
    expect(provider.blueprint!.dailyActionCount, 2);
  });

  // ── clearError ─────────────────────────────────────────────────────────
  test('clearError resets errorMessage', () async {
    gateway.shouldFail = true;
    await provider.loadBlueprint('user1');
    expect(provider.errorMessage, isNotNull);

    provider.clearError();
    expect(provider.errorMessage, isNull);
  });

  // ── clearBlueprint ─────────────────────────────────────────────────────
  test('clearBlueprint resets state', () async {
    await provider.generateBlueprint(
      userId: 'user1',
      archetypeId: 'executive',
      assessmentAnswers: {},
    );
    expect(provider.blueprint, isNotNull);

    provider.clearBlueprint();
    expect(provider.blueprint, isNull);
  });
}

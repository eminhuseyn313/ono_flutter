import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/actions_gateway.dart';
import 'package:ono/providers/daily_actions_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockActionsGateway implements ActionsGateway {
  List<DailyAction> actions = [];
  int streak = 0;
  List<DayRecord> history = [];
  int toggleCalls = 0;
  Exception? loadError;
  Exception? toggleError;

  @override
  Future<List<DailyAction>> loadTodayActions(String userId) async {
    if (loadError != null) throw loadError!;
    return List.of(actions);
  }

  @override
  Future<void> toggleAction(
      String userId, String actionId, bool completed) async {
    toggleCalls++;
    if (toggleError != null) throw toggleError!;
    actions = actions.map((a) {
      if (a.id == actionId) return a.copyWith(completed: completed);
      return a;
    }).toList();
  }

  @override
  Future<int> loadStreak(String userId) async => streak;

  @override
  Future<List<DayRecord>> loadHistory(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) async {
    return history;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
List<DailyAction> _sampleActions() => [
      const DailyAction(
        id: 'a1',
        title: '10-min meditation',
        lane: 'mind',
        orderIndex: 0,
      ),
      const DailyAction(
        id: 'a2',
        title: '30-min workout',
        lane: 'body',
        orderIndex: 1,
      ),
      const DailyAction(
        id: 'a3',
        title: 'Read 15 pages',
        lane: 'skill',
        orderIndex: 2,
      ),
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockActionsGateway gateway;
  late DailyActionsProvider provider;

  setUp(() {
    gateway = MockActionsGateway();
    provider = DailyActionsProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('actions list is empty before load', () {
      expect(provider.actions, isEmpty);
      expect(provider.streak, 0);
      expect(provider.completionRate, 0.0);
      expect(provider.isLoading, false);
    });
  });

  // -- Load today ----------------------------------------------------------

  group('loadToday', () {
    test('loads actions and streak', () async {
      gateway.actions = _sampleActions();
      gateway.streak = 5;

      await provider.loadToday('user-1');

      expect(provider.actions.length, 3);
      expect(provider.streak, 5);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('sets isLoading during fetch', () async {
      gateway.actions = _sampleActions();

      bool wasLoading = false;
      provider.addListener(() {
        if (provider.isLoading) wasLoading = true;
      });

      await provider.loadToday('user-1');

      expect(wasLoading, true);
      expect(provider.isLoading, false);
    });

    test('load error → sets error message', () async {
      gateway.loadError = Exception('offline');

      await provider.loadToday('user-1');

      expect(provider.actions, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // -- Toggle action -------------------------------------------------------

  group('toggleAction', () {
    test('marks action complete', () async {
      gateway.actions = _sampleActions();
      await provider.loadToday('user-1');

      await provider.toggleAction('user-1', 'a1', true);

      final action = provider.actions.firstWhere((a) => a.id == 'a1');
      expect(action.completed, true);
      expect(gateway.toggleCalls, 1);
    });

    test('marks action incomplete', () async {
      gateway.actions = [
        const DailyAction(
          id: 'a1',
          title: 'Meditate',
          lane: 'mind',
          completed: true,
        ),
      ];
      await provider.loadToday('user-1');

      await provider.toggleAction('user-1', 'a1', false);

      final action = provider.actions.firstWhere((a) => a.id == 'a1');
      expect(action.completed, false);
    });

    test('toggle error → sets error, reverts local state', () async {
      gateway.actions = _sampleActions();
      await provider.loadToday('user-1');
      gateway.toggleError = Exception('network');

      await provider.toggleAction('user-1', 'a1', true);

      // Should revert to original (not completed)
      final action = provider.actions.firstWhere((a) => a.id == 'a1');
      expect(action.completed, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('notifies listeners on toggle', () async {
      gateway.actions = _sampleActions();
      await provider.loadToday('user-1');

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleAction('user-1', 'a1', true);

      // At least 1 notification (optimistic update)
      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });

  // -- Completion rate -----------------------------------------------------

  group('completionRate', () {
    test('0% when nothing done', () async {
      gateway.actions = _sampleActions();
      await provider.loadToday('user-1');

      expect(provider.completionRate, 0.0);
    });

    test('100% when all done', () async {
      gateway.actions = _sampleActions()
          .map((a) => a.copyWith(completed: true))
          .toList();
      await provider.loadToday('user-1');

      expect(provider.completionRate, 1.0);
    });

    test('partial completion', () async {
      gateway.actions = [
        const DailyAction(
            id: 'a1', title: 'A', lane: 'mind', completed: true),
        const DailyAction(
            id: 'a2', title: 'B', lane: 'body', completed: false),
      ];
      await provider.loadToday('user-1');

      expect(provider.completionRate, 0.5);
    });
  });

  // -- Actions by lane -----------------------------------------------------

  group('actionsByLane', () {
    test('groups actions by their lane', () async {
      gateway.actions = _sampleActions();
      await provider.loadToday('user-1');

      final byLane = provider.actionsByLane;
      expect(byLane['mind']?.length, 1);
      expect(byLane['body']?.length, 1);
      expect(byLane['skill']?.length, 1);
    });
  });

  // -- Load history --------------------------------------------------------

  group('loadHistory', () {
    test('returns day records for date range', () async {
      gateway.history = [
        DayRecord(
            date: DateTime(2026, 1, 1), completedCount: 3, totalCount: 3),
        DayRecord(
            date: DateTime(2026, 1, 2), completedCount: 2, totalCount: 3),
      ];

      final result = await provider.loadHistory(
        'user-1',
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 7),
      );

      expect(result.length, 2);
      expect(result[0].allDone, true);
      expect(result[1].completionRate, closeTo(0.667, 0.01));
    });
  });

  // -- Clear error ---------------------------------------------------------

  group('clearError', () {
    test('clears the error message', () async {
      gateway.loadError = Exception('fail');
      await provider.loadToday('user-1');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });
}

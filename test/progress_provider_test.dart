import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/progress_gateway.dart';
import 'package:ono/providers/progress_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockProgressGateway implements ProgressGateway {
  Map<String, double> scores = {};
  List<WeeklySnapshot> snapshots = [];
  int saveCalls = 0;
  Exception? loadError;
  Exception? saveError;

  @override
  Future<Map<String, double>> loadLaneScores(String userId) async {
    if (loadError != null) throw loadError!;
    return Map.of(scores);
  }

  @override
  Future<List<WeeklySnapshot>> loadWeeklySnapshots(
    String userId, {
    required int weeks,
  }) async {
    return List.of(snapshots);
  }

  @override
  Future<void> saveLaneScores(
      String userId, Map<String, double> scores) async {
    saveCalls++;
    if (saveError != null) throw saveError!;
    this.scores = Map.of(scores);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockProgressGateway gateway;
  late ProgressProvider provider;

  setUp(() {
    gateway = MockProgressGateway();
    provider = ProgressProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('scores are empty before load', () {
      expect(provider.laneScores, isEmpty);
      expect(provider.overallScore, 0.0);
      expect(provider.weeklySnapshots, isEmpty);
      expect(provider.isLoading, false);
    });
  });

  // -- Load progress -------------------------------------------------------

  group('loadProgress', () {
    test('loads lane scores and weekly snapshots', () async {
      gateway.scores = {'mind': 0.7, 'body': 0.5, 'social': 0.3, 'skill': 0.6};
      gateway.snapshots = [
        WeeklySnapshot(
          weekStart: DateTime(2026, 1, 6),
          laneScores: {'mind': 0.6, 'body': 0.4},
          overallScore: 0.5,
          actionsCompleted: 15,
          actionsTotal: 21,
        ),
      ];

      await provider.loadProgress('user-1');

      expect(provider.laneScores.length, 4);
      expect(provider.laneScores['mind'], 0.7);
      expect(provider.weeklySnapshots.length, 1);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('sets isLoading during fetch', () async {
      gateway.scores = {'mind': 0.5};

      bool wasLoading = false;
      provider.addListener(() {
        if (provider.isLoading) wasLoading = true;
      });

      await provider.loadProgress('user-1');

      expect(wasLoading, true);
      expect(provider.isLoading, false);
    });

    test('load error → sets error message', () async {
      gateway.loadError = Exception('timeout');

      await provider.loadProgress('user-1');

      expect(provider.laneScores, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // -- Overall score -------------------------------------------------------

  group('overallScore', () {
    test('averages all lane scores', () async {
      gateway.scores = {
        'mind': 0.8,
        'body': 0.6,
        'social': 0.4,
        'skill': 0.2,
      };

      await provider.loadProgress('user-1');

      expect(provider.overallScore, closeTo(0.5, 0.01));
    });

    test('single lane → score equals that lane', () async {
      gateway.scores = {'mind': 0.75};

      await provider.loadProgress('user-1');

      expect(provider.overallScore, 0.75);
    });
  });

  // -- Strongest / weakest lane --------------------------------------------

  group('lane analysis', () {
    test('identifies strongest and weakest lanes', () async {
      gateway.scores = {
        'mind': 0.9,
        'body': 0.3,
        'social': 0.6,
        'skill': 0.7,
      };

      await provider.loadProgress('user-1');

      expect(provider.strongestLane, 'mind');
      expect(provider.weakestLane, 'body');
    });

    test('null when no scores loaded', () {
      expect(provider.strongestLane, isNull);
      expect(provider.weakestLane, isNull);
    });
  });

  // -- Update lane scores --------------------------------------------------

  group('updateLaneScores', () {
    test('saves and updates local scores', () async {
      gateway.scores = {'mind': 0.5};
      await provider.loadProgress('user-1');

      final newScores = {'mind': 0.7, 'body': 0.4};
      await provider.updateLaneScores('user-1', newScores);

      expect(provider.laneScores['mind'], 0.7);
      expect(provider.laneScores['body'], 0.4);
      expect(gateway.saveCalls, 1);
    });

    test('save error → sets error, keeps old scores', () async {
      gateway.scores = {'mind': 0.5};
      await provider.loadProgress('user-1');
      gateway.saveError = Exception('write failed');

      await provider.updateLaneScores('user-1', {'mind': 0.9});

      expect(provider.laneScores['mind'], 0.5); // reverted
      expect(provider.errorMessage, isNotNull);
    });
  });

  // -- Clear error ---------------------------------------------------------

  group('clearError', () {
    test('clears the error message', () async {
      gateway.loadError = Exception('fail');
      await provider.loadProgress('user-1');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });
}

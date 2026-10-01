import 'dart:math';

import '../models/becoming_arc.dart';
import 'becoming_arc_gateway.dart';

/// In-memory mock implementation of [BecomingArcGateway].
///
/// Seeds one active arc (Kobe's Mamba arc at day 5 with a few steps completed)
/// for `user_1`. All operations simulate 150-250 ms network latency.
class MockBecomingArcGateway implements BecomingArcGateway {
  MockBecomingArcGateway() {
    _seed();
  }

  final _random = Random();

  /// userId → { arcId → UserArcProgress }
  final Map<String, Map<String, UserArcProgress>> _store = {};

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  void _seed() {
    const userId = 'user_1';
    const arc = PrebuiltArcs.kobeArc;

    final progress = UserArcProgress(
      id: 'progress_kobe_user1',
      userId: userId,
      arcId: arc.id,
      currentDay: 5,
      completedSteps: {
        'kobe_id_01': true,
        'kobe_ref_01': true,
        'kobe_hab_01': true,
        'kobe_kn_01': true,
      },
      layerScores: {
        ArcLayer.identity: 0.25,
        ArcLayer.reflection: 0.25,
        ArcLayer.habit: 0.25,
        ArcLayer.knowledge: 0.25,
        ArcLayer.challenge: 0.0,
      },
      startedAt: DateTime.now().subtract(const Duration(days: 4)),
      assessments: [
        SelfAssessment(
          id: 'assess_kobe_d1',
          dayNumber: 1,
          takenAt: DateTime.now().subtract(const Duration(days: 4)),
          scores: {
            ArcLayer.identity: 5,
            ArcLayer.habit: 4,
            ArcLayer.knowledge: 6,
            ArcLayer.challenge: 3,
            ArcLayer.reflection: 5,
          },
        ),
      ],
    );

    _store[userId] = {arc.id: progress};
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Simulates network delay between 150 and 250 ms.
  Future<void> _delay() => Future<void>.delayed(
        Duration(milliseconds: 150 + _random.nextInt(101)),
      );

  /// Returns a unique-ish id for new records.
  String _generateId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';

  // ---------------------------------------------------------------------------
  // BecomingArcGateway implementation
  // ---------------------------------------------------------------------------

  @override
  Future<List<BecomingArc>> loadArcs() async {
    await _delay();
    return List<BecomingArc>.unmodifiable(PrebuiltArcs.all);
  }

  @override
  Future<UserArcProgress?> loadProgress(String userId, String arcId) async {
    await _delay();
    return _store[userId]?[arcId];
  }

  @override
  Future<List<UserArcProgress>> loadAllProgress(String userId) async {
    await _delay();
    final userArcs = _store[userId];
    if (userArcs == null) return const [];
    return List<UserArcProgress>.unmodifiable(userArcs.values);
  }

  @override
  Future<void> saveProgress(String userId, UserArcProgress progress) async {
    await _delay();
    _store.putIfAbsent(userId, () => {});
    _store[userId]![progress.arcId] = progress;
  }

  @override
  Future<void> completeStep(
    String userId,
    String arcId,
    String stepId,
  ) async {
    await _delay();
    final existing = _store[userId]?[arcId];
    if (existing == null) {
      throw StateError(
        'No progress found for user "$userId" on arc "$arcId".',
      );
    }

    final updatedSteps = Map<String, bool>.from(existing.completedSteps);
    updatedSteps[stepId] = true;

    // Recalculate layer scores based on completed steps.
    final arc = PrebuiltArcs.byId[arcId];
    final updatedLayerScores = <ArcLayer, double>{};
    if (arc != null) {
      for (final layer in ArcLayer.values) {
        final layerSteps = arc.stepsForLayer(layer);
        if (layerSteps.isEmpty) continue;
        final completed =
            layerSteps.where((s) => updatedSteps[s.id] == true).length;
        updatedLayerScores[layer] = completed / layerSteps.length;
      }
    }

    _store[userId]![arcId] = existing.copyWith(
      completedSteps: updatedSteps,
      layerScores: updatedLayerScores,
    );
  }

  @override
  Future<void> saveAssessment(
    String userId,
    String arcId,
    SelfAssessment assessment,
  ) async {
    await _delay();
    final existing = _store[userId]?[arcId];
    if (existing == null) {
      throw StateError(
        'No progress found for user "$userId" on arc "$arcId".',
      );
    }

    final updatedAssessments = List<SelfAssessment>.from(existing.assessments)
      ..add(assessment);

    _store[userId]![arcId] = existing.copyWith(
      assessments: updatedAssessments,
    );
  }

  @override
  Future<UserArcProgress> startArc(String userId, String arcId) async {
    await _delay();

    // Guard against duplicate starts.
    if (_store[userId]?[arcId] != null) {
      throw StateError(
        'User "$userId" already has progress for arc "$arcId".',
      );
    }

    final arc = PrebuiltArcs.byId[arcId];
    if (arc == null) {
      throw ArgumentError.value(arcId, 'arcId', 'Unknown arc id.');
    }

    // Build initial completedSteps map (all false).
    final initialSteps = {
      for (final step in arc.steps) step.id: false,
    };

    final progress = UserArcProgress(
      id: _generateId('progress'),
      userId: userId,
      arcId: arcId,
      currentDay: 1,
      completedSteps: initialSteps,
      layerScores: {
        for (final layer in arc.activeLayers) layer: 0.0,
      },
      startedAt: DateTime.now(),
    );

    _store.putIfAbsent(userId, () => {});
    _store[userId]![arcId] = progress;

    return progress;
  }
}

import 'package:flutter/foundation.dart';

import '../gateways/becoming_arc_gateway.dart';
import '../models/becoming_arc.dart';

/// [ChangeNotifier] provider that manages Becoming Arc state.
///
/// Wraps a [BecomingArcGateway] and exposes loaded arcs, active user progress,
/// and convenience helpers. Uses optimistic updates where possible so the UI
/// feels instant while the gateway write completes in the background.
class BecomingArcProvider extends ChangeNotifier {
  BecomingArcProvider({required BecomingArcGateway gateway})
      : _gateway = gateway;

  final BecomingArcGateway _gateway;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<BecomingArc> _arcs = const [];
  Map<String, UserArcProgress> _activeArcs = {};
  bool _isLoading = false;

  /// All available arcs.
  List<BecomingArc> get arcs => List.unmodifiable(_arcs);

  /// Active / completed arc progress keyed by arc id.
  Map<String, UserArcProgress> get activeArcs =>
      Map.unmodifiable(_activeArcs);

  /// Whether any load operation is in progress.
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  /// Fetches all available arcs from the gateway.
  Future<void> loadArcs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _arcs = await _gateway.loadArcs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads every arc progress record for [userId] and indexes them by arc id.
  Future<void> loadUserProgress(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final progressList = await _gateway.loadAllProgress(userId);
      _activeArcs = {
        for (final p in progressList) p.arcId: p,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Starts [arcId] for [userId]. The gateway creates initial progress and
  /// returns it; the local map is updated immediately on receipt.
  Future<void> startArc(String userId, String arcId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final progress = await _gateway.startArc(userId, arcId);
      _activeArcs = Map<String, UserArcProgress>.from(_activeArcs)
        ..[arcId] = progress;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks [stepId] complete within [arcId] for [userId].
  ///
  /// Uses an **optimistic update**: the local completed-steps map and layer
  /// scores are patched immediately so the UI reflects the change before the
  /// gateway round-trip finishes. If the gateway call fails the optimistic
  /// state is rolled back.
  Future<void> completeStep(
    String userId,
    String arcId,
    String stepId,
  ) async {
    final existing = _activeArcs[arcId];
    if (existing == null) return;

    // --- Optimistic local update ---
    final optimisticSteps = Map<String, bool>.from(existing.completedSteps)
      ..[stepId] = true;

    // Recalculate layer scores.
    final arc = getArc(arcId);
    final optimisticLayerScores = Map<ArcLayer, double>.from(
      existing.layerScores,
    );
    if (arc != null) {
      for (final layer in ArcLayer.values) {
        final layerSteps = arc.stepsForLayer(layer);
        if (layerSteps.isEmpty) continue;
        final completed =
            layerSteps.where((s) => optimisticSteps[s.id] == true).length;
        optimisticLayerScores[layer] = completed / layerSteps.length;
      }
    }

    final optimistic = existing.copyWith(
      completedSteps: optimisticSteps,
      layerScores: optimisticLayerScores,
    );

    _activeArcs = Map<String, UserArcProgress>.from(_activeArcs)
      ..[arcId] = optimistic;
    notifyListeners();

    // --- Gateway call (rollback on failure) ---
    try {
      await _gateway.completeStep(userId, arcId, stepId);
    } catch (_) {
      // Roll back to previous state.
      _activeArcs = Map<String, UserArcProgress>.from(_activeArcs)
        ..[arcId] = existing;
      notifyListeners();
      rethrow;
    }
  }

  /// Submits a [SelfAssessment] for [arcId] and [userId].
  ///
  /// Optimistically appends the assessment to the local progress so the UI
  /// can display it immediately.
  Future<void> submitAssessment(
    String userId,
    String arcId,
    SelfAssessment assessment,
  ) async {
    final existing = _activeArcs[arcId];
    if (existing == null) return;

    // --- Optimistic local update ---
    final optimistic = existing.copyWith(
      assessments: [...existing.assessments, assessment],
    );

    _activeArcs = Map<String, UserArcProgress>.from(_activeArcs)
      ..[arcId] = optimistic;
    notifyListeners();

    // --- Gateway call (rollback on failure) ---
    try {
      await _gateway.saveAssessment(userId, arcId, assessment);
    } catch (_) {
      _activeArcs = Map<String, UserArcProgress>.from(_activeArcs)
        ..[arcId] = existing;
      notifyListeners();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the user's progress for [arcId], or `null` if not started.
  UserArcProgress? getProgress(String arcId) => _activeArcs[arcId];

  /// Returns the [BecomingArc] definition for [arcId], or `null` if unknown.
  BecomingArc? getArc(String arcId) {
    for (final arc in _arcs) {
      if (arc.id == arcId) return arc;
    }
    return null;
  }

  /// Computes the completion fraction (0.0-1.0) for a specific [layer]
  /// within [arcId]. Returns 0.0 if no progress exists.
  double getLayerProgress(String arcId, ArcLayer layer) {
    final progress = _activeArcs[arcId];
    if (progress == null) return 0.0;
    return progress.layerProgress(layer);
  }

  /// Whether [stepId] has been completed in [arcId].
  bool isStepCompleted(String arcId, String stepId) {
    final progress = _activeArcs[arcId];
    if (progress == null) return false;
    return progress.completedSteps[stepId] == true;
  }
}

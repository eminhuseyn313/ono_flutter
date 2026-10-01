import 'package:flutter/foundation.dart';

import '../models/adaptive_engine.dart';
import '../gateways/adaptive_engine_gateway.dart';

class AdaptiveEngineProvider extends ChangeNotifier {
  AdaptiveEngineProvider({required AdaptiveEngineGateway gateway})
      : _gateway = gateway;

  final AdaptiveEngineGateway _gateway;

  AdaptiveState? _state;
  bool _loading = false;
  String? _error;

  AdaptiveState? get state => _state;
  bool get loading => _loading;
  String? get error => _error;

  DifficultyLevel get overallLevel =>
      _state?.overallLevel ?? DifficultyLevel.beginner;

  Map<String, DifficultyLevel> get laneLevels =>
      _state?.laneLevels ?? {};

  Map<String, LanePerformance> get lanePerformance =>
      _state?.lanePerformance ?? {};

  List<DifficultyAdjustment> get pendingAdjustments =>
      _state?.pendingAdjustments ?? [];

  List<DifficultyAdjustment> get appliedHistory =>
      _state?.appliedHistory ?? [];

  bool get autoAdjustEnabled => _state?.autoAdjustEnabled ?? true;

  int get lanesNeedingHelp => _state?.lanesNeedingHelp ?? 0;
  int get lanesReadyToAdvance => _state?.lanesReadyToAdvance ?? 0;

  /// Load adaptive state for the active arc.
  Future<void> load(String arcId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _state = await _gateway.loadState(arcId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Apply a pending difficulty adjustment.
  Future<void> applyAdjustment(DifficultyAdjustment adjustment) async {
    if (_state == null) return;

    try {
      await _gateway.applyAdjustment(_state!.arcId, adjustment);

      // Optimistic update
      final updatedLevels = Map<String, DifficultyLevel>.from(_state!.laneLevels);
      updatedLevels[adjustment.lane] = adjustment.recommendedLevel;

      final updatedPending = _state!.pendingAdjustments
          .where((a) => a.lane != adjustment.lane)
          .toList();

      final updatedHistory = [
        adjustment.copyWith(isApplied: true),
        ..._state!.appliedHistory,
      ];

      _state = _state!.copyWith(
        laneLevels: updatedLevels,
        pendingAdjustments: updatedPending,
        appliedHistory: updatedHistory,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Dismiss a pending adjustment without applying.
  void dismissAdjustment(DifficultyAdjustment adjustment) {
    if (_state == null) return;
    final updatedPending = _state!.pendingAdjustments
        .where((a) => a.lane != adjustment.lane)
        .toList();
    _state = _state!.copyWith(pendingAdjustments: updatedPending);
    notifyListeners();
  }

  /// Toggle auto-adjust on/off.
  Future<void> toggleAutoAdjust() async {
    if (_state == null) return;
    final newValue = !_state!.autoAdjustEnabled;

    try {
      await _gateway.setAutoAdjust(_state!.arcId, newValue);
      _state = _state!.copyWith(autoAdjustEnabled: newValue);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Manually set a lane's difficulty level.
  Future<void> setLaneLevel(String lane, DifficultyLevel level) async {
    if (_state == null) return;

    try {
      await _gateway.setLaneLevel(_state!.arcId, lane, level);
      final updatedLevels = Map<String, DifficultyLevel>.from(_state!.laneLevels);
      updatedLevels[lane] = level;
      _state = _state!.copyWith(laneLevels: updatedLevels);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

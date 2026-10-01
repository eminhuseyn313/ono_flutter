import '../models/adaptive_engine.dart';

/// Contract for loading and updating adaptive difficulty state.
abstract class AdaptiveEngineGateway {
  Future<AdaptiveState> loadState(String arcId);
  Future<void> applyAdjustment(String arcId, DifficultyAdjustment adjustment);
  Future<void> setAutoAdjust(String arcId, bool enabled);
  Future<void> setLaneLevel(String arcId, String lane, DifficultyLevel level);
}

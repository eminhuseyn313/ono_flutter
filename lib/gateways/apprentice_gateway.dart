import '../models/apprentice_mode.dart';

/// Abstract gateway for Apprentice Mode data operations.
abstract class ApprenticeGateway {
  /// Load all apprentice bindings for a user.
  Future<List<ApprenticeBinding>> loadBindings(String userId);

  /// Set or update a binding for a specific lane.
  Future<void> setBinding(String userId, ApprenticeBinding binding);

  /// Remove the binding for a specific lane.
  Future<void> removeBinding(String userId, String lane);

  /// Get action suggestions inspired by the role model for a lane.
  Future<List<String>> getApprenticeActions(
    String userId,
    String lane,
    String roleModelId,
  );
}

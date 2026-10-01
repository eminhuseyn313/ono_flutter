import 'package:flutter/foundation.dart';

import '../gateways/apprentice_gateway.dart';
import '../models/apprentice_mode.dart';

/// Provider that manages Apprentice Mode state across all lanes.
class ApprenticeProvider extends ChangeNotifier {
  final ApprenticeGateway _gateway;

  /// Bindings keyed by lane name.
  final Map<String, ApprenticeBinding> _bindings = {};

  /// Cached actions keyed by lane name.
  final Map<String, List<String>> _actionsCache = {};

  bool _loading = false;
  String? _error;

  ApprenticeProvider({required ApprenticeGateway gateway}) : _gateway = gateway;

  /// All current bindings by lane.
  Map<String, ApprenticeBinding> get bindings => Map.unmodifiable(_bindings);

  /// Whether data is currently loading.
  bool get loading => _loading;

  /// Last error message, if any.
  String? get error => _error;

  /// Check if a lane has an active apprentice binding.
  bool isLaneActive(String lane) {
    final binding = _bindings[lane];
    return binding != null && binding.active;
  }

  /// Get the binding for a specific lane, or null.
  ApprenticeBinding? getBinding(String lane) => _bindings[lane];

  /// Get cached actions for a lane.
  List<String> getActions(String lane) => _actionsCache[lane] ?? [];

  /// Load all bindings for a user from the gateway.
  Future<void> loadBindings(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final loaded = await _gateway.loadBindings(userId);
      _bindings.clear();
      for (final binding in loaded) {
        _bindings[binding.lane] = binding;
      }

      // Pre-fetch actions for active bindings.
      for (final binding in loaded) {
        if (binding.active) {
          final actions = await _gateway.getApprenticeActions(
            userId,
            binding.lane,
            binding.roleModelId,
          );
          _actionsCache[binding.lane] = actions;
        }
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Activate apprentice mode for a lane with a chosen role model.
  Future<void> activateApprentice(
    String userId,
    String lane,
    String roleModelId,
    String roleModelName,
    String roleModelEmoji,
  ) async {
    _error = null;

    final binding = ApprenticeBinding(
      id: '${userId}_${lane}_$roleModelId',
      lane: lane,
      roleModelId: roleModelId,
      roleModelName: roleModelName,
      roleModelEmoji: roleModelEmoji,
      active: true,
      createdAt: DateTime.now(),
    );

    try {
      await _gateway.setBinding(userId, binding);
      _bindings[lane] = binding;

      // Fetch actions for the newly activated binding.
      final actions = await _gateway.getApprenticeActions(
        userId,
        lane,
        roleModelId,
      );
      _actionsCache[lane] = actions;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deactivate apprentice mode for a lane (removes the binding).
  Future<void> deactivateApprentice(String userId, String lane) async {
    _error = null;

    try {
      await _gateway.removeBinding(userId, lane);
      _bindings.remove(lane);
      _actionsCache.remove(lane);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

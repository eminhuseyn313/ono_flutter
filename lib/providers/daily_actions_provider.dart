import 'package:flutter/foundation.dart';

import '../gateways/actions_gateway.dart';

class DailyActionsProvider extends ChangeNotifier {
  final ActionsGateway _gateway;

  List<DailyAction> _actions = [];
  int _streak = 0;
  bool _isLoading = false;
  String? _errorMessage;

  DailyActionsProvider({required ActionsGateway gateway}) : _gateway = gateway;

  // -- Public getters -------------------------------------------------------

  List<DailyAction> get actions => List.unmodifiable(_actions);
  int get streak => _streak;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get completionRate {
    if (_actions.isEmpty) return 0.0;
    final done = _actions.where((a) => a.completed).length;
    return done / _actions.length;
  }

  /// Actions grouped by lane (e.g. 'mind', 'body', 'social', 'skill').
  Map<String, List<DailyAction>> get actionsByLane {
    final map = <String, List<DailyAction>>{};
    for (final a in _actions) {
      map.putIfAbsent(a.lane, () => []).add(a);
    }
    return map;
  }

  // -- Load today's data ----------------------------------------------------

  Future<void> loadToday(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _actions = await _gateway.loadTodayActions(userId);
      _streak = await _gateway.loadStreak(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Toggle action completion (optimistic update) -------------------------

  Future<void> toggleAction(
    String userId,
    String actionId,
    bool completed,
  ) async {
    // Optimistic: update local state immediately
    final idx = _actions.indexWhere((a) => a.id == actionId);
    if (idx == -1) return;

    final original = _actions[idx];
    _actions[idx] = original.copyWith(completed: completed);
    notifyListeners();

    try {
      await _gateway.toggleAction(userId, actionId, completed);
      _errorMessage = null;
    } catch (e) {
      // Revert on failure
      _actions[idx] = original;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // -- History (for charts) -------------------------------------------------

  Future<List<DayRecord>> loadHistory(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) {
    return _gateway.loadHistory(userId, from: from, to: to);
  }

  // -- Error management -----------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

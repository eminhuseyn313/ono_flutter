import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gateways/ritual_gateway.dart';
import '../models/ritual.dart';

/// Provider for ritual state — loading, running sessions, and history.
class RitualProvider extends ChangeNotifier {
  final RitualGateway _gateway;

  List<Ritual> _rituals = [];
  RitualSession? _activeSession;
  Ritual? _activeRitual;
  int _currentStepIndex = 0;
  List<RitualSession> _sessionHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  RitualProvider({required RitualGateway gateway}) : _gateway = gateway;

  // -- Public getters ---------------------------------------------------------

  List<Ritual> get rituals => List.unmodifiable(_rituals);
  RitualSession? get activeSession => _activeSession;
  Ritual? get activeRitual => _activeRitual;
  int get currentStepIndex => _currentStepIndex;
  bool get isInProgress => _activeSession != null && _activeRitual != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RitualSession> get sessionHistory =>
      List.unmodifiable(_sessionHistory);

  Ritual? get morningRitual => _rituals
      .cast<Ritual?>()
      .firstWhere((r) => r!.type == RitualType.morning, orElse: () => null);

  Ritual? get eveningRitual => _rituals
      .cast<Ritual?>()
      .firstWhere((r) => r!.type == RitualType.evening, orElse: () => null);

  RitualStep? get currentStep {
    if (_activeRitual == null) return null;
    if (_currentStepIndex >= _activeRitual!.steps.length) return null;
    return _activeRitual!.steps[_currentStepIndex];
  }

  int get totalSteps => _activeRitual?.steps.length ?? 0;

  /// Number of consecutive days with at least one completed session.
  int get streakDays {
    if (_sessionHistory.isEmpty) return 0;

    final now = DateTime.now();
    final dates = <DateTime>{};
    for (final s in _sessionHistory) {
      if (s.completedAt != null) {
        final d = s.completedAt!;
        dates.add(DateTime(d.year, d.month, d.day));
      }
    }

    int streak = 0;
    DateTime check = DateTime(now.year, now.month, now.day);

    // Include today if a session was completed today.
    if (dates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }

    while (dates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // -- Load rituals -----------------------------------------------------------

  Future<void> loadRituals(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rituals = await _gateway.loadRituals(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Session lifecycle ------------------------------------------------------

  Future<void> startRitual(String ritualId) async {
    try {
      final ritual = await _gateway.loadRitual(ritualId);
      if (ritual == null) {
        _errorMessage = 'Ritual not found';
        notifyListeners();
        return;
      }

      final session = await _gateway.startSession(ritualId);
      _activeRitual = ritual;
      _activeSession = session;
      _currentStepIndex = 0;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void advanceStep() {
    if (_activeSession == null || _activeRitual == null) return;

    final step = _activeRitual!.steps[_currentStepIndex];
    final updatedCompleted = [
      ..._activeSession!.stepsCompleted,
      step.id,
    ];

    _activeSession = _activeSession!.copyWith(
      stepsCompleted: updatedCompleted,
    );
    _currentStepIndex++;
    notifyListeners();
  }

  void skipStep() {
    if (_activeSession == null || _activeRitual == null) return;
    _currentStepIndex++;
    notifyListeners();
  }

  Future<void> completeRitual() async {
    if (_activeSession == null) return;

    final now = DateTime.now();
    final duration = now.difference(_activeSession!.startedAt);
    final completed = _activeSession!.copyWith(
      completedAt: now,
      totalDuration: duration,
    );

    try {
      await _gateway.completeSession(completed);
      _sessionHistory = [completed, ..._sessionHistory];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _activeSession = null;
    _activeRitual = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  void cancelRitual() {
    _activeSession = null;
    _activeRitual = null;
    _currentStepIndex = 0;
    notifyListeners();
  }

  // -- Ritual configuration ---------------------------------------------------

  Future<void> updateRitualSteps(
    String ritualId,
    List<RitualStep> steps,
  ) async {
    final idx = _rituals.indexWhere((r) => r.id == ritualId);
    if (idx == -1) return;

    final updated = _rituals[idx].copyWith(steps: steps);

    // Optimistic update
    _rituals[idx] = updated;
    notifyListeners();

    try {
      await _gateway.saveRitual(updated);
      _errorMessage = null;
    } catch (e) {
      // Revert
      _rituals[idx] = _rituals[idx].copyWith(steps: _rituals[idx].steps);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleRitualActive(String ritualId, bool isActive) async {
    final idx = _rituals.indexWhere((r) => r.id == ritualId);
    if (idx == -1) return;

    final updated = _rituals[idx].copyWith(isActive: isActive);
    _rituals[idx] = updated;
    notifyListeners();

    try {
      await _gateway.saveRitual(updated);
    } catch (e) {
      _rituals[idx] = _rituals[idx].copyWith(isActive: !isActive);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePreferredTime(
    String ritualId,
    TimeOfDay time,
  ) async {
    final idx = _rituals.indexWhere((r) => r.id == ritualId);
    if (idx == -1) return;

    final updated = _rituals[idx].copyWith(preferredTime: time);
    _rituals[idx] = updated;
    notifyListeners();

    try {
      await _gateway.saveRitual(updated);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // -- History ----------------------------------------------------------------

  Future<void> loadSessionHistory(String ritualId) async {
    try {
      _sessionHistory = await _gateway.loadSessionHistory(ritualId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // -- Error management -------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

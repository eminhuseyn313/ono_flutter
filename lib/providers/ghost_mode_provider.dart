import 'package:flutter/foundation.dart';

import '../gateways/ghost_mode_gateway.dart';
import '../models/ghost_mode.dart';

/// Manages ghost-mode state: current vs. ghost comparison, history, and the
/// weekly challenge. Follows the same ChangeNotifier + gateway pattern used
/// by [ProgressProvider].
class GhostModeProvider extends ChangeNotifier {
  final GhostModeGateway _gateway;

  GhostComparison? _comparison;
  List<GhostSnapshot> _ghostHistory = [];
  WeeklyGhostChallenge? _weeklyChallenge;
  bool _isLoading = false;
  String? _errorMessage;

  GhostModeProvider({required GhostModeGateway gateway}) : _gateway = gateway;

  // -- Public getters ---------------------------------------------------------

  GhostComparison? get comparison => _comparison;
  List<GhostSnapshot> get ghostHistory => List.unmodifiable(_ghostHistory);
  WeeklyGhostChallenge? get weeklyChallenge => _weeklyChallenge;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Whether the user is currently beating the ghost overall.
  bool get isBeatingGhostOverall => _comparison?.isBeatingGhostOverall ?? false;

  /// Whether the user is beating the ghost in a specific lane.
  bool isBeatingGhostInLane(String lane) {
    return _comparison?.isBeatingGhostInLane(lane) ?? false;
  }

  // -- Load comparison --------------------------------------------------------

  /// Fetches both the current and ghost snapshots, builds a comparison,
  /// and loads the weekly challenge in parallel.
  Future<void> loadComparison() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadCurrentWeekSnapshot(),
        _gateway.loadPreviousWeekSnapshot(),
        _gateway.getWeeklyChallenge(),
      ]);

      final current = results[0] as GhostSnapshot;
      final ghost = results[1] as GhostSnapshot;
      _comparison = GhostComparison(current: current, ghost: ghost);
      _weeklyChallenge = results[2] as WeeklyGhostChallenge;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Refresh snapshots & history --------------------------------------------

  /// Reloads the comparison data and the last [weeks] weeks of history.
  Future<void> refreshSnapshots({int weeks = 4}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadCurrentWeekSnapshot(),
        _gateway.loadPreviousWeekSnapshot(),
        _gateway.loadGhostHistory(weeks),
        _gateway.getWeeklyChallenge(),
      ]);

      final current = results[0] as GhostSnapshot;
      final ghost = results[1] as GhostSnapshot;
      _comparison = GhostComparison(current: current, ghost: ghost);
      _ghostHistory = results[2] as List<GhostSnapshot>;
      _weeklyChallenge = results[3] as WeeklyGhostChallenge;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Weekly challenge -------------------------------------------------------

  /// Starts (or restarts) the weekly ghost challenge.
  Future<void> startWeeklyChallenge() async {
    _isLoading = true;
    notifyListeners();

    try {
      _weeklyChallenge = await _gateway.getWeeklyChallenge();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Marks the weekly challenge as completed via the gateway.
  Future<void> completeWeeklyChallenge() async {
    try {
      _weeklyChallenge = await _gateway.completeWeeklyChallenge();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Error management -------------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

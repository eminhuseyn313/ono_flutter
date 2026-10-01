import 'package:flutter/foundation.dart';

import '../gateways/progress_gateway.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressGateway _gateway;

  Map<String, double> _laneScores = {};
  List<WeeklySnapshot> _weeklySnapshots = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProgressProvider({required ProgressGateway gateway}) : _gateway = gateway;

  // -- Public getters -------------------------------------------------------

  Map<String, double> get laneScores => Map.unmodifiable(_laneScores);
  List<WeeklySnapshot> get weeklySnapshots =>
      List.unmodifiable(_weeklySnapshots);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Average of all lane scores (0.0–1.0).
  double get overallScore {
    if (_laneScores.isEmpty) return 0.0;
    final sum = _laneScores.values.reduce((a, b) => a + b);
    return sum / _laneScores.length;
  }

  /// The lane with the highest score, or null if no data.
  String? get strongestLane {
    if (_laneScores.isEmpty) return null;
    return _laneScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// The lane with the lowest score, or null if no data.
  String? get weakestLane {
    if (_laneScores.isEmpty) return null;
    return _laneScores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  // -- Load progress data ---------------------------------------------------

  Future<void> loadProgress(String userId, {int weeks = 8}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _laneScores = await _gateway.loadLaneScores(userId);
      _weeklySnapshots =
          await _gateway.loadWeeklySnapshots(userId, weeks: weeks);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Update lane scores ---------------------------------------------------

  Future<void> updateLaneScores(
    String userId,
    Map<String, double> newScores,
  ) async {
    final oldScores = Map.of(_laneScores);
    _laneScores = Map.of(newScores);
    notifyListeners();

    try {
      await _gateway.saveLaneScores(userId, newScores);
      _errorMessage = null;
    } catch (e) {
      // Revert on failure
      _laneScores = oldScores;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // -- Error management -----------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

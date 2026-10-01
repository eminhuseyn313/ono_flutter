import 'package:flutter/foundation.dart';
import '../gateways/reflections_gateway.dart';

class ReflectionsProvider extends ChangeNotifier {
  final ReflectionsGateway _gateway;

  List<Reflection> _reflections = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReflectionsProvider({required ReflectionsGateway gateway})
      : _gateway = gateway;

  // -- Public getters ---------------------------------------------------------

  List<Reflection> get reflections => List.unmodifiable(_reflections);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _reflections.length;

  /// Reflections grouped by lane.
  Map<String, List<Reflection>> get byLane {
    final map = <String, List<Reflection>>{};
    for (final r in _reflections) {
      map.putIfAbsent(r.lane, () => []).add(r);
    }
    return map;
  }

  /// Today's reflections only.
  List<Reflection> get todaysReflections {
    final now = DateTime.now();
    return _reflections.where((r) =>
      r.createdAt.year == now.year &&
      r.createdAt.month == now.month &&
      r.createdAt.day == now.day
    ).toList();
  }

  /// Count of reflections for a specific lane.
  int countForLane(String lane) =>
      _reflections.where((r) => r.lane == lane).length;

  // -- Load -------------------------------------------------------------------

  Future<void> loadReflections(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _reflections = await _gateway.loadReflections(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // -- Save -------------------------------------------------------------------

  Future<Reflection?> saveReflection(
    String userId, {
    required String actionId,
    required String actionTitle,
    required String lane,
    required String note,
    required String prompt,
  }) async {
    if (note.trim().isEmpty) return null;

    try {
      final reflection = await _gateway.saveReflection(
        userId,
        actionId: actionId,
        actionTitle: actionTitle,
        lane: lane,
        note: note.trim(),
        prompt: prompt,
      );
      _reflections.insert(0, reflection);
      _errorMessage = null;
      notifyListeners();
      return reflection;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // -- Delete -----------------------------------------------------------------

  Future<void> deleteReflection(String userId, String reflectionId) async {
    final idx = _reflections.indexWhere((r) => r.id == reflectionId);
    if (idx == -1) return;

    final removed = _reflections.removeAt(idx);
    notifyListeners();

    try {
      await _gateway.deleteReflection(userId, reflectionId);
      _errorMessage = null;
    } catch (e) {
      // Revert on failure
      _reflections.insert(idx, removed);
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

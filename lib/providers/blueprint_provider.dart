import 'package:flutter/foundation.dart';
import '../gateways/blueprint_gateway.dart';

/// Manages blueprint generation, loading, and caching.
///
/// Wraps [BlueprintGateway] with reactive state so screens can
/// `context.watch<BlueprintProvider>()` for updates.
class BlueprintProvider extends ChangeNotifier {
  final BlueprintGateway _gateway;

  BlueprintProvider(this._gateway);

  // ── State ──────────────────────────────────────────────────────────────

  Blueprint? _blueprint;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;

  Blueprint? get blueprint => _blueprint;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  // ── Load a previously saved blueprint ──────────────────────────────────

  Future<void> loadBlueprint(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _blueprint = await _gateway.loadBlueprint(userId);
    } catch (e) {
      _errorMessage = e.toString();
      _blueprint = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Generate a new blueprint ───────────────────────────────────────────

  Future<void> generateBlueprint({
    required String userId,
    required String archetypeId,
    required Map<int, int> assessmentAnswers,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bp = await _gateway.generateBlueprint(
        archetypeId: archetypeId,
        assessmentAnswers: assessmentAnswers,
      );

      // Persist so loadBlueprint can retrieve it next session
      await _gateway.saveBlueprint(userId, bp);

      _blueprint = bp;
    } catch (e) {
      _errorMessage = e.toString();
      _blueprint = null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearBlueprint() {
    _blueprint = null;
    notifyListeners();
  }
}

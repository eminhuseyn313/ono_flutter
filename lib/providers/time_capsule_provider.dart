import 'package:flutter/foundation.dart';
import '../models/time_capsule.dart';
import '../gateways/time_capsule_gateway.dart';

class TimeCapsuleProvider extends ChangeNotifier {
  final TimeCapsuleGateway _gateway;

  TimeCapsuleProvider(this._gateway);

  List<TimeCapsule> _capsules = [];
  bool _isLoading = false;
  String? _error;

  List<TimeCapsule> get capsules => List.unmodifiable(_capsules);

  List<TimeCapsule> get locked =>
      _capsules.where((c) => !c.isUnlocked).toList();

  List<TimeCapsule> get unlockedUnopened =>
      _capsules.where((c) => c.isUnlocked && !c.isOpened).toList();

  List<TimeCapsule> get opened =>
      _capsules.where((c) => c.isOpened).toList();

  int get totalCapsules => _capsules.length;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCapsules(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _capsules = await _gateway.loadCapsules(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load capsules: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCapsule(
    String userId, {
    required String message,
    String? lane,
    required DateTime unlockAt,
    String? mood,
  }) async {
    // Validation
    if (message.trim().isEmpty) {
      _error = 'Your letter cannot be empty';
      notifyListeners();
      return false;
    }

    if (message.trim().length > 500) {
      _error = 'Your letter is too long (max 500 characters)';
      notifyListeners();
      return false;
    }

    if (!unlockAt.isAfter(DateTime.now())) {
      _error = 'Unlock date must be in the future';
      notifyListeners();
      return false;
    }

    _error = null;

    try {
      final capsule = await _gateway.createCapsule(
        userId,
        message: message.trim(),
        lane: lane,
        unlockAt: unlockAt,
        mood: mood,
      );
      _capsules.insert(0, capsule);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create capsule: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> openCapsule(String userId, String capsuleId) async {
    final index = _capsules.indexWhere((c) => c.id == capsuleId);
    if (index == -1) {
      _error = 'Capsule not found';
      notifyListeners();
      return false;
    }

    final capsule = _capsules[index];
    if (!capsule.isUnlocked) {
      _error = 'This capsule is still sealed';
      notifyListeners();
      return false;
    }

    if (capsule.isOpened) {
      return true; // Already opened
    }

    try {
      await _gateway.openCapsule(userId, capsuleId);
      _capsules[index] = capsule.copyWith(
        isOpened: true,
        openedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to open capsule: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCapsule(String userId, String capsuleId) async {
    try {
      await _gateway.deleteCapsule(userId, capsuleId);
      _capsules.removeWhere((c) => c.id == capsuleId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete capsule: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

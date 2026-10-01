import 'package:flutter/foundation.dart';

import '../gateways/profile_gateway.dart';
import '../data/emin_system.dart';

class UserProfileProvider extends ChangeNotifier {
  final ProfileGateway _gateway;

  UserProfile? _profile;
  String? _pendingArchetypeId;
  Map<int, int> _pendingAnswers = {};
  String? _errorMessage;

  UserProfileProvider({required ProfileGateway gateway}) : _gateway = gateway;

  // -- Public getters ------------------------------------------------------

  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  bool get isOnboarded => _profile?.onboardingComplete ?? false;

  String? get archetypeId =>
      _profile?.archetypeId ?? _pendingArchetypeId;

  Map<int, int> get assessmentAnswers =>
      _profile?.assessmentAnswers ?? _pendingAnswers;

  // -- Load ----------------------------------------------------------------

  Future<void> loadProfile(String userId) async {
    try {
      _profile = await _gateway.loadProfile(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Onboarding steps (before profile is saved) --------------------------

  void selectArchetype(String archetypeId) {
    _pendingArchetypeId = archetypeId;
    notifyListeners();
  }

  void setAssessmentAnswers(Map<int, int> answers) {
    _pendingAnswers = Map.of(answers);
    notifyListeners();
  }

  // -- Complete onboarding → persist profile --------------------------------

  Future<void> completeOnboarding(String userId) async {
    final archetypeId = _pendingArchetypeId ?? 'executive';
    final newProfile = UserProfile(
      archetypeId: archetypeId,
      // The executive path is Emin's personal program.
      displayName: archetypeId == 'executive' ? EminIdentity.name : null,
      assessmentAnswers: Map.of(_pendingAnswers),
      onboardingComplete: true,
      createdAt: DateTime.now(),
    );

    try {
      await _gateway.saveProfile(userId, newProfile);
      _profile = newProfile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Update profile fields ------------------------------------------------

  Future<void> updateDisplayName(String userId, String name) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(displayName: name);
    try {
      await _gateway.saveProfile(userId, updated);
      _profile = updated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> updateNotificationSettings(
    String userId,
    Map<String, bool> settings,
  ) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(notificationSettings: settings);
    try {
      await _gateway.saveProfile(userId, updated);
      _profile = updated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Delete account -------------------------------------------------------

  Future<void> deleteProfile(String userId) async {
    try {
      await _gateway.deleteProfile(userId);
      _profile = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // -- Error management ----------------------------------------------------

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

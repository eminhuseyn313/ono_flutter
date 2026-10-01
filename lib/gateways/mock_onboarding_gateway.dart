import '../models/onboarding.dart';
import 'onboarding_gateway.dart';

/// Mock implementation of [OnboardingGateway] for development and testing.
///
/// Stores data in-memory with simulated network delays (150-250ms).
class MockOnboardingGateway implements OnboardingGateway {
  OnboardingProfile? _storedProfile;
  bool _isComplete = false;

  /// Simulates a realistic async network delay.
  Future<void> _simulateDelay() async {
    await Future.delayed(
      Duration(milliseconds: 150 + (DateTime.now().millisecond % 100)),
    );
  }

  @override
  Future<void> saveOnboardingProfile(OnboardingProfile profile) async {
    await _simulateDelay();
    _storedProfile = profile;
  }

  @override
  Future<OnboardingProfile?> loadOnboardingProfile() async {
    await _simulateDelay();
    return _storedProfile;
  }

  @override
  Future<void> markOnboardingComplete() async {
    await _simulateDelay();
    _isComplete = true;
    if (_storedProfile != null) {
      _storedProfile = _storedProfile!.copyWith(
        completedSteps: {
          ...OnboardingStep.values,
        },
      );
    }
  }

  /// Test helper: check if onboarding was marked complete.
  bool get isComplete => _isComplete;

  /// Test helper: access the stored profile directly.
  OnboardingProfile? get storedProfile => _storedProfile;

  /// Test helper: reset all stored state.
  void reset() {
    _storedProfile = null;
    _isComplete = false;
  }

  /// Test helper: seed a profile for load testing.
  void seedProfile(OnboardingProfile profile) {
    _storedProfile = profile;
  }
}

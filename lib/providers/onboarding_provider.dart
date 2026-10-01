import 'package:flutter/foundation.dart';

import '../gateways/onboarding_gateway.dart';
import '../models/onboarding.dart';

/// Provider managing the multi-step onboarding flow state.
///
/// Follows the architecture: Model -> Gateway -> Provider -> Screen.
/// Uses [ChangeNotifier] for reactive UI updates.
class OnboardingProvider extends ChangeNotifier {
  final OnboardingGateway gateway;

  OnboardingProvider({required this.gateway}) {
    _initializeDefaults();
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  OnboardingStep _currentStep = OnboardingStep.welcome;
  OnboardingProfile _profile = const OnboardingProfile();
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  OnboardingStep get currentStep => _currentStep;
  OnboardingProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Progress from 0.0 to 1.0 based on current step position.
  double get progress {
    final visibleSteps = OnboardingStep.visibleSteps;
    final currentIndex = visibleSteps.indexOf(_currentStep);
    if (currentIndex < 0) return 1.0;
    return (currentIndex + 1) / visibleSteps.length;
  }

  /// The 0-based page index for the PageView (maps visible steps).
  int get currentPageIndex {
    final idx = OnboardingStep.visibleSteps.indexOf(_currentStep);
    return idx >= 0 ? idx : 0;
  }

  /// Whether the user can proceed from the current step.
  bool get canProceed {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return _profile.name.trim().isNotEmpty;
      case OnboardingStep.laneSelection:
        return _profile.lanePreferences.isNotEmpty;
      case OnboardingStep.goalSetting:
        // Goals are optional — always allow proceeding.
        return true;
      case OnboardingStep.scheduleSetup:
        return _profile.schedule != null &&
            _profile.schedule!.activeDays.isNotEmpty;
      case OnboardingStep.tutorial:
        return true;
      case OnboardingStep.complete:
        return false;
    }
  }

  /// Whether the back button should be visible.
  bool get canGoBack => _currentStep != OnboardingStep.welcome;

  /// Whether this is the last visible step.
  bool get isLastStep => _currentStep == OnboardingStep.tutorial;

  // ---------------------------------------------------------------------------
  // Step Navigation
  // ---------------------------------------------------------------------------

  /// Advance to the next onboarding step.
  void goToNextStep() {
    final visibleSteps = OnboardingStep.visibleSteps;
    final currentIndex = visibleSteps.indexOf(_currentStep);

    if (currentIndex < 0) return;

    // Mark current step as completed.
    _profile = _profile.copyWith(
      completedSteps: {..._profile.completedSteps, _currentStep},
    );

    if (currentIndex < visibleSteps.length - 1) {
      _currentStep = visibleSteps[currentIndex + 1];
    } else {
      _currentStep = OnboardingStep.complete;
    }

    _saveProgress();
    notifyListeners();
  }

  /// Go back to the previous onboarding step.
  void goToPreviousStep() {
    final visibleSteps = OnboardingStep.visibleSteps;
    final currentIndex = visibleSteps.indexOf(_currentStep);

    if (currentIndex > 0) {
      _currentStep = visibleSteps[currentIndex - 1];
      notifyListeners();
    }
  }

  /// Jump to a specific step (used for progress bar taps on completed steps).
  void goToStep(OnboardingStep step) {
    if (_profile.completedSteps.contains(step) ||
        step == _currentStep ||
        step.stepIndex <= _currentStep.stepIndex) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Profile Updates
  // ---------------------------------------------------------------------------

  /// Update the user's display name.
  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
    notifyListeners();
  }

  /// Update the user's motivation selection.
  void updateMotivation(String motivation) {
    _profile = _profile.copyWith(motivation: motivation);
    notifyListeners();
  }

  /// Update the user's age.
  void updateAge(int? age) {
    _profile = _profile.copyWith(age: age, clearAge: age == null);
    notifyListeners();
  }

  /// Set or reorder lane preferences.
  void updateLanePreferences(List<LanePreference> preferences) {
    _profile = _profile.copyWith(lanePreferences: preferences);
    notifyListeners();
  }

  /// Add a goal for a specific lane.
  void addGoal(OnboardingGoal goal) {
    final updatedGoals = [..._profile.goals, goal];
    _profile = _profile.copyWith(goals: updatedGoals);
    notifyListeners();
  }

  /// Remove a goal by its id.
  void removeGoal(String goalId) {
    final updatedGoals =
        _profile.goals.where((g) => g.id != goalId).toList();
    _profile = _profile.copyWith(goals: updatedGoals);
    notifyListeners();
  }

  /// Update an existing goal.
  void updateGoal(OnboardingGoal updatedGoal) {
    final updatedGoals = _profile.goals.map((g) {
      return g.id == updatedGoal.id ? updatedGoal : g;
    }).toList();
    _profile = _profile.copyWith(goals: updatedGoals);
    notifyListeners();
  }

  /// Update the schedule preference.
  void updateSchedule(SchedulePreference schedule) {
    _profile = _profile.copyWith(schedule: schedule);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  /// Mark onboarding as complete and persist all data.
  Future<void> completeOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = _profile.copyWith(
        completedSteps: {...OnboardingStep.values},
      );
      await gateway.saveOnboardingProfile(_profile);
      await gateway.markOnboardingComplete();
      _currentStep = OnboardingStep.complete;
    } catch (e) {
      _errorMessage = 'Failed to save your profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load any previously saved onboarding progress.
  Future<void> loadSavedProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      final saved = await gateway.loadOnboardingProfile();
      if (saved != null) {
        _profile = saved;
        // Resume from the first incomplete step.
        for (final step in OnboardingStep.visibleSteps) {
          if (!saved.completedSteps.contains(step)) {
            _currentStep = step;
            break;
          }
        }
      }
    } catch (e) {
      // Silently continue with defaults on load failure.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _initializeDefaults() {
    // Set default lane preferences in display order.
    final defaultPrefs = OnboardingLanes.defaults
        .asMap()
        .entries
        .map((entry) => LanePreference(
              laneId: entry.value['id'] as String,
              priority: entry.key + 1,
            ))
        .toList();

    _profile = _profile.copyWith(
      lanePreferences: defaultPrefs,
      schedule: const SchedulePreference(),
    );
  }

  /// Persist current progress in the background.
  Future<void> _saveProgress() async {
    try {
      await gateway.saveOnboardingProfile(_profile);
    } catch (_) {
      // Background save — don't block the UI on failure.
    }
  }
}

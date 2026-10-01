import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/profile_gateway.dart';
import 'package:ono/providers/user_profile_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockProfileGateway implements ProfileGateway {
  UserProfile? storedProfile;
  int saveCalls = 0;
  int deleteCalls = 0;
  Exception? loadError;
  Exception? saveError;

  @override
  Future<UserProfile?> loadProfile(String userId) async {
    if (loadError != null) throw loadError!;
    return storedProfile;
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) async {
    saveCalls++;
    if (saveError != null) throw saveError!;
    storedProfile = profile;
  }

  @override
  Future<void> deleteProfile(String userId) async {
    deleteCalls++;
    storedProfile = null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
UserProfile _testProfile({
  String archetypeId = 'executive',
  bool onboardingComplete = true,
}) {
  return UserProfile(
    archetypeId: archetypeId,
    assessmentAnswers: {0: 2, 1: 1, 2: 3},
    onboardingComplete: onboardingComplete,
    createdAt: DateTime(2026, 1, 1),
    displayName: 'Test User',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockProfileGateway gateway;
  late UserProfileProvider provider;

  setUp(() {
    gateway = MockProfileGateway();
    provider = UserProfileProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('profile is null before load', () {
      expect(provider.profile, isNull);
      expect(provider.isOnboarded, false);
      expect(provider.archetypeId, isNull);
    });
  });

  // -- Load profile --------------------------------------------------------

  group('loadProfile', () {
    test('loads existing profile', () async {
      gateway.storedProfile = _testProfile();

      await provider.loadProfile('user-1');

      expect(provider.profile, isNotNull);
      expect(provider.archetypeId, 'executive');
      expect(provider.isOnboarded, true);
    });

    test('no profile exists → stays null, no error', () async {
      gateway.storedProfile = null;

      await provider.loadProfile('user-1');

      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('load error → sets error message', () async {
      gateway.loadError = Exception('DB down');

      await provider.loadProfile('user-1');

      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // -- Select archetype ----------------------------------------------------

  group('selectArchetype', () {
    test('sets archetype before onboarding is complete', () {
      provider.selectArchetype('athlete');

      expect(provider.archetypeId, 'athlete');
    });

    test('changing archetype updates the value', () {
      provider.selectArchetype('athlete');
      provider.selectArchetype('creative');

      expect(provider.archetypeId, 'creative');
    });

    test('notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.selectArchetype('gentleman');

      expect(notifyCount, 1);
    });
  });

  // -- Set assessment answers -----------------------------------------------

  group('setAssessmentAnswers', () {
    test('stores answers', () {
      final answers = {0: 1, 1: 3, 2: 0};
      provider.setAssessmentAnswers(answers);

      expect(provider.assessmentAnswers, answers);
    });
  });

  // -- Complete onboarding -------------------------------------------------

  group('completeOnboarding', () {
    test('creates and saves profile', () async {
      provider.selectArchetype('entrepreneur');
      provider.setAssessmentAnswers({0: 2, 1: 1});

      await provider.completeOnboarding('user-1');

      expect(provider.isOnboarded, true);
      expect(provider.profile, isNotNull);
      expect(provider.profile!.archetypeId, 'entrepreneur');
      expect(provider.profile!.onboardingComplete, true);
      expect(gateway.saveCalls, 1);
    });

    test('save error → sets error, onboarding not marked complete', () async {
      provider.selectArchetype('athlete');
      gateway.saveError = Exception('network down');

      await provider.completeOnboarding('user-1');

      expect(provider.errorMessage, isNotNull);
      expect(provider.isOnboarded, false);
    });
  });

  // -- Update profile ------------------------------------------------------

  group('updateProfile', () {
    test('updates display name', () async {
      gateway.storedProfile = _testProfile();
      await provider.loadProfile('user-1');

      await provider.updateDisplayName('user-1', 'Emin');

      expect(provider.profile!.displayName, 'Emin');
      expect(gateway.saveCalls, 1);
    });
  });

  // -- Clear error ---------------------------------------------------------

  group('clearError', () {
    test('clears the error message', () async {
      gateway.loadError = Exception('fail');
      await provider.loadProfile('user-1');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });
}

import '../models/onboarding.dart';

/// Abstract gateway for onboarding persistence.
///
/// TODO: Implement SupabaseOnboardingGateway for production.
abstract class OnboardingGateway {
  Future<void> saveOnboardingProfile(OnboardingProfile profile);
  Future<OnboardingProfile?> loadOnboardingProfile();
  Future<void> markOnboardingComplete();
}

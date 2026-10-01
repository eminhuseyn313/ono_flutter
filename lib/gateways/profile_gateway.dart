/// Abstraction over user profile persistence (Supabase in production).
abstract class ProfileGateway {
  /// Load the user's saved profile. Returns null if no profile exists yet.
  Future<UserProfile?> loadProfile(String userId);

  /// Save or update the user's profile.
  Future<void> saveProfile(String userId, UserProfile profile);

  /// Delete the user's profile (for account deletion).
  Future<void> deleteProfile(String userId);
}

/// Domain model for the user's profile — independent of Supabase schema.
class UserProfile {
  final String archetypeId;
  final Map<int, int> assessmentAnswers;
  final bool onboardingComplete;
  final DateTime createdAt;
  final String? displayName;
  final Map<String, bool> notificationSettings;

  const UserProfile({
    required this.archetypeId,
    this.assessmentAnswers = const {},
    this.onboardingComplete = false,
    required this.createdAt,
    this.displayName,
    this.notificationSettings = const {'dailyNudge': true},
  });

  UserProfile copyWith({
    String? archetypeId,
    Map<int, int>? assessmentAnswers,
    bool? onboardingComplete,
    DateTime? createdAt,
    String? displayName,
    Map<String, bool>? notificationSettings,
  }) {
    return UserProfile(
      archetypeId: archetypeId ?? this.archetypeId,
      assessmentAnswers: assessmentAnswers ?? this.assessmentAnswers,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }
}

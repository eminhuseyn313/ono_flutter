import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_gateway.dart';

/// Production implementation that stores user profiles in Supabase.
///
/// Expects a `profiles` table with columns:
///   id (uuid, FK to auth.users), archetype_id (text), assessment_answers (jsonb),
///   onboarding_complete (bool), created_at (timestamptz), display_name (text),
///   notification_settings (jsonb)
class SupabaseProfileGateway implements ProfileGateway {
  final SupabaseClient _client;

  SupabaseProfileGateway(this._client);

  @override
  Future<UserProfile?> loadProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return UserProfile(
        archetypeId: data['archetype_id'] as String? ?? '',
        assessmentAnswers: _parseAnswers(data['assessment_answers']),
        onboardingComplete: data['onboarding_complete'] as bool? ?? false,
        createdAt: DateTime.parse(data['created_at'] as String),
        displayName: data['display_name'] as String?,
        notificationSettings: _parseNotifications(data['notification_settings']),
      );
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  @override
  Future<void> saveProfile(String userId, UserProfile profile) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'archetype_id': profile.archetypeId,
        'assessment_answers': profile.assessmentAnswers
            .map((k, v) => MapEntry(k.toString(), v)),
        'onboarding_complete': profile.onboardingComplete,
        'created_at': profile.createdAt.toIso8601String(),
        'display_name': profile.displayName,
        'notification_settings': profile.notificationSettings,
      });
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Map<int, int> _parseAnswers(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(int.parse(k.toString()), v as int));
    }
    return {};
  }

  Map<String, bool> _parseNotifications(dynamic raw) {
    if (raw == null) return {'dailyNudge': true};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v as bool));
    }
    return {'dailyNudge': true};
  }
}

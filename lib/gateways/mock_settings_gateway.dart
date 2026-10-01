import '../models/settings.dart';
import 'settings_gateway.dart';

/// Mock implementation of [SettingsGateway] for development and testing.
///
/// Returns realistic defaults with 150-250ms simulated network delay.
/// TODO: Replace with SupabaseSettingsGateway for production.
class MockSettingsGateway implements SettingsGateway {
  AppSettings _settings = const AppSettings();
  bool _isDeleted = false;

  @override
  Future<AppSettings> loadSettings() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _settings = settings;
  }

  @override
  Future<UserStats> loadUserStats() async {
    await Future.delayed(const Duration(milliseconds: 220));

    final now = DateTime.now();
    final memberSince = now.subtract(const Duration(days: 90));

    return UserStats(
      totalXp: 2340,
      currentLevel: 5,
      levelTitle: 'Warrior',
      streakDays: 14,
      totalActionsCompleted: 87,
      totalJournalEntries: 23,
      totalDaysActive: 45,
      memberSince: memberSince,
      favoriteCategory: 'Mindset',
    );
  }

  @override
  Future<void> exportUserData() async {
    await Future.delayed(const Duration(milliseconds: 250));
    // TODO: Integrate with Supabase storage to generate and return
    // a downloadable JSON/ZIP archive of user data.
  }

  @override
  Future<void> deleteAccount() async {
    if (_isDeleted) {
      throw Exception('Account already deleted');
    }
    await Future.delayed(const Duration(milliseconds: 250));
    _isDeleted = true;
    _settings = const AppSettings();
    // TODO: Integrate with Supabase Auth to permanently delete
    // the user account and all associated data.
  }
}

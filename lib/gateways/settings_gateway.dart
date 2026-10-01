import '../models/settings.dart';

/// Abstract gateway for settings persistence.
/// Implementations: MockSettingsGateway (dev), SupabaseSettingsGateway (prod).
abstract class SettingsGateway {
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<UserStats> loadUserStats();
  Future<void> exportUserData();
  Future<void> deleteAccount();
}

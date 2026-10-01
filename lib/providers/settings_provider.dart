import 'package:flutter/foundation.dart';

import '../gateways/settings_gateway.dart';
import '../models/settings.dart';

/// Provider for app settings and user statistics.
///
/// Manages loading, updating, and persisting [AppSettings],
/// as well as fetching [UserStats] and handling data export / account deletion.
class SettingsProvider extends ChangeNotifier {
  final SettingsGateway _gateway;

  AppSettings _settings = const AppSettings();
  UserStats? _userStats;
  AppInfo _appInfo = const AppInfo(
    version: '1.0.0',
    buildNumber: '42',
    lastSyncAt: null,
  );

  bool _isLoading = false;
  bool _isExporting = false;
  bool _isDeleting = false;
  String? _errorMessage;

  SettingsProvider({required SettingsGateway gateway}) : _gateway = gateway;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  AppSettings get settings => _settings;
  UserStats? get userStats => _userStats;
  AppInfo get appInfo => _appInfo;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  /// Loads both settings and user stats in parallel.
  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadSettings(),
        _gateway.loadUserStats(),
      ]);

      _settings = results[0] as AppSettings;
      _userStats = results[1] as UserStats;
      _appInfo = AppInfo(
        version: '1.0.0',
        buildNumber: '42',
        lastSyncAt: DateTime.now(),
      );
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Update helpers
  // ---------------------------------------------------------------------------

  /// Generic setting update by key name.
  Future<void> updateSetting(String key, dynamic value) async {
    switch (key) {
      case 'themeMode':
        _settings = _settings.copyWith(themeMode: value as String);
        break;
      case 'language':
        _settings = _settings.copyWith(language: value as String);
        break;
      case 'notificationsEnabled':
        _settings = _settings.copyWith(notificationsEnabled: value as bool);
        break;
      case 'dailyReminderTime':
        _settings = _settings.copyWith(dailyReminderTime: value as String);
        break;
      case 'weeklyDigestEnabled':
        _settings = _settings.copyWith(weeklyDigestEnabled: value as bool);
        break;
      case 'soundEnabled':
        _settings = _settings.copyWith(soundEnabled: value as bool);
        break;
      case 'hapticEnabled':
        _settings = _settings.copyWith(hapticEnabled: value as bool);
        break;
      case 'privacyMode':
        _settings = _settings.copyWith(privacyMode: value as bool);
        break;
      case 'analyticsOptIn':
        _settings = _settings.copyWith(analyticsOptIn: value as bool);
        break;
      default:
        debugPrint('SettingsProvider: Unknown setting key "$key"');
        return;
    }

    notifyListeners();
    await _persistSettings();
  }

  /// Toggle notifications master switch.
  Future<void> toggleNotifications() async {
    _settings = _settings.copyWith(
      notificationsEnabled: !_settings.notificationsEnabled,
    );
    notifyListeners();
    await _persistSettings();
  }

  /// Update the daily reminder time (format: "HH:mm").
  Future<void> updateReminderTime(String time) async {
    _settings = _settings.copyWith(dailyReminderTime: time);
    notifyListeners();
    await _persistSettings();
  }

  // ---------------------------------------------------------------------------
  // Data operations
  // ---------------------------------------------------------------------------

  /// Request a data export for the current user.
  Future<bool> exportData() async {
    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _gateway.exportUserData();
      _settings = _settings.copyWith(dataExportRequested: true);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to export data: $e';
      return false;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Permanently delete the user account.
  ///
  /// Returns `true` on success. The caller should navigate to the
  /// login/onboarding screen after a successful deletion.
  Future<bool> confirmDeleteAccount() async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _gateway.deleteAccount();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account: $e';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _persistSettings() async {
    try {
      await _gateway.saveSettings(_settings);
    } catch (e) {
      _errorMessage = 'Failed to save settings: $e';
      notifyListeners();
    }
  }
}

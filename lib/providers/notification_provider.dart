import 'dart:async';

import 'package:flutter/foundation.dart';

import '../gateways/notification_gateway.dart';
import '../models/notification_model.dart';
import '../services/notification_templates.dart';

/// Provider that manages the notification feed, preferences, and
/// smart-timing tracking (learning the user's usual app-open window
/// so contextual notifications land when they're most likely to act).
class NotificationProvider extends ChangeNotifier {
  final NotificationGateway _gateway;

  final List<OnoNotification> _notifications = [];
  NotificationPreferences _preferences = const NotificationPreferences();

  bool _loading = false;
  String? _error;
  int _nextGeneratedId = 1;

  /// Rolling log of app-open hours (0-23), most recent last, capped
  /// to keep the model responsive to recent behavior.
  final List<int> _openHours = [];
  static const int _maxOpenHistory = 30;

  /// True right after a new notification lands, used to trigger a
  /// short pulse animation on badges. Cleared by [clearNewFlag].
  bool _hasNewSinceLastCheck = false;

  NotificationProvider({required NotificationGateway gateway})
      : _gateway = gateway;

  List<OnoNotification> get notifications => List.unmodifiable(_notifications);

  List<OnoNotification> get unread =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationPreferences get preferences => _preferences;

  bool get loading => _loading;

  String? get error => _error;

  bool get hasNewSinceLastCheck => _hasNewSinceLastCheck;

  /// The hour-of-day (0-23) the user most commonly opens the app,
  /// derived from recorded open events. Null until enough data exists.
  int? get usualOpenHour {
    if (_openHours.isEmpty) return null;
    final counts = <int, int>{};
    for (final h in _openHours) {
      counts[h] = (counts[h] ?? 0) + 1;
    }
    int? best;
    int bestCount = 0;
    counts.forEach((hour, count) {
      if (count > bestCount) {
        bestCount = count;
        best = hour;
      }
    });
    return best;
  }

  /// Load notifications and preferences for a user.
  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadNotifications(userId),
        _gateway.loadPreferences(userId),
      ]);

      _notifications
        ..clear()
        ..addAll(results[0] as List<OnoNotification>);
      _preferences = results[1] as NotificationPreferences;

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Record that the user opened the app right now. Feeds the smart
  /// timing model used to decide when future notifications should fire.
  void recordAppOpen([DateTime? at]) {
    final time = at ?? DateTime.now();
    _openHours.add(time.hour);
    if (_openHours.length > _maxOpenHistory) {
      _openHours.removeAt(0);
    }
  }

  /// Whether right now is a good time to deliver a notification, given
  /// quiet hours and (if enabled) the user's smart-timing window.
  bool isGoodTimeToNotify([DateTime? now]) {
    final time = now ?? DateTime.now();
    if (!_preferences.enabled) return false;
    if (_preferences.isQuietHour(time.hour)) return false;

    if (_preferences.smartTiming && usualOpenHour != null) {
      final diff = (time.hour - usualOpenHour!).abs();
      final wrapped = diff > 12 ? 24 - diff : diff;
      return wrapped <= 2;
    }
    return true;
  }

  Future<void> markRead(String userId, String notifId) async {
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      await _gateway.markRead(userId, notifId);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markAllRead(String userId) async {
    if (_notifications.every((n) => n.isRead)) return;

    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    try {
      await _gateway.markAllRead(userId);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> updatePreferences(
    String userId,
    NotificationPreferences prefs,
  ) async {
    final previous = _preferences;
    _preferences = prefs;
    notifyListeners();

    try {
      await _gateway.savePreferences(userId, prefs);
    } catch (e) {
      _preferences = previous;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clears the "new" pulse flag once a widget has shown it.
  void clearNewFlag() {
    if (_hasNewSinceLastCheck) {
      _hasNewSinceLastCheck = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // TEMPLATE ENGINE — generates and injects
  // contextual notifications into the feed.
  // ──────────────────────────────────────────

  String _newId() => 'gen_${DateTime.now().millisecondsSinceEpoch}_${_nextGeneratedId++}';

  Future<OnoNotification?> generateStreakRisk(
    String userId, {
    required int streak,
  }) {
    if (!_preferences.isEnabledFor(NotificationType.streakRisk)) {
      return Future.value(null);
    }
    final notif = NotificationTemplates.streakRisk(id: _newId(), streak: streak);
    return _push(userId, notif);
  }

  Future<OnoNotification?> generateRoleModel(
    String userId, {
    String? lane,
  }) {
    if (!_preferences.isEnabledFor(NotificationType.roleModel)) {
      return Future.value(null);
    }
    final notif = NotificationTemplates.roleModel(id: _newId(), lane: lane);
    return _push(userId, notif);
  }

  Future<OnoNotification?> generateSocialProof(
    String userId, {
    int count = 1247,
    int percent = 10,
  }) {
    if (!_preferences.isEnabledFor(NotificationType.socialProof)) {
      return Future.value(null);
    }
    final notif = NotificationTemplates.socialProof(
      id: _newId(),
      count: count,
      percent: percent,
    );
    return _push(userId, notif);
  }

  Future<OnoNotification?> generateMilestone(
    String userId, {
    String title = 'Iron Will',
    int score = 0,
    String tier = 'Disciplined Operator',
    int streak = 0,
  }) {
    if (!_preferences.isEnabledFor(NotificationType.milestone)) {
      return Future.value(null);
    }
    final notif = NotificationTemplates.milestone(
      id: _newId(),
      title: title,
      score: score,
      tier: tier,
      streak: streak,
    );
    return _push(userId, notif);
  }

  Future<OnoNotification> _push(String userId, OnoNotification notif) async {
    _notifications.insert(0, notif);
    _hasNewSinceLastCheck = true;
    notifyListeners();

    try {
      return await _gateway.addNotification(userId, notif);
    } catch (e) {
      _error = e.toString();
      return notif;
    }
  }
}

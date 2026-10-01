import '../models/notification_model.dart';

/// Abstract gateway for notification data operations.
abstract class NotificationGateway {
  /// Load all notifications for a user, most recent first.
  Future<List<OnoNotification>> loadNotifications(String userId);

  /// Mark a single notification as read.
  Future<void> markRead(String userId, String notifId);

  /// Mark every notification as read.
  Future<void> markAllRead(String userId);

  /// Load stored notification preferences for a user.
  Future<NotificationPreferences> loadPreferences(String userId);

  /// Persist notification preferences for a user.
  Future<void> savePreferences(String userId, NotificationPreferences prefs);

  /// Number of unread notifications for a user.
  Future<int> getUnreadCount(String userId);

  /// Push a freshly generated notification into the user's feed.
  Future<OnoNotification> addNotification(
    String userId,
    OnoNotification notification,
  );
}

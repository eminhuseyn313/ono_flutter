import '../models/notification_model.dart';
import 'notification_gateway.dart';

/// In-memory mock implementation of [NotificationGateway] for development.
class MockNotificationGateway implements NotificationGateway {
  final Map<String, List<OnoNotification>> _store = {};
  final Map<String, NotificationPreferences> _prefs = {};
  int _nextId = 100;

  void _seedIfNeeded(String userId) {
    if (_store.containsKey(userId)) return;

    final now = DateTime.now();
    _store[userId] = [
      OnoNotification(
        id: 'notif_1',
        type: NotificationType.streakRisk,
        title: '🔥 12 days strong.',
        body: "Don't let today be day zero. Your streak is waiting.",
        createdAt: now.subtract(const Duration(minutes: 20)),
        isRead: false,
        actionRoute: '/home',
      ),
      OnoNotification(
        id: 'notif_2',
        type: NotificationType.roleModel,
        title: 'Goggins ran 100 miles on broken feet. 💪',
        body: 'Your 20 pushups are nothing. Go.',
        lane: 'body',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
        isRead: false,
        actionRoute: '/lane/body',
      ),
      OnoNotification(
        id: 'notif_3',
        type: NotificationType.socialProof,
        title: '1,247 warriors completed their actions today.',
        body: 'Join them. Your action is one tap away.',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
        actionRoute: '/home',
      ),
      OnoNotification(
        id: 'notif_4',
        type: NotificationType.milestone,
        title: '🏆 New achievement unlocked: Iron Will',
        body: 'You completed 7 days in a row across every lane.',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
        actionRoute: '/achievements',
      ),
      OnoNotification(
        id: 'notif_5',
        type: NotificationType.roleModel,
        title: 'Marcus Aurelius journaled every morning. 🧠',
        body: 'Your Mind lane awaits.',
        lane: 'mind',
        createdAt: now.subtract(const Duration(hours: 9)),
        isRead: true,
        actionRoute: '/lane/mind',
      ),
      OnoNotification(
        id: 'notif_6',
        type: NotificationType.streakRisk,
        title: 'Your 12-day streak is waiting.',
        body: '23 hours left. The old you would skip today.',
        createdAt: now.subtract(const Duration(hours: 14)),
        isRead: true,
        actionRoute: '/home',
      ),
      OnoNotification(
        id: 'notif_7',
        type: NotificationType.socialProof,
        title: "You're in the top 8% this week.",
        body: 'Keep climbing. Momentum compounds.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        actionRoute: '/home',
      ),
      OnoNotification(
        id: 'notif_8',
        type: NotificationType.milestone,
        title: '⬆️ Legacy Score hit 2,400!',
        body: "You're now a Disciplined Operator.",
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionRoute: '/achievements',
      ),
      OnoNotification(
        id: 'notif_9',
        type: NotificationType.reminder,
        title: "Naval says specific knowledge can't be taught. 📚",
        body: 'Keep building yours. Skill lane check-in.',
        lane: 'skill',
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        isRead: true,
        actionRoute: '/lane/skill',
      ),
      OnoNotification(
        id: 'notif_10',
        type: NotificationType.socialProof,
        title: '2,003 warriors completed their actions today.',
        body: 'Join them. Your action is one tap away.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        actionRoute: '/home',
      ),
    ];

    _prefs[userId] = const NotificationPreferences();
  }

  @override
  Future<List<OnoNotification>> loadNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _seedIfNeeded(userId);
    final list = List<OnoNotification>.of(_store[userId]!);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markRead(String userId, String notifId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _seedIfNeeded(userId);
    final list = _store[userId]!;
    final idx = list.indexWhere((n) => n.id == notifId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _seedIfNeeded(userId);
    final list = _store[userId]!;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isRead: true);
    }
  }

  @override
  Future<NotificationPreferences> loadPreferences(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _seedIfNeeded(userId);
    return _prefs[userId]!;
  }

  @override
  Future<void> savePreferences(
    String userId,
    NotificationPreferences prefs,
  ) async {
    await Future.delayed(const Duration(milliseconds: 180));
    _seedIfNeeded(userId);
    _prefs[userId] = prefs;
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _seedIfNeeded(userId);
    return _store[userId]!.where((n) => !n.isRead).length;
  }

  @override
  Future<OnoNotification> addNotification(
    String userId,
    OnoNotification notification,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _seedIfNeeded(userId);
    final withId = notification.id.isEmpty
        ? notification.copyWith(id: 'notif_${_nextId++}')
        : notification;
    _store[userId]!.insert(0, withId);
    return withId;
  }
}

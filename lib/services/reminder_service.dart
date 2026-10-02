import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One weekly-repeating notification.
class PlannedReminder {
  final int id;
  final int weekday; // DateTime.monday …
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String route;

  const PlannedReminder({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.route,
  });
}

abstract class ReminderService {
  Future<void> init({required void Function(String route) onOpen});
  Future<bool> requestPermission();

  /// Replace every scheduled reminder with [reminders].
  Future<void> sync(List<PlannedReminder> reminders);
}

/// No-op implementation for web and tests.
class NoopReminderService implements ReminderService {
  List<PlannedReminder> lastSynced = const [];

  @override
  Future<void> init({required void Function(String route) onOpen}) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<PlannedReminder> reminders) async {
    lastSynced = reminders;
  }
}

/// iOS / Android local notifications, repeating weekly at local time.
class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  List<PlannedReminder>? _pending;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'ono_schedule',
      'Daily schedule',
      channelDescription: 'Reminders at the times in your ONO schedule',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init({required void Function(String route) onOpen}) async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Unknown zone name — fall back to UTC; times may be offset.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested from the Commission flow, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.isNotEmpty) onOpen(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = launch?.notificationResponse?.payload;
    _ready = true;
    if (launch?.didNotificationLaunchApp == true &&
        route != null &&
        route.isNotEmpty) {
      onOpen(route);
    }
    if (_pending != null) await sync(_pending!);
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  @override
  Future<void> sync(List<PlannedReminder> reminders) async {
    if (kIsWeb) return;
    if (!_ready) {
      _pending = reminders;
      return;
    }
    _pending = null;
    await _plugin.cancelAll();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: _next(r.weekday, r.hour, r.minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: r.route,
      );
    }
  }

  tz.TZDateTime _next(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (t.weekday != weekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }
}

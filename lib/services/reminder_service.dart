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

/// Ids at or above this are one-off notifications (timers); weekly
/// reminders stay below it, so re-syncing them leaves a running timer alone.
const int onceIdBase = 90000;

abstract class ReminderService {
  /// False where notifications can't be delivered (the web app), so the
  /// app doesn't promise reminders it can't send.
  bool get supported;

  Future<void> init({required void Function(String route) onOpen});
  Future<bool> requestPermission();

  /// Replace every scheduled reminder with [reminders].
  Future<void> sync(List<PlannedReminder> reminders);

  /// One notification at [at] (e.g. the end of a gym rest). It only shows
  /// when ONO is in the background; the open screen handles it itself.
  Future<void> notifyOnce(int id, DateTime at,
      {required String title, required String body, required String route});

  Future<void> cancel(int id);
}

/// No-op implementation for web and tests.
class NoopReminderService implements ReminderService {
  NoopReminderService({this.supported = true});

  @override
  final bool supported;

  List<PlannedReminder> lastSynced = const [];

  @override
  Future<void> init({required void Function(String route) onOpen}) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<PlannedReminder> reminders) async {
    lastSynced = reminders;
  }

  /// One-off notifications still pending, by id.
  final Map<int, DateTime> once = {};

  @override
  Future<void> notifyOnce(int id, DateTime at,
          {required String title,
          required String body,
          required String route}) async =>
      once[id] = at;

  @override
  Future<void> cancel(int id) async => once.remove(id);
}

/// iOS / Android local notifications, repeating weekly at local time.
class LocalReminderService implements ReminderService {
  @override
  bool get supported => true;

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

  // Silent while ONO is open: the screen that set it shows its own cue.
  static const _onceDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'ono_timers',
      'Timers',
      channelDescription: 'Gym rest and other timers',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: false,
      presentBanner: false,
      presentList: false,
      presentSound: false,
    ),
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
    // One sync at a time, newest request last: two overlapping syncs each
    // list → cancel → schedule, and the older one's set could win (a
    // reminder just switched off would keep firing).
    _queued = reminders;
    if (_running != null) return _running;
    final run = () async {
      try {
        while (_queued != null) {
          final next = _queued!;
          _queued = null;
          await _apply(next);
        }
      } finally {
        // Cleared before returning, so a request arriving now starts a new
        // run instead of joining this finished one.
        _running = null;
      }
    }();
    _running = run;
    await run;
  }

  List<PlannedReminder>? _queued;
  Future<void>? _running;

  Future<void> _apply(List<PlannedReminder> reminders) async {
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id < onceIdBase) await _plugin.cancel(id: p.id);
    }
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

  @override
  Future<void> notifyOnce(int id, DateTime at,
      {required String title,
      required String body,
      required String route}) async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _onceDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: route,
      );
    } catch (_) {
      // Notifications off: the in-app timer still works.
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancel(id: id);
  }

  tz.TZDateTime _next(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    // Build each candidate from the date, so a daylight-saving change in
    // between doesn't shift the time by an hour.
    for (var k = 0;; k++) {
      final t = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + k, hour, minute);
      if (t.weekday == weekday && t.isAfter(now)) return t;
    }
  }
}

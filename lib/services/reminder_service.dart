import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../time.dart';
import 'notification_actions.dart';

/// One weekly-repeating notification.
class PlannedReminder {
  final int id;
  final int weekday; // DateTime.monday …
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String route;

  /// The reminder it comes from (its `ReminderDef` id), for the
  /// notification centre.
  final String key;

  /// The daily item it is about: its notification gets a Done button.
  final String? itemId;

  /// Already done today: the weekly repeat starts from next week's day,
  /// so a calm app doesn't nag about what's finished.
  final bool skipToday;

  const PlannedReminder({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.route,
    this.key = '',
    this.itemId,
    this.skipToday = false,
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
    iOS: DarwinNotificationDetails(categoryIdentifier: NotificationActions.nudgeCategory),
    macOS: DarwinNotificationDetails(categoryIdentifier: NotificationActions.nudgeCategory),
  );

  // About a daily item: Done and In 1 hour on the notification.
  static const _itemDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'ono_schedule',
      'Daily schedule',
      channelDescription: 'Reminders at the times in your ONO schedule',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: NotificationActions.itemCategory),
    macOS: DarwinNotificationDetails(categoryIdentifier: NotificationActions.itemCategory),
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
    macOS: DarwinNotificationDetails(
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
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested from the Commission flow, not at launch.
        iOS: _darwinSettings,
        // The Mac app: same reminders, asked for the same way.
        macOS: _darwinSettings,
      ),
      onDidReceiveNotificationResponse: (r) async {
        if (await handleNotificationAction(_plugin, r)) return;
        final route = NotificationActions.parse(r.payload).route;
        if (route.isNotEmpty) onOpen(route);
      },
      onDidReceiveBackgroundNotificationResponse: onoNotificationInBackground,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = NotificationActions.parse(launch?.notificationResponse?.payload).route;
    _ready = true;
    if (launch?.didNotificationLaunchApp == true && route.isNotEmpty) {
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
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      return await mac.requestPermissions(alert: true, badge: true, sound: true) ?? false;
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
        scheduledDate: _next(r.weekday, r.hour, r.minute, skipToday: r.skipToday),
        notificationDetails: r.itemId != null ? _itemDetails : _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: NotificationActions.payload(
            route: r.route, key: r.key, item: r.itemId, title: r.title, body: r.body),
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
        payload: NotificationActions.payload(route: route, title: title, body: body),
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

  tz.TZDateTime _next(int weekday, int hour, int minute, {bool skipToday = false}) {
    final now = tz.TZDateTime.now(tz.local);
    // Build each candidate from the date, so a daylight-saving change in
    // between doesn't shift the time by an hour.
    for (var k = skipToday ? 1 : 0;; k++) {
      final t = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + k, hour, minute);
      if (t.weekday == weekday && t.isAfter(now)) return t;
    }
  }
}

/// Asking for permission happens on Today; the buttons are declared here.
final _darwinSettings = DarwinInitializationSettings(
  requestAlertPermission: false,
  requestBadgePermission: false,
  requestSoundPermission: false,
  notificationCategories: [
    DarwinNotificationCategory(NotificationActions.itemCategory, actions: [
      DarwinNotificationAction.plain(NotificationActions.done, 'Done'),
      DarwinNotificationAction.plain(NotificationActions.later, 'In 1 hour'),
    ]),
    DarwinNotificationCategory(NotificationActions.nudgeCategory, actions: [
      DarwinNotificationAction.plain(NotificationActions.later, 'In 1 hour'),
    ]),
  ],
);

/// A button on a notification: Done records the tick; In 1 hour sends the
/// same notification again an hour from now. Returns whether it was one.
Future<bool> handleNotificationAction(FlutterLocalNotificationsPlugin plugin, NotificationResponse r) async {
  final p = NotificationActions.parse(r.payload);
  switch (r.actionId) {
    case NotificationActions.done:
      if (p.item != null) {
        await NotificationActions.recordDone(p.item!, timeNow());
        NotificationActions.onTicks?.call();
      }
      return true;
    case NotificationActions.later:
      try {
        tzdata.initializeTimeZones();
        await plugin.zonedSchedule(
          id: onceIdBase + 300 + ((r.id ?? 0) % 90),
          title: p.title.isEmpty ? 'ONO' : p.title,
          body: p.body,
          scheduledDate: tz.TZDateTime.now(tz.UTC).add(const Duration(hours: 1)),
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(
                categoryIdentifier: p.item != null ? NotificationActions.itemCategory : NotificationActions.nudgeCategory),
            macOS: DarwinNotificationDetails(
                categoryIdentifier: p.item != null ? NotificationActions.itemCategory : NotificationActions.nudgeCategory),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: r.payload,
        );
      } catch (_) {
        // Notifications off: nothing to bring back.
      }
      return true;
  }
  return false;
}

/// The same, when ONO isn't running (iOS starts a short background engine;
/// AppDelegate registers the plugins for it).
@pragma('vm:entry-point')
Future<void> onoNotificationInBackground(NotificationResponse r) async {
  final plugin = FlutterLocalNotificationsPlugin();
  try {
    await plugin.initialize(settings: InitializationSettings(iOS: _darwinSettings, macOS: _darwinSettings));
  } catch (_) {
    // Already set up in this engine.
  }
  await handleNotificationAction(plugin, r);
}

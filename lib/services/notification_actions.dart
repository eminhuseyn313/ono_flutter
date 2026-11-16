import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/personal_system.dart';

/// Buttons on ONO's notifications: "Done" ticks the daily item it is about
/// without opening ONO, "In 1 hour" brings it back later. A tick made
/// while ONO is closed waits here until ONO next opens.
class NotificationActions {
  static const done = 'done';
  static const later = 'later';

  /// iOS/macOS categories: one about a daily item (Done, In 1 hour), one
  /// about anything else (In 1 hour).
  static const itemCategory = 'ono_item';
  static const nudgeCategory = 'ono_nudge';

  static const _ticksKey = 'ono_notification_ticks';

  /// Called when a tick was recorded while ONO is running.
  static void Function()? onTicks;

  /// What a notification carries, so a tap or a button knows what it is.
  static String payload({
    required String route,
    String key = '',
    String? item,
    String title = '',
    String body = '',
  }) =>
      jsonEncode({'r': route, 'k': key, if (item != null) 'i': item, 't': title, 'b': body});

  /// Reads a payload; older notifications carry only the route.
  static ({String route, String key, String? item, String title, String body}) parse(String? payload) {
    final p = payload ?? '';
    if (p.startsWith('{')) {
      try {
        final m = jsonDecode(p) as Map;
        return (
          route: '${m['r'] ?? ''}',
          key: '${m['k'] ?? ''}',
          item: m['i'] == null ? null : '${m['i']}',
          title: '${m['t'] ?? ''}',
          body: '${m['b'] ?? ''}',
        );
      } catch (_) {
        // Not ours: treat as a route.
      }
    }
    return (route: p, key: '', item: null, title: '', body: '');
  }

  /// The day a tap at [when] counts for: before 04:00 it is still the
  /// night before, as on Today.
  static DateTime dayOf(DateTime when) {
    final d = dayOnly(when);
    return when.hour < 4 ? d.minusDays(1) : d;
  }

  /// Saves a "Done" for [item] (works from a background isolate).
  static Future<void> recordDone(String item, DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ticksKey) ?? <String>[];
    list.add(jsonEncode({'id': item, 'date': dateKey(dayOf(when))}));
    await prefs.setStringList(_ticksKey, list);
  }

  /// The ticks waiting since ONO last looked, cleared once taken.
  static Future<List<({String id, String date})>> takeTicks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_ticksKey) ?? const <String>[];
    if (list.isEmpty) return const [];
    await prefs.remove(_ticksKey);
    return [
      for (final s in list)
        if (_tick(s) case final t?) t
    ];
  }

  static ({String id, String date})? _tick(String s) {
    try {
      final m = jsonDecode(s) as Map;
      final id = m['id'];
      final date = m['date'];
      if (id is! String || date is! String) return null;
      return (id: id, date: date);
    } catch (_) {
      return null;
    }
  }
}

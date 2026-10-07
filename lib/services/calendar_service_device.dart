import 'dart:io' show Platform;

import 'package:device_calendar/device_calendar.dart';

import 'calendar_service.dart';

CalendarService createCalendarService() =>
    Platform.isIOS ? DeviceCalendarService() : const NoopCalendarService();

/// iPhone calendars via EventKit. Needs only the calendar usage text in
/// Info.plist, no entitlement.
class DeviceCalendarService implements CalendarService {
  final _plugin = DeviceCalendarPlugin();

  @override
  bool get isSupported => true;

  @override
  Future<bool> connect() async {
    try {
      final has = await _plugin.hasPermissions();
      if (has.data == true) return true;
      final asked = await _plugin.requestPermissions();
      return asked.data == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Meeting>> meetingsOn(DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final out = <String, Meeting>{};
    try {
      final calendars = (await _plugin.retrieveCalendars()).data ?? const [];
      for (final c in calendars) {
        final events = (await _plugin.retrieveEvents(
                    c.id, RetrieveEventsParams(startDate: from, endDate: to)))
                .data ??
            const [];
        for (final e in events) {
          final start = e.start, end = e.end;
          if (e.allDay == true || start == null || end == null) continue;
          final id = '${e.eventId}@${start.toIso8601String()}';
          out[id] = Meeting(
            id: id,
            title: (e.title ?? '').trim().isEmpty ? 'Busy' : e.title!.trim(),
            start: start.toLocal(),
            end: end.toLocal(),
            attendees: <String>[
              for (final a in e.attendees ?? const <Attendee?>[])
                if (a != null)
                  (a.name ?? '').trim().isNotEmpty
                      ? a.name!.trim()
                      : (a.emailAddress ?? '').trim(),
            ].where((n) => n.isNotEmpty).toList(),
          );
        }
      }
    } catch (_) {
      return const [];
    }
    return out.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }
}

import 'calendar_service_stub.dart'
    if (dart.library.io) 'calendar_service_device.dart' as impl;

/// One event from the iPhone calendar (work calendars synced to it too).
class Meeting {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;

  /// Attendee names (or emails when there is no name).
  final List<String> attendees;

  const Meeting({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.attendees = const [],
  });

  Duration get length => end.difference(start);
}

/// Reads today's meetings. Read-only: ONO never writes to the calendar.
abstract class CalendarService {
  bool get isSupported;

  /// Asks for calendar access; false if refused.
  Future<bool> connect();

  /// Timed events overlapping [day], from every calendar, by start time.
  Future<List<Meeting>> meetingsOn(DateTime day);
}

class NoopCalendarService implements CalendarService {
  const NoopCalendarService();
  @override
  bool get isSupported => false;
  @override
  Future<bool> connect() async => false;
  @override
  Future<List<Meeting>> meetingsOn(DateTime day) async => const [];
}

CalendarService createCalendarService() => impl.createCalendarService();

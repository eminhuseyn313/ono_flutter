import 'package:ono/services/calendar_service.dart';

class FakeCalendarService implements CalendarService {
  final bool grant;
  List<Meeting> meetings;
  FakeCalendarService({this.grant = true, this.meetings = const []});

  @override
  bool get isSupported => true;
  @override
  Future<bool> connect() async => grant;
  @override
  Future<List<Meeting>> meetingsOn(DateTime day) async => [
        for (final m in meetings)
          if (m.start.isBefore(DateTime(day.year, day.month, day.day + 1)) &&
              m.end.isAfter(DateTime(day.year, day.month, day.day)))
            m
      ];

  /// Events ONO put in the calendar (they show as meetings too).
  final added = <Meeting>[];

  @override
  Future<bool> addEvent(String title, DateTime start, DateTime end, {String note = ''}) async {
    if (!grant) return false;
    final m = Meeting(id: 'added-${added.length}', title: title, start: start, end: end);
    added.add(m);
    meetings = [...meetings, m];
    return true;
  }
}

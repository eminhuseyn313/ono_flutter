import 'calendar_service.dart';

/// Web: no device calendar.
CalendarService createCalendarService() => const NoopCalendarService();

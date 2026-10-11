import 'emin_system.dart' show ReminderDef;

/// What each phase of the 18-month program means for anyone. The built-in
/// person's phase promises live in emin_system.dart.
const Map<String, String> generalPhasePromises = {
  'foundation':
      'Build the base: sleep, energy and a daily plan that holds on ordinary days.',
  'craft':
      'Practise on purpose: real reps in what you are growing, with feedback.',
  'signal':
      'Let it show: share the work, ask for honest views, be seen doing it.',
  'leverage':
      'Use what you have built: decide the next step from strength, not hope.',
};

/// Reminders for anyone with a plan of their own (the built-in person's
/// follow their schedule: `reminderDefs` in emin_system.dart). Times are
/// sensible defaults; each can be switched off under Me → Reminders.
const List<ReminderDef> generalReminderDefs = [
  ReminderDef('g_checkin', 'Morning check-in', 7, 30, route: '/checkin'),
  ReminderDef('g_items', 'Your daily items', 12, 30, route: '/home'),
  ReminderDef('g_shutdown', 'Close the day', 21, 0, route: '/shutdown'),
  ReminderDef('g_sunday', 'Sunday report', 18, 0,
      weekdays: [DateTime.sunday], route: '/weekly-coaching'),
];

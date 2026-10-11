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

/// The four lanes in a line each, for anyone (the welcome screen).
const List<(String lane, String name, String line)> generalLanes = [
  ('mind', 'Mind', 'Calm under pressure, clear thinking'),
  ('body', 'Body', 'Sleep, movement, energy'),
  ('skill', 'Skill', 'Practice that compounds'),
  ('social', 'Social', 'The people who matter'),
];

/// One question a day, across the whole of life, for anyone. Answering in
/// a line is enough; the answer is saved as a note.
const List<(String area, String question)> dailyQuestions = [
  ('career', 'What did you do today that the person you\'re becoming would do?'),
  ('health', 'What gave you energy today, and what took it?'),
  ('relationships', 'Who did you really listen to today?'),
  ('mind', 'What worried you today — and what part of it can you act on?'),
  ('growth', 'What did you notice today that you didn\'t know yesterday?'),
  ('meaning', 'What felt worth doing today?'),
  ('money', 'Did today\'s spending match what you care about?'),
  ('family', 'Who would you like to thank, and haven\'t yet?'),
  ('career', 'Where did you avoid something hard today? What would one small step be?'),
  ('mind', 'What would you tell a friend who had your day?'),
  ('growth', 'What will you practise tomorrow, on purpose?'),
  ('relationships', 'What do the people closest to you need from you this week?'),
  ('health', 'How did your body feel today, honestly?'),
  ('meaning', 'What are you proud of this week that nobody saw?'),
  ('career', 'What feedback did you get today — said or unsaid?'),
  ('mind', 'What story did you tell yourself today that might not be true?'),
  ('growth', 'What question would you like answered by the end of the month?'),
  ('family', 'What small ritual could make home feel better this week?'),
  ('meaning', 'If this week were a chapter, what would it be called?'),
  ('career', 'What one decision would make next week easier?'),
  ('relationships', 'Who have you been meaning to reach out to?'),
];

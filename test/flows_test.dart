import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/main.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/services/reminder_service.dart';

import 'support/fake_health.dart';

/// Tapping through the newer tools as a person would, then checking what
/// was saved. The smoke test (widget_test.dart) only checks that screens
/// render; these check that they work.

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

Future<PersonalSystemProvider> _start(WidgetTester tester,
    {Size size = const Size(1179, 2556)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(OnoApp(
    authGateway: MockAuthGateway(),
    personalGateway: MockPersonalSystemGateway(),
    reminders: NoopReminderService(),
    health: FakeHealthService(),
  ));
  await _pumpFor(tester, const Duration(seconds: 2));
  await Provider.of<AuthProvider>(tester.element(find.byType(Scaffold).first),
          listen: false)
      .signIn(email: 'flows@test.dev', password: 'password');
  await _pumpFor(tester, const Duration(seconds: 2));
  final system = Provider.of<PersonalSystemProvider>(
      tester.element(find.byType(Navigator).first),
      listen: false);
  await system.commission(
    start: dayOnly(DateTime.now()).subtract(const Duration(days: 10)),
    gymDays: const [1, 3, 5],
    reminders: const {},
  );
  return system;
}

Future<void> _go(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
  await _pumpFor(tester, const Duration(milliseconds: 1200));
}

/// Scrolls the page until [f] is built and on screen.
Future<void> _reach(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(f, findsWidgets, reason: 'never reached $f');
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final f = find.widgetWithText(TextField, label);
  await _reach(tester, f);
  await tester.enterText(f.first, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await _reach(tester, f);
  await tester.tap(f.first);
  await _pumpFor(tester, const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('thought check saves the thought, feeling and both ratings',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/thought');
    await _type(tester, 'What happened?', 'The review meeting');
    await _type(tester, 'What went through your mind?', 'They think I am not ready');
    await _tap(tester, find.text('Anxious'));
    await _type(tester, 'A more balanced thought', 'One hard question is not a verdict');
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(seconds: 1));
    final t = system.thoughts.single;
    expect(t.text, 'They think I am not ready');
    expect(t.str('feeling'), 'Anxious');
    expect(t.str('balanced'), 'One hard question is not a verdict');
    expect(t.number('before'), 60);
  });

  testWidgets('worry time: park a worry, then turn it into a priority',
      (tester) async {
    final system = await _start(tester);
    system.setWorryTime(0); // the slot has passed: worries are due
    await _go(tester, '/worry');
    await _type(tester, 'What\'s on your mind?', 'The budget for next year');
    await tester.tap(find.byTooltip('Park it'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.parkedWorries.single.text, 'The budget for next year');
    await _tap(tester, find.text('Deal with it'));
    await tester.enterText(
        find.widgetWithText(TextField, 'The smallest next step, if there is one'),
        'Ask finance for last year\'s numbers');
    await tester.tap(find.text('A next step'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(system.parkedWorries, isEmpty);
    expect(system.prioritiesFor(DateTime.now()),
        contains('Ask finance for last year\'s numbers'));
  });

  testWidgets('kindness day: pick today, log an act', (tester) async {
    final system = await _start(tester);
    await _go(tester, '/kindness');
    final day = DateTime.now().weekday;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    await _tap(tester, find.text(names[day - 1]));
    expect(system.kindnessDay, day);
    await _type(tester, 'What did you do, for whom?', 'Coffee for the night shift');
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.kindnessOn(DateTime.now()).single.text, 'Coffee for the night shift');
  });

  testWidgets('strengths: tick two, use one in a new way', (tester) async {
    final system = await _start(tester);
    await _go(tester, '/strengths');
    await _tap(tester, find.text('Curiosity'));
    await _tap(tester, find.text('Hope'));
    expect(system.signatureStrengths, ['Curiosity', 'Hope']);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await _pumpFor(tester, const Duration(milliseconds: 400));
    final how = find.byType(TextField).first;
    await tester.enterText(how, 'Asked three why-questions in the design review');
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.logsOf('strength_use').single.str('strength'), 'Curiosity');
  });

  testWidgets('personal board: put someone in a role', (tester) async {
    final system = await _start(tester);
    system.addPerson('Aysel', role: 'Former manager');
    await _go(tester, '/board');
    await tester.tap(find.text('+ Add').first); // Mentor
    await _pumpFor(tester, const Duration(milliseconds: 800));
    await tester.tap(find.text('Aysel'));
    await _pumpFor(tester, const Duration(milliseconds: 400));
    expect(system.board['mentor']!.single.text, 'Aysel');
    expect(system.boardGaps, contains('sponsor'));
  });

  testWidgets('after-action review: "change" becomes a review card',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/aar');
    await _type(tester, 'What was it?', 'The board presentation');
    await _type(tester, 'Change: one thing you\'ll do differently next time',
        'Rehearse the Q&A out loud');
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(system.aars.single.text, 'The board presentation');
    expect(system.allCards.any((c) => c.back == 'Rehearse the Q&A out loud'), isTrue);
  });

  testWidgets('best possible future and life chapters save', (tester) async {
    final system = await _start(tester);
    await _go(tester, '/best-future');
    await _type(tester, 'Work and what you build', 'I lead a team I am proud of.');
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect((system.bestFuture!.data['areas'] as Map)['work'], 'I lead a team I am proud of.');

    await _go(tester, '/chapters');
    await tester.enterText(find.widgetWithText(TextField, 'Title').first, 'Leaving home');
    await _type(tester, 'The title of the next chapter', 'Leading');
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(system.lifeChapters.single['title'], 'Leaving home');
    expect(system.lifeStory!.str('next'), 'Leading');
  });

  testWidgets('closing a program early starts the next with the chosen length',
      (tester) async {
    final system = await _start(tester);
    system.addLog('win', text: 'Shipped it');
    await _go(tester, '/next-program');
    await _type(tester, 'What changed in you?', 'I ask for help sooner');
    await _tap(tester, find.text('6 months'));
    await tester.tap(find.text('Start the next 6 months'));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(system.cycle, 2);
    expect(system.programDays, 180);
    expect(system.programDay, 1);
    expect(system.pastPrograms.single.text, 'I ask for help sooner');
    expect(system.logsOf('win'), isNotEmpty);
  });

  testWidgets('promises: add one, then keep it', (tester) async {
    final system = await _start(tester);
    await _go(tester, '/promises');
    await _type(tester, 'What you promised', 'Send the draft');
    await _type(tester, 'To whom', 'Aysel');
    await _tap(tester, find.text('Add promise'));
    expect(system.openPromises.single.str('to'), 'Aysel');
    await _tap(tester, find.text('Close'));
    await tester.tap(find.text('Kept'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.openPromises, isEmpty);
    expect(system.logsOf('promise').single.str('status'), 'kept');
  });

  testWidgets('story bank: turn a win into a STAR story', (tester) async {
    final system = await _start(tester);
    system.addLog('win', text: 'Shipped the onboarding redesign');
    await _go(tester, '/stories');
    await _tap(tester, find.text('Shipped the onboarding redesign'));
    await _type(tester, 'Result', 'Sign-ups up 18% in a month');
    await _tap(tester, find.text('Customer focus'));
    await tester.tap(find.text('Save'));
    await _pumpFor(tester, const Duration(seconds: 1));
    final s = system.stories.single;
    expect(s.text, 'Shipped the onboarding redesign');
    expect(s.str('result'), 'Sign-ups up 18% in a month');
    expect(system.skillsOf(s), ['Customer focus']);
    expect(system.storyIdeas, isEmpty);
  });

  testWidgets('the story editor fits an iPhone SE', (tester) async {
    await _start(tester, size: const Size(1125, 2001));
    await _go(tester, '/stories');
    await _tap(tester, find.text('New story'));
    expect(find.text('Tell it in four parts'), findsOneWidget);
    await _reach(tester, find.text('Creativity'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('find a tool: search narrows the list and opens the tool',
      (tester) async {
    await _start(tester);
    await _go(tester, '/tools');
    await tester.enterText(find.byType(TextField).first, 'interview');
    await _pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.text('Story bank'), findsOneWidget);
    expect(find.text('Movement'), findsNothing);
    await tester.tap(find.text('Story bank'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Your best stories, ready'), findsOneWidget);
  });

  testWidgets('ask for help: guess, ask, note the yes', (tester) async {
    final system = await _start(tester);
    await _go(tester, '/asks');
    await _type(tester, 'What you\'ll ask for', 'Twenty minutes on my draft');
    await _type(tester, 'Who', 'Aysel');
    await _tap(tester, find.text('Add the ask'));
    expect(system.openAsks.single.str('of'), 'Aysel');
    await _tap(tester, find.text('Answer'));
    await tester.tap(find.text('Yes'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.openAsks, isEmpty);
    expect(system.logsOf('ask').single.str('status'), 'yes');
  });

  testWidgets('year in review: answer, choose a word, save', (tester) async {
    final system = await _start(tester);
    system.addLog('win', text: 'Ran my first 10k');
    // Out of season it shows the year so far, with nothing to save.
    if (system.yearToReview == null) {
      await _go(tester, '/year');
      expect(find.text('${system.yearOnScreen} so far'), findsOneWidget);
      expect(find.text('Save the review'), findsNothing);
      final now = DateTime.now();
      system.clock = () => DateTime(now.year, 12, 20, 9);
      await _go(tester, '/profile');
    }
    await _go(tester, '/year');
    expect(find.text('• Ran my first 10k'), findsOneWidget);
    await _reach(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField).first, 'Keeping the mornings');
    await _type(tester, 'e.g. Steady, Brave, Home, Build', 'Steady');
    await tester.tap(find.text('Save the review'));
    await _pumpFor(tester, const Duration(seconds: 1));
    final r = system.yearReviewFor(system.yearToReview!)!;
    expect(r.text, 'Steady');
    expect(r.str('proud'), 'Keeping the mornings');
  });
}


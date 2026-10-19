import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import 'package:ono/main.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/widgets/ono_ui.dart';

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
    {Size size = const Size(1179, 2556), MockAuthGateway? auth}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(OnoApp(
    authGateway: auth ?? MockAuthGateway(),
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
    start: dayOnly(DateTime.now()).minusDays(10),
    gymDays: const [1, 3, 5],
    reminders: const {},
  );
  return system;
}

Future<void> _go(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  Navigator.of(ctx, rootNavigator: true).popUntil((r) => r is! PopupRoute);
  await tester.pump(const Duration(milliseconds: 400));
  GoRouter.of(ctx).go(route);
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

  testWidgets('the week\'s three: one tap fills them from the plan', (tester) async {
    final system = await _start(tester);
    system.saveGoal(title: 'Run a half marathon', milestones: const ['Run 10 km without stopping']);
    await _go(tester, '/week');
    await _tap(tester, find.text('Use these'));
    final week = weekStartOf(DateTime.now());
    expect(system.weekOutcomes(week).first, 'Run 10 km without stopping');
    expect(find.text('Use these'), findsNothing);
  });

  testWidgets('the month-end rating shows the lessons and feedback first',
      (tester) async {
    final system = await _start(tester);
    final area = system.focusArea(system.programMonth) ?? system.allGrowthAreas.first;
    if (system.focusArea(system.programMonth) == null) system.setFocus(area.id, startRating: 2);
    final drill = system.drillsOf(area).first;
    system.logRep(area, drill, did: 'Ran the meeting', lesson: 'Say the ask first');
    system.logFeedback(area, from: 'Sam', said: 'Clearer than last month');
    await _go(tester, '/growth');
    await _reach(tester, find.text('WHAT YOU HAVE TO GO ON'));
    expect(find.text('• Say the ask first'), findsOneWidget);
    expect(find.text('• Sam said: "Clearer than last month"'), findsOneWidget);
  });

  testWidgets('Today keeps the plan\'s next step in view while folded',
      (tester) async {
    final system = await _start(tester);
    system.setWeekOutcome(DateTime.now(), 0, 'Send the proposal');
    await _go(tester, '/home');
    await _reach(tester, find.byKey(const Key('plan-next')));
    expect(find.text('Next: Send the proposal'), findsOneWidget);
  });

  testWidgets('a person opens from the link: log yesterday, change the rhythm',
      (tester) async {
    final system = await _start(tester);
    final mum = system.addPerson('Mum', every: 7);
    system.updatePerson(mum, askAbout: 'the garden');
    await _go(tester, '/people?id=${mum.id}');
    expect(find.text('Ask about: the garden'), findsOneWidget);
    await _tap(tester, find.text('Yesterday'));
    await _tap(tester, find.text('In touch yesterday'));
    expect(system.lastContact(system.personById(mum.id)!),
        dayOnly(DateTime.now()).minusDays(1));
    expect(system.askAboutOf(system.personById(mum.id)!), '');
    await _tap(tester, find.text('Mum'));
    await _tap(tester, find.byKey(const Key('person-details')));
    await _tap(tester, find.descendant(
        of: find.byType(BottomSheet), matching: find.text('Every 2 weeks')));
    await _tap(tester, find.text('Save details'));
    expect(system.cadenceOf(system.personById(mum.id)!), 14);
  });

  testWidgets('a goal: add a milestone, name the next step, decide at the date',
      (tester) async {
    final system = await _start(tester);
    final g = system.saveGoal(
        title: 'Write a book', deadline: dayOnly(DateTime.now()).minusDays(1))!;
    await _go(tester, '/goals/view?id=${g.id}');
    // Its date has passed, but with nothing to measure it isn't "past due".
    expect(find.text('How will you know it\'s moving?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('goal-milestone')), 'Outline done');
    await _tap(tester, find.byKey(const Key('goal-milestone-add')));
    expect(system.milestonesOf(system.goalById(g.id)!).single.text, 'Outline done');
    expect(find.byKey(const Key('goal-decision')), findsOneWidget);
    await _tap(tester, find.text('3 more months'));
    expect(system.goalsAtDecision, isEmpty);
    await tester.enterText(find.byKey(const Key('goal-next')), 'Write 300 words on Saturday');
    await _tap(tester, find.byKey(const Key('goal-next-save')));
    expect(system.goalNextStep(system.goalById(g.id)!), 'Write 300 words on Saturday',
        reason: 'the step you name comes before the open milestone');
  });

  testWidgets('a low morning offers a minimum day; a set priority shows on Today',
      (tester) async {
    final system = await _start(tester);
    final today = dayOnly(DateTime.now());
    system.saveCheckin(today, energy: 2, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    await _go(tester, '/home');
    await _tap(tester, find.text('Make it a minimum day'));
    expect(system.hardDayOn(today), 'minimum');
    // Something else fills today's first priority while Today is open.
    system.setPriority(today, 0, 'Send the two emails');
    await tester.pump(const Duration(milliseconds: 300));
    await _reach(tester, find.text('Send the two emails'));
  });

  testWidgets('Log: fix a typo in a win, find it by searching', (tester) async {
    final system = await _start(tester);
    system.addLog('win', text: 'Ran 5 km withut stopping');
    await _go(tester, '/log');
    await _tap(tester, find.text('Ran 5 km withut stopping'));
    await tester.enterText(find.byKey(const Key('log-edit')), 'Ran 5 km without stopping');
    final save = find.descendant(
        of: find.byType(BottomSheet), matching: find.text('Save'));
    await tester.ensureVisible(save);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(save);
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.logsOf('win').single.text, 'Ran 5 km without stopping');
    await tester.enterText(find.byKey(const Key('log-search')), 'without');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ran 5 km without stopping'), findsOneWidget);
  });

  testWidgets('hard moments: help first, writing is kept, saving still leaves',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/need');
    await _tap(tester, find.byKey(const Key('need-support')));
    expect(find.text('You don\'t have to carry this alone'), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet)), rootNavigator: true).pop();
    await _pumpFor(tester, const Duration(milliseconds: 600));
    // Step back: writing, then the back arrow asks first.
    await _go(tester, '/home');
    GoRouter.of(tester.element(find.byType(Navigator).first)).push('/stepback');
    await _pumpFor(tester, const Duration(milliseconds: 1200));
    await tester.enterText(find.byType(TextField).first, 'The review went badly');
    await tester.pump();
    await tester.tap(find.byType(OnoBackButton));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Keep writing'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.textContaining('Talk to'), findsWidgets);
    await _tap(tester, find.text('Done'));
    expect(system.logsOf('stepback').single.text, 'The review went badly');
    expect(find.text('Leave without saving?'), findsNothing);
    // A setback with all three priorities taken says so.
    final today = dayOnly(DateTime.now());
    for (var i = 0; i < 3; i++) {
      system.setPriority(today, i, 'P$i');
    }
    expect(system.logSetback(kind: '', happened: 'Missed it', nextStep: 'Walk at 7'), isFalse);
  });

  testWidgets('progress note: an ask after editing keeps the edits',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/note');
    final note = find.byKey(const Key('note-text'));
    await _reach(tester, note);
    await tester.enterText(note, 'My own words about the week.');
    await tester.pump();
    final ask = find.byType(TextField).first;
    await tester.enterText(ask, 'An intro to someone in design');
    await tester.pump();
    expect(tester.widget<TextField>(note).controller!.text,
        'My own words about the week.');
    await _tap(tester, find.byKey(const Key('note-rebuild')));
    expect(tester.widget<TextField>(note).controller!.text,
        contains('An intro to someone in design'));
    expect(system.logsOf('progress_note'), isEmpty);
  });

  testWidgets('partner: no answer until chosen, and a check-in can change',
      (tester) async {
    final system = await _start(tester);
    system.setPartner('Aysel Karimova',
        mine: 'Train three times', theirs: 'Write daily', weekday: 1);
    await _go(tester, '/partner');
    await _tap(tester, find.text('Record the check-in'));
    expect(system.partnerCheckinFor(DateTime.now()), isNull);
    await _tap(tester, find.text('Partly').first);
    await _tap(tester, find.text('Kept').last);
    await _tap(tester, find.text('Record the check-in'));
    expect(system.partnerCheckinFor(DateTime.now())!.str('mine'), 'partly');
    await _tap(tester, find.byKey(const Key('partner-change')));
    await _tap(tester, find.text('Missed').first);
    await _tap(tester, find.text('Record the check-in'));
    expect(system.partnerCheckinFor(DateTime.now())!.str('mine'), 'missed');
    expect(system.logsOf('partner_checkin').length, 1);
  });

  testWidgets('a password reset link opens the new password page, with a way out',
      (tester) async {
    final auth = MockAuthGateway();
    await _start(tester, auth: auth);
    await _go(tester, '/home');
    auth.emit(AuthChangeEvent.passwordRecovery);
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Choose a new password'), findsOneWidget);
    await _tap(tester, find.text('Not now — sign out'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Choose a new password'), findsNothing);
  });

  testWidgets('what you know about them: write it, save it, see what to ask',
      (tester) async {
    final system = await _start(tester);
    final p = system.addPerson('Aysel Karimova', role: 'Friend', every: 14);
    await _go(tester, '/know?id=${p.id}');
    expect(find.text('What you know about Aysel'), findsOneWidget);
    expect(find.byKey(const Key('know-next')), findsOneWidget);
    await _reach(tester, find.byKey(const Key('know-working_on')));
    await tester.enterText(find.byKey(const Key('know-working_on')), 'Her first marathon');
    await tester.pump();
    await _tap(tester, find.text('Save'));
    expect(system.knowAnswer(system.personById(p.id)!, 'working_on'), 'Her first marathon');
    expect(system.nextQuestionFor(system.personById(p.id)!)!.$1, 'weighing');
  });

  testWidgets('courage ladder: add a rung, climb it, rate how it felt',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/courage');
    await tester.enterText(find.byKey(const Key('courage-what')), 'Speak first in the meeting');
    await tester.pump();
    await _tap(tester, find.text('Add to the ladder'));
    expect(system.nextCourageStep!.text, 'Speak first in the meeting');
    await _tap(tester, find.byKey(const Key('courage-did')));
    await tester.tap(find.text('Save').last);
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(system.courageDone.single.str('status'), 'done');
    expect(system.courageDone.single.number('felt'), 5);
  });

  testWidgets('playbook: a lesson shows up, can be pinned and searched',
      (tester) async {
    final system = await _start(tester);
    system.logAar(event: 'The launch', improve: 'Rehearse the demo twice');
    system.logAar(event: 'Board meeting', improve: 'Send the memo a day early');
    await _go(tester, '/playbook');
    expect(find.text('Rehearse the demo twice'), findsOneWidget);
    final key = system.playbook().firstWhere((e) => e.text.startsWith('Send')).key;
    await _tap(tester, find.byKey(Key('pin-$key')));
    expect(system.playbook().first.text, 'Send the memo a day early');
    await tester.enterText(find.byType(TextField).first, 'demo');
    await tester.pump();
    expect(find.text('Send the memo a day early'), findsNothing);
    expect(find.text('Rehearse the demo twice'), findsOneWidget);
  });

  testWidgets('advice: save it, say how it went, then that you told them',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/advice');
    await tester.enterText(find.byKey(const Key('advice-text')), 'Send the agenda the day before');
    await _type(tester, 'From', 'Rashad');
    await _tap(tester, find.text('Save the advice'));
    final a = system.adviceLog.single;
    await _tap(tester, find.byKey(Key('advice-close-${a.id}')));
    await tester.enterText(find.byKey(const Key('advice-result')), 'Shorter meetings');
    await tester.tap(find.text('I tried it'));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(system.adviceToReport.single.str('result'), 'Shorter meetings');
    await _tap(tester, find.text('I told them'));
    expect(system.adviceToReport, isEmpty);
  });

  testWidgets('self-compassion break: name it, be kind, it is kept',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/compassion');
    await tester.enterText(find.byKey(const Key('compassion-hard')), 'I missed the deadline');
    await _reach(tester, find.byKey(const Key('compassion-kind')));
    await tester.enterText(find.byKey(const Key('compassion-kind')), 'You were stretched thin; ask for a day.');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    final l = system.logsOf('compassion').single;
    expect(l.text, 'I missed the deadline');
    expect(l.str('kind'), 'You were stretched thin; ask for a day.');
    expect(system.journalText(), contains('Was on my own side about: I missed the deadline'));
  });

  testWidgets('after a focus block: a walk break, logged as movement',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/focus');
    await _tap(tester, find.textContaining('Already did a'));
    await _reach(tester, find.byKey(const Key('focus-break')));
    await _tap(tester, find.text('I walked'));
    expect(system.movesInWeek(DateTime.now()).single.number('minutes'), 3);
    expect(find.byKey(const Key('focus-break')), findsNothing);
  });

  testWidgets('a routine: step through it, finishing ticks the item',
      (tester) async {
    final system = await _start(tester);
    final id = system.addDailyItem('Evening care', lane: 'body', when: 'evening')!.id;
    system.setSteps(id, const ['Brush your teeth', 'Wash your face']);
    await _go(tester, '/routine?id=$id');
    expect(find.text('Brush your teeth'), findsWidgets);
    await _tap(tester, find.byKey(const Key('routine-next')));
    await _tap(tester, find.byKey(const Key('routine-next')));
    expect(system.isChecked(system.logicalToday, id), isTrue);
  });

  testWidgets('in my care: their story on the know screen, care under their name',
      (tester) async {
    final system = await _start(tester);
    final mum = system.addPerson('Leyla Huseynova', role: 'Mother', every: 7);
    system.setInMyCare(mum, true);
    await _go(tester, '/know?id=${mum.id}');
    await _reach(tester, find.byKey(const Key('story-grew_up')));
    await tester.enterText(find.byKey(const Key('story-grew_up')), 'Sheki');
    await tester.pump();
    await _tap(tester, find.text('Save'));
    expect(system.storyAnswer(system.personById(mum.id)!, 'grew_up'), 'Sheki');
    await _go(tester, '/upkeep');
    await _tap(tester, find.byKey(Key('care-for-${mum.id}-Eye test')));
    expect(system.careFor(system.personById(mum.id)!).single.text, 'Leyla: Eye test');
  });

  testWidgets('negotiation: prepare it, then close it with a lesson',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/negotiate');
    await _tap(tester, find.byKey(const Key('negotiation-new')));
    await tester.enterText(find.byKey(const Key('negotiation-about')), 'My salary');
    await _type(tester, 'Your first offer', '20% more');
    await tester.tap(find.text('Save').last);
    await _pumpFor(tester, const Duration(milliseconds: 800));
    final l = system.negotiations.single;
    expect(l.str('first_offer'), '20% more');
    system.closeNegotiation(l.id, outcome: 'better', lesson: 'Ask for the range first');
    expect(system.playbook().any((e) => e.text == 'Ask for the range first'), isTrue);
  });

  testWidgets('rehearse: tick the parts that landed, it is saved',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/rehearse');
    expect(find.byKey(const Key('rehearse-question')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('star-Situation')));
    await _tap(tester, find.byKey(const Key('star-Result')));
    await _tap(tester, find.text('Save the rehearsal'));
    final l = system.logsOf('rehearsal').single;
    expect((l.data['star'] as List).toSet(), {'Situation', 'Result'});
  });

  testWidgets('Me: core tools and recently used ones show, the rest fold away',
      (tester) async {
    final system = await _start(tester);
    await _go(tester, '/profile');
    await _reach(tester, find.text('Goals'));
    expect(find.text('Courage ladder'), findsNothing);
    system.addCourageStep('Speak first in the meeting', fear: 6);
    await tester.pump(const Duration(milliseconds: 300));
    await _reach(tester, find.text('Courage ladder'));
    expect(find.text('Gratitude letter'), findsNothing);
    await _tap(tester, find.byKey(const Key('me-more-people')));
    await _reach(tester, find.text('Gratitude letter'));
    expect(system.isDone('me:more:people'), isTrue);
  });
}

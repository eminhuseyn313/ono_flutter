import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/main.dart';
import 'package:ono/data/daily_library.dart';
import 'package:ono/data/emin_system.dart';
import 'package:ono/data/growth_templates.dart';
import 'package:ono/data/life_wheel.dart';
import 'package:ono/data/plan_packs.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/router.dart';
import 'package:ono/screens/plan_builder_screen.dart';
import 'package:ono/screens/need_screen.dart';
import 'package:ono/services/calendar_service.dart';
import 'package:ono/services/reminder_service.dart';

import 'support/fake_calendar.dart';
import 'support/fake_health.dart';

/// The app has looping animations (dial needle, timers), so these tests
/// pump fixed durations instead of `pumpAndSettle`.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

Widget _app() => OnoApp(
      authGateway: MockAuthGateway(),
      personalGateway: MockPersonalSystemGateway(),
      reminders: NoopReminderService(),
      health: FakeHealthService(),
      calendar: _calendar(),
    );

/// A long meeting title, a key meeting and one over the 12:00 read, so
/// Today's Meetings card renders every state.
FakeCalendarService _calendar() {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day);
  final soon = now.add(const Duration(minutes: 5));
  return FakeCalendarService(meetings: [
    Meeting(
        id: 'noon',
        title: 'Business ID weekly sync',
        start: d.add(const Duration(hours: 12)),
        end: d.add(const Duration(hours: 13)),
        attendees: const ['Leyla', 'Tural', 'Nigar']),
    Meeting(
        id: 'ali',
        title: '1:1 Ali — pricing proposal for agent permissions and KYC v2 roadmap',
        start: soon,
        end: soon.add(const Duration(minutes: 45)),
        attendees: const ['Ali Mammadov', 'Emin Huseynzade']),
  ]);
}

/// Collects every runtime error, layout overflow included. Fonts are
/// bundled in assets/google_fonts, so text is measured with the real fonts.
/// Call [_restoreErrors] before any `expect`, or a failure wedges the runner.
FlutterExceptionHandler? _previousOnError;
void _restoreErrors() => FlutterError.onError = _previousOnError;

List<String> _captureErrors(WidgetTester tester) {
  final errors = <String>[];
  final previous = _previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final where = RegExp(r'lib/[\w/]+\.dart:\d+')
        .firstMatch(details.toString())
        ?.group(0);
    final what = details.exceptionAsString().split('\n').first;
    errors.add(where == null ? what : '$what ($where)');
  };
  addTearDown(() => FlutterError.onError = previous);
  return errors;
}

Future<void> _go(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  // Sheets open above the tabs (root navigator): close them first, as a
  // person would before going somewhere else.
  Navigator.of(ctx, rootNavigator: true).popUntil((r) => r is! PopupRoute);
  await tester.pump(const Duration(milliseconds: 400));
  GoRouter.of(ctx).go(route);
  await _pumpFor(tester, const Duration(milliseconds: 1500));
}

/// Text drawn under the status bar / Dynamic Island (hidden on a real iPhone).
List<String> _underStatusBar(double topInset) {
  final out = <String>[];
  for (final e in find.byType(RichText).evaluate()) {
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;
    final r = box.localToGlobal(Offset.zero) & box.size;
    if (r.top < topInset - 0.5 && r.bottom > 0) {
      final text = (e.widget as RichText).text.toPlainText();
      out.add(
          'under status bar: "${text.length > 30 ? text.substring(0, 30) : text}" at y=${r.top.toStringAsFixed(0)}');
    }
  }
  return out;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first run: welcome, then the plan builder after sign-in',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final errors = _captureErrors(tester);

    await tester.pumpWidget(_app());
    await _pumpFor(tester, const Duration(seconds: 3));
    final sawWelcome = find.text('Begin').evaluate().isNotEmpty;

    final ctx = tester.element(find.byType(Scaffold).first);
    await Provider.of<AuthProvider>(ctx, listen: false)
        .signIn(email: 'emin@test.dev', password: 'password');
    await _pumpFor(tester, const Duration(seconds: 2));
    await _go(tester, '/home');

    // Not set up yet → Today sends them to the plan builder.
    final onBuilder = find.byType(PlanBuilderScreen).evaluate().isNotEmpty;

    // A new person builds a plan and lands on Today, set up.
    final steps = <String>[];
    var commissioned = false;
    try {
      Future<void> next(String label) async {
        await tester.tap(find.text(label));
        await _pumpFor(tester, const Duration(milliseconds: 600));
      }
      await tester.enterText(
          find.widgetWithText(TextField, 'Your name'), 'Leyla Mammadova');
      await tester.enterText(find.widgetWithText(TextField, 'Who you want to become'),
          'Head nurse');
      await next('Next');
      for (final a in lifeAreas) {
        final s = find.byKey(Key('plan-wheel-${a.id}'));
        await tester.ensureVisible(s);
        await tester.tap(s);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await next('Next');
      await tester.tap(find.text(areaTemplates.first.name).first);
      await tester.pump(const Duration(milliseconds: 200));
      await next('Next');
      steps.add('goal');
      await next('Next');
      for (final d in dailyLibrary.take(3)) {
        final row = find.text(d.title);
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await next('Build my plan');
      await _pumpFor(tester, const Duration(seconds: 2));
      final system = Provider.of<PersonalSystemProvider>(
          tester.element(find.byType(Navigator).first),
          listen: false);
      commissioned = system.isCommissioned && system.dailyCount == 3;
      system.resetProfile();
    } catch (e) {
      steps.add('$e');
    }
    _restoreErrors();
    expect([sawWelcome, onBuilder, steps, commissioned, errors],
        [true, true, ['goal'], true, isEmpty]);
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  // iPhone 15/16 (393×852) and iPhone SE (375×667), both @3x.
  for (final size in const [Size(1179, 2556), Size(1125, 2001)]) {
    testWidgets(
        'every route renders without errors once commissioned '
        '(${size.width ~/ 3}×${size.height ~/ 3})', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3;
      // Real insets: Dynamic Island + home indicator vs. SE status bar.
      final notch = size.height > 2200;
      final topInset = notch ? 59.0 : 20.0;
      final insets =
          FakeViewPadding(top: topInset * 3, bottom: notch ? 34 * 3 : 0);
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
      addTearDown(tester.view.reset);
      final errors = _captureErrors(tester);

      await tester.pumpWidget(_app());
      await _pumpFor(tester, const Duration(seconds: 3));

      final ctx = tester.element(find.byType(Scaffold).first);
      await Provider.of<AuthProvider>(ctx, listen: false)
          .signIn(email: 'emin@test.dev', password: 'password');
      await _pumpFor(tester, const Duration(seconds: 2));

      final system = Provider.of<PersonalSystemProvider>(
          tester.element(find.byType(Navigator).first),
          listen: false);
      await system.commission(
        start: dayOnly(DateTime.now()).minusDays(40),
        gymDays: const [1, 3, 5],
        weightKg: 82,
        reminders: const {},
      );
      // A little history so charts and logs have something to draw.
      system.logWeight(81.4);
      system.addProtein(DateTime.now(), 60);
      system.toggleCheck(DateTime.now(), 'manifesto');
      // Flagged shoulders today and yesterday: Today, the gym screen and
      // Me render their shoulder-sparing / Mornings states. Yesterday is
      // unheld, so Today also shows the recovery card.
      final today = dayOnly(DateTime.now());
      system.saveCheckin(today,
          energy: 2, mood: -1, sleep: 6, pain: 6, stiffness: 3);
      system.saveCheckin(today.minusDays(1),
          energy: 3, mood: 0, sleep: 7.5, pain: 4, stiffness: 3);
      system.saveCheckin(today.minusDays(2),
          energy: 4, mood: 1, sleep: 8, pain: 2, stiffness: 0);
      // Three weeks of caffeine cut-offs and sleep: Me shows a pattern.
      for (var i = 3; i <= 24; i++) {
        final d = today.minusDays(i);
        if (i.isEven) system.setCheck(d, 'caffeine', true);
        system.saveCheckin(d,
            energy: 3,
            mood: 0,
            sleep: i.isOdd ? 7.5 : 6,
            pain: 1,
            stiffness: 0);
      }
      system.setCue(
          'bed',
          'When the 22:00 alarm rings → phone stays in the hall, '
              'charger by the front door, book on the pillow instead');
      // Career cockpit, deck and habit state, so their screens and Today's
      // prompt cards render with real content.
      system.addOneOnOne(
          withWhom: 'Ali',
          decided: 'Business ID pricing goes to the board in November',
          followUps: [
            'Draft the PR/FAQ for agent permissions and share it with Rustam',
            'Book the review'
          ]);
      system.clock = () => DateTime.now().minusDays(95);
      system.addDecision(
          decision: 'Ship KYC v2 without the video step',
          options: 'Ship now / wait for the vendor fix',
          why: 'Drop-off at the video step is 38%',
          expected: 'Completion up 15 points within a month');
      system.clock = DateTime.now;
      system.saveReadiness(
          {for (final d in readinessDimensions) d.id: 4, 'strategy': 2});
      system.logProtocolUse('feynman',
          text: 'Opportunity solution trees map one outcome to opportunities '
              'and experiments.',
          data: {'book': 'Continuous Discovery Habits', 'chapter': 'Ch. 3'});
      system.addCustomCard('Kaspi QR acceptance?', '95% of merchants');
      for (var i = 1; i <= 30; i++) {
        system.setCheck(today.minusDays(i), 'bed', true);
      }
      system.saveAutomaticity({for (final n in nonNegotiables) n.id: 5});
      await system.connectHealth();
      await system.connectCalendar();
      // A letter that opened today and one sealed until day 540, plus a
      // deep-work block, so Today, /letters and /focus render them.
      system.clock = () => DateTime.now().minusDays(30);
      system.writeLetter('Remember why you started: the room at PASHA where '
          'you decided to stop waiting to be noticed.', today);
      system.clock = DateTime.now;
      system.writeLetter('Day 540.', system.programEnd);
      system.logFocus(90, 'artifact');
      // A Big 3 with a long outcome, and people: one due, one fresh.
      system.setWeekOutcome(today, 0,
          'Opportunity solution tree for entrepreneur integration reviewed by Ali and Rustam');
      system.setWeekOutcome(today, 1, 'KYC v2 scope signed off');
      system.toggleWeekOutcome(today, 1);
      system.clock = () => DateTime.now().minusDays(40);
      system.addPerson('Leyla Aliyeva-Huseynova',
          role: 'Head of Product, Kapital Bank — one role ahead', every: 30);
      system.clock = DateTime.now;
      final ali = system.addPerson('Ali', role: 'Manager', every: 7);
      system.setRitual(system.people.firstWhere((x) => x.id == ali.id),
          'Thursday walk-and-talk after the steering meeting, no laptops');
      system.logTouch(system.people.firstWhere((x) => x.id == ali.id), quality: 3);
      // Last month's growth area only: this month /growth shows the chooser
      // and Today the "what are you growing" prompt.
      system.clock = () => DateTime.now().minusDays(35);
      system.setFocus('self_trust', startRating: 2);
      system.clock = DateTime.now;
      // One area of his own, so the chooser shows "Your own areas" and the
      // editor has something to edit.
      system.saveCustomArea(const GrowthArea('', 'Being present at home with my wife',
          bar: 'Phone away from 20:30; dinner is a conversation, not logistics.',
          ask: 'What would make you feel more supported this month?',
          personal: true,
          drills: [
            Drill('Phone-free dinner', 'Both phones in another room at dinner.',
                'You talked about something other than logistics.'),
          ]));
      // Goals: one numeric with measurements, one with milestones.
      final run = system.saveGoal(
          title: 'Run a half marathon under 1 hour 50 minutes, without aggravating my shoulders',
          why: 'Prove I can train seriously alongside a demanding job',
          obstacle: 'I skip runs when work runs late',
          plan: 'If work runs late, then I run at 6:30 the next morning',
          identity: 'I am someone who trains in any week',
          deadline: today.plusDays(120),
          unit: 'min',
          start: 125,
          target: 109)!;
      system.logGoalValue(run.id, 121, date: today.minusDays(10));
      system.logGoalValue(run.id, 118);
      final roleGoal = system.saveGoal(
          title: 'Become ${activeProfile.targetRole}',
          deadline: today.plusDays(270),
          milestones: ['Own one area end to end', 'Promotion conversation']);
      // The first Big 3 outcome serves the long-titled running goal.
      system.setWeekOutcomeGoal(today, 0, run.id);
      // Learning in every state: next, now, applied with an open experiment.
      system.addLearning('Thinking in Bets — making better decisions when you don\'t have all the facts',
          by: 'Annie Duke');
      final now = system.addLearning('The Effective Executive', by: 'Peter Drucker')!;
      system.startLearning(now.id);
      final done = system.addLearning('Continuous Discovery Habits', kind: 'Course')!;
      system.applyLearning(done.id,
          principle: 'Talk to a customer every week, not every quarter — small, often, together',
          experiment: 'Two customer interviews before Friday, with the designer in the room');
      // A running experiment watching energy (check-ins are seeded above).
      system.startExperiment(
          change: 'No screens after 22:00, phone charging in the hall',
          measure: 'energy',
          days: 14,
          expect: 'Falling asleep faster and more morning energy');
      // Stop-doing, a gratitude letter and a role model, in every state.
      final stop = system.addStop('Checking email before 9:00 and between meetings',
          makesRoomFor: 'An hour of deep work on the artifact every morning')!;
      system.setStopHeld(stop.id, today, true);
      final letter = system.writeGratitude('My first manager',
          'You gave me the hard project when nobody else would, and it made me.')!;
      system.deliverGratitude(letter.id, reaction: 'Called me back the same evening');
      system.writeGratitude('Mum', 'Thank you for every morning you drove me to school.');
      final model = system.addRoleModel('A CPO one step ahead',
          learn: 'How she says no to the CEO without losing trust',
          question: 'How do you decide what not to build?')!;
      system.answerRoleModel(model.id, 'Write the trade-off down before the meeting');
      // A feedback round with one answer in and a theme.
      final round = system.startRound(['Ali', 'Leyla Aliyeva-Huseynova']);
      system.addRoundAnswer(round.id, 'Ali',
          'Keep writing decisions down first. Change: decide in the room instead of after it.');
      // Energy ratings: mornings clearly ahead of afternoons.
      for (var i = 0; i < 3; i++) {
        system.addLog('energy',
            date: DateTime.now().minusDays(i + 1),
            data: {'level': 5, 'hour': 10});
        system.addLog('energy',
            date: DateTime.now().minusDays(i + 1),
            data: {'level': 2, 'hour': 15});
      }
      // Direction tools with long text, so their screens render filled.
      system.saveOdyssey([
        {'title': 'Lead product for a regional fintech platform', 'story': 'Long days, big team', 'like': 4},
        {'title': 'Teach product management at a university'},
        {'title': 'Start a company with two friends'},
      ], leaning: 0, prototype: 'Coffee with a CPO');
      system.saveEnergyAudit([
        (name: 'Weekly status meeting with stakeholders', energy: -2),
        (name: 'Customer interviews', energy: 2),
      ], craftActivity: 'Weekly status meeting with stakeholders', craftMove: 'reshape', craftHow: 'Send a written update and cancel the meeting twice a month');
      system.addBestSelfStory('Leyla', 'You calmed the room when the launch failed and gave everyone one clear next step.');
      system.addBestSelfStory('Tural', 'You explained the plan so everyone got it.');
      system.saveBestSelfPortrait(themes: 'Calm, clarity', portrait: 'When I\'m at my best, I make hard things clear and keep people calm.');
      // Someone they're helping grow, with a long focus.
      final mentee = system.addPerson('Nigar Hasanova-Mammadli', role: 'Team', every: 14);
      system.setGrowing(mentee,
          workingOn: 'Presenting research to the leadership team with confidence',
          nextHelp: 'Rehearse the first three minutes together on Thursday');
      // Health upkeep: one overdue, one never done.
      system.addUpkeep('Dentist check-up and cleaning', 180,
          lastDone: DateTime.now().minusDays(220));
      system.addUpkeep('Blood tests', 180);
      // Inner tools with long text: a thought check, a best future, kindness,
      // parked worries with a slot already passed, and life chapters.
      system.logThought(
          situation: 'The quarterly review with the whole leadership team',
          thought: 'Everyone in that room thinks I am not ready for the bigger role',
          feeling: 'Anxious', before: 85, balanced: 'Two hard questions are not a verdict on me', after: 45);
      system.logThought(situation: 'Call', thought: 'I will fail', before: 70, after: 50);
      system.saveBestFuture(years: 3, areas: {
        'work': 'I lead a product group that customers love and my team grows faster than I do.',
        'people': 'Sunday dinners with the whole family, phones away, every week.',
      }, step: 'Ask for the stretch project');
      system.setKindnessDay(DateTime.now().weekday);
      system.logKindness('Brought coffee for the whole support team and thanked each of them by name');
      system.setWorryTime(0);
      system.parkWorry('Whether the budget for next year will cover the second hire we promised the team');
      system.parkWorry('Mum\'s appointment');
      system.saveLifeStory(chapters: [
        {'title': 'Leaving home for university in another country', 'years': '2012–2016', 'taught': 'I can start over'},
        {'title': 'First team', 'years': '2017–2021'},
      ], now: 'Learning to lead', next: 'Leading a product group');
      // Strengths, a board with gaps, and an after-action review.
      system.setSignatureStrengths(['Appreciation of beauty', 'Social intelligence', 'Love of learning', 'Perseverance', 'Hope']);
      system.logStrengthUse('Hope', 'Told the team three ways the launch could go right, before the risks');
      final boardPerson = system.addPerson('Aysel Rahimova-Guliyeva', role: 'Former manager', every: 60);
      system.setBoardRoles(boardPerson, ['mentor', 'sponsor', 'challenger']);
      system.logAar(event: 'The quarterly presentation to the whole leadership team',
          sustain: 'The one-page summary', improve: 'Rehearse the Q&A out loud with someone who pushes back');
      // An overdue promise and a story with long text.
      system.addLog('ask', date: DateTime.now().minusDays(3), text: 'Cover the Thursday stand-up while I am at the clinic', data: {'of': 'A colleague', 'guess': 40, 'status': 'asked'});
      system.addAsk(what: 'Thirty minutes to rehearse the board presentation with honest questions', of: 'Aysel Rahimova-Guliyeva', guess: 35);
      system.saveYearReview(DateTime.now().year - 1, answers: {'proud': 'Showing up on the hard mornings'}, word: 'Steady');
      system.addPromise(what: 'Send the revised pricing proposal with the three options and the risks', to: 'Aysel Rahimova-Guliyeva', by: DateTime.now().minusDays(2));
      system.saveStory(title: 'Turning around a launch that was two weeks late with a team that had lost faith',
          situation: 'Two weeks late', action: 'Cut scope with the team', result: 'Shipped in nine days',
          skills: ['Delivering under pressure', 'Leading people', 'A hard decision']);
      // A money check-in with large numbers.
      system.saveMoneyCheck(income: 12500000, spent: 9800000, savings: 32000000,
          decision: 'Move the gym membership to the annual plan and cancel two streaming services');
      // A hard conversation due today.
      system.saveConversation(
          withWhom: 'Samira Abdullayeva-Karimova',
          about: 'The last three missed deadlines on the onboarding project',
          opening: 'I want to talk about the last three deadlines, because I think we see them differently.',
          by: DateTime.now());
      // An accountability pact with a long commitment on each side.
      system.setPartner('Samira Abdullayeva-Karimova',
          mine: 'Three strength sessions and one long walk every single week',
          theirs: 'Write five hundred words every morning before work',
          weekday: DateTime.now().weekday);
      // Sick the day before yesterday: yesterday is the first day back.
      system.setHardDay(
          dayOnly(DateTime.now()).minusDays(2), 'sick');
      // One daily item of his own: 11 items, 8 hold the day.
      system.addDailyItem('Ten minutes of Spanish before dinner, with the app',
          lane: 'skill', when: 'evening', cue: 'When I sit down at home → app open');
      // A self-coaching commitment due today: Today and /coach show it.
      system.logCoaching(
          goal: 'Be seen as the owner of Business ID onboarding end to end',
          reality: 'Ali hands it over piece by piece',
          options: ['Ask directly in the 1:1', 'Write an ownership proposal'],
          will: 'Send Ali a one-page ownership proposal before Thursday\'s 1:1',
          by: today,
          commitment: 8);
      await _pumpFor(tester, const Duration(milliseconds: 500));

      final routes = <String>{
        ...appRoutes,
        '/program?tab=1',
        '/program?tab=2',
        '/program?tab=3',
        '/gym/push',
        '/gym/pull',
        '/gym/legs',
        '/month/2',
        '/month/7',
        '/month/18',
        '/tool/artifact?month=3',
        '/log?add=weight',
        '/log?add=protein',
        '/log?add=win',
        '/log?add=note',
        '/log?add=blood',
        // Every link the content points at.
        for (final n in nonNegotiables)
          if (n.route != null) n.route!,
        for (final r in reminderDefs) r.route,
        for (var m = 1; m <= programMonths; m++)
          for (final u in unlocksFor(m))
            if (u.route != null) u.route!,
        ...NeedScreen.routes,
      };

      final failures = <String, Set<String>>{};
      for (final route in routes) {
        errors.clear();
        final router =
            GoRouter.of(tester.element(find.byType(Navigator).first));
        final match = router.configuration.findMatch(route);
        if (match.isError || match.matches.isEmpty) {
          failures[route] = {'no such route'};
          continue;
        }
        await _go(tester, route);
        // /models opens scrolled to its section, so text has already
        // scrolled up under the bar, as on any scrolled page.
        if (route != '/models') errors.addAll(_underStatusBar(topInset));
        if (errors.isNotEmpty) failures[route] = errors.toSet();
      }

      // Review: revealing the answer shows compact grade buttons (they once
      // stretched to fill the screen and hid the card).
      await _go(tester, '/review');
      await tester.tap(find.text('Show answer'));
      await _pumpFor(tester, const Duration(milliseconds: 400));
      final good = tester.getRect(find
          .ancestor(of: find.text('Good'), matching: find.byType(InkWell))
          .first);
      if (good.height > 120) {
        failures['/review'] = {'grade buttons ${good.height.round()} pt tall'};
      }

      // Gym: ticking a set starts the rest timer above Finish session.
      // A throw here would skip _restoreErrors and wedge the runner.
      errors.clear();
      try {
        await _go(tester, '/gym/push');
        final setDone = find.byWidgetPredicate((w) =>
            w is IconButton &&
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('set-'));
        await tester.ensureVisible(setDone.first);
        await tester.tap(setDone.first);
        await _pumpFor(tester, const Duration(seconds: 1));
        if (find.byKey(const Key('rest-timer')).evaluate().isEmpty) {
          errors.add('rest timer did not start');
        }
        await tester.tap(find.text('Skip'));
        await _pumpFor(tester, const Duration(milliseconds: 300));
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/gym/push rest'] = errors.toSet();

      // Today starts calm: "Your plan" collapsed. Opened, it shows the
      // calendar's meetings with six-questions prep for the key one.
      errors.clear();
      try {
        system.setDone('today:plan_open', false);
        await _go(tester, '/home');
        final prep = find.text('6 Qs', skipOffstage: false);
        if (prep.evaluate().isNotEmpty) errors.add('plan should start collapsed');
        system.setDone('today:plan_open', true);
        await _pumpFor(tester, const Duration(milliseconds: 500));
        for (var i = 0; i < 25 && find.text('6 Qs').evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (find.text('6 Qs').evaluate().isEmpty) errors.add('no meetings card');
        // The rest of the plan scrolls into view without layout errors.
        for (var i = 0; i < 15; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pump(const Duration(milliseconds: 100));
        }
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/home plan'] = errors.toSet();

      // Growth plan with an area, a rep and feedback: the plan view renders.
      errors.clear();
      try {
        system.setFocus('communication', startRating: 2);
        final area = system.focusArea()!;
        system.logRep(area, area.drills.first,
            did: 'Rewrote the KYC v2 status note for Ali as BLUF',
            noticed: 'He replied in four minutes instead of the next day',
            lesson: 'Decision first means he can answer from his phone',
            next: 'Draft every update to Ali as BLUF before anything else');
        system.logFeedback(area,
            from: 'Ali',
            said: 'Lead with the decision you need from me, not the history',
            action: 'First line of every update is the ask');
        await _go(tester, '/growth');
        if (find.text('This week\'s practice').evaluate().isEmpty) {
          errors.add('plan view did not render');
        }
        await _go(tester, '/home');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/growth plan'] = errors.toSet();

      // Values: the picker rendered in the route loop; with values saved,
      // the list, affirmation and weekly check render.
      errors.clear();
      try {
        system.setValues([
          (name: 'Craft', meaning: 'Build things that outlast the meeting'),
          (name: 'Family', meaning: 'Home is the reason, not the reward'),
          (name: 'Courage', meaning: 'Say the true thing in the room, calmly'),
        ]);
        system.saveValuesCheck(today, {'Craft': 4, 'Family': 5});
        await _go(tester, '/values');
        await tester.tap(find.textContaining('Affirm before a hard moment'));
        await _pumpFor(tester, const Duration(milliseconds: 800));
        if (find.text('Why it matters').evaluate().isEmpty) {
          errors.add('affirmation did not open');
        }
        await _go(tester, '/home');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/values saved'] = errors.toSet();

      // Goal detail pages, numeric and milestones.
      errors.clear();
      try {
        await _go(tester, '/goals/view?id=${run.id}');
        if (find.byKey(const Key('goal-next')).evaluate().isEmpty) {
          errors.add('numeric goal did not render');
        }
        await tester.scrollUntilVisible(find.text('In the way, and your plan'), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.pump(const Duration(milliseconds: 200));
        await _go(tester, '/goals/view?id=${roleGoal!.id}');
        await _go(tester, '/goals/edit?id=${run.id}');
        // A closed goal asks to look back, then shows the reflection.
        final done = system.saveGoal(title: 'Read twelve books this year')!;
        system.setGoalStatus(done.id, 'achieved');
        await _go(tester, '/goals/view?id=${done.id}');
        if (find.text('Look back').evaluate().isEmpty) errors.add('no look-back on a closed goal');
        system.reflectOnGoal(done.id,
            whatWorked: 'Twenty pages every night before the phone, and a list of the next three books ready.',
            advice: 'Start with short books.');
        await _go(tester, '/goals/view?id=${done.id}');
        if (find.text('What made it happen').evaluate().isEmpty) errors.add('reflection not shown');
        await _go(tester, '/home');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/goals/view'] = errors.toSet();

      // A planned rest day today: Today shows the rest card.
      errors.clear();
      try {
        final rest = system.planRest('day', today, today,
            note: 'Family day — long walk, no laptop, phone in the drawer')!;
        await _go(tester, '/home');
        final card = find.textContaining('Rest is part of the plan');
        for (var i = 0; i < 10 && card.evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (card.evaluate().isEmpty) {
          errors.add('no rest card');
        }
        system.removeRest(rest.id);
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['rest day'] = errors.toSet();

      // Someone else entirely: a runner with no organisation and one coach.
      // Today, Me, goals, the note and the editor must still render.
      errors.clear();
      try {
        system.saveProfile(builtInProfile.copyWith(
          name: 'Leyla Mammadova',
          firstName: 'Leyla',
          currentRole: 'Amateur runner',
          targetRole: 'Sub-3 marathoner',
          organisation: '',
          focus: '',
          location: '',
          archetype: 'The Comeback Athlete',
          keyPeople: const [KeyPerson('Tural', 'Coach', every: 7, primary: true)],
        ));
        system.saveDayShape(wake: 390, workStart: 480, workEnd: 1020, bed: 1350);
        // A short program: the spine, phases and months scale to 90 days.
        system.setProgramLength(90);
        for (final r in ['/home', '/profile', '/goals', '/note', '/profile/edit', '/career', '/people', '/program', '/checkin', '/growth', '/move', '/log', '/weekly-coaching', '/day', '/evidence', '/month/2', '/next-program', '/letters', '/week', '/focus', '/shutdown', '/review', '/learning', '/tool/feynman', '/cockpit', '/cockpit?tab=2']) {
          await _go(tester, r);
          // 1:1s and decisions keep what was logged, but never his
          // readiness bar (his employer, his managers).
          if (r.startsWith('/cockpit')) {
            for (final t in ['Readiness', 'Career cockpit', 'Ali and Rustam']) {
              if (find.textContaining(t).evaluate().isNotEmpty) {
                errors.add('$r shows "$t"');
              }
            }
            continue;
          }
          // His career page and month pages are only linked for him, and
          // the Log shows what was logged before the profile changed.
          if (const {'/career', '/log', '/month/2'}.contains(r)) continue;
          // None of the built-in plan's specifics show for someone else.
          // (Their daily items are the built-in ones here, so item titles
          // may appear; the built-in cards and strips must not.)
          for (final t in ['Shoulder pain', 'Desk at 07:45', 'Face pulls', 'Lunch read', 'LinkedIn posts', 'Gym sessions', 'Scan · 07:45', 'Guavapay', 'Day 16', 'on the artifact', 'move the artifact', 'Business ID', 'Kaspi', '21:30', 'bed by 22:30', 'readiness', 'sleep, shoulders', 'navy merino', 'this month\'s book', currentBook(system.programMonth).title]) {
            if (find.textContaining(t).evaluate().isNotEmpty) {
              errors.add('$r shows "$t"');
            }
          }
        }
        await _go(tester, '/profile');
        if (find.textContaining('Leyla').evaluate().isEmpty) {
          errors.add('edited profile not shown');
        }
        system.resetProfile();
        await _go(tester, '/home');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['other profile'] = errors.toSet();

      // Plan builder: every step renders and fits.
      errors.clear();
      try {
        system.addLog('wheel', data: {
          'wheel': {for (final a in lifeAreas) a.id: a.id == 'money' ? 3 : 7}
        });
        await _go(tester, '/start');
        Future<void> next() async {
          await tester.tap(find.text('Next'));
          await _pumpFor(tester, const Duration(milliseconds: 600));
        }
        await next();
        await next();
        await tester.tap(find
            .text(areaTemplates.firstWhere((t) => t.id == 't_money').name)
            .first);
        await _pumpFor(tester, const Duration(milliseconds: 300));
        await next();
        if (find.text('One goal that matters').evaluate().isEmpty) {
          errors.add('stuck before the goal step');
        }
        await next();
        if (find.text('Build my plan').evaluate().isEmpty) {
          errors.add('did not reach the daily step');
        }
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/start steps'] = errors.toSet();

      // Hard days: the sheet opens, and a minimum day shows its card.
      errors.clear();
      try {
        await _go(tester, '/home');
        final link = find.text('Hard day? Choose how today counts');
        for (var i = 0; i < 30 && link.evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.ensureVisible(link);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(link);
        await _pumpFor(tester, const Duration(milliseconds: 800));
        await tester.tap(find.text('Minimum day').last);
        await _pumpFor(tester, const Duration(milliseconds: 600));
        if (system.hardDayOn(DateTime.now()) != 'minimum') {
          errors.add('minimum day not set from the sheet');
        }
        final card = find.textContaining('smallest version of each item counts');
        for (var i = 0; i < 30 && card.evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, 300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (card.evaluate().isEmpty) errors.add('minimum day card not shown');
        system.setHardDay(DateTime.now(), null);
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['hard days'] = errors.toSet();

      // Hard conversations: the editor renders and fits.
      errors.clear();
      try {
        await _go(tester, '/conversations');
        await tester.tap(find.text('Prepare a conversation'));
        await _pumpFor(tester, const Duration(milliseconds: 800));
        if (find.text('Prepare it').evaluate().isEmpty) errors.add('editor did not open');
        Navigator.of(tester.element(find.text('Prepare it'))).pop();
        await _pumpFor(tester, const Duration(milliseconds: 500));
        await tester.tap(find.textContaining('With Samira').first);
        await _pumpFor(tester, const Duration(milliseconds: 800));
        Navigator.of(tester.element(find.textContaining('With Samira').first)).pop();
        await _pumpFor(tester, const Duration(milliseconds: 500));
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/conversations editor'] = errors.toSet();

      // Decide: options with long names render the values grid.
      errors.clear();
      try {
        await _go(tester, '/decide');
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(1), 'Accept the regional product lead role in another city');
        await tester.enterText(fields.at(2), 'Stay and grow the current team for another year');
        await _pumpFor(tester, const Duration(milliseconds: 500));
        final choose = find.text('Choose this');
        for (var i = 0; i < 20 && choose.evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (choose.evaluate().isEmpty) errors.add('values grid not shown');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/decide grid'] = errors.toSet();

      // Plan packs: a pack's preview sheet renders and fits.
      errors.clear();
      try {
        await _go(tester, '/packs');
        await tester.tap(find.text(planPacks.first.name));
        await _pumpFor(tester, const Duration(milliseconds: 800));
        final title = find.text(planPacks.first.name);
        if (title.evaluate().length < 2) {
          errors.add('pack preview did not open');
        } else {
          Navigator.of(tester.element(title.last)).pop();
        }
        await _pumpFor(tester, const Duration(milliseconds: 500));
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/packs preview'] = errors.toSet();

      // Me: the seeded caffeine cut-offs show as a pattern.
      await _go(tester, '/profile');
      final me = find.textContaining('No caffeine after 1pm →');
      for (var i = 0; i < 30 && me.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (me.evaluate().isEmpty) failures['/profile'] = {'no pattern shown'};

      _restoreErrors();
      expect(failures, isEmpty,
          reason: failures.entries
              .map((e) => 'FAIL ${e.key}: ${e.value.join(' | ')}')
              .join('\n'));
    });
  }
}

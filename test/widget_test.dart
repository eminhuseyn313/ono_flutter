import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/main.dart';
import 'package:ono/data/emin_system.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/router.dart';
import 'package:ono/screens/commission_screen.dart';
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

  testWidgets('first run: welcome, then commission after sign-in',
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

    // Not commissioned yet → Today sends him to the commission.
    _restoreErrors();
    expect(sawWelcome, isTrue);
    expect(find.byType(CommissionScreen), findsOneWidget);
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
        start: dayOnly(DateTime.now()).subtract(const Duration(days: 40)),
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
      system.saveCheckin(today.subtract(const Duration(days: 1)),
          energy: 3, mood: 0, sleep: 7.5, pain: 4, stiffness: 3);
      system.saveCheckin(today.subtract(const Duration(days: 2)),
          energy: 4, mood: 1, sleep: 8, pain: 2, stiffness: 0);
      // Three weeks of caffeine cut-offs and sleep: Me shows a pattern.
      for (var i = 3; i <= 24; i++) {
        final d = today.subtract(Duration(days: i));
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
      system.clock = () => DateTime.now().subtract(const Duration(days: 95));
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
        system.setCheck(today.subtract(Duration(days: i)), 'bed', true);
      }
      system.saveAutomaticity({for (final n in nonNegotiables) n.id: 5});
      await system.connectHealth();
      await system.connectCalendar();
      // A letter that opened today and one sealed until day 540, plus a
      // deep-work block, so Today, /letters and /focus render them.
      system.clock = () => DateTime.now().subtract(const Duration(days: 30));
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
      system.clock = () => DateTime.now().subtract(const Duration(days: 40));
      system.addPerson('Leyla Aliyeva-Huseynova',
          role: 'Head of Product, Kapital Bank — one role ahead', every: 30);
      system.clock = DateTime.now;
      system.addPerson('Ali', role: 'Manager', every: 7);
      // Last month's growth area only: this month /growth shows the chooser
      // and Today the "what are you growing" prompt.
      system.clock = () => DateTime.now().subtract(const Duration(days: 35));
      system.setFocus('self_trust', startRating: 2);
      system.clock = DateTime.now;
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
        errors.addAll(_underStatusBar(topInset));
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

      // Today: the calendar's meetings, the key one with six-questions prep.
      await _go(tester, '/home');
      final prep = find.text('6 Qs');
      for (var i = 0; i < 20 && prep.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (prep.evaluate().isEmpty) failures['/home meetings'] = {'no meetings card'};

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
        if (find.text('This week\'s drill').evaluate().isEmpty) {
          errors.add('plan view did not render');
        }
        await _go(tester, '/home');
      } catch (e) {
        errors.add('$e');
      }
      if (errors.isNotEmpty) failures['/growth plan'] = errors.toSet();

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

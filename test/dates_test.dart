import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/data/emin_system.dart';
import 'package:ono/main.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/time.dart';

import 'support/fake_health.dart';

/// Today, the week, the Sunday report and the rest change with the day and
/// the hour. Render them at moments that have broken apps before: a Sunday
/// evening, the night clocks go back, the small hours, New Year's Eve, the
/// year-review season and a leap day — for the built-in plan and for
/// someone else's. Run with TZ=Europe/Berlin too, so the clock change is real.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

final _moments = {
  'Sunday evening': DateTime(2026, 10, 18, 19, 30),
  'clocks go back, 02:30': DateTime(2026, 10, 25, 2, 30),
  'clocks went back, Sunday noon': DateTime(2026, 10, 25, 12),
  'Monday 03:00, still Sunday night': DateTime(2026, 10, 26, 3),
  'New Year\'s Eve, 23:30': DateTime(2026, 12, 31, 23, 30),
  'year-review season': DateTime(2026, 12, 15, 9),
  'leap day': DateTime(2028, 2, 29, 8),
  'clocks go forward': DateTime(2027, 3, 28, 9),
};

const _routes = [
  '/home',
  '/profile',
  '/week',
  '/weekly-coaching',
  '/program',
  '/log',
  '/growth',
  '/month-review',
  '/year',
  '/people',
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('the app reads time from one clock', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !f.path.endsWith('time.dart') &&
            RegExp(r'\bDateTime\.now\b|\bclock\.now\(\)').hasMatch(f.readAsStringSync()))
          f.path
    ];
    expect(offenders, isEmpty, reason: 'use timeNow() (lib/time.dart) so tests can pin a moment');
  });

  for (final builtIn in [true, false]) {
    for (final m in _moments.entries) {
      testWidgets('${builtIn ? 'built-in plan' : 'someone else'}: ${m.key}',
          (tester) {
        // Time still passes inside the test (pumps advance the fake clock),
        // but starting from the chosen moment.
        // This test chooses its own moments, so no suite-wide shift.
        final shift = timeShift;
        timeShift = Duration.zero;
        addTearDown(() => timeShift = shift);
        final outer = clock;
        final start = outer.now();
        return withClock(Clock(() => m.value.add(outer.now().difference(start))),
            () async {
          tester.view.physicalSize = const Size(1125, 2001);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          final errors = <String>[];
          final previous = FlutterError.onError;
          var route = '';
          FlutterError.onError = (details) {
            final where = RegExp(r'lib/[\w/]+\.dart:\d+')
                .firstMatch(details.toString())
                ?.group(0);
            errors.add('$route: ${details.exceptionAsString().split('\n').first}'
                '${where == null ? '' : ' ($where)'}');
          };
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(OnoApp(
            authGateway: MockAuthGateway(),
            personalGateway: MockPersonalSystemGateway(),
            reminders: NoopReminderService(),
            health: FakeHealthService(),
          ));
          await _pumpFor(tester, const Duration(seconds: 2));
          await Provider.of<AuthProvider>(
                  tester.element(find.byType(Scaffold).first),
                  listen: false)
              .signIn(email: 'dates@test.dev', password: 'password');
          await _pumpFor(tester, const Duration(seconds: 2));
          final system = Provider.of<PersonalSystemProvider>(
              tester.element(find.byType(Navigator).first),
              listen: false);
          final today = dayOnly(m.value);
          await system.commission(
            start: today.minusDays(40),
            gymDays: const [1, 3, 5],
            reminders: const {},
          );
          if (!builtIn) {
            system.saveProfile(builtInProfile.copyWith(
                name: 'Sam Rivera',
                firstName: 'Sam',
                organisation: '',
                focus: '',
                keyPeople: const [],
                coachContext: ''));
          }
          // A little history, so the week and the month have something in them.
          final items = system.dailyItems;
          for (var k = 1; k <= 12; k++) {
            for (final i in items.take(items.length - 1)) {
              system.setCheck(today.minusDays(k), i.id, true);
            }
          }
          system.addLog('win', date: today.minusDays(2), text: 'Finished the draft');
          system.setWeekOutcome(today, 0, 'Ship the draft');

          // Checks record into [errors]: an expect while onError is
          // replaced would wedge the runner.
          if (system.logicalToday != (m.value.hour < 4 ? today.minusDays(1) : today)) {
            errors.add('logicalToday ${system.logicalToday}: the day ends at 04:00');
          }

          for (final r in _routes) {
            route = r;
            GoRouter.of(tester.element(find.byType(Navigator).first)).go(r);
            await _pumpFor(tester, const Duration(milliseconds: 900));
            if (r == '/home') {
              // The screens read the same clock as the provider.
              if (find.textContaining('Day ${system.programDay}').evaluate().isEmpty) {
                errors.add('Today does not show day ${system.programDay}');
              }
            }
            for (var i = 0; i < 4; i++) {
              final s = find.byType(Scrollable);
              if (s.evaluate().isEmpty) break;
              await tester.drag(s.first, const Offset(0, -500), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
          FlutterError.onError = previous;
          expect(errors.toSet().toList(), isEmpty, reason: errors.toSet().join('\n'));
        });
      });
    }
  }
}

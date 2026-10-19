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

import 'support/fake_health.dart';

/// People type long things: a two-part surname, a goal in a full sentence,
/// a daily item with its reason. The screens they appear on must still fit
/// an iPhone SE, at the default and the largest standard text size.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

const _long = 'Maria-Fernanda Albuquerque de Souza Oliveira-Hernández';
const _sentence =
    'Run the whole Baku half marathon without stopping and finish feeling strong';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final scale in [1.0, 1.35]) {
    testWidgets('long names fit an iPhone SE (text ×$scale)', (tester) async {
      tester.view.physicalSize = const Size(1125, 2001);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
          .signIn(email: 'long@test.dev', password: 'password');
      await _pumpFor(tester, const Duration(seconds: 2));
      final system = Provider.of<PersonalSystemProvider>(
          tester.element(find.byType(Navigator).first),
          listen: false);
      await system.commission(
        start: dayOnly(DateTime.now()).minusDays(20),
        gymDays: const [1, 3, 5],
        reminders: const {},
      );
      system.saveProfile(builtInProfile.copyWith(
        name: _long,
        firstName: 'Maria-Fernanda',
        currentRole: 'Senior clinical nurse specialist in paediatric intensive care',
        targetRole: 'Head of nursing for the whole children\'s hospital network',
        organisation: '',
        focus: '',
        keyPeople: const [],
        coachContext: '',
      ));
      final today = system.logicalToday;
      system.addDailyItem('Walk for thirty minutes outside after lunch, whatever the weather',
          lane: 'body', when: 'day');
      system.saveGoal(title: _sentence, obstacle: 'Getting bored on long runs', deadline: today.plusDays(120));
      system.setWeekOutcome(today, 0, 'Book the physiotherapist and finally sort out the knee properly');
      system.setPriority(today, 0, 'Finish the rota for next month and send it to everyone involved');
      final p = system.addPerson(_long, role: 'Sister who lives far away in another country', every: 7);
      system.logTouch(p, note: 'Long call', date: today.minusDays(20));
      system.addPromise(what: 'Send the photos from the wedding and the long letter I owe her', to: _long);
      system.addLog('win', text: _sentence);

      for (final r in [
        '/home',
        '/profile',
        '/people',
        '/goals',
        '/daily',
        '/week',
        '/log',
        '/promises',
        '/know?id=${p.id}',
        '/remember',
        '/change',
        '/tools',
      ]) {
        route = r;
        GoRouter.of(tester.element(find.byType(Navigator).first)).go(r);
        await _pumpFor(tester, const Duration(milliseconds: 900));
        // Scroll through so lazily built rows are laid out too.
        for (var i = 0; i < 6; i++) {
          final s = find.byType(Scrollable);
          if (s.evaluate().isEmpty) break;
          await tester.drag(s.first, const Offset(0, -400), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      FlutterError.onError = previous;
      expect(errors.toSet().toList(), isEmpty, reason: errors.toSet().join('\n'));
    });
  }
}

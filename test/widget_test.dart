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
import 'package:ono/services/reminder_service.dart';

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
    );

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
        if (errors.isNotEmpty) failures[route] = errors.toSet();
      }

      _restoreErrors();
      expect(failures, isEmpty,
          reason: failures.entries
              .map((e) => 'FAIL ${e.key}: ${e.value.join(' | ')}')
              .join('\n'));
    });
  }
}

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
import 'package:ono/router.dart';
import 'package:ono/services/reminder_service.dart';

import 'support/fake_health.dart';
import 'package:ono/time.dart';

/// Many people raise the text size on their phone. Every route must still
/// fit an iPhone SE with text at 135% (iOS's largest standard size), with no overflow or error.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('every route fits an iPhone SE with text at 135%',
      (tester) async {
    tester.view.physicalSize = const Size(1125, 2001);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
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
        .signIn(email: 'big@test.dev', password: 'password');
    await _pumpFor(tester, const Duration(seconds: 2));
    final system = Provider.of<PersonalSystemProvider>(
        tester.element(find.byType(Navigator).first),
        listen: false);
    await system.commission(
      start: dayOnly(timeNow()).minusDays(40),
      gymDays: const [1, 3, 5],
      reminders: const {},
    );
    // A little of everything, with long text.
    system.addLog('win', text: 'Shipped the onboarding redesign after three long weeks');
    system.addPromise(what: 'Send the revised proposal with three options', to: 'A colleague');
    system.logThought(situation: 'Review', thought: 'They think I am not ready for this', before: 80, after: 50);
    system.addLog('ask', date: timeNow().minusDays(3), text: 'Cover the Thursday stand-up while I am away', data: {'of': 'A colleague', 'guess': 40, 'status': 'asked'});
    system.addPerson('A friend with a rather long name', role: 'Friend', every: 14);

    for (final r in appRoutes) {
      route = r;
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(r);
      await _pumpFor(tester, const Duration(milliseconds: 900));
    }
    FlutterError.onError = previous;
    expect(errors.toSet().toList(), isEmpty,
        reason: errors.toSet().join('\n'));
  });
}

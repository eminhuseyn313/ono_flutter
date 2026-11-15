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
import 'package:ono/time.dart';
import 'package:ono/widgets/desktop_shell.dart';
import 'support/fake_health.dart';

/// ONO on a big screen (the Mac app, the web on a laptop): a sidebar, the
/// page in a reading column and today at a glance; every page fits.
Future<void> _pumpFor(WidgetTester t, Duration d) async {
  for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<PersonalSystemProvider> _start(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(OnoApp(
    authGateway: MockAuthGateway(),
    personalGateway: MockPersonalSystemGateway(),
    reminders: NoopReminderService(),
    health: FakeHealthService(),
  ));
  await _pumpFor(tester, const Duration(seconds: 2));
  // Before sign-in: no sidebar, one calm column.
  expect(find.byKey(const Key('side-/home')), findsNothing);
  await Provider.of<AuthProvider>(tester.element(find.byType(Scaffold).first), listen: false)
      .signIn(email: 'desk@test.dev', password: 'password');
  await _pumpFor(tester, const Duration(seconds: 2));
  final system = Provider.of<PersonalSystemProvider>(
      tester.element(find.byType(Navigator).first),
      listen: false);
  await system.commission(
      start: dayOnly(timeNow()).minusDays(12), gymDays: const [1, 3, 5], reminders: const {});
  await _go(tester, '/home');
  return system;
}

Future<void> _go(WidgetTester tester, String route) async {
  final ctx = tester.element(find.byType(Navigator).first);
  Navigator.of(ctx, rootNavigator: true).popUntil((r) => r is! PopupRoute);
  await tester.pump(const Duration(milliseconds: 300));
  GoRouter.of(ctx).go(route);
  await _pumpFor(tester, const Duration(milliseconds: 900));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('a laptop window: sidebar, page and today at a glance', (tester) async {
    final system = await _start(tester, const Size(1440, 900));
    expect(find.byKey(const Key('side-/home')), findsOneWidget);
    expect(find.byKey(const Key('desktop-glance')), findsOneWidget);
    expect(find.text('TODAY AT A GLANCE'), findsOneWidget);
    // The tab bar steps aside for the sidebar.
    expect(find.text('Program'), findsOneWidget, reason: 'only the sidebar shows Program');
    // The page sits in a reading column.
    final page = tester.getSize(find.byType(Navigator).first);
    expect(page.width, DesktopShell.columnWidth);
    // The panel ticks today's three.
    system.setPriority(system.logicalToday, 0, 'Write the plan');
    await tester.pump(const Duration(milliseconds: 300));
    final row = find.descendant(of: find.byKey(const Key('desktop-glance')), matching: find.text('Write the plan'));
    await tester.tap(row.last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(system.priorityDone(system.logicalToday, 0), isTrue);
    // The sidebar opens tools over the page and tabs in place.
    await tester.tap(find.byKey(const Key('side-/goals')));
    await _pumpFor(tester, const Duration(milliseconds: 900));
    expect(GoRouter.of(tester.element(find.byType(Navigator).first)).routerDelegate.currentConfiguration.last.matchedLocation, '/goals');
    await tester.tap(find.byKey(const Key('side-/log')));
    await _pumpFor(tester, const Duration(milliseconds: 900));
    expect(GoRouter.of(tester.element(find.byType(Navigator).first)).routerDelegate.currentConfiguration.last.matchedLocation, '/log');
  });

  testWidgets('a smaller window drops the panel; a phone-sized one is the phone app', (tester) async {
    await _start(tester, const Size(1100, 760));
    expect(find.byKey(const Key('side-/home')), findsOneWidget);
    expect(find.byKey(const Key('desktop-glance')), findsNothing);
    tester.view.physicalSize = const Size(700, 900);
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byKey(const Key('side-/home')), findsNothing);
    expect(find.text('Program'), findsOneWidget, reason: 'the tab bar is back');
  });

  testWidgets('every page fits a Mac window', (tester) async {
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
    addTearDown(() => FlutterError.onError = old);
    await _start(tester, const Size(1280, 800));
    final failures = <String, List<String>>{};
    for (final route in appRoutes) {
      errors.clear();
      await _go(tester, route);
      if (errors.isNotEmpty) failures[route] = List.of(errors);
    }
    FlutterError.onError = old;
    expect(failures, isEmpty, reason: failures.toString());
  });
}

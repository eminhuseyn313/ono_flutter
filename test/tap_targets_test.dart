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
import 'package:ono/time.dart';

/// Many people raise the text size on their phone. Every route must still
/// fit an iPhone SE with text at 135% (iOS's largest standard size), with no overflow or error.
Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

/// Every button, rating and segmented choice on these screens is at least
/// 44 × 44 pt — Apple's smallest comfortable tap target — so a tired thumb
/// on a small phone hits what it meant to.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  testWidgets('tap targets are at least 44 pt', (tester) async {
    tester.view.physicalSize = const Size(1125, 2001);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final sem = tester.ensureSemantics();
    await tester.pumpWidget(OnoApp(
      authGateway: MockAuthGateway(),
      personalGateway: MockPersonalSystemGateway(),
      reminders: NoopReminderService(),
      health: FakeHealthService(),
    ));
    await _pumpFor(tester, const Duration(seconds: 2));
    await Provider.of<AuthProvider>(tester.element(find.byType(Scaffold).first), listen: false)
        .signIn(email: 'taps@test.dev', password: 'password');
    await _pumpFor(tester, const Duration(seconds: 2));
    final system = Provider.of<PersonalSystemProvider>(tester.element(find.byType(Navigator).first), listen: false);
    await system.commission(start: dayOnly(timeNow()).minusDays(40), gymDays: const [1, 3, 5], reminders: const {});
    final failures = <String>[];
    for (final r in ['/home', '/profile', '/program', '/log', '/habits', '/cockpit', '/cockpit?tab=2', '/week', '/record', '/growth', '/weekly-coaching']) {
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(r);
      await _pumpFor(tester, const Duration(milliseconds: 900));
      final e = await iOSTapTargetGuideline.evaluate(tester);
      if (!e.passed) failures.add('$r: ${e.reason}');
    }
    sem.dispose();
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import 'package:ono/data/emin_system.dart';
import 'package:ono/data/plan_import.dart';
import 'package:ono/main.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/router.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/time.dart';
import 'support/fake_health.dart';

/// A person whose plan an AI wrote: partial (no training, ritual, LinkedIn
/// or readiness…), loaded through the importer, their profile the plan's.
/// Every screen must work with whatever parts the plan has.
void main() {
  testWidgets('a partial AI-written plan: every route renders without errors', (tester) async {
    final before = fallbackPlan;
    fallbackPlan = importPlan(File('test/support/partial_plan.json').readAsStringSync()).plan;
    addTearDown(() => fallbackPlan = before);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    final errors = <String>[];
    final prev = FlutterError.onError;
    var where = '';
    FlutterError.onError = (d) {
      final stack = d.stack.toString().split('\n').where((l) => l.contains('package:ono/')).take(2).join(' | ');
      errors.add('$where: ${d.exceptionAsString().split('\n').first} :: $stack');
      debugPrint('PLANERR $where: ${d.exceptionAsString().split('\n').first} :: $stack');
    };
    await tester.pumpWidget(OnoApp(authGateway: MockAuthGateway(), personalGateway: MockPersonalSystemGateway(),
        reminders: NoopReminderService(), health: FakeHealthService()));
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await Provider.of<AuthProvider>(tester.element(find.byType(Scaffold).first), listen: false).signIn(email: 'n@t.dev', password: 'password');
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    final system = Provider.of<PersonalSystemProvider>(tester.element(find.byType(Navigator).first), listen: false);
    await system.commission(start: dayOnly(timeNow()).minusDays(20), gymDays: const [1, 3, 5], reminders: const {});
    for (final r in appRoutes) {
      if (const ['/splash', '/welcome', '/sign-up', '/sign-in', '/forgot-password', '/new-password'].contains(r)) continue;
      where = r;
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(r);
      for (var i = 0; i < 8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    }
    FlutterError.onError = prev;
    expect(system.isBuiltInPerson, isTrue);
    expect(errors.toSet().toList(), isEmpty, reason: errors.toSet().join('\n'));
  });
}

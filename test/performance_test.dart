import 'dart:convert';
import 'dart:math';

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
import 'package:ono/models/state_merge.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/services/reminder_service.dart';

import 'support/fake_health.dart';

/// A full program's worth of history (500 days, a few thousand logs), the
/// way a year and a half of daily use looks. Today, Me, Log and the brief
/// must stay quick with it.
PersonalSystemState _history(DateTime today) {
  final rnd = Random(7);
  final start = today.minusDays(500);
  final checks = <String, List<String>>{};
  final logs = <LogEntry>[];
  var n = 0;
  LogEntry log(String type, DateTime d, {String text = '', Map<String, dynamic> data = const {}}) =>
      LogEntry(id: '${type}_h${n++}', type: type, date: d, createdAt: d, text: text, data: data);
  for (var i = 0; i < 500; i++) {
    final d = start.plusDays(i);
    checks[dateKey(d)] = [
      for (final item in nonNegotiables)
        if (rnd.nextDouble() < 0.72) item.id
    ];
    logs.add(log('checkin', d, data: {
      'energy': 2 + rnd.nextInt(4),
      'mood': rnd.nextInt(5) - 2,
      'sleep': 6 + rnd.nextInt(4) * 0.5,
      'pain': rnd.nextInt(6),
      'stiffness': rnd.nextInt(3),
    }));
    if (i % 2 == 0) logs.add(log('focus', d, data: {'minutes': 50, 'target': 'skill'}));
    if (i % 3 == 0) logs.add(log('note', d, text: 'Note $i about the day and what I noticed'));
    if (i % 4 == 0) logs.add(log('win', d, text: 'Win $i'));
    if (i % 5 == 0) logs.add(log('move', d, data: {'kind': 'walk', 'minutes': 40, 'vigorous': false}));
    if (i % 7 == 0) logs.add(log('weight', d, data: {'kg': 82 - i / 100}));
    if (i % 6 == 0) logs.add(log('thought', d, text: 'Thought $i', data: {'before': 70, 'after': 40}));
    if (i % 9 == 0) logs.add(log('promise', d, text: 'Promise $i', data: {'by': dateKey(d), 'status': i % 18 == 0 ? 'kept' : 'missed', 'closed_on': dateKey(d)}));
  }
  return PersonalSystemState(
    programStart: start,
    commissioned: true,
    dailyChecks: checks,
    logs: logs,
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the provider stays quick with 500 days of history', () async {
    final today = DateTime.now();
    final state = _history(today);
    SharedPreferences.setMockInitialValues(
        {'personal_system_t': jsonEncode(state.toJson())});
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway());
    await p.load('t');
    expect(p.state!.logs.length, greaterThan(1000));

    int ms(void Function() f) {
      final w = Stopwatch()..start();
      f();
      return w.elapsedMilliseconds;
    }

    final timings = {
      'streak': ms(() => p.streak),
      'score today': ms(() => p.scoreFor(today)),
      'patterns': ms(() => p.patterns()),
      'item rates': ms(() => p.itemRates([for (var i = 0; i < 60; i++) today.minusDays(i)])),
      'journal': ms(() => p.journalText()),
      'say-do': ms(() => p.sayDo()),
      'program summary': ms(() => p.programSummary()),
      'year summary': ms(() => p.yearSummary(today.year)),
      'ask record': ms(() => p.askRecord()),
      'merge with itself': ms(() => mergeStateJson(state.toJson(), state.toJson(), state.toJson())),
    };
    // Generous limits for a slow CI machine; on a phone these are a
    // fraction. Anything above means a quadratic slipped in.
    // ignore: avoid_print
    print('timings (ms): $timings');
    for (final e in timings.entries) {
      expect(e.value, lessThan(1500), reason: '${e.key} took ${e.value} ms');
    }
    p.dispose();
  });

  testWidgets('Today, Me, Log and Program render quickly with it',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mock_auth_email': 'perf@test.dev',
    });
    await tester.pumpWidget(OnoApp(
      authGateway: MockAuthGateway(),
      personalGateway: MockPersonalSystemGateway(),
      reminders: NoopReminderService(),
      health: FakeHealthService(),
    ));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final ctx = tester.element(find.byType(Navigator).first);
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    if (auth.status != AuthStatus.authenticated) {
      await auth.signIn(email: 'perf@test.dev', password: 'x');
    }
    final system = Provider.of<PersonalSystemProvider>(ctx, listen: false);
    await tester.runAsync(() async {
      await system.load(auth.userId);
    });
    system.importJson(jsonEncode(_history(today).toJson()));
    for (final route in ['/home', '/profile', '/log', '/program', '/growth', '/review']) {
      final w = Stopwatch()..start();
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      w.stop();
      expect(tester.takeException(), isNull, reason: route);
      expect(w.elapsedMilliseconds, lessThan(3000),
          reason: '$route took ${w.elapsedMilliseconds} ms to build');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  });
}

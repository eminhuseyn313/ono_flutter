import 'dart:io';

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
import 'package:ono/router.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/time.dart';

import 'support/fake_health.dart';

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

bool _tappable(Widget w) =>
    (w is InkWell && w.onTap != null) ||
    (w is ButtonStyleButton && w.onPressed != null) ||
    (w is IconButton && w.onPressed != null) ||
    (w is GestureDetector && w.onTap != null) ||
    w is Switch;

/// Taps every button, row and switch on a screen once, and everything in
/// the sheet or dialog that opens (typing into its first field), leaving
/// the screen each time while the sheet is still closing. Any runtime
/// error fails. It found a sheet reading its screen after the screen left.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  // By default the four tab screens. The whole app, in slices:
  //   TAP_ALL=1 PARTS=12 PART=0 flutter test test/tap_everything_test.dart
  final all = Platform.environment['TAP_ALL'] == '1';
  final part = int.parse(Platform.environment['PART'] ?? '0');
  final parts = int.parse(Platform.environment['PARTS'] ?? '1');
  // SCROLL=1200 starts each page that far down, for long screens.
  final scroll = double.parse(Platform.environment['SCROLL'] ?? '0');

  for (final builtIn in [true, false]) {
    testWidgets(
        '${builtIn ? 'built-in plan' : 'someone else'}: tap everything, and everything in the sheet it opens',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2001);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final errors = <String>[];
      final previous = FlutterError.onError;
      var where = '';
      FlutterError.onError = (d) {
        final at =
            RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0);
        errors.add(
            '$where: ${d.exceptionAsString().split('\n').first} ${at ?? ''}');
      };
      await tester.pumpWidget(OnoApp(
        authGateway: MockAuthGateway(),
        personalGateway: MockPersonalSystemGateway(),
        reminders: NoopReminderService(),
        health: FakeHealthService(),
      ));
      await _pumpFor(tester, const Duration(seconds: 2));
      final auth = Provider.of<AuthProvider>(
          tester.element(find.byType(Scaffold).first),
          listen: false);
      await auth.signIn(email: 'm@test.dev', password: 'password');
      await _pumpFor(tester, const Duration(seconds: 2));
      BuildContext ctx() => tester.element(find.byType(Navigator).first);
      final system = Provider.of<PersonalSystemProvider>(ctx(), listen: false);
      final today = dayOnly(timeNow());
      await system.commission(
          start: today.minusDays(40),
          gymDays: const [1, 3, 5],
          reminders: const {});
      if (!builtIn) {
        system.saveProfile(builtInProfile.copyWith(
            name: 'Sam Rivera',
            firstName: 'Sam',
            organisation: '',
            focus: '',
            keyPeople: const [],
            coachContext: ''));
      }
      for (var k = 1; k <= 10; k++) {
        for (final i in system.dailyItems.take(4)) {
          system.setCheck(today.minusDays(k), i.id, true);
        }
      }
      system.addLog('win',
          date: today.minusDays(2), text: 'Finished the draft');
      system.setWeekOutcome(today, 0, 'Ship the draft');
      system.addPerson('Dana Lee', role: 'Friend', every: 14);
      await _pumpFor(tester, const Duration(seconds: 1));

      final routes = (all
              ? [
                  for (var i = 0; i < appRoutes.length; i++)
                    if (i % parts == part) appRoutes[i]
                ]
              : const ['/home', '/profile', '/log', '/program'])
          .where((r) => !const [
                '/splash',
                '/welcome',
                '/sign-up',
                '/sign-in',
                '/forgot-password',
                '/commission',
                '/new-password'
              ].contains(r));
      var taps = 0;
      for (final r in routes) {
        Future<int> open() async {
          final nav = Navigator.of(ctx(), rootNavigator: true);
          nav.popUntil((route) => route is! PopupRoute);
          GoRouter.of(ctx()).go('/home');
          await tester.pump(const Duration(milliseconds: 200));
          GoRouter.of(ctx()).go(r);
          await _pumpFor(tester, const Duration(milliseconds: 700));
          if (scroll > 0 && find.byType(Scrollable).evaluate().isNotEmpty) {
            await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll),
                warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 300));
          }
          return find.byWidgetPredicate(_tappable).evaluate().length;
        }

        where = '$r open';
        final n = (await open()).clamp(0, 40);
        for (var i = 0; i < n; i++) {
          final f = find.byWidgetPredicate(_tappable);
          if (f.evaluate().length <= i) break;
          final target = f.at(i);
          final texts = find
              .descendant(of: target, matching: find.byType(Text))
              .evaluate();
          final label =
              texts.isEmpty ? '' : ((texts.first.widget as Text).data ?? '');
          if (label.contains('Sign out') ||
              label.contains('Delete everything')) {
            continue;
          }
          where = '$r tap $i "$label"';
          try {
            await tester.ensureVisible(target);
            await tester.pump(const Duration(milliseconds: 100));
            await tester.tap(target, warnIfMissed: false);
          } catch (e) {
            // off-screen or gone
          }
          taps++;
          await _pumpFor(tester, const Duration(milliseconds: 600));
          if (!auth.isAuthenticated) {
            await auth.signIn(email: 'm@test.dev', password: 'password');
            await _pumpFor(tester, const Duration(seconds: 1));
          }
          // Second level: everything inside a sheet or dialog it opened.
          Finder popup() =>
              find.byWidgetPredicate((w) => w is BottomSheet || w is Dialog);
          Finder inner() => find.descendant(
              of: popup(), matching: find.byWidgetPredicate(_tappable));
          final m = popup().evaluate().isEmpty
              ? 0
              : inner().evaluate().length.clamp(0, 14);
          for (var j = 0; j < m; j++) {
            if (j > 0) {
              where = '$r reopen for $i/$j "$label"';
              await open();
              final g = find.byWidgetPredicate(_tappable);
              if (g.evaluate().length <= i) break;
              try {
                await tester.ensureVisible(g.at(i));
                await tester.pump(const Duration(milliseconds: 100));
                await tester.tap(g.at(i), warnIfMissed: false);
              } catch (e) {/* gone */}
              await _pumpFor(tester, const Duration(milliseconds: 600));
            }
            if (popup().evaluate().isEmpty || inner().evaluate().length <= j) {
              break;
            }
            final fields =
                find.descendant(of: popup(), matching: find.byType(TextField));
            where = '$r tap $i "$label" > field';
            if (fields.evaluate().isNotEmpty) {
              try {
                await tester.enterText(
                    fields.first, j.isEven ? 'Something real 42' : '42');
              } catch (e) {/* not editable */}
              await tester.pump(const Duration(milliseconds: 100));
            }
            if (inner().evaluate().length <= j) break;
            final t2 = inner().at(j);
            final tx =
                find.descendant(of: t2, matching: find.byType(Text)).evaluate();
            final l2 = tx.isEmpty ? '' : ((tx.first.widget as Text).data ?? '');
            if (l2.contains('Sign out') || l2.contains('Delete')) continue;
            where = '$r tap $i "$label" > $j "$l2"';
            try {
              await tester.tap(t2, warnIfMissed: false);
            } catch (e) {/* gone */}
            taps++;
            await _pumpFor(tester, const Duration(milliseconds: 700));
            if (!auth.isAuthenticated) {
              await auth.signIn(email: 'm@test.dev', password: 'password');
              await _pumpFor(tester, const Duration(seconds: 1));
            }
          }
          where = '$r reopen after $i "$label"';
          await open();
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      FlutterError.onError = previous;
      final u = errors.toSet().toList();
      expect(taps, greaterThan(20));
      expect(u, isEmpty, reason: u.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 25)));
  }
}

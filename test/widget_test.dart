import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/main.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/widgets/feature_discovery_grid.dart';

/// The app has looping animations (splash, rings, timers), so these tests
/// pump fixed durations instead of `pumpAndSettle`.
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

  testWidgets('app builds successfully', (tester) async {
    await tester.pumpWidget(const OnoApp());
    await _pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(OnoApp), findsOneWidget);
  });

  // iPhone 15/16 (393×852) and iPhone SE (375×667), both @3x.
  for (final size in const [Size(1179, 2556), Size(1125, 2001)]) {
    testWidgets(
        'every route renders without errors after sign-in '
        '(${size.width ~/ 3}×${size.height ~/ 3})', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // Collect every runtime error, layout overflow included. Plus Jakarta
      // Sans is bundled in assets/google_fonts, so text is measured with the
      // real font rather than the square test font.
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final where = RegExp(r'lib/[\w/]+\.dart:\d+')
            .firstMatch(details.toString())
            ?.group(0);
        final what = details.exceptionAsString().split('\n').first;
        errors.add(where == null ? what : '$what ($where)');
      };

      await tester.pumpWidget(const OnoApp());
      await _pumpFor(tester, const Duration(seconds: 3));

      final ctx = tester.element(find.byType(Scaffold).first);
      await Provider.of<AuthProvider>(ctx, listen: false)
          .signIn(email: 'emin@test.dev', password: 'password');
      await _pumpFor(tester, const Duration(seconds: 2));

      final routes = <String>{
        '/home',
        '/archetype',
        '/assessment/executive',
        '/loading/executive',
        '/plan',
        '/playbook',
        '/profile',
        '/journal',
        '/progress',
        '/features',
        for (final g in featureGroups)
          for (final e in g.entries) e.route,
      };

      final failures = <String, Set<String>>{};
      for (final route in routes) {
        errors.clear();
        final routerCtx = tester.element(find.byType(Navigator).first);
        GoRouter.of(routerCtx).go(route);
        await _pumpFor(tester, const Duration(milliseconds: 1500));
        if (errors.isNotEmpty) failures[route] = errors.toSet();
      }

      FlutterError.onError = previous;
      expect(failures, isEmpty,
          reason: failures.entries
              .map((e) => 'FAIL ${e.key}: ${e.value.join(' | ')}')
              .join('\n'));
    });
  }
}

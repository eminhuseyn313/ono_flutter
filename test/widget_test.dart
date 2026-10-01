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

  testWidgets('every route renders without exceptions after sign-in',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Collect real crashes. Layout overflow is skipped: the test font draws
    // every glyph as a full square, so text-heavy rows overflow only here.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed') ||
          msg.contains('GoogleFonts') ||
          msg.contains('allowRuntimeFetching')) {
        return;
      }
      errors.add(msg);
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

    final failures = <String, List<String>>{};
    for (final route in routes) {
      errors.clear();
      final routerCtx = tester.element(find.byType(Navigator).first);
      GoRouter.of(routerCtx).go(route);
      await _pumpFor(tester, const Duration(milliseconds: 1500));
      if (errors.isNotEmpty) failures[route] = List.of(errors);
    }

    FlutterError.onError = previous;
    expect(failures, isEmpty,
        reason: failures.entries
            .map((e) =>
                'FAIL ${e.key}: ${e.value.map((m) => m.split('\n').first).toSet().join(' | ')}')
            .join('\n'));
  });
}

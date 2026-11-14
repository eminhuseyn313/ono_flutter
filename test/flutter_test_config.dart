import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ono/data/plan_content.dart';
import 'package:ono/time.dart';

/// ONO_TEST_NOW=2026-10-25T02:30 TZ=Europe/Berlin flutter test — runs the
/// whole suite as if it were that moment (time still passes from there), to
/// find what only breaks on some days: a Sunday, the night the clocks
/// change, the year's end.
///
/// The app ships with no one's plan. Tests run with an example person's
/// full plan (test/support/example_plan.json, made up) loaded, so the
/// plan-specific screens are exercised; "someone else" in a test is any
/// other name. ONO_NO_PLAN=1 flutter test runs with no plan at all, as a
/// newcomer gets the App Store build.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final at = DateTime.tryParse(Platform.environment['ONO_TEST_NOW'] ?? '');
  if (at != null) timeShift = at.difference(DateTime.now());
  // ONO_NO_PLAN=1 runs as the App Store build does for a newcomer: no plan.
  if (Platform.environment['ONO_NO_PLAN'] != '1') {
    fallbackPlan = PlanContent.fromJson(
        jsonDecode(File('test/support/example_plan.json').readAsStringSync()) as Map);
  }
  await testMain();
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/data/plan_content.dart';
import 'package:ono/data/plan_import.dart';
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
/// newcomer gets the App Store build. ONO_DARK=1 runs in dark appearance.
/// ONO_PLAN_FILE=<file> runs with that plan (e.g. the partial, AI-written
/// test/support/partial_plan.json).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final at = DateTime.tryParse(Platform.environment['ONO_TEST_NOW'] ?? '');
  if (at != null) timeShift = at.difference(DateTime.now());
  // ONO_NO_PLAN=1 runs as the App Store build does for a newcomer: no plan.
  // ONO_PLAN_FILE=test/support/partial_plan.json runs with an AI-written,
  // partial plan instead (read through the importer, as the app does).
  final planFile = Platform.environment['ONO_PLAN_FILE'];
  if (planFile != null && planFile.isNotEmpty) {
    fallbackPlan = importPlan(File(planFile).readAsStringSync()).plan;
  } else if (Platform.environment['ONO_NO_PLAN'] != '1') {
    fallbackPlan = PlanContent.fromJson(
        jsonDecode(File('test/support/example_plan.json').readAsStringSync()) as Map);
  }
  // ONO_DARK=1 runs everything in the iPhone's dark appearance.
  if (Platform.environment['ONO_DARK'] == '1') {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .platformBrightnessTestValue = Brightness.dark;
  }
  await testMain();
}

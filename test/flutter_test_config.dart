import 'dart:async';
import 'dart:io';

import 'package:ono/time.dart';

/// ONO_TEST_NOW=2026-10-25T02:30 TZ=Europe/Berlin flutter test — runs the
/// whole suite as if it were that moment (time still passes from there), to
/// find what only breaks on some days: a Sunday, the night the clocks
/// change, the year's end.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final at = DateTime.tryParse(Platform.environment['ONO_TEST_NOW'] ?? '');
  if (at != null) timeShift = at.difference(DateTime.now());
  await testMain();
}

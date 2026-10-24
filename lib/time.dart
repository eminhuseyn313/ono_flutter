import 'package:clock/clock.dart';

/// The app's one source of "now". It reads `package:clock`, so a test can
/// pin a moment with `withClock`, and adds [timeShift], which
/// test/flutter_test_config.dart sets from ONO_TEST_NOW to run the whole
/// suite as another day. Always zero in the app.
Duration timeShift = Duration.zero;

DateTime timeNow() => clock.now().add(timeShift);

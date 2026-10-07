import 'health_service_stub.dart'
    if (dart.library.io) 'health_service_apple.dart' as impl;

/// One night of sleep, from the samples ending on a given morning.
class NightSleep {
  /// First moment in bed (or asleep, if no in-bed samples).
  final DateTime bedStart;
  final DateTime wake;

  /// Time actually asleep; overlapping samples (iPhone + Watch) are merged.
  final double asleepHours;

  const NightSleep(
      {required this.bedStart, required this.wake, required this.asleepHours});
}

class Vitals {
  final double? hrvMs; // heart-rate variability (SDNN)
  final double? restingHr; // beats per minute

  const Vitals({this.hrvMs, this.restingHr});
}

/// One sleep sample: a time range, asleep or just in bed.
typedef SleepSample = ({DateTime from, DateTime to, bool asleep});

/// Turns raw samples into a night: bed start, wake time and merged asleep
/// time. Null when there is no sleep in the samples.
NightSleep? summarizeNight(List<SleepSample> samples) {
  if (samples.isEmpty) return null;
  final asleep = samples.where((s) => s.asleep).toList()
    ..sort((a, b) => a.from.compareTo(b.from));
  var total = Duration.zero;
  DateTime? start, end;
  for (final s in asleep) {
    if (start == null || s.from.isAfter(end!)) {
      if (start != null) total += end!.difference(start);
      start = s.from;
      end = s.to;
    } else if (s.to.isAfter(end)) {
      end = s.to;
    }
  }
  if (start != null) total += end!.difference(start);
  final all = [...samples]..sort((a, b) => a.from.compareTo(b.from));
  final wake = all.map((s) => s.to).reduce((a, b) => a.isAfter(b) ? a : b);
  final hours = total.inMinutes / 60;
  if (hours <= 0 && asleep.isEmpty) {
    // Only in-bed samples: use time in bed as the best estimate.
    return NightSleep(
        bedStart: all.first.from,
        wake: wake,
        asleepHours: wake.difference(all.first.from).inMinutes / 60);
  }
  return NightSleep(bedStart: all.first.from, wake: wake, asleepHours: hours);
}

/// Apple Health on iPhone; a no-op everywhere else (web, tests).
abstract class HealthService {
  bool get isSupported;

  /// Asks for permission. Throws [HealthUnavailable] when this build has
  /// no HealthKit capability.
  Future<bool> connect();

  /// The night that ended on the morning of [day].
  Future<NightSleep?> sleepEndingOn(DateTime day);

  Future<Vitals> vitalsOn(DateTime day);

  Future<bool> writeWeight(double kg, DateTime at);
}

class HealthUnavailable implements Exception {
  final String message;
  const HealthUnavailable(this.message);
  @override
  String toString() => message;
}

class NoopHealthService implements HealthService {
  const NoopHealthService();
  @override
  bool get isSupported => false;
  @override
  Future<bool> connect() async => false;
  @override
  Future<NightSleep?> sleepEndingOn(DateTime day) async => null;
  @override
  Future<Vitals> vitalsOn(DateTime day) async => const Vitals();
  @override
  Future<bool> writeWeight(double kg, DateTime at) async => false;
}

/// Apple Health on iOS, [NoopHealthService] elsewhere.
HealthService createHealthService() => impl.createHealthService();

import 'package:ono/services/health_service.dart';

/// Apple Health stand-in: nights keyed by the morning they end on.
class FakeHealthService implements HealthService {
  final Map<DateTime, NightSleep> nights;
  final Vitals vitals;
  final bool grant;
  final bool unavailable;
  final List<double> weights = [];

  FakeHealthService({
    this.nights = const {},
    this.vitals = const Vitals(hrvMs: 52, restingHr: 58),
    this.grant = true,
    this.unavailable = false,
  });

  @override
  bool get isSupported => true;

  @override
  Future<bool> connect() async {
    if (unavailable) throw const HealthUnavailable('Enable HealthKit');
    return grant;
  }

  @override
  Future<NightSleep?> sleepEndingOn(DateTime day) async =>
      nights[DateTime(day.year, day.month, day.day)];

  @override
  Future<Vitals> vitalsOn(DateTime day) async => vitals;

  @override
  Future<bool> writeWeight(double kg, DateTime at) async {
    weights.add(kg);
    return true;
  }
}

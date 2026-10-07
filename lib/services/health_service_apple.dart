import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:health/health.dart';

import 'health_service.dart';

HealthService createHealthService() =>
    Platform.isIOS ? AppleHealthService() : const NoopHealthService();

/// Reads sleep, HRV and resting heart rate from Apple Health and writes
/// weigh-ins to it. Needs the HealthKit capability on the Runner target.
class AppleHealthService implements HealthService {
  final Health _health = Health();
  bool _configured = false;

  static const _sleepTypes = [
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];
  static const _readTypes = [
    ..._sleepTypes,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WEIGHT,
  ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  bool get isSupported => true;

  @override
  Future<bool> connect() async {
    try {
      await _configure();
      return await _health.requestAuthorization(
        _readTypes,
        permissions: [
          for (final t in _readTypes)
            t == HealthDataType.WEIGHT
                ? HealthDataAccess.READ_WRITE
                : HealthDataAccess.READ,
        ],
      );
    } on PlatformException catch (e) {
      throw HealthUnavailable(
          'Apple Health isn\'t enabled in this build (${e.code}). On the Mac, '
          'in the ono_flutter folder run: bash scripts/capabilities.sh health on '
          '— then double-click ONO on iPhone to install again.');
    }
  }

  Future<List<HealthDataPoint>> _read(
      List<HealthDataType> types, DateTime from, DateTime to) async {
    try {
      await _configure();
      return await _health.getHealthDataFromTypes(
          types: types, startTime: from, endTime: to);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<NightSleep?> sleepEndingOn(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    final points = await _read(_sleepTypes,
        d.subtract(const Duration(hours: 6)), d.add(const Duration(hours: 14)));
    return summarizeNight([
      for (final p in points)
        (
          from: p.dateFrom,
          to: p.dateTo,
          asleep: p.type != HealthDataType.SLEEP_IN_BED
        )
    ]);
  }

  @override
  Future<Vitals> vitalsOn(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    final points = await _read(
        const [
          HealthDataType.HEART_RATE_VARIABILITY_SDNN,
          HealthDataType.RESTING_HEART_RATE
        ],
        d,
        d.add(const Duration(days: 1)));
    double? avg(HealthDataType t) {
      final v = [
        for (final p in points)
          if (p.type == t && p.value is NumericHealthValue)
            (p.value as NumericHealthValue).numericValue.toDouble()
      ];
      return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
    }

    return Vitals(
        hrvMs: avg(HealthDataType.HEART_RATE_VARIABILITY_SDNN),
        restingHr: avg(HealthDataType.RESTING_HEART_RATE));
  }

  @override
  Future<bool> writeWeight(double kg, DateTime at) async {
    try {
      await _configure();
      return await _health.writeHealthData(
          value: kg,
          type: HealthDataType.WEIGHT,
          unit: HealthDataUnit.KILOGRAM,
          startTime: at,
          endTime: at);
    } catch (_) {
      return false;
    }
  }
}

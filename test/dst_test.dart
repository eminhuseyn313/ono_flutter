import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ono/data/emin_system.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';

/// Days of 23 and 25 hours (daylight saving) must not shift program days,
/// month starts or the streak. These only bite in a zone with DST: run
/// `TZ=Europe/Berlin flutter test test/dst_test.dart` (and America/New_York).
/// In a zone without DST they still check the calendar arithmetic.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('calendar days survive daylight saving', () {
    final start = DateTime(2026, 10, 1);
    expect(start.plusDays(26), DateTime(2026, 10, 27));
    expect(DateTime(2026, 10, 27, 12).daysSince(start), 26);
    expect(DateTime(2026, 3, 31).daysSince(DateTime(2026, 3, 1)), 30);
    expect(DateTime(2026, 3, 30, 0, 30).minusDays(1), DateTime(2026, 3, 29, 0, 30));
    expect(weekStartOf(DateTime(2026, 10, 27)), DateTime(2026, 10, 26));
  });

  test('program day, dates and streak across autumn and spring changes',
      () async {
    var now = DateTime(2026, 10, 27, 12);
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => now;
    await p.load('t');
    await p.commission(
        start: DateTime(2026, 10, 1), gymDays: const [1, 3, 5], weightKg: 80, reminders: const {});
    expect(p.programDay, 27);
    expect(p.dateForProgramDay(27), DateTime(2026, 10, 27));
    expect(p.monthStart(2), DateTime(2026, 10, 31));
    for (var d = DateTime(2026, 10, 1); !d.isAfter(DateTime(2026, 10, 27)); d = d.plusDays(1)) {
      if (d.day == 25) continue; // one forgiven miss
      for (final n in nonNegotiables.take(7)) {
        p.setCheck(d, n.id, true);
      }
    }
    expect(p.streak, 26);

    now = DateTime(2026, 3, 31, 12);
    SharedPreferences.setMockInitialValues({});
    final q = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => now;
    await q.load('u');
    await q.commission(
        start: DateTime(2026, 3, 1), gymDays: const [1, 3, 5], weightKg: 80, reminders: const {});
    expect(q.programDay, 31);
  });
}

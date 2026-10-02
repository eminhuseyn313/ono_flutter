import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/data/emin_system.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/services/brief_generator.dart';
import 'package:ono/services/reminder_service.dart';

/// Friday 2 Oct 2026, noon. The program starts Tue 1 Sep → day 32, month 2.
final _today = DateTime(2026, 10, 2, 12);
final _start = DateTime(2026, 9, 1);

class _RecordingReminders implements ReminderService {
  List<PlannedReminder> last = const [];
  @override
  Future<void> init({required void Function(String route) onOpen}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> sync(List<PlannedReminder> reminders) async => last = reminders;
}

Future<PersonalSystemProvider> _commissioned(
    {ReminderService? reminders, BriefGenerator? briefs}) async {
  final p = PersonalSystemProvider(
    gateway: MockPersonalSystemGateway(),
    reminders: reminders,
    briefGenerator: briefs,
  )..clock = () => _today;
  await p.load('test');
  await p.commission(
    start: _start,
    gymDays: const [1, 3, 5],
    weightKg: 82,
    reminders: const {},
  );
  return p;
}

void _hold(PersonalSystemProvider p, DateTime day, [int n = 7]) {
  for (final item in nonNegotiables.take(n)) {
    p.setCheck(day, item.id, true);
  }
}

DateTime _daysAgo(int n) => dayOnly(_today).subtract(Duration(days: n));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh install is not commissioned', () async {
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway());
    await p.load('test');
    expect(p.isCommissioned, isFalse);
  });

  test('timeline follows the start date', () async {
    final p = await _commissioned();
    expect(p.programDay, 32);
    expect(p.programMonth, 2);
    expect(p.programWeek, 5);
    expect(p.dayOfMonth, 2);
    expect(p.phase.name, phaseFor(2).name);
    expect(p.latestWeight, 82);

    p.setProgramStart(DateTime(2026, 10, 12));
    expect(p.hasStarted, isFalse);
    expect(p.daysUntilStart, 10);
  });

  test('score counts only Daily 10 items', () async {
    final p = await _commissioned();
    final day = dayOnly(_today);
    _hold(p, day, 3);
    p.toggleGym(day); // gym is not part of the Daily 10
    p.togglePriority(day, 0);
    expect(p.scoreFor(day), 3);
    p.toggleCheck(day, nonNegotiables.first.id);
    expect(p.scoreFor(day), 2);
  });

  test('streak counts back from yesterday when today is not held yet',
      () async {
    final p = await _commissioned();
    for (var i = 1; i <= 4; i++) {
      _hold(p, _daysAgo(i));
    }
    _hold(p, _daysAgo(5), 6); // breaks the run
    for (var i = 6; i <= 12; i++) {
      _hold(p, _daysAgo(i));
    }
    expect(p.streak, 4);
    _hold(p, _daysAgo(0));
    expect(p.streak, 5);
    expect(p.bestStreak, 7);
    expect(p.daysHeld, 12);
  });

  test('protein auto-ticks at 150 g', () async {
    final p = await _commissioned();
    final day = dayOnly(_today);
    p.addProtein(day, 90);
    expect(p.isChecked(day, 'protein'), isFalse);
    p.addProtein(day, 60);
    expect(p.proteinFor(day), 150);
    expect(p.isChecked(day, 'protein'), isTrue);
  });

  test('protocol use ticks its item and builds mastery', () async {
    final p = await _commissioned();
    expect(p.masteryOf('sigh'), 'Not started');
    p.logProtocolUse('sigh');
    expect(p.isChecked(_today, 'sigh'), isTrue);
    expect(p.masteryOf('sigh'), 'Aware');
    for (var i = 0; i < 4; i++) {
      p.logProtocolUse('sigh');
    }
    expect(p.masteryOf('sigh'), 'Practised');
    expect(nextMasteryAt(5), 20);
    expect(nextMasteryAt(60), isNull);
  });

  test('gym sessions remember the last weights and the best lift', () async {
    final p = await _commissioned();
    final push = gymPlan.first;
    final exercise = push.exercises.first.name;
    p.saveGymSession(_daysAgo(2), push.id, [
      {
        'name': exercise,
        'sets': [
          {'kg': 60, 'reps': 8}
        ]
      },
    ]);
    p.saveGymSession(_daysAgo(0), push.id, [
      {
        'name': exercise,
        'sets': [
          {'kg': 62.5, 'reps': 8}
        ]
      },
    ]);
    expect(p.gymDone(_daysAgo(0)), isTrue);
    expect(p.bestLift(exercise), 62.5);
    expect(p.lastSessionFor(push.id)?.date, _daysAgo(0));
  });

  test('month stats cover only that month', () async {
    final p = await _commissioned();
    _hold(p, _daysAgo(0), 10); // month 2
    _hold(p, _daysAgo(1), 7); // month 2 (1 Oct)
    _hold(p, _daysAgo(3), 9); // month 1
    p.logWeight(81, date: _daysAgo(0));
    p.addLog('linkedin');
    final m2 = p.statsForMonth(2);
    expect(m2.daysElapsed, 2);
    expect(m2.daysHeld, 2);
    expect(m2.daily10Average, 8.5);
    expect(m2.posts, 1);
    expect(m2.weightStart, 82); // the commission weigh-in, dated today
    expect(m2.weightEnd, 81);
    final m1 = p.statsForMonth(1);
    expect(m1.daysElapsed, 30);
    expect(m1.daysHeld, 1);
    expect(m1.weightStart, isNull);
  });

  test('Sunday report produces a device brief from real data', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final week = weekStartOf(_today);
    final brief = await p.submitReport(WeeklyReport(
      id: 'r1',
      weekStart: week,
      nonNegotiableAverage: 5.2,
      gymSessions: 1,
      bestMoment: 'Shipped the onboarding spec',
      hardestMoment: 'Froze when Ali asked about the roadmap',
      workSituation: 'Pitching the Business ID pricing change on Tuesday',
      createdAt: _today,
    ));
    expect(brief, isNotNull);
    expect(brief!.source, 'device');
    expect(brief.headline, startsWith('Reset week'));
    expect(brief.coaching, contains('Business ID pricing'));
    expect(brief.tasks, isNotEmpty);
    expect(brief.tasks.length, lessThanOrEqualTo(6));
    expect(p.briefForWeek(week.add(const Duration(days: 7)))?.id, brief.id);
  });

  test('remote brief falls back to the device on error', () async {
    final remote = RemoteBriefGenerator((_) async => throw Exception('down'));
    final p = await _commissioned(briefs: remote);
    final brief = await p.submitReport(WeeklyReport(
      id: 'r1',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 8.4,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief?.source, 'device');
    expect(brief?.headline, startsWith('Strong week'));
  });

  test('export and import round-trip everything', () async {
    final p = await _commissioned();
    _hold(p, _daysAgo(1), 8);
    p.addEvidence('built', 'Launched Business ID v2');
    p.addProtein(_today, 40);
    final json = p.exportJson();

    final q = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await q.load('other');
    expect(q.importJson(json), isTrue);
    expect(q.isCommissioned, isTrue);
    expect(q.scoreFor(_daysAgo(1)), 8);
    expect(q.proteinFor(_today), 40);
    expect(q.evidenceCount, p.evidenceCount);
    expect(q.importJson('not json'), isFalse);
  });

  test('reminders follow toggles and gym days', () async {
    final rec = _RecordingReminders();
    final p = await _commissioned(reminders: rec);
    final planned = p.plannedReminders();
    final gym = planned.where((r) => r.title.contains('19:00')).toList();
    expect(gym.map((r) => r.weekday).toSet(), {1, 3, 5});
    expect(planned.map((r) => r.id).toSet().length, planned.length,
        reason: 'notification ids must be unique');
    final caffeineOn = planned.any((r) => r.title == 'No caffeine after 1pm' ||
        r.body.contains('no caffeine after 13:00'));
    expect(caffeineOn, isFalse, reason: 'caffeine is off by default');

    p.setReminder('gym', false);
    expect(rec.last.where((r) => r.title.contains('19:00')), isEmpty);
    p.setGymDays(const [2, 4, 6]);
    p.setReminder('gym', true);
    expect(
        rec.last
            .where((r) => r.title.contains('19:00'))
            .map((r) => r.weekday)
            .toSet(),
        {2, 4, 6});
  });
}

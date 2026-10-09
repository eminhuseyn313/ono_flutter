import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/data/emin_system.dart';
import 'package:ono/data/growth_templates.dart';
import 'package:ono/data/life_wheel.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/router.dart';
import 'package:ono/services/app_shortcuts.dart';
import 'package:ono/services/brief_generator.dart';
import 'package:ono/services/calendar_service.dart';
import 'package:ono/services/health_service.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/services/widget_sync.dart';

import '../support/fake_calendar.dart';
import '../support/fake_health.dart';

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
  final Map<int, DateTime> once = {};
  @override
  Future<void> notifyOnce(int id, DateTime at,
          {required String title,
          required String body,
          required String route}) async =>
      once[id] = at;
  @override
  Future<void> cancel(int id) async => once.remove(id);
}

Future<PersonalSystemProvider> _commissioned(
    {ReminderService? reminders,
    BriefGenerator? briefs,
    HealthService? health}) async {
  final p = PersonalSystemProvider(
    gateway: MockPersonalSystemGateway(),
    reminders: reminders,
    briefGenerator: briefs,
    health: health,
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

  test('never miss twice: one slip is forgiven', () async {
    final p = await _commissioned();
    for (var i = 1; i <= 4; i++) {
      _hold(p, _daysAgo(i));
    }
    _hold(p, _daysAgo(5), 6); // a single slip
    for (var i = 6; i <= 12; i++) {
      _hold(p, _daysAgo(i));
    }
    expect(p.streak, 11, reason: 'today is still open');
    _hold(p, _daysAgo(0));
    expect(p.streak, 12);
    expect(p.bestStreak, 12);
    expect(p.daysHeld, 12);
  });

  test('two misses in a row end the streak', () async {
    final p = await _commissioned();
    for (var i = 1; i <= 3; i++) {
      _hold(p, _daysAgo(i));
    }
    // 4 and 5 days ago: missed.
    for (var i = 6; i <= 10; i++) {
      _hold(p, _daysAgo(i));
    }
    expect(p.streak, 3);
    expect(p.bestStreak, 5);
  });

  test('only one forgiven slip per 7 days', () async {
    final p = await _commissioned();
    _hold(p, _daysAgo(1));
    _hold(p, _daysAgo(2));
    // 3 days ago: slip (second within a week → ends the run)
    for (var i = 4; i <= 6; i++) {
      _hold(p, _daysAgo(i));
    }
    // 7 days ago: slip (forgiven)
    for (var i = 8; i <= 10; i++) {
      _hold(p, _daysAgo(i));
    }
    expect(p.streak, 2);
    expect(p.bestStreak, 6);
  });

  test('recovery day: yesterday slipped and today is not held yet', () async {
    final p = await _commissioned();
    _hold(p, _daysAgo(2));
    expect(p.isRecoveryDay, isTrue);
    expect(p.streak, 1, reason: 'the slip is pending, the streak survives');
    _hold(p, _daysAgo(0));
    expect(p.isRecoveryDay, isFalse);
    expect(p.streak, 2);
  });

  test('fresh starts: Monday, new month, new phase', () async {
    final p = await _commissioned();
    // Monday 5 Oct (day 35): last week everything held except bed.
    p.clock = () => DateTime(2026, 10, 5, 8);
    for (var i = 1; i <= 7; i++) {
      for (final n in nonNegotiables.where((n) => n.id != 'bed')) {
        p.setCheck(DateTime(2026, 10, 5).subtract(Duration(days: i)), n.id,
            true);
      }
    }
    final monday = p.freshStartFor(DateTime(2026, 10, 5))!;
    expect(monday.itemId, 'bed');
    expect(monday.body, contains(p.cueFor('bed')));
    expect(monday.route, isNull);

    // Day 31 = first day of month 2 (still Foundation).
    p.clock = () => DateTime(2026, 10, 1, 8);
    final month = p.freshStartFor(DateTime(2026, 10, 1))!;
    expect(month.key, 'fresh:month:2');
    expect(month.route, '/month/2');

    // Day 61 = month 3: Craft begins.
    p.clock = () => DateTime(2026, 10, 31, 8);
    final phase = p.freshStartFor(DateTime(2026, 10, 31))!;
    expect(phase.key, startsWith('fresh:phase:'));
    expect(phase.title, contains(phaseFor(3).name));

    // An ordinary Wednesday has none.
    p.clock = () => DateTime(2026, 10, 7, 8);
    expect(p.freshStartFor(DateTime(2026, 10, 7)), isNull);
  });

  test('if-then cues: default, custom, reset, in reminders and backups',
      () async {
    final rec = _RecordingReminders();
    final p = await _commissioned(reminders: rec);
    expect(p.cueFor('bed'), defaultCues['bed']);
    p.setCue('bed', 'When the kids are asleep → phone on the charger');
    expect(p.hasCustomCue('bed'), isTrue);
    expect(rec.last.any((r) => r.body.contains('kids are asleep')), isTrue);

    final q = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await q.load('other');
    q.importJson(p.exportJson());
    expect(q.cueFor('bed'), contains('kids are asleep'));

    p.setCue('bed', '');
    expect(p.hasCustomCue('bed'), isFalse);
    expect(p.cueFor('bed'), defaultCues['bed']);
  });

  test('check-in: one per day, shoulder flag, weekly count', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    p.saveCheckin(today,
        energy: 3, mood: 0, sleep: 7, pain: 4, stiffness: 2);
    expect(p.shoulderFlag(today), isFalse);
    p.saveCheckin(today,
        energy: 2, mood: -1, sleep: 6, pain: 5, stiffness: 0);
    expect(p.logsOn(today, 'checkin').length, 1, reason: 'replaced, not added');
    expect(p.shoulderFlag(today), isTrue);
    p.saveCheckin(_daysAgo(1),
        energy: 3, mood: 0, sleep: 7, pain: 1, stiffness: 3);
    expect(p.shoulderFlag(_daysAgo(1)), isTrue, reason: 'stiffness 30+ min');
    expect(p.flagDaysInWeekEnding(today), 2);
    expect(p.averageOf(p.checkinsEnding(today, 7), 'sleep'), 6.5);
  });

  test('the brief reacts to flagged shoulders and short sleep', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final week = weekStartOf(_today);
    for (var i = 0; i < 3; i++) {
      p.saveCheckin(week.add(Duration(days: i)),
          energy: 2, mood: 0, sleep: 6, pain: 6, stiffness: 3);
    }
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: week,
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.join(' '), contains('rheumatologist'));
    expect(brief.adjustments.join(' '), contains('6.0 h'));
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

  test('SM-2 schedule: 1 → 6 → longer; "again" resets', () {
    final t = DateTime(2026, 10, 2);
    var c = CardSchedule.fresh(t);
    c = c.review(4, t);
    expect(c.interval, 1);
    c = c.review(4, t);
    expect(c.interval, 6);
    c = c.review(4, t);
    expect(c.interval, greaterThan(6));
    final easy = c.review(5, t).interval;
    final hard = c.review(3, t).interval;
    expect(easy, greaterThan(hard));
    final again = c.review(0, t);
    expect(again.interval, 1);
    expect(again.reps, 0);
    expect(again.ease, lessThan(c.ease));
  });

  test('deck: 5 new cards a day, due cards first, Feynman notes become cards',
      () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    expect(p.dueCards(today).length, newCardsPerDay);
    final first = p.dueCards(today).first;
    p.gradeCard(first.id, 4);
    expect(p.dueCards(today).length, newCardsPerDay - 1,
        reason: 'one new card already introduced today');
    expect(p.scheduleOf(first.id)!.due, today.add(const Duration(days: 1)));

    p.logProtocolUse('feynman',
        text: 'Opportunity solution trees map outcomes to opportunities.',
        data: {'book': 'Continuous Discovery Habits', 'chapter': 'Ch. 3'});
    expect(p.allCards.where((c) => c.source == 'feynman').length, 1);

    p.addCustomCard('Kaspi QR acceptance?', '95% of merchants');
    expect(p.allCards.where((c) => c.source == 'custom').length, 1);
    final total = p.deckStats.total;
    p.finishReview(3);
    expect(p.logsOn(today, 'anki').single.number('count'), 3);

    final q = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await q.load('other');
    q.importJson(p.exportJson());
    expect(q.deckStats.total, total);
    expect(q.scheduleOf(first.id), isNotNull);
  });

  test('cockpit: 1:1 follow-ups, decision reviews after 90 days, readiness',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    p.addOneOnOne(
        withWhom: 'Ali',
        decided: 'Business ID pricing goes to the board',
        followUps: ['Draft the PR/FAQ', '', 'Book Rustam']);
    expect(p.openFollowUps.length, 2);
    p.setDone(p.openFollowUps.first.key, true);
    expect(p.openFollowUps.single.text, 'Book Rustam');

    p.addDecision(
        decision: 'Ship KYC v2 without the video step',
        options: 'Ship / wait for vendor',
        why: 'Drop-off at video is 38%',
        expected: 'Completion +15 pp');
    expect(p.dueDecisionReviews(_today), isEmpty);
    final later = _today.add(const Duration(days: 90));
    expect(p.dueDecisionReviews(later).length, 1);
    p.reviewDecision(p.dueDecisionReviews(later).first.id,
        outcome: 'Completion +11 pp', verdict: 'mixed');
    expect(p.dueDecisionReviews(later), isEmpty);
    expect(p.logsOf('decision').first.str('verdict'), 'mixed');

    expect(p.readinessGap, isNull);
    p.saveReadiness({
      for (final d in readinessDimensions) d.id: 4,
      'strategy': 2,
    });
    p.saveReadiness({...p.readiness, 'leadership': 3});
    expect(p.logsOf('readiness').length, 1, reason: 'one per month');
    expect(p.readinessGap!.id, 'strategy');

    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 8,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.join(' '), contains('Strategy & business'));
  });

  test('automatic = rated 4+ and done on 80% of 30 days; reminder goes quiet',
      () async {
    final rec = _RecordingReminders();
    final p = await _commissioned(reminders: rec);
    for (var i = 1; i <= 30; i++) {
      p.setCheck(_daysAgo(i), 'bed', true);
      if (i <= 20) p.setCheck(_daysAgo(i), 'scan', true);
    }
    p.saveAutomaticity({for (final n in nonNegotiables) n.id: 5});
    expect(p.isAutomatic('bed'), isTrue);
    expect(p.isAutomatic('scan'), isFalse, reason: '20/30 is under 80%');
    expect(p.isAutomatic('manifesto'), isFalse, reason: 'never done');
    expect(p.automaticItems, ['bed']);
    expect(rec.last.any((r) => r.title == reminderDefs
        .firstWhere((d) => d.id == 'bed').label), isFalse);

    p.saveAutomaticity({for (final n in nonNegotiables) n.id: 3});
    expect(p.isAutomatic('bed'), isFalse, reason: 'feels effortful again');
  });

  test('monthly checks are due from day 25', () async {
    final p = await _commissioned();
    expect(p.automaticityDue, isFalse, reason: 'day 2 of month 2');
    p.clock = () => DateTime(2026, 10, 25, 9); // day 55 → day 25 of month 2
    expect(p.dayOfMonth, 25);
    expect(p.automaticityDue, isTrue);
    p.saveAutomaticity({for (final n in nonNegotiables) n.id: 2});
    expect(p.automaticityDue, isFalse);
  });

  test('sleep samples: overlaps merged, bed start = earliest, in-bed fallback',
      () {
    final e = DateTime(2026, 10, 1);
    final night = summarizeNight([
      (from: e.add(const Duration(hours: 22, minutes: 10)), to: e.add(const Duration(hours: 30)), asleep: false),
      (from: e.add(const Duration(hours: 22, minutes: 40)), to: e.add(const Duration(hours: 26)), asleep: true),
      // Watch and iPhone overlap 01:00–02:00; counted once.
      (from: e.add(const Duration(hours: 25)), to: e.add(const Duration(hours: 29, minutes: 30)), asleep: true),
    ])!;
    expect(night.bedStart, e.add(const Duration(hours: 22, minutes: 10)));
    expect(night.wake, e.add(const Duration(hours: 30)));
    expect(night.asleepHours, closeTo(6.83, 0.01));

    final inBedOnly = summarizeNight([
      (from: e.add(const Duration(hours: 23)), to: e.add(const Duration(hours: 30)), asleep: false),
    ])!;
    expect(inBedOnly.asleepHours, 7);
    expect(summarizeNight(const []), isNull);
  });

  test('Apple Health: sync stores sleep, ticks bed by 22:45, writes weight',
      () async {
    final today = dayOnly(_today);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoAgo = today.subtract(const Duration(days: 2));
    final fake = FakeHealthService(nights: {
      // Last night: in bed 22:20 → ticks yesterday's "bed".
      today: NightSleep(
          bedStart: yesterday.add(const Duration(hours: 22, minutes: 20)),
          wake: today.add(const Duration(hours: 6)),
          asleepHours: 7.2),
      // The night before: 23:30 → no tick.
      yesterday: NightSleep(
          bedStart: twoAgo.add(const Duration(hours: 23, minutes: 30)),
          wake: yesterday.add(const Duration(hours: 6, minutes: 30)),
          asleepHours: 6.4),
    });
    final p = await _commissioned(health: fake);
    expect(p.healthConnected, isFalse);
    expect(await p.connectHealth(), isNull);
    expect(p.healthConnected, isTrue);
    expect(p.sleepHoursFor(today), 7.2);
    expect(p.isChecked(yesterday, 'bed'), isTrue);
    expect(p.isChecked(twoAgo, 'bed'), isFalse);
    expect(p.logsOn(today, 'vitals').single.number('hrv'), 52);

    await p.syncHealth();
    expect(p.logsOn(today, 'sleep').length, 1, reason: 'replaced, not added');

    p.logWeight(81.6);
    expect(fake.weights, [81.6]);
  });

  test('Apple Health: unavailable build or refusal explains what to do',
      () async {
    final p = await _commissioned(
        health: FakeHealthService(unavailable: true));
    expect(await p.connectHealth(), 'Enable HealthKit');
    expect(p.healthConnected, isFalse);

    final q = await _commissioned(health: FakeHealthService(grant: false));
    expect(await q.connectHealth(), contains('Health app'));
    expect(q.healthConnected, isFalse);
  });

  test('widget: snapshot of today, pushed once after a burst of changes',
      () async {
    final sync = NoopWidgetSync();
    final p = PersonalSystemProvider(
        gateway: MockPersonalSystemGateway(), widgets: sync)
      ..clock = () => _today;
    await p.load('test');
    await p.commission(
        start: _start, gymDays: const [1, 3, 5], reminders: const {});
    for (final n in nonNegotiables.take(7)) {
      p.setCheck(_today, n.id, true);
    }
    p.addProtein(_today, 40);
    expect(sync.last, isNull, reason: 'batched, not pushed per tick');
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    final s = sync.last!;
    expect(s.score, 7);
    expect(s.protein, 40);
    expect(s.dateKey, dateKey(_today));
    expect(s.blocks.length, dailySchedule.length);
    final values = s.toValues();
    expect(values['blocks'], contains('"m":'));
    expect(values.values.every((v) => v is int || v is String), isTrue);
  });

  test('rest timer: notifies at the end, cancelled on skip', () async {
    final r = _RecordingReminders();
    final p = await _commissioned(reminders: r);
    final key = gymPlan.first.exercises.firstWhere((e) => e.keyLift);
    expect(PersonalSystemProvider.restFor(key), const Duration(minutes: 2));
    final end = _today.add(const Duration(seconds: 90));
    await p.startRest(end, next: 'Bench · set 2');
    expect(r.once[PersonalSystemProvider.restNotificationId], end);
    expect(PersonalSystemProvider.restNotificationId >= onceIdBase, isTrue);
    await p.cancelRest();
    expect(r.once, isEmpty);
  });

  test('patterns: need 5+ days each side and a real gap', () async {
    final p = await _commissioned();
    expect(p.patterns(), isEmpty);
    // 20 nights: bed on time on even days, then energy 4 vs 2 next morning.
    for (var i = 2; i <= 21; i++) {
      final d = _daysAgo(i);
      if (i.isEven) p.setCheck(d, 'bed', true);
      p.saveCheckin(d.add(const Duration(days: 1)),
          energy: i.isEven ? 4 : 2, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    }
    final bed = p.patterns().firstWhere((x) => x.id == 'bed_energy');
    expect(bed.withHabit, 4);
    expect(bed.without, 2);
    expect(bed.daysWith, 10);
    expect(bed.daysWithout, 10);
    expect(bed.fmt(bed.withHabit), '4.0/5');
    // Sleep was 7 h every day: no "without" side, so no sleep pattern.
    expect(p.patterns().any((x) => x.id == 'sleep_score'), isFalse);
    // Too few days on one side → nothing.
    expect(p.patterns(minDays: 11).any((x) => x.id == 'bed_energy'), isFalse);
  });

  test('the brief cites the strongest personal pattern', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    for (var i = 2; i <= 21; i++) {
      final d = _daysAgo(i);
      if (i.isEven) p.setCheck(d, 'caffeine', true);
      p.saveCheckin(d.add(const Duration(days: 1)),
          energy: 3, mood: 0, sleep: i.isEven ? 7.5 : 6, pain: 0, stiffness: 0);
    }
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.join(' '),
        contains('No caffeine after 1pm → sleep that night 7.5 h vs 6.0 h without'));
  });

  test('tool timers notify at the end and cancel cleanly', () async {
    final r = _RecordingReminders();
    final p = await _commissioned(reminders: r);
    final end = _today.add(const Duration(minutes: 15));
    await p.notifyTimerEnd(end,
        title: '15 minutes done', body: 'Time is up.', route: '/tool/scan');
    expect(r.once[PersonalSystemProvider.timerNotificationId], end);
    await p.startRest(end, next: 'x');
    await p.cancelTimerEnd();
    expect(r.once.keys, [PersonalSystemProvider.restNotificationId],
        reason: 'the rest timer is separate');
  });

  test('every Home Screen shortcut opens a real route', () {
    final router = createRouter(AuthProvider(gateway: MockAuthGateway()));
    for (final s in appShortcutList) {
      expect(routeForShortcut(s.type), s.route);
      final m = router.configuration.findMatch(s.route);
      expect(m.isError || m.matches.isEmpty, isFalse, reason: s.route);
    }
    expect(routeForShortcut('nope'), isNull);
  });

  test('calendar: meetings today, nudges before real ones, key people',
      () async {
    final r = _RecordingReminders();
    final day = dayOnly(_today); // _today is 12:00
    Meeting m(String id, String title, int h, int min, int len,
            [List<String> who = const ['A', 'B']]) =>
        Meeting(
            id: id,
            title: title,
            start: day.add(Duration(hours: h, minutes: min)),
            end: day.add(Duration(hours: h, minutes: min + len)),
            attendees: who);
    final cal = FakeCalendarService(meetings: [
      m('past', 'Standup', 9, 30, 15),
      m('lunch', 'Squad sync', 12, 0, 30),
      m('ali', '1:1', 15, 0, 30, ['Ali Mammadov', 'Emin']),
      m('focus', 'Focus: PR/FAQ', 16, 0, 90, const []),
      m('rustam', 'Roadmap with Rustam', 17, 0, 60, const []),
    ]);
    final p = PersonalSystemProvider(
        gateway: MockPersonalSystemGateway(), reminders: r, calendar: cal)
      ..clock = () => _today;
    await p.load('test');
    await p.commission(start: _start, gymDays: const [1, 3, 5], reminders: const {});
    expect(p.meetingsFor(_today), isEmpty, reason: 'not connected yet');

    expect(await p.connectCalendar(), isNull);
    expect(p.calendarConnected, isTrue);
    expect(p.meetingsFor(_today).length, 5);
    expect(p.meetingsFor(_today.add(const Duration(days: 1))), isEmpty);
    // Focus block has nobody in it; the rest are real.
    expect(p.meetingHours(_today), 0.25 + 0.5 + 0.5 + 1);
    expect(p.lunchReadAtRisk(_today), isTrue);
    expect(PersonalSystemProvider.isKeyMeeting(cal.meetings[2]), isTrue);
    expect(PersonalSystemProvider.isKeyMeeting(cal.meetings[4]), isTrue);
    expect(PersonalSystemProvider.isKeyMeeting(cal.meetings[1]), isFalse);
    // "Alina" isn't Ali.
    expect(
        PersonalSystemProvider.isKeyMeeting(
            m('x', 'Coffee', 9, 0, 10, ['Alina K', 'Emin'])),
        isFalse);

    // Nudges only for real meetings still ahead (15:00 and 17:00), plus a
    // debrief 5 min after each key meeting ends.
    expect(r.once.values.toList()..sort(), [
      day.add(const Duration(hours: 14, minutes: 50)),
      day.add(const Duration(hours: 15, minutes: 35)),
      day.add(const Duration(hours: 16, minutes: 50)),
      day.add(const Duration(hours: 18, minutes: 5)),
    ]);
    // Free: 12:30–15:00 (after the lunch read); 15:30–16:00 is too short.
    expect(p.freeBlocks(_today), [
      (
        start: day.add(const Duration(hours: 12, minutes: 30)),
        end: day.add(const Duration(hours: 15))
      ),
    ]);
    // 15:40: the 1:1 with Ali ended 10 min ago and isn't logged yet.
    p.clock = () => day.add(const Duration(hours: 15, minutes: 40));
    expect(p.debriefsDue(p.clock()).map((m) => m.id), ['ali']);
    p.addOneOnOne(withWhom: 'Ali', decided: 'Ship it', followUps: const []);
    expect(p.debriefsDue(p.clock()), isEmpty);
    p.clock = () => _today;
    // Meetings never go into saved state.
    expect(p.exportJson(), isNot(contains('Roadmap with Rustam')));

    await p.disconnectCalendar();
    expect(r.once, isEmpty);
    expect(p.meetingsFor(_today), isEmpty);
  });

  test('calendar refused: explains where to allow it', () async {
    final p = PersonalSystemProvider(
        gateway: MockPersonalSystemGateway(),
        calendar: FakeCalendarService(grant: false))
      ..clock = () => _today;
    await p.load('test');
    expect(await p.connectCalendar(), contains('Settings'));
    expect(p.calendarConnected, isFalse);
  });

  test('shutdown: carries unfinished priorities, writes tomorrow, logs', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    final tomorrow = today.add(const Duration(days: 1));
    p.setPriority(today, 0, 'Pricing memo to Ali');
    p.setPriority(today, 1, 'KYC v2 spec');
    p.togglePriority(today, 0);
    expect(p.carryOverFrom(today), ['KYC v2 spec']);
    expect(p.shutdownFor(today), isNull);
    p.completeShutdown(today,
        tomorrow: ['KYC v2 spec', 'Book the review', ''],
        open: 'Worried about the vendor delay');
    expect(p.prioritiesFor(tomorrow), ['KYC v2 spec', 'Book the review', '']);
    final s = p.shutdownFor(today)!;
    expect(s.number('done'), 1);
    expect(s.number('set'), 2);
    expect(s.str('open'), 'Worried about the vendor delay');
    // Saving again replaces, not duplicates.
    p.completeShutdown(today, tomorrow: ['KYC v2 spec']);
    expect(p.logsOn(today, 'shutdown').length, 1);
    expect(p.shutdownsInWeek(today), 1);
  });

  test('deep work: week and artifact-month minutes', () async {
    final p = await _commissioned();
    p.logFocus(90, 'artifact');
    p.logFocus(50, 'skill');
    expect(p.focusMinutesInWeek(_today), 140);
    expect(p.artifactMinutesThisMonth, 90);
    expect(p.focusMinutesInWeek(_today.subtract(const Duration(days: 7))), 0);
  });

  test('letters: sealed until their date, then waiting to be read', () async {
    final p = await _commissioned();
    final day = dayOnly(_today);
    p.writeLetter('Remember why you started.', day.add(const Duration(days: 30)));
    p.writeLetter('Day 540.', p.programEnd);
    expect(p.letters.length, 2);
    expect(p.lettersToOpen, isEmpty);
    expect(p.programEnd, _start.add(const Duration(days: programDays - 1)));
    expect(p.nextPhaseStart, p.monthStart(3), reason: 'Foundation is 1–2');
    p.clock = () => _today.add(const Duration(days: 30));
    expect(p.lettersToOpen.map((l) => l.text), ['Remember why you started.']);
    p.markLetterRead(p.lettersToOpen.first.id);
    expect(p.lettersToOpen, isEmpty);
    expect(p.letterIsOpen(p.letters.firstWhere((l) => l.text == 'Day 540.')),
        isFalse);
  });

  test('brief: deep work and shutdowns', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    p.logFocus(50, 'artifact');
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    final text = brief!.adjustments.join(' ');
    expect(text, contains('Deep work: 0.8 h'));
    expect(text, contains('Evening shutdown on 0 of 7'));
  });

  test('Big 3: set, tick, score; blanking one clears its tick', () async {
    final p = await _commissioned();
    expect(p.hasWeekPlan(_today), isFalse);
    p.setWeekOutcome(_today, 0, 'OST draft reviewed by Ali');
    p.setWeekOutcome(_today, 1, 'KYC v2 scope signed off');
    p.toggleWeekOutcome(_today, 1);
    expect(p.weekOutcomes(_today),
        ['OST draft reviewed by Ali', 'KYC v2 scope signed off', '']);
    expect(p.weekOutcomeScore(_today), (1, 2));
    // Any day of the same week reads the same plan; next week is empty.
    expect(p.weekOutcomeScore(weekStartOf(_today).add(const Duration(days: 6))),
        (1, 2));
    expect(p.hasWeekPlan(_today.add(const Duration(days: 7))), isFalse);
    p.setWeekOutcome(_today, 1, '');
    expect(p.weekOutcomeDone(_today, 1), isFalse);
    expect(p.logsOf('week_plan').length, 1, reason: 'one entry per week');
  });

  test('people: cadence, 1:1s count as contact, overdue order', () async {
    final p = await _commissioned();
    p.clock = () => _today.subtract(const Duration(days: 20));
    final ali = p.addPerson('Ali', role: 'Manager', every: 7);
    final leyla = p.addPerson('Leyla Aliyeva', role: 'Head of Product', every: 30);
    p.clock = () => _today;
    expect(p.daysSinceContact(ali), 20);
    expect(p.peopleDue.map((x) => x.text), ['Ali'],
        reason: 'Leyla is 20 of 30 days in');
    // A 1:1 with "Ali Mammadov" counts for Ali — but "Aliyeva" isn't Ali.
    p.addOneOnOne(withWhom: 'Ali Mammadov', decided: 'x', followUps: const []);
    expect(p.lastContact(ali), dayOnly(_today));
    expect(p.peopleDue, isEmpty);
    p.logTouch(leyla, note: 'Coffee');
    expect(p.daysSinceContact(leyla), 0);
    p.removePerson(leyla.id);
    expect(p.people.map((x) => x.text), ['Ali']);
    expect(p.logsOf('touch'), isEmpty, reason: 'her touches go too');
  });

  test('shutdown saves one good thing as a win, once', () async {
    final p = await _commissioned();
    p.completeShutdown(_today, tomorrow: const [], win: 'Ali took the pricing memo as is');
    p.completeShutdown(_today, tomorrow: const [], win: 'Ali took the pricing memo as is');
    expect(p.logsOn(_today, 'win').map((w) => w.text),
        ['Ali took the pricing memo as is']);
  });

  test('brief: Big 3 review and overdue people', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    p.setWeekOutcome(_today, 0, 'OST draft');
    p.setWeekOutcome(_today, 1, 'Scope signed');
    p.toggleWeekOutcome(_today, 0);
    p.clock = () => _today.subtract(const Duration(days: 10));
    p.addPerson('Rustam', every: 7);
    p.clock = () => _today;
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    final text = brief!.adjustments.join(' ');
    expect(text, contains('Week outcomes: 1 of 2 done'));
    expect(text, contains('Overdue to reach out: Rustam'));
  });

  test('growth plan: one area a month, rotating drills, reps and feedback',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    expect(p.focusArea(), isNull);
    expect(p.suggestedArea.id, growthAreas.first.id);
    p.saveReadiness({for (final d in readinessDimensions) d.id: 4, 'strategy': 2});
    expect(p.suggestedArea.id, 'strategy', reason: 'the readiness gap');

    p.setFocus('composure', startRating: 2);
    final area = p.focusArea()!;
    expect(area.name, 'Composure under pressure');
    expect(area.personal, isTrue);
    expect(p.focusRatings(), (2, null));

    // The suggested drill moves on once it has been practised.
    final first = p.drillFor(area, _today);
    p.logRep(area, first,
        did: 'Sighed before the pricing review',
        noticed: 'Voice steadier',
        lesson: 'The sigh works when I do it in the car, not in the room',
        next: 'Sigh in the car before every Ali meeting');
    expect(p.drillFor(area, _today).title, isNot(first.title));
    expect(p.repsIn('composure', p.programMonth).single.str('lesson'),
        startsWith('The sigh works'));
    expect(p.repsInWeek(_today), 1);

    p.logFeedback(area, from: 'Ali', said: 'You rush the first minute', action: 'Rehearse the opening');
    expect(p.feedbackIn('composure', p.programMonth).single.str('from'), 'Ali');

    p.rateFocusEnd(3);
    expect(p.focusRatings(), (2, 3));
    // Re-choosing the same area keeps the end rating; one entry per month.
    p.setFocus('composure', startRating: 2);
    expect(p.focusRatings(), (2, 3));
    expect(p.growthHistory.length, 1);
    // Next month starts empty.
    expect(p.focusArea(p.programMonth + 1), isNull);

    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.first,
        startsWith('Growth — Composure under pressure: 1 rep this week'));
  });

  test('every growth area has five drills and a feedback question', () {
    expect(growthAreas.length, 8);
    for (final a in growthAreas) {
      expect(a.drills.length, 5, reason: a.id);
      expect(a.ask, endsWith('?'), reason: a.id);
    }
    // Professional areas are the readiness dimensions.
    expect(growthAreas.where((a) => !a.personal).map((a) => a.id),
        readinessDimensions.map((d) => d.id));
  });

  test('values: saved in his words, weekly check, least-lived value', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    expect(p.values, isEmpty);
    p.setValues([
      (name: 'Craft', meaning: 'Build things that last'),
      (name: 'Family', meaning: 'Home comes first'),
      (name: 'Courage', meaning: 'Say the hard thing'),
    ]);
    expect(p.values.map((v) => v.name), ['Craft', 'Family', 'Courage']);
    expect(p.logsOf('values').length, 1);
    p.setValues([(name: 'Craft', meaning: 'x'), (name: 'Calm', meaning: 'y'), (name: 'Courage', meaning: 'z')]);
    expect(p.logsOf('values').length, 1, reason: 'edited in place');

    p.saveValuesCheck(_today, {'Craft': 5, 'Calm': 2, 'Courage': 4});
    expect(p.valueGap(_today), 'Calm');
    p.saveValuesCheck(_today, {'Craft': 5, 'Calm': 4, 'Courage': 4});
    expect(p.valueGap(_today), isNull, reason: 'all at 4+');
    p.saveValuesCheck(_today, {'Craft': 5, 'Calm': 3, 'Courage': 4});

    p.logAffirmation('Craft', 'I built Paya from nothing', before: 'pricing review');
    expect(p.logsOf('affirmation').single.str('before'), 'pricing review');

    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.join(' '), contains('reflected Calm least'));
  });

  test('self-coaching: commitment comes due, kept or dropped', () async {
    final p = await _commissioned();
    final c = p.logCoaching(
        goal: 'Own Business ID onboarding',
        reality: 'Ali assigns it piece by piece',
        options: ['Ask directly', 'Write a proposal', ''],
        will: 'Send Ali a one-page ownership proposal',
        by: dayOnly(_today).add(const Duration(days: 3)),
        commitment: 8);
    expect(c.data['options'], ['Ask directly', 'Write a proposal']);
    expect(p.commitmentsDue(_today), isEmpty);
    final later = _today.add(const Duration(days: 3));
    expect(p.commitmentsDue(later).single.id, c.id);
    p.setCommitmentKept(c.id, true);
    expect(p.commitmentsDue(later), isEmpty);
    final d = p.logCoaching(
        goal: 'g', reality: 'r', options: const [], will: 'w',
        by: dayOnly(_today), commitment: 5);
    p.dropCommitment(d.id);
    expect(p.commitmentsDue(later), isEmpty);
  });

  test('Head of Product case: per dimension, honest about gaps', () async {
    final p = await _commissioned();
    p.saveReadiness({for (final d in readinessDimensions) d.id: 4, 'strategy': 2});
    p.setFocus('communication', startRating: 2);
    final area = p.focusArea()!;
    p.logRep(area, area.drills.first,
        did: 'BLUF update to Ali', lesson: 'Decision first gets a reply in minutes');
    p.logFeedback(area, from: 'Ali', said: 'Clearer this month');
    p.addLog('artifact', data: {'title': 'OST — onboarding', 'kind': 'OST', 'status': 'shipped', 'month': 1});
    final c = p.caseFor('communication');
    expect(c.rating, 4);
    expect(c.reps.length, 1);
    final text = p.caseText();
    expect(text, contains('EXECUTIVE COMMUNICATION — 4/5 (bar 4)'));
    expect(text, contains('→ Decision first gets a reply in minutes'));
    expect(text, contains('Feedback from Ali: "Clearer this month"'));
    expect(text, contains('OST — onboarding (OST, shipped)'));
    expect(text, contains('Nothing logged yet'), reason: 'unpractised areas say so');
    expect(text, contains("WHERE I'M STILL GROWING\nStrategy & business"));
  });

  test('own growth areas: from a template, edited, practised, removed',
      () async {
    final p = await _commissioned();
    final t = areaTemplates.firstWhere((a) => a.id == 't_relationships');
    final a = p.saveCustomArea(t.copyWith(name: 'Being present at home'));
    expect(a.id, startsWith('c_'), reason: 'a template is copied, not used');
    expect(a.custom, isTrue);
    expect(p.customAreas.single.name, 'Being present at home');
    expect(p.allGrowthAreas.length, growthAreas.length + 1);
    expect(p.areaById(a.id).drills.length, 5);

    // Editing keeps the id; one entry per area.
    p.saveCustomArea(a.copyWith(bar: 'Phone away from 20:30'));
    expect(p.customAreas.single.bar, 'Phone away from 20:30');
    expect(p.logsOf('growth_area').length, 1);

    p.setFocus(a.id, startRating: 2);
    expect(p.focusArea()!.name, 'Being present at home');
    p.addDrill(p.focusArea()!, const Drill('Walk after dinner', 'Together, 20 min', 'Four evenings'));
    expect(p.drillsOf(p.focusArea()!).last.title, 'Walk after dinner');
    expect(p.removeCustomArea(a.id), isFalse, reason: 'it is this month\'s area');

    // Drills added to one of the profile's areas sit after the built-ins.
    final comp = growthAreas.firstWhere((g) => g.id == 'composure');
    p.addDrill(comp, const Drill('Cold open', 'Start the meeting with the ask', 'No preamble'));
    expect(p.drillsOf(comp).length, comp.drills.length + 1);
    expect(comp.drills.length, 5, reason: 'the profile content is untouched');

    p.setFocus('composure', startRating: 2);
    expect(p.removeCustomArea(a.id), isTrue);
    expect(p.customAreas, isEmpty);
    expect(p.areaById(a.id).name, 'Removed area');
    expect(p.growthHistory.first.str('name'), 'Composure under pressure');
  });

  test('templates: general, complete, unique', () {
    final ids = areaTemplates.map((t) => t.id).toSet();
    expect(ids.length, areaTemplates.length);
    for (final t in areaTemplates) {
      expect(t.drills.length, 5, reason: t.id);
      expect(t.ask, endsWith('?'), reason: t.id);
      expect(t.bar, isNotEmpty);
      // Written for anyone: nothing specific to his job or people.
      for (final text in [t.bar, t.ask, ...t.drills.expand((d) => [d.how, d.signal])]) {
        expect(text, isNot(matches(RegExp(r'Ali|Rustam|Business ID|PASHA'))), reason: t.id);
      }
    }
  });

  test('goals: WOOP saved, numeric progress and pace, lower-is-better', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final day = dayOnly(_today);
    final run = p.saveGoal(
      title: 'Marathon under 4 hours',
      why: 'Prove I can train through a hard job',
      obstacle: 'I skip runs when work runs late',
      plan: 'If work runs late, I run at 6:30 the next morning',
      identity: 'I am someone who trains in any week',
      deadline: day.add(const Duration(days: 100)),
      unit: 'min',
      start: 270,
      target: 239,
    )!;
    expect(p.goalIsNumeric(run), isTrue);
    expect(p.goalProgress(run), 0);
    p.logGoalValue(run.id, 254.5);
    expect(p.goalCurrent(p.goalById(run.id)!), 254.5);
    expect(p.goalProgress(p.goalById(run.id)!), closeTo(0.5, 0.001),
        reason: 'lower is better: 270 → 239, halfway at 254.5');
    // 40 days into 100: 40% expected; 50% done is on track (within 10).
    p.clock = () => _today.add(const Duration(days: 40));
    expect(p.goalExpected(p.goalById(run.id)!), closeTo(0.4, 0.001));
    expect(p.goalPace(p.goalById(run.id)!), 'on track');
    p.clock = () => _today.add(const Duration(days: 80));
    expect(p.goalPace(p.goalById(run.id)!), 'behind');
    expect(p.goalsToMeasure.single.id, run.id, reason: '80 days without a number');
    p.clock = () => _today;
  });

  test('goals: milestones, at most three active, closing and deleting', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final hop = p.saveGoal(
        title: 'Become ${activeProfile.targetRole}',
        milestones: ['Own an area', 'Ship the OST', 'Promotion conversation', ''])!;
    expect(p.milestonesOf(hop).length, 3);
    p.toggleMilestone(hop.id, 0);
    expect(p.goalProgress(p.goalById(hop.id)!), closeTo(1 / 3, 0.001));
    // Editing keeps ticks on milestones that still exist.
    p.saveGoal(
        id: hop.id,
        title: 'Become ${activeProfile.targetRole}',
        milestones: ['Own an area', 'Ship the OST', 'Promotion conversation', 'Lead a team']);
    expect(p.milestonesOf(p.goalById(hop.id)!).first.done, isTrue);
    expect(p.goals.length, 1, reason: 'edited in place');

    p.saveGoal(title: 'Savings', unit: 'AZN', start: 0, target: 10000);
    p.saveGoal(title: 'Read 12 books', unit: 'books', start: 0, target: 12);
    expect(p.saveGoal(title: 'Fourth', start: 0, target: 1), isNull);
    p.setGoalStatus(hop.id, 'achieved');
    expect(p.activeGoals.length, 2);
    expect(p.saveGoal(title: 'Fourth', start: 0, target: 1), isNotNull);

    final savings = p.activeGoals.firstWhere((g) => g.text == 'Savings');
    p.logGoalValue(savings.id, 2500);
    p.deleteGoal(savings.id);
    expect(p.logsOf('goal_value'), isEmpty, reason: 'measurements go with it');

    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief, isNotNull);
    expect(p.goalSummaries().first, contains('% done'));
  });

  test('progress note: built from real data, sent once a week', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    // _today is a Friday.
    expect(_today.weekday, DateTime.friday);
    expect(p.noteDue(_today), isFalse, reason: 'nothing to report yet');
    expect(p.progressNoteText(_today, to: 'Ali'), contains('What moved this week'));
    p.saveGoal(title: 'Savings', unit: 'AZN', start: 0, target: 1000,
        deadline: dayOnly(_today).add(const Duration(days: 100)));
    p.setWeekOutcome(_today, 0, 'Ship the OST draft');
    p.toggleWeekOutcome(_today, 0);
    p.addLog('win', text: 'Pricing memo approved');
    expect(p.noteDue(_today), isTrue);
    final text = p.progressNoteText(_today, to: 'Ali', ask: 'Feedback on the OST');
    expect(text, startsWith('Hi Ali — my week:'));
    expect(text, contains('• Savings: 0%'));
    expect(text, contains("This week's three: 1 of 1 done"));
    expect(text, contains('• ✓ Ship the OST draft'));
    expect(text, contains('• Pricing memo approved'));
    expect(text, endsWith('Where you could help: Feedback on the OST'));
    expect(p.defaultNoteRecipient, activeProfile.manager);
    p.logProgressNote('Ali', text);
    expect(p.noteSentInWeek(_today), isTrue);
    expect(p.noteDue(_today), isFalse);
    expect(p.noteDue(_today.subtract(const Duration(days: 3))), isFalse,
        reason: 'only Friday to Sunday');
  });

  test('setback: logged, and the next step lands on today', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final today = dayOnly(_today);
    p.setPriority(today, 0, 'Spec review');
    p.logSetback(
        kind: 'It was a heavy week',
        happened: 'Skipped the gym twice',
        nextStep: '20-minute walk at lunch');
    expect(p.prioritiesFor(today), ['Spec review', '20-minute walk at lunch', '']);
    expect(p.setbacksInWeek(_today), 1);
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(brief!.adjustments.join(' '), contains('1 setback met with a next step'));
  });

  test('quarterly review: 90-day quarters, due window, wheel, goal decisions',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    // _start = 1 Sep, _today = 2 Oct: day 32, quarter 1, not due.
    expect(p.programQuarter, 1);
    expect(p.quarterReviewDue, isFalse);
    // Day 85: inside the last week of quarter 1.
    p.clock = () => _start.add(const Duration(days: 84, hours: 12));
    expect(p.quarterReviewDue, isTrue);
    expect(p.quarterToReview, 1);
    // Day 93: the first days of quarter 2 still close quarter 1.
    p.clock = () => _start.add(const Duration(days: 92, hours: 12));
    expect(p.programQuarter, 2);
    expect(p.quarterToReview, 1);
    expect(p.quarterReviewDue, isTrue);

    final g = p.saveGoal(title: 'Savings', start: 0, target: 100)!;
    final keep = p.saveGoal(title: 'Run', start: 30, target: 25)!;
    p.saveQuarterReview(1,
        wheel: {for (final a in lifeAreas) a.id: 7, 'money': 3},
        wins: 'Shipped the OST',
        lessons: 'I overcommit in week 1',
        goalDecisions: {g.id: 'drop', keep.id: 'keep'},
        nextFocus: 'Sleep and savings');
    expect(p.quarterReviewDue, isFalse);
    expect(p.goalById(g.id)!.str('status'), 'dropped');
    expect(p.activeGoals.single.id, keep.id);
    expect(p.lowestLifeArea!.id, 'money');
    expect(p.latestWheel['money'], 3);
    // Saving again replaces the quarter's review.
    p.saveQuarterReview(1, wheel: {for (final a in lifeAreas) a.id: 6});
    expect(p.logsOf('quarterly_review').length, 1);
    p.clock = () => _today;
  });

  test('life wheel: eight general areas, each with a matching template', () {
    expect(lifeAreas.length, 8);
    final ids = areaTemplates.map((t) => t.id).toSet();
    for (final a in lifeAreas) {
      expect(ids, contains(a.template), reason: a.id);
    }
  });

  test('profile: edited profile drives everything, survives export, resets',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    expect(p.profileEdited, isFalse);
    expect(activeProfile.targetRole, builtInProfile.targetRole);
    final runner = builtInProfile.copyWith(
      name: 'Leyla Mammadova',
      firstName: 'Leyla',
      currentRole: 'Amateur runner',
      targetRole: 'Sub-3 marathoner',
      organisation: '',
      focus: '',
      keyPeople: const [KeyPerson('Tural', 'Coach', every: 7, primary: true)],
    );
    p.saveProfile(runner);
    expect(p.profileEdited, isTrue);
    expect(activeProfile.name, 'Leyla Mammadova');
    expect(activeProfile.manager, 'Tural');
    expect(activeProfile.roleLine, 'Amateur runner');
    expect(keyPeople, ['Tural']);
    expect(p.defaultNoteRecipient, 'Tural');
    // Saving again edits in place.
    p.saveProfile(runner.copyWith(targetRole: 'Sub-2:59'));
    expect(p.logsOf('profile').length, 1);
    expect(activeProfile.targetRole, 'Sub-2:59');

    // It travels with export/import into a fresh install.
    final json = p.exportJson();
    final q = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await q.load('other');
    expect(activeProfile.targetRole, builtInProfile.targetRole,
        reason: 'a fresh load without a saved profile uses the built-in one');
    expect(q.importJson(json), isTrue);
    expect(activeProfile.targetRole, 'Sub-2:59');

    q.resetProfile();
    expect(q.profileEdited, isFalse);
    expect(activeProfile.name, builtInProfile.name);
  });

  test('profile JSON round-trips', () {
    final back = Profile.fromJson(builtInProfile.toJson());
    expect(back.toJson(), builtInProfile.toJson());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/data/emin_system.dart';
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

    // Nudges only for real meetings still ahead: 15:00 and 17:00.
    expect(r.once.values.toList()..sort(), [
      day.add(const Duration(hours: 14, minutes: 50)),
      day.add(const Duration(hours: 16, minutes: 50)),
    ]);
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
}

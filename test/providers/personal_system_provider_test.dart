import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/data/emin_system.dart';
import 'package:ono/data/daily_library.dart';
import 'package:ono/data/growth_templates.dart';
import 'package:ono/data/plan_packs.dart';
import 'package:ono/data/life_wheel.dart';
import 'package:ono/data/tool_index.dart';
import 'package:ono/gateways/mock_auth_gateway.dart';
import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/providers/auth_provider.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';
import 'package:ono/router.dart';
import 'package:ono/screens/money_screen.dart' show parseAmount;
import 'package:ono/services/app_shortcuts.dart';
import 'package:ono/services/brief_generator.dart';
import 'package:ono/services/calendar_service.dart';
import 'package:ono/services/health_service.dart';
import 'package:ono/services/reminder_service.dart';
import 'package:ono/services/widget_sync.dart';

import '../support/fake_calendar.dart';
import '../support/fake_health.dart';
import 'package:ono/time.dart';

/// Friday 2 Oct 2026, noon. The program starts Tue 1 Sep → day 32, month 2.
final _today = DateTime(2026, 10, 2, 12);
final _start = DateTime(2026, 9, 1);

class _CapturingBriefs implements BriefGenerator {
  BriefInput? last;
  @override
  Future<WeeklyBrief> generate(BriefInput input) {
    last = input;
    return DeviceBriefGenerator().generate(input);
  }
}

class _RecordingReminders implements ReminderService {
  @override
  bool get supported => true;

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

DateTime _daysAgo(int n) => dayOnly(_today).minusDays(n);

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
        p.setCheck(DateTime(2026, 10, 5).minusDays(i), n.id,
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
      p.saveCheckin(week.plusDays(i),
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
    expect(p.briefForWeek(week.plusDays(7))?.id, brief.id);
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
    expect(p.scheduleOf(first.id)!.due, today.plusDays(1));

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
    final later = _today.plusDays(90);
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
    final yesterday = today.minusDays(1);
    final twoAgo = today.minusDays(2);
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

  test('widget: cleared on sign-out, so the next person sees nothing of theirs',
      () async {
    final sync = NoopWidgetSync();
    final p = PersonalSystemProvider(
        gateway: MockPersonalSystemGateway(), widgets: sync)
      ..clock = () => _today;
    await p.load('test');
    await p.commission(
        start: _start, gymDays: const [1, 3, 5], reminders: const {});
    await p.refreshWidget();
    expect(sync.last, isNotNull);
    p.signedOut();
    expect(sync.last, isNull);
  });

  test('remembered: no more nudges, history kept, a quiet day each year', () async {
    final p = await _commissioned();
    final mum = p.addPerson('Maria Lopez', role: 'Mum', every: 7);
    p.updatePerson(mum, birthday: '${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}');
    p.logTouch(p.personById(mum.id)!, note: 'Sunday lunch', date: _today.minusDays(30));
    expect(p.peopleDue.map((x) => x.id), contains(mum.id));
    expect(p.birthdaysSoon(_today), hasLength(1));
    p.setRemembered(p.personById(mum.id)!, true);
    expect(p.peopleDue, isEmpty);
    expect(p.birthdaysSoon(_today), isEmpty);
    expect(p.activePeople, isEmpty);
    expect(p.people, hasLength(1), reason: 'they stay, with their history');
    expect(p.lastContact(p.personById(mum.id)!), isNotNull);
    // Their birthday is a quiet line instead, until opened.
    expect(p.remembranceDays(_today).single.id, mum.id);
    p.setDone(p.remembranceSeenKey(p.personById(mum.id)!, _today), true);
    expect(p.remembranceDays(_today), isEmpty);
    // The anniversary, from the next year on.
    p.setDiedOn(p.personById(mum.id)!, _today.minusDays(400));
    final anniversary = DateTime(_today.year, p.diedOn(p.personById(mum.id)!)!.month,
        p.diedOn(p.personById(mum.id)!)!.day);
    expect(p.remembranceDays(anniversary).map((x) => x.id), contains(mum.id));
    expect(p.saveRemembrance(p.personById(mum.id)!, {'miss': '  '}), isNull);
    p.saveRemembrance(p.personById(mum.id)!, {'taught': 'Feed people first', 'carry': 'Sunday lunch'});
    expect(p.remembrancesOf(p.personById(mum.id)!).single.text, 'Sunday lunch');
    expect(p.journalText(), contains('Remembering Maria Lopez'));
    p.removePerson(mum.id);
    expect(p.logsOf('remembrance'), isEmpty);
  });

  test('load check: heavy two months running reaches the brief', () async {
    final p = await _commissioned();
    final m = p.programMonth;
    expect(p.heavyLoad, isNull);
    p.setMonthLoad(m, level: 5);
    p.setMonthLoad(m, from: ['work', 'nonsense']);
    expect(p.loadFromOf(m), ['work']);
    expect(p.loadLevelOf(m), 5);
    if (m >= 2) {
      expect(p.heavyLoad, isNull, reason: 'one heavy month is not a pattern');
      p.setMonthLoad(m - 1, level: 4, from: ['care']);
      expect(p.heavyLoad, containsAll(['work', 'caring for someone']));
      p.setMonthLoad(m, level: 2);
      expect(p.heavyLoad, isNull);
      // An old heavy pair isn't news once later months are rated lighter
      // or the current month is rated at all.
      p.setMonthLoad(m, level: 4);
      expect(p.heavyLoad, isNotNull);
    }
  });

  test('in my care: the next part of their story to ask about', () async {
    final p = await _commissioned();
    final dad = p.addPerson('Rauf', role: 'Father', every: 7);
    expect(p.nextStoryQuestion(dad), isNull, reason: 'only for someone in your care');
    p.setInMyCare(dad, true);
    expect(p.nextStoryQuestion(p.personById(dad.id)!), PersonalSystemProvider.storyQuestions.first.$2);
    p.setStoryAnswer(p.personById(dad.id)!, 'grew_up', 'A village by the sea');
    expect(p.nextStoryQuestion(p.personById(dad.id)!), PersonalSystemProvider.storyQuestions[1].$2);
  });

  test('calibration: nothing until ten are reviewed, then per level', () async {
    final p = await _commissioned();
    for (var i = 0; i < 10; i++) {
      p.addDecision(decision: 'Bet $i', options: '', why: '', expected: '', confidence: i < 6 ? 85 : 55);
    }
    p.addDecision(decision: 'No level', options: '', why: '', expected: '', confidence: 70);
    expect(p.logsOf('decision').first.number('confidence'), isNull, reason: 'only known levels');
    final ds = p.logsOf('decision').where((d) => d.text.startsWith('Bet')).toList();
    for (final (i, d) in ds.take(9).indexed) {
      p.reviewDecision(d.id, outcome: '', verdict: i.isEven ? 'right' : 'wrong');
    }
    expect(p.calibration(), isEmpty, reason: 'nine reviewed is too few');
    p.reviewDecision(ds[9].id, outcome: '', verdict: 'right');
    final c = p.calibration();
    expect(c.map((e) => e.$1), containsAll([85, 55]));
    final at85 = c.firstWhere((e) => e.$1 == 85);
    expect(at85.$3, 6);
  });

  test('teach it: explaining what you learned counts as help, once', () async {
    final p = await _commissioned();
    final ana = p.addPerson('Ana Lima', role: 'Junior PM', every: 14);
    final l = p.addLearning('Thinking in Bets', kind: 'book')!;
    p.applyLearning(l.id, principle: 'Separate decisions from outcomes', experiment: 'Rate two calls', teachTo: 'Ana');
    p.recordExperimentResult(l.id, 'It helped', taught: true);
    p.recordExperimentResult(l.id, 'It helped a lot', taught: true);
    expect(p.helpsFor(p.personById(ana.id)!).single.text, 'Taught: Separate decisions from outcomes');
  });

  test('a short list leaves room for one bad item', () {
    expect(PersonalSystemProvider.targetOf(3), 2);
    expect(PersonalSystemProvider.targetOf(4), 3);
    expect(PersonalSystemProvider.targetOf(5), 4);
    expect(PersonalSystemProvider.targetOf(10), 7);
    expect(PersonalSystemProvider.targetOf(1), 1);
  });

  test('a minimum day always lowers the bar, even on a short list', () {
    for (final n in [1, 2, 3, 4, 5, 10, 15]) {
      final min = PersonalSystemProvider.minTargetOf(n);
      expect(min, greaterThanOrEqualTo(1));
      if (PersonalSystemProvider.targetOf(n) > 1) {
        expect(min, lessThan(PersonalSystemProvider.targetOf(n)), reason: '$n items');
      }
    }
    expect(PersonalSystemProvider.minTargetOf(10), 5);
  });

  test('no recovery card before anything was ever ticked', () async {
    final p = await _commissioned();
    expect(p.isRecoveryDay, isFalse);
  });

  test('someone else\'s miss: a lesson in the playbook, not a story idea', () async {
    final p = await _commissioned();
    p.logAar(event: 'A launch I watched slip', improve: 'Ship the smallest version first', wentWell: false, theirs: true);
    expect(p.playbook().first.from, startsWith('From someone else'));
    expect(p.storyIdeas, isEmpty);
    expect(p.allCards.any((c) => c.id.startsWith('aar:')), isTrue);
  });

  test('check-ups to ask about follow age and sex, never without a birth year', () async {
    final p = await _commissioned();
    expect(p.checkupsToAsk, isEmpty);
    final year = p.logicalToday.year;
    p.setCareDetails(sex: 'female', birthYear: year - 45);
    final ids = p.checkupsToAsk.map((c) => c.id).toSet();
    expect(ids, containsAll(['bp', 'lipids', 'bowel', 'cervical', 'breast']));
    expect(ids, isNot(contains('prostate')));
    expect(ids, isNot(contains('shingles')), reason: 'from 50');
    final bp = p.checkupsToAsk.firstWhere((c) => c.id == 'bp');
    p.takeCheckup(bp);
    expect(p.upkeep.single.text, 'Blood pressure check');
    expect(p.checkupsToAsk.any((c) => c.id == 'bp'), isFalse);
    final hepc = p.checkupsToAsk.firstWhere((c) => c.id == 'hepc');
    p.takeCheckup(hepc);
    expect(p.checkupsToAsk.any((c) => c.id == 'hepc'), isFalse, reason: 'asked once');
    p.setCareDetails(sex: 'male');
    expect(p.checkupsToAsk.any((c) => c.id == 'breast'), isFalse);
    p.setCareDetails(birthYear: 1800);
    expect(p.careBirthYear, isNull, reason: 'a typo is refused');
  });

  test('hand-offs: postpone, and one help however often it is closed', () async {
    final p = await _commissioned();
    final ana = p.addPerson('Ana Lima', role: 'Analyst', every: 14);
    final h = p.addHandoff(what: 'The weekly report', to: 'Ana Lima', weeks: 1)!;
    p.postponeHandoff(h.id, 2);
    expect(p.openHandoffs.single.str('check_on'), dateKey(p.logicalToday.plusDays(14)));
    p.closeHandoff(h.id, 'well');
    p.closeHandoff(h.id, 'helped');
    expect(p.helpsFor(p.personById(ana.id)!), hasLength(1));
    expect(p.logsOf('help').single.id, 'help_${h.id}');
  });

  test('care details: one record, forgettable, and care for others stays separate', () async {
    final p = await _commissioned();
    p.setCareDetails(sex: 'female');
    p.setCareDetails(birthYear: timeNow().year - 45);
    expect(p.logsOf('care_details').single.id, 'care_details');
    final mum = p.addPerson('Mum', every: 7);
    p.setInMyCare(mum, true);
    p.addUpkeep('Blood pressure check', 365, forPerson: mum.id);
    expect(p.checkupsToAsk.any((c) => c.id == 'bp'), isTrue, reason: 'her check is not yours');
    final bp = p.checkupsToAsk.firstWhere((c) => c.id == 'bp');
    p.takeCheckup(bp, lastDone: timeNow().subtract(const Duration(days: 30)));
    p.takeCheckup(bp);
    expect(p.upkeep.where((u) => p.careKindOf(u) == 'health'), hasLength(1));
    p.forgetCareDetails();
    expect(p.careBirthYear, isNull);
    expect(p.logsOf('care_details'), isEmpty);
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
      p.saveCheckin(d.plusDays(1),
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
      p.saveCheckin(d.plusDays(1),
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
    expect(p.meetingsFor(_today.plusDays(1)), isEmpty);
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
    final tomorrow = today.plusDays(1);
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
    expect(p.focusMinutesInWeek(_today.minusDays(7)), 0);
  });

  test('letters: sealed until their date, then waiting to be read', () async {
    final p = await _commissioned();
    final day = dayOnly(_today);
    p.writeLetter('Remember why you started.', day.plusDays(30));
    p.writeLetter('Day 540.', p.programEnd);
    expect(p.letters.length, 2);
    expect(p.lettersToOpen, isEmpty);
    expect(p.programEnd, _start.plusDays(programDays - 1));
    expect(p.nextPhaseStart, p.monthStart(3), reason: 'Foundation is 1–2');
    p.clock = () => _today.plusDays(30);
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
    expect(p.weekOutcomeScore(weekStartOf(_today).plusDays(6)),
        (1, 2));
    expect(p.hasWeekPlan(_today.plusDays(7)), isFalse);
    p.setWeekOutcome(_today, 1, '');
    expect(p.weekOutcomeDone(_today, 1), isFalse);
    expect(p.logsOf('week_plan').length, 1, reason: 'one entry per week');
  });

  test('people: cadence, 1:1s count as contact, overdue order', () async {
    final p = await _commissioned();
    p.clock = () => _today.minusDays(20);
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
    p.clock = () => _today.minusDays(10);
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

    // The week's drill holds while it's practised; next week moves on.
    final first = p.drillFor(area, _today);
    p.logRep(area, first,
        did: 'Sighed before the pricing review',
        noticed: 'Voice steadier',
        lesson: 'The sigh works when I do it in the car, not in the room',
        next: 'Sigh in the car before every Ali meeting');
    expect(p.drillFor(area, _today).title, first.title);
    expect(p.drillFor(area, _today.plusDays(7)).title, isNot(first.title));
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
        by: dayOnly(_today).plusDays(3),
        commitment: 8);
    expect(c.data['options'], ['Ask directly', 'Write a proposal']);
    expect(p.commitmentsDue(_today), isEmpty);
    final later = _today.plusDays(3);
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
      deadline: day.plusDays(100),
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
    p.clock = () => _today.plusDays(40);
    expect(p.goalExpected(p.goalById(run.id)!), closeTo(0.4, 0.001));
    expect(p.goalPace(p.goalById(run.id)!), 'on track');
    p.clock = () => _today.plusDays(80);
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
        deadline: dayOnly(_today).plusDays(100));
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
    expect(p.noteDue(_today.minusDays(3)), isFalse,
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
    p.clock = () => _start.plusDays(84).add(const Duration(hours: 12));
    expect(p.quarterReviewDue, isTrue);
    expect(p.quarterToReview, 1);
    // Day 93: the first days of quarter 2 still close quarter 1.
    p.clock = () => _start.plusDays(92).add(const Duration(hours: 12));
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

  test('daily items: retire, add, hold at 70%, brief handles new items',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    expect(p.dailyCount, 10);
    expect(p.holdTarget, 7);
    final today = dayOnly(_today);
    for (final n in nonNegotiables.take(7)) {
      p.setCheck(today, n.id, true);
    }
    expect(p.isHeld(today), isTrue);

    // Retire one he has ticked: 9 items, 7 to hold (ceil 6.3); 6 ticked.
    expect(p.setItemActive(nonNegotiables.first.id, false), isTrue);
    expect(p.dailyCount, 9);
    expect(p.holdTarget, 7);
    expect(p.scoreFor(today), 6);
    expect(p.isHeld(today), isFalse);

    final spanish = p.addDailyItem('10 minutes of Spanish',
        lane: 'skill', when: 'evening', cue: 'When dinner ends → app open')!;
    expect(p.dailyCount, 10);
    expect(p.cueFor(spanish.id), 'When dinner ends → app open');
    p.setCheck(today, spanish.id, true);
    expect(p.scoreFor(today), 7);
    expect(p.isHeld(today), isTrue);

    // The brief names a new item it has no built-in advice for.
    for (final n in p.dailyItems.where((n) => n.id != spanish.id)) {
      for (var i = 0; i < 7; i++) {
        p.setCheck(weekStartOf(_today).plusDays(i), n.id, true);
      }
    }
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 9,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    // The new weak item reaches the brief — as one of the week's three, not twice.
    expect(brief!.tasks.join(' '), contains('10 minutes of Spanish'));
    expect(brief.tasks.where((t) => t.contains('10 minutes of Spanish')), hasLength(1));

    // Limits: never below 3 items.
    for (final n in nonNegotiables.skip(1)) {
      p.setItemActive(n.id, false);
    }
    expect(p.dailyCount, PersonalSystemProvider.minDailyItems);
    expect(p.removeDailyItem(spanish.id), isFalse);
    expect(p.setItemActive(nonNegotiables.first.id, true), isTrue);
    expect(p.removeDailyItem(spanish.id), isTrue);
  });

  test('levels: the general ladder puts the bar at 4; own levels win', () async {
    final p = await _commissioned();
    final comp = growthAreas.firstWhere((a) => a.id == 'composure');
    final ladder = levelsOf(comp);
    expect(ladder.length, 5);
    expect(ladder[3], contains(comp.bar));
    final own = p.saveCustomArea(const GrowthArea('', 'Free throws',
        bar: '80% in games',
        ask: 'Where does my form break?',
        drills: [Drill('100 a day', 'Shoot 100', 'Logged')],
        levels: ['<40%', '40–55%', '55–70%', '70–80%', '80%+ in games']));
    expect(levelsOf(p.areaById(own.id)).last, '80%+ in games');
    expect(GrowthArea.fromJson(own.toJson()).levels.length, 5);
  });

  test('learning: queue → active → applied → experiment result', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    expect(p.addLearning('  '), isNull);
    final book = p.addLearning('Continuous Discovery Habits', by: 'Teresa Torres')!;
    expect(p.learningWith('queue').single.id, book.id);
    p.startLearning(book.id);
    expect(p.learningWith('active').single.str('started'), dateKey(_today));
    p.applyLearning(book.id,
        principle: 'Talk to a customer every week, not every quarter',
        experiment: 'Two SME interviews before Friday');
    expect(p.learningWith('done').single.str('principle'),
        startsWith('Talk to a customer'));
    expect(p.experimentsToReview, isEmpty, reason: 'give it a week');
    p.clock = () => _today.plusDays(7);
    expect(p.experimentsToReview.single.id, book.id);
    p.recordExperimentResult(book.id, 'Both changed the onboarding brief — keep');
    expect(p.experimentsToReview, isEmpty);
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
    expect(brief, isNotNull);
    p.removeLearning(book.id);
    expect(p.learning, isEmpty);
  });

  test('relationship rituals and presence', () async {
    final p = await _commissioned();
    final wife = p.addPerson('Aysel', role: 'Wife', every: 7);
    expect(p.ritualOf(wife), '');
    p.setRitual(wife, 'Friday dinner, phones away');
    final w = p.people.single;
    expect(p.ritualOf(w), 'Friday dinner, phones away');
    expect(p.presenceOf(w), isNull);
    p.logTouch(w, quality: 3);
    p.logTouch(w, quality: 2);
    p.logTouch(w); // unrated: not counted
    expect(p.presenceOf(w), 2.5);
    expect(p.daysSinceContact(w), 0);
  });

  test('experiments: before vs during from real check-ins, keep or drop',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    // Energy 2 for the 7 days before, then 4 during.
    for (var i = 1; i <= 7; i++) {
      p.saveCheckin(_daysAgo(i), energy: 2, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    }
    final e = p.startExperiment(
        change: 'No screens after 22:00', measure: 'energy', days: 7,
        expect: 'More energy')!;
    expect(p.experimentDay(e), 1);
    expect(p.startExperiment(change: ' ', measure: 'energy'), isNull);
    for (var i = 0; i < 7; i++) {
      p.saveCheckin(dayOnly(_today).plusDays(i),
          energy: 4, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    }
    p.clock = () => _today.plusDays(7);
    final c = p.experimentCompare(p.experimentById(e.id)!);
    expect(c.before, 2);
    expect(c.during, 4);
    expect(c.nBefore, 7);
    expect(c.nDuring, 7);
    expect(p.experimentsToClose.single.id, e.id);
    p.closeExperiment(e.id, keep: true, result: 'Asleep faster');
    expect(p.experimentsWith('kept').single.str('result'), 'Asleep faster');
    expect(p.experimentsToClose, isEmpty);
    p.clock = () => _today;
  });

  test('recovery: planned rest never breaks the streak; brief nudges', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    // Held 5 days, then two days off (planned), then held today.
    for (var i = 7; i >= 3; i--) {
      _hold(p, _daysAgo(i));
    }
    expect(p.restPlannedSoon, isFalse);
    p.planRest('day', _daysAgo(2), _daysAgo(1), note: 'Family weekend');
    _hold(p, dayOnly(_today));
    expect(p.isRestDay(_daysAgo(1)), isTrue);
    expect(p.streak, 6, reason: 'rest days are neither held nor missed');
    expect(p.isRecoveryDay, isFalse);
    // A lighter week still counts days.
    final light = p.planRest('light', dayOnly(_today).plusDays(7),
        dayOnly(_today).plusDays(13))!;
    expect(p.isRestDay(dayOnly(_today).plusDays(8)), isFalse);
    expect(p.restPlannedSoon, isTrue);
    expect(p.planRest('day', dayOnly(_today), _daysAgo(1)), isNull,
        reason: 'end before start');
    p.removeRest(light.id);
    p.logDetachment(_daysAgo(1), 3);
    expect(p.detachmentOn(_daysAgo(1)), 3);
  });

  test('stop-doing: weekly held or slipped; retire', () async {
    final p = await _commissioned();
    expect(p.addStop(''), isNull);
    final s = p.addStop('Email before 9', makesRoomFor: 'Deep work first thing')!;
    expect(p.stopHeldInWeek(s.id, _today), isNull);
    p.setStopHeld(s.id, _today, true);
    expect(p.stopHeldInWeek(s.id, _today), isTrue);
    p.setStopHeld(s.id, _today, false);
    expect(p.stopHeldInWeek(s.id, _today), isFalse);
    expect(p.stopHeldInWeek(s.id, _today.plusDays(7)), isNull);
    p.retireStop(s.id);
    expect(p.stopList, isEmpty);
  });

  test('gratitude letter and role models', () async {
    final p = await _commissioned();
    expect(p.writeGratitude('', 'x'), isNull);
    final g = p.writeGratitude('My first manager', 'You gave me the hard project')!;
    p.deliverGratitude(g.id, reaction: 'She cried, then laughed');
    expect(p.gratitudeLetters.single.str('status'), 'delivered');
    final m = p.addRoleModel('A CPO I admire',
        learn: 'How she says no to the CEO', question: 'How do you decide what not to build?')!;
    p.answerRoleModel(m.id, 'I write the trade-off down before the meeting');
    expect(p.roleModels.single.str('answer'), startsWith('I write'));
    p.removeRoleModel(m.id);
    expect(p.roleModels, isEmpty);
  });

  test('feedback round: one per quarter, answers, themes into the case',
      () async {
    final p = await _commissioned();
    expect(p.roundDue, isFalse, reason: 'day 32 of the quarter');
    p.clock = () => _start.plusDays(50);
    expect(p.roundDue, isTrue);
    final r = p.startRound(['Ali', 'Leyla', 'Tural', 'Fourth']);
    expect((r.data['people'] as List).length, 3);
    expect(p.roundDue, isFalse);
    p.addRoundAnswer(r.id, 'Ali', 'Keep the BLUF; change: decide faster');
    p.addRoundAnswer(r.id, 'Ali', 'Keep BLUF. Decide faster.');
    expect(p.roundAnswers(p.roundFor(1)!).length, 1, reason: 'replaced');
    p.setRoundThemes(r.id, 'Decide faster in the room');
    expect(p.caseText(), contains('Quarter 1: Decide faster in the room'));
    p.startRound(['Ali']);
    expect(p.logsOf('feedback_round').length, 1);
    expect(p.roundAnswers(p.roundFor(1)!).length, 1, reason: 'answers kept');
    p.clock = () => _today;
  });

  test('energy map: bands, peak only when clear, focus ratings count',
      () async {
    final p = await _commissioned();
    expect(p.energyPeak, isNull);
    void at(int day, int hour, int level) {
      p.clock = () => DateTime(2026, 9, day, hour, 10);
      p.logEnergy(level);
    }
    for (final d in [20, 21, 22]) {
      at(d, 10, 5);
      at(d, 15, 2);
    }
    // A 50-min block ending at 11:30 started in the morning band.
    p.clock = () => DateTime(2026, 9, 23, 11, 30);
    final f = p.logFocus(50, 'artifact')!;
    p.rateFocus(f.id, 4);
    p.clock = () => _today;
    final map = p.energyMap;
    expect(map['morning']!.n, 4);
    expect(map['morning']!.avg, closeTo(4.75, 0.01));
    expect(map['afternoon']!.avg, 2);
    expect(p.energyPeak!.id, 'morning');
  });

  test('plan builder: a new person gets their own profile, focus, goal and daily list',
      () async {
    final p = await _commissioned();
    expect(p.planBuilt, isFalse);
    final wheel = {for (final a in lifeAreas) a.id: 7}..['money'] = 3;
    final picks = dailyLibrary.where((d) => d.area == 'money' || d.area == 'health').take(7).toList();
    p.buildPlan(
      name: 'Leyla Mammadova',
      currentRole: 'Nurse',
      targetRole: 'Head nurse',
      wheel: wheel,
      area: areaTemplates.firstWhere((t) => t.id == 't_money'),
      areaRating: 2,
      goal: 'Three months of expenses saved',
      obstacle: 'Impulse buys after hard shifts',
      plan: 'When I want to buy after a shift, I wait until tomorrow.',
      deadline: DateTime(2027, 4, 1),
      daily: picks,
      replaceDaily: true,
    );
    expect(p.planBuilt, isTrue);
    expect(activeProfile.firstName, 'Leyla');
    expect(activeProfile.keyPeople, isEmpty);
    expect(activeProfile.targetRole, 'Head nurse');
    expect(p.lowestLifeArea!.id, 'money');
    expect(p.focusArea()!.name, startsWith('Money'));
    expect(p.focusArea()!.custom, isTrue);
    expect(p.activeGoals.single.text, 'Three months of expenses saved');
    expect(p.dailyCount, picks.length);
    expect(p.dailyItems.map((d) => d.title), containsAll(picks.map((d) => d.title)));
    expect(p.cueFor(p.dailyItems.first.id), isNotEmpty);
    expect(p.holdTarget, PersonalSystemProvider.targetOf(picks.length));
    // Building again for the same person adds, without duplicates.
    p.buildPlan(
        name: 'Leyla Mammadova',
        currentRole: 'Nurse',
        targetRole: 'Head nurse',
        area: p.focusArea()!,
        areaRating: 3,
        daily: [picks.first, dailyLibrary.firstWhere((d) => d.area == 'meaning')]);
    expect(p.dailyCount, picks.length + 1);
    expect(p.logsOf('growth_area').length, 1);
    p.resetProfile();
  });

  test('erase everything: data, profile and reminders gone, back to commission',
      () async {
    final p = await _commissioned();
    p.addLog('note', text: 'private');
    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    expect(p.dataSummary.entries, greaterThan(0));
    expect(p.syncsToCloud, isFalse);
    expect(p.coachIsRemote, isFalse);
    await p.eraseEverything();
    expect(p.isCommissioned, isFalse);
    expect(p.logsOf('note'), isEmpty);
    expect(activeProfile.name, builtInProfile.name);
    final reloaded = await MockPersonalSystemGateway().load('test');
    expect(reloaded.commissioned, isFalse);
    expect(reloaded.logs, isEmpty);
  });

  test('plan packs: built-ins apply once, mine travels as text without personal data',
      () async {
    final p = await _commissioned();
    final pack = planPacks.firstWhere((x) => x.name == 'Money reset');
    final before = p.dailyCount;
    final r = p.applyPack(pack);
    expect(r.areas, 1);
    expect(r.items, pack.daily.length);
    expect(r.goal, isTrue);
    expect(p.dailyCount, before + pack.daily.length);
    expect(p.stopList.map((s) => s.text), contains(pack.stops.first));
    final again = p.applyPack(pack);
    expect((again.areas, again.items, again.goal), (0, 0, false));

    p.addPerson('Leyla', role: 'Friend');
    final text = p.myPack(name: 'Shared').toText();
    expect(text, startsWith('ONO plan: Shared'));
    expect(text, isNot(contains('Leyla')));
    expect(text, isNot(contains(activeProfile.name)));
    final back = PlanPack.fromText('Try this:\n$text\nGood luck')!;
    expect(back.daily.length, p.dailyCount);
    expect(back.areas.single.name, startsWith('Money'));
    expect(back.goal!.title, pack.goal!.title);
    expect(PlanPack.fromText('no plan here'), isNull);

    final fresh = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await fresh.load('someone-else');
    await fresh.commission(
        start: _start, gymDays: const [1], reminders: const {});
    expect(fresh.activeGoals, isEmpty);
    fresh.applyPack(back, replaceDaily: true, withGoal: false);
    expect(fresh.dailyCount, back.daily.length);
    expect(fresh.activeGoals, isEmpty);
  });

  test('hard days: minimum lowers the bar, sick and skips are neutral, skips are scarce',
      () async {
    final p = await _commissioned();
    // _today is day 32. Hold days 25–28, then a sick day and a skip.
    for (var i = 7; i >= 4; i--) {
      _hold(p, _daysAgo(i));
    }
    expect(p.setHardDay(_daysAgo(3), 'sick'), isTrue);
    expect(p.setHardDay(_daysAgo(2), 'pass'), isTrue);
    expect(p.isExcused(_daysAgo(3)), isTrue);
    // First day back after two days off: the minimum counts.
    expect(p.isReentryDay(_daysAgo(1)), isTrue);
    expect(p.targetFor(_daysAgo(1)), p.minimumTarget);
    expect(p.minimumTarget, 5);
    _hold(p, _daysAgo(1), 5);
    expect(p.isHeld(_daysAgo(1)), isTrue);
    expect(p.streak, 5, reason: 'sick and skip neither break nor add');

    // Item rates ignore excused days.
    final rates = p.itemRates([_daysAgo(3), _daysAgo(1)]);
    expect(rates[nonNegotiables.first.id], 1.0);

    // Two skips a program month (the one above was in month 1).
    expect(p.passesLeft, 2);
    expect(p.setHardDay(_today, 'pass'), isTrue);
    expect(p.passesLeft, 1);
    expect(p.setHardDay(_today, 'minimum'), isTrue, reason: 'switching kind gives it back');
    expect(p.passesLeft, 2);
    expect(p.setHardDay(_today, 'pass'), isTrue);
    expect(p.setHardDay(_today.plusDays(1), 'pass'), isTrue);
    expect(p.setHardDay(_today.plusDays(2), 'pass'), isFalse);
    p.setHardDay(_today.plusDays(1), null);
    p.setHardDay(_today, null);
    expect(p.hardDayOn(_today), isNull);

    // A minimum day: half holds, and the minimum version shows.
    p.setHardDay(_today, 'minimum');
    expect(p.isMinimumDay(_today), isTrue);
    expect(p.minimumFor('read'), isNotEmpty);
    p.setMinimum('read', 'Two pages');
    expect(p.minimumFor('read'), 'Two pages');

    expect(p.hardDaysInWeek(_today).values.fold<int>(0, (a, b) => a + b), greaterThan(0));
    expect(p.sickDaysInRow(_daysAgo(3)), 1);
  });

  test('device brief: two sick days ask for an easy return', () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    final week = weekStartOf(_today);
    p.setHardDay(week, 'sick');
    p.setHardDay(week.plusDays(1), 'sick');
    await p.submitReport(WeeklyReport(
        id: 'r',
        weekStart: week,
        nonNegotiableAverage: 5,
        gymSessions: 1,
        bestMoment: '',
        hardestMoment: '',
        workSituation: '',
        createdAt: _today));
    final brief = p.briefs.first;
    expect(brief.adjustments.join(' '), contains('You were sick 2 days'));
  });

  test('partner: pact, due on the check-in day, honest update, record',
      () async {
    final p = await _commissioned();
    expect(p.partnerCheckinDue, isFalse);
    // _today is a Friday.
    p.setPartner('Sam Aliyev', mine: 'Train 3x', theirs: 'Write daily', weekday: DateTime.friday);
    expect(p.partnerCheckinDue, isTrue);
    p.setHardDay(_daysAgo(1), 'sick');
    final text = p.partnerUpdateText(_today);
    expect(text, contains('Hi Sam'));
    expect(text, contains('My commitment: Train 3x'));
    expect(text, contains('1 sick day'));
    expect(text, contains('"Write daily"'));
    p.recordPartnerCheckin(_today, mine: 'kept', theirs: 'partly');
    expect(p.partnerCheckinDue, isFalse);
    expect(p.partnerRecord(), (mine: 1, theirs: 0, weeks: 1));
    p.endPartnership();
    expect(p.partner, isNull);
  });

  test('coach report: the period in facts, no private writing', () async {
    final p = await _commissioned();
    _hold(p, _daysAgo(1));
    p.addLog('note', text: 'very private thought');
    p.addLog('win', text: 'Shipped the review');
    p.setHardDay(_today, 'minimum');
    final text = p.coachReportText(p.monthStart(p.programMonth), _today.plusDays(1));
    expect(text, contains('DAILY PLAN'));
    expect(text, contains('1 minimum day'));
    expect(text, contains('Shipped the review'));
    expect(text, isNot(contains('very private thought')));
  });

  test('a week or more of illness pauses the program clock', () async {
    final p = await _commissioned();
    expect(p.programDay, 32);
    final end = p.programEnd;
    // Six sick days: no pause.
    for (var i = 6; i >= 1; i--) {
      p.setHardDay(_daysAgo(i), 'sick');
    }
    expect(p.pausedDays, 0);
    expect(p.programDay, 32);
    // The seventh: the whole illness is paused, retroactively.
    p.setHardDay(_daysAgo(7), 'sick');
    expect(p.pausedDays, 7);
    expect(p.programDay, 25);
    expect(p.programMonth, 1, reason: 'month 2 not reached yet');
    expect(p.programEnd, end.plusDays(7));
    expect(p.isPaused(_daysAgo(3)), isTrue);
    expect(p.isPaused(_today), isFalse);
    // Month 2 now starts on program day 31 = 7 days later than before.
    expect(dateKey(p.monthStart(2)), dateKey(DateTime(2026, 10, 8)));
    // Clearing one sick day in the middle ends the pause.
    p.setHardDay(_daysAgo(4), null);
    expect(p.pausedDays, 0);
    expect(p.programDay, 32);
  });

  test('emergency skips per month are set per person and travel with backups',
      () async {
    final p = await _commissioned();
    expect(p.passesPerMonth, 2);
    p.setPassesPerMonth(0);
    expect(p.setHardDay(_today, 'pass'), isFalse);
    p.setPassesPerMonth(99);
    expect(p.passesPerMonth, PersonalSystemProvider.maxPassesPerMonth);
    p.setPassesPerMonth(4);
    final json = p.exportJson();
    p.setPassesPerMonth(1);
    expect(p.importJson(json), isTrue);
    expect(p.passesPerMonth, 4);
  });

  test('odyssey, energy audit and best self feed the brief and the setback screen',
      () async {
    final p = await _commissioned();
    expect(p.odysseyLeaning, isNull);
    p.saveOdyssey([
      {'title': 'Lead product at a scale-up', 'like': 5},
      {'title': 'Teach and write'},
      {'title': 'Build my own company'},
    ], leaning: 2, prototype: 'Coffee with two founders');
    expect(p.odysseyLeaning, 'Build my own company');
    expect(p.odysseyLives.first['like'], 5);
    p.saveOdyssey(p.odysseyLives, leaning: 0);
    expect(p.logsOf('odyssey').length, 1);

    p.saveEnergyAudit([
      (name: 'Status meeting', energy: -2),
      (name: 'Customer calls', energy: 2),
      (name: '  ', energy: 0),
    ], craftActivity: 'Status meeting', craftMove: 'reshape', craftHow: 'Written update instead');
    expect(p.auditActivities(p.energyAudit!).length, 2);
    expect(p.craftingMove, 'Status meeting: reshape it — Written update instead');

    p.addBestSelfStory('Leyla', 'You calmed the room when the launch failed.');
    p.addBestSelfStory('Tural', 'You explained the plan so everyone got it.');
    p.removeBestSelfStory(5);
    expect(p.bestSelfStories().length, 2);
    p.saveBestSelfPortrait(themes: 'Calm, clarity', portrait: 'When I\'m at my best, I make hard things clear.');
    expect(p.bestSelfPortrait, contains('make hard things clear'));

    final brief = await DeviceBriefGenerator().generate(BriefInput(
      report: WeeklyReport(
          id: 'r',
          weekStart: weekStartOf(_today),
          nonNegotiableAverage: 7,
          gymSessions: 3,
          bestMoment: '',
          hardestMoment: '',
          workSituation: '',
          createdAt: _today),
      forWeek: weekStartOf(_today).plusDays(7),
      programMonth: 2,
      programWeek: 5,
      itemRates: const {'sigh': 0.5, 'bed': 0.9},
      evidenceAddedThisWeek: 0,
      artifactsThisMonth: 0,
      postsThisWeek: 0,
      gymDays: const [1, 3, 5],
      openUnlocks: const [],
      craftingMove: p.craftingMove,
      direction: p.odysseyLeaning,
    ));
    expect(brief.adjustments.join(' '), contains('Your crafting move: Status meeting'));
  });

  test('review deck: lessons, principles and values become cards; seeds only for the built-in person',
      () async {
    final p = await _commissioned();
    final seeds = seedCards.length;
    expect(p.allCards.length, seeds);
    final area = p.allGrowthAreas.first;
    p.logRep(area, p.drillsOf(area).first,
        did: 'Ran the meeting', noticed: 'I rushed', lesson: 'Pause before the ask', next: 'Try again');
    final l = p.addLearning('Thinking in Bets', kind: 'book');
    p.applyLearning(l!.id, principle: 'Judge decisions by process', experiment: 'Decision log');
    p.setValues([(name: 'Courage', meaning: 'Say the true thing kindly')]);
    final ids = p.allCards.map((c) => c.id.split(':').first).toSet();
    expect(ids, containsAll(['lesson', 'principle', 'value']));
    expect(p.allCards.firstWhere((c) => c.source == 'principle').back, contains('Decision log'));

    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    expect(p.isBuiltInPerson, isFalse);
    expect(p.allCards.where((c) => c.source == 'seed'), isEmpty);
    p.resetProfile();
  });

  test('movement: vigorous counts double; strength days include gym sessions',
      () async {
    final p = await _commissioned();
    p.logMove('walk', 30);
    p.logMove('run', 20, vigorous: true);
    p.logMove('strength', 40, day: _daysAgo(1));
    expect(p.logMove('walk', 0), isNull);
    expect(p.moveMinutesInWeek(_today), 30 + 40 + 40);
    p.toggleGym(_today);
    expect(p.strengthDaysInWeek(_today), 2);
  });

  test('someone else: own areas only, templates adopted on focus, no built-in brief tasks',
      () async {
    final p = await _commissioned();
    expect(p.isBuiltInPerson, isTrue);
    expect(p.allGrowthAreas.length, growthAreas.length);
    p.buildPlan(
        name: 'Leyla Mammadova',
        currentRole: 'Runner',
        targetRole: 'Sub-3 marathoner',
        area: areaTemplates.first,
        areaRating: 2,
        daily: dailyLibrary.take(3).toList(),
        replaceDaily: true);
    expect(p.isBuiltInPerson, isFalse);
    expect(p.allGrowthAreas.map((a) => a.custom), everyElement(isTrue));
    expect(p.state!.evidence.where((e) => e.id.startsWith('seed_')), isEmpty);
    final id = p.focusOn('t_money', startRating: 1);
    expect(id, startsWith('c_'));
    expect(p.focusArea()!.name, startsWith('Money'));
    expect(p.focusOn('t_money', startRating: 2), id, reason: 'adopted once');
    final brief = await DeviceBriefGenerator().generate(BriefInput(
      report: WeeklyReport(
          id: 'r',
          weekStart: weekStartOf(_today),
          nonNegotiableAverage: 2,
          gymSessions: 0,
          bestMoment: '',
          hardestMoment: '',
          workSituation: '',
          createdAt: _today),
      forWeek: weekStartOf(_today).plusDays(7),
      programMonth: 3,
      programWeek: 9,
      itemRates: const {'a': 0.2, 'b': 0.9},
      evidenceAddedThisWeek: 0,
      artifactsThisMonth: 0,
      postsThisWeek: 0,
      gymDays: const [],
      openUnlocks: const [],
      builtInPlan: false,
    ));
    final all = [...brief.tasks, ...brief.adjustments].join(' ');
    expect(all, isNot(contains('Face pulls')));
    expect(all, isNot(contains('LinkedIn')));
    expect(all, isNot(contains('artifact')));
    for (final t in ['manifesto', 'BLUF', 'Evidence Archive', 'Product Architect', '22:30', 'Scan rotation', 'six-questions']) {
      expect('$all ${brief.domainBrief} ${brief.coaching}', isNot(contains(t)), reason: t);
    }
    p.resetProfile();
  });

  test('hard conversations: prepare, due on the day, debrief', () async {
    final p = await _commissioned();
    expect(p.saveConversation(withWhom: ' ', about: 'x'), isNull);
    final c = p.saveConversation(
        withWhom: 'Sam',
        about: 'Missed deadlines',
        wantMe: 'Reliable delivery',
        facts: 'Three dates missed in May',
        opening: 'I want to talk about the last three deadlines.',
        by: _today.plusDays(1))!;
    expect(p.plannedConversations.length, 1);
    expect(p.conversationsDue(_today), isEmpty);
    expect(p.conversationsDue(_today.plusDays(1)).single.id, c.id);
    p.saveConversation(id: c.id, withWhom: 'Sam', about: 'Deadlines', ask: 'Flag risks a week early');
    expect(p.conversations.length, 1);
    expect(p.conversationById(c.id)!.str('facts'), '');
    p.debriefConversation(c.id, outcome: 'better', learned: 'They were overloaded');
    expect(p.plannedConversations, isEmpty);
    expect(p.conversationById(c.id)!.str('outcome'), 'better');
  });

  test('people you are growing: what they work on, help given, into the brief',
      () async {
    final p = await _commissioned();
    final sam = p.addPerson('Sam', role: 'Team');
    expect(p.peopleGrowing, isEmpty);
    p.setGrowing(sam, workingOn: 'Presenting', nextHelp: 'Review his slides');
    expect(p.peopleGrowing.single.str('growing'), 'Presenting');
    p.logHelp(p.peopleGrowing.single, 'Review his slides');
    expect(p.helpsInMonth(sam, p.programMonth), 1);
    expect(p.peopleGrowing.single.str('next_help'), '', reason: 'done, cleared');
    p.removePerson(sam.id);
    expect(p.logsOf('help'), isEmpty);
  });

  test('closing a goal asks for a look back; achieved ones become a win and a card',
      () async {
    final p = await _commissioned();
    final g = p.saveGoal(title: 'Run a half marathon')!;
    expect(p.goalsToReflect, isEmpty);
    p.setGoalStatus(g.id, 'achieved');
    expect(p.goalsToReflect.single.id, g.id);
    p.reflectOnGoal(g.id, whatWorked: '', advice: 'x');
    expect(p.goalsToReflect, isNotEmpty, reason: 'empty reflection ignored');
    p.reflectOnGoal(g.id, whatWorked: 'Three runs a week, one long', advice: 'Go slow');
    expect(p.goalsToReflect, isEmpty);
    expect(p.logsOf('win').first.text, 'Achieved: Run a half marathon');
    expect(p.allCards.any((c) => c.id == 'goal:${g.id}'), isTrue);
  });

  test('money check-in: one a month, rate and buffer, only the rate in the brief',
      () async {
    final p = await _commissioned();
    expect(p.moneyCheckDue, isFalse);
    p.setDone('money:on', true);
    p.clock = () => p.monthStart(2).plusDays(26);
    expect(p.moneyCheckDue, isTrue);
    p.saveMoneyCheck(income: 4000, spent: 3000, savings: 7500, decision: 'Cancel two subscriptions');
    p.saveMoneyCheck(income: 4000, spent: 3200, savings: 8000);
    expect(p.logsOf('money_check').length, 1);
    final c = p.moneyCheckFor(2)!;
    expect(p.savingsRate(c), closeTo(0.2, 0.001));
    expect(p.bufferMonths(c), closeTo(2.5, 0.001));
    expect(p.moneySummary, 'saved 20% of income · 2.5 months\' buffer');
    expect(p.moneyCheckDue, isFalse);
    p.clock = () => _today;
  });

  test('health upkeep: next due from last done; overdue first', () async {
    final p = await _commissioned();
    final dentist = p.addUpkeep('Dentist', 180, lastDone: _today.minusDays(200))!;
    final eyes = p.addUpkeep('Eye test', 730, lastDone: _today.minusDays(30))!;
    p.addUpkeep('Blood tests', 180);
    expect(p.addUpkeep(' ', 30), isNull);
    expect(p.upkeepDue.map((u) => u.text), ['Blood tests', 'Dentist']);
    p.markUpkeepDone(dentist.id);
    expect(p.upkeepDue.map((u) => u.text), ['Blood tests']);
    expect(dateKey(p.upkeepNextDue(p.upkeep.firstWhere((u) => u.id == eyes.id))!),
        dateKey(_today.minusDays(30).plusDays(730)));
  });

  test('three good things: one win per line, the first with its why', () async {
    final p = await _commissioned();
    p.completeShutdown(_today,
        tomorrow: const ['a'],
        win: 'Calm 1:1\n\nGym before work\nCalled Mum\nA fourth',
        why: 'I prepared the opening line');
    final wins = p.logsOn(_today, 'win');
    expect(wins.map((w) => w.text), ['Calm 1:1', 'Gym before work', 'Called Mum']);
    expect(wins.first.str('why'), 'I prepared the opening line');
    p.completeShutdown(_today, tomorrow: const ['a'], win: 'Calm 1:1');
    expect(p.logsOn(_today, 'win').length, 3, reason: 'no duplicates');
  });

  test('someone else gets the general reminders, not the built-in schedule',
      () async {
    final p = await _commissioned();
    final builtIn = p.plannedReminders().map((r) => r.title).toSet();
    expect(builtIn.any((t) => t.startsWith('Domain scan')), isTrue);
    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    final general = p.plannedReminders();
    // Check-in, items, shutdown daily (7 × 3) plus the Sunday report.
    expect(general.length, 22);
    expect(general.any((r) => r.title.startsWith('Domain scan')), isFalse);
    expect(general.where((r) => r.route == '/weekly-coaching').single.weekday, DateTime.sunday);
    p.setReminder('g_items', false);
    expect(p.plannedReminders().length, 15);
    p.resetProfile();
  });

  test('values decision goes into the journal; step back is saved', () async {
    final p = await _commissioned();
    p.addValuesDecision(
      question: 'Take the new role?',
      chosen: 'Yes',
      scores: {
        'Yes': {'Growth': 1, 'Family': -1, 'Health': 0},
        'No': {'Growth': -1, 'Family': 1, 'Health': 0},
      },
      tenTenTen: 'Nervous, settled, glad',
      premortem: 'I took on too much at home at the same time',
    );
    final d = p.logsOf('decision').first;
    expect(d.text, 'Take the new role? → Yes');
    expect(d.str('options'), 'Yes (0) · No (0)');
    expect(d.str('why'), contains('Growth +'));
    expect(d.str('expected'), startsWith('Premortem:'));
    expect(p.dueDecisionReviews(_today.plusDays(90)).length, 1);
    p.logStepBack(what: ' ');
    expect(p.logsOf('stepback'), isEmpty);
    p.logStepBack(what: 'Emin is facing a tough review', advice: 'Breathe', mattersInAYear: 1);
    expect(p.logsOf('stepback').single.number('year'), 1);
  });

  test('month review: due at month end and early next month; held excludes excused',
      () async {
    final p = await _commissioned();
    // _today is day 32 (month 2, day 2): month 1 is due.
    expect(p.monthToReview, 1);
    expect(p.monthReviewDue, isTrue);
    _hold(p, p.monthStart(1));
    p.setHardDay(p.monthStart(1).plusDays(1), 'sick');
    final h = p.monthHeld(1);
    expect(h.counted, 29);
    expect(h.held, 1);
    expect(h.hard['sick'], 1);
    p.saveMonthReview(1, carry: 'Keep the morning walk', lesson: 'Smaller is steadier');
    expect(p.monthReviewDue, isFalse);
    expect(p.monthReviewFor(1)!.str('lesson'), 'Smaller is steadier');
    p.clock = () => p.monthStart(2).plusDays(10);
    expect(p.monthToReview, isNull);
    p.clock = () => _today;
  });

  test('journal export: readable, dated, only reflective writing', () async {
    final p = await _commissioned();
    p.addLog('win', text: 'Shipped the review', data: {'why': 'Prepared early'});
    p.addLog('note', text: 'A private thought');
    p.logWeight(80);
    final area = p.allGrowthAreas.first;
    p.logRep(area, p.drillsOf(area).first, did: 'Ran it', lesson: 'Pause first');
    final text = p.journalText();
    expect(text, startsWith('${activeProfile.name} — journal from ONO'));
    expect(text, contains('Win: Shipped the review (why: Prepared early)'));
    expect(text, contains('Lesson: Pause first'));
    expect(text, contains(dateKey(_today)));
    expect(text, isNot(contains('80')), reason: 'no body numbers');
  });

  test('user manual drafts from data; couple check-in keeps a weekly streak',
      () async {
    final p = await _commissioned();
    p.setValues([(name: 'Courage', meaning: 'Say the true thing kindly')]);
    expect(p.manualSection('values'), 'Courage: Say the true thing kindly');
    expect(p.manualSection('feedback'), '');
    p.saveManual({'feedback': 'Directly, in private', 'values': ''});
    expect(p.manualSection('values'), '', reason: 'saved text wins over the draft');
    expect(p.manualText(), contains('How to give me feedback\nDirectly, in private'));

    p.logUsCheckin('Aysel', {'appreciate': '', 'hard': ''});
    expect(p.usStreak, 0, reason: 'empty answers are not saved');
    p.clock = () => _today.minusDays(7);
    p.logUsCheckin('Aysel', {'appreciate': 'The dinner'});
    p.clock = () => _today;
    p.logUsCheckin('Aysel', {'plan': 'A walk on Saturday'});
    expect(p.usStreak, 2);
  });

  test('question of the day rotates and saves one note a day; partner stake in the update',
      () async {
    final p = await _commissioned();
    final q = p.questionOfTheDay;
    p.answerQuestion(' ');
    expect(p.questionAnswer, isNull);
    p.answerQuestion('Listening to Sam');
    p.answerQuestion('Listening to Sam, properly');
    expect(p.logsOn(_today, 'note').where((n) => n.str('question') == q.$2).single.text,
        'Listening to Sam, properly');
    p.clock = () => _today.plusDays(1);
    expect(p.questionOfTheDay, isNot(q));
    expect(p.questionAnswer, isNull);
    p.clock = () => _today;
    p.setPartner('Sam', mine: 'Run', theirs: 'Write', weekday: 5, stake: 'Coffee');
    expect(p.partnerUpdateText(_today), contains('Our stake if we miss: Coffee'));
  });

  test('brag document gathers goals, wins by month, feedback, help and learning',
      () async {
    final p = await _commissioned();
    final g = p.saveGoal(title: 'Launch the onboarding redesign')!;
    p.setGoalStatus(g.id, 'achieved');
    p.reflectOnGoal(g.id, whatWorked: 'Weekly user tests');
    final sam = p.addPerson('Sam');
    p.logHelp(sam, 'Reviewed slides');
    final text = p.bragText();
    expect(text, contains('GOALS REACHED'));
    expect(text, contains('How: Weekly user tests'));
    expect(text, contains('Achieved: Launch the onboarding redesign'));
    expect(text, contains('October 2026'));
    expect(text, contains('1 time, 1 person: Sam'));
  });

  test('amounts with comma or point decimals parse correctly', () {
    expect(parseAmount('1500,50'), 1500.5);
    expect(parseAmount('1.234,50'), 1234.5);
    expect(parseAmount('1,234.50'), 1234.5);
    expect(parseAmount('1,234'), 1234);
    expect(parseAmount('1 234'), 1234);
    expect(parseAmount('12.5 AZN'), 12.5);
    expect(parseAmount(''), isNull);
  });

  test('month held: an open today is not a miss; brag learning respects the range',
      () async {
    final p = await _commissioned();
    final h = p.monthHeld(p.programMonth);
    // _today is day 2 of month 2: day 1 counted, today open and unheld.
    expect(h.counted, 1);
    _hold(p, _today);
    expect(p.monthHeld(p.programMonth).counted, 2);
    final l = p.addLearning('Old book')!;
    p.applyLearning(l.id, principle: 'Old idea', experiment: 'x');
    expect(p.bragText(since: _today.plusDays(1)), isNot(contains('Old idea')));
    expect(p.bragText(), contains('Old idea'));
  });

  test('your day: schedule blocks and reminder times follow it', () async {
    final p = await _commissioned();
    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    expect(p.personalSchedule, isEmpty);
    expect(p.activeReminderDefs.firstWhere((r) => r.id == 'g_checkin').hour, 7);
    p.saveDayShape(wake: 6 * 60 + 30, workStart: 8 * 60, workEnd: 16 * 60, bed: 22 * 60 + 30);
    expect(p.personalSchedule.map((b) => b.title), ['Morning', 'Work', 'Evening', 'Wind down', 'Sleep']);
    final defs = {for (final r in p.activeReminderDefs) r.id: r.timeLabel};
    expect(defs['g_checkin'], '07:00');
    expect(defs['g_items'], '12:00');
    expect(defs['g_shutdown'], '21:00');
    expect(p.personalBlockAt(DateTime(2026, 10, 2, 9))!.title, 'Work');
    // No fixed hours: a day block instead of work and evening.
    p.saveDayShape(wake: 8 * 60, workStart: 8 * 60, workEnd: 8 * 60, bed: 24 * 60 - 15);
    expect(p.personalSchedule.map((b) => b.title), ['Morning', 'Day', 'Wind down', 'Sleep']);
    expect(p.logsOf('day_shape').length, 1);
    p.resetProfile();
    expect(p.activeReminderDefs, same(reminderDefs));
  });

  test('Big 3 outcomes serve goals; a goal shows its next step', () async {
    final p = await _commissioned();
    final g = p.saveGoal(title: 'Promoted', plan: 'When I doubt, I ship one small thing')!;
    expect(p.goalNextStep(g), isNull, reason: 'an if-then plan is not a step');
    p.setWeekOutcome(_today, 0, 'Strategy draft reviewed');
    p.setWeekOutcomeGoal(_today, 0, g.id);
    p.setWeekOutcome(_today, 1, 'Run 3 times');
    expect(p.weekOutcomeGoal(_today, 0), g.id, reason: 'tags survive editing other outcomes');
    expect(p.weekOutcomesFor(g.id, _today), 1);
    expect(p.goalNextStep(g), 'Strategy draft reviewed');
    p.toggleWeekOutcome(_today, 0);
    expect(p.weekOutcomeGoal(_today, 0), g.id, reason: 'tags survive ticking');
    expect(p.goalNextStep(g), isNull);
    final m = p.saveGoal(title: 'Book', milestones: ['Outline', 'Draft'])!;
    expect(p.goalNextStep(m), 'Outline');
    p.setWeekOutcomeGoal(_today, 0, null);
    expect(p.weekOutcomesFor(g.id, _today), 0);
  });

  test('thought check: saved with before and after; relief needs two checks',
      () async {
    final p = await _commissioned();
    expect(p.logThought(situation: 'Review', thought: ' '), isNull);
    p.logThought(
        situation: 'Review meeting',
        thought: 'They think I am not good enough',
        feeling: 'Anxious',
        before: 80,
        evidenceAgainst: 'They asked me to lead the next one',
        balanced: 'One hard question is not a verdict',
        after: 40);
    expect(p.thoughts.single.number('before'), 80);
    expect(p.thoughtRelief, isNull);
    p.logThought(situation: 'Call', thought: 'I will fail', before: 70, after: 50);
    expect(p.thoughtRelief, 30);
    expect(p.thoughtsInWeek(_today), 2);
    expect(p.journalText(), contains('More balanced: One hard question is not a verdict'));
  });

  test('best possible future: kept per writing, empty areas dropped', () async {
    final p = await _commissioned();
    p.saveBestFuture(years: 3, areas: {'work': ' '});
    expect(p.bestFuture, isNull);
    p.saveBestFuture(
        years: 3,
        areas: {'work': 'I lead a product team I am proud of.', 'body': ''},
        step: 'Ask for the stretch project');
    expect(p.bestFuture!.number('years'), 3);
    expect((p.bestFuture!.data['areas'] as Map).keys, ['work']);
    expect(p.journalText(), contains('This week: Ask for the stretch project'));
  });

  test('kindness day: five acts on the chosen weekday', () async {
    final p = await _commissioned();
    expect(p.kindnessDue(_today), isFalse);
    p.setKindnessDay(_today.weekday);
    p.setKindnessDay(_today.weekday); // one plan, not two
    expect(p.logsOf('kindness_plan').length, 1);
    expect(p.kindnessDue(_today), isTrue);
    for (var i = 0; i < 5; i++) {
      p.logKindness('Act $i');
    }
    expect(p.kindnessDue(_today), isFalse);
    expect(p.kindnessInWeek(_today), 5);
    p.setKindnessDay(null);
    expect(p.kindnessDay, isNull);
  });

  test('worry time: parked until the slot, a next step becomes a priority',
      () async {
    final p = await _commissioned();
    p.parkWorry('The budget review');
    p.parkWorry('Mum\'s appointment');
    expect(p.worryTimeDue(_today), isFalse); // no slot set
    p.setWorryTime(18 * 60);
    expect(p.worryTimeDue(_today), isFalse); // 12:00
    expect(p.worryTimeDue(DateTime(2026, 10, 2, 18, 5)), isTrue);
    final first = p.parkedWorries.first;
    expect(first.text, 'The budget review');
    p.resolveWorry(first.id, outcome: 'keep');
    expect(p.parkedWorries.length, 2);
    p.resolveWorry(first.id, outcome: 'acted', step: 'Draft the three numbers');
    expect(p.prioritiesFor(_today), contains('Draft the three numbers'));
    p.resolveWorry(p.parkedWorries.single.id, outcome: 'let_go');
    expect(p.parkedWorries, isEmpty);
  });

  test('life chapters: edited in place, empty chapters dropped', () async {
    final p = await _commissioned();
    p.saveLifeStory(chapters: [
      {'title': 'Leaving home', 'years': '2012–2016', 'taught': 'I can start over'},
      {'title': ' ', 'high': ' '},
      {'title': '', 'high': 'The first job'},
    ], next: 'Leading');
    expect(p.lifeChapters.length, 2, reason: 'untitled but written is kept');
    p.saveLifeStory(chapters: [
      {'title': 'Leaving home'},
      {'title': 'First team'},
    ], next: 'Leading');
    expect(p.logsOf('life_story').length, 1);
    expect(p.lifeChapters.length, 2);
    expect(p.journalText(), contains('Next chapter: Leading'));
  });

  test('signature strengths: up to five known ones, uses counted per week',
      () async {
    final p = await _commissioned();
    expect(p.strengthOfTheWeek, isNull);
    p.setSignatureStrengths(['Curiosity', 'Nonsense', 'Hope', 'Zest', 'Love', 'Humour', 'Bravery']);
    expect(p.signatureStrengths, ['Curiosity', 'Hope', 'Zest', 'Love', 'Humour']);
    expect(p.signatureStrengths, contains(p.strengthOfTheWeek));
    p.setSignatureStrengths(['Hope']);
    expect(p.logsOf('strengths').length, 1);
    p.logStrengthUse('Hope', ' ');
    p.logStrengthUse('Hope', 'Wrote the team what could go right this quarter');
    expect(p.strengthUsesInWeek(_today), 1);
    WeeklyReport report() => WeeklyReport(
          id: 'r',
          weekStart: weekStartOf(_today),
          nonNegotiableAverage: 7,
          gymSessions: 0,
          bestMoment: '',
          hardestMoment: '',
          workSituation: '',
          createdAt: _today,
        );
    // Used this week: no nudge.
    var brief = await p.submitReport(report());
    expect(brief!.adjustments.join(' '), isNot(contains('in a new way')));
    p.removeLog(p.logsOf('strength_use').single.id);
    brief = await p.submitReport(report());
    expect(brief!.adjustments.join(' '), contains('Use hope in a new way'));
  });

  test('personal board: roles on people, gaps only once someone is on it',
      () async {
    final p = await _commissioned();
    final a = p.addPerson('Aysel', role: 'Former manager');
    expect(p.boardGaps, isEmpty);
    p.setBoardRoles(a, ['mentor', 'sponsor', 'bogus']);
    final saved = p.people.firstWhere((x) => x.id == a.id);
    expect(p.boardRolesOf(saved), ['mentor', 'sponsor']);
    expect(p.board['mentor']!.single.text, 'Aysel');
    expect(p.boardGaps, ['peer', 'challenger', 'supporter', 'connector']);
  });

  test('after-action review: change becomes a review card', () async {
    final p = await _commissioned();
    expect(p.logAar(event: ' '), isNull);
    p.logAar(event: 'Board presentation', sustain: 'The one-page summary', improve: 'Rehearse the Q&A out loud');
    expect(p.aars.single.str('improve'), 'Rehearse the Q&A out loud');
    final card = p.allCards.firstWhere((c) => c.id.startsWith('aar:'));
    expect(card.back, 'Rehearse the Q&A out loud');
    expect(p.journalText(), contains('Change: Rehearse the Q&A out loud'));
  });

  test('program length: phases, months and quarters scale; the end moves',
      () async {
    final p = await _commissioned();
    expect(p.programDays, 540);
    expect(p.programMonths, 18);
    p.setProgramLength(77); // not offered
    expect(p.programDays, 540);
    p.setProgramLength(90);
    expect(p.programMonths, 3);
    expect(p.programQuarters, 1);
    expect(p.programEnd, _start.plusDays(89));
    // Day 32 of 90 is past the first third: Signal.
    expect(p.phase.id, 'signal');
    expect(p.phaseMonthAt(1), 1);
    expect(p.phaseOfMonth(1).id, 'foundation');
    expect(p.phaseOfMonth(3).id, 'leverage');
    expect(p.monthsOf(p.phaseOfMonth(2)), [2]);
    expect(p.programQuarter, 1);
    expect(p.programComplete, isFalse);
    p.clock = () => _start.plusDays(90).add(const Duration(hours: 9));
    expect(p.programComplete, isTrue);
    expect(p.programMonth, 3); // stays on the last month
  });

  test('next program: starts today, keeps everything, months start over',
      () async {
    final p = await _commissioned();
    p.setProgramLength(90);
    final area = p.allGrowthAreas.first;
    p.setFocus(area.id, startRating: 2);
    expect(p.focusArea(), isNotNull);
    _hold(p, _today.minusDays(1));
    p.addLog('win', text: 'Shipped it');
    final later = _start.plusDays(91).add(const Duration(hours: 9));
    p.clock = () => later;
    _hold(p, later.minusDays(1));
    final streakBefore = p.streak;
    p.startNextProgram(days: 180, changed: 'I ask for help sooner', carry: 'The evening shutdown');
    expect(p.cycle, 2);
    expect(p.programDays, 180);
    expect(p.programStart, dayOnly(later));
    expect(p.programDay, 1);
    expect(p.phase.id, 'foundation');
    // Month 1 of the new program has no area yet; the old one is kept.
    expect(p.focusArea(), isNull);
    expect(p.logsOf('growth_focus').length, 1);
    p.setFocus(area.id, startRating: 3);
    expect(p.focusArea(), isNotNull);
    expect(p.logsOf('growth_focus').length, 2);
    expect(p.logsOf('growth_focus').first.number('cycle'), 2);
    // Updating keeps the stamp.
    p.setFocus(area.id, startRating: 4);
    expect(p.logsOf('growth_focus').where((l) => p.cycleOf(l) == 2).length, 1);
    final record = p.pastPrograms.single;
    expect(record.number('number'), 1);
    expect(record.str('start'), dateKey(_start));
    expect(record.number('days'), 90);
    expect(record.text, 'I ask for help sooner');
    expect(p.logsOf('win').length, greaterThanOrEqualTo(1));
    expect(p.streak, streakBefore); // streaks run across programs
    expect(p.journeyStart, _start);
    expect(p.journalText(), contains('Closed program 1'));
  });

  test('next program: a long illness before it does not shift the new days',
      () async {
    final p = await _commissioned();
    for (var i = 0; i < 8; i++) {
      p.setHardDay(_start.plusDays(3 + i), 'sick');
    }
    expect(p.pausedDays, 8);
    p.startNextProgram();
    expect(p.programDay, 1);
    expect(p.dateForProgramDay(10), dayOnly(_today).plusDays(9));
  });

  test('review fixes: worry kept for tomorrow, last month after the end, milestones and pauses per program',
      () async {
    final p = await _commissioned();
    p.setWorryTime(18 * 60);
    p.parkWorry('The budget review');
    final evening = DateTime(2026, 10, 2, 18, 30);
    expect(p.worriesDue(evening).length, 1);
    p.resolveWorry(p.parkedWorries.single.id, outcome: 'keep');
    expect(p.parkedWorries.length, 1);
    expect(p.worriesDue(evening), isEmpty); // kept for tomorrow
    p.clock = () => DateTime(2026, 10, 2, 19);
    p.parkWorry('Parked after the slot');
    expect(p.worriesDue(DateTime(2026, 10, 2, 19, 5)), isEmpty);

    p.clock = () => _today;
    p.setProgramLength(90);
    p.clock = () => _start.plusDays(92).add(const Duration(hours: 9));
    expect(p.programComplete, isTrue);
    expect(p.monthToReview, 3);

    p.setDone('ms_1_0', true);
    expect(p.isDone('ms_1_0'), isTrue);
    for (var i = 0; i < 8; i++) {
      p.setHardDay(_start.plusDays(3 + i), 'sick');
    }
    p.startNextProgram();
    expect(p.isDone('ms_1_0'), isFalse); // milestones tick again
    expect(p.pausedDays, 0); // the old illness belongs to program 1
  });

  test('every plan pack applies: areas, daily items with cues, a goal', () async {
    for (final pack in planPacks) {
      // A fresh person per pack, so goals don't pile up past the limit.
      final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
        ..clock = () => _today;
      await p.load('pack-${pack.name}');
      await p.commission(start: _start, gymDays: const [1, 3, 5], reminders: const {});
      final r = p.applyPack(pack, replaceDaily: true, withGoal: true);
      expect(p.dailyItems.length, greaterThanOrEqualTo(PersonalSystemProvider.minDailyItems), reason: pack.name);
      for (final d in pack.daily) {
        expect(p.dailyItems.any((x) => x.title == d.title), isTrue, reason: '${pack.name}: ${d.title}');
      }
      expect(p.activeGoals.any((g) => g.text == pack.goal!.title), isTrue, reason: pack.name);
      expect(r, isNotNull);
      expect(PlanPack.fromText(pack.toText())!.daily.length, pack.daily.length);
    }
  });

  test('promises: due, renegotiated, kept or missed; say-do after three',
      () async {
    final p = await _commissioned();
    expect(p.addPromise(what: ' '), isNull);
    final a = p.addPromise(what: 'Send the draft', to: 'Aysel', by: _today)!;
    final b = p.addPromise(what: 'Call the bank', by: _today.plusDays(3))!;
    expect(p.promisesDue(_today).map((x) => x.id), [a.id]);
    p.closePromise(a.id, 'renegotiated');
    expect(p.promisesDue(_today), isEmpty);
    expect(p.openPromises.length, 2);
    p.closePromise(a.id, 'kept');
    p.closePromise(b.id, 'missed');
    expect(p.sayDo(), isNull); // under three closed
    final c = p.addPromise(what: 'Pick up the kids at six')!;
    p.closePromise(c.id, 'kept');
    final r = p.sayDo()!;
    expect((r.kept, r.missed), (2, 1));
    expect(p.openPromises, isEmpty);
  });

  test('story bank: STAR stories, skill gaps, ideas from wins and reviews',
      () async {
    final p = await _commissioned();
    final win = p.addLog('win', text: 'Shipped the onboarding redesign')!;
    p.logAar(event: 'Board presentation', improve: 'Rehearse Q&A');
    expect(p.storyIdeas.map((l) => l.text), containsAll(['Shipped the onboarding redesign', 'Board presentation']));
    expect(p.saveStory(title: ' '), isNull);
    final s = p.saveStory(
        title: 'Turning around the late launch',
        situation: 'Two weeks late',
        action: 'Cut scope with the team',
        result: 'Shipped in 9 days',
        skills: ['Delivering under pressure', 'Nonsense'],
        from: win.id)!;
    expect(p.skillsOf(s), ['Delivering under pressure']);
    expect(p.storyIdeas.map((l) => l.text), isNot(contains('Shipped the onboarding redesign')));
    expect(p.storyGaps, isNot(contains('Delivering under pressure')));
    p.saveStory(id: s.id, title: 'Turning around the late launch', result: 'Shipped in 8 days', skills: ['Ownership']);
    expect(p.stories.length, 1);
    expect(p.storiesText(), contains('Result: Shipped in 8 days'));
    expect(p.storiesText(skill: 'Conflict'), isEmpty);
  });

  test('an overdue promise can only be kept late or missed', () async {
    final p = await _commissioned();
    final late = p.addPromise(what: 'Send the deck', by: _today.minusDays(2))!;
    expect(p.promiseOverdue(late), isTrue);
    expect(p.closePromise(late.id, 'renegotiated'), isFalse);
    expect(p.openPromises.single.str('by'), dateKey(_today.minusDays(2)));
    expect(p.closePromise(late.id, 'missed'), isTrue);
    expect(p.openPromises, isEmpty);
  });

  test('tool index: every route exists, every group is known, search works',
      () {
    final routes = appRoutes.toSet();
    for (final t in toolIndex) {
      expect(routes.contains(t.route) || t.route.startsWith('/tool/'), isTrue,
          reason: '${t.title} → ${t.route}');
      expect(toolGroups, contains(t.group), reason: t.title);
    }
    expect(toolIndex.map((t) => t.route).toSet().length, toolIndex.length,
        reason: 'one entry per tool');
    expect(toolIndex.where((t) => t.matches('anxiety')).map((t) => t.route),
        containsAll(['/thought', '/worry']));
    expect(toolIndex.where((t) => t.matches('sleep')).isNotEmpty, isTrue);
  });

  test('year in review: due mid-December to mid-January, sums the year',
      () async {
    final p = await _commissioned();
    expect(p.yearToReview, isNull); // 2 Oct
    p.clock = () => DateTime(2026, 12, 20, 9);
    expect(p.yearToReview, 2026);
    expect(p.yearReviewDue, isTrue);
    p.clock = () => DateTime(2027, 1, 10, 9);
    expect(p.yearToReview, 2026);
    p.clock = () => DateTime(2027, 1, 16, 9);
    expect(p.yearToReview, isNull);

    p.clock = () => _today;
    _hold(p, DateTime(2026, 9, 2));
    _hold(p, DateTime(2026, 9, 3));
    p.addLog('win', text: 'First win', date: DateTime(2026, 9, 5));
    p.addLog('win', text: 'Second win', date: DateTime(2026, 9, 20));
    p.addLog('focus', data: {'minutes': 90, 'target': 'skill'}, date: DateTime(2026, 9, 6));
    p.addLog('focus', data: {'minutes': 60, 'target': 'skill'}, date: DateTime(2026, 9, 7));
    p.saveMonthReview(1, carry: 'Keep the mornings', lesson: 'Start smaller');
    final y = p.yearSummary(2026);
    expect(y.held, 2);
    expect(y.counted, greaterThanOrEqualTo(31)); // 1 Sep to 1 Oct (today open)
    expect(y.wins, 2);
    expect(y.topWins, ['First win', 'Second win']);
    expect(y.focusHours, 2);
    expect(y.lessons, ['Start smaller']);
    expect(p.yearSummary(2025).counted, 0);

    // Too early: closing 2026 in October would hide December's prompt.
    expect(p.yearOnScreen, 2026);
    expect(p.canCloseYear(2026), isFalse);
    expect(p.saveYearReview(2026, answers: {'proud': 'x'}), isFalse);
    expect(p.logsOf('year_review'), isEmpty);

    p.clock = () => DateTime(2026, 12, 20, 9);
    expect(p.saveYearReview(2026, answers: {'proud': 'The mornings', 'hard': ' '}, word: 'Steady'), isTrue);
    expect(p.yearReviewDue, isFalse);
    final r = p.yearReviewFor(2026)!;
    expect(r.str('proud'), 'The mornings');
    expect(r.data.containsKey('hard'), isFalse);
    p.saveYearReview(2026, answers: {'proud': 'The mornings'}, word: 'Brave');
    expect(p.logsOf('year_review').length, 1);
    expect(p.journalText(), contains('Word for next year: Brave'));
    p.clock = () => DateTime(2027, 3, 1, 9);
    expect(p.wordForTheYear, 'Brave');
    expect(p.yearOnScreen, 2026); // out of season: last year
    expect(p.canCloseYear(2026), isTrue);
  });

  test('ask for help: guess, answer, a record after three', () async {
    final p = await _commissioned();
    p.addAsk(what: 'Review my draft', of: 'Aysel', guess: 30);
    p.addAsk(what: 'Cover my shift', guess: 40);
    p.addAsk(what: 'Lend the drill', guess: 50);
    expect(p.openAsks.length, 3);
    expect(p.asksToClose, isEmpty); // asked today
    p.clock = () => _today.plusDays(2);
    expect(p.asksToClose.length, 3);
    final ids = [for (final a in p.openAsks) a.id];
    p.closeAsk(ids[0], 'yes');
    p.closeAsk(ids[1], 'partly');
    expect(p.askRecord(), isNull);
    p.closeAsk(ids[2], 'no');
    p.closeAsk(ids[2], 'maybe'); // not an outcome: ignored
    final r = p.askRecord()!;
    expect((r.asked, r.yes, r.guess), (3, 2, 40));
    expect(p.openAsks, isEmpty);
    expect(p.asksInWeek(_today), 3);
    expect(p.journalText(), contains('Asked Aysel for help: Review my draft'));
  });

  test('device brief: at most six changes and one recognition, set-up nudges capped',
      () async {
    final p = await _commissioned(briefs: DeviceBriefGenerator());
    // Plenty to say: thoughts, kindness and a setback to recognise, and a
    // fresh plan with no goal, area, rest or Big 3.
    for (var i = 0; i < 5; i++) {
      p.logKindness('Act $i');
    }
    p.logThought(situation: 's', thought: 't', before: 80, after: 40);
    final brief = await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 3,
      gymSessions: 0,
      bestMoment: '',
      hardestMoment: 'The Monday meeting',
      workSituation: '',
      createdAt: _today,
    ));
    final a = brief!.adjustments;
    expect(a.length, lessThanOrEqualTo(DeviceBriefGenerator.maxAdjustments + 1));
    const setup = ['No growth area', 'No goals set', 'No rest planned', 'No three outcomes', 'Evidence Archive'];
    expect(a.where((l) => setup.any(l.startsWith)).length, lessThanOrEqualTo(2));
    const praise = ['kind acts this week', 'to the test this week', 'met with a next step'];
    expect(a.where((l) => praise.any(l.contains)).length, 1);
    // Health and the plan's collapse come first.
    expect(a.first, startsWith('Shrink'));
  });

  test('device brief: the week keeps a place when their own data says a lot',
      () async {
    final brief = await DeviceBriefGenerator().generate(BriefInput(
      report: WeeklyReport(
        id: 'r',
        weekStart: weekStartOf(_today),
        nonNegotiableAverage: 8,
        gymSessions: 3,
        bestMoment: '',
        hardestMoment: 'The review',
        workSituation: '',
        createdAt: _today,
      ),
      forWeek: weekStartOf(_today),
      programMonth: 2,
      programWeek: 6,
      phaseName: 'Foundation',
      itemRates: const {},
      evidenceAddedThisWeek: 5,
      artifactsThisMonth: 1,
      postsThisWeek: 2,
      openUnlocks: const [],
      gymDays: const [1, 3, 5],
      builtInPlan: false,
      growthFocus: 'Calm',
      growthDrill: 'Pause before answering',
      repsThisWeek: 0,
      feedbackThisMonth: 0,
      patterns: const ['Reading → focus 4.1 vs 3.2 without'],
      valueGap: 'Courage',
      promisesOverdue: 2,
      goals: const ['Run 10k: 40% (behind)'],
      peopleOverdue: const ['Aysel'],
      deepWorkHours: 1,
      wordForTheYear: 'Steady',
    ));
    final a = brief.adjustments;
    expect(a.length, lessThanOrEqualTo(DeviceBriefGenerator.maxAdjustments + 1));
    expect(a.first, startsWith('From your own last 60 days'));
    expect(a.any((l) => l.startsWith('No three outcomes') || l.startsWith('Deep work') || l.startsWith('No deep work') || l.startsWith('Overdue')), isTrue);
    expect(brief.headline, endsWith('Your word for the year: Steady.'));
  });

  test('protein never un-ticks a manual tick; lights out after midnight',
      () async {
    final p = await _commissioned();
    p.setCheck(_today, 'protein', true);
    p.addProtein(_today, 40);
    expect(p.isChecked(_today, 'protein'), isTrue);

    p.saveProfile(builtInProfile.copyWith(name: 'Nigar Aliyeva', firstName: 'Nigar'));
    p.saveDayShape(wake: 420, workStart: 540, workEnd: 1080, bed: 30);
    final s = p.personalSchedule;
    final wind = s.firstWhere((b) => b.title == 'Wind down');
    expect((wind.hour, wind.minute), (23, 30));
    final shut = p.activeReminderDefs.firstWhere((r) => r.id == 'g_shutdown');
    expect(shut.hour, 23); // 00:30 − 90 min, not the next morning
  });

  test('a re-entry day stays a minimum day after the next program starts',
      () async {
    final p = await _commissioned();
    final sick = dayOnly(_today).minusDays(3), back = sick.plusDays(1);
    p.setHardDay(sick, 'sick');
    expect(p.isReentryDay(back), isTrue);
    p.startNextProgram(days: 90);
    expect(p.isReentryDay(back), isTrue);
  });

  test('changing the daily list does not rewrite the past', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    for (var d = _start; d.isBefore(today); d = d.plusDays(1)) {
      _hold(p, d); // 7 of 10
    }
    final streak = p.streak, held = p.monthHeld(1).held;
    expect(streak, greaterThan(20));
    p.addDailyItem('Walk after lunch', lane: 'body', when: 'day');
    expect(p.dailyCount, 11);
    expect(p.streak, streak, reason: 'past days keep their 7-of-10 bar');
    expect(p.monthHeld(1).held, held);
    expect(p.targetFor(today), 8); // today: 8 of 11
    expect(p.isHeld(today.minusDays(1)), isTrue);

    // Retiring an item that was ticked on past days doesn't undo them.
    final ticked = nonNegotiables.first.id;
    expect(p.setItemActive(ticked, false), isTrue);
    expect(p.streak, streak);
    expect(p.scoreFor(today.minusDays(1)), 7);
    expect(p.logsOf('daily_list').length, 2); // the old list, then today's
  });

  test('a late riser\'s day shape times reminders without throwing', () async {
    final p = await _commissioned();
    p.saveProfile(builtInProfile.copyWith(name: 'Nigar Aliyeva', firstName: 'Nigar'));
    p.saveDayShape(wake: 1380, workStart: 1380, workEnd: 1380, bed: 900);
    final shut = p.activeReminderDefs.firstWhere((r) => r.id == 'g_shutdown');
    expect((shut.hour, shut.minute), (13, 30)); // 15:00 − 90 min
    expect(p.plannedReminders(), isNotEmpty);
  });

  test('a list changed before a future start, or on two devices, scores today on the current list',
      () async {
    SharedPreferences.setMockInitialValues({});
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => _today;
    await p.load('future');
    await p.commission(
        start: dayOnly(_today).plusDays(5), gymDays: const [1, 3, 5], weightKg: 82, reminders: const {});
    final mine = p.addDailyItem('Stretch', lane: 'body', when: 'morning')!;
    p.clock = () => _today.plusDays(10);
    expect(p.itemIdsOn(_today.plusDays(10)), contains(mine.id));
    expect(p.targetFor(_today.plusDays(10)), 8); // 8 of 11
    // A snapshot from another device that doesn't know the new item only
    // speaks for its own past day, never for today.
    p.addLog('daily_list', date: _today.plusDays(9), data: {'ids': [for (final n in nonNegotiables) n.id]});
    expect(p.itemIdsOn(_today.plusDays(10)), contains(mine.id));
  });

  test('building the plan twice adds no duplicate area or goal; the goal limit is reported',
      () async {
    final p = await _commissioned();
    final money = areaTemplates.firstWhere((t) => t.id == 't_money');
    bool build(String goal) => p.buildPlan(
        name: 'Nigar Aliyeva',
        currentRole: 'Nurse',
        targetRole: 'Head nurse',
        area: money,
        areaRating: 2,
        goal: goal,
        daily: dailyLibrary.take(3).toList(),
        replaceDaily: true);
    expect(build('Six months of savings'), isTrue);
    expect(build('Six months of savings'), isTrue);
    expect(p.customAreas.where((a) => a.name == money.name).length, 1);
    expect(p.activeGoals.where((g) => g.text == 'Six months of savings').length, 1);
    p.saveGoal(title: 'Second');
    p.saveGoal(title: 'Third');
    expect(build('A fourth one'), isFalse);
  });

  test('a pack applied before the plan builder keeps its items', () async {
    final p = await _commissioned();
    final pack = planPacks.first;
    p.applyPack(pack, replaceDaily: false, withGoal: true);
    final packItems = [for (final n in p.customDailyItems) n.title];
    expect(packItems, isNotEmpty);
    p.buildPlan(
        name: 'Nigar Aliyeva',
        currentRole: 'Nurse',
        targetRole: 'Head nurse',
        area: p.customAreas.first,
        areaRating: 2,
        daily: const [],
        replaceDaily: true,
        keepOwnDaily: true);
    expect([for (final n in p.dailyItems) n.title], containsAll(packItems));
    expect(p.dailyItems.any((n) => nonNegotiables.any((b) => b.id == n.id)), isFalse);
  });

  test('scores on a 10 scale for the charts; the Monday card counts only days that counted',
      () async {
    final p = await _commissioned();
    final day = dayOnly(_today).minusDays(1);
    _hold(p, day, 7);
    expect(p.scoreOutOf10(day), 7);
    p.addDailyItem('Stretch', lane: 'body', when: 'morning');
    p.addDailyItem('Walk', lane: 'body', when: 'day');
    p.addDailyItem('Call home', lane: 'social', when: 'evening');
    p.addDailyItem('Read', lane: 'skill', when: 'evening');
    p.addDailyItem('Plan', lane: 'mind', when: 'morning');
    final today = dayOnly(_today);
    for (final n in p.dailyItems) {
      p.setCheck(today, n.id, true);
    }
    expect(p.scoreOutOf10(today), 10); // 15 of 15
    expect(p.scoreOutOf10(day), 7); // yesterday still 7 of 10

    // Monday 5 Oct: last week (28 Sep–4 Oct) had three sick days.
    p.clock = () => DateTime(2026, 10, 5, 8);
    final monday = DateTime(2026, 10, 5);
    for (var i = 1; i <= 3; i++) {
      p.setHardDay(monday.minusDays(i), 'sick');
    }
    final f = p.freshStartFor(monday);
    if (f != null && f.itemId != null) {
      expect(f.body, contains('of 4 days'));
      expect(f.body, isNot(contains('Your plan: .')));
    }
  });

  test('first week: one step unlocks a day and completes from what was logged',
      () async {
    final p = await _commissioned(); // started 1 Sep
    p.setProgramStart(dayOnly(_today)); // day 1
    expect(p.programDay, 1);
    var step = p.firstWeekStep!;
    expect(step.id, 'items');
    p.setCheck(_today, nonNegotiables.first.id, true);
    expect(p.firstWeekStep, isNull, reason: 'only one step is open on day 1');
    p.clock = () => _today.plusDays(2); // day 3
    expect(p.firstWeekStep!.id, 'checkin');
    p.saveCheckin(_today.plusDays(2), energy: 3, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    expect(p.firstWeekStep!.id, 'week');
    expect(p.firstWeekProgress, 2);
    p.clock = () => _today.plusDays(20); // after the first two weeks
    expect(p.firstWeekStep, isNull);
  });

  test('a report made on Monday closes last week; the drill holds for the week',
      () async {
    final p = await _commissioned(); // started 1 Sep
    final monday = DateTime(2026, 10, 5, 9);
    p.clock = () => monday;
    expect(p.reportWeekFor(monday), DateTime(2026, 9, 28));
    expect(p.lastWeekReportDue, isTrue);
    p.saveReport(WeeklyReport(
        id: 'r1',
        weekStart: DateTime(2026, 9, 28),
        nonNegotiableAverage: 7,
        gymSessions: 3,
        bestMoment: '',
        hardestMoment: '',
        workSituation: '',
        createdAt: monday));
    expect(p.reportWeekFor(monday), DateTime(2026, 10, 5));
    expect(p.lastWeekReportDue, isFalse);
    // Wednesday: always this week.
    final wednesday = DateTime(2026, 10, 7, 9);
    expect(p.reportWeekFor(wednesday), DateTime(2026, 10, 5));

    final area = p.allGrowthAreas.first;
    p.setFocus(area.id, startRating: 2);
    final drill = p.drillFor(area, wednesday);
    p.clock = () => wednesday;
    p.logRep(area, drill, did: 'Tried it', lesson: 'Start smaller');
    expect(p.drillFor(area, wednesday).title, drill.title,
        reason: 'one rep does not move the week\'s drill');
    expect(p.drillRepsThisWeek(area, drill, wednesday), 1);
  });

  test('the week\'s three are proposed from the goal, the drill and feedback',
      () async {
    final p = await _commissioned();
    final goal = p.saveGoal(
        title: 'Lead the pricing launch',
        plan: 'If a review slips, I book the next slot the same day',
        milestones: const ['Draft the pricing page'])!;
    final area = p.allGrowthAreas.first;
    p.setFocus(area.id, startRating: 2);
    p.logFeedback(area, from: 'A peer', said: 'You rush the first minute', action: 'Rehearse the opening');
    final week = weekStartOf(_today);
    final proposals = p.proposedOutcomes(week);
    expect(proposals.first.text, 'Draft the pricing page');
    expect(proposals.first.goalId, goal.id);
    expect(proposals.map((x) => x.text), contains('Rehearse the opening'));
    expect(proposals.length, 3);

    p.setWeekOutcome(week, 1, 'My own outcome');
    expect(p.useProposedOutcomes(week), 2);
    final o = p.weekOutcomes(week);
    expect(o[0], 'Draft the pricing page');
    expect(o[1], 'My own outcome');
    expect(p.weekOutcomeGoal(week, 0), goal.id);
    expect(p.proposedOutcomes(week).map((x) => x.text), isNot(contains('Draft the pricing page')));
  });

  test('people: help and other contact count, editing keeps history, birthdays',
      () async {
    final p = await _commissioned();
    p.clock = () => _today.minusDays(40);
    final mum = p.addPerson('Mum', role: 'mother', every: 7);
    final sam = p.addPerson('Sam Lee', every: 30);
    final sam2 = p.addPerson('Sam Ortiz', every: 30);
    p.clock = () => _today;
    expect(p.peopleDue.length, 3);
    // Helping someone is contact.
    p.logHelp(mum, 'Set up her new phone');
    expect(p.lastContact(mum), dayOnly(_today));
    // A shared first name doesn't count for either Sam; a full name does.
    final g = p.writeGratitude('Sam', 'Thank you for 2019')!;
    p.deliverGratitude(g.id);
    expect(p.lastContact(sam), isNull);
    final g2 = p.writeGratitude('Sam Ortiz', 'Thank you')!;
    p.deliverGratitude(g2.id);
    expect(p.lastContact(sam2), dayOnly(_today));
    // The rhythm can change without losing history; due people come first.
    p.updatePerson(sam, every: 90, askAbout: 'the new flat', birthday: '03-14');
    final edited = p.personById(sam.id)!;
    expect(p.cadenceOf(edited), 90);
    expect(p.peopleDue, isEmpty);
    expect(p.helpsFor(mum).length, 1);
    expect(p.askAboutOf(edited), 'the new flat');
    p.logTouch(edited, date: _today.minusDays(1));
    expect(p.askAboutOf(p.personById(sam.id)!), '', reason: 'asked now');
    expect(p.lastContact(edited), dayOnly(_today.minusDays(1)));
    // Birthdays: the day before and the day itself.
    expect(p.birthdayOf(p.personById(sam.id)!), (3, 14));
    p.clock = () => DateTime(2027, 3, 13, 9);
    expect(p.birthdaysSoon(DateTime(2027, 3, 13)).map((x) => x.text), ['Sam Lee']);
    expect(p.birthdaysSoon(DateTime(2027, 3, 15)), isEmpty);
    // Between you: what is open with them.
    p.clock = () => _today;
    p.addPromise(what: 'Send the photos', to: 'Mum', by: _today.plusDays(2));
    p.addAsk(what: 'Look after the cat', of: 'Mum');
    expect(p.betweenYou(p.personById(mum.id)!).map((x) => x.$1),
        ['You promised', 'You asked for', 'Last help']);
  });

  test('an ask with no answer stays out of the record', () async {
    final p = await _commissioned();
    for (final o in ['yes', 'no', 'yes', 'none']) {
      p.addAsk(what: 'ask $o', guess: 40);
      p.closeAsk(p.openAsks.first.id, o);
    }
    final r = p.askRecord()!;
    expect((r.asked, r.yes), (3, 2));
    expect(p.openAsks, isEmpty);
  });

  test('goals: honest pace, a decision at the date, steps and times', () async {
    final p = await _commissioned();
    // No number and no milestone: it can't be behind.
    final open = p.saveGoal(
        title: 'Write more', deadline: _today.plusDays(90))!;
    p.clock = () => _today.plusDays(60);
    expect(p.goalPace(open), isNull);
    p.addMilestone(open.id, 'First essay out');
    expect(p.goalPace(p.goalById(open.id)!), 'behind');
    // Past the date: past due, and it asks for a decision.
    p.clock = () => _today.plusDays(95);
    expect(p.goalPace(p.goalById(open.id)!), 'past due');
    expect(p.goalsAtDecision.map((g) => g.id), [open.id]);
    p.setGoalDeadline(open.id, _today.plusDays(125));
    expect(p.goalsAtDecision, isEmpty);
    // A time goal, lower is better, entered as m:ss.
    expect(PersonalSystemProvider.parseGoalNumber('4:30'), 4.5);
    expect(PersonalSystemProvider.parseGoalNumber('82,5'), 82.5);
    final run = p.saveGoal(
        title: 'Faster km',
        start: 4.5,
        target: 3.0 + 59 / 60,
        clock: true,
        deadline: _today.plusDays(200))!;
    expect(PersonalSystemProvider.formatGoalNumber(run, run.number('target')!.toDouble()), '3:59');
    p.logGoalValue(run.id, 3.9);
    expect(p.goalPace(p.goalById(run.id)!), 'reached');
    expect(p.goalsAtDecision.map((g) => g.id), [run.id]);
    // The next step: yours first, never the if-then plan.
    final third = p.saveGoal(
        title: 'Calmer mornings', plan: 'If I wake late, then I skip the news',
        milestones: const ['Phone out of the bedroom'])!;
    expect(p.goalNextStep(third), 'Phone out of the bedroom');
    p.toggleMilestone(third.id, 0);
    expect(p.goalNextStep(p.goalById(third.id)!), isNull);
    p.setGoalNext(third.id, 'Buy an alarm clock');
    expect(p.goalNextStep(p.goalById(third.id)!), 'Buy an alarm clock');
    // A planned step moves the proposal to the next goal that has one.
    final week = weekStartOf(p.now);
    p.setWeekOutcome(week, 0, 'First essay out');
    expect(p.proposedOutcomes(week).map((x) => x.text), contains('Buy an alarm clock'));
    // Three are active: reopening a fourth is refused.
    p.setGoalStatus(open.id, 'dropped');
    p.saveGoal(title: 'Another');
    expect(p.setGoalStatus(open.id, 'active'), isFalse);
    expect(p.activeGoals.length, 3);
  });

  test('learning: answerable cards, newest first, retiring, honest experiments',
      () async {
    final p = await _commissioned();
    final area = p.allGrowthAreas.first;
    final drill = p.drillsOf(area).first;
    // An old lesson and many unseen cards, then one written today.
    p.clock = () => _today.minusDays(10);
    for (var i = 0; i < 8; i++) {
      p.addCustomCard('Old question $i', 'Old answer $i');
    }
    p.clock = () => _today;
    p.logRep(area, drill, did: 'Opened the meeting with the decision', lesson: 'Lead with the ask');
    final lesson = p.allCards.firstWhere((c) => c.source == 'lesson');
    expect(lesson.front, contains('when you Opened the meeting with the decision'));
    final due = p.dueCards(_today);
    expect(due.map((c) => c.id), contains(lesson.id),
        reason: 'today\'s lesson comes before the backlog of unseen cards');
    // Retiring a generated card keeps the rep but drops the card.
    p.retireCard(lesson.id);
    expect(p.allCards.map((c) => c.id), isNot(contains(lesson.id)));
    expect(p.logsOf('rep').length, 1);
    // Sick days are left out of an experiment's comparison.
    p.clock = () => _today.minusDays(4);
    final e = p.startExperiment(change: 'No phone in bed', measure: 'energy', days: 7)!;
    for (var i = 4; i >= 1; i--) {
      final d = _today.minusDays(i);
      p.clock = () => d;
      p.saveCheckin(d, energy: i == 2 ? 1 : 4, mood: 0, sleep: 7, pain: 0, stiffness: 0);
    }
    p.clock = () => _today;
    p.setHardDay(_today.minusDays(2), 'sick');
    final c = p.experimentCompare(e);
    expect(c.nDuring, 3);
    expect(c.during, 4);
  });

  test('first weeks: no review of a two-day week; a pack goal keeps what you wrote',
      () async {
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => DateTime(2026, 10, 3, 9); // a Saturday
    await p.load('test');
    await p.commission(
        start: DateTime(2026, 10, 3), gymDays: const [1, 3, 5], reminders: const {});
    // Monday: the two-day week before isn't asked for.
    p.clock = () => DateTime(2026, 10, 5, 9);
    expect(p.programDaysInWeek(DateTime(2026, 9, 28)), 2);
    expect(p.lastWeekReportDue, isFalse);
    // The look-back step waits for a Sunday after a few days.
    expect(p.firstWeekStep?.id, isNot('review'));
    // A pack added the goal from step 1; the goal step's words still land.
    final pack = planPacks.first;
    p.applyPack(pack, replaceDaily: false, withGoal: true);
    final title = p.activeGoals.single.text;
    p.buildPlan(
      name: activeProfile.name,
      currentRole: 'Now',
      targetRole: 'Next',
      area: p.allGrowthAreas.first,
      areaRating: 2,
      goal: title,
      goalWhy: 'So my team trusts me',
      plan: 'If I avoid it, then I book it first thing',
      milestone: 'First 1:1 with everyone',
      deadline: DateTime(2027, 4, 5),
      daily: const [],
    );
    final g = p.activeGoals.single;
    expect(g.str('why'), 'So my team trusts me');
    expect(g.str('plan'), 'If I avoid it, then I book it first thing');
    expect(p.milestonesOf(g).map((m) => m.text), contains('First 1:1 with everyone'));
    expect(g.str('deadline'), '2027-04-05');
  });

  test('a lapse brings a welcome, not a warning; after midnight is still last night',
      () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    // Two days with nothing ticked, after a held one.
    _hold(p, today.minusDays(3));
    expect(p.isReentryDay(today), isTrue);
    expect(p.isMinimumDay(today), isTrue);
    expect(p.isRecoveryDay, isFalse, reason: 'the welcome card replaces the warning');
    // One quiet day is not a lapse.
    _hold(p, today.minusDays(1));
    expect(p.isReentryDay(today), isFalse);
    p.clock = () => DateTime(2026, 10, 3, 0, 30);
    expect(p.logicalToday, DateTime(2026, 10, 2));
    p.clock = () => DateTime(2026, 10, 3, 4, 0);
    expect(p.logicalToday, DateTime(2026, 10, 3));
  });

  test('log: edit keeps the day, undo restores; Me says something true lately',
      () async {
    final p = await _commissioned();
    p.clock = () => _today.minusDays(3);
    final w = p.addLog('win', text: 'Shipd the draft')!;
    p.clock = () => _today;
    p.editLogText(w.id, 'Shipped the draft');
    final edited = p.logsOf('win').single;
    expect(edited.text, 'Shipped the draft');
    expect(dayOnly(edited.date), dayOnly(_today.minusDays(3)));
    p.removeLog(w.id);
    expect(p.logsOf('win'), isEmpty);
    p.restoreLog(edited);
    expect(p.logsOf('win').single.id, w.id);
    // Ten days: held on seven, the first item every day.
    for (var i = 1; i <= 10; i++) {
      final d = dayOnly(_today).minusDays(i);
      if (i <= 7) {
        _hold(p, d);
      } else {
        p.setCheck(d, nonNegotiables.first.id, true);
      }
    }
    expect(p.latelyLine, startsWith('Lately: held 7 of 30'));
    expect(p.latelyLine, contains('slips most:'),
        reason: 'over 30 days nothing is steady yet');
  });

  test('a reminder for something already done today waits for next week',
      () async {
    final rec = _RecordingReminders();
    final p = PersonalSystemProvider(
        gateway: MockPersonalSystemGateway(), reminders: rec)
      ..clock = () => _today;
    await p.load('test');
    await p.commission(
        start: _start, gymDays: const [1, 3, 5], reminders: const {'ritual': true});
    PlannedReminder today(List<PlannedReminder> l) => l.firstWhere(
        (r) => r.weekday == _today.weekday && r.title.startsWith('Morning ritual'));
    expect(today(p.plannedReminders()).skipToday, isFalse);
    p.addLog('ritual', data: {'seconds': 300});
    expect(today(p.plannedReminders()).skipToday, isTrue);
    expect(p.plannedReminders().where((r) => r.skipToday).length, 1,
        reason: 'only today\'s occurrence moves');
    // Checking in re-plans at once.
    rec.last = const [];
    p.saveCheckin(dayOnly(_today), energy: 4, mood: 1, sleep: 7, pain: 0, stiffness: 0);
    expect(rec.last, isNotEmpty);
  });

  test('reflection rhythm: honest summary, letters for the end, what carries',
      () async {
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway())
      ..clock = () => DateTime(2026, 1, 1, 9);
    await p.load('test');
    await p.commission(
        start: DateTime(2026, 1, 1), gymDays: const [1, 3, 5], reminders: const {});
    p.setProgramLength(90);
    // A letter for the end moves with the program's length.
    p.writeLetter('Dear me', p.programEnd, atEnd: true);
    final letter = p.letters.single;
    expect(p.letterOpensOn(letter), p.programEnd);
    p.setProgramLength(180);
    expect(p.letterOpensOn(letter), p.programEnd);
    p.setProgramLength(90);
    // Month 1 closed: what to carry comes back in month 2.
    p.clock = () => DateTime(2026, 1, 29, 9);
    p.saveMonthReview(1, carry: 'Phone out of the bedroom', lesson: 'Mornings decide days');
    p.clock = () => DateTime(2026, 2, 2, 9);
    expect(p.lastCarry, 'Phone out of the bedroom');
    // End of quarter 1: one look back, not two; it closes month 3 too.
    p.clock = () => DateTime(2026, 3, 28, 9);
    expect(p.quarterReviewDue, isTrue);
    expect(p.monthReviewDue, isFalse);
    final g = p.saveGoal(title: 'Run 10 km')!;
    p.saveQuarterReview(1,
        wheel: const {}, lessons: 'Small beats big\nSleep first',
        goalDecisions: {g.id: 'achieved'}, nextFocus: 'Strength');
    expect(p.monthReviewFor(3)?.str('lesson'), 'Small beats big');
    p.saveQuarterReview(1, wheel: const {}, nextFocus: 'Strength');
    expect((p.reviewFor(1)!.data['goals'] as Map)[g.id], 'achieved',
        reason: 'saving again keeps the first decisions');
    // The program ended on day 90; opening the look-back weeks later
    // doesn't count the weeks after it.
    p.clock = () => DateTime(2026, 4, 25, 9);
    expect(p.programComplete, isTrue);
    final sum = p.programSummary();
    expect(sum.counted, lessThanOrEqualTo(90));
    p.startNextProgram(days: 90);
    expect(p.letterIsOpen(p.letters.single), isTrue,
        reason: 'the program it waited for has closed');
  });

  test('worry time reminds only while something is parked', () async {
    final p = await _commissioned();
    p.setWorryTime(18 * 60 + 30);
    bool has() => p.plannedReminders().any((r) => r.title == 'Worry time');
    expect(has(), isFalse);
    p.parkWorry('The budget meeting');
    expect(has(), isTrue);
    expect(p.plannedReminders().where((r) => r.title == 'Worry time').first.hour, 18);
    p.resolveWorry(p.parkedWorries.single.id, outcome: 'let_go');
    expect(has(), isFalse);
  });

  test('restore: only a real backup, says what it removes, can be undone',
      () async {
    final p = await _commissioned();
    final backup = p.exportJson();
    p.addLog('win', text: 'After the backup');
    expect(p.importPreview('{"program_start": "2026-09-01"}'), isNull,
        reason: 'a fragment is not a backup');
    expect(p.importJson('{"program_start": "2026-09-01"}'), isFalse);
    expect(p.importPreview(backup)!.missingHere, 1);
    expect(p.importJson(backup), isTrue);
    expect(p.logsOf('win'), isEmpty);
    p.undoImport();
    expect(p.logsOf('win').single.text, 'After the backup');
  });

  test('growth: next month from what happened, Monday drill weeks, month line',
      () async {
    final p = await _commissioned();
    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    expect(p.programMonth, 2);
    // Month 1 on health, rated 2 → 2: it didn't move, so keep it.
    final health = p.focusOn('t_health', startRating: 2, month: 1);
    p.rateFocusEnd(2, month: 1);
    expect(p.focusArea(2), isNull, reason: 'month 1 chosen without touching 2');
    expect(p.suggestedAreaFor(2).id, health);
    expect(p.monthGrowthLine(1), 'Health & energy, 2→2 · 0 reps');
    // It moved: an active goal's area that hasn't had a month comes next.
    p.rateFocusEnd(3, month: 1);
    final rel = p.focusOn('t_relationships', startRating: 2, month: 1);
    p.focusOn('t_health', startRating: 2, month: 1);
    p.rateFocusEnd(3, month: 1);
    p.saveGoal(title: 'A closer marriage', areas: [rel]);
    expect(p.suggestedAreaFor(2).id, rel);
    // Choosing next month's area leaves this month alone.
    p.focusOn(rel, startRating: 3, month: 2);
    p.focusOn('t_strength', startRating: 1, month: 3);
    expect(p.focusArea(2)!.id, rel);
    expect(p.focusArea(3)!.name, 'Strength & athletic performance');
    // Drill weeks run Monday to Sunday, even for a program begun on Tuesday.
    final area = p.focusArea(2)!;
    expect(p.drillFor(area, DateTime(2026, 10, 5)).title,
        p.drillFor(area, DateTime(2026, 10, 11)).title);
  });

  test('body and money: typos refused, last month\'s money, his patterns only for him',
      () async {
    final p = await _commissioned();
    final weights = p.logsOf('weight').length;
    expect(p.logWeight(805), isFalse);
    expect(p.logWeight(80.5), isTrue);
    expect(p.logsOf('weight').length, weights + 1);
    expect(p.addProtein(_today, -30), isFalse);
    expect(p.addProtein(_today, 40), isTrue);
    expect(p.proteinFor(_today), 40);
    // 2 Oct is day 2 of month 2: last month's money is still open.
    expect(p.programMonth, 2);
    expect(p.moneyMonthDefault, 1);
    p.saveMoneyCheck(month: p.moneyMonthDefault, income: 3000, spent: 2400);
    expect(p.moneyCheckFor(1), isNotNull);
    expect(p.moneyCheckFor(2), isNull);
    expect(p.moneyMonthDefault, 2);
    // Someone without a bedtime or caffeine item never sees those patterns.
    p.saveProfile(activeProfile.copyWith(name: 'Someone Else'));
    p.buildPlan(
        name: 'Someone Else',
        currentRole: '',
        targetRole: '',
        area: areaTemplates.first,
        areaRating: 2,
        daily: [for (final d in dailyLibrary.take(3)) d],
        replaceDaily: true);
    expect(p.dailyItems.any((i) => i.id == 'bed'), isFalse);
    expect(p.patterns().map((x) => x.id), isNot(contains('bed_energy')));
  });

  test('plan packs: pasted text is bounded, replacing retires (not deletes)',
      () async {
    final pasted = PlanPack.fromText('ONO plan: x\n${jsonEncode({
      'name': 'Shared',
      'areas': [
        {'name': ''},
        {'name': 'Focus', 'drills': []},
      ],
      'goal': {'title': 'Run far', 'months': -3},
      'daily': [
        {'title': 'Walk', 'lane': 'weird', 'when': 'noon'},
        {'title': 'walk'},
        {'title': 'Read'},
        {'title': 'Stretch'},
      ],
      'stops': ['Scrolling', 'scrolling', ''],
    })}')!;
    expect(pasted.areas.map((a) => a.name), ['Focus']);
    expect(pasted.goal!.months, 1);
    expect(pasted.daily.map((d) => d.title), ['Walk', 'Read', 'Stretch']);
    expect(pasted.daily.first.lane, 'mind');
    expect(pasted.daily.first.when, 'day');
    expect(pasted.stops, ['Scrolling']);
    expect(PlanPack.fromText('ONO plan: {"name": 3, "areas": "x"}'), isNotNull);
    expect(PlanPack.fromText('not a plan'), isNull);

    final p = await _commissioned();
    final mine = p.addDailyItem('Journal', lane: 'mind', when: 'evening')!;
    p.applyPack(pasted, replaceDaily: true);
    expect(p.dailyItems.map((d) => d.title), ['Walk', 'Read', 'Stretch']);
    expect(p.retiredCustomItems.map((d) => d.id), [mine.id]);
    expect(p.dailyItem(mine.id)!.title, 'Journal');
    // Bringing a retired item back keeps it, rather than a new copy.
    p.applyPack(const PlanPack('Again', daily: [DailyIdea('Journal', 'mind', 'evening', '', '')]));
    expect(p.dailyItems.any((d) => d.id == mine.id), isTrue);
    expect(p.logsOf('daily_item').where((l) => l.text == 'Journal').length, 1);
  });

  test('values check: done only when every value is rated', () async {
    final p = await _commissioned();
    p.setValues([
      (name: 'Courage', meaning: ''),
      (name: 'Family', meaning: ''),
      (name: 'Growth', meaning: ''),
    ]);
    p.saveValuesCheck(_today, {'Courage': 2});
    expect(p.valuesCheckDone(_today), isFalse);
    p.saveValuesCheck(_today, {'Courage': 2, 'Family': 4, 'Growth': 5, 'Old value': 1});
    expect(p.valuesCheckDone(_today), isTrue);
    expect(p.valueGap(_today), 'Courage', reason: 'a removed value is never the gap');
  });

  test('loads overlap into one; signing out stops this person\'s reminders',
      () async {
    final r = _RecordingReminders();
    final p = PersonalSystemProvider(gateway: MockPersonalSystemGateway(), reminders: r)
      ..clock = () => _today;
    final a = p.load('one');
    final b = p.load('one');
    expect(identical(a, b), isTrue);
    await a;
    await p.commission(start: _start, gymDays: const [1, 3, 5], reminders: const {});
    p.setReminder(reminderDefs.first.id, true);
    await Future<void>.delayed(Duration.zero);
    expect(r.last, isNotEmpty);
    r.once[PersonalSystemProvider.restNotificationId] = _today;
    p.signedOut();
    await Future<void>.delayed(Duration.zero);
    expect(r.last, isEmpty);
    expect(r.once.containsKey(PersonalSystemProvider.restNotificationId), isFalse);
  });

  test('his plan after month 6: the book you read, not the last planned one',
      () async {
    final p = await _commissioned();
    expect(p.planBook.title, currentBook(2).title);
    p.clock = () => _start.plusDays(200);
    expect(p.programMonth, 7);
    expect(p.planBook, PersonalSystemProvider.noPlanBook);
    final l = p.addLearning('Thinking in Systems', kind: 'Book', by: 'Donella Meadows')!;
    p.startLearning(l.id);
    expect(p.planBook.title, 'Thinking in Systems');
  });

  test('Pennebaker counts this program; seeded evidence isn\'t practice',
      () async {
    final p = await _commissioned();
    expect(p.evidenceCount, greaterThan(0), reason: 'the seeded proof to read');
    expect(p.usesOf('evidence'), 0);
    for (var i = 0; i < 4; i++) {
      p.addLog('pennebaker', date: _start.plusDays(i), text: 'x');
    }
    expect(p.pennebakerSessions, 4);
    p.clock = () => _start.plusDays(40);
    p.startNextProgram(days: 90, changed: '', carry: '');
    expect(p.pennebakerSessions, 0);
  });

  test('after midnight the day still open is last night\'s', () async {
    final p = await _commissioned();
    final fri = dayOnly(_today);
    _hold(p, fri.minusDays(1));
    // Friday not held yet; at 01:00 Saturday it is still Friday's to hold.
    p.clock = () => DateTime(2026, 10, 3, 1);
    expect(p.logicalToday, fri);
    final before = p.streak;
    expect(p.isRecoveryDay, isFalse);
    _hold(p, fri);
    expect(p.streak, before + 1);
  });

  test('a past day shows the list it was scored on', () async {
    final p = await _commissioned();
    final yesterday = dayOnly(_today).minusDays(1);
    final first = p.dailyItems.first.id;
    p.setItemActive(first, false);
    expect(p.dailyItems.any((n) => n.id == first), isFalse);
    expect(p.itemsOn(yesterday).any((n) => n.id == first), isTrue);
    expect(p.itemsOn(yesterday).length, p.itemIdsOn(yesterday).length);
    expect(p.itemsOn(dayOnly(_today)).length, p.dailyCount);
  });

  test('first week: Not now moves on to the next step', () async {
    final p = await _commissioned();
    p.clock = () => _start.plusDays(4);
    final step = p.firstWeekStep!;
    p.skipFirstWeekStep(step.id);
    expect(p.firstWeekStep?.id, isNot(step.id));
  });

  test('what you know about them: answers, dates, what to ask next', () async {
    final p = await _commissioned();
    final aysel = p.addPerson('Aysel Karimova', role: 'Friend', every: 14);
    expect(p.knownCount(aysel), 0);
    expect(p.nextQuestionFor(aysel)!.$1, 'working_on');
    p.setKnow(aysel, 'working_on', ' Her first marathon ');
    var a = p.personById(aysel.id)!;
    expect(p.knowAnswer(a, 'working_on'), 'Her first marathon');
    expect(p.knowOn(a, 'working_on'), dayOnly(_today));
    expect(p.nextQuestionFor(a)!.$1, 'weighing');
    for (final q in PersonalSystemProvider.knowQuestions) {
      p.setKnow(p.personById(aysel.id)!, q.$1, 'Known');
    }
    a = p.personById(aysel.id)!;
    expect(p.knownCount(a), PersonalSystemProvider.knowQuestions.length);
    expect(p.nextQuestionFor(a), isNull);
    // Three months on, the oldest answer is worth asking again.
    p.clock = () => _today.plusDays(PersonalSystemProvider.knowStaleDays);
    expect(p.knowStale(a, 'working_on'), isTrue);
    expect(p.nextQuestionFor(a)!.$3, isTrue);
    p.setKnow(a, 'working_on', '');
    expect(p.knowAnswer(p.personById(aysel.id)!, 'working_on'), '');
  });

  test('what you know about them never goes to the coach', () async {
    final sent = _CapturingBriefs();
    final p = await _commissioned(briefs: sent);
    final aysel = p.addPerson('Aysel Karimova', role: 'Friend', every: 14);
    p.setKnow(aysel, 'weighing', 'Her mother is unwell');
    await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(_today),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: _today,
    ));
    expect(jsonEncode(sent.last!.toJson()), isNot(contains('unwell')));
  });

  test('courage ladder: lowest rung first, felt vs feared, the gap', () async {
    final p = await _commissioned();
    expect(p.addCourageStep(' ', fear: 3), isNull);
    final talk = p.addCourageStep('Give the talk', fear: 9)!;
    final speak = p.addCourageStep('Speak first in the meeting', fear: 4)!;
    final ask = p.addCourageStep('Ask for feedback', fear: 6)!;
    expect(p.nextCourageStep!.id, speak.id);
    p.doCourageStep(speak.id, felt: 2, happened: 'Nobody minded');
    expect(p.nextCourageStep!.id, ask.id);
    expect(p.courageGap, isNull, reason: 'needs three steps');
    p.doCourageStep(ask.id, felt: 3);
    p.doCourageStep(talk.id, felt: 6);
    expect(p.courageGap, closeTo((2 + 3 + 3) / 3, 0.01));
    expect(p.courageStepsInWeek(_today), 3);
    expect(p.nextCourageStep, isNull);
    final dropped = p.addCourageStep('Cold call', fear: 8)!;
    p.dropCourageStep(dropped.id);
    expect(p.courageLadder, isEmpty);
  });

  test('playbook: lessons from everywhere, pinned first, retired out', () async {
    final p = await _commissioned();
    expect(p.playbook(), isEmpty);
    p.logAar(event: 'The launch', improve: 'Rehearse the demo twice');
    p.saveMonthReview(1, carry: 'Keep mornings', lesson: 'Small steps beat big plans');
    final book = p.addLearning('Deep Work', kind: 'Book')!;
    p.applyLearning(book.id, principle: 'Protect one block a day', experiment: 'No meetings before 11');
    p.logAar(event: 'A quiet week');
    final texts = p.playbook().map((e) => e.text).toList();
    expect(texts, containsAll(['Rehearse the demo twice', 'Small steps beat big plans', 'Protect one block a day']));
    expect(texts.length, 3, reason: 'empty lessons are left out');
    final small = p.playbook().firstWhere((e) => e.text.startsWith('Small'));
    p.pinPlay(small.key, true);
    expect(p.playbook().first.key, small.key);
    expect(p.playbookText(), contains('★ Small steps beat big plans'));
    p.retirePlay(small.key, true);
    expect(p.playbook().any((e) => e.key == small.key), isFalse);
    expect(p.playbook(withRetired: true).any((e) => e.key == small.key), isTrue);
  });

  test('advice: try it, note the result, tell them', () async {
    final p = await _commissioned();
    final rashad = p.addPerson('Rashad Aliyev', role: 'Mentor', every: 30);
    expect(p.addAdvice(advice: ' '), isNull);
    final a = p.addAdvice(advice: 'Send the agenda the day before', from: 'Rashad Aliyev', about: 'Meetings')!;
    expect(p.adviceToReport, isEmpty);
    p.setAdviceStatus(a.id, 'trying');
    p.setAdviceStatus(a.id, 'tried', result: 'Meetings ran 15 minutes shorter');
    expect(p.adviceToReport.single.id, a.id);
    expect(p.betweenYou(p.personById(rashad.id)!).any((b) => b.$1.startsWith('Tell them')), isTrue);
    expect(p.playbook().any((e) => e.from == 'Advice from Rashad Aliyev'), isTrue);
    p.markAdviceReported(a.id, true);
    expect(p.adviceToReport, isEmpty);
    // Advice from nobody named has no one to report back to.
    final b = p.addAdvice(advice: 'Walk after lunch')!;
    p.setAdviceStatus(b.id, 'tried', result: 'Better afternoons');
    expect(p.adviceToReport, isEmpty);
  });

  test('a pinned rule comes back on Monday', () async {
    final p = await _commissioned();
    expect(p.ruleOfTheWeek(_today), isNull);
    p.logAar(event: 'The launch', improve: 'Rehearse the demo twice');
    p.pinPlay(p.playbook().single.key, true);
    expect(p.ruleOfTheWeek(_today), 'Rehearse the demo twice');
    final monday = weekStartOf(_today).plusDays(7);
    _hold(p, monday.minusDays(3));
    _hold(p, monday.minusDays(2));
    _hold(p, monday.minusDays(1));
    p.clock = () => monday.add(const Duration(hours: 9));
    expect(p.freshStartFor(monday)?.body, contains('A rule you wrote: "Rehearse the demo twice"'));
  });

  test('care: grooming comes due days before, booking, your real rhythm', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    final hair = p.addUpkeep('Haircut', 28, kind: 'grooming', lastDone: today.minusDays(20))!;
    expect(p.careKindOf(hair), 'grooming');
    // 8 days left of a 28-day cycle: not due yet (it comes due 7 days out).
    expect(p.upkeepDue.any((u) => u.id == hair.id), isFalse);
    p.clock = () => _today.plusDays(1);
    expect(p.upkeepDue.any((u) => u.id == hair.id), isTrue);
    // Booked: planned, not due; on Today the day before and on the day.
    p.bookUpkeep(hair.id, today.plusDays(3));
    expect(p.upkeepDue.any((u) => u.id == hair.id), isFalse);
    expect(p.upkeepBookedSoon(today.plusDays(1)), isEmpty);
    expect(p.upkeepBookedSoon(today.plusDays(2)).single.id, hair.id);
    p.markUpkeepDone(hair.id, on: today.plusDays(3));
    var h = p.upkeep.firstWhere((u) => u.id == hair.id);
    expect(p.upkeepBooked(h), isNull, reason: 'done clears the booking');
    expect(p.upkeepUsualEvery(h), isNull, reason: 'needs three visits');
    p.markUpkeepDone(hair.id, on: today.plusDays(28));
    h = p.upkeep.firstWhere((u) => u.id == hair.id);
    expect(p.upkeepUsualEvery(h), 25, reason: 'the middle of 23 and 25 days, rounded up');
    p.editUpkeep(hair.id, every: 25);
    expect(p.upkeep.firstWhere((u) => u.id == hair.id).number('every'), 25);
  });

  test('care: a document asks 90 days before it expires, never its number', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    final passport = p.addUpkeep('Passport', 0, kind: 'documents', expires: today.plusDays(200))!;
    expect(p.upkeepNextDue(passport), today.plusDays(110));
    expect(p.upkeepDue.any((u) => u.id == passport.id), isFalse);
    p.clock = () => _today.plusDays(100);
    expect(p.upkeepDue.any((u) => u.id == passport.id), isTrue);
    p.setUpkeepExpires(passport.id, today.plusDays(3750));
    expect(p.upkeepDue.any((u) => u.id == passport.id), isFalse);
    expect(p.upkeep.single.data.keys.toSet(), containsAll({'expires', 'kind'}));
    expect(p.addUpkeep('Haircut', 0, kind: 'grooming'), isNull, reason: 'non-documents need an interval');
  });

  test('check-in feelings: up to two words, counted over the month', () async {
    final p = await _commissioned();
    p.saveCheckin(dayOnly(_today), energy: 2, mood: -1, sleep: 6, pain: 0, stiffness: 0,
        feelings: const ['Tired', 'Stressed', 'Sad']);
    expect((p.checkinFor(dayOnly(_today))!.data['feelings'] as List).length, 2);
    p.saveCheckin(dayOnly(_today).minusDays(1), energy: 4, mood: 1, sleep: 8, pain: 0, stiffness: 0,
        feelings: const ['Tired']);
    expect(p.feelingsNamed().first, ('Tired', 2));
    p.saveCheckin(dayOnly(_today).minusDays(2), energy: 4, mood: 1, sleep: 8, pain: 0, stiffness: 0);
    expect(p.checkinFor(dayOnly(_today).minusDays(2))!.data.containsKey('feelings'), isFalse);
  });

  test('on this day: a month ago, weekly at most, never private writing', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    p.addLog('thought', date: today.minusDays(30), text: 'Private');
    expect(p.onThisDay(today), isNull);
    p.addLog('win', date: today.minusDays(30), text: 'Shipped the pricing page');
    final o = p.onThisDay(today)!;
    expect(o.when, 'A month ago');
    expect(o.text, 'Win: Shipped the pricing page');
    p.setDone(p.onThisDaySeenKey(today), true);
    expect(p.onThisDay(today), isNull);
  });

  test('time outside: minutes as logged, only moves marked outside', () async {
    final p = await _commissioned();
    p.logMove('walk', 40, outside: true);
    p.logMove('run', 20, vigorous: true, outside: true);
    p.logMove('strength', 30);
    expect(p.outsideMinutesInWeek(_today), 60);
    expect(p.moveMinutesInWeek(_today), 40 + 40 + 30);
  });

  test('time together: hours from touches with a length, last 90 days', () async {
    final p = await _commissioned();
    final mum = p.addPerson('Mum', role: 'Family', every: 7);
    p.logTouch(mum, minutes: 180);
    p.logTouch(mum, minutes: 60, date: dayOnly(_today).minusDays(10));
    p.logTouch(mum, minutes: 480, date: dayOnly(_today).minusDays(120));
    p.logTouch(mum);
    expect(p.hoursTogether(mum), 4);
  });

  test('routines: an item with steps opens its step-through; packs carry steps', () async {
    final p = await _commissioned();
    final evening = dailyLibrary.firstWhere((d) => d.title == 'Evening care');
    p.applyPack(PlanPack('Care', daily: [evening]));
    final item = p.dailyItems.firstWhere((n) => n.title == 'Evening care');
    expect(p.stepsOf(item.id), evening.steps);
    expect(item.route, '/routine?id=${item.id}');
    expect(p.myPack().daily.firstWhere((d) => d.title == 'Evening care').steps, evening.steps);
    final pasted = PlanPack.fromText(p.myPack().toText())!;
    expect(pasted.daily.firstWhere((d) => d.title == 'Evening care').steps, evening.steps);
    p.setSteps(item.id, const ['', ' ']);
    expect(p.stepsOf(item.id), isEmpty);
    expect(p.dailyItems.firstWhere((n) => n.id == item.id).route, isNull);
  });

  test('in my care: their care items, their story, a monthly caregiver check', () async {
    final sent = _CapturingBriefs();
    final p = await _commissioned(briefs: sent);
    final mum = p.addPerson('Leyla Huseynova', role: 'Mother', every: 7);
    expect(p.caregiverCheckDue, isFalse);
    p.setInMyCare(mum, true);
    expect(p.peopleInCare.single.id, mum.id);
    final eyes = p.addUpkeep('Leyla: Eye test', 365, forPerson: mum.id)!;
    expect(p.careKindOf(eyes), 'for');
    expect(p.careFor(p.personById(mum.id)!).single.id, eyes.id);
    p.setStoryAnswer(p.personById(mum.id)!, 'grew_up', 'Sheki, by the river');
    expect(p.storyAnswer(p.personById(mum.id)!, 'grew_up'), 'Sheki, by the river');
    p.clock = () => _start.plusDays(55);
    expect(p.caregiverCheckDue, isTrue);
    p.saveCaregiverCheck(heavy: 4, share: 'My brother');
    expect(p.caregiverCheckDue, isFalse);
    await p.submitReport(WeeklyReport(
      id: 'r',
      weekStart: weekStartOf(p.now),
      nonNegotiableAverage: 7,
      gymSessions: 3,
      bestMoment: '',
      hardestMoment: '',
      workSituation: '',
      createdAt: p.now,
    ));
    expect(jsonEncode(sent.last!.toJson()), isNot(contains('Sheki')));
  });

  test('care fixes: a passed booking comes due, care for someone leaves with them', () async {
    final p = await _commissioned();
    final today = dayOnly(_today);
    final hair = p.addUpkeep('Haircut', 28, kind: 'grooming', lastDone: today.minusDays(27))!;
    p.bookUpkeep(hair.id, today.plusDays(1));
    expect(p.upkeepDue.any((u) => u.id == hair.id), isFalse);
    p.clock = () => _today.plusDays(3);
    expect(p.upkeepDue.any((u) => u.id == hair.id), isTrue, reason: 'missed booking');
    final dad = p.addPerson('Dad', role: 'Father', every: 7);
    p.setInMyCare(dad, true);
    final dentist = p.addUpkeep('Dad: Dentist', 180, forPerson: dad.id)!;
    expect(p.upkeepDue.any((u) => u.id == dentist.id), isTrue);
    p.setInMyCare(p.personById(dad.id)!, false);
    expect(p.upkeepDue.any((u) => u.id == dentist.id), isFalse);
    p.removePerson(dad.id);
    expect(p.upkeep.any((u) => u.id == dentist.id), isFalse);
  });

  test('values in action: a small act this week, asked about next week', () async {
    final p = await _commissioned();
    p.setValues([(name: 'Family', meaning: ''), (name: 'Courage', meaning: ''), (name: 'Growth', meaning: '')]);
    p.saveValuesCheck(_today, {'Family': 2});
    p.setValueAct(_today, value: 'Family', act: 'Call Dad on Wednesday');
    expect(p.valuesCheck(_today), {'Family': 2}, reason: 'the act keeps the ratings');
    p.saveValuesCheck(_today, {'Family': 3});
    expect(p.valueAct(_today)!.act, 'Call Dad on Wednesday', reason: 'ratings keep the act');
    p.clock = () => _today.plusDays(7);
    final lastWeek = weekStartOf(p.now).minusDays(7);
    expect(p.valueAct(lastWeek)!.done, isNull);
    p.markValueAct(lastWeek, true);
    expect(p.valueAct(lastWeek)!.done, isTrue);
  });

  test('after-action review: advice to a friend joins the card and playbook', () async {
    final p = await _commissioned();
    p.logAar(event: 'The demo', improve: 'Rehearse twice', friend: 'Nobody remembers the stumble, only the point');
    expect(p.allCards.firstWhere((c) => c.id.startsWith('aar:')).back, contains('What you\'d tell a friend'));
    expect(p.playbook().any((e) => e.from == 'Advice to a friend · The demo'), isTrue);
  });

  test('reconnect: someone quiet for six months, at most weekly', () async {
    final p = await _commissioned();
    final old = p.addPerson('Kamran', role: 'Old friend', every: 365);
    p.logTouch(old, date: dayOnly(_today).minusDays(10));
    expect(p.reconnectSuggestion(_today), isNull);
    p.clock = () => _today.plusDays(200);
    expect(p.reconnectSuggestion(p.now)!.id, old.id);
    p.setDone(p.reconnectSeenKey(p.now), true);
    expect(p.reconnectSuggestion(p.now), isNull);
  });

  test('learning: guesses before reading; the deck mixes sources', () async {
    final p = await _commissioned();
    final book = p.addLearning('Thinking in Systems', kind: 'Book')!;
    p.startLearning(book.id);
    p.setLearningGuesses(book.id, ' Stocks and flows ');
    expect(p.learningById(book.id)!.str('guesses'), 'Stocks and flows');
    expect(p.learningById(book.id)!.str('status'), 'active');
    // Interleaving keeps every due card, alternating sources.
    final due = p.dueCards(_today);
    expect(due.length, due.map((c) => c.id).toSet().length);
  });

  test('steady sleep: wake-time spread from three nights; rules with your times', () async {
    final p = await _commissioned();
    final mon = weekStartOf(_today);
    expect(p.wakeSpread(_today), isNull);
    for (final (d, h, m) in [(0, 7, 0), (1, 7, 30), (2, 8, 15)]) {
      p.addLog('sleep', date: mon.plusDays(d), data: {'wake': DateTime(mon.year, mon.month, mon.day + d, h, m).toIso8601String()});
    }
    expect(p.wakeSpread(_today), 75);
    p.saveDayShape(wake: 420, workStart: 540, workEnd: 1080, bed: 1380);
    expect(p.sleepRules.last.cue, contains('15:00'));
    expect(p.sleepRules.first.cue, contains('07:00'));
  });

  test('visibility: what deciders saw in 90 days', () async {
    final p = await _commissioned();
    expect(p.decidersSeen, (0, 0));
    final boss = p.addPerson('Farid', role: 'Manager', every: 7);
    p.setBoardRoles(boss, ['decider']);
    final cfo = p.addPerson('Nigar', role: 'CFO', every: 30);
    p.setBoardRoles(cfo, ['decider', 'sponsor']);
    p.logVisible(p.personById(boss.id)!, what: 'Onboarding results', how: 'showed');
    expect(p.decidersSeen, (1, 2));
    p.clock = () => _today.plusDays(95);
    expect(p.decidersSeen, (0, 2));
  });

  test('1:1 agenda: the week, what you owe them, one ask to fill in', () async {
    final p = await _commissioned();
    p.setWeekOutcome(_today, 0, 'Ship the pricing page');
    p.addAsk(what: 'Budget for research', of: 'Farid');
    final agenda = p.oneOnOneAgenda('Farid');
    expect(agenda, contains('Ship the pricing page'));
    expect(agenda, contains('Budget for research'));
    expect(agenda, contains('My one ask'));
  });

  test('review fixes: whole-name agenda, circular wake spread, decider-only board', () async {
    final p = await _commissioned();
    p.addAsk(what: 'Budget for Natalia', of: 'Natalia');
    expect(p.oneOnOneAgenda('Ali'), isNot(contains('Natalia')));
    final mon = weekStartOf(_today);
    for (final (d, h, m) in [(0, 23, 40), (1, 0, 20), (2, 0, 0)]) {
      p.addLog('sleep', date: mon.plusDays(d), data: {'wake': DateTime(2026, 1, 1, h, m).toIso8601String()});
    }
    expect(p.wakeSpread(_today), 40);
    final boss = p.addPerson('Farid', role: 'Manager', every: 7);
    p.setBoardRoles(boss, ['decider']);
    expect(p.boardGaps, isEmpty);
    p.setValueAct(_today, value: 'Family', act: 'Call Dad');
    p.saveValuesCheck(_today, {'Family': 3});
    expect(p.valueAct(_today)!.act, 'Call Dad');
    p.setValueAct(_today, value: 'Family', act: '');
    expect(p.valueAct(_today), isNull);
    expect(p.valuesCheck(_today), {'Family': 3});
  });

  test('someone remembered is no longer in your care', () async {
    final p = await _commissioned();
    final mother = p.addPerson('Leyla');
    p.setInMyCare(mother, true);
    p.addUpkeep('Leyla: Dentist', 180, forPerson: mother.id);
    expect(p.upkeepDue.map((u) => u.text), contains('Leyla: Dentist'));
    p.setRemembered(p.people.single, true);
    final now = p.people.single;
    expect(p.inMyCare(now), isFalse);
    expect(p.peopleInCare, isEmpty);
    expect(p.upkeepDue.map((u) => u.text), isNot(contains('Leyla: Dentist')));
  });

  test('Today stops nudging about someone remembered', () async {
    final p = await _commissioned();
    p.addPerson('Rauf');
    p.addPromise(what: 'Fix the gate', to: 'Rauf', by: p.logicalToday);
    p.addAsk(what: 'Lend the drill', of: 'Rauf', guess: 50);
    final a = p.addAdvice(advice: 'Measure twice', from: 'Rauf');
    p.setAdviceStatus(a!.id, 'tried', result: 'Fewer mistakes');
    expect(p.promisesDue(p.logicalToday), hasLength(1));
    expect(p.adviceToReport, hasLength(1));
    p.setRemembered(p.people.single, true);
    expect(p.promisesDue(p.logicalToday), isEmpty);
    expect(p.adviceToReport, isEmpty);
    expect(p.asksToClose, isEmpty);
  });
}

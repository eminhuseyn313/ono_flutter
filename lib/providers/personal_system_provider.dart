import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/emin_system.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';
import '../services/brief_generator.dart';
import '../services/calendar_service.dart';
import '../services/health_service.dart';
import '../services/reminder_service.dart';
import '../services/widget_sync.dart';

/// Single source of truth for Emin's program. Every number the app shows is
/// computed here from real check-offs and logs.
class PersonalSystemProvider extends ChangeNotifier {
  final PersonalSystemGateway _gateway;
  final ReminderService? _reminders;
  final BriefGenerator _briefs;

  PersonalSystemProvider({
    required PersonalSystemGateway gateway,
    ReminderService? reminders,
    BriefGenerator? briefGenerator,
    HealthService? health,
    WidgetSync? widgets,
    CalendarService? calendar,
  })  : _gateway = gateway,
        _calendar = calendar ?? const NoopCalendarService(),
        _reminders = reminders,
        _briefs = briefGenerator ?? DeviceBriefGenerator(),
        _health = health ?? const NoopHealthService(),
        _widgets = widgets;

  final WidgetSync? _widgets;
  Timer? _widgetTimer;

  final HealthService _health;
  final CalendarService _calendar;

  static const _gymId = 'gym';
  static const _fallbackUser = 'local';

  String _userId = _fallbackUser;
  PersonalSystemState? _state;
  bool _loading = false;

  bool get isLoaded => _state != null;
  bool get isLoading => _loading;
  PersonalSystemState? get state => _state;

  /// Overridable clock for tests.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;
  DateTime get _now => clock();

  Future<void> load(String? userId) async {
    final id = userId ?? _fallbackUser;
    if (_state != null && id == _userId) return;
    _userId = id;
    _loading = true;
    notifyListeners();
    _state = await _gateway.load(id);
    _loading = false;
    notifyListeners();
    _syncReminders();
  }

  void _update(PersonalSystemState next, {bool reschedule = false}) {
    _state = next;
    notifyListeners();
    _gateway.save(_userId, next);
    if (reschedule) _syncReminders();
    _scheduleWidgetPush();
  }

  // ── Home Screen widget ───────────────────────────────────────────────

  /// What the widget should show right now.
  WidgetSnapshot widgetSnapshot() {
    final today = dayOnly(_now);
    return WidgetSnapshot(
      dateKey: dateKey(today),
      score: scoreFor(today),
      streak: streak,
      programDay: hasStarted ? programDay : 0,
      protein: proteinFor(today),
      cardsDue: dueCards(today).length,
      phase: phase.name,
      blocks: [for (final b in dailySchedule) (b.minuteOfDay, b.title)],
    );
  }

  /// Push to the widget at most every 2 seconds (ticks come in bursts).
  void _scheduleWidgetPush() {
    final w = _widgets;
    if (w == null || !isCommissioned) return;
    _widgetTimer?.cancel();
    _widgetTimer =
        Timer(const Duration(seconds: 2), () => w.push(widgetSnapshot()));
  }

  /// Push now (app start, back to foreground).
  Future<void> refreshWidget() async {
    final w = _widgets;
    if (w == null || !isCommissioned) return;
    await w.push(widgetSnapshot());
  }

  @override
  void dispose() {
    _widgetTimer?.cancel();
    super.dispose();
  }

  // ── Commission (onboarding) ──────────────────────────────────────────

  bool get isCommissioned => _state?.commissioned ?? false;

  Future<void> commission({
    required DateTime start,
    required List<int> gymDays,
    double? weightKg,
    required Map<String, bool> reminders,
  }) async {
    final s = _state;
    if (s == null) return;
    var next = s.copyWith(
      programStart: dayOnly(start),
      commissioned: true,
      manifestoSignedAt: _now,
      gymDays: gymDays,
      reminders: reminders,
    );
    if (weightKg != null) {
      next = next.copyWith(logs: [
        ...next.logs,
        _entry('weight', dayOnly(_now), data: {'kg': weightKg}),
      ]);
    }
    _update(next, reschedule: true);
  }

  // ── Program timeline ─────────────────────────────────────────────────

  DateTime get programStart => _state?.programStart ?? dayOnly(_now);

  /// 1-based day of the program; ≤ 0 means it hasn't started yet.
  int get programDay => dayOnly(_now).difference(programStart).inDays + 1;

  bool get hasStarted => programDay >= 1;
  int get daysUntilStart => hasStarted ? 0 : 1 - programDay;

  int get programMonth =>
      hasStarted ? (((programDay - 1) ~/ 30) + 1).clamp(1, programMonths) : 1;
  int get programWeek => hasStarted ? ((programDay - 1) ~/ 7) + 1 : 1;
  Phase get phase => phaseFor(programMonth);

  /// Day within the current month (1–30).
  int get dayOfMonth => hasStarted ? ((programDay - 1) % 30) + 1 : 0;

  DateTime monthStart(int month) =>
      programStart.add(Duration(days: (month - 1) * 30));

  void setProgramStart(DateTime date) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(programStart: dayOnly(date)), reschedule: true);
  }

  // ── Gym days ─────────────────────────────────────────────────────────

  List<int> get gymDays =>
      _state?.gymDays ??
      const [DateTime.monday, DateTime.wednesday, DateTime.thursday];

  void setGymDays(List<int> days) {
    final s = _state;
    if (s == null || days.length != 3) return;
    _update(s.copyWith(gymDays: days), reschedule: true);
  }

  GymDay? gymDayOn(DateTime date) => gymDayFor(date, gymDays);

  /// Next gym day from [from] (inclusive).
  ({DateTime date, GymDay day}) nextGymDay(DateTime from) {
    for (var i = 0; i < 8; i++) {
      final d = dayOnly(from).add(Duration(days: i));
      final g = gymDayOn(d);
      if (g != null) return (date: d, day: g);
    }
    return (date: dayOnly(from), day: gymPlan.first);
  }

  // ── Daily checks ─────────────────────────────────────────────────────

  List<String> _checks(DateTime date) =>
      _state?.dailyChecks[dateKey(date)] ?? const [];

  bool isChecked(DateTime date, String id) => _checks(date).contains(id);

  void setCheck(DateTime date, String id, bool value) {
    final s = _state;
    if (s == null || isChecked(date, id) == value) return;
    final key = dateKey(date);
    final current = List<String>.from(s.dailyChecks[key] ?? const []);
    value ? current.add(id) : current.remove(id);
    _update(s.copyWith(dailyChecks: {...s.dailyChecks, key: current}));
  }

  void toggleCheck(DateTime date, String id) =>
      setCheck(date, id, !isChecked(date, id));

  int scoreFor(DateTime date) {
    final ids = nonNegotiables.map((n) => n.id).toSet();
    return _checks(date).where(ids.contains).length;
  }

  bool gymDone(DateTime date) => isChecked(date, _gymId);
  void toggleGym(DateTime date) => toggleCheck(date, _gymId);

  List<DateTime> weekDays(DateTime anyDay) {
    final start = weekStartOf(anyDay);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Average Daily 10 over the days of that week that have passed and fall
  /// inside the program.
  double weekAverage(DateTime anyDay) {
    final now = _now;
    final days = weekDays(anyDay)
        .where((d) => !d.isAfter(now) && !d.isBefore(programStart))
        .toList();
    if (days.isEmpty) return 0;
    return days.fold<int>(0, (sum, d) => sum + scoreFor(d)) / days.length;
  }

  int gymSessionsInWeek(DateTime anyDay) =>
      weekDays(anyDay).where(gymDone).length;

  /// Never miss twice: one day under 7 is forgiven, as long as the next
  /// day is held (or is today, still open) and no other day was forgiven in
  /// the 6 days before it. Two misses in a row end the streak.
  ({int current, int best, bool pending}) get _streaks {
    final today = dayOnly(_now);
    var run = 0, best = 0;
    var prevMiss = false;
    DateTime? grace;
    for (var d = programStart;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final held = scoreFor(d) >= 7;
      if (held) {
        run++;
        prevMiss = false;
      } else if (d == today) {
        // Today is still open — it can't break anything yet.
      } else if (!prevMiss &&
          run > 0 &&
          (grace == null || d.difference(grace).inDays >= 7)) {
        grace = d;
        prevMiss = true;
      } else {
        run = 0;
        grace = null;
        prevMiss = true;
      }
      if (run > best) best = run;
    }
    return (current: run, best: best, pending: prevMiss && run > 0);
  }

  /// Current streak of held days, with one forgiven miss (see [_streaks]).
  int get streak => _streaks.current;

  int get bestStreak => _streaks.best;

  /// Yesterday slipped and today isn't held yet: today decides the streak.
  bool get isRecoveryDay {
    final today = dayOnly(_now);
    final yesterday = today.subtract(const Duration(days: 1));
    if (yesterday.isBefore(programStart)) return false;
    return scoreFor(yesterday) < 7 && scoreFor(today) < 7;
  }

  /// Days held in the current program month.
  int get daysHeldThisMonth => statsForMonth(programMonth).daysHeld;

  /// Days held (7+/10) since the program started.
  int get daysHeld {
    var n = 0;
    for (var d = programStart;
        !d.isAfter(dayOnly(_now));
        d = d.add(const Duration(days: 1))) {
      if (scoreFor(d) >= 7) n++;
    }
    return n;
  }

  /// Completion rate of each Daily 10 item over the given days.
  Map<String, double> itemRates(List<DateTime> days) {
    if (days.isEmpty) return {for (final n in nonNegotiables) n.id: 0};
    return {
      for (final n in nonNegotiables)
        n.id: days.where((d) => isChecked(d, n.id)).length / days.length,
    };
  }

  // ── Fresh starts ─────────────────────────────────────────────────────

  /// The temporal landmark that [day] is, if any: a new phase, a new month,
  /// or a Monday. Dismissed with `setDone(fs.key, true)`.
  FreshStart? freshStartFor(DateTime day) {
    if (!hasStarted || programDay < 2) return null;
    final d = dayOnly(day);
    final month = programMonth;
    if (dayOfMonth == 1 && month > 1) {
      final phase = phaseFor(month);
      final theme = monthThemes[month] ?? '';
      if (phase.fromMonth == month) {
        return FreshStart(
          key: 'fresh:phase:${phase.id}',
          eyebrow: 'Phase · months ${phase.fromMonth}–${phase.toMonth}',
          title: '${phase.name} begins',
          body: '${phase.promise}\n\nMonth $month: $theme',
          cta: 'Open month $month',
          route: '/month/$month',
        );
      }
      return FreshStart(
        key: 'fresh:month:$month',
        eyebrow: 'Month $month begins',
        title: theme,
        body: 'Artifact of the month: ${artifactFor(month)}.',
        cta: 'Open month $month',
        route: '/month/$month',
      );
    }
    if (d.weekday == DateTime.monday) {
      final lastWeek = weekDays(d.subtract(const Duration(days: 7)))
          .where((x) => !x.isBefore(programStart))
          .toList();
      if (lastWeek.length < 3) return null;
      final rates = itemRates(lastWeek).entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final weakest = nonNegotiables.firstWhere((n) => n.id == rates.first.key);
      final hits = (rates.first.value * lastWeek.length).round();
      return FreshStart(
        key: 'fresh:week:${dateKey(d)}',
        eyebrow: 'New week · week $programWeek',
        title: 'One commitment: ${weakest.title.toLowerCase()}',
        body: 'Last week: $hits of ${lastWeek.length} days.\n'
            'Your plan: ${cueFor(weakest.id)}.\n\n'
            'Close your eyes for 20 seconds and picture the moment the cue '
            'happens and you do it.',
        cta: 'Commit',
        itemId: weakest.id,
      );
    }
    return null;
  }

  // ── If-then plans ────────────────────────────────────────────────────

  /// The cue that triggers a Daily 10 item ("When X → Y").
  String cueFor(String id) => _state?.cues[id] ?? defaultCues[id] ?? '';

  bool hasCustomCue(String id) => _state?.cues.containsKey(id) ?? false;

  /// Save a cue; an empty [text] restores the default. Pass
  /// `reschedule: false` while typing and call [resyncReminders] after.
  void setCue(String id, String text, {bool reschedule = true}) {
    final s = _state;
    if (s == null) return;
    final next = Map<String, String>.from(s.cues);
    final t = text.trim();
    if (t.isEmpty || t == defaultCues[id]) {
      next.remove(id);
    } else {
      next[id] = t;
    }
    _update(s.copyWith(cues: next), reschedule: reschedule);
  }

  /// Re-schedule reminders now (e.g. after editing cues).
  void resyncReminders() => _syncReminders();

  // ── Morning check-in ─────────────────────────────────────────────────

  LogEntry? checkinFor(DateTime date) {
    final l = logsOn(date, 'checkin');
    return l.isEmpty ? null : l.last;
  }

  /// One check-in per day; saving again replaces it.
  void saveCheckin(DateTime date,
      {required int energy,
      required int mood,
      required double sleep,
      required int pain,
      required int stiffness}) {
    final data = {
      'energy': energy,
      'mood': mood,
      'sleep': sleep,
      'pain': pain,
      'stiffness': stiffness,
    };
    final existing = checkinFor(date);
    if (existing != null) {
      updateLog(LogEntry(
        id: existing.id,
        type: existing.type,
        date: existing.date,
        createdAt: existing.createdAt,
        text: existing.text,
        data: data,
      ));
    } else {
      addLog('checkin', date: date, data: data);
    }
  }

  /// Shoulders need sparing today: pain ≥ 5/10 or morning stiffness of
  /// 30 minutes or more (stiffness bucket ≥ 3).
  bool shoulderFlag(DateTime date) {
    final c = checkinFor(date);
    if (c == null) return false;
    return (c.number('pain') ?? 0) >= 5 || (c.number('stiffness') ?? 0) >= 3;
  }

  /// Flagged mornings in the 7 days ending [date].
  int flagDaysInWeekEnding(DateTime date) {
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (shoulderFlag(dayOnly(date).subtract(Duration(days: i)))) n++;
    }
    return n;
  }

  /// Check-ins in the [days] days ending [date], oldest first.
  List<LogEntry> checkinsEnding(DateTime date, int days) {
    final out = <LogEntry>[];
    for (var i = days - 1; i >= 0; i--) {
      final c = checkinFor(dayOnly(date).subtract(Duration(days: i)));
      if (c != null) out.add(c);
    }
    return out;
  }

  double? averageOf(List<LogEntry> entries, String key) {
    final v = entries.map((e) => e.number(key)).whereType<num>().toList();
    if (v.isEmpty) return null;
    return v.fold<double>(0, (s, x) => s + x) / v.length;
  }

  // ── Study deck (spaced repetition) ────────────────────────────────────

  /// Seed cards, one card per Feynman note, and your own cards.
  List<StudyCard> get allCards => [
        ...seedCards,
        for (final n in logsOf('feynman').reversed)
          if (n.text.trim().isNotEmpty)
            StudyCard(
              'feynman:${n.id}',
              'Explain from memory: ${n.str('book') ?? 'your reading'}'
                  '${(n.str('chapter') ?? '').isEmpty ? '' : ' — ${n.str('chapter')}'}',
              n.text,
              source: 'feynman',
            ),
        ...?_state?.customCards,
      ];

  CardSchedule? scheduleOf(String cardId) => _state?.cardSchedules[cardId];

  /// Cards to review on [day]: everything due, then up to
  /// [newCardsPerDay] unseen cards (minus those already introduced today).
  List<StudyCard> dueCards(DateTime day) {
    final d = dayOnly(day);
    final schedules = _state?.cardSchedules ?? const {};
    final due = <StudyCard>[];
    final fresh = <StudyCard>[];
    for (final c in allCards) {
      final s = schedules[c.id];
      if (s == null) {
        fresh.add(c);
      } else if (!s.due.isAfter(d)) {
        due.add(c);
      }
    }
    due.sort((a, b) => schedules[a.id]!.due.compareTo(schedules[b.id]!.due));
    final introducedToday = schedules.values
        .where((s) => dateKey(s.firstSeen) == dateKey(d))
        .length;
    final room = (newCardsPerDay - introducedToday).clamp(0, newCardsPerDay);
    return [...due, ...fresh.take(room)];
  }

  /// Grade 0 again · 3 hard · 4 good · 5 easy.
  void gradeCard(String cardId, int grade) {
    final s = _state;
    if (s == null) return;
    final today = dayOnly(_now);
    final current = s.cardSchedules[cardId] ?? CardSchedule.fresh(today);
    _update(s.copyWith(cardSchedules: {
      ...s.cardSchedules,
      cardId: current.review(grade, today),
    }));
  }

  /// Days until the card would next be due for [grade] (button labels).
  int previewInterval(String cardId, int grade) {
    final today = dayOnly(_now);
    final current = scheduleOf(cardId) ?? CardSchedule.fresh(today);
    return current.review(grade, today).interval;
  }

  /// Logged like an Anki review so the review streak keeps counting.
  void finishReview(int count) {
    if (count <= 0) return;
    addLog('anki', data: {'kind': 'review', 'count': count, 'deck': 'ono'});
  }

  void addCustomCard(String front, String back) {
    final s = _state;
    if (s == null || front.trim().isEmpty || back.trim().isEmpty) return;
    final card = StudyCard(
        'custom:${_now.microsecondsSinceEpoch}', front.trim(), back.trim(),
        source: 'custom');
    _update(s.copyWith(customCards: [...s.customCards, card]));
  }

  void removeCustomCard(String id) {
    final s = _state;
    if (s == null) return;
    final schedules = Map<String, CardSchedule>.from(s.cardSchedules)
      ..remove(id);
    _update(s.copyWith(
        customCards: s.customCards.where((c) => c.id != id).toList(),
        cardSchedules: schedules));
  }

  /// (total, learning, mature ≥ 21 days).
  ({int total, int learning, int mature}) get deckStats {
    final schedules = _state?.cardSchedules ?? const {};
    final cards = allCards;
    var learning = 0, mature = 0;
    for (final c in cards) {
      final s = schedules[c.id];
      if (s == null) continue;
      s.interval >= 21 ? mature++ : learning++;
    }
    return (total: cards.length, learning: learning, mature: mature);
  }

  // ── Career cockpit ───────────────────────────────────────────────────

  /// Log a 1:1: what was decided and the follow-ups you own.
  void addOneOnOne(
      {required String withWhom,
      required String decided,
      required List<String> followUps}) {
    addLog('one_on_one', text: decided.trim(), data: {
      'with': withWhom.trim().isEmpty ? 'Ali' : withWhom.trim(),
      'followups': [
        for (final f in followUps)
          if (f.trim().isNotEmpty) f.trim()
      ],
    });
  }

  /// Follow-ups from 1:1s not yet ticked, newest first.
  List<({String key, String text, DateTime date, String withWhom})>
      get openFollowUps => [
            for (final l in logsOf('one_on_one'))
              for (final (i, f)
                  in ((l.data['followups'] as List?) ?? const []).indexed)
                if (!isDone('fu:${l.id}:$i'))
                  (
                    key: 'fu:${l.id}:$i',
                    text: f as String,
                    date: l.date,
                    withWhom: l.str('with') ?? 'Ali'
                  ),
          ];

  /// Decision journal entry, reviewed again after [reviewInDays].
  void addDecision(
      {required String decision,
      required String options,
      required String why,
      required String expected,
      int reviewInDays = 90}) {
    addLog('decision', text: decision.trim(), data: {
      'options': options.trim(),
      'why': why.trim(),
      'expected': expected.trim(),
      'review_on': dateKey(dayOnly(_now).add(Duration(days: reviewInDays))),
    });
  }

  /// Decisions whose review date has come and that aren't reviewed yet.
  List<LogEntry> dueDecisionReviews(DateTime day) {
    final d = dateKey(dayOnly(day));
    return logsOf('decision')
        .where((l) =>
            l.str('verdict') == null &&
            (l.str('review_on') ?? '9999').compareTo(d) <= 0)
        .toList();
  }

  /// verdict: right | mixed | wrong.
  void reviewDecision(String id,
      {required String outcome, required String verdict}) {
    final l = (_state?.logs ?? const <LogEntry>[])
        .where((e) => e.id == id)
        .firstOrNull;
    if (l == null) return;
    updateLog(LogEntry(
      id: l.id,
      type: l.type,
      date: l.date,
      createdAt: l.createdAt,
      text: l.text,
      data: {
        ...l.data,
        'outcome': outcome.trim(),
        'verdict': verdict,
        'reviewed_on': dateKey(dayOnly(_now)),
      },
    ));
  }

  /// Monthly Head of Product self-rating, 1–5 per dimension.
  void saveReadiness(Map<String, int> ratings) {
    final existing = logsOf('readiness')
        .where((l) => l.number('month') == programMonth)
        .firstOrNull;
    final data = {'month': programMonth, 'ratings': ratings};
    if (existing != null) {
      updateLog(LogEntry(
          id: existing.id,
          type: existing.type,
          date: existing.date,
          createdAt: existing.createdAt,
          text: existing.text,
          data: data));
    } else {
      addLog('readiness', data: data);
    }
  }

  /// Latest readiness ratings (empty if never rated).
  Map<String, int> get readiness {
    final l = logsOf('readiness').firstOrNull;
    final r = (l?.data['ratings'] as Map?) ?? const {};
    return r.map((k, v) => MapEntry(k as String, (v as num).toInt()));
  }

  /// The dimension furthest below the bar, or null when all meet it.
  ReadinessDimension? get readinessGap {
    final r = readiness;
    if (r.isEmpty) return null;
    final below = readinessDimensions
        .where((d) => (r[d.id] ?? 0) < readinessBar)
        .toList()
      ..sort((a, b) => (r[a.id] ?? 0).compareTo(r[b.id] ?? 0));
    return below.firstOrNull;
  }

  bool get readinessDueThisMonth =>
      !logsOf('readiness').any((l) => l.number('month') == programMonth);

  // ── Automaticity ─────────────────────────────────────────────────────

  /// Monthly self-rating per Daily 10 item: "I do it without thinking"
  /// 1 (not at all) – 5 (completely).
  void saveAutomaticity(Map<String, int> ratings) {
    final existing = logsOf('automaticity')
        .where((l) => l.number('month') == programMonth)
        .firstOrNull;
    final data = {'month': programMonth, 'ratings': ratings};
    if (existing != null) {
      updateLog(LogEntry(
          id: existing.id,
          type: existing.type,
          date: existing.date,
          createdAt: existing.createdAt,
          text: existing.text,
          data: data));
    } else {
      addLog('automaticity', data: data);
    }
    _syncReminders();
  }

  Map<String, int> get automaticityRatings {
    final r = (logsOf('automaticity').firstOrNull?.data['ratings'] as Map?) ??
        const {};
    return r.map((k, v) => MapEntry(k as String, (v as num).toInt()));
  }

  /// Automatic = rated 4+ on the latest check and done on 80% of the last
  /// 30 program days. Both: a feeling alone isn't proof.
  bool isAutomatic(String id) {
    if ((automaticityRatings[id] ?? 0) < 4) return false;
    final today = dayOnly(_now);
    final days = [
      for (var i = 1; i <= 30; i++) today.subtract(Duration(days: i))
    ].where((d) => !d.isBefore(programStart)).toList();
    if (days.length < 14) return false;
    return (itemRates(days)[id] ?? 0) >= 0.8;
  }

  List<String> get automaticItems => [
        for (final n in nonNegotiables)
          if (isAutomatic(n.id)) n.id
      ];

  /// Prompt the monthly check from day 25 of each program month.
  bool get automaticityDue =>
      hasStarted &&
      dayOfMonth >= 25 &&
      !logsOf('automaticity').any((l) => l.number('month') == programMonth);

  // ── Apple Health ─────────────────────────────────────────────────────

  bool get healthSupported => _health.isSupported;
  bool get healthConnected => isDone('health:connected');
  bool _syncingHealth = false;

  /// Ask for Apple Health access. Returns null on success, otherwise a
  /// message saying what to do.
  Future<String?> connectHealth() async {
    if (!_health.isSupported) return 'Apple Health is only on iPhone.';
    try {
      final ok = await _health.connect();
      if (!ok) {
        return 'Access wasn\'t granted. Open the Health app → Sharing → '
            'Apps → ONO and allow Sleep, Heart and Weight.';
      }
    } on HealthUnavailable catch (e) {
      return e.message;
    }
    setDone('health:connected', true);
    await syncHealth();
    return null;
  }

  void disconnectHealth() => setDone('health:connected', false);

  /// Pull the last [nights] nights of sleep plus HRV and resting heart rate.
  /// Bed by 22:45 (15 minutes' grace) ticks "In bed by 10:30pm" for that
  /// evening; it never un-ticks.
  Future<void> syncHealth({int nights = 3}) async {
    if (!healthConnected || _syncingHealth) return;
    _syncingHealth = true;
    try {
      final today = dayOnly(_now);
      for (var i = 0; i < nights; i++) {
        final morning = today.subtract(Duration(days: i));
        final night = await _health.sleepEndingOn(morning);
        if (night != null && night.asleepHours > 0) {
          _upsertDayLog('sleep', morning, {
            'asleep_h': double.parse(night.asleepHours.toStringAsFixed(1)),
            'bed_start': night.bedStart.toIso8601String(),
            'wake': night.wake.toIso8601String(),
          });
          final evening = dayOnly(night.bedStart);
          final cutoff = evening.add(const Duration(hours: 22, minutes: 45));
          if (evening.isBefore(morning) &&
              !night.bedStart.isAfter(cutoff) &&
              !evening.isBefore(programStart)) {
            setCheck(evening, 'bed', true);
          }
        }
        final v = await _health.vitalsOn(morning);
        if (v.hrvMs != null || v.restingHr != null) {
          _upsertDayLog('vitals', morning, {
            if (v.hrvMs != null) 'hrv': v.hrvMs!.round(),
            if (v.restingHr != null) 'rhr': v.restingHr!.round(),
          });
        }
      }
    } finally {
      _syncingHealth = false;
    }
  }

  /// One log of [type] per day; replaced on each sync.
  void _upsertDayLog(String type, DateTime day, Map<String, dynamic> data) {
    final existing = logsOn(day, type);
    if (existing.isEmpty) {
      addLog(type, date: day, data: data);
    } else {
      final e = existing.last;
      updateLog(LogEntry(
          id: e.id,
          type: e.type,
          date: e.date,
          createdAt: e.createdAt,
          text: e.text,
          data: data));
    }
  }

  /// Hours asleep last night from Apple Health, if synced.
  double? sleepHoursFor(DateTime morning) {
    final l = logsOn(morning, 'sleep');
    return l.isEmpty ? null : l.last.number('asleep_h')?.toDouble();
  }

  // ── Priorities ───────────────────────────────────────────────────────

  List<String> prioritiesFor(DateTime date) {
    final p = _state?.priorities[dateKey(date)] ?? const [];
    return List.generate(3, (i) => i < p.length ? p[i] : '');
  }

  void setPriority(DateTime date, int index, String text) {
    final s = _state;
    if (s == null) return;
    final list = prioritiesFor(date);
    list[index] = text.trim();
    _update(s.copyWith(priorities: {...s.priorities, dateKey(date): list}));
  }

  bool priorityDone(DateTime date, int i) => isChecked(date, 'p$i');
  void togglePriority(DateTime date, int i) => toggleCheck(date, 'p$i');

  // ── One-off checklists ───────────────────────────────────────────────

  bool isDone(String key) => _state?.done.contains(key) ?? false;

  void setDone(String key, bool value) {
    final s = _state;
    if (s == null || isDone(key) == value) return;
    final next = Set<String>.from(s.done);
    value ? next.add(key) : next.remove(key);
    _update(s.copyWith(done: next));
  }

  void toggleDone(String key) => setDone(key, !isDone(key));

  int doneCount(Iterable<String> keys) => keys.where(isDone).length;

  // ── Logs ─────────────────────────────────────────────────────────────

  int _seq = 0;
  LogEntry _entry(String type, DateTime date,
          {String text = '', Map<String, dynamic> data = const {}}) =>
      LogEntry(
        id: '${type}_${_now.microsecondsSinceEpoch}_${_seq++}',
        type: type,
        date: dayOnly(date),
        createdAt: _now,
        text: text,
        data: data,
      );

  LogEntry? addLog(String type,
      {DateTime? date,
      String text = '',
      Map<String, dynamic> data = const {}}) {
    final s = _state;
    if (s == null) return null;
    final e = _entry(type, date ?? _now, text: text, data: data);
    _update(s.copyWith(logs: [...s.logs, e]), reschedule: type == 'pennebaker');
    return e;
  }

  void updateLog(LogEntry entry) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        logs: [for (final l in s.logs) l.id == entry.id ? entry : l]));
  }

  void removeLog(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(logs: s.logs.where((l) => l.id != id).toList()));
  }

  /// By the day a log is for, then by entry order — so a weigh-in
  /// backdated to yesterday never counts as the latest.
  static List<LogEntry> _newestFirst(List<LogEntry> list) {
    final order = {for (var i = 0; i < list.length; i++) list[i]: i};
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      final byCreated = b.createdAt.compareTo(a.createdAt);
      return byCreated != 0 ? byCreated : order[b]!.compareTo(order[a]!);
    });
    return list;
  }

  /// Newest first.
  List<LogEntry> logsOf(String type) {
    final list = (_state?.logs ?? const <LogEntry>[])
        .where((l) => l.type == type)
        .toList();
    return _newestFirst(list);
  }

  List<LogEntry> logsOn(DateTime date, [String? type]) => (_state?.logs ??
          const <LogEntry>[])
      .where((l) =>
          dateKey(l.date) == dateKey(date) && (type == null || l.type == type))
      .toList();

  /// All logs newest first, optionally filtered by type set.
  List<LogEntry> allLogs([Set<String>? types]) {
    final list = (_state?.logs ?? const <LogEntry>[])
        .where((l) => types == null || types.contains(l.type))
        .toList();
    return _newestFirst(list);
  }

  int countOf(String type) =>
      (_state?.logs ?? const <LogEntry>[]).where((l) => l.type == type).length;

  int countBetween(String type, DateTime from, DateTime to) =>
      (_state?.logs ?? const <LogEntry>[])
          .where((l) =>
              l.type == type && !l.date.isBefore(from) && l.date.isBefore(to))
          .length;

  // ── Protocol uses & mastery ──────────────────────────────────────────

  /// Log one use of a protocol and tick the Daily 10 item it satisfies.
  void logProtocolUse(String type,
      {String text = '', Map<String, dynamic> data = const {}}) {
    addLog(type, text: text, data: data);
    const ticks = {
      'sigh': 'sigh',
      'bluf': 'bluf',
      'pause': 'pause',
      'feynman': 'feynman',
      'scan': 'scan',
      'read': 'read',
    };
    final id = ticks[type];
    if (id != null) setCheck(_now, id, true);
  }

  int usesOf(String protocolId) {
    final type = protocolLogTypes[protocolId];
    if (type == null) return 0;
    if (type == 'evidence') return evidenceCount;
    return countOf(type);
  }

  String masteryOf(String protocolId) => masteryFor(usesOf(protocolId));

  int get pennebakerSessions => countOf('pennebaker');

  // ── Body ─────────────────────────────────────────────────────────────

  /// Weigh-ins oldest → newest.
  List<LogEntry> get weightSeries => logsOf('weight').reversed.toList();

  double? get latestWeight => logsOf('weight').isEmpty
      ? null
      : logsOf('weight').first.number('kg')?.toDouble();

  double? get startWeight =>
      weightSeries.isEmpty ? null : weightSeries.first.number('kg')?.toDouble();

  void logWeight(double kg, {DateTime? date}) {
    addLog('weight', date: date, data: {'kg': kg});
    if (healthConnected) _health.writeWeight(kg, date ?? _now);
  }

  int proteinFor(DateTime date) => logsOn(date, 'protein')
      .fold<int>(0, (sum, l) => sum + (l.number('g')?.toInt() ?? 0));

  void addProtein(DateTime date, int grams) {
    addLog('protein', date: date, data: {'g': grams});
    setCheck(date, 'protein', proteinFor(date) >= 150);
  }

  /// Most recent gym session for that day (A/B/C).
  LogEntry? lastSessionFor(String gymDayId) {
    for (final l in logsOf('gym')) {
      if (l.str('day') == gymDayId) return l;
    }
    return null;
  }

  void saveGymSession(
      DateTime date, String gymDayId, List<Map<String, dynamic>> exercises,
      {bool zone2 = false, bool shoulderSparing = false}) {
    final volume = exercises.fold<double>(0, (sum, e) {
      final sets = (e['sets'] as List).cast<Map<String, dynamic>>();
      return sum +
          sets.fold<double>(
              0,
              (s, set) =>
                  s +
                  ((set['kg'] as num?) ?? 0).toDouble() *
                      ((set['reps'] as num?) ?? 0).toDouble());
    });
    addLog('gym', date: date, data: {
      'day': gymDayId,
      'exercises': exercises,
      'zone2': zone2,
      'volume': volume,
      if (shoulderSparing) 'shoulder_sparing': true,
    });
    setCheck(date, _gymId, true);
  }

  /// Best weight ever lifted for an exercise, across sessions.
  double bestLift(String exercise) {
    var best = 0.0;
    for (final l in logsOf('gym')) {
      for (final e in (l.data['exercises'] as List? ?? const [])) {
        final m = Map<String, dynamic>.from(e as Map);
        if (m['name'] != exercise) continue;
        for (final set in (m['sets'] as List? ?? const [])) {
          final kg = ((set as Map)['kg'] as num?)?.toDouble() ?? 0;
          if (kg > best) best = kg;
        }
      }
    }
    return best;
  }

  LogEntry? latestBlood(String test) {
    for (final l in logsOf('blood')) {
      if (l.str('test') == test) return l;
    }
    return null;
  }

  // ── Evidence archive ─────────────────────────────────────────────────

  List<EvidenceItem> evidenceIn(String section) =>
      (_state?.evidence ?? const [])
          .where((e) => e.section == section)
          .toList();

  int get evidenceCount => _state?.evidence.length ?? 0;

  int evidenceAddedBetween(DateTime from, DateTime to) =>
      (_state?.evidence ?? const <EvidenceItem>[])
          .where((e) => !e.createdAt.isBefore(from) && e.createdAt.isBefore(to))
          .length;

  void addEvidence(String section, String text) {
    final s = _state;
    if (s == null || text.trim().isEmpty) return;
    final item = EvidenceItem(
      id: 'ev_${_now.microsecondsSinceEpoch}',
      section: section,
      text: text.trim(),
      createdAt: _now,
    );
    _update(s.copyWith(evidence: [...s.evidence, item]));
  }

  void removeEvidence(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(evidence: s.evidence.where((e) => e.id != id).toList()));
  }

  // ── Month review stats ───────────────────────────────────────────────

  MonthStats statsForMonth(int month) {
    final from = monthStart(month);
    final to = monthStart(month + 1);
    final today = dayOnly(_now);
    final days = <DateTime>[];
    for (var d = from;
        d.isBefore(to) && !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    final weights = weightSeries
        .where((l) => !l.date.isBefore(from) && l.date.isBefore(to))
        .toList();
    return MonthStats(
      month: month,
      daysElapsed: days.length,
      daily10Average: days.isEmpty
          ? 0
          : days.fold<int>(0, (s, d) => s + scoreFor(d)) / days.length,
      daysHeld: days.where((d) => scoreFor(d) >= 7).length,
      gymSessions: days.where(gymDone).length,
      evidenceAdded: evidenceAddedBetween(from, to),
      notes: countBetween('feynman', from, to) +
          countBetween('pennebaker', from, to) +
          countBetween('scan', from, to),
      protocolUses: ['sigh', 'excited', 'bluf', 'sixq', 'pause', 'still']
          .fold<int>(0, (s, t) => s + countBetween(t, from, to)),
      posts: countBetween('linkedin', from, to),
      artifacts: countBetween('artifact', from, to),
      weightStart:
          weights.isEmpty ? null : weights.first.number('kg')?.toDouble(),
      weightEnd: weights.isEmpty ? null : weights.last.number('kg')?.toDouble(),
    );
  }

  // ── Weekly reports & briefs ──────────────────────────────────────────

  List<WeeklyReport> get reports {
    final list = List<WeeklyReport>.from(_state?.reports ?? const []);
    list.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return list;
  }

  WeeklyReport? reportForWeek(DateTime anyDay) {
    final key = dateKey(weekStartOf(anyDay));
    for (final r in _state?.reports ?? const <WeeklyReport>[]) {
      if (dateKey(r.weekStart) == key) return r;
    }
    return null;
  }

  void saveReport(WeeklyReport report) {
    final s = _state;
    if (s == null) return;
    final others = s.reports
        .where((r) => dateKey(r.weekStart) != dateKey(report.weekStart))
        .toList();
    _update(s.copyWith(reports: [...others, report]));
  }

  List<WeeklyBrief> get briefs {
    final list = List<WeeklyBrief>.from(_state?.briefs ?? const []);
    list.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return list;
  }

  /// The brief written for the week containing [anyDay].
  WeeklyBrief? briefForWeek(DateTime anyDay) {
    final key = dateKey(weekStartOf(anyDay));
    for (final b in _state?.briefs ?? const <WeeklyBrief>[]) {
      if (dateKey(b.weekStart) == key) return b;
    }
    return null;
  }

  bool _generating = false;
  bool get isGeneratingBrief => _generating;
  String? briefError;

  /// Save the Sunday report and generate next week's brief from it.
  Future<WeeklyBrief?> submitReport(WeeklyReport report) async {
    saveReport(report);
    _generating = true;
    briefError = null;
    notifyListeners();
    try {
      final forWeek = report.weekStart.add(const Duration(days: 7));
      final weekCheckins = [
        for (final d in weekDays(report.weekStart))
          if (checkinFor(d) case final c?) c
      ];
      final brief = await _briefs.generate(BriefInput(
        report: report,
        forWeek: forWeek,
        programMonth: programMonth,
        programWeek: programWeek,
        itemRates: itemRates(
            weekDays(report.weekStart).where((d) => !d.isAfter(_now)).toList()),
        evidenceAddedThisWeek: evidenceAddedBetween(
            report.weekStart, report.weekStart.add(const Duration(days: 7))),
        artifactsThisMonth: countBetween(
            'artifact', monthStart(programMonth), monthStart(programMonth + 1)),
        postsThisWeek: countBetween('linkedin', report.weekStart,
            report.weekStart.add(const Duration(days: 7))),
        gymDays: gymDays,
        openUnlocks: unlocksFor(programMonth)
            .where((u) => u.doneKey == null || !isDone(u.doneKey!))
            .map((u) => u.title)
            .toList(),
        latestWeight: latestWeight,
        avgEnergy: averageOf(weekCheckins, 'energy'),
        avgSleep: averageOf(weekCheckins, 'sleep'),
        readinessGap: readinessGap?.name,
        openFollowUps: openFollowUps.length,
        patterns: patterns().map((p) => p.sentence).take(3).toList(),
        deepWorkHours: focusMinutesInWeek(report.weekStart) / 60,
        shutdowns: shutdownsInWeek(report.weekStart),
        weekOutcomes: [
          for (var i = 0; i < 3; i++)
            if (weekOutcomes(report.weekStart)[i].trim().isNotEmpty)
              '${weekOutcomeDone(report.weekStart, i) ? '[done]' : '[open]'} ${weekOutcomes(report.weekStart)[i].trim()}'
        ],
        peopleOverdue: [for (final p in peopleDue.take(3)) p.text],
        growthFocus: focusArea()?.name,
        growthDrill: focusArea() == null
            ? null
            : drillFor(focusArea()!, report.weekStart.add(const Duration(days: 7))).title,
        repsThisWeek: repsInWeek(report.weekStart),
        valueGap: valueGap(report.weekStart),
        openCommitments: [
          for (final c in commitmentsDue(report.weekStart.add(const Duration(days: 6))))
            c.str('will') ?? ''
        ],
        feedbackThisMonth: focusArea() == null
            ? 0
            : feedbackIn(focusArea()!.id, programMonth).length,
        shoulderFlagDays:
            weekCheckins.where((c) => shoulderFlag(c.date)).length,
      ));
      final s = _state!;
      final others = s.briefs
          .where((b) => dateKey(b.weekStart) != dateKey(brief.weekStart))
          .toList();
      _update(s.copyWith(briefs: [...others, brief]));
      return brief;
    } catch (e) {
      briefError = '$e';
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  // ── Reminders ────────────────────────────────────────────────────────

  bool reminderOn(String id) {
    final def = reminderDefs.firstWhere((d) => d.id == id);
    return _state?.reminders[id] ?? def.defaultOn;
  }

  void setReminder(String id, bool on) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(reminders: {...s.reminders, id: on}), reschedule: true);
  }

  Future<bool> requestReminderPermission() async =>
      await _reminders?.requestPermission() ?? false;

  /// Concrete notifications for the coming week, with today's content.
  List<PlannedReminder> plannedReminders() {
    if (!isCommissioned) return const [];
    final out = <PlannedReminder>[];
    final book = currentBook(programMonth);
    for (var i = 0; i < reminderDefs.length; i++) {
      final def = reminderDefs[i];
      if (!reminderOn(def.id)) continue;
      // Automatic habits don't need a nudge any more.
      if (itemReminder.entries
          .any((e) => e.value == def.id && isAutomatic(e.key))) {
        continue;
      }
      if (def.id == 'pennebaker' && pennebakerSessions >= 4) continue;
      final days = def.id == 'gym'
          ? gymDays
          : (def.weekdays ?? List.generate(7, (d) => d + 1));
      for (final wd in days) {
        var body = def.label;
        var title = 'ONO';
        switch (def.id) {
          case 'scan':
            final src = domainScanRotation.firstWhere((s) => s.weekday == wd);
            title = 'Domain scan · ${src.title}';
            body =
                'D3 + creatine + omega-3 with breakfast. Then 15 min: ${src.detail}.';
          case 'read':
            title = 'Lunch read · ${book.title}';
            body = '20 min, ${book.chapters}. Then 5 min Feynman from memory.';
          case 'gym':
            final g = gymDayFor(
                DateTime(2024, 1, wd), // 2024-01-01 is a Monday
                gymDays);
            title = g == null ? 'Gym' : 'Day ${g.letter} · ${g.name} at 19:00';
            body = 'Face pulls 3×15 never skipped. Zone 2 cooldown 15 min.';
          case 'ritual':
            title = 'Morning ritual · 5 min';
            body = EminIdentity.identityStatement;
          default:
            title = def.label;
            body = _reminderBody(def.id);
        }
        out.add(PlannedReminder(
          id: i * 10 + wd,
          weekday: wd,
          hour: def.hour,
          minute: def.minute,
          title: title,
          body: body,
          route: def.route,
        ));
      }
    }
    return out;
  }

  String _reminderBody(String id) {
    switch (id) {
      case 'wake':
        return '500ml before coffee, before the phone.';
      case 'winddown':
        return 'No screens. Tomorrow: ${outfitFor(_now.add(const Duration(days: 1))).occasion}.';
      case 'bed':
        return '${cueFor('bed')}. 7.5 hours protects tomorrow\'s mind.';
      case 'evidence_add':
        return 'Things built, problems solved, knowledge others don\'t have.';
      case 'evidence_read':
        return 'Proof before pressure — $evidenceCount items.';
      case 'report':
        return 'Five answers. Your brief for next week comes straight back.';
      case 'pennebaker':
        return 'Session ${pennebakerSessions + 1} of 4. Write without stopping.';
      case 'grooming':
        return 'Ten minutes on the beard line, then lay out Monday.';
      case 'caffeine':
        return cueFor('caffeine');
      default:
        return '';
    }
  }

  void _syncReminders() {
    final r = _reminders;
    if (r == null) return;
    r.sync(plannedReminders());
  }

  // ── Gym rest timer ───────────────────────────────────────────────────

  static const restNotificationId = onceIdBase + 1;

  /// Rest between sets: [exercise] is the lift; the default is 2 minutes
  /// for key lifts and 90 s for the rest.
  static Duration restFor(Exercise exercise) =>
      Duration(seconds: exercise.keyLift ? 120 : 90);

  /// Notifies when the rest ends, in case ONO is in the background then.
  Future<void> startRest(DateTime endsAt, {required String next}) async {
    await _reminders?.notifyOnce(restNotificationId, endsAt,
        title: 'Rest done', body: 'Next: $next', route: '/gym');
  }

  Future<void> cancelRest() async => _reminders?.cancel(restNotificationId);

  static const timerNotificationId = onceIdBase + 2;

  /// Tool timers (scan, lunch read, Pennebaker): a notification at the end
  /// in case ONO is in the background then.
  Future<void> notifyTimerEnd(DateTime at,
      {required String title,
      required String body,
      required String route}) async {
    await _reminders?.notifyOnce(timerNotificationId, at,
        title: title, body: body, route: route);
  }

  Future<void> cancelTimerEnd() async =>
      _reminders?.cancel(timerNotificationId);

  // ── Meetings (iPhone calendar) ───────────────────────────────────────

  bool get calendarSupported => _calendar.isSupported;
  bool get calendarConnected => isDone('calendar:connected');

  /// Kept in memory only: meeting titles and attendees never go into the
  /// saved state, the export or the cloud copy.
  List<Meeting> _meetings = const [];
  DateTime? _meetingsDay;

  static const _nudgeBase = onceIdBase + 100;
  static const _debriefBase = onceIdBase + 120;
  static const maxMeetingNudges = 8;

  /// Null when connected; otherwise what to do.
  Future<String?> connectCalendar() async {
    if (!_calendar.isSupported) return 'The calendar is available on the iPhone app.';
    if (!await _calendar.connect()) {
      return 'Calendar access was refused. Allow it in Settings → Privacy & Security → Calendars → ONO.';
    }
    setDone('calendar:connected', true);
    await syncCalendar();
    return null;
  }

  Future<void> disconnectCalendar() async {
    setDone('calendar:connected', false);
    _meetings = const [];
    _meetingsDay = null;
    await _cancelMeetingNudges();
    notifyListeners();
  }

  List<Meeting> meetingsFor(DateTime day) =>
      _meetingsDay != null && dayOnly(day) == _meetingsDay ? _meetings : const [];

  /// With Ali or Rustam (in the title or the invite).
  static bool isKeyMeeting(Meeting m) => keyPeople.any((name) {
        final re = RegExp('\\b${RegExp.escape(name)}\\b', caseSensitive: false);
        return re.hasMatch(m.title) || m.attendees.any(re.hasMatch);
      });

  /// Other people are in it (not a focus block or a reminder to self).
  static bool isRealMeeting(Meeting m) =>
      m.attendees.length >= 2 || isKeyMeeting(m);

  /// Hours in real meetings on [day].
  double meetingHours(DateTime day) =>
      meetingsFor(day).where(isRealMeeting).fold<double>(
          0, (s, m) => s + m.length.inMinutes / 60);

  /// A real meeting overlaps the 12:00 lunch read.
  bool lunchReadAtRisk(DateTime day) {
    final d = dayOnly(day);
    final from = d.add(const Duration(hours: 12));
    final to = d.add(const Duration(hours: 12, minutes: 20));
    return meetingsFor(day)
        .where(isRealMeeting)
        .any((m) => m.start.isBefore(to) && m.end.isAfter(from));
  }

  /// Loads today's meetings and sets a nudge 10 minutes before each real
  /// one still ahead: six questions for key meetings, the sigh otherwise.
  Future<void> syncCalendar() async {
    if (!calendarConnected || !_calendar.isSupported) return;
    final today = dayOnly(_now);
    _meetings = await _calendar.meetingsOn(today);
    _meetingsDay = today;
    notifyListeners();
    await _cancelMeetingNudges();
    final r = _reminders;
    if (r == null) return;
    var i = 0;
    for (final m in _meetings.where(isRealMeeting)) {
      final at = m.start.subtract(const Duration(minutes: 10));
      if (!at.isAfter(_now)) continue;
      if (i >= maxMeetingNudges) break;
      final key = isKeyMeeting(m);
      await r.notifyOnce(_nudgeBase + i, at,
          title: 'In 10 min: ${m.title}',
          body: key
              ? 'Six questions ready? Decision first, then three reasons. Sigh ×3 before you go in.'
              : 'Sigh ×3 before you go in. One breath before every answer.',
          route: key ? '/tool/sixq' : '/tool/sigh');
      i++;
    }
    // After-action review: debrief key meetings while they're fresh.
    var j = 0;
    for (final m in _meetings.where(isKeyMeeting)) {
      final at = m.end.add(const Duration(minutes: 5));
      if (!at.isAfter(_now)) continue;
      if (j >= maxMeetingNudges) break;
      await r.notifyOnce(_debriefBase + j, at,
          title: 'Debrief: ${m.title}',
          body: 'Two minutes while it\'s fresh: what was decided, who owns what, by when.',
          route: '/cockpit');
      j++;
    }
  }

  /// Key meetings that ended in the last 3 hours with no 1:1 logged since.
  List<Meeting> debriefsDue(DateTime now) {
    final logged = logsOn(now, 'one_on_one');
    return [
      for (final m in meetingsFor(now).where(isKeyMeeting))
        if (!m.end.isAfter(now) &&
            now.difference(m.end) <= const Duration(hours: 3) &&
            !logged.any((l) => !l.createdAt.isBefore(m.end)))
          m
    ];
  }

  /// Gaps of [minMinutes]+ between 09:00 and 18:00 still ahead on [day],
  /// around every calendar event and the 12:00–12:30 lunch read.
  List<({DateTime start, DateTime end})> freeBlocks(DateTime day,
      {int minMinutes = 60}) {
    if (!calendarConnected || _meetingsDay != dayOnly(day)) return const [];
    final d = dayOnly(day);
    var cursor = d.add(const Duration(hours: 9));
    if (_now.isAfter(cursor)) {
      // Round up to the next quarter hour.
      final q = (_now.minute / 15).ceil() * 15;
      cursor = DateTime(_now.year, _now.month, _now.day, _now.hour)
          .add(Duration(minutes: q));
    }
    final close = d.add(const Duration(hours: 18));
    final busy = [
      for (final m in _meetings) (start: m.start, end: m.end),
      (
        start: d.add(const Duration(hours: 12)),
        end: d.add(const Duration(hours: 12, minutes: 30))
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final out = <({DateTime start, DateTime end})>[];
    void gap(DateTime to) {
      final end = to.isAfter(close) ? close : to;
      if (end.difference(cursor).inMinutes >= minMinutes) {
        out.add((start: cursor, end: end));
      }
    }

    for (final b in busy) {
      if (!b.end.isAfter(cursor)) continue;
      if (b.start.isAfter(cursor)) gap(b.start);
      if (b.end.isAfter(cursor)) cursor = b.end;
      if (!cursor.isBefore(close)) return out;
    }
    gap(close);
    return out;
  }

  Future<void> _cancelMeetingNudges() async {
    final r = _reminders;
    if (r == null) return;
    for (var i = 0; i < maxMeetingNudges; i++) {
      await r.cancel(_nudgeBase + i);
      await r.cancel(_debriefBase + i);
    }
  }

  // ── Evening shutdown ─────────────────────────────────────────────────

  LogEntry? shutdownFor(DateTime day) {
    final l = logsOn(day, 'shutdown');
    return l.isEmpty ? null : l.last;
  }

  /// Today's priorities not ticked, to carry into tomorrow.
  List<String> carryOverFrom(DateTime day) {
    final p = prioritiesFor(day);
    return [
      for (var i = 0; i < 3; i++)
        if (p[i].trim().isNotEmpty && !priorityDone(day, i)) p[i].trim()
    ];
  }

  /// Writes tomorrow's three and closes [day]. Planning unfinished goals
  /// quiets them (Masicampo & Baumeister 2011); a written to-do list before
  /// bed shortens sleep onset (Scullin et al. 2018).
  void completeShutdown(DateTime day,
      {required List<String> tomorrow, String open = '', String win = ''}) {
    // One good thing, written down (Seligman et al. 2005). It's a win.
    if (win.trim().isNotEmpty &&
        !logsOn(day, 'win').any((w) => w.text == win.trim())) {
      addLog('win', date: dayOnly(day), text: win.trim());
    }
    final next = dayOnly(day).add(const Duration(days: 1));
    for (var i = 0; i < 3; i++) {
      setPriority(next, i, i < tomorrow.length ? tomorrow[i].trim() : '');
    }
    final p = prioritiesFor(day);
    _upsertDayLog('shutdown', dayOnly(day), {
      'open': open.trim(),
      'done': [for (var i = 0; i < 3; i++) if (p[i].isNotEmpty && priorityDone(day, i)) i].length,
      'set': p.where((x) => x.trim().isNotEmpty).length,
      'at': _now.toIso8601String(),
    });
  }

  int shutdownsInWeek(DateTime anyDay) =>
      weekDays(anyDay).where((d) => shutdownFor(d) != null).length;

  // ── Growth plan ──────────────────────────────────────────────────────

  LogEntry? _focusLog(int month) {
    for (final l in logsOf('growth_focus')) {
      if (l.number('month') == month) return l;
    }
    return null;
  }

  /// Areas he created himself (from scratch or a template).
  List<GrowthArea> get customAreas => [
        for (final l in logsOf('growth_area').reversed)
          GrowthArea.fromJson(l.data)
      ];

  /// His profile's areas first, then his own.
  List<GrowthArea> get allGrowthAreas => [...growthAreas, ...customAreas];

  /// Any area by id; a removed one reads as "Removed area".
  GrowthArea areaById(String id) {
    for (final a in allGrowthAreas) {
      if (a.id == id) return a;
    }
    return GrowthArea(id, 'Removed area',
        bar: '', ask: 'What could I do better here?', drills: const []);
  }

  LogEntry? _areaLog(String id) {
    for (final l in logsOf('growth_area')) {
      if (l.data['id'] == id) return l;
    }
    return null;
  }

  /// Creates or updates one of his own areas; returns it with its id.
  GrowthArea saveCustomArea(GrowthArea area) {
    final a = area.id.isEmpty || !area.id.startsWith('c_')
        ? area.copyWith(id: 'c_${_now.microsecondsSinceEpoch}', custom: true)
        : area.copyWith(custom: true);
    final existing = _areaLog(a.id);
    if (existing == null) {
      addLog('growth_area', text: a.name, data: a.toJson());
    } else {
      updateLog(existing.copyWith(text: a.name, data: a.toJson()));
    }
    return a;
  }

  /// Removes one of his own areas. Its past reps stay in the log.
  bool removeCustomArea(String id) {
    final l = _areaLog(id);
    if (l == null || focusArea()?.id == id) return false;
    removeLog(l.id);
    return true;
  }

  /// Drills he added to one of the profile's areas.
  List<Drill> _extraDrills(String areaId) {
    final l = logsOf('area_drills').where((x) => x.str('area') == areaId);
    if (l.isEmpty) return const [];
    return [
      for (final d in (l.first.data['drills'] as List? ?? const []))
        Drill.fromJson(d as Map)
    ];
  }

  /// An area's drills, including any he added.
  List<Drill> drillsOf(GrowthArea area) =>
      area.custom ? area.drills : [...area.drills, ..._extraDrills(area.id)];

  /// Adds a drill: into a custom area's own list, or alongside a profile
  /// area's built-in ones.
  void addDrill(GrowthArea area, Drill drill) {
    if (area.custom) {
      saveCustomArea(area.copyWith(drills: [...area.drills, drill]));
      return;
    }
    final extra = [..._extraDrills(area.id), drill];
    final data = {
      'area': area.id,
      'drills': [for (final d in extra) d.toJson()]
    };
    final l = logsOf('area_drills').where((x) => x.str('area') == area.id);
    if (l.isEmpty) {
      addLog('area_drills', data: data);
    } else {
      updateLog(l.first.copyWith(data: data));
    }
  }

  /// The area chosen for [month] (default: this month), or null.
  GrowthArea? focusArea([int? month]) {
    final l = _focusLog(month ?? programMonth);
    return l == null ? null : areaById(l.str('area') ?? '');
  }

  /// What to suggest when nothing is chosen: the readiness gap, else the
  /// first area.
  GrowthArea get suggestedArea =>
      readinessGap == null ? growthAreas.first : areaById(readinessGap!.id);

  /// Chooses this month's area, rated 1–5 where you are now.
  void setFocus(String areaId, {required int startRating}) {
    final month = programMonth;
    final existing = _focusLog(month);
    final data = {
      'area': areaId,
      'name': areaById(areaId).name,
      'month': month,
      'start': startRating,
      if (existing != null && existing.str('area') == areaId &&
          existing.number('end') != null)
        'end': existing.number('end'),
    };
    if (existing == null) {
      addLog('growth_focus', date: monthStart(month), data: data);
    } else {
      updateLog(existing.copyWith(data: data));
    }
  }

  /// Rates the month's area again at the end; the gap is the growth.
  void rateFocusEnd(int rating) {
    final l = _focusLog(programMonth);
    if (l == null) return;
    updateLog(l.copyWith(data: {...l.data, 'end': rating}));
  }

  /// (start, end) ratings for [month]'s area; end is null until rated.
  (int?, int?) focusRatings([int? month]) {
    final l = _focusLog(month ?? programMonth);
    return (l?.number('start')?.toInt(), l?.number('end')?.toInt());
  }

  /// Past months with a chosen area, newest first.
  List<LogEntry> get growthHistory => logsOf('growth_focus');

  /// Reps logged on [areaId] in the program month [month].
  List<LogEntry> repsIn(String areaId, int month) => [
        for (final l in logsOf('rep'))
          if (l.str('area') == areaId &&
              !l.date.isBefore(monthStart(month)) &&
              l.date.isBefore(monthStart(month + 1)))
            l
      ];

  int repsInWeek(DateTime anyDay) {
    final from = weekStartOf(anyDay);
    return countBetween('rep', from, from.add(const Duration(days: 7)));
  }

  /// This week's drill: the first not yet practised this month, rotating
  /// by week so each week brings a different one.
  Drill drillFor(GrowthArea area, DateTime day) {
    final done = repsIn(area.id, programMonth).map((r) => r.str('drill')).toSet();
    final week = dayOnly(day).difference(programStart).inDays ~/ 7;
    final drills = drillsOf(area);
    final n = drills.length;
    if (n == 0) {
      return const Drill('Add your first drill',
          'Write one concrete thing to practise this week, and how you\'ll know it worked.',
          'It\'s on the list.');
    }
    for (var i = 0; i < n; i++) {
      final d = drills[(week + i) % n];
      if (!done.contains(d.title)) return d;
    }
    return drills[week % n];
  }

  /// One rep through the learning cycle: what you did, what you noticed,
  /// the lesson, and what you'll do next time (Kolb 1984).
  void logRep(GrowthArea area, Drill drill,
          {required String did,
          String noticed = '',
          String lesson = '',
          String next = ''}) =>
      addLog('rep', text: did.trim(), data: {
        'area': area.id,
        'drill': drill.title,
        'noticed': noticed.trim(),
        'lesson': lesson.trim(),
        'next': next.trim(),
      });

  /// What someone told you, and what you'll do with it.
  void logFeedback(GrowthArea area,
          {required String from, required String said, String action = ''}) =>
      addLog('feedback', text: said.trim(), data: {
        'area': area.id,
        'from': from.trim(),
        'action': action.trim(),
      });

  List<LogEntry> feedbackIn(String areaId, int month) => [
        for (final l in logsOf('feedback'))
          if (l.str('area') == areaId &&
              !l.date.isBefore(monthStart(month)) &&
              l.date.isBefore(monthStart(month + 1)))
            l
      ];

  // ── Values ───────────────────────────────────────────────────────────

  /// His values, each with what it means to him, in his order.
  List<({String name, String meaning})> get values {
    final l = logsOf('values');
    if (l.isEmpty) return const [];
    return [
      for (final v in (l.first.data['values'] as List? ?? const []))
        (
          name: '${(v as Map)['name']}',
          meaning: '${v['meaning'] ?? ''}',
        )
    ];
  }

  void setValues(List<({String name, String meaning})> list) {
    final data = {
      'values': [
        for (final v in list) {'name': v.name, 'meaning': v.meaning.trim()}
      ]
    };
    final l = logsOf('values');
    if (l.isEmpty) {
      addLog('values', data: data);
    } else {
      updateLog(l.first.copyWith(data: data));
    }
  }

  /// A values affirmation: writing why a core value matters lowers the
  /// stress response in evaluative moments (Creswell et al. 2005; Cohen &
  /// Sherman 2014).
  void logAffirmation(String value, String text, {String before = ''}) =>
      addLog('affirmation',
          text: text.trim(), data: {'value': value, 'before': before.trim()});

  /// How much the week reflected each value, 1–5.
  Map<String, int> valuesCheck(DateTime anyDay) {
    final l = logsOn(weekStartOf(anyDay), 'values_check');
    if (l.isEmpty) return const {};
    return (l.last.data['ratings'] as Map? ?? const {})
        .map((k, v) => MapEntry('$k', (v as num).toInt()));
  }

  void saveValuesCheck(DateTime anyDay, Map<String, int> ratings) =>
      _upsertDayLog('values_check', weekStartOf(anyDay), {'ratings': ratings});

  /// The value this week reflected least, if checked and below 4.
  String? valueGap(DateTime anyDay) {
    final r = valuesCheck(anyDay);
    if (r.isEmpty) return null;
    final low = r.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return low.value < 4 ? low.key : null;
  }

  // ── Self-coaching (GROW) ─────────────────────────────────────────────

  /// One GROW session (Whitmore): goal, reality, options, will — with a
  /// date to check back and how committed he is (1–10).
  LogEntry logCoaching(
          {required String goal,
          required String reality,
          required List<String> options,
          required String will,
          required DateTime by,
          required int commitment}) =>
      addLog('coaching', text: goal.trim(), data: {
        'reality': reality.trim(),
        'options': [for (final o in options) if (o.trim().isNotEmpty) o.trim()],
        'will': will.trim(),
        'by': dateKey(by),
        'commitment': commitment,
      })!;

  List<LogEntry> get coachingSessions => logsOf('coaching');

  bool commitmentKept(String id) => isDone('coach:$id');
  void setCommitmentKept(String id, bool kept) => setDone('coach:$id', kept);

  /// Commitments whose date has come and that aren't marked kept.
  List<LogEntry> commitmentsDue(DateTime day) => [
        for (final c in coachingSessions)
          if (!dayOnly(day).isBefore(
                  DateTime.tryParse(c.str('by') ?? '') ?? dayOnly(day)) &&
              !commitmentKept(c.id) &&
              !isDone('coach:${c.id}:dropped'))
            c
      ];

  void dropCommitment(String id) => setDone('coach:$id:dropped', true);

  // ── Head of Product case ─────────────────────────────────────────────

  /// Everything logged that speaks to one professional area.
  ({
    int? rating,
    List<LogEntry> reps,
    List<LogEntry> feedback,
  }) caseFor(String areaId) => (
        rating: readiness[areaId],
        reps: [for (final r in logsOf('rep')) if (r.str('area') == areaId) r],
        feedback: [
          for (final f in logsOf('feedback')) if (f.str('area') == areaId) f
        ],
      );

  /// The case as plain text, to share or prepare a career conversation.
  String caseText() {
    final b = StringBuffer()
      ..writeln('${EminIdentity.name} — towards Head of Product')
      ..writeln('Day $programDay of $programDays · ${phase.name}')
      ..writeln();
    for (final a in growthAreas.where((a) => !a.personal)) {
      final c = caseFor(a.id);
      b.writeln('${a.name.toUpperCase()}'
          '${c.rating == null ? '' : ' — ${c.rating}/5 (bar $readinessBar)'}');
      b.writeln('Bar: ${a.bar}');
      for (final r in c.reps.take(3)) {
        final lesson = r.str('lesson') ?? '';
        b.writeln('• ${r.text}${lesson.isEmpty ? '' : ' → $lesson'}');
      }
      for (final f in c.feedback.take(2)) {
        b.writeln('• Feedback from ${f.str('from')}: "${f.text}"');
      }
      if (c.reps.isEmpty && c.feedback.isEmpty) {
        b.writeln('• Nothing logged yet — still to build.');
      }
      b.writeln();
    }
    final artifacts = [
      for (final a in logsOf('artifact'))
        if (a.str('status') == 'shipped' || a.str('status') == 'review') a
    ];
    if (artifacts.isNotEmpty) {
      b.writeln('ARTIFACTS');
      for (final a in artifacts) {
        b.writeln('• ${a.str('title')} (${a.str('kind')}, ${a.str('status')})');
      }
      b.writeln();
    }
    final right = [
      for (final d in logsOf('decision'))
        if (d.str('verdict') == 'right') d
    ];
    if (right.isNotEmpty) {
      b.writeln('DECISIONS THAT PROVED RIGHT');
      for (final d in right.take(5)) {
        b.writeln('• ${d.text}');
      }
      b.writeln();
    }
    final wins = logsOf('win').take(8).toList();
    final built = (_state?.evidence ?? const <EvidenceItem>[])
        .where((e) => e.section == 'built')
        .take(5)
        .toList();
    if (wins.isNotEmpty || built.isNotEmpty) {
      b.writeln('EVIDENCE');
      for (final e in built) {
        b.writeln('• ${e.text}');
      }
      for (final w in wins) {
        b.writeln('• ${w.text}');
      }
      b.writeln();
    }
    final gap = readinessGap;
    if (gap != null) {
      b.writeln('WHERE I\'M STILL GROWING');
      b.writeln('${gap.name}: ${gap.bar}');
    }
    return b.toString().trimRight();
  }

  // ── This week's Big 3 ────────────────────────────────────────────────

  LogEntry? _weekPlan(DateTime anyDay) {
    final l = logsOn(weekStartOf(anyDay), 'week_plan');
    return l.isEmpty ? null : l.last;
  }

  /// Three outcomes for the week of [anyDay] (blank when not set).
  List<String> weekOutcomes(DateTime anyDay) {
    final raw = (_weekPlan(anyDay)?.data['outcomes'] as List?) ?? const [];
    return [for (var i = 0; i < 3; i++) i < raw.length ? '${raw[i]}' : ''];
  }

  bool weekOutcomeDone(DateTime anyDay, int i) =>
      ((_weekPlan(anyDay)?.data['done'] as List?) ?? const []).contains(i);

  bool hasWeekPlan(DateTime anyDay) =>
      weekOutcomes(anyDay).any((o) => o.trim().isNotEmpty);

  void _saveWeekPlan(DateTime anyDay, List<String> outcomes, List<int> done) =>
      _upsertDayLog('week_plan', weekStartOf(anyDay),
          {'outcomes': outcomes, 'done': done..sort()});

  void setWeekOutcome(DateTime anyDay, int i, String text) {
    final o = weekOutcomes(anyDay)..[i] = text;
    final done = [
      for (var j = 0; j < 3; j++)
        if (weekOutcomeDone(anyDay, j) && (j != i || text.trim().isNotEmpty)) j
    ];
    _saveWeekPlan(anyDay, o, done);
  }

  void toggleWeekOutcome(DateTime anyDay, int i) {
    final done = [
      for (var j = 0; j < 3; j++)
        if (weekOutcomeDone(anyDay, j) != (j == i)) j
    ];
    _saveWeekPlan(anyDay, weekOutcomes(anyDay), done);
  }

  /// (done, set) for the week of [anyDay].
  (int, int) weekOutcomeScore(DateTime anyDay) {
    final o = weekOutcomes(anyDay);
    var set = 0, done = 0;
    for (var i = 0; i < 3; i++) {
      if (o[i].trim().isEmpty) continue;
      set++;
      if (weekOutcomeDone(anyDay, i)) done++;
    }
    return (done, set);
  }

  // ── People ───────────────────────────────────────────────────────────

  static const contactCadences = [7, 14, 30, 90];

  /// The people he invests in, oldest first. A `person` log holds the
  /// name, role and how often (days) he wants contact.
  List<LogEntry> get people => logsOf('person').reversed.toList();

  LogEntry addPerson(String name, {String role = '', int every = 30}) =>
      addLog('person',
          text: name.trim(), data: {'role': role.trim(), 'every': every})!;

  void removePerson(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        logs: s.logs
            .where((l) =>
                l.id != id && !(l.type == 'touch' && l.str('person') == id))
            .toList()));
  }

  void logTouch(LogEntry person, {String note = ''}) => addLog('touch',
      text: note.trim(), data: {'person': person.id, 'name': person.text});

  /// Last contact: a logged touch, or a 1:1 with them (name as a word).
  DateTime? lastContact(LogEntry person) {
    final first = person.text.split(' ').first;
    final re = RegExp('\\b${RegExp.escape(first)}\\b', caseSensitive: false);
    DateTime? last;
    for (final l in _state?.logs ?? const <LogEntry>[]) {
      final hit = (l.type == 'touch' && l.str('person') == person.id) ||
          (l.type == 'one_on_one' && re.hasMatch(l.str('with') ?? ''));
      if (hit && (last == null || l.date.isAfter(last))) last = l.date;
    }
    return last;
  }

  /// Days since the last contact (or since he was added, if never).
  int daysSinceContact(LogEntry person) =>
      dayOnly(_now).difference(dayOnly(lastContact(person) ?? person.date)).inDays;

  int cadenceOf(LogEntry person) => (person.number('every') ?? 30).toInt();

  /// Overdue people, most overdue (relative to their cadence) first.
  List<LogEntry> get peopleDue {
    final due = people
        .where((p) => daysSinceContact(p) >= cadenceOf(p))
        .toList()
      ..sort((a, b) => (daysSinceContact(b) / cadenceOf(b))
          .compareTo(daysSinceContact(a) / cadenceOf(a)));
    return due;
  }

  // ── Deep work ────────────────────────────────────────────────────────

  static const focusLengths = [25, 50, 90];

  /// One focus block; [target] is 'artifact', 'skill' or 'other'.
  void logFocus(int minutes, String target) =>
      addLog('focus', data: {'minutes': minutes, 'target': target});

  int focusMinutesBetween(DateTime from, DateTime to, {String? target}) =>
      (_state?.logs ?? const <LogEntry>[])
          .where((l) =>
              l.type == 'focus' &&
              !l.date.isBefore(from) &&
              l.date.isBefore(to) &&
              (target == null || l.str('target') == target))
          .fold<int>(0, (s, l) => s + (l.number('minutes') ?? 0).toInt());

  int focusMinutesInWeek(DateTime anyDay) {
    final start = weekStartOf(anyDay);
    return focusMinutesBetween(start, start.add(const Duration(days: 7)));
  }

  int get artifactMinutesThisMonth => focusMinutesBetween(
      monthStart(programMonth), monthStart(programMonth + 1),
      target: 'artifact');

  // ── Letters to future you ────────────────────────────────────────────

  /// Last day of the program (day 540).
  DateTime get programEnd =>
      programStart.add(const Duration(days: programDays - 1));

  /// First day of the next phase, or null in the last one.
  DateTime? get nextPhaseStart {
    final next = phase.toMonth + 1;
    return next > programMonths ? null : monthStart(next);
  }

  /// Sealed until [openOn]; written to the person he is becoming
  /// (future-self continuity, Hershfield 2011; Rutchick et al. 2018).
  void writeLetter(String text, DateTime openOn) => addLog('letter',
      text: text.trim(),
      data: {'open_on': dateKey(openOn), 'month': programMonth});

  List<LogEntry> get letters => logsOf('letter');

  DateTime letterOpensOn(LogEntry l) =>
      DateTime.tryParse(l.str('open_on') ?? '') ?? programEnd;

  bool letterIsOpen(LogEntry l) =>
      !dayOnly(_now).isBefore(letterOpensOn(l));

  List<LogEntry> get lettersToOpen => [
        for (final l in letters)
          if (letterIsOpen(l) && !isDone('letter:${l.id}')) l
      ];

  void markLetterRead(String id) => setDone('letter:$id', true);

  // ── Personal patterns ────────────────────────────────────────────────

  /// Patterns in the last [days] closed days (today excluded, never before
  /// the program start). Each compares days with and without one habit and
  /// needs [minDays] on both sides; small differences are dropped.
  List<DayPattern> patterns({int days = 60, int minDays = 5}) {
    final today = dayOnly(_now);
    final from = [
      today.subtract(Duration(days: days)),
      programStart,
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    final range = [
      for (var d = from; d.isBefore(today); d = d.add(const Duration(days: 1)))
        d
    ];
    DateTime next(DateTime d) => d.add(const Duration(days: 1));
    double? energy(DateTime d) => checkinFor(d)?.number('energy')?.toDouble();
    double? sleep(DateTime d) =>
        sleepHoursFor(d) ?? checkinFor(d)?.number('sleep')?.toDouble();
    double score(DateTime d) => scoreFor(d).toDouble();
    double scoreWithout(DateTime d, String id) =>
        (scoreFor(d) - (isChecked(d, id) ? 1 : 0)).toDouble();
    bool trained(DateTime d) => logsOn(d, 'gym').isNotEmpty;

    final out = <DayPattern>[];
    void compare({
      required String id,
      required String habit,
      required String outcome,
      required String unit,
      required double threshold,
      required bool? Function(DateTime) when,
      required double? Function(DateTime) measure,
      int digits = 1,
    }) {
      final yes = <double>[], no = <double>[];
      for (final d in range) {
        final w = when(d);
        final m = measure(d);
        if (w == null || m == null) continue;
        (w ? yes : no).add(m);
      }
      if (yes.length < minDays || no.length < minDays) return;
      double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
      final a = avg(yes), b = avg(no);
      if ((a - b).abs() < threshold) return;
      out.add(DayPattern(
        id: id,
        habit: habit,
        outcome: outcome,
        unit: unit,
        withHabit: a,
        without: b,
        daysWith: yes.length,
        daysWithout: no.length,
        digits: digits,
      ));
    }

    compare(
        id: 'sleep_score',
        habit: '7+ hours of sleep',
        outcome: 'Daily 10 that day',
        unit: '/10',
        threshold: 0.5,
        when: (d) => sleep(d) == null ? null : sleep(d)! >= 7,
        measure: score);
    compare(
        id: 'bed_energy',
        habit: 'In bed by 10:30',
        outcome: 'energy next morning',
        unit: '/5',
        threshold: 0.3,
        when: (d) => isChecked(d, 'bed'),
        measure: (d) => energy(next(d)));
    compare(
        id: 'caffeine_sleep',
        habit: 'No caffeine after 1pm',
        outcome: 'sleep that night',
        unit: ' h',
        threshold: 0.25,
        when: (d) => isChecked(d, 'caffeine'),
        measure: (d) => sleep(next(d)));
    compare(
        id: 'shutdown_sleep',
        habit: 'Evening shutdown',
        outcome: 'sleep that night',
        unit: ' h',
        threshold: 0.25,
        when: (d) => shutdownFor(d) != null,
        measure: (d) => sleep(next(d)));
    compare(
        id: 'gym_energy',
        habit: 'A gym session',
        outcome: 'energy next morning',
        unit: '/5',
        threshold: 0.3,
        when: trained,
        measure: (d) => energy(next(d)));
    compare(
        id: 'ritual_score',
        habit: 'Morning ritual',
        outcome: 'the other nine items',
        unit: '/9',
        threshold: 0.5,
        when: (d) => isChecked(d, 'manifesto'),
        measure: (d) => scoreWithout(d, 'manifesto'));
    compare(
        id: 'energy_score',
        habit: 'Morning energy 4–5',
        outcome: 'Daily 10 that day',
        unit: '/10',
        threshold: 0.5,
        when: (d) {
          final e = energy(d);
          return e == null ? null : e >= 4;
        },
        measure: score);
    out.sort((a, b) => b.relative.compareTo(a.relative));
    return out;
  }

  // ── Backup ───────────────────────────────────────────────────────────

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_state?.toJson() ?? {});

  /// Replace all data with an exported backup. Returns false if invalid.
  bool importJson(String raw) {
    try {
      final next =
          PersonalSystemState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _update(next, reschedule: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class MonthStats {
  final int month;
  final int daysElapsed;
  final double daily10Average;
  final int daysHeld;
  final int gymSessions;
  final int evidenceAdded;
  final int notes;
  final int protocolUses;
  final int posts;
  final int artifacts;
  final double? weightStart;
  final double? weightEnd;

  const MonthStats({
    required this.month,
    required this.daysElapsed,
    required this.daily10Average,
    required this.daysHeld,
    required this.gymSessions,
    required this.evidenceAdded,
    required this.notes,
    required this.protocolUses,
    required this.posts,
    required this.artifacts,
    this.weightStart,
    this.weightEnd,
  });
}

/// A temporal landmark worth a moment: Monday, a new month, a new phase.
class FreshStart {
  final String key;
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final String? route;

  /// The Daily 10 item this fresh start commits to (Mondays).
  final String? itemId;

  const FreshStart({
    required this.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    this.route,
    this.itemId,
  });
}

/// One personal pattern: an outcome averaged on days with and without a
/// habit. A correlation in his own data, not proof of cause.
class DayPattern {
  final String id;
  final String habit;
  final String outcome;
  final String unit;
  final double withHabit;
  final double without;
  final int daysWith;
  final int daysWithout;
  final int digits;

  const DayPattern({
    required this.id,
    required this.habit,
    required this.outcome,
    required this.unit,
    required this.withHabit,
    required this.without,
    required this.daysWith,
    required this.daysWithout,
    this.digits = 1,
  });

  double get delta => withHabit - without;

  /// Size of the gap relative to the scale, for ordering.
  double get relative {
    final scale = switch (unit) {
      '/10' => 10.0,
      '/9' => 9.0,
      '/5' => 5.0,
      _ => 8.0,
    };
    return delta.abs() / scale;
  }

  String fmt(double v) => '${v.toStringAsFixed(digits)}$unit';

  /// "No caffeine after 1pm → sleep that night 7.5 h vs 6.0 h without".
  String get sentence =>
      '$habit → $outcome ${fmt(withHabit)} vs ${fmt(without)} without';
}

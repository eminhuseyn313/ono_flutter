import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/emin_system.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';
import '../services/brief_generator.dart';
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
  })  : _gateway = gateway,
        _reminders = reminders,
        _briefs = briefGenerator ?? DeviceBriefGenerator(),
        _health = health ?? const NoopHealthService(),
        _widgets = widgets;

  final WidgetSync? _widgets;
  Timer? _widgetTimer;

  final HealthService _health;

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
    addLog('one_on_one',
        text: decided.trim(),
        data: {
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
    addLog('decision',
        text: decision.trim(),
        data: {
          'options': options.trim(),
          'why': why.trim(),
          'expected': expected.trim(),
          'review_on':
              dateKey(dayOnly(_now).add(Duration(days: reviewInDays))),
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
  void reviewDecision(String id, {required String outcome, required String verdict}) {
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
    final r =
        (logsOf('automaticity').firstOrNull?.data['ratings'] as Map?) ?? const {};
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

  List<String> get automaticItems =>
      [for (final n in nonNegotiables) if (isAutomatic(n.id)) n.id];

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
      {DateTime? date, String text = '', Map<String, dynamic> data = const {}}) {
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

  List<LogEntry> logsOn(DateTime date, [String? type]) =>
      (_state?.logs ?? const <LogEntry>[])
          .where((l) =>
              dateKey(l.date) == dateKey(date) &&
              (type == null || l.type == type))
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

  double? get startWeight => weightSeries.isEmpty
      ? null
      : weightSeries.first.number('kg')?.toDouble();

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

  void saveGymSession(DateTime date, String gymDayId,
      List<Map<String, dynamic>> exercises,
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
    addLog('gym',
        date: date,
        data: {
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
          .where((e) =>
              !e.createdAt.isBefore(from) && e.createdAt.isBefore(to))
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
    _update(s.copyWith(
        evidence: s.evidence.where((e) => e.id != id).toList()));
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
      weightStart: weights.isEmpty ? null : weights.first.number('kg')?.toDouble(),
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
        itemRates: itemRates(weekDays(report.weekStart)
            .where((d) => !d.isAfter(_now))
            .toList()),
        evidenceAddedThisWeek: evidenceAddedBetween(
            report.weekStart, report.weekStart.add(const Duration(days: 7))),
        artifactsThisMonth: countBetween('artifact', monthStart(programMonth),
            monthStart(programMonth + 1)),
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
        shoulderFlagDays: weekCheckins
            .where((c) => shoulderFlag(c.date))
            .length,
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
    _update(s.copyWith(reminders: {...s.reminders, id: on}),
        reschedule: true);
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
            body = 'D3 + creatine + omega-3 with breakfast. Then 15 min: ${src.detail}.';
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

  // ── Backup ───────────────────────────────────────────────────────────

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_state?.toJson() ?? {});

  /// Replace all data with an exported backup. Returns false if invalid.
  bool importJson(String raw) {
    try {
      final next = PersonalSystemState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
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

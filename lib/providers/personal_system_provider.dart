import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/daily_library.dart';
import '../data/emin_system.dart';
import '../data/growth_templates.dart';
import '../data/life_wheel.dart';
import '../data/plan_packs.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';
import '../services/brief_generator.dart';
import '../services/calendar_service.dart';
import '../services/health_service.dart';
import '../services/reminder_service.dart';
import '../services/widget_sync.dart';

/// Single source of truth for the program. Every number the app shows is
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
    _applyProfile();
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
      total: dailyCount,
      target: targetFor(today),
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

  /// 1-based day of the program; ≤ 0 means it hasn't started yet. Days of
  /// a long illness don't count (see [pausedDays]).
  int get programDay => programDayOf(_now);

  /// The program day [date] falls on: calendar days since the start, minus
  /// paused days before it. A paused day shares its number with the next.
  int programDayOf(DateTime date) {
    final d = dayOnly(date);
    final calendar = d.difference(programStart).inDays + 1;
    if (calendar < 1) return calendar;
    _reindex();
    return calendar - _pausedList.where((p) => p.isBefore(d)).length;
  }

  /// The first calendar date of program day [n], skipping paused days.
  DateTime dateForProgramDay(int n) {
    _reindex();
    var date = programStart.add(Duration(days: n - 1));
    for (final p in _pausedList) {
      if (!p.isAfter(date)) date = date.add(const Duration(days: 1));
    }
    return date;
  }

  /// Sick days in a row from which the program clock pauses for the whole
  /// illness, so 540 days of practice stay 540 days of practice.
  static const pauseAfterSickDays = 7;

  /// Calendar days the clock skipped for long illness.
  int get pausedDays {
    _reindex();
    return _pausedList.length;
  }

  bool isPaused(DateTime day) {
    _reindex();
    return _pausedKeys.contains(dateKey(day));
  }

  bool get hasStarted => programDay >= 1;
  int get daysUntilStart => hasStarted ? 0 : 1 - programDay;

  int get programMonth =>
      hasStarted ? (((programDay - 1) ~/ 30) + 1).clamp(1, programMonths) : 1;
  int get programWeek => hasStarted ? ((programDay - 1) ~/ 7) + 1 : 1;
  Phase get phase => phaseFor(programMonth);

  /// Day within the current month (1–30).
  int get dayOfMonth => hasStarted ? ((programDay - 1) % 30) + 1 : 0;

  DateTime monthStart(int month) => dateForProgramDay((month - 1) * 30 + 1);

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

  // ── Daily items (configurable) ───────────────────────────────────────

  /// Today's daily items: the profile's built-in ones he hasn't retired,
  /// then the ones he added. Every score, streak and check reads this.
  List<NonNegotiable> get dailyItems => [
        for (final n in nonNegotiables)
          if (!isDone('daily:off:${n.id}')) n,
        ...customDailyItems,
      ];

  List<NonNegotiable> get customDailyItems => [
        for (final l in logsOf('daily_item').reversed)
          NonNegotiable(l.str('id') ?? l.id, l.text, l.str('lane') ?? 'mind',
              l.str('when') ?? 'day')
      ];

  int get dailyCount => dailyItems.length;

  /// Holding the day = 70% of the items (7 of 10), at least 1.
  int get holdTarget => dailyCount == 0 ? 1 : (dailyCount * 0.7).ceil();

  bool isHeld(DateTime date) => scoreFor(date) >= targetFor(date);

  /// What holds [date]: the usual 70%, or half on a minimum day.
  int targetFor(DateTime date) => isMinimumDay(date) ? minimumTarget : holdTarget;

  /// Half the items, rounded up: the minimum day's bar.
  int get minimumTarget => dailyCount == 0 ? 1 : (dailyCount / 2).ceil();

  // ── Hard days ────────────────────────────────────────────────────────

  /// Days the plan can't be kept as written. A minimum day lowers the bar
  /// to the smallest version of each item; an emergency skip and a sick
  /// day are neutral for the streak, like planned rest. Skips are a small
  /// monthly reserve: goals with an emergency reserve are kept more often
  /// than easy or rigid ones (Sharif & Shu 2019).
  static const hardDayKinds = {
    'minimum': 'Minimum day',
    'sick': 'Sick day',
    'pass': 'Emergency skip',
  };

  /// Emergency skips per program month; unused ones don't roll over.
  /// Each person sets their own (some lives are more volatile).
  int get passesPerMonth => _state?.skipsPerMonth ?? 2;

  static const maxPassesPerMonth = 6;

  void setPassesPerMonth(int n) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(skipsPerMonth: n.clamp(0, maxPassesPerMonth)));
  }

  // Day-by-day lookups run for every day of the streak, so hard days and
  // rest ranges are indexed once per state.
  PersonalSystemState? _indexedState;
  Map<String, String> _hardIndex = const {};
  List<DateTime> _pausedList = const [];
  Set<String> _pausedKeys = const {};
  List<({DateTime from, DateTime to, bool rest})> _restIndex = const [];

  void _reindex() {
    if (identical(_indexedState, _state)) return;
    _indexedState = _state;
    final hard = <String, String>{};
    final rest = <({DateTime from, DateTime to, bool rest})>[];
    for (final l in _state?.logs ?? const <LogEntry>[]) {
      if (l.type == 'hard_day') {
        hard[dateKey(l.date)] = l.str('kind') ?? '';
      } else if (l.type == 'rest') {
        final from = DateTime.tryParse(l.str('from') ?? '');
        final to = DateTime.tryParse(l.str('to') ?? '');
        if (from != null && to != null) {
          rest.add((from: from, to: to, rest: l.str('kind') != 'light'));
        }
      }
    }
    _hardIndex = hard;
    _restIndex = rest;
    // Runs of [pauseAfterSickDays]+ sick days pause the clock.
    final sick = [
      for (final e in hard.entries)
        if (e.value == 'sick') DateTime.parse(e.key)
    ]..sort();
    final paused = <DateTime>[];
    var run = <DateTime>[];
    for (final d in [...sick, null]) {
      if (d != null &&
          run.isNotEmpty &&
          dateKey(DateTime(run.last.year, run.last.month, run.last.day + 1)) == dateKey(d)) {
        run.add(d);
        continue;
      }
      if (run.length >= pauseAfterSickDays) paused.addAll(run);
      run = d == null ? [] : [d];
    }
    _pausedList = paused;
    _pausedKeys = {for (final d in paused) dateKey(d)};
  }

  String? hardDayOn(DateTime day) {
    _reindex();
    return _hardIndex[dateKey(day)];
  }

  int passesUsedInMonth(int month) {
    final from = monthStart(month), to = monthStart(month + 1);
    return logsOf('hard_day')
        .where((l) =>
            l.str('kind') == 'pass' && !l.date.isBefore(from) && l.date.isBefore(to))
        .length;
  }

  int get passesLeft => passesPerMonth - passesUsedInMonth(programMonth);

  /// Marks [day] (today or yesterday) as a hard day, or clears it with
  /// null. A skip needs one left in that day's month. Returns false when
  /// refused.
  bool setHardDay(DateTime day, String? kind, {String note = ''}) {
    final d = dayOnly(day);
    final existing = logsOn(d, 'hard_day');
    if (kind == null) {
      for (final l in existing) {
        removeLog(l.id);
      }
      return true;
    }
    if (!hardDayKinds.containsKey(kind)) return false;
    if (kind == 'pass' && hardDayOn(d) != 'pass') {
      final month = (programDayOf(d) - 1) ~/ 30 + 1;
      if (passesUsedInMonth(month) >= passesPerMonth) return false;
    }
    _upsertDayLog('hard_day', d, {'kind': kind, 'note': note.trim()});
    return true;
  }

  /// Neither held nor missed: planned rest, a sick day or a skip.
  bool isExcused(DateTime day) =>
      isRestDay(day) || const {'sick', 'pass'}.contains(hardDayOn(day));

  /// The first day back after being sick, or after two or more days off:
  /// the minimum counts, so the return is easy (a lapse becomes a relapse
  /// when the first day back feels impossible).
  bool isReentryDay(DateTime day) {
    final d = dayOnly(day);
    if (isExcused(d)) return false;
    final prev = d.subtract(const Duration(days: 1));
    if (prev.isBefore(programStart)) return false;
    if (hardDayOn(prev) == 'sick') return true;
    return isExcused(prev) && isExcused(prev.subtract(const Duration(days: 1)));
  }

  bool isMinimumDay(DateTime day) =>
      hardDayOn(day) == 'minimum' || isReentryDay(day);

  /// Sick days in a row up to [day].
  int sickDaysInRow(DateTime day) {
    var n = 0;
    for (var d = dayOnly(day); hardDayOn(d) == 'sick'; d = d.subtract(const Duration(days: 1))) {
      n++;
    }
    return n;
  }

  /// Hard days in the week of [anyDay], by kind.
  Map<String, int> hardDaysInWeek(DateTime anyDay) {
    final out = <String, int>{};
    for (final d in weekDays(anyDay)) {
      final k = hardDayOn(d);
      if (k != null) out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  /// The smallest version of an item, for hard days.
  String minimumFor(String id) =>
      _state?.cues['min:$id'] ?? defaultMinimums[id] ?? '';

  void setMinimum(String id, String text) {
    final s = _state;
    if (s == null) return;
    final next = Map<String, String>.from(s.cues);
    final t = text.trim();
    if (t.isEmpty || t == defaultMinimums[id]) {
      next.remove('min:$id');
    } else {
      next['min:$id'] = t;
    }
    _update(s.copyWith(cues: next));
  }

  static const minDailyItems = 3;
  static const maxDailyItems = 15;

  bool isRetired(String id) => isDone('daily:off:$id');

  /// Retires (or brings back) a built-in item. Never below
  /// [minDailyItems].
  bool setItemActive(String id, bool active) {
    if (!active && dailyCount <= minDailyItems) return false;
    if (active && dailyCount >= maxDailyItems) return false;
    setDone('daily:off:$id', !active);
    _syncReminders();
    return true;
  }

  /// Adds an item of his own, with an if–then cue.
  NonNegotiable? addDailyItem(String title,
      {required String lane, required String when, String cue = ''}) {
    if (title.trim().isEmpty || dailyCount >= maxDailyItems) return null;
    final id = 'd_${_now.microsecondsSinceEpoch}';
    addLog('daily_item',
        text: title.trim(), data: {'id': id, 'lane': lane, 'when': when});
    if (cue.trim().isNotEmpty) setCue(id, cue.trim());
    return dailyItems.firstWhere((n) => n.id == id);
  }

  bool removeDailyItem(String id) {
    if (dailyCount <= minDailyItems) return false;
    final l = logsOf('daily_item').where((x) => x.str('id') == id);
    if (l.isEmpty) return false;
    removeLog(l.first.id);
    return true;
  }

  NonNegotiable? dailyItem(String id) {
    for (final n in [...nonNegotiables, ...customDailyItems]) {
      if (n.id == id) return n;
    }
    return null;
  }

  int scoreFor(DateTime date) {
    final ids = dailyItems.map((n) => n.id).toSet();
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
      final held = isHeld(d);
      if (held) {
        run++;
        prevMiss = false;
      } else if (isExcused(d)) {
        // Planned rest, a sick day or a skip: neither held nor missed.
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
    return !isHeld(yesterday) &&
        !isExcused(yesterday) &&
        !isHeld(today) &&
        !isExcused(today);
  }

  /// Days held in the current program month.
  int get daysHeldThisMonth => statsForMonth(programMonth).daysHeld;

  /// Days held (7+/10) since the program started.
  int get daysHeld {
    var n = 0;
    for (var d = programStart;
        !d.isAfter(dayOnly(_now));
        d = d.add(const Duration(days: 1))) {
      if (isHeld(d)) n++;
    }
    return n;
  }

  /// Completion rate of each Daily 10 item over the given days.
  /// Sick days, skips and rest don't count against an item.
  Map<String, double> itemRates(List<DateTime> all) {
    final days = [for (final d in all) if (!isExcused(d)) d];
    if (days.isEmpty) return {for (final n in dailyItems) n.id: 0};
    return {
      for (final n in dailyItems)
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
      final weakest = dailyItem(rates.first.key)!;
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

  /// Whether the built-in person is using ONO (their content — seed cards,
  /// gym plan, schedule — only applies to them).
  bool get isBuiltInPerson => activeProfile.name == builtInProfile.name;

  /// Seed cards (built-in person only), one card per Feynman note, lesson,
  /// applied principle and value, and your own cards. Retrieval keeps what
  /// you learned (Roediger & Karpicke 2006).
  List<StudyCard> get allCards => [
        if (isBuiltInPerson) ...seedCards,
        for (final r in logsOf('rep').reversed)
          if ((r.str('lesson') ?? '').trim().isNotEmpty)
            StudyCard(
              'lesson:${r.id}',
              'What did you learn from: ${r.str('drill') ?? 'a practice rep'}?',
              r.str('lesson')!.trim(),
              source: 'lesson',
            ),
        for (final l in logsOf('learning').reversed)
          if ((l.str('principle') ?? '').trim().isNotEmpty)
            StudyCard(
              'principle:${l.id}',
              'The principle you took from "${l.text}"?',
              '${l.str('principle')!.trim()}${(l.str('experiment') ?? '').isEmpty ? '' : '\n\nYour experiment: ${l.str('experiment')}'}',
              source: 'principle',
            ),
        for (final v in values)
          if (v.meaning.trim().isNotEmpty)
            StudyCard(
              'value:${v.name.toLowerCase()}',
              'What does ${v.name} mean to you?',
              v.meaning.trim(),
              source: 'value',
            ),
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
      'with': withWhom.trim().isEmpty ? activeProfile.manager : withWhom.trim(),
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
                    withWhom: l.str('with') ?? activeProfile.manager
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

  /// Monthly self-rating against the target role, 1–5 per dimension.
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
        for (final n in dailyItems)
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
      daysHeld: days.where(isHeld).length,
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
        itemTitles: {for (final n in dailyItems) n.id: n.title},
        itemCount: dailyCount,
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
        gymDays: isBuiltInPerson ? gymDays : const [],
        builtInPlan: isBuiltInPerson,
        openUnlocks: !isBuiltInPerson
            ? const []
            : unlocksFor(programMonth)
                .where((u) => u.doneKey == null || !isDone(u.doneKey!))
                .map((u) => u.title)
                .toList(),
        latestWeight: latestWeight,
        avgEnergy: averageOf(weekCheckins, 'energy'),
        avgSleep: averageOf(weekCheckins, 'sleep'),
        readinessGap: isBuiltInPerson ? readinessGap?.name : null,
        openFollowUps: openFollowUps.length,
        patterns: patterns().map((p) => p.sentence).take(3).toList(),
        deepWorkHours: focusMinutesInWeek(report.weekStart) / 60,
        hardDays: hardDaysInWeek(report.weekStart),
        direction: odysseyLeaning,
        moveMinutes: logsOf('move').isEmpty ? null : moveMinutesInWeek(report.weekStart),
        strengthDays: strengthDaysInWeek(report.weekStart),
        craftingMove: craftingMove,
        partner: partner == null || partnerRecord().weeks == 0
            ? null
            : 'with ${partner!.text}: you kept it ${partnerRecord().mine} of ${partnerRecord().weeks} weeks, they ${partnerRecord().theirs}',
        energyPeak: energyPeak == null
            ? null
            : '${energyPeak!.label.toLowerCase()} (${energyPeak!.from}:00–${energyPeak!.to}:00)',
        feedbackThemes: [
          for (final r in logsOf('feedback_round'))
            if ((r.str('themes') ?? '').isNotEmpty) r.str('themes')!
        ].firstOrNull,
        shutdowns: shutdownsInWeek(report.weekStart),
        weekOutcomes: [
          for (var i = 0; i < 3; i++)
            if (weekOutcomes(report.weekStart)[i].trim().isNotEmpty)
              '${weekOutcomeDone(report.weekStart, i) ? '[done]' : '[open]'} ${weekOutcomes(report.weekStart)[i].trim()}'
        ],
        peopleOverdue: [for (final p in peopleDue.take(3)) p.text],
        goals: goalSummaries(),
        noteSent: noteSentInWeek(report.weekStart),
        setbacks: setbacksInWeek(report.weekStart),
        restPlanned: restPlannedSoon,
        experiments: [
          for (final e in [...experimentsWith('running'), ...experimentsWith('kept').take(2)])
            '${e.text} (${e.str('status')}, watching ${experimentMeasures[e.str('measure')] ?? e.str('measure')}'
                '${experimentCompare(e).before == null || experimentCompare(e).during == null ? '' : ': ${experimentCompare(e).before!.toStringAsFixed(1)} before → ${experimentCompare(e).during!.toStringAsFixed(1)} during'})'
        ],
        learningApplied: [
          for (final l in learningWith('done').take(3))
            if ((l.str('principle') ?? '').isNotEmpty)
              '${l.text}: ${l.str('principle')}${(l.str('result') ?? '').isEmpty ? ' (experiment: ${l.str('experiment')})' : ' → ${l.str('result')}'}'
        ],
        lowestLifeArea: lowestLifeArea == null
            ? null
            : '${lowestLifeArea!.name} (${latestWheel[lowestLifeArea!.id]}/10)',
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
            body = activeProfile.identityStatement;
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

  /// With a profile key person (in the title or the invite).
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

  // ── Profile ──────────────────────────────────────────────────────────

  /// The person's own profile, if edited, stored as one `profile` log so
  /// it travels with export, import and sync.
  LogEntry? get _profileLog {
    final l = logsOf('profile');
    return l.isEmpty ? null : l.first;
  }

  bool get profileEdited => _profileLog != null;

  void _applyProfile() {
    final l = _profileLog;
    setProfileOverride(l == null ? null : Profile.fromJson(l.data));
  }

  /// Saves an edited profile; every screen and the coach read it from now.
  void saveProfile(Profile p) {
    final l = _profileLog;
    if (l == null) {
      addLog('profile', text: p.name, data: p.toJson());
    } else {
      updateLog(l.copyWith(text: p.name, data: p.toJson()));
    }
    _applyProfile();
    notifyListeners();
  }

  /// Back to the built-in profile.
  void resetProfile() {
    final l = _profileLog;
    if (l != null) removeLog(l.id);
    _applyProfile();
    notifyListeners();
  }

  // ── Plan builder ─────────────────────────────────────────────────────

  static const planBuiltKey = 'plan:built';

  bool get planBuilt => isDone(planBuiltKey);

  /// Offered on Today in the first two weeks, until there is a plan.
  bool get planBuildSuggested =>
      hasStarted && !planBuilt && activeGoals.isEmpty && programDay <= 14;

  /// Builds a first plan in one go: who they are becoming, a life wheel,
  /// this month's growth area, one goal (WOOP) and the daily items.
  /// A different name means a different person, so the profile's own
  /// details (organisation, people, coach context) start empty.
  /// [replaceDaily] swaps the whole daily list for [daily].
  void buildPlan({
    required String name,
    required String currentRole,
    required String targetRole,
    Map<String, int> wheel = const {},
    required GrowthArea area,
    required int areaRating,
    String goal = '',
    String goalWhy = '',
    String obstacle = '',
    String plan = '',
    DateTime? deadline,
    required List<DailyIdea> daily,
    bool replaceDaily = false,
  }) {
    final n = name.trim();
    final current = activeProfile;
    saveProfile(n.isEmpty || n == current.name
        ? current.copyWith(currentRole: currentRole.trim(), targetRole: targetRole.trim())
        : Profile(
            name: n,
            firstName: n.split(RegExp(r'\s+')).first,
            currentRole: currentRole.trim(),
            targetRole: targetRole.trim(),
            organisation: '',
            focus: '',
            domain: '',
            identityStatement: '',
            path: const [],
            keyPeople: const [],
          ));
    // The seeded evidence is the built-in person's; a new person starts
    // with none.
    if (!isBuiltInPerson && (_state?.evidence.any((e) => e.id.startsWith('seed_')) ?? false)) {
      final s = _state!;
      _update(s.copyWith(evidence: [
        for (final e in s.evidence)
          if (!e.id.startsWith('seed_')) e
      ]));
    }
    if (wheel.isNotEmpty) addLog('wheel', data: {'wheel': wheel});
    final areaId = area.custom || growthAreas.any((a) => a.id == area.id)
        ? area.id
        : saveCustomArea(area.copyWith(id: '')).id;
    setFocus(areaId, startRating: areaRating);
    if (goal.trim().isNotEmpty) {
      saveGoal(
          title: goal,
          why: goalWhy,
          obstacle: obstacle,
          plan: plan,
          deadline: deadline,
          areas: [areaId]);
    }
    if (replaceDaily && daily.length >= minDailyItems) {
      for (final b in nonNegotiables) {
        setDone('daily:off:${b.id}', true);
      }
      for (final l in logsOf('daily_item')) {
        removeLog(l.id);
      }
    }
    _addIdeas(daily);
    setDone(planBuiltKey, true);
    _syncReminders();
  }

  /// Adds daily items with their cues, skipping titles already there.
  /// Returns how many were added.
  int _addIdeas(List<DailyIdea> ideas) {
    var added = 0;
    for (final d in ideas) {
      if (dailyCount >= maxDailyItems) break;
      if (dailyItems.any((x) => x.title.toLowerCase() == d.title.toLowerCase())) continue;
      final id = 'd_${_now.microsecondsSinceEpoch}_${added++}';
      addLog('daily_item',
          text: d.title, data: {'id': id, 'lane': d.lane, 'when': d.when});
      if (d.cue.trim().isNotEmpty) setCue(id, d.cue, reschedule: false);
      if (d.minimum.trim().isNotEmpty) setMinimum(id, d.minimum);
    }
    return added;
  }

  // ── Accountability partner ───────────────────────────────────────────

  /// One partner, a two-way pact and a weekly check-in. Reporting
  /// progress to someone makes goals more likely to be reached (Harkin et
  /// al. 2016); a pact makes it mutual. ONO never sends anything: the
  /// update is copied and the answers are recorded by hand.
  static const checkinAnswers = ['kept', 'partly', 'missed'];

  LogEntry? get partner {
    for (final l in logsOf('partner')) {
      if ((l.str('status') ?? 'active') == 'active') return l;
    }
    return null;
  }

  LogEntry setPartner(String name,
      {required String mine, required String theirs, required int weekday}) {
    final p = partner;
    final data = {
      'mine': mine.trim(),
      'theirs': theirs.trim(),
      'weekday': weekday.clamp(1, 7),
      'status': 'active',
    };
    if (p == null) return addLog('partner', text: name.trim(), data: data)!;
    final next = p.copyWith(text: name.trim(), data: {...p.data, ...data});
    updateLog(next);
    return next;
  }

  void endPartnership() {
    final p = partner;
    if (p != null) {
      updateLog(p.copyWith(data: {...p.data, 'status': 'ended', 'ended': dateKey(_now)}));
    }
  }

  LogEntry? partnerCheckinFor(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    for (final l in logsOf('partner_checkin')) {
      if (dateKey(l.date) == dateKey(week)) return l;
    }
    return null;
  }

  /// Records this week's check-in: each side's answer from [checkinAnswers].
  void recordPartnerCheckin(DateTime anyDay,
      {required String mine, required String theirs, String note = ''}) {
    final p = partner;
    if (p == null) return;
    _upsertDayLog('partner_checkin', weekStartOf(anyDay), {
      'partner': p.text,
      'mine': mine,
      'theirs': theirs,
      'note': note.trim(),
    });
  }

  /// From the check-in weekday until this week's check-in is recorded.
  bool get partnerCheckinDue {
    final p = partner;
    if (p == null || !hasStarted) return false;
    final today = dayOnly(_now);
    final day = (p.number('weekday') ?? 7).toInt();
    return today.weekday >= day && partnerCheckinFor(today) == null;
  }

  /// The message for the partner: the pact, the week in numbers, honest
  /// about hard days, and their turn.
  String partnerUpdateText(DateTime anyDay) {
    final p = partner;
    if (p == null) return '';
    final week = weekStartOf(anyDay);
    final days = [
      for (final d in weekDays(week))
        if (!d.isAfter(dayOnly(_now)) && !d.isBefore(programStart)) d
    ];
    final held = days.where(isHeld).length;
    final hard = hardDaysInWeek(week);
    final (done, set) = weekOutcomeScore(week);
    final b = StringBuffer()
      ..writeln('Hi ${p.text.split(' ').first} — our weekly check-in.')
      ..writeln()
      ..writeln('My commitment: ${p.str('mine')}')
      ..writeln('This week: held my daily plan $held of ${days.length} days');
    if (hard.isNotEmpty) {
      b.writeln('Hard days: ${[for (final e in hard.entries) '${e.value} ${(hardDayKinds[e.key] ?? e.key).toLowerCase()}${e.value == 1 ? '' : 's'}'].join(', ')}');
    }
    if (set > 0) b.writeln('Week\'s three: $done of $set done');
    b
      ..writeln()
      ..writeln('Your turn: how did "${p.str('theirs')}" go this week?');
    return b.toString().trim();
  }

  /// Weeks each side kept the pact, over the last [weeks] check-ins.
  ({int mine, int theirs, int weeks}) partnerRecord({int weeks = 4}) {
    final p = partner;
    if (p == null) return (mine: 0, theirs: 0, weeks: 0);
    final l = [
      for (final c in logsOf('partner_checkin'))
        if (c.str('partner') == p.text) c
    ].take(weeks).toList();
    return (
      mine: l.where((c) => c.str('mine') == 'kept').length,
      theirs: l.where((c) => c.str('theirs') == 'kept').length,
      weeks: l.length,
    );
  }

  // ── Coach mode ───────────────────────────────────────────────────────

  /// A report for a coach, mentor or therapist over [from]–[to] (to
  /// exclusive): goals, the daily plan, growth, feedback, experiments and
  /// what was hard. Private writing (notes, letters, journal) never goes in.
  String coachReportText(DateTime from, DateTime to, {bool mornings = true}) {
    bool inRange(LogEntry l) => !l.date.isBefore(from) && l.date.isBefore(to);
    final today = dayOnly(_now);
    final days = <DateTime>[
      for (var d = from; d.isBefore(to) && !d.isAfter(today); d = d.add(const Duration(days: 1)))
        if (!d.isBefore(programStart)) d
    ];
    final p = activeProfile;
    final b = StringBuffer()
      ..writeln('${p.name} — progress ${dateKey(from)} to ${dateKey(to.subtract(const Duration(days: 1)))}')
      ..writeln('${p.currentRole} → ${p.targetRole}')
      ..writeln();
    if (activeGoals.isNotEmpty) {
      b.writeln('GOALS');
      for (final g in activeGoals) {
        final pace = goalPace(g);
        b.writeln('• ${g.text}: ${(goalProgress(g) * 100).round()}%${pace == null ? '' : ' ($pace)'}');
        if ((g.str('obstacle') ?? '').isNotEmpty) b.writeln('  Obstacle: ${g.str('obstacle')}');
      }
      b.writeln();
    }
    if (days.isNotEmpty) {
      final counted = [for (final d in days) if (!isExcused(d)) d];
      final held = counted.where(isHeld).length;
      b.writeln('DAILY PLAN ($dailyCount items)');
      b.writeln('• Held $held of ${counted.length} days');
      final hard = <String, int>{};
      for (final d in days) {
        final k = hardDayOn(d);
        if (k != null) hard[k] = (hard[k] ?? 0) + 1;
      }
      if (hard.isNotEmpty) {
        b.writeln('• Hard days: ${[for (final e in hard.entries) '${e.value} ${(hardDayKinds[e.key] ?? e.key).toLowerCase()}'].join(', ')}');
      }
      final rates = itemRates(days).entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      if (rates.isNotEmpty) {
        b.writeln('• Weakest: ${dailyItem(rates.first.key)?.title ?? rates.first.key} (${(rates.first.value * 100).round()}%)');
        b.writeln('• Strongest: ${dailyItem(rates.last.key)?.title ?? rates.last.key} (${(rates.last.value * 100).round()}%)');
      }
      b.writeln();
    }
    final reps = logsOf('rep').where(inRange).toList();
    final feedback = logsOf('feedback').where(inRange).toList();
    final focus = [for (final l in logsOf('growth_focus')) if (inRange(l)) l];
    if (reps.isNotEmpty || focus.isNotEmpty) {
      b.writeln('GROWTH');
      for (final f in focus) {
        final end = f.number('end');
        b.writeln('• ${f.str('name') ?? areaById(f.str('area') ?? '').name}: ${f.number('start')}${end == null ? '' : ' → $end'} of 5');
      }
      b.writeln('• ${reps.length} practice reps, ${feedback.length} pieces of feedback');
      for (final r in reps.take(3)) {
        if ((r.str('lesson') ?? '').isNotEmpty) b.writeln('  Lesson: ${r.str('lesson')}');
      }
      b.writeln();
    }
    final experiments = logsOf('experiment').where((e) => inRange(e) || e.str('status') == 'running').toList();
    if (experiments.isNotEmpty) {
      b.writeln('EXPERIMENTS');
      for (final e in experiments.take(3)) {
        b.writeln('• ${e.text} (${e.str('status')})${(e.str('result') ?? '').isEmpty ? '' : ': ${e.str('result')}'}');
      }
      b.writeln();
    }
    final setbacks = logsOf('setback').where(inRange).length;
    final wins = [for (final w in logsOf('win')) if (inRange(w)) w.text];
    if (wins.isNotEmpty || setbacks > 0) {
      b.writeln('WINS AND SETBACKS');
      for (final w in wins.take(3)) {
        b.writeln('• $w');
      }
      if (setbacks > 0) b.writeln('• $setbacks setback${setbacks == 1 ? '' : 's'} met with a next step');
      b.writeln();
    }
    if (mornings) {
      final checkins = logsOf('checkin').where(inRange).toList();
      final energy = averageOf(checkins, 'energy');
      final sleep = averageOf(checkins, 'sleep');
      if (energy != null || sleep != null) {
        b.writeln('MORNINGS');
        if (energy != null) b.writeln('• Energy ${energy.toStringAsFixed(1)} / 5');
        if (sleep != null) b.writeln('• Sleep ${sleep.toStringAsFixed(1)} h');
        b.writeln();
      }
    }
    b.writeln('What I\'d like your view on:');
    return b.toString().trim();
  }

  // ── Hard conversations ───────────────────────────────────────────────

  /// Prepare a conversation you've been avoiding — feedback, a conflict, a
  /// boundary, at work or at home. Start with what you really want for you,
  /// them and the relationship; separate facts from your story; imagine
  /// theirs (Patterson et al., Crucial Conversations; Stone, Patton & Heen,
  /// Difficult Conversations). Debriefed after it happened.
  static const conversationOutcomes = {
    'better': 'Better than I feared',
    'same': 'About as expected',
    'worse': 'Harder than I hoped',
  };

  List<LogEntry> get conversations => logsOf('conversation');

  LogEntry? conversationById(String id) {
    for (final c in conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  LogEntry? saveConversation({
    String? id,
    required String withWhom,
    required String about,
    String wantMe = '',
    String wantThem = '',
    String wantUs = '',
    String facts = '',
    String myStory = '',
    String theirStory = '',
    String opening = '',
    String ask = '',
    DateTime? by,
  }) {
    if (withWhom.trim().isEmpty) return null;
    final data = {
      'with': withWhom.trim(),
      'want_me': wantMe.trim(),
      'want_them': wantThem.trim(),
      'want_us': wantUs.trim(),
      'facts': facts.trim(),
      'my_story': myStory.trim(),
      'their_story': theirStory.trim(),
      'opening': opening.trim(),
      'ask': ask.trim(),
      'by': by == null ? null : dateKey(by),
    };
    final existing = id == null ? null : conversationById(id);
    if (existing == null) {
      return addLog('conversation', text: about.trim(), data: {...data, 'status': 'planned'});
    }
    final next = existing.copyWith(text: about.trim(), data: {...existing.data, ...data});
    updateLog(next);
    return next;
  }

  void debriefConversation(String id, {required String outcome, String learned = ''}) {
    final c = conversationById(id);
    if (c == null) return;
    updateLog(c.copyWith(data: {
      ...c.data,
      'status': 'done',
      'outcome': outcome,
      'learned': learned.trim(),
      'done_on': dateKey(_now),
    }));
  }

  List<LogEntry> get plannedConversations =>
      [for (final c in conversations) if (c.str('status') == 'planned') c];

  /// Planned conversations whose day has come: debrief them, or have them.
  List<LogEntry> conversationsDue(DateTime day) {
    final d = dateKey(dayOnly(day));
    return [
      for (final c in plannedConversations)
        if ((c.str('by') ?? '').isNotEmpty && c.str('by')!.compareTo(d) <= 0) c
    ];
  }

  // ── Movement ─────────────────────────────────────────────────────────

  /// Any movement, for anyone: a walk, a run, a game, a class. Weekly
  /// targets follow the WHO 2020 guidelines: 150–300 minutes of moderate
  /// activity (a vigorous minute counts double) and strength work on 2+
  /// days.
  static const moveKinds = {
    'walk': 'Walk',
    'run': 'Run',
    'cycle': 'Cycle',
    'swim': 'Swim',
    'strength': 'Strength',
    'sport': 'Sport',
    'yoga': 'Yoga / mobility',
    'other': 'Other',
  };
  static const weeklyMoveTarget = 150;
  static const weeklyStrengthDays = 2;

  LogEntry? logMove(String kind, int minutes, {bool vigorous = false, DateTime? day}) =>
      minutes <= 0
          ? null
          : addLog('move',
              date: day == null ? null : dayOnly(day),
              data: {'kind': kind, 'minutes': minutes, 'vigorous': vigorous});

  List<LogEntry> movesInWeek(DateTime anyDay) {
    final from = weekStartOf(anyDay), to = from.add(const Duration(days: 7));
    return [
      for (final l in logsOf('move'))
        if (!l.date.isBefore(from) && l.date.isBefore(to)) l
    ];
  }

  /// Moderate-equivalent minutes in the week (vigorous counts double).
  int moveMinutesInWeek(DateTime anyDay) => movesInWeek(anyDay).fold<int>(
      0,
      (s, l) =>
          s + (l.number('minutes') ?? 0).toInt() * (l.data['vigorous'] == true ? 2 : 1));

  /// Days with strength work: a strength move or a logged gym session.
  int strengthDaysInWeek(DateTime anyDay) {
    final days = <String>{
      for (final l in movesInWeek(anyDay))
        if (l.str('kind') == 'strength') dateKey(l.date),
      for (final d in weekDays(anyDay))
        if (gymDone(d)) dateKey(d),
    };
    return days.length;
  }

  // ── Odyssey plan ─────────────────────────────────────────────────────

  /// Three different five-year lives, rated on the same four questions, so
  /// direction is chosen rather than drifted into (Burnett & Evans 2016).
  static const odysseyPrompts = [
    'The life you\'re heading for',
    'If that path disappeared tomorrow',
    'If money and other people\'s opinion didn\'t matter',
  ];

  /// Ratings each life gets, 1–5.
  static const odysseyGauges = {
    'resources': 'Resources — do you have what it takes?',
    'like': 'How much you like it',
    'confidence': 'Confidence you could do it',
    'coherence': 'Fits who you are and what you value',
  };

  LogEntry? get odyssey {
    final l = logsOf('odyssey');
    return l.isEmpty ? null : l.first;
  }

  List<Map<String, dynamic>> get odysseyLives {
    final raw = odyssey?.data['lives'] as List? ?? const [];
    return [
      for (var i = 0; i < 3; i++)
        i < raw.length ? Map<String, dynamic>.from(raw[i] as Map) : <String, dynamic>{}
    ];
  }

  /// Saves the three lives, the one leaning towards (or null), and the next
  /// small prototype: a conversation or experience that tests it.
  void saveOdyssey(List<Map<String, dynamic>> lives,
      {int? leaning, String prototype = ''}) {
    final data = {
      'lives': lives.take(3).toList(),
      'leaning': leaning,
      'prototype': prototype.trim(),
    };
    final o = odyssey;
    if (o == null) {
      addLog('odyssey', data: data);
    } else {
      updateLog(o.copyWith(date: dayOnly(_now), data: data));
    }
  }

  /// The life leaned towards, e.g. "Founder in Lisbon".
  String? get odysseyLeaning {
    final i = (odyssey?.number('leaning'))?.toInt();
    if (i == null) return null;
    final t = '${odysseyLives[i]['title'] ?? ''}'.trim();
    return t.isEmpty ? null : t;
  }

  // ── Energy audit (job crafting) ──────────────────────────────────────

  /// The recurring activities of a normal week, each giving or draining
  /// energy (-2…2), and one crafting move: do more of a giving one, less
  /// of a draining one, or reshape it. Job crafting is linked to
  /// engagement and performance (Wrzesniewski & Dutton 2001; Rudolph et
  /// al. 2017) and works the same for home and family.
  static const craftMoves = {
    'more': 'Do more of it',
    'less': 'Do less of it — delegate, drop or batch',
    'reshape': 'Reshape it — change how, when or with whom',
  };

  /// One audit per program quarter; the latest is edited in place.
  LogEntry? get energyAudit {
    for (final l in logsOf('energy_audit')) {
      if (l.number('quarter') == programQuarter) return l;
    }
    return null;
  }

  LogEntry? get latestEnergyAudit {
    final l = logsOf('energy_audit');
    return l.isEmpty ? null : l.first;
  }

  List<({String name, int energy})> auditActivities(LogEntry audit) => [
        for (final a in (audit.data['activities'] as List? ?? const []))
          (name: '${(a as Map)['name']}', energy: (a['energy'] as num? ?? 0).toInt())
      ];

  void saveEnergyAudit(List<({String name, int energy})> activities,
      {String craftActivity = '', String craftMove = '', String craftHow = ''}) {
    final data = {
      'quarter': programQuarter,
      'activities': [
        for (final a in activities)
          if (a.name.trim().isNotEmpty)
            {'name': a.name.trim(), 'energy': a.energy.clamp(-2, 2)}
      ],
      'craft': craftActivity.trim(),
      'move': craftMove,
      'how': craftHow.trim(),
    };
    final e = energyAudit;
    if (e == null) {
      addLog('energy_audit', data: data);
    } else {
      updateLog(e.copyWith(date: dayOnly(_now), data: data));
    }
  }

  /// The crafting move in a line, e.g. "Weekly report: reshape it — …".
  String? get craftingMove {
    final a = latestEnergyAudit;
    if (a == null || (a.str('craft') ?? '').isEmpty) return null;
    final how = a.str('how') ?? '';
    return '${a.str('craft')}: ${(craftMoves[a.str('move')] ?? '').split(' —').first.toLowerCase()}${how.isEmpty ? '' : ' — $how'}';
  }

  // ── Reflected best self ──────────────────────────────────────────────

  /// Stories from people who have seen you at your best, the themes across
  /// them, and a portrait in your words (Roberts et al. 2005). Shown again
  /// on hard days and setbacks.
  static const bestSelfAsk =
      'Could you tell me about a time you saw me at my best — what I did, and why it mattered? A short story is perfect.';

  LogEntry? get bestSelf {
    final l = logsOf('best_self');
    return l.isEmpty ? null : l.first;
  }

  List<({String from, String story})> bestSelfStories() => [
        for (final s in (bestSelf?.data['stories'] as List? ?? const []))
          (from: '${(s as Map)['from']}', story: '${s['story']}')
      ];

  void _saveBestSelf(Map<String, dynamic> patch) {
    final b = bestSelf;
    if (b == null) {
      addLog('best_self', data: {'stories': const [], 'themes': '', 'portrait': '', ...patch});
    } else {
      updateLog(b.copyWith(data: {...b.data, ...patch}));
    }
  }

  void addBestSelfStory(String from, String story) {
    if (story.trim().isEmpty) return;
    _saveBestSelf({
      'stories': [
        for (final s in bestSelfStories()) {'from': s.from, 'story': s.story},
        {'from': from.trim(), 'story': story.trim()},
      ]
    });
  }

  void removeBestSelfStory(int index) {
    final s = bestSelfStories();
    if (index < 0 || index >= s.length) return;
    s.removeAt(index);
    _saveBestSelf({
      'stories': [for (final x in s) {'from': x.from, 'story': x.story}]
    });
  }

  void saveBestSelfPortrait({required String themes, required String portrait}) =>
      _saveBestSelf({'themes': themes.trim(), 'portrait': portrait.trim()});

  /// "When I'm at my best, I…", once written.
  String? get bestSelfPortrait {
    final p = bestSelf?.str('portrait') ?? '';
    return p.isEmpty ? null : p;
  }

  // ── Plan packs ───────────────────────────────────────────────────────

  /// This plan, to pass on: own growth areas, the daily list with cues,
  /// the first goal's shape (no numbers or dates) and the stop list.
  /// Never includes the profile, people or any log.
  PlanPack myPack({String name = 'My plan', bool withGoal = true}) {
    final g = activeGoals.firstOrNull;
    return PlanPack(name,
        areas: customAreas,
        goal: !withGoal || g == null
            ? null
            : PackGoal(g.text,
                obstacle: g.str('obstacle') ?? '', plan: g.str('plan') ?? ''),
        daily: [
          for (final d in dailyItems)
            DailyIdea(d.title, d.lane, d.when, '', cueFor(d.id), minimum: minimumFor(d.id))
        ],
        stops: [for (final s in stopList) s.text]);
  }

  /// Adds a pack to this plan: its areas (skipping names already there),
  /// its goal (if there is room for one more), daily items and stops.
  /// [replaceDaily] retires the current daily list first.
  ({int areas, int items, bool goal}) applyPack(PlanPack pack,
      {bool replaceDaily = false, bool withGoal = true}) {
    var areas = 0;
    for (final a in pack.areas) {
      if (allGrowthAreas.any((x) => x.name.toLowerCase() == a.name.toLowerCase())) continue;
      saveCustomArea(a.copyWith(id: ''));
      areas++;
    }
    var goal = false;
    final g = pack.goal;
    if (withGoal && g != null && g.title.trim().isNotEmpty &&
        !activeGoals.any((x) => x.text == g.title)) {
      final now = _now;
      goal = saveGoal(
              title: g.title,
              obstacle: g.obstacle,
              plan: g.plan,
              deadline: DateTime(now.year, now.month + g.months, now.day)) !=
          null;
    }
    if (replaceDaily && pack.daily.length >= minDailyItems) {
      for (final b in nonNegotiables) {
        setDone('daily:off:${b.id}', true);
      }
      for (final l in logsOf('daily_item')) {
        removeLog(l.id);
      }
    }
    final items = _addIdeas(pack.daily);
    for (final s in pack.stops) {
      if (!stopList.any((x) => x.text == s)) addStop(s);
    }
    _syncReminders();
    return (areas: areas, items: items, goal: goal);
  }

  // ── Goals ────────────────────────────────────────────────────────────

  static const maxActiveGoals = 3;

  /// All goals, newest first. A `goal` log holds the WOOP (title = wish,
  /// why = outcome, obstacle, plan), an identity statement, a deadline,
  /// linked growth areas, and either a number (start → target, unit) or
  /// milestones.
  List<LogEntry> get goals => logsOf('goal');

  List<LogEntry> get activeGoals =>
      [for (final g in goals) if ((g.str('status') ?? 'active') == 'active') g];

  LogEntry? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Creates a goal, or updates [id]'s. Returns the saved entry.
  LogEntry? saveGoal({
    String? id,
    required String title,
    String why = '',
    String obstacle = '',
    String plan = '',
    String identity = '',
    DateTime? deadline,
    List<String> areas = const [],
    String unit = '',
    double? start,
    double? target,
    List<String> milestones = const [],
  }) {
    final existing = id == null ? null : goalById(id);
    if (existing == null && activeGoals.length >= maxActiveGoals) return null;
    final old = existing?.data ?? const {};
    final oldMilestones = (old['milestones'] as List? ?? const [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();
    final data = {
      'why': why.trim(),
      'obstacle': obstacle.trim(),
      'plan': plan.trim(),
      'identity': identity.trim(),
      'deadline': deadline == null ? null : dateKey(deadline),
      'areas': areas,
      'unit': unit.trim(),
      'start': start,
      'target': target,
      'milestones': [
        for (final m in milestones)
          if (m.trim().isNotEmpty)
            {
              'text': m.trim(),
              'done': oldMilestones.any((o) => o['text'] == m.trim() && o['done'] == true),
            }
      ],
      'status': old['status'] ?? 'active',
    };
    if (existing == null) {
      return addLog('goal', text: title.trim(), data: data);
    }
    final next = existing.copyWith(text: title.trim(), data: data);
    updateLog(next);
    return next;
  }

  void setGoalStatus(String id, String status) {
    final g = goalById(id);
    if (g == null) return;
    updateLog(g.copyWith(data: {
      ...g.data,
      'status': status,
      'closed_on': status == 'active' ? null : dateKey(_now),
    }));
  }

  /// Removes a goal and its measurements.
  void deleteGoal(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        logs: s.logs
            .where((l) =>
                l.id != id && !(l.type == 'goal_value' && l.str('goal') == id))
            .toList()));
  }

  bool goalIsNumeric(LogEntry g) =>
      g.number('start') != null && g.number('target') != null;

  /// Measurements of a numeric goal, oldest first.
  List<LogEntry> goalValues(String id) => [
        for (final l in logsOf('goal_value').reversed)
          if (l.str('goal') == id) l
      ];

  void logGoalValue(String id, double value, {DateTime? date}) =>
      addLog('goal_value',
          date: date,
          data: {'goal': id, 'value': value, 'title': goalById(id)?.text ?? ''});

  double? goalCurrent(LogEntry g) {
    final v = goalValues(g.id);
    return v.isEmpty
        ? g.number('start')?.toDouble()
        : v.last.number('value')?.toDouble();
  }

  void toggleMilestone(String id, int i) {
    final g = goalById(id);
    if (g == null) return;
    final ms = (g.data['milestones'] as List? ?? const [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();
    if (i < 0 || i >= ms.length) return;
    ms[i]['done'] = !(ms[i]['done'] == true);
    updateLog(g.copyWith(data: {...g.data, 'milestones': ms}));
  }

  List<({String text, bool done})> milestonesOf(LogEntry g) => [
        for (final m in (g.data['milestones'] as List? ?? const []))
          (text: '${(m as Map)['text']}', done: m['done'] == true)
      ];

  /// 0–1: how far from start to target (numeric) or milestones done.
  double goalProgress(LogEntry g) {
    if (goalIsNumeric(g)) {
      final s = g.number('start')!.toDouble();
      final t = g.number('target')!.toDouble();
      final c = goalCurrent(g) ?? s;
      if (t == s) return c == t ? 1 : 0;
      return ((c - s) / (t - s)).clamp(0.0, 1.0);
    }
    final ms = milestonesOf(g);
    if (ms.isEmpty) return 0;
    return ms.where((m) => m.done).length / ms.length;
  }

  DateTime? goalDeadline(LogEntry g) =>
      DateTime.tryParse(g.str('deadline') ?? '');

  /// Where a straight line from the start date to the deadline would be
  /// today, 0–1; null without a deadline.
  double? goalExpected(LogEntry g) {
    final end = goalDeadline(g);
    if (end == null) return null;
    final from = dayOnly(g.date);
    final total = end.difference(from).inDays;
    if (total <= 0) return 1;
    return (dayOnly(_now).difference(from).inDays / total).clamp(0.0, 1.0);
  }

  /// 'ahead', 'on track', 'behind', or null without a deadline. Within 10
  /// points of the line counts as on track.
  String? goalPace(LogEntry g) {
    final e = goalExpected(g);
    if (e == null) return null;
    final d = goalProgress(g) - e;
    if (d > 0.1) return 'ahead';
    if (d < -0.1) return 'behind';
    return 'on track';
  }

  /// Days since the goal was last measured or a milestone moved (or since
  /// it was set).
  int daysSinceGoalUpdate(LogEntry g) {
    final v = goalValues(g.id);
    final last = v.isEmpty ? g.date : v.last.date;
    return dayOnly(_now).difference(dayOnly(last)).inDays;
  }

  /// Active numeric goals not measured for 14+ days.
  List<LogEntry> get goalsToMeasure => [
        for (final g in activeGoals)
          if (goalIsNumeric(g) && daysSinceGoalUpdate(g) >= 14) g
      ];

  /// One line per active goal for the brief.
  List<String> goalSummaries() => [
        for (final g in activeGoals)
          '${g.text}: ${(goalProgress(g) * 100).round()}% done'
              '${goalExpected(g) == null ? '' : ', ${(goalExpected(g)! * 100).round()}% of the time used (${goalPace(g)})'}'
              '${(g.str('obstacle') ?? '').isEmpty ? '' : '. Obstacle: ${g.str('obstacle')}'}'
              '${(g.str('plan') ?? '').isEmpty ? '' : '. Plan: ${g.str('plan')}'}'
      ];

  // ── Weekly progress note ─────────────────────────────────────────────

  /// Who the note goes to by default: the profile's primary person.
  String get defaultNoteRecipient => activeProfile.manager;

  /// A short weekly update from real data, to send to one person.
  /// Reported progress beats private monitoring (Harkin et al. 2016).
  String progressNoteText(DateTime anyDay, {String to = '', String ask = ''}) {
    final week = weekStartOf(anyDay);
    final end = week.add(const Duration(days: 7));
    final b = StringBuffer()
      ..writeln(to.trim().isEmpty ? 'My week' : 'Hi ${to.trim()} — my week:')
      ..writeln();
    final goals = activeGoals;
    if (goals.isNotEmpty) {
      b.writeln('Goals');
      for (final g in goals) {
        final pace = goalPace(g);
        b.writeln('• ${g.text}: ${(goalProgress(g) * 100).round()}%${pace == null ? '' : ' ($pace)'}');
      }
      b.writeln();
    }
    final (done, set) = weekOutcomeScore(week);
    if (set > 0) {
      b.writeln('This week\'s three: $done of $set done');
      final o = weekOutcomes(week);
      for (var i = 0; i < 3; i++) {
        if (o[i].trim().isEmpty) continue;
        b.writeln('• ${weekOutcomeDone(week, i) ? '✓' : '○'} ${o[i].trim()}');
      }
      b.writeln();
    }
    final area = focusArea();
    if (area != null) {
      final reps = [
        for (final r in logsOf('rep'))
          if (!r.date.isBefore(week) && r.date.isBefore(end)) r
      ];
      b.writeln('Working on: ${area.name} — ${reps.length} practice rep${reps.length == 1 ? '' : 's'} this week');
      final lesson = reps.map((r) => r.str('lesson') ?? '').firstWhere(
          (l) => l.isNotEmpty,
          orElse: () => '');
      if (lesson.isNotEmpty) b.writeln('Learned: $lesson');
      b.writeln();
    }
    final wins = [
      for (final w in logsOf('win'))
        if (!w.date.isBefore(week) && w.date.isBefore(end)) w.text
    ];
    if (wins.isNotEmpty) {
      b.writeln('Wins');
      for (final w in wins.take(3)) {
        b.writeln('• $w');
      }
      b.writeln();
    }
    final header = to.trim().isEmpty ? 'My week' : 'Hi ${to.trim()} — my week:';
    if (b.toString().trim() == header) {
      b.writeln('• What moved this week: …');
      b.writeln();
    }
    if (ask.trim().isNotEmpty) {
      b.writeln('Where you could help: ${ask.trim()}');
    }
    return b.toString().trimRight();
  }

  void logProgressNote(String to, String text) =>
      addLog('progress_note', text: text.trim(), data: {'to': to.trim()});

  bool noteSentInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('progress_note', week, week.add(const Duration(days: 7))) > 0;
  }

  /// Friday to Sunday, with something to report and no note sent yet.
  bool noteDue(DateTime day) =>
      day.weekday >= DateTime.friday &&
      !noteSentInWeek(day) &&
      (activeGoals.isNotEmpty || hasWeekPlan(day));

  // ── Setback protocol ─────────────────────────────────────────────────

  /// After a slip: kindness first, then facts, then the smallest next step
  /// — which becomes today's first open priority. Self-compassion after a
  /// failure raises the motivation to improve (Breines & Chen 2012).
  void logSetback(
      {required String kind,
      required String happened,
      required String nextStep}) {
    final today = dayOnly(_now);
    addLog('setback', text: happened.trim(), data: {
      'kind': kind.trim(),
      'next': nextStep.trim(),
    });
    if (nextStep.trim().isEmpty) return;
    final p = prioritiesFor(today);
    final slot = p.indexWhere((x) => x.trim().isEmpty);
    if (slot >= 0) setPriority(today, slot, nextStep.trim());
  }

  int setbacksInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('setback', week, week.add(const Duration(days: 7)));
  }

  // ── Learning queue ───────────────────────────────────────────────────

  static const learningKinds = ['Book', 'Course', 'Podcast', 'Talk', 'Article'];

  /// Everything he is learning from, newest first. Status: queue → active
  /// → done. Done means applied: one principle in his words and one
  /// experiment in real life (transfer of learning, Baldwin & Ford 1988).
  List<LogEntry> get learning => logsOf('learning');

  List<LogEntry> learningWith(String status) => [
        for (final l in learning)
          if ((l.str('status') ?? 'queue') == status) l
      ];

  LogEntry? learningById(String id) {
    for (final l in learning) {
      if (l.id == id) return l;
    }
    return null;
  }

  LogEntry? addLearning(String title,
          {String kind = 'Book', String by = '', String area = ''}) =>
      title.trim().isEmpty
          ? null
          : addLog('learning', text: title.trim(), data: {
              'kind': kind,
              'by': by.trim(),
              'area': area,
              'status': 'queue',
            });

  void _setLearning(String id, Map<String, dynamic> changes) {
    final l = learningById(id);
    if (l == null) return;
    updateLog(l.copyWith(data: {...l.data, ...changes}));
  }

  void startLearning(String id) =>
      _setLearning(id, {'status': 'active', 'started': dateKey(_now)});

  /// Finishing asks for the principle and the experiment.
  void applyLearning(String id,
          {required String principle, required String experiment}) =>
      _setLearning(id, {
        'status': 'done',
        'principle': principle.trim(),
        'experiment': experiment.trim(),
        'finished': dateKey(_now),
      });

  void recordExperimentResult(String id, String result) =>
      _setLearning(id, {'result': result.trim(), 'result_on': dateKey(_now)});

  void removeLearning(String id) {
    final l = learningById(id);
    if (l != null) removeLog(l.id);
  }

  /// Finished items whose experiment has no result after 7 days.
  List<LogEntry> get experimentsToReview => [
        for (final l in learningWith('done'))
          if ((l.str('experiment') ?? '').isNotEmpty &&
              (l.str('result') ?? '').isEmpty &&
              dayOnly(_now)
                      .difference(DateTime.tryParse(l.str('finished') ?? '') ??
                          dayOnly(_now))
                      .inDays >=
                  7)
            l
      ];

  // ── Recovery planning ────────────────────────────────────────────────

  static const restKinds = {
    'day': 'Rest day',
    'light': 'Lighter week',
    'holiday': 'Holiday',
  };

  /// Planned rest, newest first: kind, from, to, note.
  List<LogEntry> get restPlans => logsOf('rest');

  LogEntry? planRest(String kind, DateTime from, DateTime to,
      {String note = ''}) {
    final a = dayOnly(from), b = dayOnly(to);
    if (b.isBefore(a)) return null;
    return addLog('rest', date: a, text: note.trim(), data: {
      'kind': kind,
      'from': dateKey(a),
      'to': dateKey(b),
    });
  }

  void removeRest(String id) {
    final l = restPlans.where((r) => r.id == id);
    if (l.isNotEmpty) removeLog(l.first.id);
  }

  LogEntry? restOn(DateTime day) {
    final d = dayOnly(day);
    for (final r in restPlans) {
      final from = DateTime.tryParse(r.str('from') ?? '');
      final to = DateTime.tryParse(r.str('to') ?? '');
      if (from == null || to == null) continue;
      if (!d.isBefore(from) && !d.isAfter(to)) return r;
    }
    return null;
  }

  /// A planned rest day or holiday (a lighter week still counts days).
  bool isRestDay(DateTime day) {
    _reindex();
    final d = dayOnly(day);
    return _restIndex
        .any((r) => r.rest && !d.isBefore(r.from) && !d.isAfter(r.to));
  }

  /// Rest planned to start in the next 8 weeks (or running now).
  bool get restPlannedSoon {
    final today = dayOnly(_now);
    final horizon = today.add(const Duration(days: 56));
    return restPlans.any((r) {
      final from = DateTime.tryParse(r.str('from') ?? '');
      final to = DateTime.tryParse(r.str('to') ?? '');
      return from != null && to != null && !to.isBefore(today) && !from.isAfter(horizon);
    });
  }

  /// "Did you switch off from work today?" 1 = no, 2 = partly, 3 = fully.
  void logDetachment(DateTime day, int level) =>
      _upsertDayLog('detach', dayOnly(day), {'level': level});

  int? detachmentOn(DateTime day) {
    final l = logsOn(day, 'detach');
    return l.isEmpty ? null : l.last.number('level')?.toInt();
  }

  // ── Stop-doing list ──────────────────────────────────────────────────

  /// Things given up on purpose, with what each makes room for. Saying
  /// no is how the yeses get time.
  List<LogEntry> get stopList => [
        for (final l in logsOf('stop'))
          if ((l.str('status') ?? 'active') == 'active') l
      ];

  LogEntry? addStop(String what, {String makesRoomFor = ''}) =>
      what.trim().isEmpty
          ? null
          : addLog('stop',
              text: what.trim(),
              data: {'room': makesRoomFor.trim(), 'status': 'active'});

  void retireStop(String id) {
    final l = logsOf('stop').where((x) => x.id == id);
    if (l.isEmpty) return;
    updateLog(l.first.copyWith(data: {...l.first.data, 'status': 'retired'}));
  }

  /// This week's check: held (true) or slipped (false); null = not checked.
  bool? stopHeldInWeek(String id, DateTime anyDay) {
    final key = 'stop:$id:${dateKey(weekStartOf(anyDay))}';
    if (isDone('$key:held')) return true;
    if (isDone('$key:slipped')) return false;
    return null;
  }

  void setStopHeld(String id, DateTime anyDay, bool held) {
    final key = 'stop:$id:${dateKey(weekStartOf(anyDay))}';
    setDone('$key:held', held);
    setDone('$key:slipped', !held);
  }

  // ── Gratitude letters ────────────────────────────────────────────────

  /// Written to someone who changed your life, then delivered — ideally
  /// read aloud (Seligman et al. 2005's "gratitude visit").
  List<LogEntry> get gratitudeLetters => logsOf('gratitude');

  LogEntry? writeGratitude(String to, String text) =>
      to.trim().isEmpty || text.trim().isEmpty
          ? null
          : addLog('gratitude',
              text: text.trim(), data: {'to': to.trim(), 'status': 'written'});

  void deliverGratitude(String id, {String reaction = ''}) {
    final l = gratitudeLetters.where((x) => x.id == id);
    if (l.isEmpty) return;
    updateLog(l.first.copyWith(data: {
      ...l.first.data,
      'status': 'delivered',
      'reaction': reaction.trim(),
      'delivered': dateKey(_now),
    }));
  }

  // ── Role models ──────────────────────────────────────────────────────

  /// People one step ahead: what to learn from each, and one question.
  List<LogEntry> get roleModels => logsOf('role_model');

  LogEntry? addRoleModel(String name, {String learn = '', String question = ''}) =>
      name.trim().isEmpty
          ? null
          : addLog('role_model', text: name.trim(), data: {
              'learn': learn.trim(),
              'question': question.trim(),
            });

  /// Records the answer once the question has been asked.
  void answerRoleModel(String id, String answer) {
    final l = roleModels.where((x) => x.id == id);
    if (l.isEmpty) return;
    updateLog(l.first.copyWith(data: {
      ...l.first.data,
      'answer': answer.trim(),
      'asked': dateKey(_now),
    }));
  }

  void removeRoleModel(String id) {
    final l = roleModels.where((x) => x.id == id);
    if (l.isNotEmpty) removeLog(l.first.id);
  }

  // ── Quarterly 360-lite ───────────────────────────────────────────────

  static const defaultRoundQuestion =
      'What\'s one thing I should keep doing, and one thing I should change?';

  /// One round per program quarter: the same question to up to three
  /// people, their answers, and the theme that repeats (multisource
  /// feedback, London & Smither 1995).
  LogEntry? roundFor(int quarter) {
    for (final l in logsOf('feedback_round')) {
      if (l.number('quarter') == quarter) return l;
    }
    return null;
  }

  LogEntry startRound(List<String> people, {String question = defaultRoundQuestion}) {
    final q = programQuarter;
    final existing = roundFor(q);
    final data = {
      'quarter': q,
      'people': [for (final p in people.take(3)) if (p.trim().isNotEmpty) p.trim()],
      'answers': existing?.data['answers'] ?? const [],
      'themes': existing?.str('themes') ?? '',
    };
    if (existing == null) {
      return addLog('feedback_round', text: question.trim(), data: data)!;
    }
    final next = existing.copyWith(text: question.trim(), data: data);
    updateLog(next);
    return next;
  }

  List<({String from, String said})> roundAnswers(LogEntry round) => [
        for (final a in (round.data['answers'] as List? ?? const []))
          (from: '${(a as Map)['from']}', said: '${a['said']}')
      ];

  void addRoundAnswer(String roundId, String from, String said) {
    final l = logsOf('feedback_round').where((x) => x.id == roundId);
    if (l.isEmpty || said.trim().isEmpty) return;
    final r = l.first;
    final answers = [
      for (final a in roundAnswers(r))
        if (a.from != from.trim()) {'from': a.from, 'said': a.said},
      {'from': from.trim(), 'said': said.trim()},
    ];
    updateLog(r.copyWith(data: {...r.data, 'answers': answers}));
  }

  void setRoundThemes(String roundId, String themes) {
    final l = logsOf('feedback_round').where((x) => x.id == roundId);
    if (l.isEmpty) return;
    updateLog(l.first.copyWith(data: {...l.first.data, 'themes': themes.trim()}));
  }

  /// From day 45 of a quarter until this quarter's round exists.
  bool get roundDue {
    if (!hasStarted || roundFor(programQuarter) != null) return false;
    return dayOnly(_now).difference(quarterStart(programQuarter)).inDays >= 45;
  }

  // ── Personal experiments ─────────────────────────────────────────────

  /// What an experiment can watch, from data already logged.
  static const experimentMeasures = {
    'score': 'Daily score',
    'energy': 'Morning energy',
    'sleep': 'Sleep (h)',
    'mood': 'Mood',
  };

  List<LogEntry> get experiments => logsOf('experiment');

  List<LogEntry> experimentsWith(String status) => [
        for (final e in experiments)
          if ((e.str('status') ?? 'running') == status) e
      ];

  LogEntry? experimentById(String id) {
    for (final e in experiments) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// A small test of a change: [change] for [days] days, watching
  /// [measure]. Personal science beats generic advice.
  LogEntry? startExperiment(
          {required String change,
          required String measure,
          int days = 14,
          String expect = ''}) =>
      change.trim().isEmpty
          ? null
          : addLog('experiment', text: change.trim(), data: {
              'measure': measure,
              'days': days,
              'expect': expect.trim(),
              'start': dateKey(_now),
              'status': 'running',
            });

  DateTime experimentStart(LogEntry e) =>
      DateTime.tryParse(e.str('start') ?? '') ?? dayOnly(e.date);

  int experimentDay(LogEntry e) =>
      dayOnly(_now).difference(experimentStart(e)).inDays + 1;

  bool experimentEnded(LogEntry e) =>
      experimentDay(e) > (e.number('days') ?? 14).toInt();

  double? _measureOn(String measure, DateTime d) => switch (measure) {
        'score' => d.isAfter(dayOnly(_now)) ? null : scoreFor(d).toDouble(),
        'sleep' => sleepHoursFor(d) ?? checkinFor(d)?.number('sleep')?.toDouble(),
        _ => checkinFor(d)?.number(measure)?.toDouble(),
      };

  /// Average of the measure before (the same number of days) and during.
  ({double? before, double? during, int nBefore, int nDuring}) experimentCompare(
      LogEntry e) {
    final start = experimentStart(e);
    final days = (e.number('days') ?? 14).toInt();
    final m = e.str('measure') ?? 'score';
    final today = dayOnly(_now);
    final ranStop = start.add(Duration(days: days));
    List<double> collect(DateTime from, DateTime to) => [
          for (var d = from; d.isBefore(to); d = d.add(const Duration(days: 1)))
            if (!d.isBefore(programStart) && !d.isAfter(today) && (m != 'score' || d.isBefore(today)))
              if (_measureOn(m, d) case final v?) v
        ];
    final before = collect(start.subtract(Duration(days: days)), start);
    final during = collect(start, ranStop.isAfter(today) ? today.add(const Duration(days: 1)) : ranStop);
    double? avg(List<double> v) =>
        v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
    return (
      before: avg(before),
      during: avg(during),
      nBefore: before.length,
      nDuring: during.length,
    );
  }

  /// Keep it (it becomes part of how you live) or drop it, with a note.
  void closeExperiment(String id, {required bool keep, String result = ''}) {
    final e = experimentById(id);
    if (e == null) return;
    updateLog(e.copyWith(data: {
      ...e.data,
      'status': keep ? 'kept' : 'dropped',
      'result': result.trim(),
      'closed': dateKey(_now),
    }));
  }

  /// Running experiments that reached their end and need a decision.
  List<LogEntry> get experimentsToClose =>
      [for (final e in experimentsWith('running')) if (experimentEnded(e)) e];

  // ── Quarterly review ─────────────────────────────────────────────────

  /// 90-day quarters of the program: 1 = days 1–90, … 6 = days 451–540.
  int get programQuarter => hasStarted ? ((programDay - 1) ~/ 90) + 1 : 1;

  DateTime quarterStart(int q) => dateForProgramDay((q - 1) * 90 + 1);

  LogEntry? reviewFor(int quarter) {
    for (final l in logsOf('quarterly_review')) {
      if (l.number('quarter') == quarter) return l;
    }
    return null;
  }

  /// The quarter a review now would close: in the first 7 days of a
  /// quarter that's the previous one; otherwise the current one.
  int get quarterToReview {
    final day = dayOnly(_now).difference(quarterStart(programQuarter)).inDays;
    return day < 7 && programQuarter > 1 ? programQuarter - 1 : programQuarter;
  }

  /// From the last 7 days of a quarter to the first 7 of the next, until
  /// that quarter has a review.
  bool get quarterReviewDue {
    if (!hasStarted) return false;
    final q = quarterToReview;
    if (reviewFor(q) != null) return false;
    final end = quarterStart(q + 1);
    final left = end.difference(dayOnly(_now)).inDays;
    return left <= 7 && left > -7;
  }

  /// Saves the quarter's review: life wheel 1–10, wins, lessons, what
  /// happens to each goal, and the focus for the next quarter.
  void saveQuarterReview(int quarter,
      {required Map<String, int> wheel,
      String wins = '',
      String lessons = '',
      Map<String, String> goalDecisions = const {},
      String nextFocus = ''}) {
    for (final e in goalDecisions.entries) {
      if (e.value == 'drop') setGoalStatus(e.key, 'dropped');
      if (e.value == 'achieved') setGoalStatus(e.key, 'achieved');
    }
    final data = {
      'quarter': quarter,
      'wheel': wheel,
      'wins': wins.trim(),
      'lessons': lessons.trim(),
      'goals': goalDecisions,
      'next': nextFocus.trim(),
    };
    final existing = reviewFor(quarter);
    if (existing == null) {
      addLog('quarterly_review', text: nextFocus.trim(), data: data);
    } else {
      updateLog(existing.copyWith(text: nextFocus.trim(), data: data));
    }
  }

  /// The latest life wheel ratings, or empty.
  Map<String, int> get latestWheel {
    final l = [...logsOf('quarterly_review'), ...logsOf('wheel')]
      ..sort((a, b) => b.date.compareTo(a.date));
    if (l.isEmpty) return const {};
    return (l.first.data['wheel'] as Map? ?? const {})
        .map((k, v) => MapEntry('$k', (v as num).toInt()));
  }

  /// The lowest-rated life area in the latest wheel.
  LifeArea? get lowestLifeArea {
    final w = latestWheel;
    if (w.isEmpty) return null;
    final low = w.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return lifeAreas.where((a) => a.id == low.key).firstOrNull;
  }

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
  /// The built-in person's areas (their job and diagnosis) plus their own;
  /// anyone else has only their own.
  List<GrowthArea> get allGrowthAreas =>
      [if (isBuiltInPerson) ...growthAreas, ...customAreas];

  /// Any area by id; a removed one reads as "Removed area".
  GrowthArea areaById(String id) {
    for (final a in [...allGrowthAreas, ...growthAreas, ...areaTemplates]) {
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
  GrowthArea get suggestedArea {
    if (!isBuiltInPerson) {
      final own = customAreas;
      if (own.isNotEmpty) return own.first;
      return areaById(lowestLifeArea?.template ?? 't_health');
    }
    return readinessGap == null ? growthAreas.first : areaById(readinessGap!.id);
  }

  /// Focuses on [areaId]; a template (`t_…`) first becomes an area of
  /// your own. Returns the id used.
  String focusOn(String areaId, {required int startRating}) {
    var id = areaId;
    if (areaTemplates.any((t) => t.id == areaId)) {
      final t = areaTemplates.firstWhere((t) => t.id == areaId);
      final existing = customAreas.where((a) => a.name == t.name);
      id = existing.isNotEmpty ? existing.first.id : saveCustomArea(t.copyWith(id: '')).id;
    }
    setFocus(id, startRating: startRating);
    return id;
  }

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

  // ── Case for the target role ─────────────────────────────────────────────

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
      ..writeln('${activeProfile.name} — towards ${activeProfile.targetRole}')
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
    final themes = [
      for (final r in logsOf('feedback_round'))
        if ((r.str('themes') ?? '').isNotEmpty) r
    ];
    if (themes.isNotEmpty) {
      b.writeln('WHAT OTHERS SAY');
      for (final r in themes.take(3)) {
        b.writeln('• Quarter ${r.number('quarter')}: ${r.str('themes')}');
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

  /// Contact with someone; [quality] 1 = distracted, 2 = okay, 3 = fully
  /// present. Presence, not just frequency, is what keeps people close.
  void logTouch(LogEntry person, {String note = '', int? quality}) =>
      addLog('touch', text: note.trim(), data: {
        'person': person.id,
        'name': person.text,
        if (quality != null) 'quality': quality,
      });

  /// A ritual with this person ("Friday dinner, phones away"), or ''.
  String ritualOf(LogEntry person) => person.str('ritual') ?? '';

  void setRitual(LogEntry person, String ritual) {
    final p = logsOf('person').where((x) => x.id == person.id);
    if (p.isEmpty) return;
    updateLog(p.first.copyWith(data: {...p.first.data, 'ritual': ritual.trim()}));
  }

  /// Average presence (1–3) over the last 4 rated touches, or null.
  double? presenceOf(LogEntry person) {
    final q = [
      for (final t in logsOf('touch'))
        if (t.str('person') == person.id && t.number('quality') != null)
          t.number('quality')!.toDouble()
    ].take(4).toList();
    return q.isEmpty ? null : q.reduce((a, b) => a + b) / q.length;
  }

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
  LogEntry? logFocus(int minutes, String target) =>
      addLog('focus', data: {'minutes': minutes, 'target': target});

  // ── Energy map ───────────────────────────────────────────────────────

  /// Times of day the map compares (start hour inclusive, end exclusive).
  static const energyBands = [
    (id: 'early', label: 'Early morning', from: 5, to: 9),
    (id: 'morning', label: 'Morning', from: 9, to: 12),
    (id: 'midday', label: 'Midday', from: 12, to: 14),
    (id: 'afternoon', label: 'Afternoon', from: 14, to: 17),
    (id: 'evening', label: 'Evening', from: 17, to: 23),
  ];

  /// Ratings a band needs before it can be called the peak.
  static const minEnergySamples = 3;

  /// "How's your energy right now?", 1–5, at the current hour.
  void logEnergy(int level) =>
      addLog('energy', data: {'level': level.clamp(1, 5), 'hour': _now.hour});

  /// How sharp a focus block felt, 1–5; it counts for the hour it started.
  void rateFocus(String logId, int sharp) {
    final l = logsOf('focus').where((x) => x.id == logId);
    if (l.isEmpty) return;
    updateLog(l.first.copyWith(data: {...l.first.data, 'sharp': sharp.clamp(1, 5)}));
  }

  /// Every rating of the last 60 days as (hour, level): energy pings and
  /// rated focus blocks.
  List<({int hour, int level})> get energySamples {
    final from = dayOnly(_now).subtract(const Duration(days: 60));
    return [
      for (final l in logsOf('energy'))
        if (!l.date.isBefore(from) && l.number('hour') != null && l.number('level') != null)
          (hour: l.number('hour')!.toInt(), level: l.number('level')!.toInt()),
      for (final l in logsOf('focus'))
        if (!l.date.isBefore(from) && l.number('sharp') != null)
          (
            hour: l.createdAt
                .subtract(Duration(minutes: (l.number('minutes') ?? 0).toInt()))
                .hour,
            level: l.number('sharp')!.toInt()
          ),
    ];
  }

  /// Average rating and count per band.
  Map<String, ({double? avg, int n})> get energyMap {
    final samples = energySamples;
    return {
      for (final b in energyBands)
        b.id: () {
          final s = [for (final x in samples) if (x.hour >= b.from && x.hour < b.to) x.level];
          return (avg: s.isEmpty ? null : s.reduce((a, c) => a + c) / s.length, n: s.length);
        }(),
    };
  }

  /// The best-rated band, once at least two bands have enough ratings and
  /// it is ahead of the next by 0.3 or more.
  ({String id, String label, int from, int to})? get energyPeak {
    final map = energyMap;
    final ranked = [
      for (final b in energyBands)
        if (map[b.id]!.n >= minEnergySamples) b
    ]..sort((a, b) => map[b.id]!.avg!.compareTo(map[a.id]!.avg!));
    if (ranked.length < 2) return null;
    if (map[ranked[0].id]!.avg! - map[ranked[1].id]!.avg! < 0.3) return null;
    return ranked.first;
  }

  /// Morning check-in energy by weekday (1 = Monday), last 60 days.
  Map<int, double> get energyByWeekday {
    final from = dayOnly(_now).subtract(const Duration(days: 60));
    final by = <int, List<num>>{};
    for (final l in logsOf('checkin')) {
      final e = l.number('energy');
      if (e == null || l.date.isBefore(from)) continue;
      by.putIfAbsent(l.date.weekday, () => []).add(e);
    }
    return {
      for (final e in by.entries)
        if (e.value.length >= 2) e.key: e.value.reduce((a, b) => a + b) / e.value.length
    };
  }

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
  DateTime get programEnd => dateForProgramDay(programDays);

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

  // ── Your data ────────────────────────────────────────────────────────

  bool get syncsToCloud => _gateway.syncsToCloud;

  /// Whether the Sunday brief is written by the cloud coach (Claude) rather
  /// than on the device.
  bool get coachIsRemote => _briefs is RemoteBriefGenerator;

  /// What is stored, by kind, for the "Your data" screen.
  ({int days, int entries, int health, int reports, int people}) get dataSummary {
    final s = _state;
    if (s == null) return (days: 0, entries: 0, health: 0, reports: 0, people: 0);
    const health = {'weight', 'protein', 'gym', 'blood', 'checkin', 'sleep', 'vitals', 'energy'};
    return (
      days: s.dailyChecks.keys.length,
      entries: s.logs.length,
      health: s.logs.where((l) => health.contains(l.type)).length,
      reports: s.reports.length + s.briefs.length,
      people: s.logs.where((l) => l.type == 'person').length,
    );
  }

  /// Deletes everything — on this device and, with sync on, in the cloud —
  /// cancels every reminder and starts over. Throws if the cloud delete
  /// fails, leaving the data in place.
  Future<void> eraseEverything() async {
    await _gateway.erase(_userId);
    _widgetTimer?.cancel();
    await _reminders?.sync(const []);
    await _reminders?.cancel(restNotificationId);
    await _reminders?.cancel(timerNotificationId);
    for (var i = 0; i < 40; i++) {
      await _reminders?.cancel(onceIdBase + 100 + i);
    }
    _state = await _gateway.load(_userId);
    _applyProfile();
    notifyListeners();
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
      _applyProfile();
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

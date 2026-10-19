import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

import '../data/daily_library.dart';
import '../data/emin_system.dart';
import '../data/general_program.dart';
import '../data/growth_templates.dart';
import '../data/life_wheel.dart';
import '../data/plan_packs.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';
import '../models/state_merge.dart';
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

  /// Whether this device can deliver reminders (not the web app).
  bool get remindersSupported => _reminders?.supported ?? false;
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

  /// The provider's time (the test clock in tests).
  DateTime get now => _now;

  /// Hours after midnight that still belong to the night before.
  static const dayEndsAt = 4;

  /// The day someone is living: before 04:00 it is still last night, so a
  /// shutdown at 00:30 closes the day just ended.
  DateTime get logicalToday {
    final n = _now;
    final d = dayOnly(n);
    return n.hour < dayEndsAt ? d.minusDays(1) : d;
  }

  Future<void>? _loadFuture;
  String? _loadingFor;

  /// Loads [userId]'s program. A second call while the first is still
  /// syncing waits for it, so Today never judges a half-loaded device
  /// (and opens the plan builder over a program on its way).
  Future<void> load(String? userId) {
    final id = userId ?? _fallbackUser;
    final running = _loadFuture;
    if (running != null && _loadingFor == id) return running;
    final f = _load(id);
    _loadFuture = f;
    _loadingFor = id;
    f.whenComplete(() {
      if (identical(_loadFuture, f)) _loadFuture = null;
    });
    return f;
  }

  Future<void> _load(String id) async {
    final again = _signedOut;
    _signedOut = false;
    if (_state != null && id == _userId && !again) return;
    _userId = id;
    _loading = true;
    notifyListeners();
    _state = await _gateway.load(id);
    if (_gateway.syncsToCloud) {
      // A new device gets the program before Today decides whether to
      // show the plan builder; offline it carries on with its own copy.
      // A sync that outlasts the wait still lands: syncNow merges it into
      // whatever the state is by then, never drops it.
      try {
        await syncNow(notify: false).timeout(const Duration(seconds: 8));
      } catch (_) {}
      _syncTimer?.cancel();
      _syncTimer =
          Timer.periodic(const Duration(seconds: 60), (_) => syncNow());
    }
    _applyProfile();
    _loading = false;
    notifyListeners();
    _syncReminders();
  }

  /// Signed out: stop syncing (a sync without a session would read the
  /// missing row as "deleted everywhere"). Signing in again reloads.
  void signedOut() {
    _syncTimer?.cancel();
    _syncSoon?.cancel();
    _syncTimer = null;
    _syncSoon = null;
    _signedOut = true;
    _beforeImport = null;
    // Their reminders and one-off nudges stop with them: the next person
    // to sign in here mustn't get them.
    _widgetTimer?.cancel();
    _reminders?.sync(const []);
    _reminders?.cancel(restNotificationId);
    _reminders?.cancel(timerNotificationId);
    for (var i = 0; i < 40; i++) {
      _reminders?.cancel(onceIdBase + 100 + i);
    }
  }

  bool _signedOut = false;

  void _update(PersonalSystemState next, {bool reschedule = false}) {
    _state = next;
    notifyListeners();
    _gateway.save(_userId, next);
    if (reschedule) _syncReminders();
    _scheduleWidgetPush();
    _scheduleSync();
  }

  // ── Sync between devices ─────────────────────────────────────────────

  Timer? _syncTimer;
  Timer? _syncSoon;

  /// Sync a few seconds after the last change (ticks come in bursts).
  void _scheduleSync() {
    if (_signedOut) return;
    if (!_gateway.syncsToCloud) return;
    _syncSoon?.cancel();
    _syncSoon = Timer(const Duration(seconds: 3), syncNow);
  }

  /// One sync at a time; a request while one is out runs once it ends,
  /// with the state as it is then.
  Future<void>? _syncing;
  bool _syncAgain = false;

  /// Merges this device's state with the cloud copy and takes in what
  /// other devices changed. Edits made while the request was out are kept.
  Future<void> syncNow({bool notify = true}) async {
    if (!_gateway.syncsToCloud || _signedOut) return;
    if (_syncing != null) {
      _syncAgain = true;
      return _syncing;
    }
    final run = _syncOnce(notify: notify);
    _syncing = run;
    try {
      await run;
    } finally {
      _syncing = null;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(syncNow());
      }
    }
  }

  Future<void> _syncOnce({required bool notify}) async {
    final sent = _state;
    final user = _userId;
    if (sent == null) return;
    final PersonalSystemState? synced;
    try {
      synced = await _gateway.sync(user, sent);
    } catch (_) {
      return; // Offline: the next change, resume or minute tries again.
    }
    final current = _state;
    if (synced == null || current == null || user != _userId) return;
    final next = identical(current, sent)
        ? synced
        : PersonalSystemState.fromJson(mergeStateJson(
            sent.toJson(), current.toJson(), synced.toJson()));
    _state = next;
    _gateway.save(_userId, next);
    if (!identical(current, sent)) _scheduleSync();
    _applyProfile();
    if (notify || !_loading) notifyListeners();
    _syncReminders();
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
    _syncTimer?.cancel();
    _syncSoon?.cancel();
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
    final calendar = d.daysSince(programStart) + 1;
    if (calendar < 1) return calendar;
    _reindex();
    return calendar -
        _pausedList
            .where((p) => !p.isBefore(programStart) && p.isBefore(d))
            .length;
  }

  /// The first calendar date of program day [n], skipping paused days.
  DateTime dateForProgramDay(int n) {
    _reindex();
    var date = programStart.plusDays(n - 1);
    for (final p in _pausedList) {
      if (p.isBefore(programStart)) continue;
      if (!p.isAfter(date)) date = date.plusDays(1);
    }
    return date;
  }

  /// Sick days in a row from which the program clock pauses for the whole
  /// illness, so the program's days of practice stay days of practice.
  static const pauseAfterSickDays = 7;

  /// Calendar days the clock skipped for long illness.
  int get pausedDays {
    _reindex();
    return _pausedList.where((p) => !p.isBefore(programStart)).length;
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
  Phase get phase => phaseFor(phaseMonthAt(hasStarted ? programDay : 1));

  // ── Program length and cycles ────────────────────────────────────────

  /// The lengths a program can have (days → label). Months are 30 days,
  /// quarters 90, so every length has whole months and quarters.
  static const programLengths = {
    90: '90 days',
    180: '6 months',
    360: '12 months',
    540: '18 months',
  };

  /// This program's length in days (540 unless the person chose another).
  int get programDays => _state?.programDays ?? 540;
  int get programMonths => programDays ~/ 30;
  int get programQuarters => programDays ~/ 90;
  String get programLengthLabel =>
      programLengths[programDays] ?? '$programDays days';

  /// Which program this is (1 = the first).
  int get cycle => _state?.cycle ?? 1;

  /// The four phases are laid out on 18 months; a shorter program keeps
  /// their proportions. Program day [day] → its month on that 18-month
  /// scale.
  int phaseMonthAt(int day) =>
      (((day.clamp(1, programDays) - 1) * 18) ~/ programDays) + 1;

  /// The phase month [month] of this program starts in.
  Phase phaseOfMonth(int month) => phaseFor(phaseMonthAt((month - 1) * 30 + 1));

  /// This program's months that begin in [p] (may be empty for a short
  /// program, where a phase can start mid-month).
  List<int> monthsOf(Phase p) => [
        for (var m = 1; m <= programMonths; m++)
          if (phaseOfMonth(m).id == p.id) m
      ];

  /// The program days [p] covers, e.g. days 1–10 of a 90-day program.
  ({int from, int to}) phaseDays(Phase p) => (
        from: (p.fromMonth - 1) * programDays ~/ 18 + 1,
        to: p.toMonth * programDays ~/ 18,
      );

  /// "Months 1–2" when the phase covers whole months, else "Days 1–10".
  String phaseSpanLabel(Phase p) {
    final d = phaseDays(p);
    if ((d.from - 1) % 30 == 0 && d.to % 30 == 0) {
      final a = (d.from - 1) ~/ 30 + 1, b = d.to ~/ 30;
      return a == b ? 'Month $a' : 'Months $a–$b';
    }
    return 'Days ${d.from}–${d.to}';
  }

  /// Past the last day: time to look back and start the next program.
  bool get programComplete => hasStarted && programDay > programDays;

  /// Change the length of the running program (the start stays).
  void setProgramLength(int days) {
    final s = _state;
    if (s == null || !programLengths.containsKey(days)) return;
    _update(s.copyWith(programDays: days), reschedule: true);
  }

  /// The program a month- or quarter-keyed log belongs to.
  int cycleOf(LogEntry l) => (l.number('cycle') ?? 1).toInt();

  /// [l] is for month [m] of this program.
  bool atMonth(LogEntry l, int m) =>
      l.number('month') == m && cycleOf(l) == cycle;

  /// [l] is for quarter [q] of this program.
  bool atQuarter(LogEntry l, int q) =>
      l.number('quarter') == q && cycleOf(l) == cycle;

  /// Finished programs, newest first.
  List<LogEntry> get pastPrograms => logsOf('program_cycle');

  /// The first day of the first program; streaks run across programs.
  DateTime get journeyStart {
    var first = programStart;
    for (final c in pastPrograms) {
      final d = DateTime.tryParse(c.str('start') ?? '');
      if (d != null && d.isBefore(first)) first = d;
    }
    return first;
  }

  /// What this program added up to, for the closing review.
  ({int held, int counted, int goalsAchieved, int wins, int reps, int lessons})
      programSummary() {
    final end = programSummaryEnd;
    var held = 0, counted = 0;
    for (var d = programStart; d.isBefore(end); d = d.plusDays(1)) {
      if (isExcused(d)) continue;
      counted++;
      if (isHeld(d)) held++;
    }
    // Only what happened inside the program: opening the look-back three
    // weeks late doesn't add those weeks to it.
    bool inProgram(LogEntry l) =>
        !l.date.isBefore(programStart) && l.date.isBefore(end);
    return (
      held: held,
      counted: counted,
      goalsAchieved: goals
          .where((g) =>
              g.str('status') == 'achieved' &&
              !(DateTime.tryParse(g.str('closed_on') ?? '') ?? g.date)
                  .isBefore(programStart) &&
              (DateTime.tryParse(g.str('closed_on') ?? '') ?? g.date)
                  .isBefore(end))
          .length,
      wins: logsOf('win').where(inProgram).length,
      reps: logsOf('rep').where(inProgram).length,
      lessons: logsOf('rep')
          .where((r) => inProgram(r) && (r.str('lesson') ?? '').isNotEmpty)
          .length,
    );
  }

  /// The day after the program's last day, or today if it is still on.
  DateTime get programSummaryEnd {
    final today = dayOnly(_now);
    final after = programEnd.plusDays(1);
    return after.isBefore(today) ? after : today;
  }

  /// Closes this program with a look back and starts the next from today,
  /// keeping everything logged. [days] picks the next length.
  void startNextProgram({
    int? days,
    String changed = '',
    String carry = '',
  }) {
    final s = _state;
    if (s == null) return;
    final today = dayOnly(_now);
    final sum = programSummary();
    final record = _entry('program_cycle', today, text: changed.trim(), data: {
      'number': cycle,
      'start': dateKey(programStart),
      'end': dateKey(programSummaryEnd.minusDays(1)),
      'days': programDays,
      'held': sum.held,
      'counted': sum.counted,
      'goals_achieved': sum.goalsAchieved,
      'wins': sum.wins,
      'reps': sum.reps,
      'carry': carry.trim(),
    });
    final next = days != null && programLengths.containsKey(days) ? days : programDays;
    _update(
        s.copyWith(
          programStart: today,
          programDays: next,
          cycle: cycle + 1,
          logs: [...s.logs, record],
        ),
        reschedule: true);
  }

  /// Day within the current month (1–30).
  int get dayOfMonth => !hasStarted
      ? 0
      : programComplete
          ? 30
          : ((programDay - 1) % 30) + 1;

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
      final d = dayOnly(from).plusDays(i);
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
    if (key == dateKey(_now)) _resyncIfHeldChanged();
  }

  void toggleCheck(DateTime date, String id) =>
      setCheck(date, id, !isChecked(date, id));

  // ── Daily items (configurable) ───────────────────────────────────────

  /// Today's daily items: the profile's built-in ones he hasn't retired,
  /// then the ones he added. Every score, streak and check reads this.
  // The daily list and the streak are read many times per frame and for
  // every day of the program, so they are computed once per state.
  PersonalSystemState? _dailyState;
  List<NonNegotiable> _dailyCache = const [];
  Set<String> _dailyIds = const {};

  List<NonNegotiable> get dailyItems {
    if (!identical(_dailyState, _state)) {
      _dailyState = _state;
      _dailyCache = [
        for (final n in nonNegotiables)
          if (!isDone('daily:off:${n.id}')) n,
        ...customDailyItems,
      ];
      _dailyIds = {for (final n in _dailyCache) n.id};
    }
    return _dailyCache;
  }

  List<NonNegotiable> get customDailyItems => [
        for (final n in _allCustomItems)
          if (!isDone('daily:off:${n.id}')) n
      ];

  /// Their own items, retired ones too: retiring keeps the item, its cue
  /// and its history, so it can come back.
  List<NonNegotiable> get _allCustomItems => [
        for (final l in logsOf('daily_item').reversed)
          NonNegotiable(l.str('id') ?? l.id, l.text, l.str('lane') ?? 'mind',
              l.str('when') ?? 'day',
              // A routine opens its step-through; a plain item is a tick.
              route: (l.data['steps'] as List? ?? const []).isEmpty
                  ? null
                  : '/routine?id=${l.str('id') ?? l.id}')
      ];

  /// A routine's steps (own items only), or empty.
  List<String> stepsOf(String id) {
    final l = logsOf('daily_item').where((x) => (x.str('id') ?? x.id) == id).firstOrNull;
    return [for (final s in (l?.data['steps'] as List? ?? const [])) '$s'];
  }

  /// Turns an own item into a routine (or back into a tick with none).
  void setSteps(String id, List<String> steps) {
    final l = logsOf('daily_item').where((x) => (x.str('id') ?? x.id) == id).firstOrNull;
    if (l == null) return;
    final clean = [for (final s in steps) if (s.trim().isNotEmpty) s.trim()].take(12).toList();
    final data = {...l.data};
    if (clean.isEmpty) {
      data.remove('steps');
    } else {
      data['steps'] = clean;
    }
    updateLog(l.copyWith(data: data));
  }

  /// Their own items they retired, to bring back on /daily.
  List<NonNegotiable> get retiredCustomItems => [
        for (final n in _allCustomItems)
          if (isDone('daily:off:${n.id}')) n
      ];

  int get dailyCount => dailyItems.length;

  /// Holding the day = 70% of the items (7 of 10), at least 1.
  int get holdTarget => dailyCount == 0 ? 1 : (dailyCount * 0.7).ceil();

  bool isHeld(DateTime date) => scoreFor(date) >= targetFor(date);

  /// What holds [date]: the usual 70%, or half on a minimum day — of the
  /// list as it was that day.
  int targetFor(DateTime date) {
    final n = itemIdsOn(date).length;
    if (n == 0) return 1;
    return isMinimumDay(date) ? (n / 2).ceil() : (n * 0.7).ceil();
  }

  // ── The daily list over time ─────────────────────────────────────────

  // Changing the list must not rewrite the past: adding an eleventh item
  // would otherwise turn every 7-of-10 day into a 7-of-11 miss. Each
  // change saves a `daily_list` snapshot (ids) dated the day it happened;
  // a day is scored against the list in effect on it.
  PersonalSystemState? _listState;
  List<(String, Set<String>)> _listHistory = const [];

  List<(String, Set<String>)> get _snapshots {
    if (!identical(_listState, _state)) {
      _listState = _state;
      // Oldest first.
      _listHistory = [
        for (final l in logsOf('daily_list').reversed)
          (dateKey(l.date), {for (final i in (l.data['ids'] as List? ?? const [])) '$i'})
      ];
    }
    return _listHistory;
  }

  /// The ids of the daily items in effect on [date].
  /// The items as they were on [date] (today: the current list), in the
  /// list's order — what a past day is scored on.
  List<NonNegotiable> itemsOn(DateTime date) {
    final ids = itemIdsOn(date);
    return [
      for (final n in dailyItems)
        if (ids.contains(n.id)) n,
      for (final id in ids)
        if (!_dailyIds.contains(id))
          if (dailyItem(id) case final n?) n,
    ];
  }

  Set<String> itemIdsOn(DateTime date) {
    dailyItems;
    final s = _snapshots;
    final k = dateKey(date);
    // Today and later always use the list as it is now — merged from every
    // device, whatever order their snapshots arrived in.
    if (s.isEmpty || k.compareTo(dateKey(_now)) >= 0) return _dailyIds;
    Set<String>? found;
    for (final (d, ids) in s) {
      if (d.compareTo(k) > 0) break;
      found = ids;
    }
    // Days before the first change used the first list on record.
    return found ?? s.first.$2;
  }

  /// Runs [change] to the daily list and records the list it leaves, so
  /// earlier days keep the list they had.
  T _changingList<T>(T Function() change) {
    final before = {for (final n in dailyItems) n.id};
    final out = change();
    final after = {for (final n in dailyItems) n.id};
    if (before.length == after.length && before.containsAll(after)) return out;
    if (logsOf('daily_list').isEmpty) {
      final yesterday = dayOnly(_now).minusDays(1);
      final first = journeyStart.isBefore(yesterday) ? dayOnly(journeyStart) : yesterday;
      addLog('daily_list', date: first, data: {'ids': before.toList()});
    }
    _upsertDayLog('daily_list', dayOnly(_now), {'ids': after.toList()});
    return out;
  }

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
    final prev = d.minusDays(1);
    if (prev.isBefore(dayOnly(journeyStart))) return false;
    if (hardDayOn(prev) == 'sick') return true;
    if (isExcused(prev) && isExcused(prev.minusDays(1))) return true;
    // Back after two or more days with nothing ticked: start small, not
    // with a warning.
    final before = prev.minusDays(1);
    if (before.isBefore(dayOnly(journeyStart))) return false;
    // Only someone who had started and then stopped is coming back.
    final first = firstTickDay;
    if (first == null || !first.isBefore(before)) return false;
    bool blank(DateTime x) => !isExcused(x) && !isPaused(x) && scoreFor(x) == 0;
    return blank(prev) && blank(before);
  }

  PersonalSystemState? _firstTickState;
  DateTime? _firstTick;

  /// The first day anything was ticked, or null (cached per state).
  DateTime? get firstTickDay {
    if (identical(_firstTickState, _state)) return _firstTick;
    _firstTickState = _state;
    String? min;
    for (final e in (_state?.dailyChecks ?? const <String, List<String>>{}).entries) {
      if (e.value.isNotEmpty && (min == null || e.key.compareTo(min) < 0)) min = e.key;
    }
    return _firstTick = min == null ? null : DateTime.tryParse(min);
  }

  bool isMinimumDay(DateTime day) =>
      hardDayOn(day) == 'minimum' || isReentryDay(day);

  /// Sick days in a row up to [day].
  int sickDaysInRow(DateTime day) {
    var n = 0;
    for (var d = dayOnly(day); hardDayOn(d) == 'sick'; d = d.minusDays(1)) {
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
    _changingList(() => setDone('daily:off:$id', !active));
    _syncReminders();
    return true;
  }

  /// Adds an item of his own, with an if–then cue.
  NonNegotiable? addDailyItem(String title,
      {required String lane, required String when, String cue = ''}) {
    if (title.trim().isEmpty || dailyCount >= maxDailyItems) return null;
    final id = 'd_${_uid()}';
    _changingList(() => addLog('daily_item',
        text: title.trim(), data: {'id': id, 'lane': lane, 'when': when}));
    if (cue.trim().isNotEmpty) setCue(id, cue.trim());
    return dailyItems.firstWhere((n) => n.id == id);
  }

  bool removeDailyItem(String id) {
    if (dailyCount <= minDailyItems) return false;
    final l = logsOf('daily_item').where((x) => x.str('id') == id);
    if (l.isEmpty) return false;
    _changingList(() => removeLog(l.first.id));
    return true;
  }

  NonNegotiable? dailyItem(String id) {
    for (final n in [...nonNegotiables, ..._allCustomItems]) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// [date]'s score on a 0–10 scale, whatever the list's length — what
  /// the heat colours and week bars draw.
  /// Share of the day's list ticked, on 0–10 unrounded: days with a
  /// longer or shorter list compare fairly.
  double scoreShare10(DateTime date) {
    final n = itemIdsOn(date).length;
    return n == 0 ? 0 : scoreFor(date) * 10 / n;
  }

  int scoreOutOf10(DateTime date) {
    final n = itemIdsOn(date).length;
    return n == 0 ? 0 : (scoreFor(date) * 10 / n).round().clamp(0, 10);
  }

  int scoreFor(DateTime date) {
    final ids = itemIdsOn(date);
    return _checks(date).where(ids.contains).length;
  }

  bool gymDone(DateTime date) => isChecked(date, _gymId);
  void toggleGym(DateTime date) => toggleCheck(date, _gymId);

  List<DateTime> weekDays(DateTime anyDay) {
    final start = weekStartOf(anyDay);
    return List.generate(7, (i) => start.plusDays(i));
  }

  /// Average Daily 10 over the days of that week that have passed and fall
  /// inside the program.
  double weekAverage(DateTime anyDay) {
    final now = _now;
    // Sick days, skips, rest and paused days aren't failures: left out.
    final days = weekDays(anyDay)
        .where((d) =>
            !d.isAfter(now) &&
            !d.isBefore(programStart) &&
            !isExcused(d) &&
            !isRestDay(d) &&
            !isPaused(d))
        .toList();
    if (days.isEmpty) return 0;
    return days.fold<int>(0, (sum, d) => sum + scoreFor(d)) / days.length;
  }

  int gymSessionsInWeek(DateTime anyDay) =>
      weekDays(anyDay).where(gymDone).length;

  /// Never miss twice: one day under 7 is forgiven, as long as the next
  /// day is held (or is today, still open) and no other day was forgiven in
  /// the 6 days before it. Two misses in a row end the streak.
  PersonalSystemState? _streakState;
  String _streakDay = '';
  ({int current, int best, bool pending}) _streakCache = (current: 0, best: 0, pending: false);

  ({int current, int best, bool pending}) get _streaks {
    final key = dateKey(logicalToday);
    if (identical(_streakState, _state) && _streakDay == key) return _streakCache;
    _streakState = _state;
    _streakDay = key;
    return _streakCache = _computeStreaks();
  }

  ({int current, int best, bool pending}) _computeStreaks() {
    // Before 04:00 the open day is still last night's.
    final today = logicalToday;
    var run = 0, best = 0;
    var prevMiss = false;
    DateTime? grace;
    for (var d = journeyStart;
        !d.isAfter(today);
        d = d.plusDays(1)) {
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
          (grace == null || d.daysSince(grace) >= 7)) {
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
    final today = logicalToday;
    final yesterday = today.minusDays(1);
    if (yesterday.isBefore(programStart)) return false;
    return !isHeld(yesterday) &&
        !isExcused(yesterday) &&
        !isHeld(today) &&
        !isExcused(today) &&
        // After a real lapse Today says "Welcome back" instead.
        !isReentryDay(today);
  }

  /// Days held in the current program month.
  int get daysHeldThisMonth => statsForMonth(programMonth).daysHeld;

  /// Days held (7+/10) since the program started.
  int get daysHeld {
    var n = 0;
    for (var d = programStart;
        !d.isAfter(dayOnly(_now));
        d = d.plusDays(1)) {
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

  /// One true line about the last 30 days, from what was ticked: days
  /// held of those counted, the steadiest item and the one that slips
  /// most. Null until 7 days count.
  String? get latelyLine {
    final today = dayOnly(_now);
    final days = [
      for (var i = 1; i <= 30; i++)
        if (!today.minusDays(i).isBefore(journeyStart)) today.minusDays(i)
    ];
    final counted = [for (final d in days) if (!isExcused(d) && !isPaused(d)) d];
    if (counted.length < 7) return null;
    final held = counted.where(isHeld).length;
    final rates = itemRates(counted).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    String name(String id) =>
        dailyItems.where((n) => n.id == id).firstOrNull?.title ?? id;
    final top = rates.firstOrNull, low = rates.lastOrNull;
    return [
      'Lately: held $held of ${counted.length}',
      if (top != null && top.value >= 0.6)
        'steadiest: ${name(top.key)} (${(top.value * 100).round()}%)',
      if (low != null && low.key != top?.key && low.value < 0.6)
        'slips most: ${name(low.key)} (${(low.value * 100).round()}%)',
    ].join(' · ');
  }

  // ── Fresh starts ─────────────────────────────────────────────────────

  /// The temporal landmark that [day] is, if any: a new phase, a new month,
  /// or a Monday. Dismissed with `setDone(fs.key, true)`.
  FreshStart? freshStartFor(DateTime day) {
    if (!hasStarted || programDay < 2) return null;
    final d = dayOnly(day);
    final month = programMonth;
    if (dayOfMonth == 1 && month > 1) {
      final phase = phaseOfMonth(month);
      final theme = isBuiltInPerson ? monthThemes[month] ?? '' : '';
      if (phaseOfMonth(month - 1).id != phase.id) {
        return FreshStart(
          key: 'fresh:phase:${phase.id}${cycle > 1 ? ':$cycle' : ''}',
          eyebrow: 'Phase · ${phaseSpanLabel(phase).toLowerCase()}',
          title: '${phase.name} begins',
          body: isBuiltInPerson
              ? '${phase.promise}\n\nMonth $month: $theme'
              : generalPhasePromises[phase.id] ?? phase.promise,
          cta: isBuiltInPerson ? 'Open month $month' : 'Choose this month\'s area',
          route: isBuiltInPerson ? '/month/$month' : '/growth',
        );
      }
      return FreshStart(
        key: 'fresh:month:$month${cycle > 1 ? ':$cycle' : ''}',
        eyebrow: 'Month $month begins',
        title: isBuiltInPerson ? theme : 'A fresh month',
        body: [
          isBuiltInPerson
              ? 'Artifact of the month: ${artifactFor(month)}.'
              : 'A clean page. Pick the one area you\'ll grow this month.',
          // What they decided to carry, in their words, three days ago.
          if (lastCarry case final c?) 'You said you\'d carry: "$c".',
        ].join('\n\n'),
        cta: isBuiltInPerson ? 'Open month $month' : 'Choose this month\'s area',
        route: isBuiltInPerson ? '/month/$month' : '/growth',
      );
    }
    if (d.weekday == DateTime.monday) {
      final lastWeek = weekDays(d.minusDays(7))
          .where((x) => !x.isBefore(programStart))
          .toList();
      if (lastWeek.length < 3) return null;
      final rates = itemRates(lastWeek).entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final weakest = dailyItem(rates.first.key)!;
      // Rates leave excused days out; count against the days that counted.
      final counted = lastWeek.where((x) => !isExcused(x)).length;
      if (counted == 0) return null;
      final hits = (rates.first.value * counted).round();
      final cue = cueFor(weakest.id).trim().replaceFirst(RegExp(r'\.$'), '');
      return FreshStart(
        key: 'fresh:week:${dateKey(d)}',
        eyebrow: 'New week · week $programWeek',
        title: 'One commitment: ${weakest.title.toLowerCase()}',
        body: 'Last week: $hits of $counted days.\n'
            '${cue.isEmpty ? '' : 'Your plan: $cue.\n'}\n'
            'Close your eyes for 20 seconds and picture the moment the cue '
            'happens and you do it.'
            '${ruleOfTheWeek(d) == null ? '' : '\n\nA rule you wrote: "${ruleOfTheWeek(d)}"'}',
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

  /// Words for a feeling, by how pleasant and how energetic (the mood
  /// meter): naming a feeling precisely calms it (Lieberman et al. 2007).
  static const feelingWords = {
    'Unpleasant, high energy': ['Stressed', 'Anxious', 'Frustrated', 'Angry'],
    'Unpleasant, low energy': ['Tired', 'Sad', 'Lonely', 'Drained'],
    'Pleasant, high energy': ['Excited', 'Energised', 'Proud', 'Hopeful'],
    'Pleasant, low energy': ['Calm', 'Content', 'Grateful', 'Relaxed'],
  };

  static const maxFeelings = 2;

  /// One check-in per day; saving again replaces it. [feelings] are up to
  /// [maxFeelings] words, optional.
  void saveCheckin(DateTime date,
      {required int energy,
      required int mood,
      required double sleep,
      required int pain,
      required int stiffness,
      List<String> feelings = const []}) {
    final data = {
      'energy': energy,
      'mood': mood,
      'sleep': sleep,
      'pain': pain,
      'stiffness': stiffness,
      if (feelings.isNotEmpty) 'feelings': feelings.take(maxFeelings).toList(),
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
    if (dateKey(date) == dateKey(_now)) _syncReminders();
  }

  /// The feeling words named in check-ins over the last [days], most
  /// named first.
  List<(String, int)> feelingsNamed({int days = 30}) {
    final from = dayOnly(_now).minusDays(days - 1);
    final count = <String, int>{};
    for (final c in logsOf('checkin')) {
      if (c.date.isBefore(from)) continue;
      for (final f in (c.data['feelings'] as List? ?? const [])) {
        count['$f'] = (count['$f'] ?? 0) + 1;
      }
    }
    return [for (final e in count.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
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
      if (shoulderFlag(dayOnly(date).minusDays(i))) n++;
    }
    return n;
  }

  /// Check-ins in the [days] days ending [date], oldest first.
  List<LogEntry> checkinsEnding(DateTime date, int days) {
    final out = <LogEntry>[];
    for (var i = days - 1; i >= 0; i--) {
      final c = checkinFor(dayOnly(date).minusDays(i));
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
        for (final c in _allCardsUnfiltered)
          if (!isDone('card:off:${c.id}')) c
      ];

  static String _clip(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n - 1).trimRight()}…';

  /// Stops a generated card from coming back; its source stays.
  void retireCard(String id) => setDone('card:off:$id', true);

  List<StudyCard> get _allCardsUnfiltered => [
        if (isBuiltInPerson) ...seedCards,
        for (final r in logsOf('rep').reversed)
          if ((r.str('lesson') ?? '').trim().isNotEmpty)
            StudyCard(
              'lesson:${r.id}',
              'What did you learn from: ${r.str('drill') ?? 'a practice rep'}'
                  '${r.text.trim().isEmpty ? '' : ' — when you ${_clip(r.text.trim(), 70)}'}?',
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
        for (final g in goals)
          if (g.str('status') == 'achieved' && (g.str('reflection') ?? '').isNotEmpty)
            StudyCard(
              'goal:${g.id}',
              'What made "${g.text}" happen?',
              '${g.str('reflection')}${(g.str('advice') ?? '').isEmpty ? '' : '\n\nTo someone starting: ${g.str('advice')}'}',
              source: 'goal',
            ),
        for (final a in logsOf('aar').reversed)
          if ((a.str('improve') ?? '').trim().isNotEmpty)
            StudyCard(
              'aar:${a.id}',
              'Next time — ${a.text}: what will you do differently?',
              '${a.str('improve')!.trim()}${(a.str('friend') ?? '').trim().isEmpty ? '' : '\n\nWhat you\'d tell a friend: ${a.str('friend')!.trim()}'}',
              source: 'aar',
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
                  '${(n.str('chapter') ?? '').isEmpty ? ' (your note of ${dateKey(n.date)})' : ' — ${n.str('chapter')}'}',
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
    // What you wrote in the last two days comes first: the first retrieval
    // soon after learning matters most.
    final recentIds = {
      for (final l in _state?.logs ?? const <LogEntry>[])
        if (!dayOnly(l.date).isBefore(d.minusDays(2))) l.id
    };
    bool recent(StudyCard c) {
      final i = c.id.indexOf(':');
      return i > 0 && recentIds.contains(c.id.substring(i + 1));
    }
    fresh.sort((a, b) => (recent(b) ? 1 : 0) - (recent(a) ? 1 : 0));
    final introducedToday = schedules.values
        .where((s) => dateKey(s.firstSeen) == dateKey(d))
        .length;
    final room = (newCardsPerDay - introducedToday).clamp(0, newCardsPerDay);
    return [..._interleave(due), ...fresh.take(room)];
  }

  /// Mixes cards from different sources (lessons, books, values…) in turn,
  /// most overdue first within each: mixing categories helps them stick
  /// (interleaving, Brunmair & Richter 2019).
  static List<StudyCard> _interleave(List<StudyCard> cards) {
    final bySource = <String, List<StudyCard>>{};
    for (final c in cards) {
      bySource.putIfAbsent(c.source, () => []).add(c);
    }
    final queues = bySource.values.toList();
    final out = <StudyCard>[];
    for (var i = 0; out.length < cards.length; i++) {
      for (final q in queues) {
        if (i < q.length) out.add(q[i]);
      }
    }
    return out;
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
        'custom:${_uid()}', front.trim(), back.trim(),
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
      'review_on': dateKey(dayOnly(_now).plusDays(reviewInDays)),
    });
  }

  /// A decision weighed against your values: each option scored −1/0/+1 per
  /// value, the 10/10/10 view and a premortem; saved to the decision
  /// journal and reviewed after [reviewInDays].
  void addValuesDecision({
    required String question,
    required String chosen,
    required Map<String, Map<String, int>> scores,
    String tenTenTen = '',
    String premortem = '',
    int reviewInDays = 90,
  }) {
    String total(String o) =>
        '${(scores[o]?.values.fold<int>(0, (a, b) => a + b) ?? 0)}';
    addDecision(
      decision: '${question.trim()} → ${chosen.trim()}',
      options: [for (final o in scores.keys) '$o (${total(o)})'].join(' · '),
      why: [
        if (tenTenTen.trim().isNotEmpty) '10/10/10: ${tenTenTen.trim()}',
        'Values: ${[for (final e in (scores[chosen] ?? const <String, int>{}).entries) '${e.key} ${e.value > 0 ? '+' : e.value < 0 ? '−' : '·'}'].join(', ')}',
      ].join('\n'),
      expected: premortem.trim().isEmpty ? '' : 'Premortem: ${premortem.trim()}',
      reviewInDays: reviewInDays,
    );
  }

  /// Self-distanced reflection (Kross et al. 2014): the situation, the
  /// feeling and the advice, written about yourself by name; and how much
  /// it will matter in a year (temporal distance).
  void logStepBack({required String what, String feeling = '', String advice = '', int? mattersInAYear}) {
    if (what.trim().isEmpty) return;
    addLog('stepback', text: what.trim(), data: {
      'feeling': feeling.trim(),
      'advice': advice.trim(),
      'year': mattersInAYear,
    });
  }

  /// A self-compassion break (Neff): what's hard, that others feel it
  /// too, and the kind words you'd give a friend. [heavyBefore] and
  /// [heavyAfter] (1–5) are optional: how heavy it felt.
  LogEntry? logCompassion({required String hard, String kindWords = '', int? heavyBefore, int? heavyAfter}) =>
      hard.trim().isEmpty
          ? null
          : addLog('compassion', text: hard.trim(), data: {
              'kind': kindWords.trim(),
              'before': heavyBefore,
              'after': heavyAfter,
            });

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
        .where((l) => atMonth(l, programMonth))
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
      !logsOf('readiness').any((l) => atMonth(l, programMonth));

  // ── Automaticity ─────────────────────────────────────────────────────

  /// Monthly self-rating per Daily 10 item: "I do it without thinking"
  /// 1 (not at all) – 5 (completely).
  void saveAutomaticity(Map<String, int> ratings) {
    final existing = logsOf('automaticity')
        .where((l) => atMonth(l, programMonth))
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
      for (var i = 1; i <= 30; i++) today.minusDays(i)
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
      !logsOf('automaticity').any((l) => atMonth(l, programMonth));

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
        final morning = today.minusDays(i);
        final night = await _health.sleepEndingOn(morning);
        if (night != null && night.asleepHours > 0) {
          _upsertDayLog('sleep', morning, {
            'asleep_h': double.parse(night.asleepHours.toStringAsFixed(1)),
            'bed_start': night.bedStart.toIso8601String(),
            'wake': night.wake.toIso8601String(),
          });
          final evening = dayOnly(night.bedStart);
          final cutoff = DateTime(evening.year, evening.month, evening.day, 22, 45);
          if (dailyItems.any((i) => i.id == 'bed') &&
              evening.isBefore(morning) &&
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

  // ── Steady sleep ─────────────────────────────────────────────────────

  /// Wake times (minutes after midnight) this week, from Apple Health.
  List<int> wakeTimesInWeek(DateTime anyDay) => [
        for (final d in weekDays(anyDay))
          for (final l in logsOn(d, 'sleep'))
            if (DateTime.tryParse(l.str('wake') ?? '') case final w?) w.hour * 60 + w.minute
      ];

  /// Minutes between the earliest and latest wake this week (3+ nights
  /// measured). Regular sleep matters as much as long sleep (Windred et
  /// al. 2024) — a real measure, never an invented score.
  int? wakeSpread(DateTime anyDay) {
    final w = wakeTimesInWeek(anyDay);
    if (w.length < 3) return null;
    w.sort();
    return w.last - w.first;
  }

  /// Sleep rules to adopt as daily items, each with its cue. Behavioural
  /// parts of CBT-I that are safe without a clinician; never limits on
  /// time in bed.
  List<DailyIdea> get sleepRules {
    final bed = dayShape?.bed;
    final caffeine = bed == null ? null : ((bed - 8 * 60) % (24 * 60));
    String clock(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    return [
      DailyIdea('Same wake time every day, weekends too', 'body', 'morning', 'health',
          dayShape == null
              ? 'When my alarm rings, I get up — the same time all seven days.'
              : 'When my ${clock(dayShape!.wake)} alarm rings, I get up — all seven days.',
          minimum: 'Up within 30 minutes of it'),
      const DailyIdea('Bed is for sleep: up if awake 20 minutes', 'body', 'evening', 'health',
          'When I\'ve been awake in bed for about 20 minutes, I get up and read in dim light until sleepy.',
          minimum: 'No phone in bed'),
      DailyIdea('No caffeine 8 hours before bed', 'body', 'day', 'health',
          caffeine == null
              ? 'When it\'s 8 hours before my bedtime, I switch to water or herbal tea.'
              : 'When it\'s ${clock(caffeine)}, I switch to water or herbal tea.',
          minimum: 'Nothing after mid-afternoon'),
    ];
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

  bool isDone(String key) => _state?.done.contains(_cycled(key)) ?? false;

  /// Month milestones (`ms_…`) are ticked again in each new program.
  String _cycled(String key) =>
      cycle > 1 && key.startsWith('ms_') ? '$key@$cycle' : key;

  void setDone(String key, bool value) {
    final s = _state;
    if (s == null || isDone(key) == value) return;
    final next = Set<String>.from(s.done);
    value ? next.add(_cycled(key)) : next.remove(_cycled(key));
    _update(s.copyWith(done: next));
  }

  void toggleDone(String key) => setDone(key, !isDone(key));

  int doneCount(Iterable<String> keys) => keys.where(isDone).length;

  // ── Logs ─────────────────────────────────────────────────────────────

  int _seq = 0;
  static final _random = Random();

  /// A new id: time, a counter and a random part, so two devices (or a web
  /// clock with millisecond precision) never hand out the same one.
  String _uid() =>
      '${_now.microsecondsSinceEpoch}_${_seq++}_${_random.nextInt(0x7fffffff).toRadixString(36)}';
  LogEntry _entry(String type, DateTime date,
          {String text = '', Map<String, dynamic> data = const {}}) =>
      LogEntry(
        id: '${type}_${_uid()}',
        type: type,
        date: dayOnly(date),
        createdAt: _now,
        text: text,
        // Month- and quarter-keyed logs carry the program they belong to,
        // so month 1 of the next program isn't month 1 of this one.
        data: cycle > 1 &&
                !data.containsKey('cycle') &&
                (data.containsKey('month') || data.containsKey('quarter'))
            ? {...data, 'cycle': cycle}
            : data,
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
    final old = s.logs.where((l) => l.id == entry.id).firstOrNull;
    if (old != null &&
        old.data.containsKey('cycle') &&
        !entry.data.containsKey('cycle')) {
      entry = entry.copyWith(data: {...entry.data, 'cycle': old.data['cycle']});
    }
    _update(s.copyWith(
        logs: [for (final l in s.logs) l.id == entry.id ? entry : l]));
  }

  void removeLog(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(logs: s.logs.where((l) => l.id != id).toList()));
  }

  /// Puts back an entry just removed (Undo); its id and date are kept.
  void restoreLog(LogEntry entry) {
    final s = _state;
    if (s == null || s.logs.any((l) => l.id == entry.id)) return;
    _update(s.copyWith(logs: [...s.logs, entry]));
  }

  /// Changes an entry's text, keeping its day, time and data.
  void editLogText(String id, String text) {
    final l = _state?.logs.where((x) => x.id == id).firstOrNull;
    if (l == null || text.trim().isEmpty) return;
    updateLog(l.copyWith(text: text.trim()));
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

  List<LogEntry> logsOn(DateTime date, [String? type]) {
    final day = _logsByDay[dateKey(date)] ?? const <LogEntry>[];
    return [
      for (final l in day)
        if (type == null || l.type == type) l
    ];
  }

  /// Logs by the day they are for, in entry order — rebuilt only when the
  /// state changes, because Today, patterns and the streak ask day by day.
  PersonalSystemState? _byDayState;
  Map<String, List<LogEntry>> _byDay = const {};
  Map<String, List<LogEntry>> get _logsByDay {
    if (identical(_byDayState, _state)) return _byDay;
    _byDayState = _state;
    final m = <String, List<LogEntry>>{};
    for (final l in _state?.logs ?? const <LogEntry>[]) {
      (m[dateKey(l.date)] ??= []).add(l);
    }
    return _byDay = m;
  }

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
    if (type == 'evidence') return evidenceAdded;
    return countOf(type);
  }

  String masteryOf(String protocolId) => masteryFor(usesOf(protocolId));

  /// Sessions in this program: the four-session protocol starts again
  /// with each new program.
  int get pennebakerSessions => logsOf('pennebaker')
      .where((l) => !l.date.isBefore(programStart))
      .length;

  // ── Body ─────────────────────────────────────────────────────────────

  /// Weigh-ins oldest → newest.
  List<LogEntry> get weightSeries => logsOf('weight').reversed.toList();

  double? get latestWeight => logsOf('weight').isEmpty
      ? null
      : logsOf('weight').first.number('kg')?.toDouble();

  double? get startWeight =>
      weightSeries.isEmpty ? null : weightSeries.first.number('kg')?.toDouble();

  /// A body weight people can have; a typo ("805") is refused before it
  /// reaches the log or Apple Health.
  static bool plausibleWeight(double kg) => kg >= 20 && kg <= 400;

  bool logWeight(double kg, {DateTime? date}) {
    if (!plausibleWeight(kg)) return false;
    addLog('weight', date: date, data: {'kg': kg});
    if (healthConnected) _health.writeWeight(kg, date ?? _now);
    return true;
  }

  int proteinFor(DateTime date) => logsOn(date, 'protein')
      .fold<int>(0, (sum, l) => sum + (l.number('g')?.toInt() ?? 0));

  bool addProtein(DateTime date, int grams) {
    if (grams <= 0 || grams > 500) return false;
    addLog('protein', date: date, data: {'g': grams});
    // Ticks itself at 150 g; never un-ticks one ticked by hand.
    if (proteinFor(date) >= 150) setCheck(date, 'protein', true);
    return true;
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

  /// What they added themselves: the seeded starting evidence counts as
  /// proof to read, not as practice.
  int get evidenceAdded =>
      (_state?.evidence ?? const <EvidenceItem>[]).where((e) => !e.id.startsWith('seed_')).length;

  int evidenceAddedBetween(DateTime from, DateTime to) =>
      (_state?.evidence ?? const <EvidenceItem>[])
          .where((e) =>
              !e.id.startsWith('seed_') &&
              !e.createdAt.isBefore(from) &&
              e.createdAt.isBefore(to))
          .length;

  void addEvidence(String section, String text) {
    final s = _state;
    if (s == null || text.trim().isEmpty) return;
    final item = EvidenceItem(
      id: 'ev_${_uid()}',
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

  /// Puts back an item just removed (Undo), at its old place.
  void restoreEvidence(EvidenceItem item, int index) {
    final s = _state;
    if (s == null || s.evidence.any((e) => e.id == item.id)) return;
    final list = [...s.evidence]..insert(index.clamp(0, s.evidence.length), item);
    _update(s.copyWith(evidence: list));
  }

  // ── Month review stats ───────────────────────────────────────────────

  MonthStats statsForMonth(int month) {
    final from = monthStart(month);
    final to = monthStart(month + 1);
    final today = dayOnly(_now);
    final days = <DateTime>[];
    for (var d = from;
        d.isBefore(to) && !d.isAfter(today);
        d = d.plusDays(1)) {
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
          // As a share of each day's list, so months compare across list
          // changes.
          : days.fold<double>(0, (s, d) => s + scoreShare10(d)) / days.length,
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
    _syncReminders();
    _generating = true;
    briefError = null;
    notifyListeners();
    try {
      final forWeek = report.weekStart.plusDays(7);
      final weekCheckins = [
        for (final d in weekDays(report.weekStart))
          if (checkinFor(d) case final c?) c
      ];
      final brief = await _briefs.generate(BriefInput(
        report: report,
        itemTitles: {for (final n in dailyItems) n.id: n.title},
        itemCount: dailyCount,
        monthCarry: lastCarry,
        quarterFocus: quarterFocus,
        wins: [
          for (final w in logsOf('win').reversed)
            if (!w.date.isBefore(report.weekStart) &&
                w.date.isBefore(report.weekStart.plusDays(7)))
              w.text
        ],
        peopleCount: people.length,
        peopleReached: people
            .where((p) =>
                !(lastContact(p)?.isBefore(report.weekStart) ?? true))
            .length,
        itemCues: {
          for (final n in dailyItems)
            if (cueFor(n.id).trim().isNotEmpty) n.id: cueFor(n.id)
        },
        daysCounted: weekDays(report.weekStart)
            .where((d) => !d.isBefore(programStart) && !d.isAfter(_now))
            .length,
        forWeek: forWeek,
        programMonth: programMonth,
        phaseName: phase.name,
        programWeek: programWeek,
        // Only program days: a Saturday start isn't five missed days.
        itemRates: itemRates(weekDays(report.weekStart)
            .where((d) => !d.isAfter(_now) && !d.isBefore(programStart))
            .toList()),
        excusedDays: weekDays(report.weekStart)
            .where((d) =>
                !d.isAfter(_now) &&
                !d.isBefore(programStart) &&
                (isExcused(d) || isRestDay(d) || isPaused(d)))
            .length,
        evidenceAddedThisWeek: evidenceAddedBetween(
            report.weekStart, report.weekStart.plusDays(7)),
        artifactsThisMonth: countBetween(
            'artifact', monthStart(programMonth), monthStart(programMonth + 1)),
        postsThisWeek: countBetween('linkedin', report.weekStart,
            report.weekStart.plusDays(7)),
        gymDays: isBuiltInPerson ? gymDays : const [],
        builtInPlan: isBuiltInPerson,
        openUnlocks: !isBuiltInPerson
            ? const []
            : unlocksFor(programMonth)
                .where((u) => u.doneKey == null || !isDone(u.doneKey!))
                .map((u) => u.title)
                .toList(),
        latestWeight: isBuiltInPerson ? latestWeight : null,
        avgEnergy: averageOf(weekCheckins, 'energy'),
        avgSleep: averageOf(weekCheckins, 'sleep'),
        wakeSpread: wakeSpread(report.weekStart),
        readinessGap: isBuiltInPerson ? readinessGap?.name : null,
        openFollowUps: openFollowUps.length,
        patterns: patterns().map((p) => p.sentence).take(3).toList(),
        deepWorkHours: focusMinutesInWeek(report.weekStart) / 60,
        hardDays: hardDaysInWeek(report.weekStart),
        direction: odysseyLeaning,
        money: moneySummary == null || moneySummary!.isEmpty ? null : moneySummary,
        growingOthers: [
          for (final p in peopleGrowing)
            // Their name and how often you helped; what they're working on
            // stays on the device.
            '${p.text} (${helpsInMonth(p, programMonth)} helps this month)'
        ],
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
              '${weekOutcomeDone(report.weekStart, i) ? '[done]' : '[open]'} ${weekOutcomes(report.weekStart)[i].trim()}${weekOutcomeGoal(report.weekStart, i) == null ? '' : ' (for: ${goalById(weekOutcomeGoal(report.weekStart, i)!)!.text})'}'
        ],
        peopleOverdue: [for (final p in peopleDue.take(3)) p.text],
        goals: goalSummaries(),
        noteSent: noteSentInWeek(report.weekStart),
        setbacks: setbacksInWeek(report.weekStart),
        kindnessActs: kindnessInWeek(report.weekStart),
        strengths: signatureStrengths,
        strengthUses: strengthUsesInWeek(report.weekStart),
        boardGaps: boardGaps,
        sayDo: sayDo() == null ? null : '${sayDo()!.kept} of ${sayDo()!.kept + sayDo()!.missed}',
        promisesOverdue: promisesDue(_now.minusDays(1)).length,
        thoughtsChecked: thoughtsInWeek(report.weekStart),
        courageSteps: courageStepsInWeek(report.weekStart),
        asksThisWeek: asksInWeek(report.weekStart),
        proposedOutcomes: [for (final p in proposedOutcomes(forWeek)) p.text],
        askRecord: askRecord() == null
            ? null
            : '${askRecord()!.yes} of ${askRecord()!.asked} said yes or partly; you expected ${askRecord()!.guess}%',
        wordForTheYear: wordForTheYear,
        restPlanned: restPlannedSoon,
        experiments: [
          for (final e in [...experimentsWith('running'), ...experimentsWith('kept').take(2)])
            '${e.text} (${e.str('status')}, watching ${experimentMeasures[e.str('measure')] ?? e.str('measure')}'
                '${experimentCompare(e).before == null || experimentCompare(e).during == null ? '' : ': ${experimentCompare(e).before!.toStringAsFixed(1)} before → ${experimentCompare(e).during!.toStringAsFixed(1)} during'})'
        ],
        learningApplied: [
          for (final l in learningWith('done')
              .where((l) => (l.str('finished') ?? '')
                  .compareTo(dateKey(dayOnly(_now).minusDays(30))) >= 0)
              .take(3))
            if ((l.str('principle') ?? '').isNotEmpty)
              '${l.text}: ${l.str('principle')}${(l.str('result') ?? '').isEmpty ? ' (experiment: ${l.str('experiment')})' : ' → ${l.str('result')}'}'
        ],
        lowestLifeArea: lowestLifeArea == null
            ? null
            : '${lowestLifeArea!.name} (${latestWheel[lowestLifeArea!.id]}/10)',
        growthFocus: focusArea()?.name,
        growthDrill: focusArea() == null
            ? null
            : drillFor(focusArea()!, report.weekStart.plusDays(7)).title,
        repsThisWeek: repsInWeek(report.weekStart),
        repsWithoutFeedback: repsWithoutFeedback(programMonth),
        decidersSeen: decidersSeen,
        valueGap: valueGap(report.weekStart),
        openCommitments: [
          for (final c in commitmentsDue(report.weekStart.plusDays(6)))
            if ((c.str('will') ?? '').trim().isNotEmpty) c.str('will')!
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

  /// The built-in person's reminders follow their schedule; anyone else
  /// gets the general set, timed to their own day once they've shaped it.
  List<ReminderDef> get activeReminderDefs {
    if (isBuiltInPerson) return reminderDefs;
    final d = dayShape;
    if (d == null) return generalReminderDefs;
    ReminderDef at(ReminderDef r, int minute) => ReminderDef(
        r.id, r.label, (minute % 1440) ~/ 60, minute % 60,
        weekdays: r.weekdays, route: r.route, defaultOn: r.defaultOn);
    final midday = d.workStart < d.workEnd
        ? d.workStart + (d.workEnd - d.workStart) ~/ 2
        : d.wake + 300;
    return [
      for (final r in generalReminderDefs)
        switch (r.id) {
          'g_checkin' => at(r, d.wake + 30),
          'g_items' => at(r, midday),
          // Lights out after midnight counts as the same night.
          // (A late riser's bounds can cross, so no clamp: at() wraps.)
          'g_shutdown' => at(r, () {
              final bed = d.bed < d.wake ? d.bed + 24 * 60 : d.bed;
              final lo = d.wake + 60, hi = 23 * 60 + 30;
              final t = bed - 90;
              return lo > hi ? t : t.clamp(lo, hi);
            }()),
          _ => r,
        }
    ];
  }

  /// Evidence prompts: the built-in person's own, or general ones.
  List<EvidencePrompt> get activeEvidenceSections =>
      isBuiltInPerson ? evidenceSections : generalEvidenceSections;

  // ── Your day ─────────────────────────────────────────────────────────

  /// The shape of an ordinary day for anyone without the built-in schedule:
  /// wake, work and bed times (minutes after midnight). It draws the dial
  /// and times their reminders.
  ({int wake, int workStart, int workEnd, int bed})? get dayShape {
    final l = logsOf('day_shape');
    if (l.isEmpty) return null;
    int m(String k, int d) => (l.first.number(k) ?? d).toInt();
    return (
      wake: m('wake', 7 * 60),
      workStart: m('work_start', 9 * 60),
      workEnd: m('work_end', 17 * 60 + 30),
      bed: m('bed', 23 * 60),
    );
  }

  void saveDayShape({required int wake, required int workStart, required int workEnd, required int bed}) {
    final data = {'wake': wake, 'work_start': workStart, 'work_end': workEnd, 'bed': bed};
    final l = logsOf('day_shape');
    if (l.isEmpty) {
      addLog('day_shape', data: data);
    } else {
      updateLog(l.first.copyWith(data: data));
    }
    _syncReminders();
  }

  /// Their day as schedule blocks (for the dial); empty until shaped.
  List<ScheduleBlock> get personalSchedule {
    final d = dayShape;
    if (d == null) return const [];
    ScheduleBlock b(int minute, String title, String detail, String lane, IconData icon) =>
        ScheduleBlock((minute ~/ 60) % 24, minute % 60, title, detail, lane, icon);
    final hasWork = d.workStart < d.workEnd;
    // Lights out after midnight belongs to the same night.
    final bed = d.bed < d.wake ? d.bed + 24 * 60 : d.bed;
    return [
      b(d.wake, 'Morning', 'Your first items, before the day takes over', 'body',
          Icons.wb_twilight_rounded),
      if (hasWork) ...[
        b(d.workStart, 'Work', 'One block on what matters most', 'skill',
            Icons.center_focus_strong_rounded),
        b(d.workEnd, 'Evening', 'People, movement, rest', 'social', Icons.home_outlined),
      ] else
        b(d.wake + 120, 'Day', 'What matters most first', 'skill',
            Icons.center_focus_strong_rounded),
      b(bed - 60, 'Wind down', 'Tomorrow\'s three, screens off', 'mind',
          Icons.nights_stay_outlined),
      b(bed, 'Sleep', 'Lights out', 'body', Icons.bedtime_outlined),
    ]..sort((a, c) => a.minuteOfDay.compareTo(c.minuteOfDay));
  }

  /// The block they're in now, if their day is shaped.
  ScheduleBlock? personalBlockAt(DateTime now) {
    final s = personalSchedule;
    if (s.isEmpty) return null;
    final m = now.hour * 60 + now.minute;
    var active = s.last;
    for (final b in s) {
      if (b.minuteOfDay <= m) active = b;
    }
    return active;
  }

  bool reminderOn(String id) {
    final def = [...reminderDefs, ...generalReminderDefs].firstWhere((d) => d.id == id);
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
    final book = planBook;
    final defs = activeReminderDefs;
    for (var i = 0; i < defs.length; i++) {
      final def = defs[i];
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
          skipToday: wd == _now.weekday && reminderDoneToday(def.id),
        ));
      }
    }
    // Worry time: a daily nudge at their slot, only while something is
    // parked (ids from worryReminderBase, below the one-off range).
    final wt = worryTime;
    if (wt != null && parkedWorries.isNotEmpty) {
      for (var wd = 1; wd <= 7; wd++) {
        out.add(PlannedReminder(
          id: worryReminderBase + wd,
          weekday: wd,
          hour: wt ~/ 60,
          minute: wt % 60,
          title: 'Worry time',
          body: '${parkedWorries.length} parked — a next step, or let it go.',
          route: '/worry',
        ));
      }
    }
    return out;
  }

  static const worryReminderBase = 950;

  /// Whether what reminder [id] asks for is already done today.
  bool reminderDoneToday(String id) {
    final today = dayOnly(_now);
    return switch (id) {
      'g_checkin' => checkinFor(today) != null,
      'g_items' => isHeld(today),
      'g_shutdown' => shutdownFor(today) != null,
      'g_sunday' || 'report' => reportForWeek(today) != null,
      'ritual' => logsOn(today, 'ritual').isNotEmpty,
      'gym' => gymDone(today),
      _ => false,
    };
  }

  /// Re-plans reminders when today becomes held (or stops being): only
  /// that change matters to them, so most ticks schedule nothing.
  bool _lastHeldToday = false;
  void _resyncIfHeldChanged() {
    if (_reminders == null || !isCommissioned) return;
    final held = isHeld(dayOnly(_now));
    if (held == _lastHeldToday) return;
    _lastHeldToday = held;
    _syncReminders();
  }

  String _reminderBody(String id) {
    switch (id) {
      case 'g_checkin':
        return 'Thirty seconds: energy, mood, sleep.';
      case 'g_items':
        final day = dailyItems.where((n) => n.when == 'day').map((n) => n.title).take(2).toList();
        return day.isEmpty
            ? 'A look at your list: what\'s left for today?'
            : '${day.join(' · ')} — still on today\'s list?';
      case 'g_shutdown':
        return 'Tomorrow\'s three on paper, one good thing, then stop.';
      case 'g_sunday':
        return 'Five answers about your week; your brief comes straight back.';
      case 'wake':
        return '500ml before coffee, before the phone.';
      case 'winddown':
        return 'No screens. Tomorrow: ${outfitFor(_now.plusDays(1)).occasion}.';
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
      {required List<String> tomorrow, String open = '', String win = '', String why = ''}) {
    // Up to three good things, one per line, and why the first happened
    // (Seligman et al. 2005: "three good things" lifted happiness for six
    // months). Each is a win.
    final goods = [
      for (final l in win.split('\n'))
        if (l.trim().isNotEmpty) l.trim()
    ].take(3).toList();
    for (final (i, g) in goods.indexed) {
      if (!logsOn(day, 'win').any((w) => w.text == g)) {
        addLog('win',
            date: dayOnly(day),
            text: g,
            data: i == 0 && why.trim().isNotEmpty ? {'why': why.trim()} : const {});
      }
    }
    final next = dayOnly(day).plusDays(1);
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
    // Tonight's "close the day" reminder has nothing left to ask.
    if (dateKey(day) == dateKey(_now)) _syncReminders();
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
  /// Returns false when the goal couldn't be added (three already active).
  bool buildPlan({
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
    String milestone = '',
    DateTime? deadline,
    required List<DailyIdea> daily,
    bool replaceDaily = false,
    bool keepOwnDaily = false,
    int? programLength,
  }) {
    if (programLength != null) setProgramLength(programLength);
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
    // A template already adopted (a second run, or a pack) is reused.
    final same = customAreas
        .where((c) => c.name.toLowerCase() == area.name.toLowerCase())
        .firstOrNull;
    final areaId = area.custom || growthAreas.any((a) => a.id == area.id)
        ? area.id
        : same?.id ?? saveCustomArea(area.copyWith(id: '')).id;
    setFocus(areaId, startRating: areaRating);
    var goalAdded = true;
    final title = goal.trim().toLowerCase();
    if (title.isNotEmpty &&
        !activeGoals.any((g) => g.text.trim().toLowerCase() == title)) {
      goalAdded = saveGoal(
          title: goal,
          why: goalWhy,
          obstacle: obstacle,
          plan: plan,
          deadline: deadline,
          milestones: [milestone],
          areas: [areaId]) != null;
    } else if (title.isNotEmpty) {
      // The goal is already there (a pack added it from step 1): keep what
      // they wrote in this step instead of dropping it.
      final g = activeGoals.firstWhere((g) => g.text.trim().toLowerCase() == title);
      final fresh = dayOnly(g.createdAt) == dayOnly(_now);
      final ms = milestonesOf(g);
      updateLog(g.copyWith(data: {
        ...g.data,
        if (goalWhy.trim().isNotEmpty) 'why': goalWhy.trim(),
        if (obstacle.trim().isNotEmpty) 'obstacle': obstacle.trim(),
        if (plan.trim().isNotEmpty) 'plan': plan.trim(),
        if (fresh && deadline != null) 'deadline': dateKey(deadline),
        if (milestone.trim().isNotEmpty && !ms.any((m) => m.text == milestone.trim()))
          'milestones': [
            ...(g.data['milestones'] as List? ?? const []),
            {'text': milestone.trim(), 'done': false},
          ],
      }));
    }
    _changingList(() {
      final own = keepOwnDaily ? customDailyItems.length : 0;
      if (replaceDaily && daily.length + own >= minDailyItems) {
        for (final b in nonNegotiables) {
          setDone('daily:off:${b.id}', true);
        }
        // Items just added from a plan pack stay. Retired, not deleted.
        if (!keepOwnDaily) {
          for (final n in customDailyItems) {
            setDone('daily:off:${n.id}', true);
          }
        }
      }
      _addIdeas(daily);
    });
    setDone(planBuiltKey, true);
    _syncReminders();
    return goalAdded;
  }

  /// Adds daily items with their cues, skipping titles already there.
  /// Returns how many were added.
  int _addIdeas(List<DailyIdea> ideas) {
    var added = 0;
    for (final d in ideas) {
      if (dailyCount >= maxDailyItems) break;
      if (dailyItems.any((x) => x.title.toLowerCase() == d.title.toLowerCase())) continue;
      // One they retired comes back, with its history and cue.
      final old = retiredCustomItems
          .where((x) => x.title.toLowerCase() == d.title.toLowerCase())
          .firstOrNull;
      if (old != null) {
        setDone('daily:off:${old.id}', false);
        added++;
        continue;
      }
      final id = 'd_${_uid()}';
      added++;
      addLog('daily_item', text: d.title, data: {
        'id': id,
        'lane': d.lane,
        'when': d.when,
        if (d.steps.isNotEmpty) 'steps': d.steps,
      });
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
      {required String mine, required String theirs, required int weekday, String stake = ''}) {
    final p = partner;
    final data = {
      'mine': mine.trim(),
      'theirs': theirs.trim(),
      'weekday': weekday.clamp(1, 7),
      'stake': stake.trim(),
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
    if ((p.str('stake') ?? '').isNotEmpty) b.writeln('Our stake if we miss: ${p.str('stake')}');
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
      for (var d = from; d.isBefore(to) && !d.isAfter(today); d = d.plusDays(1))
        if (!d.isBefore(programStart)) d
    ];
    final p = activeProfile;
    final b = StringBuffer()
      ..writeln('${p.name} — progress ${dateKey(from)} to ${dateKey(to.minusDays(1))}')
      ..writeln(p.targetRole.trim().isEmpty
          ? p.currentRole
          : p.currentRole.trim().isEmpty
              ? 'Towards ${p.targetRole}'
              : '${p.currentRole} → ${p.targetRole}')
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

  // ── Care: health, grooming, home and things ──────────────────────────

  /// Recurring care you set yourself — check-ups, the barber, nails, the
  /// car — with how often and when last done. ONO only keeps the dates;
  /// how often health checks happen is for you and your doctor.
  static const careKinds = {
    'health': 'Health',
    'grooming': 'Grooming',
    'home': 'Home & things',
    'documents': 'Documents',
    'for': 'For someone in your care',
  };

  /// Documents are asked about this long before they expire: renewals
  /// take time.
  static const renewLeadDays = 90;

  /// One-tap suggestions per kind: (name, every days, kind).
  static const upkeepSuggestions = [
    ('Dentist check-up', 180, 'health'),
    ('General check-up', 365, 'health'),
    ('Blood tests', 180, 'health'),
    ('Eye test', 730, 'health'),
    ('Skin check', 365, 'health'),
    ('Flu jab (ask your doctor)', 365, 'health'),
    ('New toothbrush', 90, 'health'),
    ('Haircut', 28, 'grooming'),
    ('Beard trim', 14, 'grooming'),
    ('Nails', 14, 'grooming'),
    ('Brows', 42, 'grooming'),
    ('Car service', 365, 'home'),
    ('Back up photos and files', 30, 'home'),
    ('Sort the wardrobe', 180, 'home'),
    ('Test the smoke alarm', 180, 'home'),
    ('Passport', 0, 'documents'),
    ('ID card', 0, 'documents'),
    ('Driving licence', 0, 'documents'),
    ('Insurance renewal', 0, 'documents'),
  ];

  List<LogEntry> get upkeep => logsOf('upkeep');

  /// Health, grooming or home — older entries without one are health.
  String careKindOf(LogEntry u) => u.str('kind') ?? 'health';

  /// A document has no interval, only an [expires] date (never its
  /// number: ONO keeps the date, nothing else). Care for someone else
  /// ([forPerson], kind 'for') belongs to that person.
  LogEntry? addUpkeep(String name, int everyDays,
          {DateTime? lastDone, String kind = 'health', DateTime? expires, String? forPerson}) =>
      name.trim().isEmpty || (everyDays <= 0 && kind != 'documents')
          ? null
          : addLog('upkeep', text: name.trim(), data: {
              'every': kind == 'documents' ? 0 : everyDays,
              'kind': forPerson != null ? 'for' : careKinds.containsKey(kind) ? kind : 'health',
              'last': lastDone == null ? null : dateKey(lastDone),
              if (expires != null) 'expires': dateKey(expires),
              if (forPerson != null) 'for': forPerson,
            });

  /// Care items for someone in your care.
  List<LogEntry> careFor(LogEntry person) =>
      [for (final u in upkeep) if (u.str('for') == person.id) u];

  // ── In my care ───────────────────────────────────────────────────────

  /// Someone you look after: a parent, a child, a partner who is ill.
  bool inMyCare(LogEntry person) => person.data['in_care'] == true;

  void setInMyCare(LogEntry person, bool on) {
    final p = personById(person.id);
    if (p == null) return;
    updateLog(p.copyWith(data: {...p.data, 'in_care': on}));
  }

  List<LogEntry> get peopleInCare => [for (final p in people) if (inMyCare(p)) p];

  /// Questions to ask while you can — their story, in their words.
  static const storyQuestions = [
    ('grew_up', 'Where did they grow up, and what was it like?'),
    ('proud', 'What are they proudest of?'),
    ('met', 'How did they meet the people they love most?'),
    ('hardest', 'What was their hardest time, and how did they get through it?'),
    ('remember', 'What do they want you to know, or to remember?'),
  ];

  String storyAnswer(LogEntry person, String key) => person.str('story:$key') ?? '';

  void setStoryAnswer(LogEntry person, String key, String answer) {
    final p = personById(person.id);
    if (p == null) return;
    final a = answer.trim();
    if (a == storyAnswer(p, key)) return;
    final data = {...p.data};
    if (a.isEmpty) {
      data.remove('story:$key');
    } else {
      data['story:$key'] = a;
    }
    updateLog(p.copyWith(data: data));
  }

  /// Once a month, for anyone caring for someone: how heavy it has felt
  /// (1–5) and who could share it. Caregiver strain grows unseen.
  LogEntry? caregiverCheckFor(int month) {
    for (final l in logsOf('caregiver_check')) {
      if (atMonth(l, month)) return l;
    }
    return null;
  }

  void saveCaregiverCheck({required int heavy, String share = ''}) {
    final data = {'month': programMonth, 'heavy': heavy.clamp(1, 5), 'share': share.trim()};
    final e = caregiverCheckFor(programMonth);
    if (e == null) {
      addLog('caregiver_check', data: data);
    } else {
      updateLog(e.copyWith(data: data));
    }
  }

  bool get caregiverCheckDue =>
      hasStarted && peopleInCare.isNotEmpty && dayOfMonth >= 25 && caregiverCheckFor(programMonth) == null;

  DateTime? upkeepExpires(LogEntry u) => DateTime.tryParse(u.str('expires') ?? '');

  /// Renewed: the new expiry date.
  void setUpkeepExpires(String id, DateTime expires) {
    final l = upkeep.where((u) => u.id == id).firstOrNull;
    if (l == null) return;
    final data = {...l.data, 'expires': dateKey(expires), 'last': dateKey(_now)};
    data.remove('booked');
    updateLog(l.copyWith(data: data));
  }

  /// Done on [on] (today by default): it becomes the last time, joins the
  /// history (the last 8) and clears a booking.
  void markUpkeepDone(String id, {DateTime? on}) {
    final l = upkeep.where((u) => u.id == id);
    if (l.isEmpty) return;
    final day = dateKey(on ?? _now);
    final history = <String>{
      ...[for (final h in (l.first.data['history'] as List? ?? const [])) '$h'],
      if ((l.first.str('last') ?? '').isNotEmpty) l.first.str('last')!,
      day,
    }.toList()
      ..sort();
    final last = history.last;
    final data = {...l.first.data, 'last': last, 'history': history.reversed.take(8).toList().reversed.toList()};
    data.remove('booked');
    updateLog(l.first.copyWith(data: data));
  }

  /// Change how often, or the name.
  void editUpkeep(String id, {String? name, int? every, String? kind}) {
    final l = upkeep.where((u) => u.id == id).firstOrNull;
    if (l == null) return;
    updateLog(l.copyWith(
      text: name == null || name.trim().isEmpty ? l.text : name.trim(),
      data: {
        ...l.data,
        if (every != null && every > 0) 'every': every,
        if (kind != null && careKinds.containsKey(kind)) 'kind': kind,
      },
    ));
  }

  /// An appointment made for [day]; null clears it.
  void bookUpkeep(String id, DateTime? day) {
    final l = upkeep.where((u) => u.id == id).firstOrNull;
    if (l == null) return;
    final data = {...l.data};
    if (day == null) {
      data.remove('booked');
    } else {
      data['booked'] = dateKey(day);
    }
    updateLog(l.copyWith(data: data));
  }

  DateTime? upkeepBooked(LogEntry u) => DateTime.tryParse(u.str('booked') ?? '');

  /// Your real rhythm, from 3+ times done: the median gap in days.
  int? upkeepUsualEvery(LogEntry u) {
    final days = [
      for (final h in (u.data['history'] as List? ?? const []))
        if (DateTime.tryParse('$h') case final d?) d
    ]..sort();
    if (days.length < 3) return null;
    final gaps = [for (var i = 1; i < days.length; i++) days[i].daysSince(days[i - 1])]..sort();
    return gaps[gaps.length ~/ 2];
  }

  void removeUpkeep(String id) => removeLog(id);

  /// When it's next due; null if never done (due now).
  DateTime? upkeepNextDue(LogEntry u) {
    if (careKindOf(u) == 'documents') {
      return upkeepExpires(u)?.minusDays(renewLeadDays);
    }
    final last = DateTime.tryParse(u.str('last') ?? '');
    if (last == null) return null;
    return last.plusDays((u.number('every') ?? 365).toInt());
  }

  /// How early it comes due: two weeks for a yearly check, a few days for
  /// nails — never a permanent nag for things done every fortnight.
  int upkeepLead(LogEntry u) => careKindOf(u) == 'documents'
      ? 14
      : ((u.number('every') ?? 365).toInt() ~/ 4).clamp(2, 14);

  /// Due soon (within its lead time), overdue first; never-done items
  /// count as due. Booked ones aren't due: they're planned.
  List<LogEntry> get upkeepDue {
    final today = dayOnly(_now);
    final inCare = {for (final p in peopleInCare) p.id};
    final due = [
      for (final u in upkeep)
        // A booking still ahead is planned; one that passed without "Done"
        // comes due again. Care for someone no longer in your care waits.
        if ((upkeepBooked(u) == null || upkeepBooked(u)!.isBefore(today)) &&
            (careKindOf(u) != 'for' || inCare.contains(u.str('for'))) &&
            (upkeepNextDue(u) == null ||
                !upkeepNextDue(u)!.isAfter(today.plusDays(upkeepLead(u)))))
          u
    ];
    due.sort((a, b) => (upkeepNextDue(a) ?? DateTime(2000)).compareTo(upkeepNextDue(b) ?? DateTime(2000)));
    return due;
  }

  /// Appointments today or tomorrow, soonest first.
  List<LogEntry> upkeepBookedSoon(DateTime day) {
    final today = dayOnly(day);
    return [
      for (final u in upkeep)
        if (upkeepBooked(u) case final b?)
          if (!b.isBefore(today) && !b.isAfter(today.plusDays(1))) u
    ]..sort((a, b) => upkeepBooked(a)!.compareTo(upkeepBooked(b)!));
  }

  // ── Money check-in ───────────────────────────────────────────────────

  /// Once a month: what came in, what went out, what's set aside, and one
  /// decision. Seeing it is most of the battle (self-monitoring; Harkin et
  /// al. 2016). Numbers stay in your own currency; only the savings rate
  /// and buffer go to the coach.
  LogEntry? moneyCheckFor(int month) {
    for (final l in logsOf('money_check')) {
      if (atMonth(l, month)) return l;
    }
    return null;
  }

  /// The month a money check is for: this one, or last month during the
  /// first 5 days of a month when last month has none yet.
  int get moneyMonthDefault =>
      programMonth > 1 && dayOfMonth <= 5 && moneyCheckFor(programMonth - 1) == null
          ? programMonth - 1
          : programMonth;

  void saveMoneyCheck({
    int? month,
    required double income,
    required double spent,
    double? savings,
    String decision = '',
    String worry = '',
  }) {
    month ??= programMonth;
    final data = {
      'month': month,
      'income': income,
      'spent': spent,
      'savings': savings,
      'decision': decision.trim(),
      'worry': worry.trim(),
    };
    final e = moneyCheckFor(month);
    if (e == null) {
      addLog('money_check', data: data);
    } else {
      updateLog(e.copyWith(date: dayOnly(_now), data: data));
    }
  }

  /// Share of income not spent, 0–1 (can be negative).
  double? savingsRate(LogEntry check) {
    final i = check.number('income')?.toDouble() ?? 0;
    if (i <= 0) return null;
    return (i - (check.number('spent')?.toDouble() ?? 0)) / i;
  }

  /// Months of spending the savings would cover.
  double? bufferMonths(LogEntry check) {
    final s = check.number('savings')?.toDouble();
    final spent = check.number('spent')?.toDouble() ?? 0;
    if (s == null || spent <= 0) return null;
    return s / spent;
  }

  /// From day 25 of a program month until this month's check-in is done.
  bool get moneyCheckDue =>
      hasStarted && dayOfMonth >= 25 && moneyCheckFor(programMonth) == null &&
      (logsOf('money_check').isNotEmpty || moneyOptedIn);

  /// Prompting starts once they've done one, or asked for it.
  bool get moneyOptedIn => isDone('money:on');

  /// "Saved 18% · 2.5 months' buffer" from the latest check-in.
  String? get moneySummary {
    final l = logsOf('money_check');
    if (l.isEmpty) return null;
    final r = savingsRate(l.first);
    final b = bufferMonths(l.first);
    return [
      if (r != null)
        r >= 0
            ? 'saved ${(r * 100).round()}% of income'
            : 'spent ${(-r * 100).round()}% more than income',
      if (b != null) '${b.toStringAsFixed(1)} months\' buffer',
    ].join(' · ');
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

  // ── Negotiation planner ──────────────────────────────────────────────

  /// The parts of a plan, in order: (key, label, hint).
  static const negotiationFields = [
    ('want', 'What you want', 'The outcome, as specific as you can'),
    ('walkaway', 'If there\'s no deal, what will you do?', 'Your best alternative — it decides how firm you can be'),
    ('bottom', 'Your bottom line', 'Below this, you\'d rather walk away'),
    ('they_care', 'What do they care about?', 'Their pressures, goals, constraints'),
    ('first_offer', 'Your first offer', 'Ambitious and justifiable'),
    ('why', 'Why it\'s fair', 'The reason you\'ll give for it'),
    ('give', 'What you could give', 'Things cheap for you, valuable to them'),
    ('questions', 'Questions to ask', 'To learn what they need'),
  ];

  static const negotiationOutcomes = {
    'better': 'Better than my first offer',
    'met': 'About my first offer',
    'less': 'Less, but above my bottom line',
    'none': 'No deal',
  };

  List<LogEntry> get negotiations => logsOf('negotiation');

  LogEntry? saveNegotiation({String? id, required String about, Map<String, String> fields = const {}}) {
    if (about.trim().isEmpty) return null;
    final data = {
      for (final f in negotiationFields) f.$1: (fields[f.$1] ?? '').trim(),
    };
    final existing = id == null ? null : negotiations.where((l) => l.id == id).firstOrNull;
    if (existing == null) {
      return addLog('negotiation', text: about.trim(), data: {...data, 'status': 'planned'});
    }
    final updated = existing.copyWith(text: about.trim(), data: {...existing.data, ...data});
    updateLog(updated);
    return updated;
  }

  /// How it went, against the first offer, and one lesson.
  void closeNegotiation(String id, {required String outcome, String lesson = ''}) {
    final l = negotiations.where((x) => x.id == id).firstOrNull;
    if (l == null || !negotiationOutcomes.containsKey(outcome)) return;
    updateLog(l.copyWith(data: {
      ...l.data,
      'status': 'done',
      'outcome': outcome,
      'lesson': lesson.trim(),
      'closed_on': dateKey(_now),
    }));
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

  LogEntry? logMove(String kind, int minutes,
          {bool vigorous = false, bool outside = false, DateTime? day}) =>
      minutes <= 0
          ? null
          : addLog('move', date: day == null ? null : dayOnly(day), data: {
              'kind': kind,
              'minutes': minutes,
              'vigorous': vigorous,
              if (outside) 'outside': true,
            });

  /// Minutes moved outside this week (as logged, not doubled). Two hours
  /// a week in nature goes with better health and wellbeing (White et al.
  /// 2019 — an association, so it's shown, never set as a target).
  int outsideMinutesInWeek(DateTime anyDay) => movesInWeek(anyDay)
      .where((l) => l.data['outside'] == true)
      .fold<int>(0, (s, l) => s + (l.number('minutes') ?? 0).toInt());

  List<LogEntry> movesInWeek(DateTime anyDay) {
    final from = weekStartOf(anyDay), to = from.plusDays(7);
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
      if (atQuarter(l, programQuarter)) return l;
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
  /// This quarter's move only: last quarter's isn't news for the coach.
  String? get craftingMove {
    final a = energyAudit;
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
            DailyIdea(d.title, d.lane, d.when, '', cueFor(d.id),
                minimum: minimumFor(d.id), steps: stepsOf(d.id))
        ],
        stops: [for (final s in stopList) s.text]);
  }

  /// Adds a pack to this plan: its areas (skipping names already there),
  /// its goal (if there is room for one more), daily items and stops.
  /// [replaceDaily] retires the current daily list first.
  ({int areas, int items, bool goal}) applyPack(PlanPack pack,
      {bool replaceDaily = false, bool withGoal = true}) {
    var areas = 0;
    final areaIds = <String>[];
    for (final a in pack.areas) {
      final have = allGrowthAreas
          .where((x) => x.name.toLowerCase() == a.name.toLowerCase())
          .firstOrNull;
      if (have != null) {
        areaIds.add(have.id);
        continue;
      }
      areaIds.add(saveCustomArea(a.copyWith(id: '')).id);
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
              areas: areaIds,
              // 31 Jan + 1 month is 28 Feb, not 3 March.
              deadline: DateTime(now.year, now.month + g.months,
                  min(now.day, DateTime(now.year, now.month + g.months + 1, 0).day))) !=
          null;
    }
    final items = _changingList(() {
      if (replaceDaily && pack.daily.length >= minDailyItems) {
        for (final b in nonNegotiables) {
          setDone('daily:off:${b.id}', true);
        }
        for (final n in customDailyItems) {
          setDone('daily:off:${n.id}', true);
        }
      }
      return _addIdeas(pack.daily);
    });
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
    bool clock = false,
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
      'clock': clock,
      'next': old['next'] ?? '',
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

  /// Returns false when reopening would make a fourth active goal.
  bool setGoalStatus(String id, String status) {
    final g = goalById(id);
    if (g == null) return false;
    if (status == 'active' &&
        (g.str('status') ?? 'active') != 'active' &&
        activeGoals.length >= maxActiveGoals) {
      return false;
    }
    updateLog(g.copyWith(data: {
      ...g.data,
      'status': status,
      'closed_on': status == 'active' ? null : dateKey(_now),
    }));
    return true;
  }

  /// A new date for a goal that reached its old one (or needs more time).
  void setGoalDeadline(String id, DateTime deadline) {
    final g = goalById(id);
    if (g == null) return;
    updateLog(g.copyWith(data: {
      ...g.data,
      'deadline': dateKey(dayOnly(deadline)),
      'extended': ((g.number('extended') ?? 0) + 1).toInt(),
    }));
  }

  /// The one next thing for this goal, in your words ('' clears it).
  void setGoalNext(String id, String next) {
    final g = goalById(id);
    if (g == null) return;
    updateLog(g.copyWith(data: {...g.data, 'next': next.trim()}));
  }

  void addMilestone(String id, String text) {
    final g = goalById(id);
    if (g == null || text.trim().isEmpty) return;
    updateLog(g.copyWith(data: {
      ...g.data,
      'milestones': [
        ...(g.data['milestones'] as List? ?? const []),
        {'text': text.trim(), 'done': false},
      ],
    }));
  }

  /// "4:30" (minutes:seconds or hours:minutes) → 4.5; "82,5" → 82.5.
  static double? parseGoalNumber(String text) {
    final t = text.trim().replaceAll(',', '.');
    final clock = RegExp(r'^(-?\d+):([0-5]\d)$').firstMatch(t);
    if (clock != null) {
      final whole = int.parse(clock.group(1)!);
      return whole + (whole < 0 ? -1 : 1) * int.parse(clock.group(2)!) / 60;
    }
    return double.tryParse(t);
  }

  /// A goal value as written: m:ss for a goal set as a time, else the
  /// number with at most one decimal.
  static String formatGoalNumber(LogEntry goal, double v) {
    if (goal.data['clock'] == true) {
      final whole = v.truncate();
      final rest = ((v - whole).abs() * 60).round();
      return rest == 60 ? '${whole + 1}:00' : '$whole:${rest.toString().padLeft(2, '0')}';
    }
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  /// Whether the goal can show progress: a number or at least a milestone.
  bool goalIsMeasured(LogEntry g) =>
      goalIsNumeric(g) || milestonesOf(g).isNotEmpty;

  /// Past its date, or its target reached: time to decide — achieved, a
  /// new date, or drop it on purpose.
  bool goalAtDecision(LogEntry g) {
    if ((g.str('status') ?? 'active') != 'active') return false;
    final end = goalDeadline(g);
    final past = end != null && dayOnly(_now).isAfter(end);
    return past || (goalIsMeasured(g) && goalProgress(g) >= 1);
  }

  List<LogEntry> get goalsAtDecision =>
      [for (final g in activeGoals) if (goalAtDecision(g)) g];

  /// Looking back at a closed goal: what made it happen (or why it was
  /// dropped and what that taught), and what you'd tell someone starting.
  /// An achieved goal's reflection becomes a review card and a win.
  void reflectOnGoal(String id, {required String whatWorked, String advice = ''}) {
    final g = goalById(id);
    if (g == null || whatWorked.trim().isEmpty) return;
    updateLog(g.copyWith(data: {
      ...g.data,
      'reflection': whatWorked.trim(),
      'advice': advice.trim(),
    }));
    if (g.str('status') == 'achieved') {
      addLog('win', text: 'Achieved: ${g.text}');
    }
  }

  /// Goals closed in the last 14 days with no reflection yet.
  List<LogEntry> get goalsToReflect {
    final since = dateKey(dayOnly(_now).minusDays(14));
    return [
      for (final g in goals)
        if ((g.str('status') ?? 'active') != 'active' &&
            (g.str('reflection') ?? '').isEmpty &&
            (g.str('closed_on') ?? '').compareTo(since) >= 0)
          g
    ];
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
    final total = end.daysSince(from);
    if (total <= 0) return 1;
    return (dayOnly(_now).daysSince(from) / total).clamp(0.0, 1.0);
  }

  /// 'ahead', 'on track', 'behind', or null without a deadline. Within 10
  /// points of the line counts as on track.
  /// 'reached' once the target is met; 'past due' after the deadline;
  /// null for a goal with nothing to measure it by — it can't be behind.
  String? goalPace(LogEntry g) {
    final e = goalExpected(g);
    if (e == null || !goalIsMeasured(g)) return null;
    if (goalProgress(g) >= 1) return 'reached';
    final end = goalDeadline(g);
    if (end != null && dayOnly(_now).isAfter(end)) return 'past due';
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
    return dayOnly(_now).daysSince(dayOnly(last));
  }

  /// Active numeric goals not measured for 14+ days.
  List<LogEntry> get goalsToMeasure => [
        for (final g in activeGoals)
          if (goalIsNumeric(g) && daysSinceGoalUpdate(g) >= 14) g
      ];

  /// One line per active goal for the brief.
  List<String> goalSummaries() => [
        for (final g in activeGoals)
          '${g.text} — ${(goalProgress(g) * 100).round()}% done'
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
    final end = week.plusDays(7);
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
    return countBetween('progress_note', week, week.plusDays(7)) > 0;
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
  /// Saves the setback; returns whether the next step went into today's
  /// priorities (false when there is no step or all three are taken).
  bool logSetback(
      {required String kind,
      required String happened,
      required String nextStep}) {
    addLog('setback', text: happened.trim(), data: {
      'kind': kind.trim(),
      'next': nextStep.trim(),
    });
    return addToTodayPriorities(nextStep);
  }

  /// Puts [step] in today's first empty priority; false if all are taken.
  bool addToTodayPriorities(String step) {
    if (step.trim().isEmpty) return false;
    final today = dayOnly(_now);
    final p = prioritiesFor(today);
    if (p.any((x) => x.trim() == step.trim())) return true;
    final slot = p.indexWhere((x) => x.trim().isEmpty);
    if (slot < 0) return false;
    setPriority(today, slot, step.trim());
    return true;
  }

  int setbacksInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('setback', week, week.plusDays(7));
  }

  // ── Learning queue ───────────────────────────────────────────────────

  static const learningKinds = ['Book', 'Course', 'Podcast', 'Talk', 'Article'];

  /// Everything he is learning from, newest first. Status: queue → active
  /// → done. Done means applied: one principle in his words and one
  /// experiment in real life (transfer of learning, Baldwin & Ford 1988).
  List<LogEntry> get learning => logsOf('learning');

  /// The book for this month's lunch read: the plan's while it has one,
  /// then the book being read on the learning list, else a prompt to
  /// choose one — never the last planned book again for a year.
  Book get planBook {
    if (scheduledBook(programMonth) case final b?) return b;
    for (final l in learningWith('active')) {
      if ((l.str('kind') ?? 'Book').toLowerCase() == 'book') {
        return Book(
            slot: 'Now',
            month: null,
            title: l.text,
            author: l.str('by') ?? '',
            chapters: '',
            why: 'From your learning list.');
      }
    }
    return noPlanBook;
  }

  static const noPlanBook = Book(
      slot: 'Now',
      month: null,
      title: 'Choose your next book',
      author: '',
      chapters: '',
      why: 'The planned books are read. Pick the next one under Learning.');

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

  /// Three guesses about what it will say, before reading: guessing
  /// first makes the answer stick (Metcalfe 2024), and comparing at the
  /// end shows what you learned.
  void setLearningGuesses(String id, String guesses) =>
      _setLearning(id, {'guesses': guesses.trim()});

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
              dayOnly(_now).daysSince(
                      DateTime.tryParse(l.str('finished') ?? '') ?? dayOnly(_now)) >=
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
    final horizon = today.plusDays(56);
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
      if (atQuarter(l, quarter)) return l;
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
    return dayOnly(_now).daysSince(quarterStart(programQuarter)) >= 45;
  }

  // ── Personal experiments ─────────────────────────────────────────────

  /// What an experiment can watch, from data already logged.
  static const experimentMeasures = {
    'score': 'Daily items (of 10)',
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
      dayOnly(_now).daysSince(experimentStart(e)) + 1;

  bool experimentEnded(LogEntry e) =>
      experimentDay(e) > (e.number('days') ?? 14).toInt();

  double? _measureOn(String measure, DateTime d) => switch (measure) {
        'score' => d.isAfter(dayOnly(_now)) || isMinimumDay(d) ? null : scoreShare10(d),
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
    final ranStop = start.plusDays(days);
    List<double> collect(DateTime from, DateTime to) => [
          for (var d = from; d.isBefore(to); d = d.plusDays(1))
            // Sick, skipped, rest and paused days say nothing about the change.
            if (!d.isBefore(journeyStart) &&
                !d.isAfter(today) &&
                (m != 'score' || d.isBefore(today)) &&
                !isExcused(d) &&
                !isRestDay(d) &&
                !isPaused(d))
              if (_measureOn(m, d) case final v?) v
        ];
    final before = collect(start.minusDays(days), start);
    final during = collect(start, ranStop.isAfter(today) ? today.plusDays(1) : ranStop);
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
  int get programQuarter => hasStarted
      ? (((programDay - 1) ~/ 90) + 1).clamp(1, programQuarters)
      : 1;

  DateTime quarterStart(int q) => dateForProgramDay((q - 1) * 90 + 1);

  LogEntry? reviewFor(int quarter) {
    for (final l in logsOf('quarterly_review')) {
      if (atQuarter(l, quarter)) return l;
    }
    return null;
  }

  /// The quarter a review now would close: in the first 7 days of a
  /// quarter that's the previous one; otherwise the current one.
  int get quarterToReview {
    final day = dayOnly(_now).daysSince(quarterStart(programQuarter));
    return day < 7 && programQuarter > 1 ? programQuarter - 1 : programQuarter;
  }

  /// From the last 7 days of a quarter to the first 7 of the next, until
  /// that quarter has a review.
  bool get quarterReviewDue {
    if (!hasStarted) return false;
    final q = quarterToReview;
    if (reviewFor(q) != null) return false;
    final end = quarterStart(q + 1);
    final left = end.daysSince(dayOnly(_now));
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
    // The quarter's last month is closed by this review too.
    final lastMonth = quarter * 3;
    if (monthReviewFor(lastMonth) == null && nextFocus.trim().isNotEmpty) {
      saveMonthReview(lastMonth,
          carry: nextFocus,
          lesson: lessons.trim().split('\n').first);
    }
    final existing = reviewFor(quarter);
    // Saving again keeps the decisions made the first time (those goals
    // are closed now, so they aren't on the screen any more).
    final earlier = {
      for (final e in (existing?.data['goals'] as Map? ?? const {}).entries)
        '${e.key}': '${e.value}'
    };
    final data = {
      'quarter': quarter,
      'wheel': wheel,
      'wins': wins.trim(),
      'lessons': lessons.trim(),
      'goals': {...earlier, ...goalDecisions},
      'next': nextFocus.trim(),
    };
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
      if (atMonth(l, month)) return l;
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
        ? area.copyWith(id: 'c_${_uid()}', custom: true)
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
  GrowthArea get suggestedArea => suggestedAreaFor(programMonth);

  /// What to grow in [month], from what happened: keep last month's area
  /// if it didn't move (or wasn't rated); else an area an active goal
  /// needs that hasn't had a month yet; else the lowest life area.
  GrowthArea suggestedAreaFor(int month) {
    if (!isBuiltInPerson) {
      final last = month > 1 ? focusArea(month - 1) : null;
      if (last != null) {
        final (start, end) = focusRatings(month - 1);
        if (end == null || (start != null && end <= start)) return last;
      }
      final focused = {
        for (var m = 1; m < month; m++)
          if (focusArea(m) case final a?) a.id
      };
      for (final g in activeGoals) {
        for (final a in (g.data['areas'] as List? ?? const [])) {
          if (!focused.contains('$a') && allGrowthAreas.any((x) => x.id == '$a')) {
            return areaById('$a');
          }
        }
      }
      if (lowestLifeArea?.template case final t?) return areaById(t);
      final own = customAreas;
      if (own.isNotEmpty) return own.first;
      return areaById('t_health');
    }
    return readinessGap == null ? growthAreas.first : areaById(readinessGap!.id);
  }

  /// Focuses on [areaId]; a template (`t_…`) first becomes an area of
  /// your own. Returns the id used.
  String focusOn(String areaId, {required int startRating, int? month}) {
    var id = areaId;
    if (areaTemplates.any((t) => t.id == areaId)) {
      final t = areaTemplates.firstWhere((t) => t.id == areaId);
      final existing = customAreas.where((a) => a.name == t.name);
      id = existing.isNotEmpty ? existing.first.id : saveCustomArea(t.copyWith(id: '')).id;
    }
    setFocus(id, startRating: startRating, month: month);
    return id;
  }

  /// One line on last month's area for choosing the next: name, start to
  /// end rating, reps. Null in the first month or without an area.
  String? monthGrowthLine(int month) {
    final a = focusArea(month);
    if (a == null) return null;
    final (start, end) = focusRatings(month);
    final reps = repsIn(a.id, month).length;
    return '${a.name}${start == null ? '' : ', $start→${end ?? '?'}'} · $reps rep${reps == 1 ? '' : 's'}';
  }

  /// Chooses this month's area, rated 1–5 where you are now.
  /// [month] defaults to this one; from day 27 the next can be chosen
  /// without touching the month being closed.
  void setFocus(String areaId, {required int startRating, int? month}) {
    month ??= programMonth;
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
  void rateFocusEnd(int rating, {int? month}) {
    final l = _focusLog(month ?? programMonth);
    if (l == null) return;
    updateLog(l.copyWith(data: {...l.data, 'end': rating}));
  }

  // ── Month review (for anyone) ────────────────────────────────────────

  /// The month to review: this one from day 27, otherwise the previous one
  /// during the first 5 days of a month.
  int? get monthToReview {
    if (!hasStarted) return null;
    if (programComplete) return programMonths;
    if (dayOfMonth >= 27) return programMonth;
    if (dayOfMonth <= 5 && programMonth > 1) return programMonth - 1;
    return null;
  }

  LogEntry? monthReviewFor(int month) {
    for (final l in logsOf('month_review')) {
      if (atMonth(l, month)) return l;
    }
    return null;
  }

  bool get monthReviewDue {
    final m = monthToReview;
    if (m == null || monthReviewFor(m) != null) return false;
    // One look back at a time: the quarterly review covers its last month,
    // and the end of the program has its own.
    if (programComplete) return false;
    if (quarterReviewDue && m == quarterToReview * 3) return false;
    return true;
  }

  /// Held days out of the days that counted (excused days left out).
  ({int held, int counted, Map<String, int> hard}) monthHeld(int month) {
    final from = monthStart(month), to = monthStart(month + 1);
    final today = dayOnly(_now);
    var held = 0, counted = 0;
    final hard = <String, int>{};
    for (var d = from; d.isBefore(to) && !d.isAfter(today); d = d.plusDays(1)) {
      final k = hardDayOn(d);
      if (k != null) hard[k] = (hard[k] ?? 0) + 1;
      if (isExcused(d)) continue;
      // Today is still open: it counts once it's held.
      if (d == today && !isHeld(d)) continue;
      counted++;
      if (isHeld(d)) held++;
    }
    return (held: held, counted: counted, hard: hard);
  }

  void saveMonthReview(int month, {required String carry, String lesson = ''}) {
    final existing = monthReviewFor(month);
    final data = {'month': month, 'lesson': lesson.trim()};
    if (existing == null) {
      addLog('month_review', text: carry.trim(), data: data);
    } else {
      updateLog(existing.copyWith(text: carry.trim(), data: {...existing.data, ...data}));
    }
  }

  /// What last month's review said to carry into this one, or null.
  String? get lastCarry {
    if (programMonth < 2) return null;
    final t = (monthReviewFor(programMonth - 1)?.text ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// The focus the last quarterly review set for this quarter, or null.
  String? get quarterFocus {
    if (programQuarter < 2) return null;
    final t = (reviewFor(programQuarter - 1)?.str('next') ?? '').trim();
    return t.isEmpty ? null : t;
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

  /// Reps of [drill] this week, toward [repsPerDrill].
  int drillRepsThisWeek(GrowthArea area, Drill drill, DateTime day) {
    final from = weekStartOf(day), to = from.plusDays(7);
    return logsOf('rep')
        .where((r) =>
            r.str('area') == area.id &&
            r.str('drill') == drill.title &&
            !r.date.isBefore(from) &&
            r.date.isBefore(to))
        .length;
  }

  static const repsPerDrill = 2;

  /// What the last rep in [area] said to do next time — where the next
  /// rep starts.
  String? lastNextStep(GrowthArea area) {
    for (final r in logsOf('rep')) {
      if (r.str('area') == area.id && (r.str('next') ?? '').trim().isNotEmpty) {
        return r.str('next')!.trim();
      }
    }
    return null;
  }

  // ── Which week the report closes ─────────────────────────────────────

  /// The week the Sunday report covers: this one, except on Monday and
  /// Tuesday while last week has no report — a busy Sunday shouldn't
  /// skip a week.
  /// Days of [anyDay]'s week since the journey began, up to today.
  int programDaysInWeek(DateTime anyDay) {
    if (!hasStarted) return 0;
    final today = dayOnly(_now);
    return [
      for (final d in weekDays(weekStartOf(anyDay)))
        if (!d.isBefore(journeyStart) && !d.isAfter(today)) d
    ].length;
  }

  /// A week is worth reviewing once it held three days of the program —
  /// someone who starts on a Saturday isn't asked to review two days.
  bool weekWorthReviewing(DateTime anyDay) => programDaysInWeek(anyDay) >= 3;

  DateTime reportWeekFor(DateTime now) {
    final thisWeek = weekStartOf(now);
    final lastWeek = thisWeek.minusDays(7);
    if (now.weekday <= DateTime.tuesday &&
        hasStarted &&
        weekWorthReviewing(lastWeek) &&
        reportForWeek(lastWeek) == null) {
      return lastWeek;
    }
    return thisWeek;
  }

  /// Monday or Tuesday, and last week still has no report.
  bool get lastWeekReportDue =>
      reportWeekFor(_now) != weekStartOf(_now);

  int repsInWeek(DateTime anyDay) {
    final from = weekStartOf(anyDay);
    return countBetween('rep', from, from.plusDays(7));
  }

  /// This week's drill: the first not practised earlier this month,
  /// rotating by week so each week brings a different one. Reps this week
  /// don't move it: a drill is practised more than once (deliberate
  /// practice is repetition with feedback, Ericsson 1993).
  Drill drillFor(GrowthArea area, DateTime day) {
    final weekFrom = weekStartOf(day);
    final done = {
      for (final r in repsIn(area.id, programMonth))
        if (r.date.isBefore(weekFrom)) r.str('drill')
    };
    // Monday weeks, like the reps counted against it: a program that began
    // on a Wednesday doesn't change the drill every Wednesday.
    final week = weekStartOf(day).daysSince(weekStartOf(programStart)) ~/ 7;
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
  /// Where a rep's feedback came from. Feedback is the part of
  /// deliberate practice with solid evidence (debriefs, Tannenbaum &
  /// Cerasoli 2013).
  static const feedbackSources = {
    'recording': 'A recording',
    'person': 'A person',
    'result': 'The result',
    'none': 'None',
  };

  void logRep(GrowthArea area, Drill drill,
          {required String did,
          String noticed = '',
          String lesson = '',
          String next = '',
          String subskill = '',
          String? feedbackFrom,
          bool? stretch}) =>
      addLog('rep', text: did.trim(), data: {
        'area': area.id,
        'drill': drill.title,
        'noticed': noticed.trim(),
        'lesson': lesson.trim(),
        'next': next.trim(),
        if (subskill.trim().isNotEmpty) 'subskill': subskill.trim(),
        if (feedbackFrom != null) 'feedback_from': feedbackFrom,
        if (stretch != null) 'stretch': stretch,
      });

  /// Reps this month whose feedback source was recorded as none, out of
  /// those that recorded one — (none, recorded).
  (int, int) repsWithoutFeedback(int month) {
    final reps = [
      for (final r in logsOf('rep'))
        if (!r.date.isBefore(monthStart(month)) && r.date.isBefore(monthStart(month + 1)) &&
            r.str('feedback_from') != null)
          r
    ];
    return (reps.where((r) => r.str('feedback_from') == 'none').length, reps.length);
  }

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
  /// Whether every current value was rated this week.
  bool valuesCheckDone(DateTime anyDay) {
    final r = valuesCheck(anyDay);
    return values.isNotEmpty && values.every((v) => r.containsKey(v.name));
  }

  Map<String, int> valuesCheck(DateTime anyDay) {
    final l = logsOn(weekStartOf(anyDay), 'values_check');
    if (l.isEmpty) return const {};
    return (l.last.data['ratings'] as Map? ?? const {})
        .map((k, v) => MapEntry('$k', (v as num).toInt()));
  }

  void saveValuesCheck(DateTime anyDay, Map<String, int> ratings) =>
      _upsertDayLog('values_check', weekStartOf(anyDay), {..._weekValues(anyDay), 'ratings': ratings});

  Map<String, dynamic> _weekValues(DateTime anyDay) {
    final l = logsOn(weekStartOf(anyDay), 'values_check');
    return l.isEmpty ? {} : {...l.last.data};
  }

  /// One small act of a value planned for the week of [anyDay]: living by
  /// what you value, not only naming it (values-consistent action, Tunç
  /// et al. 2023). (value, act, done — null until asked).
  ({String value, String act, bool? done})? valueAct(DateTime anyDay) {
    final d = _weekValues(anyDay);
    final act = '${d['act'] ?? ''}'.trim();
    if (act.isEmpty) return null;
    return (value: '${d['act_value'] ?? ''}', act: act, done: d['act_done'] as bool?);
  }

  void setValueAct(DateTime anyDay, {required String value, required String act}) =>
      _upsertDayLog('values_check', weekStartOf(anyDay), {
        ..._weekValues(anyDay),
        'act_value': value,
        'act': act.trim(),
      });

  void markValueAct(DateTime anyDay, bool done) {
    if (valueAct(anyDay) == null) return;
    _upsertDayLog('values_check', weekStartOf(anyDay), {..._weekValues(anyDay), 'act_done': done});
  }

  /// The value this week reflected least, if checked and below 4.
  String? valueGap(DateTime anyDay) {
    // Only values they still hold count.
    final names = {for (final v in values) v.name};
    final r = {
      for (final e in valuesCheck(anyDay).entries)
        if (names.contains(e.key)) e.key: e.value
    };
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
        b.writeln((f.str('from') ?? '').trim().isEmpty
            ? '• Feedback: "${f.text}"'
            : '• Feedback from ${f.str('from')}: "${f.text}"');
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
      _upsertDayLog('week_plan', weekStartOf(anyDay), {
        'outcomes': outcomes,
        'done': done..sort(),
        'goals': [for (var i = 0; i < 3; i++) weekOutcomeGoal(anyDay, i) ?? ''],
      });

  /// The goal a week outcome serves, if tagged.
  String? weekOutcomeGoal(DateTime anyDay, int i) {
    final raw = (_weekPlan(anyDay)?.data['goals'] as List?) ?? const [];
    final id = i < raw.length ? '${raw[i]}' : '';
    return id.isEmpty || goalById(id) == null ? null : id;
  }

  /// Tags outcome [i] with the goal it serves (null clears).
  void setWeekOutcomeGoal(DateTime anyDay, int i, String? goalId) {
    final goals = [for (var j = 0; j < 3; j++) weekOutcomeGoal(anyDay, j) ?? '']..[i] = goalId ?? '';
    _upsertDayLog('week_plan', weekStartOf(anyDay), {
      'outcomes': weekOutcomes(anyDay),
      'done': [for (var j = 0; j < 3; j++) if (weekOutcomeDone(anyDay, j)) j],
      'goals': goals,
    });
  }

  /// This week's outcomes that serve [goalId].
  int weekOutcomesFor(String goalId, DateTime anyDay) =>
      [for (var i = 0; i < 3; i++) if (weekOutcomeGoal(anyDay, i) == goalId && weekOutcomes(anyDay)[i].trim().isNotEmpty) i].length;

  /// The goal's next step: the one you named, else the first open
  /// milestone, else a Big 3 outcome serving it this week. Its if-then
  /// plan is for when the obstacle shows up, not a step.
  String? goalNextStep(LogEntry goal) {
    final named = (goal.str('next') ?? '').trim();
    if (named.isNotEmpty) return named;
    final m = milestonesOf(goal).where((m) => !m.done).firstOrNull;
    if (m != null) return m.text;
    final today = dayOnly(_now);
    for (var i = 0; i < 3; i++) {
      if (weekOutcomeGoal(today, i) == goal.id && !weekOutcomeDone(today, i)) {
        final o = weekOutcomes(today)[i].trim();
        if (o.isNotEmpty) return o;
      }
    }
    return null;
  }

  /// Up to three outcomes ONO proposes for [week]'s Big 3, so the week
  /// doesn't start from a blank page: the first goal's next step (linked
  /// to it), the growth area's drill, and what the latest feedback said to
  /// do — or, without it, the weakest daily item. Ones already planned
  /// are left out.
  List<({String text, String? goalId})> proposedOutcomes(DateTime week) {
    final planned = {
      for (final o in weekOutcomes(week))
        if (o.trim().isNotEmpty) o.trim().toLowerCase()
    };
    final out = <({String text, String? goalId})>[];
    void add(String text, [String? goalId]) {
      final t = text.trim();
      if (t.isEmpty || planned.contains(t.toLowerCase()) || out.any((x) => x.text == t)) return;
      out.add((text: t, goalId: goalId));
    }

    // The first goal with a step not already planned this week.
    for (final g in activeGoals) {
      final named = (g.str('next') ?? '').trim();
      final step = named.isNotEmpty
          ? named
          : milestonesOf(g).where((m) => !m.done).firstOrNull?.text ?? '';
      if (step.isEmpty || planned.contains(step.toLowerCase())) continue;
      add(step, g.id);
      break;
    }
    final area = focusArea();
    if (area != null) {
      add('${drillFor(area, week).title} — practise it twice');
      final heard = feedbackIn(area.id, programMonth)
          .map((f) => (f.str('action') ?? '').trim())
          .where((a) => a.isNotEmpty)
          .firstOrNull;
      if (heard != null) add(heard);
    }
    if (out.length < 3) {
      final last = weekDays(week.minusDays(7))
          .where((d) => !d.isBefore(programStart) && d.isBefore(dayOnly(_now)))
          .toList();
      if (last.length >= 3) {
        final rates = itemRates(last).entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final weakest = rates.isEmpty ? null : dailyItem(rates.first.key);
        if (weakest != null && rates.first.value < 0.7) {
          add('${weakest.title} on 5 of 7 days');
        }
      }
    }
    return out.take(3).toList();
  }

  /// Fills [week]'s empty Big 3 slots with [proposedOutcomes], linking
  /// goal ones to their goal. Returns how many were added.
  int useProposedOutcomes(DateTime week) {
    final proposals = proposedOutcomes(week);
    var n = 0;
    for (var i = 0; i < 3 && n < proposals.length; i++) {
      if (weekOutcomes(week)[i].trim().isNotEmpty) continue;
      final p = proposals[n++];
      setWeekOutcome(week, i, p.text);
      if (p.goalId != null) setWeekOutcomeGoal(week, i, p.goalId);
    }
    return n;
  }

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

  static const contactCadences = [7, 14, 30, 90, 365];

  /// Someone you've lost touch with — six months or more and not already
  /// overdue — at most one a week. People enjoy hearing from an old
  /// friend far more than we expect (Liu et al. 2022). Null once seen.
  LogEntry? reconnectSuggestion(DateTime day) {
    if (isDone(reconnectSeenKey(day))) return null;
    final due = {for (final p in peopleDue) p.id};
    final quiet = [
      for (final p in people)
        if (!due.contains(p.id) && daysSinceContact(p) >= 180) p
    ]..sort((a, b) => daysSinceContact(b).compareTo(daysSinceContact(a)));
    return quiet.firstOrNull;
  }

  String reconnectSeenKey(DateTime day) => 'reconnect:${dateKey(weekStartOf(day))}';

  /// The people he invests in, oldest first. A `person` log holds the
  /// name, role and how often (days) he wants contact.
  List<LogEntry> get people => logsOf('person').reversed.toList();

  LogEntry addPerson(String name, {String role = '', int every = 30}) =>
      addLog('person',
          text: name.trim(), data: {'role': role.trim(), 'every': every})!;

  /// Edit who they are and how often you want contact; the history stays.
  /// [askAbout] is what to ask next time ("how the exam went"), cleared
  /// when a touch is logged; [birthday] is 'MM-dd' or ''.
  void updatePerson(LogEntry person,
      {String? name, String? role, int? every, String? askAbout, String? birthday}) {
    final p = logsOf('person').where((x) => x.id == person.id).firstOrNull;
    if (p == null) return;
    updateLog(p.copyWith(
      text: name == null || name.trim().isEmpty ? p.text : name.trim(),
      data: {
        ...p.data,
        if (role != null) 'role': role.trim(),
        if (every != null) 'every': every,
        if (askAbout != null) 'ask_about': askAbout.trim(),
        if (birthday != null) 'birthday': birthday.trim(),
      },
    ));
  }

  LogEntry? personById(String id) =>
      logsOf('person').where((p) => p.id == id).firstOrNull;

  /// What to ask them about next time, or ''.
  String askAboutOf(LogEntry person) => person.str('ask_about') ?? '';

  /// Their birthday as (month, day), or null.
  (int, int)? birthdayOf(LogEntry person) {
    final b = (person.str('birthday') ?? '').split('-');
    if (b.length != 2) return null;
    final m = int.tryParse(b[0]), d = int.tryParse(b[1]);
    if (m == null || d == null || m < 1 || m > 12 || d < 1 || d > 31) return null;
    return (m, d);
  }

  /// People whose birthday is [day] or the day after.
  List<LogEntry> birthdaysSoon(DateTime day) {
    final today = dayOnly(day), tomorrow = today.plusDays(1);
    bool on(DateTime d, (int, int) b) => d.month == b.$1 && d.day == b.$2;
    return [
      for (final p in people)
        if (birthdayOf(p) case final b?)
          if (on(today, b) || on(tomorrow, b)) p
    ];
  }

  /// Whether [text] (a "to", "of" or "with" field) names [person]: their
  /// full name, or their first name when no one else on the list shares it.
  bool names(LogEntry person, String? text) {
    if (text == null || text.trim().isEmpty) return false;
    RegExp word(String w) =>
        RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false);
    if (word(person.text.trim()).hasMatch(text)) return true;
    final first = person.text.trim().split(' ').first;
    final shared = people
        .where((p) =>
            p.id != person.id &&
            p.text.trim().split(' ').first.toLowerCase() == first.toLowerCase())
        .isNotEmpty;
    return !shared && word(first).hasMatch(text);
  }

  /// What is open or recent between you and [person], for a look before
  /// you call: open promises to them, open asks, hard conversations, help.
  /// Each line is (what kind, the text, a date to show or null).
  List<(String, String, DateTime?)> betweenYou(LogEntry person) => [
        for (final p in openPromises)
          if (names(person, p.str('to')))
            (
              promiseOverdue(p) ? 'Promise, past its date' : 'You promised',
              p.text,
              DateTime.tryParse(p.str('by') ?? '')
            ),
        for (final a in openAsks)
          if (names(person, a.str('of'))) ('You asked for', a.text, a.date),
        if (conversations.where((c) => names(person, c.str('with'))).firstOrNull
            case final c?)
          c.str('status') == 'planned'
              ? ('Conversation to have', c.text, null)
              : (
                  'Last hard conversation',
                  '${c.text}${(c.str('learned') ?? '').isEmpty ? '' : ' — you learned: ${c.str('learned')}'}',
                  null
                ),
        if (helpsFor(person).firstOrNull case final h?)
          ('Last help', h.text, h.date),
        for (final a in adviceToReport)
          if (names(person, a.str('from')))
            ('Tell them how their advice went', '${a.text} — ${a.str('result') ?? ''}', null),
      ];

  /// Due people first (most overdue first), then the rest as added.
  List<LogEntry> get peopleByDue {
    final due = peopleDue;
    final ids = {for (final p in due) p.id};
    return [...due, for (final p in people) if (!ids.contains(p.id)) p];
  }

  void removePerson(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        logs: s.logs
            .where((l) =>
                l.id != id &&
                !((l.type == 'touch' || l.type == 'help') && l.str('person') == id) &&
                // Care you kept for them goes with them.
                !(l.type == 'upkeep' && l.str('for') == id))
            .toList()));
  }

  /// Contact with someone; [quality] 1 = distracted, 2 = okay, 3 = fully
  /// present. Presence, not just frequency, is what keeps people close.
  /// How long a contact lasted, in minutes: a call, an hour, an evening,
  /// a day. Closeness grows with time together — about 50 hours to a
  /// casual friend, 90 to a friend, 200+ to a close friend (Hall 2018).
  static const touchLengths = {
    15: 'A quick call',
    60: 'An hour',
    180: 'An evening',
    480: 'A day',
  };

  void logTouch(LogEntry person, {String note = '', int? quality, int? minutes, DateTime? date}) {
    addLog('touch', text: note.trim(), date: date, data: {
      'person': person.id,
      'name': person.text,
      if (quality != null) 'quality': quality,
      if (minutes != null && minutes > 0) 'minutes': minutes,
    });
    // The question was for this contact; it's asked now.
    final p = personById(person.id);
    if (p != null && askAboutOf(p).isNotEmpty) {
      updateLog(p.copyWith(data: {...p.data, 'ask_about': ''}));
    }
  }

  /// Hours together over the last [days] (90), from touches with a length.
  double hoursTogether(LogEntry person, {int days = 90}) {
    final from = dayOnly(_now).minusDays(days - 1);
    var minutes = 0;
    for (final t in logsOf('touch')) {
      if (t.str('person') == person.id && !t.date.isBefore(from)) {
        minutes += (t.number('minutes') ?? 0).toInt();
      }
    }
    return minutes / 60;
  }

  /// A ritual with this person ("Friday dinner, phones away"), or ''.
  String ritualOf(LogEntry person) => person.str('ritual') ?? '';

  // People you're helping grow: a team member, a mentee, a child. Helping
  // others learn deepens your own learning (the protégé effect, Nestojko et
  // al. 2014) and developing people is the core of leading.

  /// What they're working on and your next way to help.
  void setGrowing(LogEntry person, {required String workingOn, String nextHelp = ''}) {
    final p = logsOf('person').where((x) => x.id == person.id);
    if (p.isEmpty) return;
    updateLog(p.first.copyWith(data: {
      ...p.first.data,
      'growing': workingOn.trim(),
      'next_help': nextHelp.trim(),
    }));
  }

  List<LogEntry> get peopleGrowing => [
        for (final p in people)
          if ((p.str('growing') ?? '').isNotEmpty) p
      ];

  /// Records help given; the next way to help is cleared once done.
  void logHelp(LogEntry person, String what) {
    if (what.trim().isEmpty) return;
    addLog('help', text: what.trim(), data: {'person': person.id, 'name': person.text});
    final p = logsOf('person').where((x) => x.id == person.id);
    if (p.isNotEmpty && (p.first.str('next_help') ?? '') == what.trim()) {
      updateLog(p.first.copyWith(data: {...p.first.data, 'next_help': ''}));
    }
  }

  List<LogEntry> helpsFor(LogEntry person) =>
      [for (final h in logsOf('help')) if (h.str('person') == person.id) h];

  int helpsInMonth(LogEntry person, int month) {
    final from = monthStart(month), to = monthStart(month + 1);
    return helpsFor(person)
        .where((h) => !h.date.isBefore(from) && h.date.isBefore(to))
        .length;
  }

  // ── What you know about them ─────────────────────────────────────────

  /// What you can know about someone's world — Gottman's "love maps",
  /// and at work the same thing as understanding a stakeholder. Each is
  /// (key, the question, how it reads as something to ask).
  static const knowQuestions = [
    ('working_on', 'What are they working towards right now?', 'what they\'re working towards'),
    ('weighing', 'What is weighing on them lately?', 'what\'s weighing on them'),
    ('lifts', 'What gives them energy?', 'what gives them energy lately'),
    ('appreciated', 'How do they like to be appreciated?', 'how they like to be appreciated'),
    ('talk', 'How do they like to talk things through — and to disagree?', 'how they like to talk things through'),
    ('matters', 'Who and what matters most to them?', 'who and what matters most to them now'),
    ('coming', 'What is coming up for them?', 'what\'s coming up for them'),
  ];

  /// An answer older than this may have changed: ask again.
  static const knowStaleDays = 90;

  /// Their answer to [key] in your words, or ''. Stored flat on the
  /// person (`know:<key>`, `know_on:<key>`) so two devices merge each
  /// answer on its own.
  String knowAnswer(LogEntry person, String key) => person.str('know:$key') ?? '';

  DateTime? knowOn(LogEntry person, String key) =>
      DateTime.tryParse(person.str('know_on:$key') ?? '');

  /// Saves what you know; an empty answer clears it. The date is today's
  /// only when the answer changed.
  void setKnow(LogEntry person, String key, String answer) {
    final p = personById(person.id);
    if (p == null) return;
    final a = answer.trim();
    if (a == knowAnswer(p, key)) return;
    final data = {...p.data};
    if (a.isEmpty) {
      data.remove('know:$key');
      data.remove('know_on:$key');
    } else {
      data['know:$key'] = a;
      data['know_on:$key'] = dateKey(_now);
    }
    updateLog(p.copyWith(data: data));
  }

  int knownCount(LogEntry person) =>
      knowQuestions.where((q) => knowAnswer(person, q.$1).isNotEmpty).length;

  /// Answered long enough ago that it may no longer be true.
  bool knowStale(LogEntry person, String key) {
    final on = knowOn(person, key);
    return knowAnswer(person, key).isNotEmpty &&
        on != null &&
        dayOnly(_now).daysSince(on) >= knowStaleDays;
  }

  /// Something to ask next time you talk: the first thing you don't know
  /// yet, else the oldest answer that may have changed. Null when you're
  /// up to date. (key, how to ask it, whether it's asking again)
  (String, String, bool)? nextQuestionFor(LogEntry person) {
    for (final q in knowQuestions) {
      if (knowAnswer(person, q.$1).isEmpty) return (q.$1, q.$3, false);
    }
    final stale = [for (final q in knowQuestions) if (knowStale(person, q.$1)) q]
      ..sort((a, b) => knowOn(person, a.$1)!.compareTo(knowOn(person, b.$1)!));
    return stale.isEmpty ? null : (stale.first.$1, stale.first.$3, true);
  }

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

  /// Last contact: a touch or help logged for them, or a 1:1, a check-in
  /// for two, a finished hard conversation or a delivered gratitude letter
  /// naming them (full name, or first name when no one else shares it).
  DateTime? lastContact(LogEntry person) => _contacts[person.id];

  PersonalSystemState? _contactsState;
  Map<String, DateTime> _contactsIndex = const {};

  /// One pass over the logs per state: Today and the brief ask per person.
  Map<String, DateTime> get _contacts {
    if (identical(_contactsState, _state)) return _contactsIndex;
    _contactsState = _state;
    final m = <String, DateTime>{};
    void hit(String? id, DateTime d) {
      if (id == null) return;
      final x = m[id];
      if (x == null || d.isAfter(x)) m[id] = dayOnly(d);
    }

    final ps = people;
    final firstCount = <String, int>{};
    for (final p in ps) {
      final f = p.text.trim().split(' ').first.toLowerCase();
      firstCount[f] = (firstCount[f] ?? 0) + 1;
    }
    RegExp word(String w) =>
        RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false);
    final matchers = [
      for (final p in ps)
        (
          p.id,
          word(p.text.trim()),
          firstCount[p.text.trim().split(' ').first.toLowerCase()] == 1
              ? word(p.text.trim().split(' ').first)
              : null,
        )
    ];
    void byName(String? text, DateTime d) {
      if (text == null || text.trim().isEmpty) return;
      for (final (id, full, first) in matchers) {
        if (full.hasMatch(text) || (first?.hasMatch(text) ?? false)) hit(id, d);
      }
    }

    DateTime on(LogEntry l, String key) =>
        DateTime.tryParse(l.str(key) ?? '') ?? l.date;
    for (final l in _state?.logs ?? const <LogEntry>[]) {
      switch (l.type) {
        case 'touch' || 'help':
          hit(l.str('person'), l.date);
        case 'one_on_one':
          byName(l.str('with'), l.date);
        case 'us_checkin':
          byName(l.str('with'), l.createdAt);
        case 'conversation' when l.str('status') == 'done':
          byName(l.str('with'), on(l, 'done_on'));
        case 'gratitude' when l.str('status') == 'delivered':
          byName(l.str('to'), on(l, 'delivered'));
      }
    }
    return _contactsIndex = m;
  }

  /// Days since the last contact (or since he was added, if never).
  int daysSinceContact(LogEntry person) =>
      dayOnly(_now).daysSince(dayOnly(lastContact(person) ?? person.date));

  int cadenceOf(LogEntry person) => (person.number('every') ?? 30).toInt();

  /// Overdue people, most overdue (relative to their cadence) first.
  List<LogEntry> get peopleDue {
    final late = {
      for (final p in people)
        if (daysSinceContact(p) >= cadenceOf(p))
          p: daysSinceContact(p) / cadenceOf(p)
    };
    return late.keys.toList()..sort((a, b) => late[b]!.compareTo(late[a]!));
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
    final from = dayOnly(_now).minusDays(60);
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
    final from = dayOnly(_now).minusDays(60);
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
    return focusMinutesBetween(start, start.plusDays(7));
  }

  int get artifactMinutesThisMonth => focusMinutesBetween(
      monthStart(programMonth), monthStart(programMonth + 1),
      target: 'artifact');

  // ── Letters to future you ────────────────────────────────────────────

  /// Last day of the program (day 540).
  DateTime get programEnd => dateForProgramDay(programDays);

  /// First day of the next phase, or null in the last one.
  DateTime? get nextPhaseStart {
    final day = phase.toMonth * programDays ~/ 18 + 1;
    return day > programDays ? null : dateForProgramDay(day);
  }

  /// Sealed until [openOn]; written to the person he is becoming
  /// (future-self continuity, Hershfield 2011; Rutchick et al. 2018).
  /// [atEnd] seals it until the end of this program, wherever that falls
  /// (a length change, paused days or an early close move it).
  void writeLetter(String text, DateTime openOn, {bool atEnd = false}) =>
      addLog('letter', text: text.trim(), data: {
        'open_on': dateKey(openOn),
        'month': programMonth,
        if (atEnd) 'open_at': 'end',
      });

  List<LogEntry> get letters => logsOf('letter');

  DateTime letterOpensOn(LogEntry l) {
    if (l.str('open_at') == 'end') {
      // Written in an earlier program: that program has closed, so it's due.
      final written = (l.number('cycle') ?? 1).toInt();
      if (written < cycle) return dayOnly(l.date);
      return programEnd;
    }
    return DateTime.tryParse(l.str('open_on') ?? '') ?? programEnd;
  }

  /// Letters sealed for the end of this program and still closed.
  List<LogEntry> get lettersForTheEnd => [
        for (final l in letters)
          if (l.str('open_at') == 'end' && !letterIsOpen(l)) l
      ];

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
  PersonalSystemState? _patternsState;
  String _patternsKey = '';
  List<DayPattern> _patternsCache = const [];

  /// Cached for the same state, day and arguments: Me and the experiments
  /// screen ask on every build.
  List<DayPattern> patterns({int days = 60, int minDays = 5}) {
    final key = '${dateKey(_now)}|$days|$minDays';
    if (identical(_patternsState, _state) && _patternsKey == key) {
      return _patternsCache;
    }
    final result = _computePatterns(days: days, minDays: minDays);
    _patternsState = _state;
    _patternsKey = key;
    return _patternsCache = result;
  }

  List<DayPattern> _computePatterns({required int days, required int minDays}) {
    final today = dayOnly(_now);
    final from = [
      today.minusDays(days),
      programStart,
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    // Sick, skipped, rest and paused days say nothing about a habit.
    final range = [
      for (var d = from; d.isBefore(today); d = d.plusDays(1))
        if (!isExcused(d) && !isRestDay(d) && !isPaused(d)) d
    ];
    DateTime next(DateTime d) => d.plusDays(1);
    double? energy(DateTime d) => checkinFor(d)?.number('energy')?.toDouble();
    double? sleep(DateTime d) =>
        sleepHoursFor(d) ?? checkinFor(d)?.number('sleep')?.toDouble();
    // A minimum day's lower bar would read as a worse day.
    double? score(DateTime d) => isMinimumDay(d) ? null : scoreShare10(d);
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
        outcome: 'daily items held that day',
        unit: '/10',
        threshold: 0.5,
        when: (d) => sleep(d) == null ? null : sleep(d)! >= 7,
        measure: score);
    final items = {for (final i in dailyItems) i.id};
    if (items.contains('bed')) {
      compare(
        id: 'bed_energy',
        habit: 'In bed by 10:30',
        outcome: 'energy next morning',
        unit: '/5',
        threshold: 0.3,
        when: (d) => isChecked(d, 'bed'),
        measure: (d) => energy(next(d)));
    }
    if (items.contains('caffeine')) {
      compare(
        id: 'caffeine_sleep',
        habit: 'No caffeine after 1pm',
        outcome: 'sleep that night',
        unit: ' h',
        threshold: 0.25,
        when: (d) => isChecked(d, 'caffeine'),
        measure: (d) => sleep(next(d)));
    }
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
    if (items.contains('manifesto')) {
      compare(
        id: 'ritual_score',
        habit: 'Morning ritual',
        outcome: 'the other nine items',
        unit: '/9',
        threshold: 0.5,
        when: (d) => isChecked(d, 'manifesto'),
        measure: (d) => scoreWithout(d, 'manifesto'));
    }
    compare(
        id: 'energy_score',
        habit: 'Morning energy 4–5',
        outcome: 'daily items held that day',
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

  // ── Brag document ────────────────────────────────────────────────────

  /// Everything you achieved, for a review, a promotion or a CV: goals
  /// reached with what made them happen, wins by month, what others said,
  /// people you helped grow and what you learned and applied. Memory is
  /// unreliable at review time; a running record isn't.
  String bragText({DateTime? since}) {
    final from = since ?? journeyStart;
    bool after(LogEntry l) => !l.date.isBefore(from);
    final b = StringBuffer()
      ..writeln('${activeProfile.name} — what I\'ve done since ${dateKey(from)}')
      ..writeln(activeProfile.roleLine);
    final achieved = [
      for (final g in goals)
        if (g.str('status') == 'achieved' && (g.str('closed_on') ?? '').compareTo(dateKey(from)) >= 0) g
    ];
    if (achieved.isNotEmpty) {
      b
        ..writeln()
        ..writeln('GOALS REACHED');
      for (final g in achieved) {
        b.writeln('• ${g.text} (${g.str('closed_on')})');
        if ((g.str('reflection') ?? '').isNotEmpty) b.writeln('  How: ${g.str('reflection')}');
      }
    }
    final wins = [for (final w in logsOf('win')) if (after(w)) w];
    if (wins.isNotEmpty) {
      b
        ..writeln()
        ..writeln('WINS');
      String? month;
      for (final w in wins) {
        const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December'];
        final m = '${names[w.date.month - 1]} ${w.date.year}';
        if (m != month) {
          b.writeln(m);
          month = m;
        }
        b.writeln('• ${w.text}');
      }
    }
    final themes = [
      for (final r in logsOf('feedback_round'))
        if (after(r) && (r.str('themes') ?? '').isNotEmpty) r.str('themes')!
    ];
    final portrait = bestSelfPortrait;
    if (themes.isNotEmpty || portrait != null) {
      b
        ..writeln()
        ..writeln('WHAT OTHERS SAY');
      for (final t in themes) {
        b.writeln('• $t');
      }
      if (portrait != null) b.writeln('• At my best: $portrait');
    }
    final helped = [for (final h in logsOf('help')) if (after(h)) h];
    if (helped.isNotEmpty) {
      final names = {for (final h in helped) h.str('name') ?? ''}..remove('');
      b
        ..writeln()
        ..writeln('PEOPLE I HELPED GROW')
        ..writeln('• ${helped.length} time${helped.length == 1 ? '' : 's'}, ${names.length} ${names.length == 1 ? 'person' : 'people'}: ${names.join(', ')}');
    }
    final learned = [
      for (final l in learningWith('done'))
        if ((l.str('principle') ?? '').isNotEmpty &&
            (l.str('finished') ?? dateKey(l.date)).compareTo(dateKey(from)) >= 0)
          l
    ];
    if (learned.isNotEmpty) {
      b
        ..writeln()
        ..writeln('LEARNED AND APPLIED');
      for (final l in learned.take(8)) {
        b.writeln('• ${l.text}: ${l.str('principle')}');
      }
    }
    return b.toString().trim();
  }

  // ── Question of the day ──────────────────────────────────────────────

  /// Today's question, rotating through [dailyQuestions] by program day.
  (String area, String question) get questionOfTheDay =>
      dailyQuestions[(programDay < 1 ? 0 : programDay - 1) % dailyQuestions.length];

  /// Today's answer, if written.
  LogEntry? get questionAnswer {
    final q = questionOfTheDay.$2;
    return logsOn(dayOnly(_now), 'note').where((n) => n.str('question') == q).firstOrNull;
  }

  void answerQuestion(String answer) {
    if (answer.trim().isEmpty) return;
    final existing = questionAnswer;
    if (existing != null) {
      updateLog(existing.copyWith(text: answer.trim()));
    } else {
      addLog('note', text: answer.trim(), data: {'question': questionOfTheDay.$2});
    }
  }

  // ── How to work with me ──────────────────────────────────────────────

  /// A personal user manual to share with a team, a partner or a coach:
  /// drafted from what ONO knows, then edited in your own words.
  static const manualSections = [
    ('best', 'When I\'m at my best'),
    ('values', 'What I care about'),
    ('energy', 'When to catch me'),
    ('communication', 'How I like to communicate'),
    ('feedback', 'How to give me feedback'),
    ('watch', 'What to watch for when I\'m stretched'),
  ];

  LogEntry? get manual {
    final l = logsOf('manual');
    return l.isEmpty ? null : l.first;
  }

  /// The saved text of a section, or a draft from your data.
  String manualSection(String key) {
    final saved = manual?.str(key);
    if (saved != null) return saved;
    return switch (key) {
      'best' => bestSelfPortrait ?? '',
      'values' => values.map((v) => v.meaning.isEmpty ? v.name : '${v.name}: ${v.meaning}').join('\n'),
      'energy' => energyPeak == null
          ? ''
          : 'I\'m sharpest in the ${energyPeak!.label.toLowerCase()} (${energyPeak!.from}:00–${energyPeak!.to}:00). Bring hard problems then.',
      _ => '',
    };
  }

  void saveManual(Map<String, String> sections) {
    final data = {for (final e in sections.entries) e.key: e.value.trim()};
    final m = manual;
    if (m == null) {
      addLog('manual', data: data);
    } else {
      updateLog(m.copyWith(date: dayOnly(_now), data: data));
    }
  }

  String manualText() {
    final b = StringBuffer('How to work with ${activeProfile.firstName.isEmpty ? 'me' : activeProfile.firstName}\n');
    for (final s in manualSections) {
      final t = manualSection(s.$1).trim();
      if (t.isEmpty) continue;
      b
        ..writeln()
        ..writeln(s.$2)
        ..writeln(t);
    }
    return b.toString().trim();
  }

  // ── Couple check-in ──────────────────────────────────────────────────

  /// A weekly 20-minute check-in with a partner: appreciation first, then
  /// what's been hard, what each needs, and one plan together. Small
  /// rituals of connection and expressed appreciation keep relationships
  /// strong (Gottman & Silver 1999).
  static const usQuestions = [
    ('appreciate', 'Something I appreciated about you this week'),
    ('hard', 'What was hard for me this week'),
    ('need', 'What I need from you next week'),
    ('plan', 'One thing we\'ll do together'),
  ];

  void logUsCheckin(String partnerName, Map<String, String> answers) {
    if (answers.values.every((a) => a.trim().isEmpty)) return;
    _upsertDayLog('us_checkin', weekStartOf(_now), {
      'with': partnerName.trim(),
      for (final e in answers.entries) e.key: e.value.trim(),
    });
  }

  LogEntry? usCheckinFor(DateTime anyDay) {
    final l = logsOn(weekStartOf(anyDay), 'us_checkin');
    return l.isEmpty ? null : l.last;
  }

  /// Weeks in a row (up to this one or last) with a check-in.
  int get usStreak {
    var n = 0;
    var w = weekStartOf(_now);
    if (usCheckinFor(w) == null) w = w.minusDays(7);
    while (usCheckinFor(w) != null) {
      n++;
      w = w.minusDays(7);
    }
    return n;
  }

  // ── Your first week ──────────────────────────────────────────────────

  /// One small step a day for the first week of a first program, each
  /// introducing one core practice — instead of every tool on day one.
  /// Starting small and adding one thing at a time keeps people going
  /// (Fogg 2019; choice overload: Iyengar & Lepper 2000).
  static const firstWeekSteps = [
    ('items', 'Tick one daily item', 'Tick one in your list below. Small is the point.', ''),
    ('checkin', 'Do the morning check-in', 'Thirty seconds that tell you what today can ask of you.', '/checkin'),
    ('week', 'Set this week\'s three outcomes', 'Three things that would make the week a win.', '/week'),
    ('shutdown', 'Close one evening with the shutdown', 'Tomorrow\'s three on paper, then let the day go.', '/shutdown'),
    ('people', 'Add two people who matter', 'Who you want to stay close to, and how often.', '/people'),
    ('rep', 'Practise once in your growth area', 'One real rep, then write what you noticed.', '/growth'),
    ('review', 'Look back at your first week', 'Five answers; next week\'s brief comes back.', '/weekly-coaching'),
  ];

  static const firstWeekOffKey = 'firstweek:off';

  /// "Not now" on a first-week step: the guide moves on to the next.
  void skipFirstWeekStep(String id) => setDone('firstweek:skip:$id', true);

  /// Whether [step] is done, judged from what was actually logged.
  bool firstWeekDone(String step) {
    final s = _state;
    if (s == null) return false;
    final from = dateKey(programStart);
    return switch (step) {
      'items' => s.dailyChecks.entries
          .any((e) => e.key.compareTo(from) >= 0 && e.value.isNotEmpty),
      'checkin' => logsOf('checkin').isNotEmpty,
      'week' => logsOf('week_plan').any((l) =>
          ((l.data['outcomes'] as List?) ?? const []).any((o) => '$o'.trim().isNotEmpty)),
      'shutdown' => logsOf('shutdown').isNotEmpty,
      'people' => logsOf('person').length >= 2,
      'rep' => logsOf('rep').isNotEmpty,
      'review' => reports.isNotEmpty,
      _ => false,
    };
  }

  /// Steps done of the seven.
  int get firstWeekProgress =>
      firstWeekSteps.where((x) => firstWeekDone(x.$1)).length;

  /// Today's step: the first one not done among those unlocked so far
  /// (one more each day). Only in a first program's first two weeks.
  ({int index, String id, String title, String why, String route})? get firstWeekStep {
    if (!hasStarted || cycle > 1 || programDay > 14 || isDone(firstWeekOffKey)) {
      return null;
    }
    final unlocked = programDay.clamp(1, firstWeekSteps.length);
    for (var i = 0; i < unlocked; i++) {
      final x = firstWeekSteps[i];
      // The look back belongs to a real Sunday after a few days, not to a
      // Wednesday that happens to be day 7.
      if (x.$1 == 'review' &&
          !(_now.weekday == DateTime.sunday && weekWorthReviewing(_now))) {
        continue;
      }
      if (isDone('firstweek:skip:${x.$1}')) continue;
      if (!firstWeekDone(x.$1)) {
        return (index: i, id: x.$1, title: x.$2, why: x.$3, route: x.$4);
      }
    }
    return null;
  }

  // ── Year in review ───────────────────────────────────────────────────

  /// The questions for closing a calendar year, in order. The last, the
  /// word for next year, is the log's text.
  static const yearQuestions = [
    ('proud', 'What are you proudest of this year?'),
    ('hard', 'What was hardest — and how did you get through it?'),
    ('learned', 'What did the year teach you?'),
    ('thanks', 'Who do you want to thank, and for what?'),
    ('letgo', 'What are you leaving behind?'),
    ('hold', 'Next year: the one thing that must hold'),
  ];

  /// The calendar year to look back on: this one from 15 December, the
  /// last one until 15 January — if ONO was used in it.
  int? get yearToReview {
    if (!hasStarted) return null;
    final d = dayOnly(_now);
    final year = d.month == 12 && d.day >= 15
        ? d.year
        : d.month == 1 && d.day <= 15
            ? d.year - 1
            : null;
    if (year == null || journeyStart.year > year) return null;
    return year;
  }

  /// The year the review screen shows: the one to close in season,
  /// otherwise last year if ONO was used in it, otherwise this year so far.
  int get yearOnScreen {
    if (yearToReview case final y?) return y;
    final last = _now.year - 1;
    return hasStarted && journeyStart.year <= last ? last : _now.year;
  }

  /// A year can be closed once it's ending: from 15 December, or any time
  /// after it. Closing it earlier would hide December's prompt.
  bool canCloseYear(int year) => year < _now.year || yearToReview == year;

  LogEntry? yearReviewFor(int year) =>
      logsOf('year_review').where((l) => l.number('year') == year).firstOrNull;

  bool get yearReviewDue =>
      yearToReview != null && yearReviewFor(yearToReview!) == null;

  /// The word chosen for this year in last year's review.
  String? get wordForTheYear {
    final t = yearReviewFor(_now.year - 1)?.text ?? '';
    return t.isEmpty ? null : t;
  }

  /// What [year] added up to, from the day ONO started (or 1 January) to
  /// 31 December (or today).
  ({
    int held,
    int counted,
    int wins,
    int goalsReached,
    int reps,
    int focusHours,
    int kindActs,
    int promisesKept,
    List<String> lessons,
    List<String> topWins,
  }) yearSummary(int year) {
    final first = DateTime(year), next = DateTime(year + 1);
    bool inYear(DateTime d) => !d.isBefore(first) && d.isBefore(next);
    bool closedIn(LogEntry l) {
      final c = DateTime.tryParse(l.str('closed_on') ?? '');
      return c != null && inYear(c);
    }
    final today = dayOnly(_now);
    final from = journeyStart.isAfter(first) ? dayOnly(journeyStart) : first;
    var held = 0, counted = 0;
    for (var d = from; d.isBefore(next) && !d.isAfter(today); d = d.plusDays(1)) {
      if (isExcused(d)) continue;
      if (d == today && !isHeld(d)) continue;
      counted++;
      if (isHeld(d)) held++;
    }
    final wins = [for (final w in logsOf('win')) if (inYear(w.date)) w];
    final reached = goals.where((g) => g.str('status') == 'achieved' && closedIn(g)).length;
    var minutes = 0;
    for (final f in logsOf('focus')) {
      if (inYear(f.date)) minutes += (f.number('minutes') ?? 0).toInt();
    }
    final lessons = [
      // A month's lesson belongs to the year the month started in, not to
      // the day it was written (December is often closed in January).
      for (final r in logsOf('month_review').reversed)
        if (inYear(cycleOf(r) == cycle && r.number('month') != null
                ? monthStart(r.number('month')!.toInt())
                : r.date) &&
            (r.str('lesson') ?? '').trim().isNotEmpty)
          r.str('lesson')!.trim(),
      for (final r in logsOf('quarterly_review').reversed)
        if (inYear(r.date) && (r.str('lessons') ?? '').trim().isNotEmpty) r.str('lessons')!.trim(),
    ];
    return (
      held: held,
      counted: counted,
      wins: wins.length,
      goalsReached: reached,
      reps: logsOf('rep').where((r) => inYear(r.date)).length,
      focusHours: minutes ~/ 60,
      kindActs: logsOf('kindness').where((k) => inYear(k.date)).length,
      promisesKept: logsOf('promise').where((p) => p.str('status') == 'kept' && closedIn(p)).length,
      lessons: lessons,
      // Oldest first reads like the year it was.
      topWins: [for (final w in wins.reversed) w.text],
    );
  }

  /// Saves (or updates) the review of [year]: the answers to
  /// [yearQuestions] and one word for next year.
  bool saveYearReview(int year, {required Map<String, String> answers, String word = ''}) {
    if (!canCloseYear(year)) return false;
    final existing = yearReviewFor(year);
    final data = {
      'year': year,
      for (final q in yearQuestions)
        if ((answers[q.$1] ?? '').trim().isNotEmpty) q.$1: answers[q.$1]!.trim(),
    };
    if (existing == null) {
      addLog('year_review', text: word.trim(), data: data);
    } else {
      updateLog(existing.copyWith(text: word.trim(), data: data));
    }
    return true;
  }

  // ── Ask for help ─────────────────────────────────────────────────────

  /// How an ask ended.
  static const askOutcomes = {
    'yes': 'Yes',
    'partly': 'Partly',
    'no': 'No',
    'none': 'No answer',
  };

  /// People guess that about half as many others will say yes as actually
  /// do (Flynn & Lake 2008). Writing down the guess, then the answer,
  /// corrects it with your own numbers.
  void addAsk({required String what, String of = '', int guess = 50}) {
    addLog('ask', text: what.trim(), data: {
      'of': of.trim(),
      'guess': guess.clamp(0, 100),
      'status': 'asked',
    });
  }

  // ── Advice: ask, try, report back ────────────────────────────────────

  /// Advice someone gave you, and what became of it. Asking for advice
  /// makes people see you as more competent, not less (Brooks et al.
  /// 2015); telling them later how it worked is what turns advice into a
  /// relationship.
  static const adviceStatuses = {
    'new': 'To try',
    'trying': 'Trying it',
    'tried': 'Tried',
    'skipped': 'Not for me',
  };

  LogEntry? addAdvice({required String advice, String from = '', String about = ''}) =>
      advice.trim().isEmpty
          ? null
          : addLog('advice', text: advice.trim(), data: {
              'from': from.trim(),
              'about': about.trim(),
              'status': 'new',
            });

  List<LogEntry> get adviceLog => logsOf('advice');

  void setAdviceStatus(String id, String status, {String? result}) {
    final l = adviceLog.where((x) => x.id == id).firstOrNull;
    if (l == null || !adviceStatuses.containsKey(status)) return;
    updateLog(l.copyWith(data: {
      ...l.data,
      'status': status,
      if (result != null) 'result': result.trim(),
      if (status == 'tried' || status == 'skipped') 'closed_on': dateKey(_now),
    }));
  }

  /// You told them how it went.
  void markAdviceReported(String id, bool reported) {
    final l = adviceLog.where((x) => x.id == id).firstOrNull;
    if (l == null) return;
    updateLog(l.copyWith(data: {...l.data, 'reported': reported}));
  }

  /// Tried, from someone named, and they haven't heard how it went.
  List<LogEntry> get adviceToReport => [
        for (final l in adviceLog)
          if (l.str('status') == 'tried' &&
              (l.str('from') ?? '').isNotEmpty &&
              l.data['reported'] != true)
            l
      ];

  /// Advice written down a week ago or more and not yet tried.
  List<LogEntry> get adviceWaiting {
    final cutoff = dayOnly(_now).minusDays(7);
    return [
      for (final l in adviceLog)
        if ((l.str('status') ?? 'new') == 'new' && !dayOnly(l.date).isAfter(cutoff)) l
    ];
  }

  List<LogEntry> get openAsks => [
        for (final a in logsOf('ask'))
          if (a.str('status') == 'asked') a
      ];

  /// Asks made two or more days ago with no answer noted.
  List<LogEntry> get asksToClose {
    final cutoff = dayOnly(_now).minusDays(2);
    return [for (final a in openAsks) if (!dayOnly(a.date).isAfter(cutoff)) a];
  }

  void closeAsk(String id, String outcome) {
    final a = logsOf('ask').where((l) => l.id == id).firstOrNull;
    if (a == null || !askOutcomes.containsKey(outcome)) return;
    updateLog(a.copyWith(data: {...a.data, 'status': outcome, 'closed_on': dateKey(_now)}));
  }

  /// Answered asks in the last [days]: how many, how many got a yes (a
  /// partial yes counts), and the average guess; null until three.
  ({int asked, int yes, int guess})? askRecord({int days = 180}) {
    final from = dayOnly(_now).minusDays(days);
    var asked = 0, yes = 0, guess = 0;
    for (final a in logsOf('ask')) {
      final st = a.str('status');
      // No answer isn't a no: it stays out of the record.
      if (st == null || st == 'asked' || st == 'none' || a.date.isBefore(from)) {
        continue;
      }
      asked++;
      if (st == 'yes' || st == 'partly') yes++;
      guess += (a.number('guess') ?? 50).toInt();
    }
    if (asked < 3) return null;
    return (asked: asked, yes: yes, guess: (guess / asked).round());
  }

  int asksInWeek(DateTime anyDay) {
    final from = weekStartOf(anyDay);
    return countBetween('ask', from, from.plusDays(7));
  }

  // ── Journal export ───────────────────────────────────────────────────

  /// Everything you wrote to learn from — wins, lessons, reflections,
  /// reviews, letters you've opened — as readable text, newest first. Yours
  /// to keep outside ONO.
  String journalText() {
    final b = StringBuffer()
      ..writeln('${activeProfile.name} — journal from ONO')
      ..writeln('Exported ${dateKey(_now)}')
      ..writeln();
    String line(LogEntry l) {
      String f(String k) => (l.str(k) ?? '').trim();
      return switch (l.type) {
        'win' => 'Win: ${l.text}${f('why').isEmpty ? '' : ' (why: ${f('why')})'}',
        'rep' => 'Practice — ${f('drill')}: ${l.text}${f('noticed').isEmpty ? '' : '\n  Noticed: ${f('noticed')}'}${f('lesson').isEmpty ? '' : '\n  Lesson: ${f('lesson')}'}',
        'note' => 'Note: ${l.text}',
        'feynman' => 'From memory (${f('book')}): ${l.text}',
        'month_review' => 'Month ${l.number('month')} review: ${l.text}${f('lesson').isEmpty ? '' : '\n  Lesson: ${f('lesson')}'}',
        'quarterly_review' => 'Quarter ${l.number('quarter')} review — next: ${l.text}${f('wins').isEmpty ? '' : '\n  Wins: ${f('wins')}'}${f('lessons').isEmpty ? '' : '\n  Lessons: ${f('lessons')}'}',
        'setback' => 'Setback: ${l.text}${f('next').isEmpty ? '' : '\n  Next step: ${f('next')}'}',
        'stepback' => 'Stepped back: ${l.text}${f('advice').isEmpty ? '' : '\n  Advice: ${f('advice')}'}',
        'conversation' => 'Conversation with ${f('with')} — ${l.text}${f('learned').isEmpty ? '' : '\n  Learned: ${f('learned')}'}',
        'feedback' => 'Feedback: ${l.text}',
        'learning' => f('principle').isEmpty ? '' : 'Learned from ${l.text}: ${f('principle')}',
        'letter' => letterIsOpen(l) ? 'Letter to myself (opened): ${l.text}' : '',
        'gratitude' => 'Gratitude letter to ${f('to')}: ${l.text}',
        'shutdown' => f('open').isEmpty ? '' : 'Evening, on my mind: ${f('open')}',
        'thought' => 'Checked a thought: ${l.text}${f('balanced').isEmpty ? '' : '\n  More balanced: ${f('balanced')}'}',
        'kindness' => 'Kindness: ${l.text}',
        'compassion' => 'Was on my own side about: ${l.text}${f('kind').isEmpty ? '' : '\n  I told myself: ${f('kind')}'}',
        'courage' => f('status') == 'done' ? 'Did what I had avoided: ${l.text} (feared ${l.number('fear')}, felt ${l.number('felt')})${f('happened').isEmpty ? '' : '\n  What happened: ${f('happened')}'}' : '',
        'advice' => f('status') == 'tried' ? 'Tried advice${f('from').isEmpty ? '' : ' from ${f('from')}'}: ${l.text}${f('result').isEmpty ? '' : ' — ${f('result')}'}' : '',
        'strength_use' => 'Used ${f('strength')}: ${l.text}',
        'year_review' => 'Looked back at ${l.number('year')}:${[for (final q in yearQuestions) if (f(q.$1).isNotEmpty) '\n  ${q.$2} ${f(q.$1)}'].join()}${l.text.isEmpty ? '' : '\n  Word for next year: ${l.text}'}',
        'ask' => 'Asked ${f('of').isEmpty ? '' : '${f('of')} '}for help: ${l.text}${f('status') == 'asked' ? '' : ' — ${askOutcomes[f('status')] ?? f('status')}'}',
        'story' => 'Story: ${l.text}${f('result').isEmpty ? '' : '\n  Result: ${f('result')}'}',
        'program_cycle' => 'Closed program ${l.number('number')} (${l.number('held')} of ${l.number('counted')} days held)${l.text.isEmpty ? '' : '\n  What changed: ${l.text}'}${f('carry').isEmpty ? '' : '\n  Taking with me: ${f('carry')}'}',
        'aar' => 'Looked back at ${l.text}${f('sustain').isEmpty ? '' : '\n  Keep: ${f('sustain')}'}${f('improve').isEmpty ? '' : '\n  Change: ${f('improve')}'}${f('friend').isEmpty ? '' : '\n  To a friend: ${f('friend')}'}',
        'best_future' => 'My best possible future in ${l.number('years')} years:${[for (final a in bestFutureAreas) if ((l.data['areas'] as Map?)?[a.$1] != null) '\n  ${a.$2}: ${(l.data['areas'] as Map)[a.$1]}'].join()}${l.text.isEmpty ? '' : '\n  This week: ${l.text}'}',
        'life_story' => 'My life in chapters:${[for (final c in lifeChapters) '\n  ${c['title']}${(c['years'] ?? '').isEmpty ? '' : ' (${c['years']})'}${(c['taught'] ?? '').isEmpty ? '' : ' — taught me: ${c['taught']}'}'].join()}${f('next').isEmpty ? '' : '\n  Next chapter: ${f('next')}'}',
        _ => '',
      };
    }
    String? lastDay;
    for (final l in allLogs()) {
      final t = line(l);
      if (t.isEmpty) continue;
      final d = dateKey(l.date);
      if (d != lastDay) {
        b
          ..writeln()
          ..writeln(d);
        lastDay = d;
      }
      b.writeln(t);
    }
    return b.toString().trim();
  }

  // ── Thought check (CBT thought record) ───────────────────────────────

  /// Feelings offered on the thought check; the person can type their own.
  static const thoughtFeelings = [
    'Anxious', 'Sad', 'Angry', 'Ashamed', 'Guilty', 'Hurt', 'Overwhelmed',
  ];

  /// A thought put to the test: the situation, the thought, the feeling
  /// and how strong it was (0–100), the evidence for and against, a more
  /// balanced thought, and the feeling again. Cognitive restructuring is
  /// the core of CBT (Beck 1979; Hofmann et al. 2012, meta-analysis).
  LogEntry? logThought({
    required String situation,
    required String thought,
    String feeling = '',
    int? before,
    String evidenceFor = '',
    String evidenceAgainst = '',
    String balanced = '',
    int? after,
  }) {
    if (thought.trim().isEmpty) return null;
    return addLog('thought', text: thought.trim(), data: {
      'situation': situation.trim(),
      'feeling': feeling.trim(),
      'before': before,
      'for': evidenceFor.trim(),
      'against': evidenceAgainst.trim(),
      'balanced': balanced.trim(),
      'after': after,
    });
  }

  List<LogEntry> get thoughts => logsOf('thought');

  /// How much a check took the edge off, on average (points of 0–100,
  /// from before to after) over the last 30 days; null under 2 checks.
  double? get thoughtRelief {
    final from = dayOnly(_now).minusDays(30);
    final drops = [
      for (final t in thoughts)
        if (!t.date.isBefore(from) &&
            t.number('before') != null &&
            t.number('after') != null)
          t.number('before')! - t.number('after')!,
    ];
    if (drops.length < 2) return null;
    return drops.reduce((a, b) => a + b) / drops.length;
  }

  int thoughtsInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('thought', week, week.plusDays(7));
  }

  // ── Best possible future (King 2001) ─────────────────────────────────

  /// The areas the best-possible-future writing walks through.
  static const bestFutureAreas = [
    ('work', 'Work and what you build'),
    ('people', 'The people around you'),
    ('body', 'Your health and energy'),
    ('self', 'Who you have become'),
  ];

  /// Writing about your life when things have gone as well as they
  /// realistically could raises optimism and positive mood (King 2001;
  /// Meevissen et al. 2011; Carrillo et al. 2019, meta-analysis). Each
  /// writing is kept, so it can be done again.
  void saveBestFuture({
    required int years,
    required Map<String, String> areas,
    String step = '',
  }) {
    final filled = {
      for (final e in areas.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
    };
    if (filled.isEmpty) return;
    addLog('best_future', text: step.trim(), data: {
      'years': years,
      'areas': filled,
    });
  }

  LogEntry? get bestFuture {
    final l = logsOf('best_future');
    return l.isEmpty ? null : l.first;
  }

  // ── Kindness day (Lyubomirsky, Sheldon & Schkade 2005) ───────────────

  /// Five acts of kindness on one day a week raised well-being; the same
  /// acts spread over the week did not.
  static const kindnessPerDay = 5;

  /// The weekday chosen for kindness, or null.
  int? get kindnessDay {
    final l = logsOf('kindness_plan');
    return l.isEmpty ? null : l.first.number('weekday')?.toInt();
  }

  void setKindnessDay(int? weekday) {
    final s = _state;
    if (s == null) return;
    final rest = s.logs.where((l) => l.type != 'kindness_plan').toList();
    if (weekday == null) {
      _update(s.copyWith(logs: rest));
      return;
    }
    _update(s.copyWith(logs: [
      ...rest,
      _entry('kindness_plan', _now, data: {'weekday': weekday}),
    ]));
  }

  void logKindness(String act, {DateTime? day}) {
    if (act.trim().isEmpty) return;
    addLog('kindness', date: day ?? _now, text: act.trim());
  }

  List<LogEntry> kindnessOn(DateTime day) => logsOn(day, 'kindness');

  int kindnessInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('kindness', week, week.plusDays(7));
  }

  /// Today is the kindness day and the five aren't done yet.
  bool kindnessDue(DateTime day) =>
      kindnessDay == day.weekday && kindnessOn(day).length < kindnessPerDay;

  // ── Worry time (Borkovec et al. 1983) ────────────────────────────────

  /// Worries are parked when they come and dealt with in one short slot
  /// a day; postponing worry reduces it (Borkovec et al. 1983; McGowan &
  /// Behar 2013, RCT).
  static const worryOutcomes = {
    'acted': 'A next step',
    'let_go': 'Let it go',
    'keep': 'Keep for tomorrow',
  };

  /// Minutes after midnight of the daily worry slot, or null.
  int? get worryTime {
    final l = logsOf('worry_plan');
    return l.isEmpty ? null : l.first.number('minute')?.toInt();
  }

  void setWorryTime(int? minuteOfDay) {
    final s = _state;
    if (s == null) return;
    final rest = s.logs.where((l) => l.type != 'worry_plan').toList();
    _update(s.copyWith(logs: [
      ...rest,
      if (minuteOfDay != null)
        _entry('worry_plan', _now, data: {'minute': minuteOfDay}),
    ]));
    _syncReminders();
  }

  void parkWorry(String worry) {
    if (worry.trim().isEmpty) return;
    final first = parkedWorries.isEmpty;
    addLog('worry', text: worry.trim(), data: {'status': 'parked'});
    // The worry-time reminder only exists while something is parked.
    if (first) _syncReminders();
  }

  /// Parked worries, oldest first (the order they are dealt with).
  List<LogEntry> get parkedWorries =>
      logsOf('worry').where((w) => w.str('status') == 'parked').toList().reversed.toList();

  /// [outcome] from [worryOutcomes]. A next step becomes today's first
  /// open priority, as after a setback.
  void resolveWorry(String id, {required String outcome, String step = ''}) {
    final w = logsOf('worry').where((l) => l.id == id).firstOrNull;
    if (w == null) return;
    if (outcome == 'keep') {
      updateLog(w.copyWith(data: {...w.data, 'kept_on': dateKey(_now)}));
      return;
    }
    updateLog(w.copyWith(data: {
      ...w.data,
      'status': outcome,
      'step': step.trim(),
      'resolved_on': dateKey(_now),
    }));
    if (parkedWorries.isEmpty) _syncReminders();
    if (outcome != 'acted' || step.trim().isEmpty) return;
    addToTodayPriorities(step);
  }

  /// The worry slot has come and something is parked.
  bool worryTimeDue(DateTime now) => worriesDue(now).isNotEmpty;

  /// Parked worries to deal with now: the slot has come, they were parked
  /// before it, and they weren't kept for tomorrow today.
  List<LogEntry> worriesDue(DateTime now) {
    final t = worryTime;
    if (t == null || now.hour * 60 + now.minute < t) return const [];
    final slot = DateTime(now.year, now.month, now.day, t ~/ 60, t % 60);
    final today = dateKey(now);
    return [
      for (final w in parkedWorries)
        if (w.createdAt.isBefore(slot) && w.str('kept_on') != today) w
    ];
  }

  // ── Life chapters (narrative identity) ───────────────────────────────

  /// Your life as chapters, each with a high point, a low point and what
  /// it taught, then the chapter you're in and the next one's title.
  /// Telling your story with growth and agency goes with well-being
  /// (McAdams & McLean 2013; Adler 2012).
  LogEntry? get lifeStory {
    final l = logsOf('life_story');
    return l.isEmpty ? null : l.first;
  }

  List<Map<String, String>> get lifeChapters => [
        for (final c in (lifeStory?.data['chapters'] as List?) ?? const [])
          {
            for (final e in Map<String, dynamic>.from(c as Map).entries)
              e.key: '${e.value ?? ''}',
          },
      ];

  void saveLifeStory({
    required List<Map<String, String>> chapters,
    String now = '',
    String next = '',
  }) {
    final kept = [
      for (final c in chapters)
        // A chapter with any of it written is kept, titled or not.
        if (c.values.any((v) => v.trim().isNotEmpty))
          {for (final e in c.entries) e.key: e.value.trim()},
    ];
    final data = {'chapters': kept, 'now': now.trim(), 'next': next.trim()};
    final existing = lifeStory;
    if (existing == null) {
      addLog('life_story', data: data);
    } else {
      updateLog(existing.copyWith(data: data));
    }
  }

  // ── Signature strengths (Seligman et al. 2005) ───────────────────────

  /// The 24 character strengths of the VIA classification (Peterson &
  /// Seligman 2004), each with a plain description.
  static const characterStrengths = <String, String>{
    'Creativity': 'New and useful ways of doing things',
    'Curiosity': 'Interest in everything, asking why',
    'Judgment': 'Thinking things through, weighing evidence',
    'Love of learning': 'Mastering new skills and knowledge',
    'Perspective': 'Giving wise counsel, seeing the big picture',
    'Bravery': 'Not shrinking from threat or difficulty',
    'Perseverance': 'Finishing what you start',
    'Honesty': 'Speaking the truth, being genuine',
    'Zest': 'Approaching life with energy',
    'Love': 'Valuing close relationships',
    'Kindness': 'Doing good for others',
    'Social intelligence': 'Knowing what makes people tick',
    'Teamwork': 'Doing your share for the group',
    'Fairness': 'Treating everyone the same way',
    'Leadership': 'Organising the group to get things done',
    'Forgiveness': 'Giving people a second chance',
    'Humility': 'Letting your work speak for itself',
    'Prudence': 'Careful choices, no needless risks',
    'Self-regulation': 'Managing what you feel and do',
    'Appreciation of beauty': 'Noticing excellence and skill',
    'Gratitude': 'Being aware of the good, saying thanks',
    'Hope': 'Expecting the best and working for it',
    'Humour': 'Bringing smiles to others',
    'Spirituality': 'A sense of meaning and purpose',
  };

  static const maxSignatureStrengths = 5;

  /// Your top strengths, in the order you picked them.
  List<String> get signatureStrengths {
    final l = logsOf('strengths');
    return l.isEmpty
        ? const []
        : [for (final x in (l.first.data['top'] as List?) ?? const []) '$x'];
  }

  void setSignatureStrengths(List<String> top) {
    final kept = [
      for (final t in top)
        if (characterStrengths.containsKey(t)) t
    ].take(maxSignatureStrengths).toList();
    final existing = logsOf('strengths');
    if (existing.isEmpty) {
      if (kept.isNotEmpty) addLog('strengths', data: {'top': kept});
    } else {
      updateLog(existing.first.copyWith(data: {'top': kept}));
    }
  }

  /// Using a signature strength in a new way each day for a week raised
  /// happiness and lowered depressive symptoms for six months (Seligman,
  /// Steen, Park & Peterson 2005).
  void logStrengthUse(String strength, String how) {
    if (how.trim().isEmpty) return;
    addLog('strength_use', text: how.trim(), data: {'strength': strength});
  }

  int strengthUsesInWeek(DateTime anyDay) {
    final week = weekStartOf(anyDay);
    return countBetween('strength_use', week, week.plusDays(7));
  }

  /// The strength to try in a new way this week, rotating weekly through
  /// your top ones.
  String? get strengthOfTheWeek {
    final top = signatureStrengths;
    if (top.isEmpty) return null;
    // Calendar weeks, like the uses counted against it.
    final today = dayOnly(_now);
    return top[(weekStartOf(today).daysSince(weekStartOf(programStart)) ~/ 7) % top.length];
  }

  // ── Your personal board (developmental network) ──────────────────────

  /// The roles a personal board of advisors covers. A range of developers
  /// beats one mentor (Higgins & Kram 2001; Cummings & Higgins 2006).
  static const boardRoles = <String, String>{
    'mentor': 'Has walked your road, gives advice',
    'sponsor': 'Speaks for you where you are not',
    'peer': 'On the same road, compares notes',
    'challenger': 'Tells you the hard truth',
    'supporter': 'Believes in you on bad days',
    'connector': 'Opens doors to new people',
    'decider': 'Decides your next step — a manager, a client, a committee',
  };

  // ── Visibility: what the people who decide have seen ─────────────────

  /// How work was made visible: shown, written up, or put to them for
  /// their input (rational persuasion — the upward-influence tactic linked
  /// to better ratings, Higgins et al. 2003).
  static const visibilityWays = {
    'showed': 'Showed it (a demo, a walkthrough)',
    'wrote': 'Wrote it up',
    'asked': 'Asked for their input',
  };

  /// People on your board who decide your next step.
  List<LogEntry> get deciders => [for (final p in people) if (boardRolesOf(p).contains('decider')) p];

  LogEntry? logVisible(LogEntry person, {required String what, String how = 'showed'}) =>
      what.trim().isEmpty
          ? null
          : addLog('visible', text: what.trim(), data: {
              'person': person.id,
              'name': person.text,
              'how': visibilityWays.containsKey(how) ? how : 'showed',
            });

  /// What [person] has seen of your work in the last [days], newest first.
  List<LogEntry> seenBy(LogEntry person, {int days = 90}) {
    final from = dayOnly(_now).minusDays(days - 1);
    return [
      for (final l in logsOf('visible'))
        if (l.str('person') == person.id && !l.date.isBefore(from)) l
    ];
  }

  /// (deciders who saw something in 90 days, deciders).
  (int, int) get decidersSeen =>
      (deciders.where((p) => seenBy(p).isNotEmpty).length, deciders.length);

  List<String> boardRolesOf(LogEntry person) =>
      [for (final r in (person.data['board'] as List?) ?? const []) '$r'];

  void setBoardRoles(LogEntry person, List<String> roles) {
    final p = logsOf('person').where((x) => x.id == person.id);
    if (p.isEmpty) return;
    updateLog(p.first.copyWith(data: {
      ...p.first.data,
      'board': [for (final r in roles) if (boardRoles.containsKey(r)) r],
    }));
  }

  /// role → the people who fill it.
  Map<String, List<LogEntry>> get board => {
        for (final r in boardRoles.keys)
          r: [for (final p in people) if (boardRolesOf(p).contains(r)) p],
      };

  /// Roles nobody fills yet (empty until someone is on the board).
  List<String> get boardGaps {
    final b = board;
    if (b.values.every((v) => v.isEmpty)) return const [];
    // Deciders aren't a development role: no gap when there are none.
    return [for (final e in b.entries) if (e.value.isEmpty && e.key != 'decider') e.key];
  }

  // ── After-action review (Ellis & Davidi 2005) ────────────────────────

  /// After an event that mattered: what was meant to happen, what did,
  /// why, what to keep and what to change. Reviewing successes as well as
  /// failures improves the next performance (Ellis & Davidi 2005; Tannenbaum
  /// & Cerasoli 2013, meta-analysis of debriefs). "Change" becomes a card.
  LogEntry? logAar({
    required String event,
    String intended = '',
    String happened = '',
    String why = '',
    String sustain = '',
    String improve = '',
    String friend = '',
    bool wentWell = true,
  }) {
    if (event.trim().isEmpty) return null;
    return addLog('aar', text: event.trim(), data: {
      'intended': intended.trim(),
      'happened': happened.trim(),
      'why': why.trim(),
      'sustain': sustain.trim(),
      'improve': improve.trim(),
      'friend': friend.trim(),
      'went_well': wentWell,
    });
  }

  List<LogEntry> get aars => logsOf('aar');

  // ── Your playbook ────────────────────────────────────────────────────

  /// Every lesson you wrote in your own words, wherever you wrote it —
  /// practice reps, after-action reviews, month and quarter reviews,
  /// books applied, goals closed, hard conversations, experiments kept and
  /// the year's lesson. Pinned first, then newest. Retired ones only with
  /// [withRetired].
  List<PlayEntry> playbook({bool withRetired = false}) {
    final out = <PlayEntry>[];
    void add(LogEntry l, String field, String text, String from) {
      final t = text.trim();
      if (t.isEmpty) return;
      final key = '${l.id}:$field';
      if (!withRetired && isDone('play:off:$key')) return;
      out.add(PlayEntry(key, t, from, dayOnly(l.date), isDone('play:pin:$key')));
    }

    for (final r in logsOf('rep')) {
      add(r, 'lesson', r.str('lesson') ?? '', 'Practice · ${areaById(r.str('area') ?? '').name}');
    }
    for (final a in logsOf('aar')) {
      add(a, 'improve', a.str('improve') ?? '', 'After-action review · ${a.text}');
      add(a, 'friend', a.str('friend') ?? '', 'Advice to a friend · ${a.text}');
    }
    for (final m in logsOf('month_review')) {
      add(m, 'lesson', m.str('lesson') ?? '', 'Month ${m.number('month')} review');
    }
    for (final q in logsOf('quarterly_review')) {
      add(q, 'lessons', q.str('lessons') ?? '', 'Quarter ${q.number('quarter')} review');
    }
    for (final l in learning) {
      add(l, 'principle', l.str('principle') ?? '', 'From ${l.text}');
    }
    for (final g in goals) {
      add(g, 'advice', (g.str('advice') ?? '').isNotEmpty ? g.str('advice')! : g.str('reflection') ?? '',
          'Goal · ${g.text}');
    }
    for (final c in conversations) {
      add(c, 'learned', c.str('learned') ?? '',
          'Conversation${(c.str('with') ?? '').isEmpty ? '' : ' with ${c.str('with')}'}');
    }
    for (final e in experiments) {
      if (e.str('status') == 'kept') {
        add(e, 'kept', (e.str('result') ?? '').isEmpty ? e.text : '${e.text} — ${e.str('result')}',
            'Experiment kept');
      }
    }
    for (final a in logsOf('advice')) {
      if (a.str('status') == 'tried' && (a.str('result') ?? '').isNotEmpty) {
        add(a, 'result', '${a.text} — ${a.str('result')}',
            'Advice${(a.str('from') ?? '').isEmpty ? '' : ' from ${a.str('from')}'}');
      }
    }
    for (final g in negotiations) {
      add(g, 'lesson', g.str('lesson') ?? '', 'Negotiation · ${g.text}');
    }
    for (final y in logsOf('year_review')) {
      add(y, 'learned', y.str('learned') ?? '', 'Year ${y.number('year') ?? y.date.year} review');
    }
    out.sort((a, b) => a.pinned != b.pinned
        ? (a.pinned ? -1 : 1)
        : b.date.compareTo(a.date));
    return out;
  }

  void pinPlay(String key, bool pin) => setDone('play:pin:$key', pin);

  // ── On this day ──────────────────────────────────────────────────────

  /// One thing from a year, six months or a month ago today — a win, a
  /// lesson, feedback, a fear faced, advice that worked. People
  /// underestimate how much they'll enjoy rediscovering ordinary moments
  /// (Zhang et al. 2014). Never thoughts, letters, conversations or other
  /// private writing. Null once seen this week ([onThisDaySeenKey]).
  ({String when, String text, LogEntry log})? onThisDay(DateTime day) {
    final today = dayOnly(day);
    if (isDone(onThisDaySeenKey(today))) return null;
    for (final (back, label) in [(365, 'A year ago today'), (182, 'Six months ago'), (30, 'A month ago')]) {
      final d = today.minusDays(back);
      if (d.isBefore(journeyStart)) continue;
      final doneThatDay = [
        for (final l in [...logsOf('courage'), ...logsOf('advice')])
          if ((l.str('done_on') ?? l.str('closed_on')) == dateKey(d)) l
      ];
      for (final l in [...logsOn(d).where((x) => x.type != 'courage' && x.type != 'advice'), ...doneThatDay]) {
        final f = l.str;
        final text = switch (l.type) {
          'win' => 'Win: ${l.text}',
          'rep' => (f('lesson') ?? '').isEmpty ? '' : 'You learned: ${f('lesson')}',
          'feedback' => '${(f('from') ?? '').isEmpty ? 'Someone' : f('from')} told you: "${l.text}"',
          'aar' => (f('improve') ?? '').isEmpty ? '' : 'After ${l.text}: ${f('improve')}',
          'courage' => f('status') == 'done' ? 'You did what you had avoided: ${l.text}' : '',
          'advice' => f('status') == 'tried' ? 'You tried: ${l.text}' : '',
          _ => '',
        };
        if (text.isNotEmpty) return (when: label, text: text, log: l);
      }
    }
    return null;
  }

  String onThisDaySeenKey(DateTime day) => 'otd:${dateKey(weekStartOf(day))}';

  /// One pinned lesson for the week of [day], rotating through them.
  String? ruleOfTheWeek(DateTime day) {
    final pinned = [for (final e in playbook()) if (e.pinned) e]
      ..sort((a, b) => a.key.compareTo(b.key));
    if (pinned.isEmpty) return null;
    final week = weekStartOf(day).daysSince(weekStartOf(journeyStart)) ~/ 7;
    return pinned[week % pinned.length].text;
  }

  /// Take a lesson out of the playbook (the record it came from stays).
  void retirePlay(String key, bool retire) => setDone('play:off:$key', retire);

  /// The playbook as plain text to copy: pinned, then the rest.
  String playbookText() {
    final b = StringBuffer('${activeProfile.firstName}\'s playbook\n');
    for (final e in playbook()) {
      b.writeln('${e.pinned ? '★ ' : '• '}${e.text} (${e.from}, ${dateKey(e.date)})');
    }
    return b.toString().trim();
  }

  // ── Courage ladder ───────────────────────────────────────────────────

  /// Things you avoid, each with how hard it feels (0–10), climbed from
  /// the lowest rung (graded exposure). After each step you rate how hard
  /// it really was: people expect more discomfort than they feel, and
  /// seeing that gap is how avoidance loosens and self-trust grows.
  LogEntry? addCourageStep(String what, {required int fear}) => what.trim().isEmpty
      ? null
      : addLog('courage',
          text: what.trim(), data: {'fear': fear.clamp(0, 10), 'status': 'planned'});

  /// Planned steps, lowest rung first.
  List<LogEntry> get courageLadder => [
        for (final l in logsOf('courage'))
          if ((l.str('status') ?? 'planned') == 'planned') l
      ]..sort((a, b) => (a.number('fear') ?? 0).compareTo(b.number('fear') ?? 0));

  /// Steps taken, newest first.
  List<LogEntry> get courageDone => [
        for (final l in logsOf('courage'))
          if (l.str('status') == 'done') l
      ];

  /// The rung to take next: the lowest still on the ladder.
  LogEntry? get nextCourageStep => courageLadder.firstOrNull;

  void doCourageStep(String id, {required int felt, String happened = ''}) {
    final l = logsOf('courage').where((x) => x.id == id).firstOrNull;
    if (l == null) return;
    updateLog(l.copyWith(data: {
      ...l.data,
      'status': 'done',
      'felt': felt.clamp(0, 10),
      'happened': happened.trim(),
      'done_on': dateKey(_now),
    }));
  }

  /// Taken off the ladder on purpose (it stays in the log).
  void dropCourageStep(String id) {
    final l = logsOf('courage').where((x) => x.id == id).firstOrNull;
    if (l == null) return;
    updateLog(l.copyWith(data: {...l.data, 'status': 'dropped'}));
  }

  /// How much easier steps felt than feared, on average (0–10 points),
  /// from 3+ steps taken; null before. Negative means harder.
  double? get courageGap {
    final done = [
      for (final l in courageDone)
        if (l.number('fear') != null && l.number('felt') != null)
          (l.number('fear')! - l.number('felt')!).toDouble()
    ];
    if (done.length < 3) return null;
    return done.reduce((a, b) => a + b) / done.length;
  }

  /// Steps taken in the week of [anyDay].
  int courageStepsInWeek(DateTime anyDay) {
    final from = dateKey(weekStartOf(anyDay)),
        to = dateKey(weekStartOf(anyDay).plusDays(7));
    return courageDone.where((l) {
      final on = l.str('done_on') ?? '';
      return on.compareTo(from) >= 0 && on.compareTo(to) < 0;
    }).length;
  }

  // ── Promises (say–do) ────────────────────────────────────────────────

  /// What you said you'd do, for whom, by when. How well words and deeds
  /// match is what people trust (behavioural integrity, Simons 2002);
  /// renegotiating before the date keeps that trust, missing silently
  /// doesn't.
  static const promiseOutcomes = {
    'kept': 'Kept',
    'renegotiated': 'Renegotiated in time',
    'missed': 'Missed',
  };

  LogEntry? addPromise({required String what, String to = '', DateTime? by}) {
    if (what.trim().isEmpty) return null;
    return addLog('promise', text: what.trim(), data: {
      'to': to.trim(),
      'by': dateKey(dayOnly(by ?? _now)),
      'status': 'open',
    });
  }

  List<LogEntry> get openPromises => [
        for (final p in logsOf('promise').reversed)
          if (p.str('status') == 'open') p
      ]..sort((a, b) => (a.str('by') ?? '').compareTo(b.str('by') ?? ''));

  /// Open promises due on or before [day].
  List<LogEntry> promisesDue(DateTime day) => [
        for (final p in openPromises)
          if ((p.str('by') ?? '9999').compareTo(dateKey(dayOnly(day))) <= 0) p
      ];

  /// [outcome] from [promiseOutcomes]; renegotiating moves the date to
  /// [newBy] and keeps the promise open — only before the date has passed
  /// (after it, it was kept late or missed). Returns false when refused.
  bool closePromise(String id, String outcome, {DateTime? newBy}) {
    final p = logsOf('promise').where((l) => l.id == id).firstOrNull;
    if (p == null || !promiseOutcomes.containsKey(outcome)) return false;
    if (outcome == 'renegotiated') {
      if (promiseOverdue(p)) return false;
      updateLog(p.copyWith(data: {
        ...p.data,
        'by': dateKey(dayOnly(newBy ?? _now.plusDays(7))),
        'renegotiated': ((p.number('renegotiated') ?? 0) + 1).toInt(),
      }));
      return true;
    }
    updateLog(p.copyWith(data: {
      ...p.data,
      'status': outcome,
      'closed_on': dateKey(_now),
    }));
    return true;
  }

  /// Past its date and still open.
  bool promiseOverdue(LogEntry p) =>
      p.str('status') == 'open' &&
      (p.str('by') ?? '9999').compareTo(dateKey(dayOnly(_now))) < 0;

  /// Kept of closed promises (kept + missed) in the last [days]; null
  /// until three are closed.
  ({int kept, int missed, double ratio})? sayDo({int days = 90}) {
    final from = dateKey(dayOnly(_now).minusDays(days));
    var kept = 0, missed = 0;
    for (final p in logsOf('promise')) {
      if ((p.str('closed_on') ?? '').compareTo(from) < 0) continue;
      if (p.str('status') == 'kept') kept++;
      if (p.str('status') == 'missed') missed++;
    }
    if (kept + missed < 3) return null;
    return (kept: kept, missed: missed, ratio: kept / (kept + missed));
  }

  // ── Story bank (STAR) ────────────────────────────────────────────────

  /// The skills interviewers, promotion panels and reviews ask about.
  /// One interview question per story skill, for rehearsing out loud.
  static const rehearsalQuestions = {
    'Leading people': 'Tell me about a time you led a team through something hard.',
    'Influence without authority': 'Tell me about a time you changed someone\'s mind without authority over them.',
    'Conflict': 'Tell me about a disagreement with a colleague and how you handled it.',
    'A failure and what I learned': 'Tell me about a time you failed. What did you learn?',
    'Delivering under pressure': 'Tell me about a time you delivered under real pressure.',
    'Ownership': 'Tell me about a time you took ownership of something nobody owned.',
    'A hard decision': 'Tell me about a hard decision you made with incomplete information.',
    'Learning fast': 'Tell me about a time you had to learn something new quickly.',
    'Customer focus': 'Tell me about a time you changed course because of a customer.',
    'Creativity': 'Tell me about an idea of yours that made something better.',
  };

  static const starParts = ['Situation', 'Task', 'Action', 'Result'];

  /// A question rehearsed out loud, and which parts of the answer landed.
  LogEntry? logRehearsal({required String question, String skill = '', List<String> star = const []}) =>
      addLog('rehearsal', text: question.trim(), data: {'skill': skill, 'star': star});

  static const storySkills = [
    'Leading people',
    'Influence without authority',
    'Conflict',
    'A failure and what I learned',
    'Delivering under pressure',
    'Ownership',
    'A hard decision',
    'Learning fast',
    'Customer focus',
    'Creativity',
  ];

  /// Situation, task, action, result: stories ready for an interview, a
  /// promotion case or a review. Prepared, concrete examples are what
  /// behavioural interviews reward (Maurer et al. 2001).
  LogEntry? saveStory({
    String? id,
    required String title,
    String situation = '',
    String task = '',
    String action = '',
    String result = '',
    List<String> skills = const [],
    String from = '',
  }) {
    if (title.trim().isEmpty) return null;
    final data = {
      'situation': situation.trim(),
      'task': task.trim(),
      'action': action.trim(),
      'result': result.trim(),
      'skills': [for (final k in skills) if (storySkills.contains(k)) k],
      'from': from,
    };
    final existing = id == null
        ? null
        : logsOf('story').where((l) => l.id == id).firstOrNull;
    if (existing != null) {
      final next = existing.copyWith(text: title.trim(), data: data);
      updateLog(next);
      return next;
    }
    return addLog('story', text: title.trim(), data: data);
  }

  List<LogEntry> get stories => logsOf('story');

  List<String> skillsOf(LogEntry story) =>
      [for (final k in (story.data['skills'] as List?) ?? const []) '$k'];

  /// Skills with no story yet.
  List<String> get storyGaps => [
        for (final k in storySkills)
          if (!stories.any((s) => skillsOf(s).contains(k))) k
      ];

  /// Wins and after-action reviews from the last 180 days not yet turned
  /// into a story, newest first.
  List<LogEntry> get storyIdeas {
    final used = {for (final s in stories) s.str('from')};
    final from = dayOnly(_now).minusDays(180);
    return [
      for (final l in allLogs({'win', 'aar'}))
        if (!l.date.isBefore(from) && !used.contains(l.id)) l
    ].take(5).toList();
  }

  /// Every story (or those for [skill]) as text to read before an
  /// interview.
  String storiesText({String? skill}) {
    final b = StringBuffer();
    for (final s in stories) {
      if (skill != null && !skillsOf(s).contains(skill)) continue;
      String f(String k) => (s.str(k) ?? '').trim();
      b.writeln(s.text);
      if (skillsOf(s).isNotEmpty) b.writeln('(${skillsOf(s).join(', ')})');
      if (f('situation').isNotEmpty) b.writeln('Situation: ${f('situation')}');
      if (f('task').isNotEmpty) b.writeln('Task: ${f('task')}');
      if (f('action').isNotEmpty) b.writeln('Action: ${f('action')}');
      if (f('result').isNotEmpty) b.writeln('Result: ${f('result')}');
      b.writeln();
    }
    return b.toString().trim();
  }

  // ── Backup ───────────────────────────────────────────────────────────

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_state?.toJson() ?? {});

  /// Replace all data with an exported backup. Returns false if invalid.
  bool importJson(String raw) {
    final next = _parseBackup(raw);
    if (next == null) return false;
    _beforeImport = _state;
    _update(next, reschedule: true);
    _applyProfile();
    return true;
  }

  /// The state before the last import, for Undo (this session only).
  PersonalSystemState? _beforeImport;
  bool get canUndoImport => _beforeImport != null;

  /// Puts back what was there before the last import.
  void undoImport() {
    final s = _beforeImport;
    if (s == null) return;
    _beforeImport = null;
    _update(s, reschedule: true);
    _applyProfile();
  }

  /// A backup only if it has the program and its logs: a fragment or a
  /// truncated paste must not replace everything.
  PersonalSystemState? _parseBackup(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic> ||
          j['program_start'] == null ||
          j['logs'] is! List) {
        return null;
      }
      return PersonalSystemState.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  /// What restoring [raw] would do: null if it isn't a backup; otherwise
  /// its entries, how many entries here it doesn't have (they would go),
  /// and the latest day it holds.
  ({int entries, int missingHere, DateTime? latest})? importPreview(String raw) {
    final next = _parseBackup(raw);
    if (next == null) return null;
    final ids = {for (final l in next.logs) l.id};
    DateTime? latest;
    for (final l in next.logs) {
      if (latest == null || l.date.isAfter(latest)) latest = l.date;
    }
    return (
      entries: next.logs.length,
      missingHere: (_state?.logs ?? const <LogEntry>[])
          .where((l) => !ids.contains(l.id))
          .length,
      latest: latest,
    );
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

/// One lesson in the playbook: [key] is `<logId>:<field>`.
class PlayEntry {
  final String key;
  final String text;
  final String from;
  final DateTime date;
  final bool pinned;
  const PlayEntry(this.key, this.text, this.from, this.date, this.pinned);
}

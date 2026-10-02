import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/emin_system.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';
import '../services/brief_generator.dart';
import '../services/reminder_service.dart';

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
  })  : _gateway = gateway,
        _reminders = reminders,
        _briefs = briefGenerator ?? DeviceBriefGenerator();

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

  /// Consecutive days (ending today, or yesterday if today isn't held yet)
  /// with at least 7/10.
  int get streak {
    var day = dayOnly(_now);
    if (scoreFor(day) < 7) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (!day.isBefore(programStart) && scoreFor(day) >= 7) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get bestStreak {
    var best = 0, run = 0;
    for (var d = programStart;
        !d.isAfter(dayOnly(_now));
        d = d.add(const Duration(days: 1))) {
      run = scoreFor(d) >= 7 ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

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

  void logWeight(double kg, {DateTime? date}) =>
      addLog('weight', date: date, data: {'kg': kg});

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
      {bool zone2 = false}) {
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
        return '7.5 hours protects tomorrow\'s mind. Phone outside, room 18–19°C.';
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
        return 'Sleep starts now — no caffeine after 13:00.';
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

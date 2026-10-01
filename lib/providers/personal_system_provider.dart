import 'package:flutter/foundation.dart';

import '../data/emin_system.dart';
import '../gateways/personal_system_gateway.dart';
import '../models/personal_system.dart';

class PersonalSystemProvider extends ChangeNotifier {
  final PersonalSystemGateway _gateway;

  PersonalSystemProvider({required PersonalSystemGateway gateway})
      : _gateway = gateway;

  static const _gymId = 'gym';
  static const _fallbackUser = 'local';

  String _userId = _fallbackUser;
  PersonalSystemState? _state;
  bool _loading = false;

  bool get isLoaded => _state != null;
  bool get isLoading => _loading;
  PersonalSystemState? get state => _state;

  Future<void> load(String? userId) async {
    final id = userId ?? _fallbackUser;
    if (_state != null && id == _userId) return;
    _userId = id;
    _loading = true;
    notifyListeners();
    _state = await _gateway.load(id);
    _loading = false;
    notifyListeners();
  }

  void _update(PersonalSystemState next) {
    _state = next;
    notifyListeners();
    _gateway.save(_userId, next);
  }

  // ── Program timeline ──

  DateTime get programStart => _state?.programStart ?? DateTime.now();

  int get programDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(programStart).inDays + 1;
  }

  int get programMonth => ((programDay - 1) ~/ 30) + 1;
  int get programWeek => ((programDay - 1) ~/ 7) + 1;

  void setProgramStart(DateTime date) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        programStart: DateTime(date.year, date.month, date.day)));
  }

  // ── Daily checks ──

  List<String> _checks(DateTime date) =>
      _state?.dailyChecks[dateKey(date)] ?? const [];

  bool isChecked(DateTime date, String id) => _checks(date).contains(id);

  void toggleCheck(DateTime date, String id) {
    final s = _state;
    if (s == null) return;
    final key = dateKey(date);
    final current = List<String>.from(s.dailyChecks[key] ?? const []);
    current.contains(id) ? current.remove(id) : current.add(id);
    _update(s.copyWith(dailyChecks: {...s.dailyChecks, key: current}));
  }

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

  /// Average non-negotiable score over the days of this week so far.
  double weekAverage(DateTime anyDay) {
    final now = DateTime.now();
    final days = weekDays(anyDay)
        .where((d) => !d.isAfter(now))
        .toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (sum, d) => sum + scoreFor(d));
    return total / days.length;
  }

  int gymSessionsInWeek(DateTime anyDay) =>
      weekDays(anyDay).where(gymDone).length;

  /// Consecutive days (ending today, or yesterday if today is still empty)
  /// with at least 7/10 non-negotiables.
  int get streak {
    var day = DateTime.now();
    if (scoreFor(day) < 7) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (scoreFor(day) >= 7) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ── Priorities ──

  List<String> prioritiesFor(DateTime date) {
    final p = _state?.priorities[dateKey(date)] ?? const [];
    return List.generate(3, (i) => i < p.length ? p[i] : '');
  }

  void setPriority(DateTime date, int index, String text) {
    final s = _state;
    if (s == null) return;
    final key = dateKey(date);
    final list = prioritiesFor(date);
    list[index] = text.trim();
    _update(s.copyWith(priorities: {...s.priorities, key: list}));
  }

  // ── Generic checklists ──

  bool isDone(String key) => _state?.done.contains(key) ?? false;

  void toggleDone(String key) {
    final s = _state;
    if (s == null) return;
    final next = Set<String>.from(s.done);
    next.contains(key) ? next.remove(key) : next.add(key);
    _update(s.copyWith(done: next));
  }

  int doneCount(Iterable<String> keys) => keys.where(isDone).length;

  // ── Evidence archive ──

  List<EvidenceItem> evidenceIn(String section) =>
      (_state?.evidence ?? const [])
          .where((e) => e.section == section)
          .toList();

  int get evidenceCount => _state?.evidence.length ?? 0;

  void addEvidence(String section, String text) {
    final s = _state;
    if (s == null || text.trim().isEmpty) return;
    final item = EvidenceItem(
      id: 'ev_${DateTime.now().microsecondsSinceEpoch}',
      section: section,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _update(s.copyWith(evidence: [...s.evidence, item]));
  }

  void removeEvidence(String id) {
    final s = _state;
    if (s == null) return;
    _update(s.copyWith(
        evidence: s.evidence.where((e) => e.id != id).toList()));
  }

  // ── Weekly reports ──

  List<WeeklyReport> get reports {
    final list = List<WeeklyReport>.from(_state?.reports ?? const []);
    list.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return list;
  }

  WeeklyReport? reportForWeek(DateTime anyDay) {
    final start = weekStartOf(anyDay);
    for (final r in _state?.reports ?? const <WeeklyReport>[]) {
      if (dateKey(r.weekStart) == dateKey(start)) return r;
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
}

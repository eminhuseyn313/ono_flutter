import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Set-by-set logger for Day A / B / C. Pre-fills last session's weights so
/// progression is visible, flags new bests, and marks the session done.
class GymSessionScreen extends StatefulWidget {
  final String? dayId;
  const GymSessionScreen({super.key, this.dayId});

  @override
  State<GymSessionScreen> createState() => _GymSessionScreenState();
}

class _SetRow {
  final TextEditingController kg;
  final TextEditingController reps;

  /// Ticked when the set is finished; starts the rest timer.
  bool done = false;
  _SetRow(String kg, String reps)
      : kg = TextEditingController(text: kg),
        reps = TextEditingController(text: reps);
}

class _GymSessionScreenState extends State<GymSessionScreen> {
  late GymDay _day;
  final Map<String, List<_SetRow>> _sets = {};
  bool _zone2 = false;
  bool _initialised = false;

  /// Shoulders flagged in this morning's check-in (RA): presses, flyes and
  /// pulldowns are swapped for legs and trunk work. Can be switched off.
  bool _sparing = false;

  // Rest timer between sets.
  DateTime? _restEnds;
  Duration _restTotal = Duration.zero;
  String _restNext = '';
  Timer? _tick;
  late PersonalSystemProvider _system;

  List<Exercise> get _exercises => _sparing
      ? [
          ..._day.exercises.where((e) => !e.shoulder),
          ...shoulderSparingAddOns
              .where((a) => !_day.exercises.any((e) => e.name == a.name)),
        ]
      : _day.exercises;

  List<Exercise> get _skipped =>
      _sparing ? _day.exercises.where((e) => e.shoulder).toList() : const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final system = context.read<PersonalSystemProvider>();
    _system = system;
    _day = widget.dayId == null
        ? system.nextGymDay(DateTime.now()).day
        : gymPlan.firstWhere((g) => g.id == widget.dayId,
            orElse: () => gymPlan.first);
    _sparing = system.shoulderFlag(DateTime.now());
    final last = system.lastSessionFor(_day.id);
    final lastByName = <String, List<Map<String, dynamic>>>{};
    for (final e in (last?.data['exercises'] as List? ?? const [])) {
      final m = Map<String, dynamic>.from(e as Map);
      lastByName[m['name'] as String] = (m['sets'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    }
    for (final ex in [..._day.exercises, ...shoulderSparingAddOns]) {
      if (_sets.containsKey(ex.name)) continue;
      final spec = _parse(ex.sets);
      final prev = lastByName[ex.name];
      // At least the planned sets, even if last time fell short; the
      // extra rows start from the last set done.
      _sets[ex.name] = List.generate(
        prev == null ? spec.$1 : (prev.length > spec.$1 ? prev.length : spec.$1),
        (i) {
          final p = prev == null || prev.isEmpty ? null : prev[i < prev.length ? i : prev.length - 1];
          return _SetRow(
            p == null ? '' : _fmt(p['kg']),
            p == null ? '${spec.$2}' : _fmt(p['reps']),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    if (_restEnds != null) _system.cancelRest();
    for (final rows in _sets.values) {
      for (final r in rows) {
        r.kg.dispose();
        r.reps.dispose();
      }
    }
    super.dispose();
  }

  static String _fmt(Object? v) {
    if (v == null) return '';
    final n = (v as num).toDouble();
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  /// "3×12" → (3, 12); "3×45 sec" → (3, 45).
  static (int, int) _parse(String spec) {
    final m = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(spec);
    if (m == null) return (3, 12);
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// Ticks set [i] of [ex] and starts the rest before the next one.
  void _finishSet(Exercise ex, int i) {
    final rows = _sets[ex.name]!;
    final wasDone = rows[i].done;
    setState(() => rows[i].done = !wasDone);
    if (wasDone) return;
    HapticFeedback.mediumImpact();
    final list = _exercises;
    final at = list.indexWhere((e) => e.name == ex.name);
    String next;
    final open = [
      for (var j = 0; j < rows.length; j++)
        if (!rows[j].done) j
    ];
    if (open.isNotEmpty) {
      next = '${ex.name} · set ${open.first + 1}';
    } else if (at >= 0 && at + 1 < list.length) {
      next = list[at + 1].name;
    } else {
      next = _day.finisher;
    }
    _startRest(PersonalSystemProvider.restFor(ex), next);
  }

  void _startRest(Duration d, String next) {
    _restTotal = d;
    _restNext = next;
    _restEnds = DateTime.now().add(d);
    _system.startRest(_restEnds!, next: next);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    setState(() {});
  }

  void _onTick() {
    if (!mounted || _restEnds == null) return;
    if (!DateTime.now().isBefore(_restEnds!)) {
      _tick?.cancel();
      _restEnds = null;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      toast(context, 'Rest done. Next: $_restNext');
    }
    setState(() {});
  }

  void _addRest(int seconds) {
    if (_restEnds == null) return;
    _restEnds = _restEnds!.add(Duration(seconds: seconds));
    _restTotal += Duration(seconds: seconds);
    _system.startRest(_restEnds!, next: _restNext);
    setState(() {});
  }

  void _skipRest() {
    _tick?.cancel();
    _restEnds = null;
    _system.cancelRest();
    setState(() {});
  }

  Widget _restBar() {
    final left = _restEnds!.difference(DateTime.now());
    final secs = (left.inMilliseconds / 1000).ceil().clamp(0, 3600);
    final clock = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final total = _restTotal.inMilliseconds;
    final progress =
        total == 0 ? 1.0 : (1 - left.inMilliseconds / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        key: const Key('rest-timer'),
        accent: AppColors.body,
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(clock, style: AppText.number(size: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Rest · next: $_restNext',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small(color: AppColors.greyLight)),
                ),
                TextButton(
                    onPressed: () => _addRest(15), child: const Text('+15')),
                TextButton(onPressed: _skipRest, child: const Text('Skip')),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                color: AppColors.body,
                backgroundColor: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sets ticked but not saved yet: leaving loses them.
  bool get _inProgress =>
      _sets.values.any((rows) => rows.any((r) => r.done));

  Future<bool> _confirmLeave() async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave this session?'),
          content: const Text('The sets you ticked aren\'t saved until you finish the session.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Leave')),
          ],
        ),
      ) ==
      true;

  void _save() {
    final system = context.read<PersonalSystemProvider>();
    final exercises = <Map<String, dynamic>>[];
    final prs = <String>[];
    for (final ex in _exercises) {
      final rows = _sets[ex.name]!;
      final sets = <Map<String, dynamic>>[];
      for (final r in rows) {
        // Rows come pre-filled from last time: only ticked sets happened.
        if (!r.done) continue;
        final kg = double.tryParse(r.kg.text.replaceAll(',', '.'));
        final reps = int.tryParse(r.reps.text);
        if (reps == null && kg == null) continue;
        sets.add({'kg': kg ?? 0, 'reps': reps ?? 0});
      }
      if (sets.isEmpty) continue;
      final top = sets
          .map((s) => (s['kg'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
      if (top > 0 && top > system.bestLift(ex.name)) prs.add(ex.name);
      exercises.add({'name': ex.name, 'sets': sets});
    }
    if (exercises.isEmpty) {
      toast(context, 'Tick the sets you did.');
      return;
    }
    system.saveGymSession(DateTime.now(), _day.id, exercises,
        zone2: _zone2, shoulderSparing: _sparing);
    _skipRest();
    HapticFeedback.heavyImpact();
    toast(
        context,
        prs.isEmpty
            ? 'Day ${_day.letter} logged. ${system.gymSessionsInWeek(DateTime.now())}/3 this week.'
            : 'Logged — new best: ${prs.join(', ')}');
    context.canPop() ? context.pop() : context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final last = system.lastSessionFor(_day.id);
    final loggedToday = system
        .logsOn(DateTime.now(), 'gym')
        .any((l) => l.str('day') == _day.id);

    return PopScope(
      canPop: !_inProgress,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.of(this.context).pop();
      },
      child: OnoPage(
      showBack: true,
      eyebrow: _sparing
          ? 'Day ${_day.letter} · shoulder-sparing'
          : 'Day ${_day.letter} · RA-safe',
      title: _day.name,
      subtitle: last == null
          ? 'First time logging this day — enter what you lift today.'
          : 'Pre-filled from ${weekdayName(last.date.weekday)} ${shortDate(last.date)}. Beat one number.',
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_restEnds != null) _restBar(),
          PrimaryButton('Finish session',
              icon: Icons.check_rounded, onPressed: _save),
        ],
      ),
      children: [
        const SizedBox(height: 12),
        Wrap(
          runSpacing: 8,
          children: [
            for (final g in gymPlan)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${g.letter} · ${g.name}'),
                  selected: g.id == _day.id,
                  showCheckmark: false,
                  selectedColor: AppColors.cardLight,
                  onSelected: (_) async {
                    if (g.id == _day.id) return;
                    if (_inProgress && !await _confirmLeave()) return;
                    if (mounted) this.context.pushReplacement('/gym/${g.id}');
                  },
                ),
              ),
          ],
        ),
        if (loggedToday) ...[
          const SizedBox(height: 12),
          OnoCard(
            accent: AppColors.body,
            padding: const EdgeInsets.all(14),
            child: Text(
                'Already logged today. Finishing again adds a second session.',
                style: AppText.small(color: AppColors.greyLight)),
          ),
        ],
        if (_sparing || system.shoulderFlag(DateTime.now())) ...[
          const SizedBox(height: 12),
          OnoCard(
            accent: AppColors.warning,
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                      _sparing
                          ? 'Shoulders flagged this morning. Skipped today: ${_skipped.map((e) => e.name).join(', ')}.'
                          : 'Shoulders were flagged this morning — normal plan chosen.',
                      style: AppText.small(color: AppColors.greyLight)),
                ),
                Switch(
                  value: _sparing,
                  onChanged: (v) => setState(() => _sparing = v),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (final ex in _exercises) _exercise(ex, system),
        const SizedBox(height: 8),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: CheckRow(
            checked: _zone2,
            title: _day.finisher,
            subtitle: 'Conversational pace — builds the energy base.',
            lane: 'body',
            onChanged: (v) => setState(() => _zone2 = v),
          ),
        ),
      ],
    ));
  }

  Widget _exercise(Exercise ex, PersonalSystemProvider system) {
    final rows = _sets[ex.name]!;
    final best = system.bestLift(ex.name);
    final spec = _parse(ex.sets);
    final allHit = rows.isNotEmpty &&
        rows.every((r) => (int.tryParse(r.reps.text) ?? 0) >= spec.$2);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        accent: ex.keyLift ? AppColors.accent : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ex.name,
                      style: AppText.heading(
                          color:
                              ex.keyLift ? AppColors.accent : AppColors.white)),
                ),
                Text(ex.sets, style: AppText.small()),
              ],
            ),
            if (ex.note != null)
              Text(ex.note!, style: AppText.small().copyWith(fontSize: 12)),
            if (best > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    'Best ${_fmt(best)} kg${allHit ? ' · all reps hit — add 2.5 kg next time' : ''}',
                    style: AppText.small(
                            color: allHit ? AppColors.body : AppColors.grey)
                        .copyWith(fontSize: 12)),
              ),
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 26,
                        child: Text('${i + 1}', style: AppText.small())),
                    Expanded(child: _num(rows[i].kg, 'kg')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _num(rows[i].reps,
                            ex.sets.contains('sec') ? 'sec' : 'reps')),
                    IconButton(
                      key: Key('set-${ex.name}-$i'),
                      tooltip: rows[i].done ? 'Undo set' : 'Set done — rest',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _finishSet(ex, i),
                      icon: Icon(
                        rows[i].done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: rows[i].done ? AppColors.body : AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() => rows.add(_SetRow(
                  rows.isEmpty ? '' : rows.last.kg.text,
                  rows.isEmpty ? '${spec.$2}' : rows.last.reps.text))),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String suffix) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: AppText.number(size: 16),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          hintText: '–',
          // suffixText hides on empty fields; the unit should always show.
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(suffix, style: AppText.small()),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      );
}

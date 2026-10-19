import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Routes /tool/:id to the guided flow for that protocol.
class ToolScreen extends StatelessWidget {
  final String id;
  final Map<String, String> params;
  const ToolScreen({super.key, required this.id, this.params = const {}});

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case 'sigh':
        return const _SighTool();
      case 'excited':
        return const _QuickProtocol(
          type: 'excited',
          protocolId: 'excited',
          title: '"I am excited"',
          big: 'I am excited.',
          body:
              'Anxiety and excitement are the same body state. Calm-down asks you to change it — nearly impossible. "I am excited" only reinterprets it. Say it internally, once, right before you walk in.',
          prompt: 'Before what?',
        );
      case 'pause':
        return const _QuickProtocol(
          type: 'pause',
          protocolId: 'pause',
          title: 'Deliberate pause',
          big: 'One breath. Then answer.',
          body:
              'Immediate answers read as reactive; a 1–2 second pause reads as deliberate. Log it when you used it on a hard question.',
          prompt: 'Which question?',
          outcome: true,
        );
      case 'still':
        return const _QuickProtocol(
          type: 'still',
          protocolId: 'still',
          title: 'Still body',
          big: 'Feet flat. Hands still. Phone away. Eyes on the speaker.',
          body:
              'Physical stillness is the strongest unconscious signal of authority. Log the meetings where you held it.',
          prompt: 'Which meeting?',
          outcome: true,
        );
      case 'bluf':
        return const _BlufTool();
      case 'sixq':
        return const _SixQTool();
      case 'read':
        return const _ReadTool();
      case 'feynman':
        return const _FeynmanTool();
      case 'scan':
        return const _ScanTool();
      case 'pennebaker':
        return const _PennebakerTool();
      case 'anki':
        return const _AnkiTool();
      case 'artifact':
        return _ArtifactTool(month: int.tryParse(params['month'] ?? ''));
      case 'linkedin':
        return const _LinkedInTool();
      case 'metta':
        return const _MettaTool();
      default:
        return const OnoPage(
            showBack: true, title: 'Unknown tool', children: []);
    }
  }
}

// ── Shared pieces ──────────────────────────────────────────────────────

/// Count-down timer with a ring. Calls [onDone] at zero (heavy haptic).
class CountdownTimer extends StatefulWidget {
  final int minutes;
  final VoidCallback? onDone;
  final String label;

  const CountdownTimer(
      {super.key, required this.minutes, this.onDone, this.label = ''});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _t;
  late int _left = widget.minutes * 60;

  /// Counted from the end time, so it stays right after iOS suspends ONO.
  DateTime? _endsAt;
  late PersonalSystemProvider _system;
  bool get _running => _t != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _system = context.read<PersonalSystemProvider>();
  }

  String get _route {
    try {
      return GoRouterState.of(context).uri.toString();
    } catch (_) {
      return '/home';
    }
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_running) {
      _t!.cancel();
      _system.cancelTimerEnd();
      setState(() {
        _t = null;
        _endsAt = null;
      });
      return;
    }
    _endsAt = DateTime.now().add(Duration(seconds: _left));
    _system.notifyTimerEnd(_endsAt!,
        title: '${widget.minutes} minutes done',
        body: widget.label.isEmpty
            ? 'Time is up.'
            : 'Time is up — ${widget.label}.',
        route: _route);
    setState(() {
      _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    });
  }

  void _tick() {
    if (!mounted || _endsAt == null) return;
    final ms = _endsAt!.difference(DateTime.now()).inMilliseconds;
    setState(() => _left = (ms / 1000).ceil().clamp(0, widget.minutes * 60));
    if (_left <= 0) {
      _t?.cancel();
      _t = null;
      _endsAt = null;
      HapticFeedback.heavyImpact();
      widget.onDone?.call();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    if (_endsAt != null) _system.cancelTimerEnd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.minutes * 60;
    final mm = (_left ~/ 60).toString().padLeft(2, '0');
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        ScoreRing(
          progress: 1 - _left / total,
          size: 180,
          stroke: 10,
          color: AppColors.accent,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$mm:$ss', style: AppText.number(size: 40)),
              if (widget.label.isNotEmpty)
                Text(widget.label, style: AppText.small()),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GhostButton(
              _left <= 0
                  ? 'Done'
                  : _running
                      ? 'Pause'
                      : (_left == total ? 'Start ${widget.minutes} min' : 'Resume'),
              icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: _left <= 0 ? null : _toggle,
            ),
            if (_left != total) ...[
              const SizedBox(width: 8),
              GhostButton('Reset',
                  icon: Icons.replay_rounded,
                  onPressed: () {
                    _t?.cancel();
                    // A reset block must not still notify at the old end.
                    if (_endsAt != null) _system.cancelTimerEnd();
                    setState(() {
                      _t = null;
                      _endsAt = null;
                      _left = total;
                    });
                  }),
            ],
          ],
        ),
      ],
    );
  }
}

class _Mastery extends StatelessWidget {
  final String protocolId;
  const _Mastery(this.protocolId);

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final uses = system.usesOf(protocolId);
    final next = nextMasteryAt(uses);
    return Row(
      children: [
        Tag(masteryFor(uses), color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
            next == null
                ? '$uses uses — automatic'
                : '$uses uses · ${next - uses} to the next level',
            style: AppText.small()),
      ],
    );
  }
}

Widget _field(TextEditingController c, String hint,
        {int lines = 1, String? label}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 4,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint, labelText: label),
      ),
    );

Widget _history(BuildContext context, List<LogEntry> items,
    String Function(LogEntry) line,
    {String title = 'History', int max = 8}) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title),
      OnoCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (final e in items.take(max))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(shortDate(e.date), style: AppText.small()),
                    ),
                    Expanded(
                        child: Text(line(e),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.small(color: AppColors.greyLight))),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

void _doneAndBack(BuildContext context, String message) {
  HapticFeedback.mediumImpact();
  toast(context, message);
  context.canPop() ? context.pop() : context.go('/home');
}

// ── Physiological sigh ─────────────────────────────────────────────────

class _SighTool extends StatefulWidget {
  const _SighTool();

  @override
  State<_SighTool> createState() => _SighToolState();
}

class _SighToolState extends State<_SighTool>
    with SingleTickerProviderStateMixin {
  // One cycle: inhale 2s, top-up 1s, long exhale 6s.
  static const _phases = [('Inhale', 2), ('Again — top up', 1), ('Long exhale', 6)];
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));
  int _cycle = 0;
  bool _running = false;
  bool _done = false;
  // Three sighs; "Keep going" carries on to about two minutes.
  int _breaths = 3;
  final _context = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      HapticFeedback.mediumImpact();
      if (_cycle < _breaths - 1) {
        setState(() => _cycle++);
        _c.forward(from: 0);
      } else {
        setState(() {
          _running = false;
          _done = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _context.dispose();
    super.dispose();
  }

  ({String label, double scale}) _phaseAt(double t) {
    final s = t * 9;
    if (s < 2) return (label: _phases[0].$1, scale: 0.55 + 0.3 * (s / 2));
    if (s < 3) return (label: _phases[1].$1, scale: 0.85 + 0.15 * (s - 2));
    return (label: _phases[2].$1, scale: 1.0 - 0.45 * ((s - 3) / 6));
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    // Mastery and "today's list" only mean something when it's an item.
    final onList = system.dailyItems.any((n) => n.id == 'sigh');
    return OnoPage(
      showBack: true,
      eyebrow: onList ? 'Protocol · 30 seconds' : 'Breathe · 30 seconds to 2 minutes',
      title: 'Physiological sigh',
      subtitle:
          'Double inhale through the nose, long exhale through the mouth. Three times — or keep going.',
      children: [
        const SizedBox(height: 12),
        if (onList) const _Mastery('sigh'),
        const SizedBox(height: 24),
        Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final p = _running ? _phaseAt(_c.value) : (label: _done ? 'Done' : 'Ready', scale: 0.6);
              return Column(
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(
                      child: Container(
                        width: 240 * p.scale,
                        height: 240 * p.scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mind.withValues(alpha: 0.18),
                          border: Border.all(color: AppColors.mind, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(p.label, style: AppText.title()),
                  Text(_running ? 'Breath ${_cycle + 1} of $_breaths' : '',
                      style: AppText.small()),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        if (!_done)
          PrimaryButton(_running ? 'Breathing…' : 'Begin',
              onPressed: _running
                  ? null
                  : () {
                      setState(() {
                        _running = true;
                        _cycle = 0;
                      });
                      _c.forward(from: 0);
                    })
        else ...[
          OnoCard(
            color: AppColors.navy,
            child: Text(
                system.isBuiltInPerson
                    ? 'Now, internally: "I am excited."'
                    : 'Notice your shoulders and jaw. Let them drop.',
                style: AppText.serif(size: 22)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                key: const Key('sigh-keep-going'),
                onPressed: () {
                  setState(() {
                    _done = false;
                    _running = true;
                    _cycle = 0;
                    _breaths = 10;
                  });
                  _c.forward(from: 0);
                },
                child: const Text('Keep going'),
              ),
              TextButton(
                onPressed: () => context.push('/stepback'),
                child: const Text('Step back next'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _field(_context, 'Before what? (optional)'),
          PrimaryButton('Log it', onPressed: () {
            system.logProtocolUse('sigh', text: _context.text.trim());
            _doneAndBack(context,
                onList ? 'Sigh logged — today\'s list updated.' : 'Logged.');
          }),
        ],
      ],
    );
  }
}

// ── Quick protocols (excited / pause / still) ──────────────────────────

class _QuickProtocol extends StatefulWidget {
  final String type;
  final String protocolId;
  final String title;
  final String big;
  final String body;
  final String prompt;
  final bool outcome;

  const _QuickProtocol({
    required this.type,
    required this.protocolId,
    required this.title,
    required this.big,
    required this.body,
    required this.prompt,
    this.outcome = false,
  });

  @override
  State<_QuickProtocol> createState() => _QuickProtocolState();
}

class _QuickProtocolState extends State<_QuickProtocol> {
  final _c = TextEditingController();
  String? _outcome;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Protocol',
      title: widget.title,
      children: [
        const SizedBox(height: 12),
        _Mastery(widget.protocolId),
        const SizedBox(height: 18),
        OnoCard(
          color: AppColors.navy,
          padding: const EdgeInsets.all(22),
          child: Text(widget.big, style: AppText.serif(size: 28)),
        ),
        const SizedBox(height: 14),
        Text(widget.body, style: AppText.body()),
        const SizedBox(height: 20),
        _field(_c, widget.prompt),
        if (widget.outcome)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                for (final o in ['held', 'shaky'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(o == 'held' ? 'It held' : 'Shaky'),
                      selected: _outcome == o,
                      onSelected: (_) => setState(() => _outcome = o),
                    ),
                  ),
              ],
            ),
          ),
        PrimaryButton('Log it', onPressed: () {
          system.logProtocolUse(widget.type,
              text: _c.text.trim(),
              data: {if (_outcome != null) 'outcome': _outcome});
          _doneAndBack(context, '${widget.title} logged.');
        }),
        _history(context, system.logsOf(widget.type),
            (e) => [
                  if (e.text.isNotEmpty) e.text,
                  if (e.str('outcome') != null) '(${e.str('outcome')})'
                ].join(' ').ifEmpty('Used')),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

// ── BLUF drafter ───────────────────────────────────────────────────────

class _BlufTool extends StatefulWidget {
  const _BlufTool();

  @override
  State<_BlufTool> createState() => _BlufToolState();
}

class _BlufToolState extends State<_BlufTool> {
  final _to = TextEditingController(text: activeProfile.manager);
  final _decision = TextEditingController();
  final _r = List.generate(3, (_) => TextEditingController());
  final _need = TextEditingController();
  final _by = TextEditingController();

  @override
  void dispose() {
    for (final c in [_to, _decision, ..._r, _need, _by]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _composed {
    final reasons = _r.map((c) => c.text.trim()).where((t) => t.isNotEmpty);
    final parts = <String>[
      if (_decision.text.trim().isNotEmpty) _decision.text.trim().endsWith('.')
          ? _decision.text.trim()
          : '${_decision.text.trim()}.',
      if (reasons.isNotEmpty) '${reasons.join('; ')}.',
      if (_need.text.trim().isNotEmpty || _by.text.trim().isNotEmpty)
        'Need ${_need.text.trim().isEmpty ? 'your alignment' : _need.text.trim()}${_by.text.trim().isEmpty ? '' : ' by ${_by.text.trim()}'}.',
    ];
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Protocol · decision first',
      title: 'BLUF',
      subtitle: 'Decision → three reasons → what you need → by when.',
      children: [
        const SizedBox(height: 12),
        const _Mastery('bluf'),
        const SizedBox(height: 18),
        _field(_to, 'To', label: 'To'),
        _field(_decision, 'I recommend… / We should… / I decided…',
            label: 'Decision (one sentence)'),
        for (var i = 0; i < 3; i++)
          _field(_r[i], 'Reason ${i + 1}', label: 'Reason ${i + 1}'),
        _field(_need, 'your alignment / budget / a decision', label: 'Need'),
        _field(_by, 'Thursday', label: 'By'),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: Listenable.merge([_decision, ..._r, _need, _by]),
          builder: (_, __) => OnoCard(
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TO ${_to.text.toUpperCase()}',
                    style: AppText.eyebrow(color: AppColors.accent)),
                const SizedBox(height: 8),
                Text(_composed.isEmpty ? 'Your message appears here.' : _composed,
                    style: AppText.body(color: AppColors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GhostButton('Copy',
                  icon: Icons.copy_rounded,
                  onPressed: () => copyText(context, _composed)),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton('Save & tick', onPressed: () {
                if (_decision.text.trim().isEmpty) {
                  toast(context, 'Write the decision first.');
                  return;
                }
                system.logProtocolUse('bluf',
                    text: _composed, data: {'to': _to.text.trim()});
                _doneAndBack(context, 'BLUF saved — today\'s list updated.');
              }),
            ),
          ],
        ),
        _history(context, system.logsOf('bluf'), (e) => e.text,
            title: 'Your BLUFs'),
      ],
    );
  }
}

// ── Six questions deep ─────────────────────────────────────────────────

class _SixQTool extends StatefulWidget {
  const _SixQTool();

  @override
  State<_SixQTool> createState() => _SixQToolState();
}

class _SixQToolState extends State<_SixQTool> {
  final _meeting = TextEditingController();
  final _with = TextEditingController(text: activeProfile.manager);
  final _q = List.generate(6, (_) => TextEditingController());
  final _a = List.generate(6, (_) => TextEditingController());
  final _f = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in [_meeting, _with, ..._q, ..._a, ..._f]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final preps = system.logsOf('sixq');
    final open = preps.where((p) => p.str('outcome') == null).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Protocol · preparation is gravitas',
      title: 'Six questions deep',
      subtitle:
          'The six hardest questions they could ask, your answer, and the hardest follow-up to each answer.',
      children: [
        const SizedBox(height: 12),
        const _Mastery('six_deep'),
        if (open.isNotEmpty) ...[
          const SectionHeader('After the meeting'),
          for (final p in open)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${p.str('meeting')} · ${p.str('with')} · ${shortDate(p.date)}',
                          style: AppText.body(color: AppColors.white)),
                    ),
                    for (final o in ['held', 'shaky'])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ActionChip(
                          label: Text(o == 'held' ? 'Held' : 'Shaky'),
                          onPressed: () => system.updateLog(p.copyWith(
                              data: {...p.data, 'outcome': o})),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('New prep'),
        _field(_meeting, 'e.g. SA automation timeline', label: 'Meeting'),
        _field(_with, 'Who', label: 'With'),
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUESTION ${i + 1}', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _field(_q[i], 'The hard question'),
                  _field(_a[i], 'Your answer', lines: 2),
                  _field(_f[i], 'Their hardest follow-up — and your answer',
                      lines: 2),
                ],
              ),
            ),
          ),
        PrimaryButton('Save prep', onPressed: () {
          if (_meeting.text.trim().isEmpty) {
            toast(context, 'Name the meeting first.');
            return;
          }
          system.addLog('sixq', data: {
            'meeting': _meeting.text.trim(),
            'with': _with.text.trim(),
            'items': [
              for (var i = 0; i < 6; i++)
                if (_q[i].text.trim().isNotEmpty)
                  {'q': _q[i].text.trim(), 'a': _a[i].text.trim(), 'f': _f[i].text.trim()}
            ],
          });
          _doneAndBack(context,
              'Prep saved. Mark held / shaky after the meeting.');
        }),
        _history(
            context,
            preps,
            (e) =>
                '${e.str('meeting')} · ${(e.data['items'] as List? ?? []).length}/6${e.str('outcome') == null ? '' : ' · ${e.str('outcome')}'}',
            title: 'Past preps'),
      ],
    );
  }
}

// ── Lunch read ─────────────────────────────────────────────────────────

class _ReadTool extends StatefulWidget {
  const _ReadTool();

  @override
  State<_ReadTool> createState() => _ReadToolState();
}

class _ReadToolState extends State<_ReadTool> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final book = system.planBook;
    return OnoPage(
      showBack: true,
      eyebrow: '12:00 · 20 minutes',
      title: book.title,
      subtitle: '${book.author} · ${book.chapters}\n${book.why}',
      children: [
        const SizedBox(height: 26),
        Center(
          child: CountdownTimer(
            minutes: 20,
            label: 'phone face-down',
            onDone: () => setState(() => _finished = true),
          ),
        ),
        const SizedBox(height: 26),
        PrimaryButton(_finished ? 'Done — now write from memory' : 'I read 20 min',
            onPressed: () {
          system.logProtocolUse('read',
              data: {'book': book.title, 'minutes': 20});
          context.pushReplacement('/tool/feynman');
        }),
      ],
    );
  }
}

// ── Feynman ────────────────────────────────────────────────────────────

class _FeynmanTool extends StatefulWidget {
  const _FeynmanTool();

  @override
  State<_FeynmanTool> createState() => _FeynmanToolState();
}

class _FeynmanToolState extends State<_FeynmanTool> {
  final _chapter = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _chapter.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    // What you're reading now: the active learning item, else the plan's
    // book (built-in person), else just "your reading".
    final active = system.learningWith('active').firstOrNull;
    final bookTitle = active?.text ??
        (system.isBuiltInPerson && system.planBook != PersonalSystemProvider.noPlanBook ? system.planBook.title : 'Your reading');
    final notes = system
        .logsOf('feynman')
        .where((e) => e.str('book') == bookTitle)
        .toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Protocol · 5 minutes, no notes',
      title: 'Write from memory',
      subtitle:
          'Close the book. Explain what you just read in plain language. Where you blank is the gap.',
      children: [
        const SizedBox(height: 12),
        const _Mastery('feynman'),
        const SizedBox(height: 18),
        Text(bookTitle.toUpperCase(), style: AppText.eyebrow()),
        const SizedBox(height: 8),
        _field(_chapter, 'e.g. Ch. 3 — opportunity solution trees',
            label: 'Chapter'),
        _field(_note, 'Explain it to a smart 12-year-old…', lines: 8),
        const SizedBox(height: 6),
        PrimaryButton('Save note & tick', onPressed: () {
          if (_note.text.trim().length < 20) {
            toast(context, 'Write a few sentences first.');
            return;
          }
          system.logProtocolUse('feynman',
              text: _note.text.trim(),
              data: {'book': bookTitle, 'chapter': _chapter.text.trim()});
          _doneAndBack(context, 'Feynman note saved — today\'s list updated.');
        }),
        _history(
            context,
            notes,
            (e) =>
                '${(e.str('chapter') ?? '').isEmpty ? '' : '${e.str('chapter')} — '}${e.text}',
            title: 'Notes on this'),
      ],
    );
  }
}

// ── Domain scan ────────────────────────────────────────────────────────

class _ScanTool extends StatefulWidget {
  const _ScanTool();

  @override
  State<_ScanTool> createState() => _ScanToolState();
}

class _ScanToolState extends State<_ScanTool> {
  final _insight = TextEditingController();

  @override
  void dispose() {
    _insight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final src = domainScanFor(DateTime.now());
    return OnoPage(
      showBack: true,
      eyebrow: '07:45 · 15 minutes',
      title: src.title,
      subtitle: src.detail,
      children: [
        if (src.url != null) ...[
          const SizedBox(height: 14),
          GhostButton('Open ${src.title}',
              icon: Icons.north_east_rounded,
              onPressed: () => openLink(src.url!)),
        ],
        const SizedBox(height: 22),
        const Center(child: CountdownTimer(minutes: 15, label: 'scan')),
        const SizedBox(height: 22),
        _field(_insight,
            'One insight you\'d tell ${activeProfile.manager} — and why it matters for ${activeProfile.focus}',
            lines: 3),
        PrimaryButton('Save insight & tick', onPressed: () {
          system.logProtocolUse('scan',
              text: _insight.text.trim(), data: {'source': src.title});
          _doneAndBack(context, 'Scan logged — today\'s list updated.');
        }),
        _history(
            context,
            system.logsOf('scan').where((e) => e.text.isNotEmpty).toList(),
            (e) => '${e.str('source')}: ${e.text}',
            title: 'Domain bank'),
      ],
    );
  }
}

// ── Pennebaker ─────────────────────────────────────────────────────────

class _PennebakerTool extends StatefulWidget {
  const _PennebakerTool();

  @override
  State<_PennebakerTool> createState() => _PennebakerToolState();
}

class _PennebakerToolState extends State<_PennebakerTool> {
  final _text = TextEditingController();
  bool _keep = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final n = system.pennebakerSessions;
    return OnoPage(
      showBack: true,
      eyebrow: 'Tuesday · session ${n >= 4 ? 4 : n + 1} of 4',
      title: 'Pennebaker writing',
      subtitle:
          'Fifteen minutes about your deepest fears and anxieties, without stopping. Nobody reads this.',
      children: [
        const SizedBox(height: 14),
        TickSegments(total: 4, filled: n.clamp(0, 4), color: AppColors.mind),
        const SizedBox(height: 6),
        Text(n >= 4 ? 'All four sessions done.' : '$n of 4 done',
            style: AppText.small()),
        const SizedBox(height: 22),
        const Center(child: CountdownTimer(minutes: 15, label: 'write')),
        const SizedBox(height: 22),
        _field(_text, 'Start anywhere. Keep the pen moving.', lines: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _keep,
          onChanged: (v) => setState(() => _keep = v),
          title: Text('Keep the text', style: AppText.body()),
          subtitle: Text(
              'Off: only the session is counted; the words are discarded.',
              style: AppText.small()),
        ),
        const SizedBox(height: 6),
        PrimaryButton('Finish session', onPressed: () {
          system.addLog('pennebaker',
              text: _keep ? _text.text.trim() : '',
              data: {'minutes': 15, 'session': n + 1});
          _doneAndBack(context, 'Session ${n + 1} of 4 done.');
        }),
      ],
    );
  }
}

// ── Anki ───────────────────────────────────────────────────────────────

class _AnkiTool extends StatelessWidget {
  const _AnkiTool();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = dayOnly(DateTime.now());
    final week = weekStartOf(today);
    final reviewedToday = system
        .logsOn(today, 'anki')
        .any((e) => e.str('kind') == 'review');
    final newThisWeek = system
        .logsOf('anki')
        .where((e) => e.str('kind') == 'new' && !e.date.isBefore(week))
        .fold<int>(0, (s, e) => s + (e.number('count')?.toInt() ?? 0));
    var reviewDays = 0;
    for (var d = today;; d = d.minusDays(1)) {
      final hit = system
          .logsOn(d, 'anki')
          .any((e) => e.str('kind') == 'review');
      if (!hit) {
        if (d == today) continue;
        break;
      }
      reviewDays++;
      if (reviewDays > 400) break;
    }
    return OnoPage(
      showBack: true,
      eyebrow: 'Spaced repetition',
      title: 'Anki',
      subtitle:
          '5 minutes of review daily beats an hour of re-reading. Add 5 new cards a week from what you read.',
      children: [
        const SizedBox(height: 18),
        OnoCard(
          child: Row(
            children: [
              Expanded(child: StatTile('$reviewDays', 'review streak (days)')),
              Expanded(
                  child: StatTile('$newThisWeek', 'new cards this week',
                      unit: '/5')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
            'Review ONO deck · ${system.dueCards(today).length} due',
            icon: Icons.style_rounded,
            onPressed: () => context.push('/review')),
        const SizedBox(height: 10),
        GhostButton(
            reviewedToday ? 'Reviewed today ✓' : 'I reviewed in the Anki app',
            onPressed: reviewedToday
                ? null
                : () => system.addLog('anki', data: {'kind': 'review'})),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final n in [1, 3, 5])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('+$n new'),
                  onPressed: () =>
                      system.addLog('anki', data: {'kind': 'new', 'count': n}),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Artifact of the month ──────────────────────────────────────────────

class _ArtifactTool extends StatefulWidget {
  final int? month;
  const _ArtifactTool({this.month});

  @override
  State<_ArtifactTool> createState() => _ArtifactToolState();
}

class _ArtifactToolState extends State<_ArtifactTool> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String _kind = 'PR/FAQ';
  bool _seeded = false;

  static const _kinds = ['PR/FAQ', 'OST', 'Strategy doc', '6-pager', 'Other'];
  static const _statuses = ['idea', 'draft', 'review', 'shipped'];

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final month = widget.month ?? system.programMonth;
    if (!_seeded) {
      _seeded = true;
      _title.text = artifactFor(month);
    }
    final all = system.logsOf('artifact');
    return OnoPage(
      showBack: true,
      eyebrow: 'One per month · month $month',
      title: 'Artifact',
      subtitle: 'The thinking made visible: PR/FAQ, OST, strategy doc, 6-pager.',
      children: [
        if (all.isNotEmpty) ...[
          const SectionHeader('Your artifacts'),
          for (final a in all)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.str('title') ?? '', style: AppText.heading()),
                    Text('${a.str('kind')} · month ${a.number('month')}',
                        style: AppText.small()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final s in _statuses)
                          ChoiceChip(
                            label: Text(s),
                            selected: a.str('status') == s,
                            onSelected: (_) => system.updateLog(
                                a.copyWith(data: {...a.data, 'status': s})),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('New artifact'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in _kinds)
              ChoiceChip(
                label: Text(k),
                selected: _kind == k,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _field(_title, 'Title', label: 'Title'),
        _field(_notes, 'Link or where it lives', label: 'Link / notes'),
        PrimaryButton('Add artifact', onPressed: () {
          system.addLog('artifact', text: _notes.text.trim(), data: {
            'month': month,
            'kind': _kind,
            'title': _title.text.trim(),
            'status': 'draft',
          });
          toast(context, 'Artifact added as draft.');
          _notes.clear();
        }),
      ],
    );
  }
}

// ── LinkedIn post log ──────────────────────────────────────────────────

class _LinkedInTool extends StatefulWidget {
  const _LinkedInTool();

  @override
  State<_LinkedInTool> createState() => _LinkedInToolState();
}

class _LinkedInToolState extends State<_LinkedInTool> {
  final _hook = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _hook.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final week = weekStartOf(DateTime.now());
    final thisWeek = system
        .logsOf('linkedin')
        .where((e) => !e.date.isBefore(week))
        .length;
    final cadenceOn = system.programMonth >= 2;
    return OnoPage(
      showBack: true,
      eyebrow: cadenceOn ? '2 posts a week' : 'Cadence starts in month 2',
      title: 'LinkedIn posts',
      subtitle:
          'Hook (surprising claim or number) → real insight → one example → one question. 150–250 words, no links in the body.',
      children: [
        const SizedBox(height: 16),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TickSegments(total: 2, filled: thisWeek.clamp(0, 2)),
              const SizedBox(height: 8),
              Text(
                  '$thisWeek this week · ${system.countOf('linkedin')} published in total',
                  style: AppText.small()),
            ],
          ),
        ),
        const SectionHeader('Log a post'),
        _field(_hook, 'First line / topic', label: 'Hook'),
        _field(_url, 'https://linkedin.com/…', label: 'Link (optional)'),
        PrimaryButton('Published', onPressed: () {
          if (_hook.text.trim().isEmpty) {
            toast(context, 'Add the hook.');
            return;
          }
          system.addLog('linkedin',
              text: _hook.text.trim(), data: {'url': _url.text.trim()});
          _hook.clear();
          _url.clear();
          toast(context, 'Post logged.');
        }),
        _history(context, system.logsOf('linkedin'), (e) => e.text,
            title: 'Published'),
      ],
    );
  }
}

// ── Wish people well (loving-kindness) ─────────────────────────────────

/// Five short steps of loving-kindness: yourself, someone close, someone
/// you barely know, someone hard, everyone. Raises positive emotion with
/// medium effects (Zeng et al. 2015). Ticks "Wish three people well" when
/// it is one of today's items.
class _MettaTool extends StatefulWidget {
  const _MettaTool();

  @override
  State<_MettaTool> createState() => _MettaToolState();
}

class _MettaToolState extends State<_MettaTool> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final close = system.activePeople.firstOrNull?.text.split(' ').first;
    final steps = [
      ('Yourself', 'Start with you. You count too.'),
      (close == null ? 'Someone close' : 'Someone close — $close?', 'Picture them for a moment.'),
      ('Someone you barely know', 'The person at the shop, a neighbour, a colleague you rarely talk to.'),
      ('Someone you find hard', 'Only as far as feels honest today. A little is enough.'),
      ('Everyone', 'Everyone you will meet today, and everyone you won\'t.'),
    ];
    final (who, hint) = steps[_step];
    final last = _step == steps.length - 1;
    return OnoPage(
      showBack: true,
      eyebrow: 'Wish people well · ${_step + 1} of ${steps.length}',
      title: who,
      subtitle: hint,
      bottomBar: PrimaryButton(last ? 'Done' : 'Next',
          key: const Key('metta-next'),
          icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded, onPressed: () {
        if (!last) {
          setState(() => _step++);
          return;
        }
        system.addLog('metta');
        final item = system.dailyItems
            .where((d) => d.title.toLowerCase().startsWith('wish three people well'))
            .firstOrNull;
        if (item != null) system.setCheck(system.logicalToday, item.id, true);
        HapticFeedback.mediumImpact();
        toast(context, item == null ? 'Done.' : 'Done. Ticked for today.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SizedBox(height: 40),
        Text('May you be safe.\nMay you be well.\nMay you live with ease.',
            textAlign: TextAlign.center, style: AppText.serif(size: 30)),
        const SizedBox(height: 24),
        Text('Say it slowly, silently, three times. Then go on.',
            textAlign: TextAlign.center, style: AppText.small()),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

// ── Signature strengths ────────────────────────────────────────────────

/// Pick your top strengths, then use one in a new way this week.
class StrengthsScreen extends StatefulWidget {
  const StrengthsScreen({super.key});

  @override
  State<StrengthsScreen> createState() => _StrengthsScreenState();
}

class _StrengthsScreenState extends State<StrengthsScreen> {
  final _how = TextEditingController();
  late List<String> _top;
  String? _using;

  @override
  void initState() {
    super.initState();
    final system = context.read<PersonalSystemProvider>();
    _top = [...system.signatureStrengths];
    _using = system.strengthOfTheWeek;
  }

  @override
  void dispose() {
    _how.dispose();
    super.dispose();
  }

  void _toggle(PersonalSystemProvider system, String s) {
    setState(() {
      if (_top.contains(s)) {
        _top.remove(s);
      } else if (_top.length < PersonalSystemProvider.maxSignatureStrengths) {
        _top.add(s);
      } else {
        toast(context, 'Five at most — the ones that feel most like you.');
        return;
      }
    });
    system.setSignatureStrengths(_top);
    if (_using == null || !_top.contains(_using)) {
      setState(() => _using = _top.firstOrNull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final uses = system.logsOf('strength_use').take(5).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Signature strengths',
      title: 'What you\'re best at being',
      subtitle:
          'Pick up to five strengths that feel most like you — the ones that energise you when you use them. Then use one in a new way each day this week.',
      children: [
        if (_top.isNotEmpty) ...[
          const SectionHeader('Use one in a new way'),
          OnoCard(
            highlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in _top)
                      ChoiceChip(
                        label: Text(s),
                        selected: _using == s,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _using = s),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _how,
                  minLines: 1,
                  maxLines: 4,
                  style: AppText.body(color: AppColors.white),
                  decoration: InputDecoration(
                      hintText: _using == null
                          ? 'How did you use it?'
                          : 'A new way you used ${_using!.toLowerCase()} today'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${system.strengthUsesInWeek(DateTime.now())} this week',
                          style: AppText.small()),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_using == null || _how.text.trim().isEmpty) {
                          toast(context, 'Write how you used it.');
                          return;
                        }
                        system.logStrengthUse(_using!, _how.text);
                        _how.clear();
                        toast(context, 'Saved.');
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                for (final u in uses)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${u.str('strength')}: ${u.text}',
                        style: AppText.small()),
                  ),
              ],
            ),
          ),
        ],
        SectionHeader('Your top ${_top.length}/${PersonalSystemProvider.maxSignatureStrengths}'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, e)
                  in PersonalSystemProvider.characterStrengths.entries.indexed) ...[
                if (i > 0) const Divider(indent: 16),
                CheckboxListTile(
                  value: _top.contains(e.key),
                  onChanged: (_) => _toggle(system, e.key),
                  title: Text(e.key, style: AppText.heading()),
                  subtitle: Text(e.value, style: AppText.small()),
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: AppColors.accent,
                  checkColor: AppColors.ink,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('From the VIA classification of character strengths (Peterson & Seligman 2004).',
            style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Personal board ─────────────────────────────────────────────────────

/// The people who help you grow, by the role they play — and the gaps.
class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  Future<void> _pick(BuildContext context, PersonalSystemProvider system,
      String role) async {
    final people = system.people;
    if (people.isEmpty) {
      toast(context, 'Add people first under People.');
      context.push('/people');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final s = ctx.watch<PersonalSystemProvider>();
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Text(_title(role), style: AppText.title()),
                  const SizedBox(height: 4),
                  Text(PersonalSystemProvider.boardRoles[role]!,
                      style: AppText.small()),
                  const SizedBox(height: 8),
                  for (final p in s.people)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: s.boardRolesOf(p).contains(role),
                      activeColor: AppColors.accent,
                      checkColor: AppColors.ink,
                      title: Text(p.text,
                          style: AppText.body(color: AppColors.white)),
                      subtitle: (p.str('role') ?? '').isEmpty
                          ? null
                          : Text(p.str('role')!, style: AppText.small()),
                      onChanged: (on) {
                        final roles = s.boardRolesOf(p);
                        s.setBoardRoles(p, [
                          ...roles.where((r) => r != role),
                          if (on == true) role,
                        ]);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _title(String role) =>
      role[0].toUpperCase() + role.substring(1);

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final board = system.board;
    final gaps = system.boardGaps;
    return OnoPage(
      showBack: true,
      eyebrow: 'Your personal board',
      title: 'Who helps you grow',
      subtitle:
          'No one person can be everything. People who grow fastest have several: someone who has walked the road, someone who speaks for them, someone who tells them the truth.',
      children: [
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Missing: ${gaps.map(_title).join(', ')}.',
              style: AppText.body(color: AppColors.accent)),
        ],
        const SizedBox(height: 4),
        for (final e in PersonalSystemProvider.boardRoles.entries) ...[
          SectionHeader(_title(e.key),
              action: '+ Add', onAction: () => _pick(context, system, e.key)),
          OnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.value, style: AppText.small()),
                const SizedBox(height: 6),
                if (board[e.key]!.isEmpty)
                  Text('Nobody yet', style: AppText.body(color: AppColors.faint))
                else
                  for (final p in board[e.key]!)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '${p.text}${system.daysSinceContact(p) > 60 ? ' · no contact in 60+ days' : ''}',
                          style: AppText.body(color: AppColors.white)),
                    ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── After-action review ────────────────────────────────────────────────

/// Four questions after an event that mattered, whether it went well or
/// not. What to change next time becomes a review card.
class AarScreen extends StatefulWidget {
  const AarScreen({super.key});

  @override
  State<AarScreen> createState() => _AarScreenState();
}

class _AarScreenState extends State<AarScreen> {
  final _event = TextEditingController();
  final _intended = TextEditingController();
  final _happened = TextEditingController();
  final _why = TextEditingController();
  final _sustain = TextEditingController();
  final _improve = TextEditingController();
  bool _wentWell = true;

  @override
  void dispose() {
    for (final c in [_event, _intended, _happened, _why, _sustain, _improve]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: 5,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    final past = context.watch<PersonalSystemProvider>().aars.take(3).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'After-action review · 10 minutes',
      title: 'Look back while it\'s fresh',
      subtitle:
          'After a launch, a talk, a game, a hard evening at home — success or not. Teams that review what went well as well as what didn\'t do better next time.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_event.text.trim().isEmpty) {
          toast(context, 'Name the event first.');
          return;
        }
        system.logAar(
          event: _event.text,
          intended: _intended.text,
          happened: _happened.text,
          why: _why.text,
          sustain: _sustain.text,
          improve: _improve.text,
          wentWell: _wentWell,
        );
        toast(
            context,
            _improve.text.trim().isEmpty
                ? 'Saved.'
                : 'Saved. "Next time" is now a review card.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        _field(_event, 'What was it?', 'e.g. The board presentation'),
        const SectionHeader('How did it go?'),
        Segmented(
          labels: const ['Well', 'Not well'],
          index: _wentWell ? 0 : 1,
          onChanged: (i) => setState(() => _wentWell = i == 0),
        ),
        _field(_intended, 'What was meant to happen?', 'The result you planned for'),
        _field(_happened, 'What actually happened?', 'The facts, not the verdict'),
        _field(_why, 'Why the difference?', 'What caused it — including what you did'),
        _field(_sustain, 'Keep: what worked that you\'ll do again', ''),
        _field(_improve, 'Change: one thing you\'ll do differently next time', ''),
        if (past.isNotEmpty) ...[
          const SectionHeader('Earlier reviews'),
          for (final a in past)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PastAar(a),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PastAar extends StatelessWidget {
  final LogEntry a;
  const _PastAar(this.a);

  @override
  Widget build(BuildContext context) => OnoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${a.text} · ${shortDate(a.date)}', style: AppText.heading()),
            if ((a.str('improve') ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Next time: ${a.str('improve')}', style: AppText.small()),
            ],
          ],
        ),
      );
}

// ── Courage ladder ─────────────────────────────────────────────────────

/// Things you avoid, rated by how hard they feel, climbed from the bottom
/// rung. Afterwards: how hard was it really? The gap between what you
/// feared and what you felt is what you learn (graded exposure).
class CourageScreen extends StatefulWidget {
  const CourageScreen({super.key});

  @override
  State<CourageScreen> createState() => _CourageScreenState();
}

class _CourageScreenState extends State<CourageScreen> {
  final _what = TextEditingController();
  double _fear = 5;

  @override
  void dispose() {
    _what.dispose();
    super.dispose();
  }

  void _did(PersonalSystemProvider system, LogEntry step) {
    final happened = TextEditingController();
    var felt = (step.number('fear') ?? 5).toDouble();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You did it', style: AppText.title()),
                Text(step.text, style: AppText.small()),
                const SizedBox(height: 14),
                Text('How hard was it, really? You expected ${step.number('fear')}.',
                    style: AppText.body(color: AppColors.white)),
                Slider(
                  key: const Key('courage-felt'),
                  value: felt,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${felt.round()}',
                  onChanged: (v) => setSheet(() => felt = v),
                ),
                TextField(
                  controller: happened,
                  minLines: 1,
                  maxLines: 3,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(hintText: 'What actually happened? (optional)'),
                ),
                const SizedBox(height: 12),
                PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
                  system.doCourageStep(step.id, felt: felt.round(), happened: happened.text);
                  Navigator.of(ctx).pop();
                  toast(context,
                      felt.round() < (step.number('fear') ?? 0)
                          ? 'Easier than you feared. Remember that before the next rung.'
                          : 'Done — and you know now what it takes.');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final ladder = system.courageLadder;
    final next = system.nextCourageStep;
    final done = system.courageDone;
    final gap = system.courageGap;
    return OnoPage(
      showBack: true,
      eyebrow: 'Practice · courage',
      title: 'Courage ladder',
      subtitle:
          'List what you avoid and how hard each feels. Start at the bottom rung. Afterwards, rate how hard it really was — the gap is what you learn.',
      children: [
        if (gap != null) ...[
          const SizedBox(height: 14),
          OnoCard(
            key: const Key('courage-gap'),
            accent: AppColors.skill,
            child: Text(
                gap > 0
                    ? 'Across ${done.length} steps, things felt ${gap.toStringAsFixed(1)} points easier than you feared.'
                    : gap < 0
                        ? 'Across ${done.length} steps, things felt ${(-gap).toStringAsFixed(1)} points harder than you expected. Take a smaller rung next.'
                        : 'Across ${done.length} steps, things felt as hard as you expected.',
                style: AppText.body(color: AppColors.white)),
          ),
        ],
        if (next != null) ...[
          const SectionHeader('Next rung'),
          OnoCard(
            accent: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.text, style: AppText.heading()),
                Text('Feels like ${next.number('fear')} of 10', style: AppText.small()),
                const SizedBox(height: 10),
                PrimaryButton('I did it',
                    key: const Key('courage-did'),
                    icon: Icons.check_rounded,
                    onPressed: () => _did(system, next)),
              ],
            ),
          ),
        ],
        const SectionHeader('Add a rung'),
        TextField(
          key: const Key('courage-what'),
          controller: _what,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'Something you avoid, e.g. speak first in the meeting'),
        ),
        const SizedBox(height: 8),
        Text('How hard does it feel? ${_fear.round()} of 10', style: AppText.small()),
        Slider(
          value: _fear,
          min: 0,
          max: 10,
          divisions: 10,
          label: '${_fear.round()}',
          onChanged: (v) => setState(() => _fear = v),
        ),
        GhostButton('Add to the ladder', icon: Icons.add_rounded, onPressed: () {
          if (system.addCourageStep(_what.text, fear: _fear.round()) == null) {
            toast(context, 'Write what you avoid first.');
            return;
          }
          _what.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }),
        if (ladder.length > 1) ...[
          const SectionHeader('Higher up'),
          for (final l in ladder.skip(1))
            Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${l.number('fear')}', style: AppText.heading()),
                ),
                Expanded(child: Text(l.text, style: AppText.body(color: AppColors.white))),
                IconButton(
                  tooltip: 'Take off the ladder',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.faint,
                  onPressed: () => system.dropCourageStep(l.id),
                ),
              ],
            ),
        ],
        if (done.isNotEmpty) ...[
          const SectionHeader('Climbed'),
          for (final l in done.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  '${l.text} · feared ${l.number('fear')}, felt ${l.number('felt')}${(l.str('happened') ?? '').isEmpty ? '' : ' — ${l.str('happened')}'}',
                  style: AppText.small(color: AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

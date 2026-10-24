import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

String _num(LogEntry goal, double v) =>
    PersonalSystemProvider.formatGoalNumber(goal, v);

Color _paceColor(String? pace) => switch (pace) {
      'ahead' || 'reached' => AppColors.body,
      'behind' || 'past due' => AppColors.warning,
      _ => AppColors.grey,
    };

/// The 6–18-month outcomes everything else serves. At most three active.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final active = system.activeGoals;
    final closed = system.goals.where((g) => !active.contains(g)).toList();
    final full = active.length >= PersonalSystemProvider.maxActiveGoals;
    return OnoPage(
      showBack: true,
      eyebrow: 'Direction',
      title: 'Goals',
      subtitle:
          'Up to three outcomes for the next 6–18 months. Each one names the obstacle in your way and what you\'ll do when it shows up.',
      children: [
        const SizedBox(height: 14),
        if (active.isEmpty) ...[
          OnoCard(
            accent: AppColors.accent,
            padding: EdgeInsets.zero,
            child: LinkRow(
              icon: Icons.flag_circle_outlined,
              color: AppColors.accent,
              title: 'Become ${activeProfile.targetRole}',
              subtitle: 'Suggested from your profile — start here or write your own',
              onTap: () => context.push(
                  '/goals/edit?title=${Uri.encodeComponent('Become ${activeProfile.targetRole}')}'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (final g in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoalTile(goal: g),
          ),
        PrimaryButton(full ? 'Three active — close one to add' : 'New goal',
            icon: Icons.add_rounded,
            onPressed: full ? null : () => context.push('/goals/edit')),
        if (closed.isNotEmpty) ...[
          const SectionHeader('Closed'),
          for (final g in closed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${g.str('status') == 'achieved' ? '✓ Achieved' : 'Dropped'} · ${g.text}${g.str('closed_on') == null ? '' : ' · ${g.str('closed_on')}'}',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A goal with its progress bar and pace; tap for detail.
class GoalTile extends StatelessWidget {
  final LogEntry goal;
  final bool compact;
  const GoalTile({super.key, required this.goal, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = system.goalProgress(goal);
    final pace = system.goalPace(goal);
    final deadline = system.goalDeadline(goal);
    final numeric = system.goalIsNumeric(goal);
    final unit = goal.str('unit') ?? '';
    final detail = numeric
        ? '${_num(goal, system.goalCurrent(goal)!)} → ${_num(goal, goal.number('target')!.toDouble())}${unit.isEmpty ? '' : ' $unit'}'
        : system.milestonesOf(goal).isEmpty
            ? 'Not measured yet — add a milestone'
            : '${system.milestonesOf(goal).where((m) => m.done).length}/${system.milestonesOf(goal).length} milestones';
    final now = system.now;
    return OnoCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      onTap: () => context.push('/goals/view?id=${goal.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading()),
              ),
              if (pace != null)
                Text(pace,
                    style: AppText.small(color: _paceColor(pace))
                        .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 5,
              color: AppColors.accent,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 6),
          Text(
              '$detail${deadline == null ? '' : ' · by ${shortDate(deadline)} ${deadline.year}'}',
              style: AppText.small()),
          if (compact && system.goalNextStep(goal) != null) ...[
            const SizedBox(height: 4),
            Text('Next: ${system.goalNextStep(goal)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.small(color: AppColors.white)),
          ],
          if (compact && system.weekOutcomesFor(goal.id, now) > 0)
            Text('${system.weekOutcomesFor(goal.id, now)} of this week\'s three serve it',
                style: AppText.small(color: AppColors.accent)),
        ],
      ),
    );
  }
}

/// One goal: progress, the trend, the WOOP, and measuring it.
class GoalScreen extends StatefulWidget {
  final String id;
  const GoalScreen({super.key, required this.id});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _value = TextEditingController();
  final _milestone = TextEditingController();
  final _next = TextEditingController();
  bool _nextLoaded = false;

  @override
  void dispose() {
    _value.dispose();
    _milestone.dispose();
    _next.dispose();
    super.dispose();
  }

  void _close(PersonalSystemProvider system, LogEntry g, String status) {
    system.setGoalStatus(g.id, status);
    if (status == 'achieved') {
      HapticFeedback.heavyImpact();
      toast(context, 'Achieved. Write down what made it happen — it\'s evidence.');
    } else {
      toast(context, 'Dropped on purpose. That frees room for what matters.');
    }
  }

  /// When the date has come or the target is met: decide on purpose.
  Widget _decision(PersonalSystemProvider system, LogEntry g) {
    final reached = system.goalPace(g) == 'reached';
    final now = dayOnly(system.now);
    return OnoCard(
      key: const Key('goal-decision'),
      accent: AppColors.accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reached ? 'You reached the target' : 'Its date has come',
              style: AppText.title()),
          const SizedBox(height: 4),
          Text(
              reached
                  ? 'Close it as achieved and write down what made it happen — or raise the bar in Edit.'
                  : 'Decide on purpose: an open goal past its date quietly costs attention.',
              style: AppText.small()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilledButton(
                  onPressed: () => _close(system, g, 'achieved'),
                  child: const Text('Achieved')),
              if (!reached)
                for (final m in const [1, 3])
                  OutlinedButton(
                    onPressed: () {
                      system.setGoalDeadline(g.id, now.plusDays(m * 30));
                      toast(context, 'New date set. What changes so this one holds?');
                    },
                    child: Text('$m more month${m == 1 ? '' : 's'}'),
                  ),
              if (!reached)
                OutlinedButton(
                    onPressed: () => _close(system, g, 'dropped'),
                    child: const Text('Drop it')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final g = system.goalById(widget.id);
    if (g == null) {
      return const OnoPage(
          showBack: true,
          title: 'Goal not found',
          children: [EmptyNote('It may have been deleted.', icon: Icons.flag_outlined)]);
    }
    final numeric = system.goalIsNumeric(g);
    final values = system.goalValues(g.id);
    final unit = g.str('unit') ?? '';
    final active = (g.str('status') ?? 'active') == 'active';
    final expected = system.goalExpected(g);
    final pace = system.goalPace(g);
    final measured = system.goalIsMeasured(g);
    if (!_nextLoaded) {
      _nextLoaded = true;
      _next.text = g.str('next') ?? '';
    }
    String s(String k) => g.str(k) ?? '';
    return OnoPage(
      showBack: true,
      eyebrow: active ? 'Goal' : (s('status') == 'achieved' ? 'Achieved' : 'Dropped'),
      title: g.text,
      subtitle: s('why').isEmpty ? null : s('why'),
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile('${(system.goalProgress(g) * 100).round()}', 'done',
                    unit: '%')),
            Expanded(
                child: StatTile(expected == null ? '–' : '${(expected * 100).round()}',
                    'of the time used',
                    unit: expected == null ? '' : '%')),
            Expanded(child: StatTile(pace ?? '–', 'pace')),
          ],
        ),
        if (active && system.goalAtDecision(g)) ...[
          const SizedBox(height: 12),
          _decision(system, g),
        ] else if (active && pace == 'behind') ...[
          const SizedBox(height: 12),
          OnoCard(
            key: const Key('goal-behind'),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Behind the line', style: AppText.heading()),
                const SizedBox(height: 4),
                Text(
                    s('obstacle').isEmpty
                        ? 'What is really in the way? Name it, and what you\'ll do when it shows up.'
                        : 'Is "${s('obstacle')}" still what\'s in the way? If not, name the real one and re-plan.',
                    style: AppText.small()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    OutlinedButton(
                        onPressed: () => context.push('/goals/edit?id=${g.id}'),
                        child: const Text('Re-plan')),
                    OutlinedButton(
                        onPressed: () => context.push('/week'),
                        child: const Text('Put a step in this week')),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (active) ...[
          const SectionHeader('Next step'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('goal-next'),
                  controller: _next,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'The one next thing, small enough for this week'),
                  onSubmitted: (v) => system.setGoalNext(g.id, v),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const Key('goal-next-save'),
                tooltip: 'Save the step',
                icon: const Icon(Icons.check_rounded),
                onPressed: () {
                  system.setGoalNext(g.id, _next.text);
                  FocusManager.instance.primaryFocus?.unfocus();
                  toast(context, _next.text.trim().isEmpty
                      ? 'Cleared.'
                      : 'Saved. It shows on Today and is offered for the week\'s three.');
                },
              ),
            ],
          ),
        ],
        if (numeric) ...[
          const SectionHeader('Progress'),
          if (values.length >= 2)
            OnoCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: TrendLine(
                points: [
                  for (final v in values)
                    (x: v.date, y: (v.number('value') ?? 0).toDouble())
                ],
                unit: unit,
                color: AppColors.accent,
              ),
            )
          else
            Text('Start ${_num(g, g.number('start')!.toDouble())} · target ${_num(g, g.number('target')!.toDouble())}${unit.isEmpty ? '' : ' $unit'}. Log a measurement to start the line.',
                style: AppText.small()),
          for (final v in values.reversed.take(5))
            Row(
              children: [
                Expanded(
                  child: Text(
                      '${shortDate(v.date)} · ${_num(g, (v.number('value') ?? 0).toDouble())}${unit.isEmpty ? '' : ' $unit'}',
                      style: AppText.small(color: AppColors.white)),
                ),
                if (active)
                  IconButton(
                    tooltip: 'Remove this measurement',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.grey),
                    onPressed: () => system.removeLog(v.id),
                  ),
              ],
            ),
          if (active) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('goal-value'),
                    controller: _value,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    style: AppText.number(size: 18),
                    decoration: InputDecoration(
                        hintText: g.data['clock'] == true ? 'Today\'s time, e.g. 4:12' : 'Today\'s number',
                        suffixText: unit.isEmpty ? null : unit),
                  ),
                ),
                const SizedBox(width: 10),
                GhostButton('Log', icon: Icons.check_rounded, onPressed: () {
                  final v = PersonalSystemProvider.parseGoalNumber(_value.text);
                  if (v == null) {
                    toast(context, 'Enter a number.');
                    return;
                  }
                  system.logGoalValue(g.id, v);
                  _value.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                  HapticFeedback.mediumImpact();
                }),
              ],
            ),
          ],
        ] else ...[
          SectionHeader(measured ? 'Milestones' : 'How will you know it\'s moving?'),
          if (!measured)
            Text(
                'Without a milestone or a number ONO can\'t show progress. Add the first milestone below, or use Edit for a number.',
                style: AppText.small()),
          if (measured)
            OnoCard(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: Column(
                children: [
                  for (final (i, m) in system.milestonesOf(g).indexed)
                    CheckRow(
                      checked: m.done,
                      title: m.text,
                      onChanged: active ? (_) => system.toggleMilestone(g.id, i) : (_) {},
                    ),
                ],
              ),
            ),
          if (active)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('goal-milestone'),
                    controller: _milestone,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(hintText: 'Add a milestone'),
                    onSubmitted: (v) {
                      system.addMilestone(g.id, v);
                      _milestone.clear();
                    },
                  ),
                ),
                IconButton(
                  key: const Key('goal-milestone-add'),
                  tooltip: 'Add the milestone',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {
                    system.addMilestone(g.id, _milestone.text);
                    _milestone.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ],
            ),
        ],
        const SectionHeader('In the way, and your plan'),
        OnoCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OBSTACLE', style: AppText.eyebrow()),
              Text(s('obstacle').isEmpty ? '—' : s('obstacle'),
                  style: AppText.body(color: AppColors.white)),
              const SizedBox(height: 10),
              Text('IF IT SHOWS UP', style: AppText.eyebrow()),
              Text(s('plan').isEmpty ? '—' : s('plan'),
                  style: AppText.body(color: AppColors.white)),
              if (s('identity').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('WHO YOU\'RE BECOMING', style: AppText.eyebrow()),
                Text(s('identity'), style: AppText.serif(size: 20)),
              ],
            ],
          ),
        ),
        if ((g.data['areas'] as List? ?? const []).isNotEmpty) ...[
          const SectionHeader('Grown through'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in (g.data['areas'] as List))
                ActionChip(
                  label: Text(system.areaById('$a').name),
                  onPressed: () => context.push('/growth'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        if (active) ...[
          GhostButton('Edit', icon: Icons.edit_outlined,
              onPressed: () => context.push('/goals/edit?id=${g.id}')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _close(system, g, 'achieved'),
                  child: const Text('Mark achieved'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _close(system, g, 'dropped'),
                  child: const Text('Drop on purpose'),
                ),
              ),
            ],
          ),
        ] else ...[
          if ((g.str('reflection') ?? '').isNotEmpty) ...[
            SectionHeader(g.str('status') == 'achieved' ? 'What made it happen' : 'What dropping it taught'),
            Text(g.str('reflection')!, style: AppText.body(color: AppColors.white)),
            if ((g.str('advice') ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('To someone starting: ${g.str('advice')}', style: AppText.small()),
            ],
          ] else
            _GoalReflection(goal: g),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (!system.setGoalStatus(g.id, 'active')) {
                toast(context, 'Three goals are active. Close one first.');
              }
            },
            child: const Text('Reopen'),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Create or edit a goal, walked through WOOP: wish, outcome, obstacle,
/// plan — then how it's measured, by when, and what grows it.
class GoalEditScreen extends StatefulWidget {
  final String? id;
  final String? title;
  const GoalEditScreen({super.key, this.id, this.title});

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  final _title = TextEditingController();
  final _why = TextEditingController();
  final _obstacle = TextEditingController();
  final _plan = TextEditingController();
  final _identity = TextEditingController();
  final _unit = TextEditingController();
  final _start = TextEditingController();
  final _target = TextEditingController();
  final _milestones = <TextEditingController>[];
  bool _numeric = true;
  int? _months = 6;
  DateTime? _deadline;
  final Set<String> _areas = {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _title.text = widget.title ?? '';
    final existing = widget.id == null
        ? 0
        : context.read<PersonalSystemProvider>().goalById(widget.id!) == null
            ? 0
            : context
                .read<PersonalSystemProvider>()
                .milestonesOf(context.read<PersonalSystemProvider>().goalById(widget.id!)!)
                .length;
    _milestones.addAll(List.generate(
        existing < 3 ? 3 : existing + 1, (_) => TextEditingController()));
    final g = widget.id == null
        ? null
        : context.read<PersonalSystemProvider>().goalById(widget.id!);
    if (g == null) return;
    final system = context.read<PersonalSystemProvider>();
    String s(String k) => g.str(k) ?? '';
    _title.text = g.text;
    _why.text = s('why');
    _obstacle.text = s('obstacle');
    _plan.text = s('plan');
    _identity.text = s('identity');
    _numeric = system.goalIsNumeric(g);
    _unit.text = s('unit');
    if (_numeric) {
      _start.text = _num(g, g.number('start')!.toDouble());
      _target.text = _num(g, g.number('target')!.toDouble());
    } else if (system.milestonesOf(g).isEmpty) {
      _numeric = false;
    }
    for (final (i, m) in system.milestonesOf(g).indexed) {
      _milestones[i].text = m.text;
    }
    _deadline = system.goalDeadline(g);
    _months = null;
    _areas.addAll([for (final a in (g.data['areas'] as List? ?? const [])) '$a']);
  }

  @override
  void dispose() {
    for (final c in [_title, _why, _obstacle, _plan, _identity, _unit, _start, _target, ..._milestones]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? get _due => _months == null
      ? _deadline
      : dayOnly(timeNow()).plusDays(_months! * 30);

  void _save() {
    final system = context.read<PersonalSystemProvider>();
    if (_title.text.trim().isEmpty) {
      toast(context, 'Name the goal first.');
      return;
    }
    double? n(TextEditingController c) =>
        PersonalSystemProvider.parseGoalNumber(c.text);
    if (_numeric && (n(_start) == null || n(_target) == null)) {
      toast(context, 'Enter where you start and the target — or use milestones.');
      return;
    }
    if (!_numeric && _milestones.every((m) => m.text.trim().isEmpty)) {
      toast(context, 'Add at least one milestone.');
      return;
    }
    final saved = system.saveGoal(
      id: widget.id,
      title: _title.text,
      why: _why.text,
      obstacle: _obstacle.text,
      plan: _plan.text,
      identity: _identity.text,
      deadline: _due,
      areas: _areas.toList(),
      unit: _numeric ? _unit.text : '',
      start: _numeric ? n(_start) : null,
      target: _numeric ? n(_target) : null,
      clock: _numeric && (_start.text.contains(':') || _target.text.contains(':')),
      milestones: _numeric ? const [] : [for (final m in _milestones) m.text],
    );
    if (saved == null) {
      toast(context, 'Three goals are active. Close one first.');
      return;
    }
    HapticFeedback.mediumImpact();
    if (widget.id == null) {
      context.pushReplacement('/goals/view?id=${saved.id}');
    } else {
      context.canPop() ? context.pop() : context.go('/goals');
    }
  }

  TextField _field(TextEditingController c, String hint,
          {int lines = 1, TextInputType? type, Key? key}) =>
      TextField(
        key: key,
        controller: c,
        minLines: lines,
        maxLines: lines + 2,
        keyboardType: type,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint),
      );

  Widget _step(String label, String help) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.title()),
            Text(help, style: AppText.small()),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    const number = TextInputType.numberWithOptions(decimal: true, signed: true);
    return OnoPage(
      showBack: true,
      eyebrow: widget.id == null ? 'New goal · WOOP' : 'Edit goal',
      title: widget.id == null ? 'What do you want?' : 'Edit goal',
      subtitle:
          'Wish, outcome, obstacle, plan. Naming the obstacle — and what you\'ll do when it shows up — is what makes the wish happen.',
      bottomBar: PrimaryButton('Save goal', icon: Icons.check_rounded, onPressed: _save),
      children: [
        _step('Wish', 'Specific and a little scary. Something you control enough to move.'),
        _field(_title, 'e.g. Run a marathon under 4 hours', key: const Key('goal-title')),
        _step('Outcome', 'The best thing about achieving it — why it matters to you.'),
        _field(_why, 'Picture it: what changes when it\'s true?', lines: 2),
        _step('Obstacle', 'What inside you is most likely to get in the way?'),
        _field(_obstacle, 'e.g. I skip training when work runs late', lines: 2),
        _step('Plan', 'If the obstacle shows up, then you will…'),
        _field(_plan, 'If work runs late, then I run at 6:30 the next morning', lines: 2),
        _step('Who you\'re becoming', 'Optional: one line of identity.'),
        _field(_identity, 'I am someone who…'),
        _step('How you\'ll measure it', 'A number if it has one; milestones if it doesn\'t.'),
        Row(
          children: [
            ChoiceChip(
              label: const Text('A number'),
              selected: _numeric,
              showCheckmark: false,
              onSelected: (_) => setState(() => _numeric = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Milestones'),
              selected: !_numeric,
              showCheckmark: false,
              onSelected: (_) => setState(() => _numeric = false),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_numeric) ...[
          _field(_unit, 'Unit (e.g. min, kg, AZN, posts)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_start, 'Now', type: number)),
              const SizedBox(width: 10),
              Expanded(child: _field(_target, 'Target', type: number)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Lower can be better (85 → 78 kg). Times work as m:ss: 4:30 → 3:59.',
              style: AppText.small()),
        ] else ...[
          for (var i = 0; i < _milestones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _field(_milestones[i], 'Milestone ${i + 1}'),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _milestones.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Another milestone'),
            ),
          ),
        ],
        _step('By when', 'A deadline lets ONO tell you if you\'re on pace.'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in const [3, 6, 9, 12, 18])
              ChoiceChip(
                label: Text('$m months'),
                selected: _months == m,
                showCheckmark: false,
                onSelected: (_) => setState(() => _months = m),
              ),
            if (_deadline != null && _months == null)
              ChoiceChip(
                label: Text('${shortDate(_deadline!)} ${_deadline!.year}'),
                selected: true,
                showCheckmark: false,
                onSelected: (_) {},
              ),
          ],
        ),
        _step('Grown through', 'Optional: the growth areas that move this goal.'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in system.allGrowthAreas)
              FilterChip(
                label: Text(a.name),
                selected: _areas.contains(a.id),
                showCheckmark: false,
                onSelected: (on) => setState(
                    () => on ? _areas.add(a.id) : _areas.remove(a.id)),
              ),
          ],
        ),
        if (widget.id != null) ...[
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              system.deleteGoal(widget.id!);
              context.go('/goals');
            },
            child: Text('Delete this goal', style: AppText.small(color: AppColors.danger)),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Looking back once a goal is closed.
class _GoalReflection extends StatefulWidget {
  final LogEntry goal;
  const _GoalReflection({required this.goal});

  @override
  State<_GoalReflection> createState() => _GoalReflectionState();
}

class _GoalReflectionState extends State<_GoalReflection> {
  final _worked = TextEditingController();
  final _advice = TextEditingController();

  @override
  void dispose() {
    _worked.dispose();
    _advice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achieved = widget.goal.str('status') == 'achieved';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Look back'),
        TextField(
          controller: _worked,
          minLines: 2,
          maxLines: 5,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(
              hintText: achieved
                  ? 'What made it happen? Habits, people, decisions'
                  : 'Why drop it — and what did it teach you?'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _advice,
          minLines: 1,
          maxLines: 3,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'What would you tell someone starting it?'),
        ),
        const SizedBox(height: 10),
        GhostButton('Save', icon: Icons.check_rounded, onPressed: () {
          if (_worked.text.trim().isEmpty) {
            toast(context, achieved ? 'Write what made it happen first.' : 'Write why you dropped it first.');
            return;
          }
          context
              .read<PersonalSystemProvider>()
              .reflectOnGoal(widget.goal.id, whatWorked: _worked.text, advice: _advice.text);
          toast(context, achieved ? 'Saved — and added to your wins.' : 'Saved.');
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/daily_library.dart';
import '../data/emin_system.dart';
import '../data/growth_templates.dart';
import '../data/life_wheel.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// A first plan in five minutes: who you are becoming, how your life is
/// going, one area to grow this month, one goal, and a few daily actions.
class PlanBuilderScreen extends StatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  static const _steps = ['You', 'Your life', 'This month', 'One goal', 'Every day'];
  static const _maxPicks = 7;

  int _step = 0;
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _target = TextEditingController();
  final Map<String, int> _wheel = {};
  GrowthArea? _area;
  int _rating = 2;
  final _goal = TextEditingController();
  final _why = TextEditingController();
  final _obstacle = TextEditingController();
  final _plan = TextEditingController();
  int _months = 6;
  int? _length;
  final List<DailyIdea> _picks = [];
  bool? _replace;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // First run starts empty: the built-in profile is someone else's until
    // its owner types their own name. A rebuild starts from the profile.
    final system = context.read<PersonalSystemProvider>();
    if (system.isCommissioned) {
      final p = activeProfile;
      _name.text = p.name;
      _current.text = p.currentRole;
      _target.text = p.targetRole;
    }
    _wheel.addAll(system.latestWheel);
  }

  @override
  void dispose() {
    for (final c in [_name, _current, _target, _goal, _why, _obstacle, _plan]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _newPerson => _name.text.trim().isNotEmpty && _name.text.trim() != activeProfile.name;

  /// The two lowest-rated areas of the wheel.
  List<LifeArea> get _lowest {
    final rated = [for (final a in lifeAreas) if (_wheel[a.id] != null) a]
      ..sort((a, b) => _wheel[a.id]!.compareTo(_wheel[b.id]!));
    return rated.take(2).toList();
  }

  List<GrowthArea> _suggested(PersonalSystemProvider system) {
    final ids = [for (final a in _lowest) a.template];
    return [
      for (final id in ids) ...areaTemplates.where((t) => t.id == id),
      for (final t in areaTemplates) if (!ids.contains(t.id)) t,
      if (!_newPerson) ...system.allGrowthAreas,
    ];
  }

  String? _problem() {
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) return 'Add your name.';
        if (_target.text.trim().isEmpty) return 'Name who you want to become.';
      case 1:
        if (_wheel.length < lifeAreas.length) return 'Rate all eight areas.';
      case 2:
        if (_area == null) return 'Pick one area to grow this month.';
      case 4:
        if (_picks.length < PersonalSystemProvider.minDailyItems &&
            (_replace ?? _newPerson)) {
          return 'Pick at least ${PersonalSystemProvider.minDailyItems}.';
        }
    }
    return null;
  }

  Future<void> _next(PersonalSystemProvider system) async {
    final problem = _problem();
    if (problem != null) {
      toast(context, problem);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    final now = DateTime.now();
    final newPerson = _newPerson;
    system.buildPlan(
      name: _name.text,
      currentRole: _current.text,
      targetRole: _target.text,
      wheel: Map.of(_wheel),
      area: _area!,
      areaRating: _rating,
      goal: _goal.text,
      goalWhy: _why.text,
      obstacle: _obstacle.text,
      plan: _plan.text,
      deadline: DateTime(now.year, now.month + _months, now.day),
      daily: List.of(_picks),
      replaceDaily: _replace ?? newPerson,
      programLength: _length,
    );
    // First run: a new person starts today with their own plan and no
    // built-in reminders (they switch on what they want under Me). The
    // built-in person goes on to the full setup: training days, reminders.
    if (!system.isCommissioned) {
      if (!newPerson) {
        if (mounted) context.go('/commission');
        return;
      }
      await system.commission(
        start: DateTime.now(),
        gymDays: system.gymDays,
        reminders: {for (final r in reminderDefs) r.id: false},
      );
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    toast(context, 'Your plan is ready.');
    context.go('/home');
  }

  Widget _field(TextEditingController c, String label, String hint, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines + 2,
          onChanged: (_) => setState(() {}),
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      // A new key per step, so each step opens at the top.
      key: ValueKey(_step),
      showBack: system.isCommissioned,
      eyebrow: 'Step ${_step + 1} of ${_steps.length} · ${_steps[_step]}',
      title: const [
        'Who are you becoming?',
        'How is your life going?',
        'One area to grow',
        'One goal that matters',
        'Small things, every day',
      ][_step],
      subtitle: const [
        'Five minutes to a plan of your own. A leader, an athlete, a parent — anyone.',
        'Rate each area honestly. The lowest tells you where growth would change the most.',
        'Practise one thing for a month. Start with where your wheel is lowest.',
        'The outcome all of this serves. Then the obstacle in you, and your plan for it.',
        'Pick 3 to 7. Each comes with a moment it is tied to — that is what makes it stick.',
      ][_step],
      bottomBar: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: GhostButton('Back',
                  icon: Icons.arrow_back_rounded, onPressed: () => setState(() => _step--)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(_step == _steps.length - 1 ? 'Build my plan' : 'Next',
                icon: _step == _steps.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: () => _next(system)),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 14),
        ...switch (_step) {
          0 => _you(),
          1 => _life(),
          2 => _focus(system),
          3 => _goalStep(),
          _ => _daily(system),
        },
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _you() => [
        if (_step == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () => context.push('/packs'),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('Or start from a ready-made plan'),
            ),
          ),
        _field(_name, 'Your name', 'First and last'),
        _field(_current, 'What you do now', 'e.g. Team lead, nurse, student, runner'),
        _field(_target, 'Who you want to become', 'e.g. Director, sub-4 marathoner, a calmer parent'),
        if (_newPerson)
          Text('A new name starts a fresh profile: your organisation, people and coach notes start empty.',
              style: AppText.small()),
      ];

  List<Widget> _life() => [
        Text('1 = badly neglected · 10 = exactly as you want it', style: AppText.small()),
        const SizedBox(height: 8),
        for (final a in lifeAreas)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(a.name, style: AppText.heading())),
                      Text(_wheel[a.id] == null ? '–' : '${_wheel[a.id]}',
                          style: AppText.number(size: 18)),
                    ],
                  ),
                  Slider(
                    key: Key('plan-wheel-${a.id}'),
                    value: (_wheel[a.id] ?? 5).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _wheel[a.id] == null ? AppColors.faint : AppColors.accent,
                    onChanged: (v) => setState(() => _wheel[a.id] = v.round()),
                  ),
                ],
              ),
            ),
          ),
      ];

  List<Widget> _focus(PersonalSystemProvider system) {
    final options = _suggested(system);
    final levels = _area == null ? const <String>[] : levelsOf(_area!);
    return [
      if (_lowest.isNotEmpty)
        Text('Lowest on your wheel: ${_lowest.map((a) => a.name).join(' and ')}.',
            style: AppText.small()),
      const SizedBox(height: 8),
      for (final a in options.take(10))
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: OnoCard(
            onTap: () => setState(() => _area = a),
            accent: _area?.id == a.id ? AppColors.accent : null,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(
                    _area?.id == a.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: _area?.id == a.id ? AppColors.accent : AppColors.faint),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: AppText.heading()),
                      Text(a.bar, style: AppText.small(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_area != null) ...[
        const SectionHeader('Where are you now?'),
        Segmented(
          labels: const ['1', '2', '3', '4', '5'],
          index: _rating - 1,
          onChanged: (i) => setState(() => _rating = i + 1),
        ),
        if (levels.length >= _rating)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(levels[_rating - 1], style: AppText.small()),
          ),
      ],
    ];
  }

  List<Widget> _goalStep() => [
        _field(_goal, 'The goal', 'e.g. Promoted to director · run a marathon · 3 months saved'),
        _field(_why, 'The best outcome', 'What would reaching it give you?'),
        _field(_obstacle, 'The obstacle in you', 'What in you is most likely to stop it?'),
        _field(_plan, 'If–then plan', 'When that happens, I will…'),
        const SectionHeader('By when'),
        Segmented(
          labels: const ['3 months', '6 months', '12 months'],
          index: const [3, 6, 12].indexOf(_months),
          onChanged: (i) => setState(() => _months = const [3, 6, 12][i]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Not sure yet? Leave it empty and add it later under Goals.',
              style: AppText.small()),
        ),
        const SectionHeader('Your program'),
        Builder(builder: (context) {
          final lengths = PersonalSystemProvider.programLengths.keys.toList();
          final current =
              _length ?? context.read<PersonalSystemProvider>().programDays;
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in lengths)
                ChoiceChip(
                  label: Text(PersonalSystemProvider.programLengths[d]!),
                  selected: current == d,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _length = d),
                ),
            ],
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
              'Four phases — foundation, craft, signal, leverage — spread over it. At the end you look back and start the next.',
              style: AppText.small()),
        ),
      ];

  List<Widget> _daily(PersonalSystemProvider system) {
    final first = {for (final a in _lowest) a.id};
    final ideas = [
      ...dailyLibrary.where((d) => first.contains(d.area)),
      ...dailyLibrary.where((d) => !first.contains(d.area)),
    ];
    final replace = _replace ?? _newPerson;
    return [
      if (system.dailyCount > 0)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: replace,
          onChanged: (v) => setState(() => _replace = v),
          title: Text('Replace my current daily list', style: AppText.body(color: AppColors.white)),
          subtitle: Text(
              replace
                  ? 'Your ${system.dailyCount} current items are retired; you can bring them back.'
                  : 'Added to your ${system.dailyCount} current items.',
              style: AppText.small()),
        ),
      Text('${_picks.length} picked', style: AppText.eyebrow(color: AppColors.accent)),
      const SizedBox(height: 6),
      for (final d in ideas)
        CheckRow(
          title: d.title,
          subtitle: d.cue,
          checked: _picks.contains(d),
          onChanged: (on) => setState(() {
            if (on && _picks.length >= _maxPicks) {
              toast(context, 'Seven is plenty to start. Add more once these hold.');
              return;
            }
            on ? _picks.add(d) : _picks.remove(d);
          }),
        ),
    ];
  }
}

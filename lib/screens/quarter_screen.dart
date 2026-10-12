import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../data/growth_templates.dart';
import '../data/life_wheel.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Every 90 days: rate the life wheel, name wins and lessons, decide on
/// each goal, and choose the next quarter's focus. A fresh start.
class QuarterScreen extends StatefulWidget {
  const QuarterScreen({super.key});

  @override
  State<QuarterScreen> createState() => _QuarterScreenState();
}

class _QuarterScreenState extends State<QuarterScreen> {
  final Map<String, int> _wheel = {};
  final _wins = TextEditingController();
  final _lessons = TextEditingController();
  final _next = TextEditingController();
  final Map<String, String> _goals = {};
  late int _quarter;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final system = context.read<PersonalSystemProvider>();
    _quarter = system.quarterToReview;
    final r = system.reviewFor(_quarter);
    if (r != null) {
      _wheel.addAll((r.data['wheel'] as Map? ?? const {})
          .map((k, v) => MapEntry('$k', (v as num).toInt())));
      _wins.text = r.str('wins') ?? '';
      _lessons.text = r.str('lessons') ?? '';
      _next.text = r.str('next') ?? '';
    } else {
      _wheel.addAll(system.latestWheel);
    }
  }

  @override
  void dispose() {
    _wins.dispose();
    _lessons.dispose();
    _next.dispose();
    super.dispose();
  }

  TextField _field(TextEditingController c, String hint) => TextField(
        controller: c,
        minLines: 2,
        maxLines: 6,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint),
      );

  /// The quarterly tools not yet done this quarter.
  List<(IconData, String, String, String)> _deeper(PersonalSystemProvider system) {
    final odysseyAge = system.odyssey == null
        ? null
        : DateTime.now().daysSince(system.odyssey!.date);
    return [
      if (system.roundFor(system.programQuarter) == null)
        (Icons.groups_2_outlined, 'Feedback round', 'One question to three people', '/360'),
      if (system.energyAudit == null)
        (Icons.battery_charging_full_rounded, 'What gives and drains you',
            'Rate a normal week, change one thing', '/crafting'),
      if (odysseyAge == null || odysseyAge > 80)
        (Icons.explore_outlined, 'Three possible lives',
            odysseyAge == null ? 'Sketch your options for five years' : 'Revisit the plan you made', '/odyssey'),
      if (system.bestSelf == null)
        (Icons.auto_awesome_outlined, 'You, at your best', 'Stories from people who have seen it', '/best-self'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final low = _wheel.isEmpty
        ? null
        : lifeAreas.where((a) => _wheel.containsKey(a.id)).fold<LifeArea?>(
            null,
            (m, a) => m == null || _wheel[a.id]! < _wheel[m.id]! ? a : m);
    final template = low == null
        ? null
        : areaTemplates.where((t) => t.id == low.template).firstOrNull;
    return OnoPage(
      showBack: true,
      eyebrow: 'Quarter $_quarter of 6 · 15 minutes',
      title: 'Quarterly review',
      subtitle:
          'Step back from the weeks. How is your whole life going, what did these 90 days teach you, and what matters most next?',
      bottomBar: PrimaryButton('Close the quarter', icon: Icons.check_rounded,
          onPressed: () {
        if (_wheel.length < lifeAreas.length) {
          toast(context, 'Rate all eight areas first.');
          return;
        }
        system.saveQuarterReview(_quarter,
            wheel: Map.of(_wheel),
            wins: _wins.text,
            lessons: _lessons.text,
            goalDecisions: Map.of(_goals),
            nextFocus: _next.text);
        HapticFeedback.heavyImpact();
        toast(context, 'Quarter closed. A fresh start begins now.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SectionHeader('1 · Your life wheel'),
        Text('1 = badly neglected · 10 = exactly as you want it', style: AppText.small()),
        const SizedBox(height: 8),
        for (final a in lifeAreas)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
                  Text(a.prompt, style: AppText.small()),
                  Slider(
                    key: Key('wheel-${a.id}'),
                    value: (_wheel[a.id] ?? 5).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _wheel[a.id] == null
                        ? AppColors.faint
                        : AppColors.accent,
                    onChanged: (v) => setState(() => _wheel[a.id] = v.round()),
                  ),
                ],
              ),
            ),
          ),
        if (low != null)
          OnoCard(
            accent: AppColors.warning,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lowest: ${low.name} (${_wheel[low.id]}/10)',
                    style: AppText.heading()),
                Text('Small gains in the lowest area often lift everything else.',
                    style: AppText.small()),
                if (template != null)
                  TextButton(
                    onPressed: () =>
                        context.push('/growth/area?template=${template.id}'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text('Make it a growth area: ${template.name}'),
                  ),
              ],
            ),
          ),
        const SectionHeader('2 · Wins'),
        _field(_wins, 'What went well these 90 days — the things you\'re proud of'),
        const SectionHeader('3 · Lessons'),
        _field(_lessons, 'What did you learn about yourself? What would you do differently?'),
        if (system.activeGoals.isNotEmpty) ...[
          const SectionHeader('4 · Your goals'),
          for (final g in system.activeGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.text, style: AppText.heading()),
                    Text('${(system.goalProgress(g) * 100).round()}% done${system.goalPace(g) == null ? '' : ' · ${system.goalPace(g)}'}',
                        style: AppText.small()),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final d in const ['keep', 'achieved', 'drop'])
                          ChoiceChip(
                            label: Text(switch (d) {
                              'keep' => 'Keep',
                              'achieved' => 'Achieved',
                              _ => 'Drop',
                            }),
                            selected: (_goals[g.id] ?? 'keep') == d,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _goals[g.id] = d),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        SectionHeader('${system.activeGoals.isEmpty ? 4 : 5} · Next quarter'),
        _field(_next, 'The one thing that would make the next 90 days a success'),
        if (_deeper(system).isNotEmpty) ...[
          const SectionHeader('Go deeper this quarter'),
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in _deeper(system).indexed) ...[
                  if (i > 0) const Divider(indent: 66),
                  LinkRow(
                    icon: d.$1,
                    color: AppColors.skill,
                    title: d.$2,
                    subtitle: d.$3,
                    onTap: () => context.push(d.$4),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

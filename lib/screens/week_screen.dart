import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// This week's Big 3: outcomes that would make the week a win. From
/// Saturday the next week can be planned too.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final week = weekStartOf(now);
    final next = week.plusDays(7);
    final planNext = now.weekday >= DateTime.saturday;
    final (done, set) = system.weekOutcomeScore(now);
    return OnoPage(
      showBack: true,
      eyebrow: system.isBuiltInPerson
          ? 'Month ${system.programMonth} · ${artifactFor(system.programMonth)}'
          : 'Month ${system.programMonth}',
      title: 'This week\'s three',
      subtitle: system.isBuiltInPerson
          ? 'Outcomes you control, specific enough to tick. One should move the artifact; daily priorities serve these.'
          : 'Outcomes you control, specific enough to tick. One should move a goal; daily priorities serve these.',
      children: [
        SectionHeader('Week of ${shortDate(week)}',
            action: set == 0 ? null : '$done/$set done'),
        _Outcomes(key: ValueKey(dateKey(week)), week: week, tickable: true),
        if (planNext) ...[
          SectionHeader('Next week · ${shortDate(next)}'),
          _Outcomes(key: ValueKey(dateKey(next)), week: next, tickable: false),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Outcomes extends StatefulWidget {
  final DateTime week;
  final bool tickable;
  const _Outcomes({super.key, required this.week, required this.tickable});

  @override
  State<_Outcomes> createState() => _OutcomesState();
}

class _OutcomesState extends State<_Outcomes> {
  late final List<TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final o = context.read<PersonalSystemProvider>().weekOutcomes(widget.week);
    _c = List.generate(3, (i) => TextEditingController(text: o[i]));
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final proposals = system.proposedOutcomes(widget.week);
    final empty = _c.where((c) => c.text.trim().isEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(context, system),
        // Not a blank page: what the goal, the growth area and the latest
        // feedback point to, in one tap.
        if (empty > 0 && proposals.isNotEmpty) ...[
          const SizedBox(height: 10),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUGGESTED FROM YOUR PLAN',
                    style: AppText.eyebrow(color: AppColors.accent)),
                const SizedBox(height: 6),
                for (final p in proposals.take(empty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${p.text}',
                        style: AppText.body(color: AppColors.white)),
                  ),
                TextButton(
                  key: Key('use-proposals-${dateKey(widget.week)}'),
                  onPressed: () {
                    system.useProposedOutcomes(widget.week);
                    final o = system.weekOutcomes(widget.week);
                    setState(() {
                      for (var i = 0; i < 3; i++) {
                        _c[i].text = o[i];
                      }
                    });
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(empty == 3 ? 'Use these' : 'Fill the empty ones'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, PersonalSystemProvider system) {
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Row(
              children: [
                if (widget.tickable)
                  IconButton(
                    tooltip: 'Mark this outcome done',
                    visualDensity: VisualDensity.compact,
                    onPressed: _c[i].text.trim().isEmpty
                        ? null
                        : () => system.toggleWeekOutcome(widget.week, i),
                    icon: Icon(
                      system.weekOutcomeDone(widget.week, i)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: system.weekOutcomeDone(widget.week, i)
                          ? AppColors.accent
                          : AppColors.faint,
                    ),
                  )
                else
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text('${i + 1}',
                          style:
                              AppText.serif(size: 20, color: AppColors.accent)),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    key: Key('week-${dateKey(widget.week)}-$i'),
                    controller: _c[i],
                    style: AppText.body(color: AppColors.white),
                    textInputAction: TextInputAction.next,
                    onChanged: (v) {
                      system.setWeekOutcome(widget.week, i, v);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        hintText: const [
                          'e.g. The hard email sent',
                          'e.g. Two evenings fully offline',
                          'e.g. Three workouts done',
                        ][i],
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false),
                  ),
                ),
              ],
            ),
            if (_c[i].text.trim().isNotEmpty && system.activeGoals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final g in system.activeGoals)
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(g.text, overflow: TextOverflow.ellipsis),
                        ),
                        selected:
                            system.weekOutcomeGoal(widget.week, i) == g.id,
                        showCheckmark: false,
                        onSelected: (on) => system.setWeekOutcomeGoal(
                            widget.week, i, on ? g.id : null),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

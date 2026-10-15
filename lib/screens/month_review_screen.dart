import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Close the month: what held, how the area moved, what you learned, and
/// what you carry into the next one.
class MonthReviewScreen extends StatefulWidget {
  const MonthReviewScreen({super.key});

  @override
  State<MonthReviewScreen> createState() => _MonthReviewScreenState();
}

class _MonthReviewScreenState extends State<MonthReviewScreen> {
  final _lesson = TextEditingController();
  final _carry = TextEditingController();
  late int _month;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    _month = system.monthToReview ?? system.programMonth;
    final r = system.monthReviewFor(_month);
    _carry.text = r?.text ?? '';
    _lesson.text = r?.str('lesson') ?? '';
  }

  @override
  void dispose() {
    _lesson.dispose();
    _carry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final m = _month;
    final held = system.monthHeld(m);
    final area = system.focusArea(m);
    final (start, end) = system.focusRatings(m);
    final from = system.monthStart(m), to = system.monthStart(m + 1);
    final wins = [
      for (final w in system.logsOf('win'))
        if (!w.date.isBefore(from) && w.date.isBefore(to)) w.text
    ];
    final levels = area == null ? const <String>[] : levelsOf(area);
    return OnoPage(
      showBack: true,
      eyebrow: 'Month $m of ${system.programMonths} · 10 minutes',
      title: 'Close the month',
      subtitle: 'Look at what happened, name one lesson, choose what comes with you.',
      bottomBar: PrimaryButton('Save the review', icon: Icons.check_rounded, onPressed: () {
        if (_carry.text.trim().isEmpty) {
          toast(context, 'Write what you carry into next month.');
          return;
        }
        system.saveMonthReview(m, carry: _carry.text, lesson: _lesson.text);
        toast(context, 'Month $m closed. A fresh start tomorrow.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: StatTile('${held.held}', 'of ${held.counted} days held')),
            Expanded(child: StatTile('${wins.length}', 'wins logged')),
            Expanded(
                child: StatTile('${held.hard.values.fold<int>(0, (a, b) => a + b)}', 'hard days')),
          ],
        ),
        if (area != null) ...[
          SectionHeader('Growing: ${area.name}'),
          Text(
              start == null
                  ? 'Rate where you are now against the bar.'
                  : 'You started at $start. Where are you now?',
              style: AppText.small()),
          for (final l in [
            for (final r in system.repsIn(area.id, m))
              if ((r.str('lesson') ?? '').trim().isNotEmpty) r.str('lesson')!.trim()
          ].take(3))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• You learned: $l',
                  style: AppText.small(color: AppColors.white)),
            ),
          for (final f in system.feedbackIn(area.id, m).take(2))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  '• ${(f.str('from') ?? '').isEmpty ? 'Someone' : f.str('from')} said: "${f.text}"',
                  style: AppText.small(color: AppColors.white)),
            ),
          const SizedBox(height: 8),
          Segmented(
            labels: const ['1', '2', '3', '4', '5'],
            index: (end ?? 0) - 1,
            onChanged: (i) => system.rateFocusEnd(i + 1, month: m),
          ),
          if (end != null && levels.length >= end)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(levels[end - 1], style: AppText.small()),
            ),
        ],
        if (wins.isNotEmpty) ...[
          const SectionHeader('Wins'),
          for (final w in wins.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $w', style: AppText.body(color: AppColors.white)),
            ),
        ],
        if (system.activeGoals.isNotEmpty) ...[
          const SectionHeader('Goals'),
          for (final g in system.activeGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                  '${g.text} · ${(system.goalProgress(g) * 100).round()}%${system.goalPace(g) == null ? '' : ' · ${system.goalPace(g)}'}',
                  style: AppText.body(color: AppColors.white)),
            ),
        ],
        const SectionHeader('One lesson'),
        TextField(
          controller: _lesson,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'What did this month teach you?'),
        ),
        const SectionHeader('Carry into next month'),
        TextField(
          controller: _carry,
          minLines: 3,
          maxLines: 6,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'One thing you\'re keeping, one you\'re changing, one to start.'),
        ),
        const SizedBox(height: 10),
        // Reviewing this month (day 27+): choose for the next one. Reviewing
        // last month (days 1–5): the "next" one is the month already on.
        GhostButton('Choose next month\'s area', icon: Icons.trending_up_rounded,
            onPressed: () => context.push(
                m == system.programMonth ? '/growth?next=1' : '/growth')),
        const SizedBox(height: 16),
      ],
    );
  }
}

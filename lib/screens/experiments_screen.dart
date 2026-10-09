import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Small tests of a change: try it for a fixed time, watch one number,
/// then keep it or drop it on purpose.
class ExperimentsScreen extends StatefulWidget {
  const ExperimentsScreen({super.key});

  @override
  State<ExperimentsScreen> createState() => _ExperimentsScreenState();
}

class _ExperimentsScreenState extends State<ExperimentsScreen> {
  final _change = TextEditingController();
  final _expect = TextEditingController();
  String _measure = 'energy';
  int _days = 14;

  @override
  void dispose() {
    _change.dispose();
    _expect.dispose();
    super.dispose();
  }

  String _fmt(double? v) => v == null ? '–' : v.toStringAsFixed(1);

  void _close(PersonalSystemProvider system, LogEntry e) {
    final note = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keep it or drop it?', style: AppText.title()),
            Text(e.text, style: AppText.small()),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  hintText: 'What did you notice? (numbers aside)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton('Keep it', icon: Icons.check_rounded,
                      onPressed: () {
                    system.closeExperiment(e.id, keep: true, result: note.text);
                    Navigator.of(ctx).pop();
                    HapticFeedback.mediumImpact();
                    toast(context, 'Kept. Consider making it a daily item.');
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton('Drop it', onPressed: () {
                    system.closeExperiment(e.id, keep: false, result: note.text);
                    Navigator.of(ctx).pop();
                    toast(context, 'Dropped on purpose. You learned something.');
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(note.dispose);
  }

  Widget _running(PersonalSystemProvider system, LogEntry e) {
    final c = system.experimentCompare(e);
    final days = (e.number('days') ?? 14).toInt();
    final day = system.experimentDay(e).clamp(1, days);
    final ended = system.experimentEnded(e);
    final measure = PersonalSystemProvider.experimentMeasures[e.str('measure')] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        accent: ended ? AppColors.accent : null,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ended ? 'FINISHED · DECIDE' : 'DAY $day OF $days',
                style: AppText.eyebrow(color: ended ? AppColors.accent : AppColors.grey)),
            const SizedBox(height: 4),
            Text(e.text, style: AppText.heading()),
            if ((e.str('expect') ?? '').isNotEmpty)
              Text('Expected: ${e.str('expect')}', style: AppText.small()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: StatTile(_fmt(c.before), '$measure before')),
                Expanded(child: StatTile(_fmt(c.during), 'during')),
              ],
            ),
            Text('${c.nBefore} days before · ${c.nDuring} days so far. A hint, not proof.',
                style: AppText.small().copyWith(fontSize: 12)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _close(system, e),
                child: Text(ended ? 'Keep or drop' : 'End early'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final running = system.experimentsWith('running');
    final closed = [
      ...system.experimentsWith('kept'),
      ...system.experimentsWith('dropped'),
    ];
    final ideas = system.patterns().take(2).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Mind · personal science',
      title: 'Experiments',
      subtitle:
          'Don\'t guess what works for you — test it. One change, a fixed time, one number to watch. Then keep it or drop it on purpose.',
      children: [
        if (running.isNotEmpty) ...[
          const SectionHeader('Running'),
          for (final e in running) _running(system, e),
        ],
        const SectionHeader('New experiment'),
        if (ideas.isNotEmpty) ...[
          Text('From your patterns:', style: AppText.small()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in ideas)
                ActionChip(
                  label: Text(p.habit),
                  onPressed: () => setState(() {
                    _change.text = '${p.habit} every day';
                    _expect.text = 'Better ${p.outcome}';
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          key: const Key('experiment-change'),
          controller: _change,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'The change, e.g. no screens after 22:00'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _expect,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'What you expect (optional)'),
        ),
        const SizedBox(height: 10),
        Text('Watch', style: AppText.small()),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in PersonalSystemProvider.experimentMeasures.entries)
              ChoiceChip(
                label: Text(m.value),
                selected: _measure == m.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _measure = m.key),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text('For', style: AppText.small()),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (final d in const [7, 14, 21])
              ChoiceChip(
                label: Text('$d days'),
                selected: _days == d,
                showCheckmark: false,
                onSelected: (_) => setState(() => _days = d),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton('Start experiment', icon: Icons.science_outlined,
            onPressed: () {
          if (system.startExperiment(
                  change: _change.text,
                  measure: _measure,
                  days: _days,
                  expect: _expect.text) ==
              null) {
            toast(context, 'Describe the change first.');
            return;
          }
          _change.clear();
          _expect.clear();
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Started. Morning check-ins make the numbers.');
        }),
        if (closed.isNotEmpty) ...[
          const SectionHeader('Done'),
          for (final e in closed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${e.str('status') == 'kept' ? '✓ Kept' : 'Dropped'} · ${e.text}${(e.str('result') ?? '').isEmpty ? '' : ' — ${e.str('result')}'}',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

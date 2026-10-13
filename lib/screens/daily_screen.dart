import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The daily items: retire what has done its job, add what the next stage
/// needs. Holding the day stays at 70% of whatever the list is.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final _title = TextEditingController();
  final _cue = TextEditingController();
  String _lane = 'mind';
  String _when = 'day';

  static const _lanes = {
    'mind': 'Mind',
    'body': 'Body',
    'skill': 'Skill',
    'social': 'Social',
  };

  @override
  void dispose() {
    _title.dispose();
    _cue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final active = system.dailyItems;
    // The built-in list is only offered back to the built-in person.
    final retired = system.isBuiltInPerson
        ? nonNegotiables.where((n) => system.isRetired(n.id)).toList()
        : const <NonNegotiable>[];
    return OnoPage(
      showBack: true,
      eyebrow: '${active.length} items · ${system.holdTarget} hold the day',
      title: 'Your daily items',
      subtitle:
          'A few things done every day beat many done sometimes. Retire an item once it runs on its own; add what your next stage needs.',
      children: [
        for (final g in nonNegotiableGroups)
          if (active.any((n) => n.when == g[0])) ...[
            SectionHeader(g[1]),
            OnoCard(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Column(
                children: [
                  for (final n in active.where((n) => n.when == g[0]))
                    Row(
                      children: [
                        LaneDot(n.lane),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(n.title,
                              style: AppText.body(color: AppColors.white)),
                        ),
                        IconButton(
                          key: Key('daily-off-${n.id}'),
                          tooltip: n.id.startsWith('d_') ? 'Remove' : 'Retire',
                          onPressed: () {
                            final ok = n.id.startsWith('d_')
                                ? system.removeDailyItem(n.id)
                                : system.setItemActive(n.id, false);
                            if (!ok) {
                              toast(context,
                                  'Keep at least ${PersonalSystemProvider.minDailyItems} items.');
                            }
                          },
                          icon: Icon(
                              n.id.startsWith('d_')
                                  ? Icons.delete_outline_rounded
                                  : Icons.remove_circle_outline_rounded,
                              size: 20,
                              color: AppColors.faint),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        if (retired.isNotEmpty) ...[
          const SectionHeader('Retired'),
          for (final n in retired)
            Row(
              children: [
                Expanded(
                  child: Text(n.title,
                      style: AppText.small(color: AppColors.greyLight)),
                ),
                TextButton(
                  onPressed: () {
                    if (!system.setItemActive(n.id, true)) {
                      toast(context,
                          'At most ${PersonalSystemProvider.maxDailyItems} items.');
                    }
                  },
                  child: const Text('Bring back'),
                ),
              ],
            ),
        ],
        const SectionHeader('Add an item'),
        TextField(
          key: const Key('daily-title'),
          controller: _title,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'e.g. 10 minutes of Spanish, stretch before bed'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in _lanes.entries)
              ChoiceChip(
                label: Text(l.value),
                selected: _lane == l.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _lane = l.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final g in nonNegotiableGroups)
              ChoiceChip(
                label: Text(g[1]),
                selected: _when == g[0],
                showCheckmark: false,
                onSelected: (_) => setState(() => _when = g[0]),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cue,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'If–then cue: "When I …, I …"'),
        ),
        const SizedBox(height: 12),
        PrimaryButton('Add item', icon: Icons.add_rounded, onPressed: () {
          final added = system.addDailyItem(_title.text,
              lane: _lane, when: _when, cue: _cue.text);
          if (added == null) {
            toast(
                context,
                _title.text.trim().isEmpty
                    ? 'Name the item first.'
                    : 'At most ${PersonalSystemProvider.maxDailyItems} items — retire one first.');
            return;
          }
          _title.clear();
          _cue.clear();
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Added. It counts from today.');
        }),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => context.push('/plans'),
            child: const Text('Edit if-then plans'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

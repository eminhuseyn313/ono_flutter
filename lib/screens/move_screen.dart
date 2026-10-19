import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Any movement counts. A week of 150 minutes (vigorous counts double) and
/// two strength days is the WHO guideline for adults.
class MoveScreen extends StatefulWidget {
  const MoveScreen({super.key});

  @override
  State<MoveScreen> createState() => _MoveScreenState();
}

class _MoveScreenState extends State<MoveScreen> {
  String _kind = 'walk';
  int _minutes = 30;
  bool _vigorous = false;
  bool _yesterday = false;
  bool _outside = false;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final minutes = system.moveMinutesInWeek(now);
    final strength = system.strengthDaysInWeek(now);
    final week = system.movesInWeek(now);
    return OnoPage(
      showBack: true,
      eyebrow: 'Movement',
      title: 'Move most days',
      subtitle:
          'Walks, runs, games, classes — it all counts. The aim: 150 minutes a week and strength work on two days.',
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile('$minutes', 'of ${PersonalSystemProvider.weeklyMoveTarget} min this week')),
            Expanded(
                child: StatTile('$strength',
                    'of ${PersonalSystemProvider.weeklyStrengthDays} strength days')),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (minutes / PersonalSystemProvider.weeklyMoveTarget).clamp(0, 1).toDouble(),
            backgroundColor: AppColors.cardLight,
            color: AppColors.body,
          ),
        ),
        if (system.outsideMinutesInWeek(now) > 0) ...[
          const SizedBox(height: 8),
          Text('${system.outsideMinutesInWeek(now)} min of it outside. About two hours a week outdoors goes with feeling better.',
              key: const Key('move-outside'), style: AppText.small()),
        ],
        const SectionHeader('Log it'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in PersonalSystemProvider.moveKinds.entries)
              ChoiceChip(
                label: Text(k.value),
                selected: _kind == k.key,
                onSelected: (_) => setState(() => _kind = k.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in const [10, 20, 30, 45, 60, 90])
              ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _vigorous,
          onChanged: (v) => setState(() => _vigorous = v),
          title: Text('Vigorous', style: AppText.body(color: AppColors.white)),
          subtitle: Text('Too out of breath to talk in full sentences', style: AppText.small()),
        ),
        SwitchListTile(
          key: const Key('move-outside-switch'),
          contentPadding: EdgeInsets.zero,
          value: _outside,
          onChanged: (v) => setState(() => _outside = v),
          title: Text('Outside', style: AppText.body(color: AppColors.white)),
          subtitle: Text(
              _outside && _kind == 'walk'
                  ? 'An awe walk: look for one thing bigger or older than your worries.'
                  : 'In a park, by the sea, on a trail',
              style: AppText.small()),
        ),
        Segmented(
          labels: const ['Today', 'Yesterday'],
          index: _yesterday ? 1 : 0,
          onChanged: (i) => setState(() => _yesterday = i == 1),
        ),
        const SizedBox(height: 10),
        PrimaryButton('Log $_minutes min', icon: Icons.add_rounded, onPressed: () {
          system.logMove(_kind, _minutes,
              vigorous: _vigorous,
              outside: _outside,
              day: _yesterday ? dayOnly(now).minusDays(1) : null);
          toast(context, 'Logged.');
        }),
        if (week.isNotEmpty) ...[
          const SectionHeader('This week'),
          for (final l in week)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${PersonalSystemProvider.moveKinds[l.str('kind')] ?? l.str('kind')} · ${l.number('minutes')} min${l.data['vigorous'] == true ? ' · vigorous' : ''}',
                  style: AppText.small(color: AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

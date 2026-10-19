import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Steady sleep: one wake time, a few rules that work (the behavioural
/// parts of CBT-I that are safe on your own), and what the week shows.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final spread = system.wakeSpread(now);
    final week = system.checkinsEnding(now, 7);
    final sleep = system.averageOf(week, 'sleep');
    final titles = {for (final d in system.dailyItems) d.title.toLowerCase()};
    return OnoPage(
      showBack: true,
      eyebrow: 'Body · sleep',
      title: 'Steady sleep',
      subtitle:
          'The same wake time every day does more than chasing more hours. Keep the rules that fit; ONO only counts what you log.',
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile(spread == null ? '—' : '$spread', 'min wake-time spread', unit: '')),
            Expanded(
                child: StatTile(sleep == null ? '—' : sleep.toStringAsFixed(1), 'h sleep, check-ins', unit: '')),
          ],
        ),
        const SizedBox(height: 6),
        Text(
            spread == null
                ? 'The spread shows once Apple Health has three nights this week.'
                : spread <= 60
                    ? 'Your wake times sat within an hour of each other this week.'
                    : 'Your wake times varied by ${spread ~/ 60} h ${spread % 60} min this week. A steadier wake time is the first lever.',
            style: AppText.small()),
        const SectionHeader('Rules that work'),
        for (final r in system.sleepRules)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: AppText.heading()),
                  Text(r.cue, style: AppText.small()),
                  Align(
                    alignment: Alignment.centerRight,
                    child: titles.contains(r.title.toLowerCase())
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('In your daily items', style: AppText.small(color: AppColors.body)),
                          )
                        : TextButton(
                            key: Key('sleep-rule-${r.title}'),
                            onPressed: () {
                              final n = system.addDailyItem(r.title, lane: r.lane, when: r.when, cue: r.cue);
                              if (n == null) {
                                toast(context, 'Your daily list is full — retire one first.');
                              } else if (r.minimum.isNotEmpty) {
                                system.setMinimum(n.id, r.minimum);
                              }
                            },
                            child: const Text('Make it a daily item'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader('When your mind won\'t stop'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.local_parking_rounded,
            color: AppColors.mind,
            title: 'Park the worry',
            subtitle: 'Write it down with one possible step — then it waits for worry time',
            onTap: () => context.push('/worry'),
          ),
        ),
        const SizedBox(height: 14),
        Text(
            'If sleeping badly lasts three months or more, or you snore loudly or feel sleepy in the day, talk to a doctor — insomnia and sleep apnoea are treatable. ONO doesn\'t give medical advice or limit your time in bed.',
            style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

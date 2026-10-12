import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The end of a program: what it added up to, a look back, then the next
/// program from today — everything logged stays.
class NextProgramScreen extends StatefulWidget {
  const NextProgramScreen({super.key});

  @override
  State<NextProgramScreen> createState() => _NextProgramScreenState();
}

class _NextProgramScreenState extends State<NextProgramScreen> {
  final _changed = TextEditingController();
  final _carry = TextEditingController();
  int? _length;

  @override
  void dispose() {
    _changed.dispose();
    _carry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final sum = system.programSummary();
    final length = _length ?? system.programDays;
    final complete = system.programComplete;
    final letters = system.lettersToOpen.length;
    return OnoPage(
      showBack: true,
      eyebrow: 'Program ${system.cycle} · ${system.programLengthLabel}',
      title: complete ? 'You finished it' : 'Close this program early?',
      subtitle: complete
          ? 'Before the next one: look at what this one added up to, and what you\'ll take with you.'
          : 'You are on day ${system.programDay} of ${system.programDays}. You can close it now and start the next from today.',
      bottomBar: PrimaryButton(
        'Start the next ${PersonalSystemProvider.programLengths[length]}',
        icon: Icons.arrow_forward_rounded,
        onPressed: () {
          system.startNextProgram(
              days: length, changed: _changed.text, carry: _carry.text);
          toast(context, 'Day 1. Everything you built comes with you.');
          context.go('/home');
        },
      ),
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile('${sum.held}/${sum.counted}', 'Days held')),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile('${sum.goalsAchieved}', 'Goals reached')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: StatTile('${sum.wins}', 'Wins')),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile('${sum.reps}', 'Practice reps · ${sum.lessons} lessons')),
          ],
        ),
        if (letters > 0) ...[
          const SizedBox(height: 12),
          OnoCard(
            highlight: true,
            padding: EdgeInsets.zero,
            child: LinkRow(
              icon: Icons.mail_outline_rounded,
              color: AppColors.accent,
              title: letters == 1
                  ? 'A letter is waiting'
                  : '$letters letters are waiting',
              subtitle: 'Read what you wrote to yourself first',
              onTap: () => context.push('/letters'),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: _changed,
            minLines: 2,
            maxLines: 6,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                labelText: 'What changed in you?',
                hintText: 'Who you were on day 1, who you are now'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: _carry,
            minLines: 2,
            maxLines: 6,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                labelText: 'What comes with you',
                hintText: 'The habits, people and lessons you keep'),
          ),
        ),
        const SectionHeader('The next program'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in PersonalSystemProvider.programLengths.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: length == e.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _length = e.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            'Your goals, daily plan, people and everything you logged stay. Months, quarters and phases start again from day 1.',
            style: AppText.small()),
        if (system.pastPrograms.isNotEmpty) ...[
          const SectionHeader('Earlier programs'),
          for (final p in system.pastPrograms)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Program ${p.number('number')} · ${p.str('start')} → ${p.str('end')}',
                        style: AppText.heading()),
                    const SizedBox(height: 2),
                    Text(
                        '${p.number('held')} of ${p.number('counted')} days held · ${p.number('goals_achieved')} goals reached',
                        style: AppText.small()),
                    if (p.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.text, style: AppText.body(color: AppColors.white)),
                    ],
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

/// Letters to the man he is becoming, sealed until a date he picks.
class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  final _text = TextEditingController();
  int _choice = 1;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<(String, DateTime)> _options(PersonalSystemProvider system) {
    final today = dayOnly(timeNow());
    final next = system.nextPhaseStart;
    return [
      ('In 30 days', today.plusDays(30)),
      ('In 90 days', today.plusDays(90)),
      if (next != null && next.isAfter(today))
        ('Next phase · ${shortDate(next)}', next),
      ('Day ${system.programDays} · ${shortDate(system.programEnd)} ${system.programEnd.year}',
          system.programEnd),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final options = _options(system);
    final choice = _choice.clamp(0, options.length - 1);
    final letters = system.letters;
    return OnoPage(
      showBack: true,
      eyebrow: 'Future you',
      title: 'Letters',
      subtitle:
          'Write to the ${activeProfile.firstName} who finishes this. What should they remember about why you started — and what do you promise them?',
      children: [
        const SectionHeader('Write'),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 12,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(
              hintText: 'Dear ${activeProfile.firstName}, by the time you read this…'),
        ),
        const SizedBox(height: 12),
        Text('Opens', style: AppText.small()),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < options.length; i++)
              ChoiceChip(
                label: Text(options[i].$1),
                selected: choice == i,
                onSelected: (_) => setState(() => _choice = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        PrimaryButton('Seal the letter', icon: Icons.lock_rounded,
            onPressed: () {
          if (_text.text.trim().isEmpty) {
            toast(context, 'Write something first.');
            return;
          }
          system.writeLetter(_text.text, options[choice].$2,
              atEnd: choice == options.length - 1);
          _text.clear();
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Sealed until ${shortDate(options[choice].$2)}.');
        }),
        if (letters.isNotEmpty) const SectionHeader('Your letters'),
        for (final l in letters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Letter(entry: l),
          ),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  final LogEntry entry;
  const _Letter({required this.entry});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final open = system.letterIsOpen(entry);
    final opens = system.letterOpensOn(entry);
    final written =
        'Written ${shortDate(entry.date)} ${entry.date.year} · month ${entry.number('month') ?? '–'}';
    if (!open) {
      return OnoCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: AppColors.faint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sealed until ${shortDate(opens)} ${opens.year}',
                      style: AppText.heading()),
                  Text(written, style: AppText.small()),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final unread = !system.isDone('letter:${entry.id}');
    return OnoCard(
      accent: unread ? AppColors.accent : null,
      padding: const EdgeInsets.all(14),
      onTap: unread ? () => system.markLetterRead(entry.id) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unread ? 'Opened today — tap when read' : written,
              style: AppText.eyebrow(
                  color: unread ? AppColors.accent : AppColors.grey)),
          const SizedBox(height: 8),
          Text(entry.text, style: AppText.body(color: AppColors.white)),
          if (unread) ...[
            const SizedBox(height: 8),
            Text(written, style: AppText.small()),
          ],
        ],
      ),
    );
  }
}

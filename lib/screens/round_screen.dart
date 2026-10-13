import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Once a quarter: one question to three people who see you differently,
/// then the theme that repeats. One opinion is a data point; three that
/// agree are a pattern.
class RoundScreen extends StatefulWidget {
  const RoundScreen({super.key});

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  final _question = TextEditingController(text: PersonalSystemProvider.defaultRoundQuestion);
  final _themes = TextEditingController();
  final Set<String> _people = {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final r = system.roundFor(system.programQuarter);
    if (r != null) {
      _question.text = r.text;
      _themes.text = r.str('themes') ?? '';
      _people.addAll([for (final p in (r.data['people'] as List? ?? const [])) '$p']);
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _themes.dispose();
    super.dispose();
  }

  void _answer(PersonalSystemProvider system, String roundId, String from) {
    final c = TextEditingController();
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
            Text('What $from said', style: AppText.title()),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              minLines: 3,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'In their words — no defending'),
            ),
            const SizedBox(height: 12),
            PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              system.addRoundAnswer(roundId, from, c.text);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final round = system.roundFor(system.programQuarter);
    final names = <String>{
      for (final p in activeProfile.keyPeople) p.name,
      for (final p in system.people) p.text,
      ..._people,
    }.where((n) => n.isNotEmpty).toList();
    final answers = round == null ? const <({String from, String said})>[] : system.roundAnswers(round);
    final past = [
      for (final r in system.logsOf('feedback_round'))
        if (!system.atQuarter(r, system.programQuarter)) r
    ];
    return OnoPage(
      showBack: true,
      eyebrow: 'Quarter ${system.programQuarter} · feedback round',
      title: 'Three views',
      subtitle:
          'Ask the same question to three people who see you in different settings. What repeats is worth acting on.',
      children: [
        const SectionHeader('The question'),
        TextField(
          controller: _question,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(color: AppColors.white),
        ),
        const SectionHeader('Ask up to three people'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in names)
              FilterChip(
                label: Text(n),
                selected: _people.contains(n),
                showCheckmark: false,
                onSelected: (on) => setState(() {
                  if (on && _people.length < 3) _people.add(n);
                  if (!on) _people.remove(n);
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(round == null ? 'Start the round · copy the ask' : 'Update · copy the ask',
            icon: Icons.copy_rounded, onPressed: () {
          if (_people.isEmpty) {
            toast(context, 'Pick at least one person.');
            return;
          }
          system.startRound(_people.toList(), question: _question.text);
          Clipboard.setData(ClipboardData(
              text: 'I\'m working on getting better and I value your view. ${_question.text.trim()} Honest is more useful than nice.'));
          toast(context, 'Copied. Send it to each of them.');
        }),
        if (round != null) ...[
          const SectionHeader('Answers'),
          for (final p in [for (final x in (round.data['people'] as List? ?? const [])) '$x'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p, style: AppText.heading()),
                    if (answers.any((a) => a.from == p))
                      Text('"${answers.firstWhere((a) => a.from == p).said}"',
                          style: AppText.body(color: AppColors.white))
                    else
                      TextButton(
                        onPressed: () => _answer(system, round.id, p),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Save their answer'),
                      ),
                  ],
                ),
              ),
            ),
          const SectionHeader('What repeats?'),
          TextField(
            controller: _themes,
            minLines: 2,
            maxLines: 4,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                hintText: 'The theme two or three of them share — and what you\'ll do about it'),
          ),
          const SizedBox(height: 10),
          GhostButton('Save the theme', icon: Icons.check_rounded, onPressed: () {
            system.setRoundThemes(round.id, _themes.text);
            FocusManager.instance.primaryFocus?.unfocus();
            toast(context, 'Saved. It goes into your career case.');
          }),
        ],
        if (past.isNotEmpty) ...[
          const SectionHeader('Earlier rounds'),
          for (final r in past)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  'Quarter ${r.number('quarter')} · ${(r.str('themes') ?? '').isEmpty ? '${system.roundAnswers(r).length} answers' : r.str('themes')}',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

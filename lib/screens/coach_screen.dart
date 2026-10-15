import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Self-coaching with GROW: goal, reality, options, will. For a problem
/// at work or at home that keeps circling.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _goal = TextEditingController();
  final _reality = TextEditingController();
  final _options = List.generate(3, (_) => TextEditingController());
  final _will = TextEditingController();
  int _days = 7;
  int _commitment = 7;

  @override
  void dispose() {
    for (final c in [_goal, _reality, _will, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _step(String n, String title, String help, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader('$n · $title'),
          Text(help, style: AppText.small()),
          const SizedBox(height: 8),
          field,
        ],
      );

  TextField _field(TextEditingController c, String hint, {int lines = 2}) =>
      TextField(
        controller: c,
        minLines: lines,
        maxLines: lines + 3,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final due = system.commitmentsDue(system.logicalToday);
    final past = system.coachingSessions;
    return OnoPage(
      showBack: true,
      eyebrow: 'Coach yourself · 10 min',
      title: 'Think it through',
      subtitle:
          'A problem that keeps circling — at work or at home. Four questions, then one commitment you\'ll check back on.',
      children: [
        for (final c in due) _Due(entry: c),
        _step('G', 'Goal', 'What do you want — specifically? What would good look like?',
            _field(_goal, 'e.g. Be trusted to own a whole area, not pieces of it')),
        _step('R', 'Reality', 'What\'s happening now? What have you tried? What\'s in your control?',
            _field(_reality, 'Facts, not the story', lines: 3)),
        _step('O', 'Options', 'At least three. Include one you\'d do if you weren\'t afraid.',
            Column(children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _field(_options[i], 'Option ${i + 1}', lines: 1),
                ),
            ])),
        _step('W', 'Will', 'What will you do? One action.',
            _field(_will, 'I will…', lines: 1)),
        const SizedBox(height: 10),
        Text('Check back in', style: AppText.small()),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          for (final d in const [1, 3, 7, 14])
            ChoiceChip(
              label: Text(d == 1 ? 'Tomorrow' : '$d days'),
              selected: _days == d,
              showCheckmark: false,
              onSelected: (_) => setState(() => _days = d),
            ),
        ]),
        const SizedBox(height: 12),
        Text('How committed are you? $_commitment/10${_commitment < 7 ? ' — what would make it an 8?' : ''}',
            style: AppText.small()),
        Slider(
          value: _commitment.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: AppColors.accent,
          onChanged: (v) => setState(() => _commitment = v.round()),
        ),
        PrimaryButton('Commit', icon: Icons.handshake_outlined, onPressed: () {
          if (_goal.text.trim().isEmpty || _will.text.trim().isEmpty) {
            toast(context, 'Write the goal and what you will do.');
            return;
          }
          system.logCoaching(
            goal: _goal.text,
            reality: _reality.text,
            options: [for (final o in _options) o.text],
            will: _will.text,
            by: system.logicalToday.plusDays(_days),
            commitment: _commitment,
          );
          HapticFeedback.mediumImpact();
          for (final c in [_goal, _reality, _will, ..._options]) {
            c.clear();
          }
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Committed. Today will ask you about it.');
        }),
        if (past.isNotEmpty) ...[
          const SectionHeader('Earlier sessions'),
          for (final c in past.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.text, style: AppText.heading()),
                    Text(
                        '${c.str('will')} · ${system.commitmentKept(c.id) ? 'kept' : system.isDone('coach:${c.id}:dropped') ? 'dropped' : 'by ${c.str('by')}'}',
                        style: AppText.small()),
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

class _Due extends StatelessWidget {
  final LogEntry entry;
  const _Due({required this.entry});

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        accent: AppColors.accent,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOU COMMITTED', style: AppText.eyebrow(color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(entry.str('will') ?? '', style: AppText.heading()),
            Text('For: ${entry.text}', style: AppText.small()),
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      system.setCommitmentKept(entry.id, true);
                      _undo(context, 'Kept.',
                          () => system.setCommitmentKept(entry.id, false));
                    },
                    child: const Text('Kept it')),
                TextButton(
                    onPressed: () {
                      system.dropCommitment(entry.id);
                      _undo(context, 'Dropped on purpose.',
                          () => system.setDone('coach:${entry.id}:dropped', false));
                    },
                    child: const Text('Drop it on purpose')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _undo(BuildContext context, String text, VoidCallback undo) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: SnackBarAction(label: 'Undo', onPressed: undo),
      ));

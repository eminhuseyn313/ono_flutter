import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// After a slip: kindness, facts, the smallest next step. Shame makes
/// people quit; self-compassion makes them try again.
class SetbackScreen extends StatefulWidget {
  const SetbackScreen({super.key});

  @override
  State<SetbackScreen> createState() => _SetbackScreenState();
}

class _SetbackScreenState extends State<SetbackScreen> {
  final _kind = TextEditingController();
  final _happened = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _kind.dispose();
    _happened.dispose();
    _next.dispose();
    super.dispose();
  }

  Widget _step(String n, String title, String help, TextEditingController c,
          String hint, {int lines = 2}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader('$n · $title'),
          Text(help, style: AppText.small()),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            minLines: lines,
            maxLines: lines + 3,
            style: AppText.body(color: AppColors.white),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return UnsavedGuard(
        fields: [_kind, _happened, _next],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Setback · 3 minutes',
      title: 'It slipped. Now what?',
      subtitle:
          'Everyone who gets good at anything misses days. What matters is the next step — and you take it faster when you\'re kind to yourself first.',
      bottomBar: PrimaryButton('Back on track', icon: Icons.replay_rounded,
          onPressed: () {
        if ([_kind, _happened, _next].every((c) => c.text.trim().isEmpty)) {
          toast(context, 'Write a line first — even just what happened.');
          return;
        }
        final placed = system.logSetback(
            kind: _kind.text, happened: _happened.text, nextStep: _next.text);
        HapticFeedback.mediumImpact();
        toast(
            context,
            _next.text.trim().isEmpty
                ? 'Saved. When you know the next step, it can be small.'
                : placed
                    ? 'It\'s on today\'s priorities. One step, then the next.'
                    : 'Saved. Today\'s three are full — the step is in your log.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        if (system.bestSelfPortrait case final portrait?) ...[
          const SizedBox(height: 14),
          OnoCard(
            accent: AppColors.accent,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOU, AT YOUR BEST', style: AppText.eyebrow(color: AppColors.accent)),
                const SizedBox(height: 6),
                Text(portrait, style: AppText.body(color: AppColors.white)),
                const SizedBox(height: 4),
                Text('From people who have seen it. One slip doesn\'t change it.',
                    style: AppText.small()),
              ],
            ),
          ),
        ],
        _step('1', 'Talk to yourself like a friend',
            'What would you say to a friend who had this day or week?', _kind,
            'It happens. You were carrying a lot. It doesn\'t erase what you\'ve built…',
            lines: 3),
        _step('2', 'What actually happened', 'Facts only — no story about who you are.',
            _happened, 'e.g. Three late evenings, skipped my walks, slept 6 h'),
        _step('3', 'The smallest next step', 'So small you can do it today. It goes on today\'s priorities.',
            _next, 'e.g. 20-minute walk at lunch', lines: 1),
        const SizedBox(height: 16),
      ],
    ));
  }
}

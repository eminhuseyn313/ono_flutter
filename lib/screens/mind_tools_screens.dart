import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../widgets/support_sheet.dart';

/// Step back: talk about yourself by name. Self-distancing lowers
/// distress and improves judgement under stress (Kross et al. 2014).
class StepBackScreen extends StatefulWidget {
  const StepBackScreen({super.key});

  @override
  State<StepBackScreen> createState() => _StepBackScreenState();
}

class _StepBackScreenState extends State<StepBackScreen> {
  final _what = TextEditingController();
  final _feeling = TextEditingController();
  final _advice = TextEditingController();
  final _step = TextEditingController();
  int? _year;

  @override
  void dispose() {
    for (final c in [_what, _feeling, _advice, _step]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          minLines: 2,
          maxLines: 5,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    final name = activeProfile.firstName.isEmpty ? 'you' : activeProfile.firstName;
    return UnsavedGuard(
        fields: [_what, _feeling, _advice, _step],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Step back · 3 minutes',
      title: 'Talk to $name, not to "I"',
      subtitle:
          'Write about yourself by name, like a wise friend would. The distance calms the moment and clears the next step.',
      bottomBar: PrimaryButton('Done', icon: Icons.check_rounded, onPressed: () {
        if (_what.text.trim().isEmpty) {
          toast(context, 'Start with what\'s happening.');
          return;
        }
        system.logStepBack(
            what: _what.text, feeling: _feeling.text, advice: _advice.text, mattersInAYear: _year);
        final placed = system.addToTodayPriorities(_step.text);
        toast(
            context,
            _step.text.trim().isEmpty
                ? 'Saved. You can come back to it.'
                : placed
                    ? 'Saved — the step is on today\'s priorities.'
                    : 'Saved. Today\'s three are full; the step is in your log.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SupportLink(),
        _field(_what, 'What is happening to $name?', '$name is facing…'),
        _field(_feeling, 'What is $name feeling — and why does it make sense?', '$name feels … because …'),
        _field(_advice, 'What would you tell $name, as a friend?', '$name, you can…'),
        const SectionHeader('In a year, how much will this matter?'),
        Segmented(
          labels: const ['Not at all', 'A little', 'A lot'],
          index: _year ?? -1,
          onChanged: (i) => setState(() => _year = i),
        ),
        _field(_step, 'One next step, if there is one', 'Optional — it goes on today\'s priorities'),
        const SizedBox(height: 16),
      ],
    ));
  }
}

/// Decide with your values: options against what matters, the 10/10/10
/// view, a premortem — then into the decision journal for review.
class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  final Map<int, Map<String, int>> _scores = {};
  final _ten = TextEditingController();
  final _premortem = TextEditingController();
  int? _chosen;

  @override
  void dispose() {
    for (final c in [_question, ..._options, _ten, _premortem]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final values = system.values.map((v) => v.name).toList();
    final criteria = values.isEmpty ? const ['Health', 'People I love', 'Growth', 'Freedom'] : values;
    final named = [
      for (var i = 0; i < _options.length; i++)
        if (_options[i].text.trim().isNotEmpty) i
    ];
    int total(int i) => (_scores[i]?.values.fold<int>(0, (a, b) => a + b)) ?? 0;
    return UnsavedGuard(
        fields: [_question, ..._options, _ten, _premortem],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Decide with your values',
      title: 'A decision that fits you',
      subtitle:
          'Name the options, weigh them against what matters to you, look ten years out, imagine it failing. Then decide — and review it in 90 days.',
      bottomBar: PrimaryButton('Decide and save', icon: Icons.gavel_rounded, onPressed: () {
        if (_question.text.trim().isEmpty ||
            _chosen == null ||
            _options[_chosen!].text.trim().isEmpty) {
          toast(context, 'Write the question and choose an option.');
          return;
        }
        system.addValuesDecision(
          question: _question.text,
          chosen: _options[_chosen!].text.trim(),
          scores: {
            for (final i in named) _options[i].text.trim(): {..._scores[i] ?? const {}}
          },
          tenTenTen: _ten.text,
          premortem: _premortem.text,
        );
        toast(context, 'Saved to your decisions. Review in 90 days.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _question,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(labelText: 'The decision', hintText: 'e.g. Take the new role?'),
        ),
        const SectionHeader('Options'),
        for (var i = 0; i < _options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _options[i],
              onChanged: (_) => setState(() {}),
              style: AppText.body(color: AppColors.white),
              decoration: InputDecoration(hintText: 'Option ${i + 1}'),
            ),
          ),
        if (_options.length < 4)
          TextButton.icon(
            onPressed: () => setState(() => _options.add(TextEditingController())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Another option'),
          ),
        if (named.isNotEmpty) ...[
          SectionHeader(values.isEmpty ? 'Against what matters' : 'Against your values'),
          if (values.isEmpty)
            Text('Set your values under Me to weigh against your own.', style: AppText.small()),
          for (final i in named)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OnoCard(
                highlight: _chosen == i,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_options[i].text, style: AppText.heading())),
                        Text('${total(i) > 0 ? '+' : ''}${total(i)}', style: AppText.number(size: 18)),
                      ],
                    ),
                    for (final v in criteria) ...[
                      const SizedBox(height: 6),
                      Text(v, style: AppText.small()),
                      const SizedBox(height: 4),
                      Segmented(
                        labels: const ['Against', 'Neutral', 'For'],
                        index: (_scores[i]?[v] ?? 0) + 1,
                        onChanged: (s) => setState(() => (_scores[i] ??= {})[v] = s - 1),
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(() => _chosen = i),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(_chosen == i ? 'Chosen' : 'Choose this'),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('10 minutes, 10 months, 10 years'),
        TextField(
          controller: _ten,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'How will you feel about it at each?'),
        ),
        const SectionHeader('Premortem'),
        TextField(
          controller: _premortem,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'A year from now it went badly. What most likely happened?'),
        ),
        const SizedBox(height: 16),
      ],
    ));
  }
}

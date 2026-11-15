import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/tool_index.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../time.dart';
import '../widgets/ono_ui.dart';

/// Ask ONO: questions answered from the person's own plan and days, on the
/// device. A question it can't answer gets the tools that fit its words.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _text = TextEditingController();
  final _asked = <(String, AskAnswer, List<ToolEntry>)>[];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _ask(PersonalSystemProvider system, String question, {String? intent}) {
    final q = question.trim();
    if (q.isEmpty) return;
    final answer = system.ask(intent ?? q, timeNow());
    final known = intent != null || PersonalSystemProvider.askIntent(q) != null;
    final tools = known
        ? const <ToolEntry>[]
        : [
            for (final t in toolIndex)
              if ((!t.builtInOnly || system.isBuiltInPerson) && t.matches(q)) t
          ].take(3).toList();
    setState(() {
      _asked.insert(0, (q, answer, tools));
      _text.clear();
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Ask ONO',
      title: 'What do you want to know?',
      subtitle: 'Answers from your own plan and days. Nothing leaves your phone.',
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (id, label) in PersonalSystemProvider.askQuestions)
              ActionChip(
                key: Key('ask-$id'),
                label: Text(label),
                onPressed: () => _ask(system, label, intent: id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('ask-field'),
          controller: _text,
          textInputAction: TextInputAction.send,
          onSubmitted: (v) => _ask(system, v),
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(
            hintText: 'Or ask in your own words',
            suffixIcon: IconButton(
              key: const Key('ask-send'),
              tooltip: 'Ask',
              icon: const Icon(Icons.arrow_upward_rounded),
              onPressed: () => _ask(system, _text.text),
            ),
          ),
        ),
        for (final (q, a, tools) in _asked) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentDeep,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(q, style: AppText.body(color: AppColors.white)),
            ),
          ),
          const SizedBox(height: 8),
          OnoCard(
            key: Key('ask-answer-${_asked.length}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: AppText.heading()),
                for (final l in a.lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l, style: AppText.body(color: AppColors.greyLight)),
                  ),
                if (a.actions.isNotEmpty || tools.isNotEmpty) const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final (label, route) in [
                      for (final t in tools) (t.title, t.route),
                      if (tools.isEmpty) ...a.actions,
                    ])
                      TextButton(
                        onPressed: () => context.push(route),
                        child: Text(label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

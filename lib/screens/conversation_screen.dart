import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Hard conversations: prepare the one you've been avoiding, then debrief.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final planned = system.plannedConversations;
    final done = [
      for (final c in system.conversations)
        if (c.str('status') == 'done') c
    ];
    return OnoPage(
      showBack: true,
      eyebrow: 'Hard conversations',
      title: 'Say the hard thing well',
      subtitle:
          'Feedback, a conflict, a boundary — at work or at home. Ten minutes of preparation changes how it lands.',
      children: [
        const SizedBox(height: 14),
        PrimaryButton('Prepare a conversation', icon: Icons.add_rounded, onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ConversationEditScreen()));
        }),
        if (planned.isNotEmpty) ...[
          const SectionHeader('Ahead of you'),
          for (final c in planned) _row(context, c),
        ],
        if (done.isNotEmpty) ...[
          const SectionHeader('Had'),
          for (final c in done.take(10)) _row(context, c),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _row(BuildContext context, LogEntry c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OnoCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ConversationEditScreen(id: c.id))),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('With ${c.str('with')}', style: AppText.heading()),
              Text(c.text, style: AppText.small()),
              if (c.str('status') == 'done')
                Text(
                    '${PersonalSystemProvider.conversationOutcomes[c.str('outcome')] ?? ''}${(c.str('learned') ?? '').isEmpty ? '' : ' · ${c.str('learned')}'}',
                    style: AppText.small(color: AppColors.body))
              else if ((c.str('by') ?? '').isNotEmpty)
                Text('By ${c.str('by')}', style: AppText.small(color: AppColors.accent)),
            ],
          ),
        ),
      );
}

class ConversationEditScreen extends StatefulWidget {
  final String? id;
  const ConversationEditScreen({super.key, this.id});

  @override
  State<ConversationEditScreen> createState() => _ConversationEditScreenState();
}

class _ConversationEditScreenState extends State<ConversationEditScreen> {
  static const _fields = [
    ('with', 'With whom', 'A name'),
    ('about', 'About what', 'In a few words'),
    ('want_me', 'What I really want — for me', 'Not "to win": what result do I want?'),
    ('want_them', '… for them', 'What do I want for them?'),
    ('want_us', '… for us', 'What do I want for the relationship?'),
    ('facts', 'The facts', 'What a camera would have recorded — no adjectives'),
    ('my_story', 'The story I\'m telling myself', 'What I think it means'),
    ('their_story', 'Their story, as they might tell it', 'Why might a reasonable person do this?'),
    ('opening', 'My first sentence', 'Describe the gap and invite their view'),
    ('ask', 'What I\'ll ask for', 'One concrete request'),
  ];

  final Map<String, TextEditingController> _c = {
    for (final f in _fields) f.$1: TextEditingController(),
  };
  final _learned = TextEditingController();
  int? _byDays;
  String _outcome = 'better';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final c = widget.id == null
        ? null
        : context.read<PersonalSystemProvider>().conversationById(widget.id!);
    if (c != null) {
      _c['about']!.text = c.text;
      for (final f in _fields) {
        if (f.$1 != 'about') _c[f.$1]!.text = c.str(f.$1) ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in [..._c.values, _learned]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final existing = widget.id == null ? null : system.conversationById(widget.id!);
    final done = existing?.str('status') == 'done';
    return OnoPage(
      showBack: true,
      eyebrow: done ? 'Hard conversation · had' : 'Hard conversation · prepare',
      title: existing == null ? 'Prepare it' : 'With ${existing.str('with')}',
      subtitle: 'Start with what you really want. Facts before stories. Assume their story makes sense to them.',
      bottomBar: done
          ? null
          : PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              final saved = system.saveConversation(
                id: widget.id,
                withWhom: _c['with']!.text,
                about: _c['about']!.text,
                wantMe: _c['want_me']!.text,
                wantThem: _c['want_them']!.text,
                wantUs: _c['want_us']!.text,
                facts: _c['facts']!.text,
                myStory: _c['my_story']!.text,
                theirStory: _c['their_story']!.text,
                opening: _c['opening']!.text,
                ask: _c['ask']!.text,
                by: _byDays == null
                    ? (existing == null ? null : DateTime.tryParse(existing.str('by') ?? ''))
                    : dayOnly(DateTime.now()).add(Duration(days: _byDays!)),
              );
              if (saved == null) {
                toast(context, 'Name who it\'s with.');
                return;
              }
              FocusManager.instance.primaryFocus?.unfocus();
              toast(context, 'Ready. Read your first sentence once more before you start.');
              Navigator.of(context).maybePop();
            }),
      children: [
        for (final f in _fields)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _c[f.$1],
              readOnly: done,
              minLines: f.$1 == 'with' || f.$1 == 'about' ? 1 : 2,
              maxLines: 5,
              style: AppText.body(color: AppColors.white),
              decoration: InputDecoration(labelText: f.$2, hintText: f.$3),
            ),
          ),
        if (!done) ...[
          const SectionHeader('When'),
          Wrap(
            spacing: 6,
            children: [
              for (final d in const [(0, 'Today'), (1, 'Tomorrow'), (7, 'This week')])
                ChoiceChip(
                  label: Text(d.$2),
                  selected: _byDays == d.$1,
                  onSelected: (_) => setState(() => _byDays = d.$1),
                ),
            ],
          ),
          if ((_c['opening']!.text).trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            GhostButton('Copy my first sentence', icon: Icons.copy_rounded, onPressed: () {
              Clipboard.setData(ClipboardData(text: _c['opening']!.text.trim()));
              toast(context, 'Copied.');
            }),
          ],
        ],
        if (existing != null && !done) ...[
          const SectionHeader('After you had it'),
          for (final o in PersonalSystemProvider.conversationOutcomes.entries)
            CheckRow(
              checked: _outcome == o.key,
              title: o.value,
              onChanged: (_) => setState(() => _outcome = o.key),
            ),
          TextField(
            controller: _learned,
            minLines: 2,
            maxLines: 4,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'What did you learn — about them, or yourself?'),
          ),
          const SizedBox(height: 10),
          GhostButton('It happened — save the debrief', icon: Icons.done_all_rounded, onPressed: () {
            system.debriefConversation(existing.id, outcome: _outcome, learned: _learned.text);
            toast(context, 'Debriefed. That took courage.');
            Navigator.of(context).maybePop();
          }),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// What you learn from — books, courses, talks — and, for each, one
/// principle in your own words and one experiment in real life.
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final _title = TextEditingController();
  final _by = TextEditingController();
  String _kind = 'Book';

  @override
  void dispose() {
    _title.dispose();
    _by.dispose();
    super.dispose();
  }

  void _apply(PersonalSystemProvider system, LogEntry l) {
    final principle = TextEditingController();
    final experiment = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apply it', style: AppText.title()),
              Text(l.text, style: AppText.small()),
              const SizedBox(height: 12),
              Text('The one principle, in your words', style: AppText.small(color: AppColors.white)),
              const SizedBox(height: 4),
              TextField(
                controller: principle,
                minLines: 2,
                maxLines: 4,
                style: AppText.body(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'If you remember one thing…'),
              ),
              const SizedBox(height: 10),
              Text('One experiment this week', style: AppText.small(color: AppColors.white)),
              const SizedBox(height: 4),
              TextField(
                controller: experiment,
                minLines: 1,
                maxLines: 3,
                style: AppText.body(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'This week I will try…'),
              ),
              const SizedBox(height: 14),
              PrimaryButton('Done — apply it', icon: Icons.check_rounded, onPressed: () {
                if (principle.text.trim().isEmpty || experiment.text.trim().isEmpty) {
                  toast(ctx, 'Write the principle and the experiment.');
                  return;
                }
                system.applyLearning(l.id,
                    principle: principle.text, experiment: experiment.text);
                Navigator.of(ctx).pop();
                HapticFeedback.mediumImpact();
                toast(context, 'Finished and applied. ONO asks how it went in a week.');
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _result(PersonalSystemProvider system, LogEntry l) {
    final c = TextEditingController(text: l.str('result') ?? '');
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
            Text('How did it go?', style: AppText.title()),
            Text(l.str('experiment') ?? '', style: AppText.small()),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              minLines: 2,
              maxLines: 5,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  hintText: 'What happened — keep it, change it, or drop it?'),
            ),
            const SizedBox(height: 12),
            PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              system.recordExperimentResult(l.id, c.text);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    );
  }

  /// Write what you just read without looking — retrieval is the learning,
  /// and the note becomes a review card.
  void _fromMemory(PersonalSystemProvider system, LogEntry l) {
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
            Text('From memory', style: AppText.title()),
            Text('${l.text} · close it first. Where you blank is what to reread.',
                style: AppText.small()),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              minLines: 3,
              maxLines: 8,
              autofocus: true,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  hintText: 'Explain it in plain words, as if to a friend'),
            ),
            const SizedBox(height: 12),
            PrimaryButton('Save the note', icon: Icons.check_rounded, onPressed: () {
              if (c.text.trim().length < 20) {
                toast(context, 'Write a few sentences first.');
                return;
              }
              system.logProtocolUse('feynman',
                  text: c.text.trim(), data: {'book': l.text, 'chapter': ''});
              Navigator.of(ctx).pop();
              toast(context, 'Saved. It comes back as a review card tomorrow.');
            }),
          ],
        ),
      ),
    );
  }

  Widget _item(PersonalSystemProvider system, LogEntry l) {
    final status = l.str('status') ?? 'queue';
    final by = l.str('by') ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OnoCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.text, style: AppText.heading())),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    if (status == 'done' || (l.str('notes') ?? '').isNotEmpty) {
                      final sure = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text('Remove "${l.text}"?'),
                          content: const Text(
                              'What you took from it and its review card go too.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(d, false),
                                child: const Text('Keep')),
                            TextButton(
                                onPressed: () => Navigator.pop(d, true),
                                child: const Text('Remove')),
                          ],
                        ),
                      );
                      if (sure != true) return;
                    }
                    system.removeLearning(l.id);
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.faint),
                ),
              ],
            ),
            Text('${l.str('kind') ?? 'Book'}${by.isEmpty ? '' : ' · $by'}',
                style: AppText.small()),
            if (status == 'done') ...[
              const SizedBox(height: 6),
              Text('“${l.str('principle')}”', style: AppText.body(color: AppColors.white)),
              Text('Experiment: ${l.str('experiment')}', style: AppText.small()),
              if ((l.str('result') ?? '').isNotEmpty)
                Text('Result: ${l.str('result')}', style: AppText.small(color: AppColors.body)),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: switch (status) {
                'queue' => TextButton(
                    onPressed: () => system.startLearning(l.id),
                    child: const Text('Start')),
                'active' => Wrap(
                    children: [
                      TextButton(
                          key: Key('from-memory-${l.id}'),
                          onPressed: () => _fromMemory(system, l),
                          child: const Text('What I just read, from memory')),
                      TextButton(
                          onPressed: () => _apply(system, l),
                          child: const Text('Finished — apply it')),
                    ],
                  ),
                _ => TextButton(
                    onPressed: () => _result(system, l),
                    child: Text((l.str('result') ?? '').isEmpty
                        ? 'How did the experiment go?'
                        : 'Edit result')),
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final active = system.learningWith('active');
    final queue = system.learningWith('queue');
    final done = system.learningWith('done');
    final planBook = currentBook(system.programMonth);
    final hasPlanBook = system.learning.any((l) => l.text == planBook.title);
    return OnoPage(
      showBack: true,
      eyebrow: 'Skill · learn and apply',
      title: 'Learning',
      subtitle:
          'Reading isn\'t learning until it changes what you do. Finish each one with a principle in your words and one real experiment.',
      children: [
        if (system.isBuiltInPerson && !hasPlanBook) ...[
          const SizedBox(height: 14),
          OnoCard(
            padding: EdgeInsets.zero,
            child: LinkRow(
              icon: Icons.menu_book_rounded,
              color: AppColors.skill,
              title: 'Add this month\'s book',
              subtitle: '${planBook.title} · ${planBook.author}',
              onTap: () => system.addLearning(planBook.title,
                  kind: 'Book', by: planBook.author),
            ),
          ),
        ],
        if (active.isNotEmpty) ...[
          const SectionHeader('Now'),
          for (final l in active) _item(system, l),
        ],
        if (queue.isNotEmpty) ...[
          const SectionHeader('Next'),
          for (final l in queue) _item(system, l),
        ],
        if (active.isEmpty && queue.isEmpty)
          const EmptyNote('Add what you want to learn from next — a book, a course, a talk.',
              icon: Icons.school_outlined),
        const SectionHeader('Add'),
        TextField(
          key: const Key('learning-title'),
          controller: _title,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Title'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _by,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Author or teacher (optional)'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in PersonalSystemProvider.learningKinds)
              ChoiceChip(
                label: Text(k),
                selected: _kind == k,
                showCheckmark: false,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton('Add', icon: Icons.add_rounded, onPressed: () {
          if (system.addLearning(_title.text, kind: _kind, by: _by.text) == null) {
            toast(context, 'Give it a title.');
            return;
          }
          _title.clear();
          _by.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }),
        if (done.isNotEmpty) ...[
          SectionHeader('Applied · ${done.length}'),
          for (final l in done) _item(system, l),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

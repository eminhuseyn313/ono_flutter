import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

// ── Promises ───────────────────────────────────────────────────────────

/// What you said you'd do: kept, renegotiated in time, or missed.
class PromisesScreen extends StatefulWidget {
  const PromisesScreen({super.key});

  @override
  State<PromisesScreen> createState() => _PromisesScreenState();
}

class _PromisesScreenState extends State<PromisesScreen> {
  final _what = TextEditingController();
  final _to = TextEditingController();
  int _inDays = 1;

  @override
  void dispose() {
    _what.dispose();
    _to.dispose();
    super.dispose();
  }

  void _add(PersonalSystemProvider system) {
    if (_what.text.trim().isEmpty) {
      toast(context, 'Write what you promised.');
      return;
    }
    system.addPromise(
        what: _what.text,
        to: _to.text,
        by: DateTime.now().add(Duration(days: _inDays)));
    _what.clear();
    _to.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    toast(context, 'Noted. It shows on Today on the day.');
  }

  Future<void> _close(PersonalSystemProvider system, LogEntry p) async {
    final outcome = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.text, style: AppText.title()),
              if ((p.str('to') ?? '').isNotEmpty)
                Text('To ${p.str('to')}', style: AppText.small()),
              const SizedBox(height: 14),
              for (final o in PersonalSystemProvider.promiseOutcomes.entries)
                if (o.key != 'renegotiated' || !system.promiseOverdue(p))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: o.key == 'kept'
                          ? FilledButton(
                              onPressed: () => Navigator.pop(ctx, o.key),
                              child: Text(o.value))
                          : OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, o.key),
                              child: Text(o.key == 'renegotiated'
                                  ? 'New date: one week later'
                                  : o.value)),
                    ),
                  ),
              if (system.promiseOverdue(p))
                Text('The date has passed: it was kept late, or missed.',
                    style: AppText.small()),
            ],
          ),
        ),
      ),
    );
    if (outcome == null) return;
    system.closePromise(p.id, outcome);
    if (mounted && outcome == 'renegotiated') {
      toast(context, 'Tell them the new date now — that\'s what keeps trust.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final open = system.openPromises;
    final record = system.sayDo();
    final today = dateKey(DateTime.now());
    const days = [1, 3, 7, 14];
    return OnoPage(
      showBack: true,
      eyebrow: 'Promises',
      title: 'Keep your word',
      subtitle:
          'Small promises — "I\'ll send it Friday", "I\'ll be there at six" — are how people decide whether to trust you. Note them, keep them, and when you can\'t, say so before the day.',
      children: [
        if (record != null) ...[
          const SizedBox(height: 14),
          Text(
              'Kept ${record.kept} of ${record.kept + record.missed} in the last 90 days.',
              style: AppText.body(color: AppColors.accent)),
        ],
        const SectionHeader('A new promise'),
        TextField(
          controller: _what,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              labelText: 'What you promised', hintText: 'e.g. Send the draft'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _to,
          style: AppText.body(color: AppColors.white),
          decoration:
              const InputDecoration(labelText: 'To whom', hintText: 'Optional'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final d in days)
              ChoiceChip(
                label: Text(d == 1 ? 'Tomorrow' : 'In $d days'),
                selected: _inDays == d,
                showCheckmark: false,
                onSelected: (_) => setState(() => _inDays = d),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GhostButton('Add promise',
            icon: Icons.add_rounded, onPressed: () => _add(system)),
        SectionHeader('Open · ${open.length}'),
        if (open.isEmpty)
          Text('Nothing open.', style: AppText.small())
        else
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, p) in open.indexed) ...[
                  if (i > 0) const Divider(indent: 16),
                  ListTile(
                    title: Text(p.text,
                        style: AppText.body(color: AppColors.white)),
                    subtitle: Text(
                        '${(p.str('to') ?? '').isEmpty ? '' : 'To ${p.str('to')} · '}'
                        '${(p.str('by') ?? '').compareTo(today) < 0 ? 'overdue · ' : ''}by ${p.str('by')}',
                        style: AppText.small(
                            color: (p.str('by') ?? '').compareTo(today) < 0
                                ? AppColors.warning
                                : AppColors.grey)),
                    trailing: TextButton(
                      onPressed: () => _close(system, p),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Story bank ─────────────────────────────────────────────────────────

/// Your best experiences as situation–task–action–result stories, tagged
/// by the skill they show.
class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  Future<void> _edit(BuildContext context,
          {LogEntry? story, String title = '', String from = ''}) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              StoryEditScreen(story: story, title: title, from: from)));

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final stories = system.stories;
    final ideas = system.storyIdeas;
    final gaps = system.storyGaps;
    return OnoPage(
      showBack: true,
      eyebrow: 'Story bank',
      title: 'Your best stories, ready',
      subtitle:
          'For an interview, a promotion case or a review: what the situation was, what you had to do, what you did, and what came of it.',
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: GhostButton('New story',
                    icon: Icons.add_rounded, onPressed: () => _edit(context))),
            const SizedBox(width: 10),
            Expanded(
              child: GhostButton('Copy all',
                  icon: Icons.copy_rounded,
                  onPressed: stories.isEmpty
                      ? null
                      : () => copyText(context, system.storiesText(),
                          message: 'Stories copied')),
            ),
          ],
        ),
        if (ideas.isNotEmpty) ...[
          const SectionHeader('From your wins and reviews'),
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, l) in ideas.indexed) ...[
                  if (i > 0) const Divider(indent: 66),
                  LinkRow(
                    icon: l.type == 'aar'
                        ? Icons.flag_outlined
                        : Icons.emoji_events_outlined,
                    color: AppColors.accent,
                    title: l.text,
                    subtitle: 'Turn it into a story',
                    onTap: () => _edit(context, title: l.text, from: l.id),
                  ),
                ],
              ],
            ),
          ),
        ],
        SectionHeader('Stories · ${stories.length}'),
        if (stories.isEmpty)
          Text('None yet. Start with the moment you\'re proudest of.',
              style: AppText.small())
        else
          for (final s in stories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _edit(context, story: s),
                child: OnoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.text, style: AppText.heading()),
                      if (system.skillsOf(s).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(system.skillsOf(s).join(' · '),
                            style: AppText.small(color: AppColors.accent)),
                      ],
                      if ((s.str('result') ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Result: ${s.str('result')}',
                            style: AppText.small()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        if (stories.isNotEmpty && gaps.isNotEmpty) ...[
          const SectionHeader('No story yet for'),
          Text(gaps.join(' · '), style: AppText.small()),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class StoryEditScreen extends StatefulWidget {
  final LogEntry? story;
  final String title;
  final String from;
  const StoryEditScreen(
      {super.key, this.story, this.title = '', this.from = ''});

  @override
  State<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends State<StoryEditScreen> {
  late final _title =
      TextEditingController(text: widget.story?.text ?? widget.title);
  late final _situation =
      TextEditingController(text: widget.story?.str('situation') ?? '');
  late final _task =
      TextEditingController(text: widget.story?.str('task') ?? '');
  late final _action =
      TextEditingController(text: widget.story?.str('action') ?? '');
  late final _result =
      TextEditingController(text: widget.story?.str('result') ?? '');
  late final Set<String> _skills = {
    for (final k in (widget.story?.data['skills'] as List?) ?? const []) '$k'
  };

  @override
  void dispose() {
    for (final c in [_title, _situation, _task, _action, _result]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          minLines: 2,
          maxLines: 6,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'A story',
      title: widget.story == null ? 'Tell it in four parts' : 'Edit the story',
      bottomBar:
          PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_title.text.trim().isEmpty) {
          toast(context, 'Give it a title.');
          return;
        }
        system.saveStory(
          id: widget.story?.id,
          title: _title.text,
          situation: _situation.text,
          task: _task.text,
          action: _action.text,
          result: _result.text,
          skills: _skills.toList(),
          from: widget.story?.str('from') ?? widget.from,
        );
        toast(context, 'Saved to your story bank.');
        Navigator.of(context).pop();
      }),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: _title,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Turning around the late launch'),
          ),
        ),
        _field(_situation, 'Situation',
            'Where and when — the context in two lines'),
        _field(_task, 'Task', 'What you had to achieve, and why it was hard'),
        _field(_action, 'Action', 'What you did — "I", not "we"'),
        _field(_result, 'Result', 'What changed, ideally with a number'),
        const SectionHeader('What it shows'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in PersonalSystemProvider.storySkills)
              FilterChip(
                label: Text(k),
                selected: _skills.contains(k),
                onSelected: (on) =>
                    setState(() => on ? _skills.add(k) : _skills.remove(k)),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../widgets/support_sheet.dart';
import '../time.dart';

Widget _field(TextEditingController c, String label, String hint,
        {int minLines = 2, ValueChanged<String>? onChanged}) =>
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: c,
        minLines: minLines,
        maxLines: 6,
        onChanged: onChanged,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );

void _close(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/home');

String _clock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

// ── Thought check ──────────────────────────────────────────────────────

/// A thought record: put one thought to the test, the way CBT does
/// (Beck 1979). The feeling is rated before and after.
class ThoughtScreen extends StatefulWidget {
  const ThoughtScreen({super.key});

  @override
  State<ThoughtScreen> createState() => _ThoughtScreenState();
}

class _ThoughtScreenState extends State<ThoughtScreen> {
  final _situation = TextEditingController();
  final _thought = TextEditingController();
  final _for = TextEditingController();
  final _against = TextEditingController();
  final _balanced = TextEditingController();
  String _feeling = '';
  double _before = 60;
  double? _after;

  @override
  void dispose() {
    for (final c in [_situation, _thought, _for, _against, _balanced]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _rating(String label, double value) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.small())),
            Text('${value.round()}', style: AppText.number(size: 16)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final relief = system.thoughtRelief;
    return UnsavedGuard(
        fields: [_situation, _thought, _for, _against, _balanced],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Thought check · 5 minutes',
      title: 'Is that thought true?',
      subtitle:
          'Catch the thought, weigh it like a fair judge, write a more balanced one. Feelings follow the thoughts we believe.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_thought.text.trim().isEmpty) {
          toast(context, 'Write the thought first.');
          return;
        }
        system.logThought(
          situation: _situation.text,
          thought: _thought.text,
          feeling: _feeling,
          before: _before.round(),
          evidenceFor: _for.text,
          evidenceAgainst: _against.text,
          balanced: _balanced.text,
          after: _after?.round(),
        );
        final drop = _after == null ? null : (_before - _after!).round();
        toast(
            context,
            drop != null && drop > 0
                ? 'Saved. $drop points lighter.'
                : 'Saved. Noticing it is the first step.');
        _close(context);
      }),
      children: [
        const SupportLink(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('to-compassion'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => context.push('/compassion'),
            child: const Text('Being hard on yourself? Two minutes on your own side first →'),
          ),
        ),
        _field(_situation, 'What happened?', 'Where, when, who — just the facts'),
        _field(_thought, 'What went through your mind?',
            'e.g. "They think I\'m not good enough"'),
        const SectionHeader('The feeling'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final f in PersonalSystemProvider.thoughtFeelings)
              ChoiceChip(
                label: Text(f),
                selected: _feeling == f,
                showCheckmark: false,
                onSelected: (on) => setState(() => _feeling = on ? f : ''),
              ),
          ],
        ),
        _rating('How strong, 0–100', _before),
        Slider(
          value: _before,
          max: 100,
          divisions: 20,
          onChanged: (v) => setState(() => _before = v),
        ),
        _field(_for, 'Evidence that supports the thought', 'Facts only, not feelings'),
        _field(_against, 'Evidence that doesn\'t fit it',
            'What would a friend point out? What happened last time?'),
        _field(_balanced, 'A more balanced thought',
            'Something you can believe that takes in all the evidence'),
        _rating('The feeling now, 0–100', _after ?? _before),
        Slider(
          value: _after ?? _before,
          max: 100,
          divisions: 20,
          onChanged: (v) => setState(() => _after = v),
        ),
        if (relief != null) ...[
          const SizedBox(height: 8),
          Text(
              'Your checks in the last 30 days took the feeling down ${relief.round()} points on average.',
              style: AppText.small()),
        ],
        // What you concluded before, in your own words: the coping card.
        if (system.thoughts
                .where((t) => (t.str('balanced') ?? '').trim().isNotEmpty)
                .take(3)
                .toList()
            case final past when past.isNotEmpty) ...[
          const SectionHeader('What you concluded before'),
          for (final t in past)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('"${t.str('balanced')!.trim()}"',
                  style: AppText.body(color: AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    ));
  }
}

// ── Best possible future ───────────────────────────────────────────────

/// Write your life a few years out, when things have gone as well as they
/// realistically could (King 2001), then one thing it asks of this week.
class BestFutureScreen extends StatefulWidget {
  const BestFutureScreen({super.key});

  @override
  State<BestFutureScreen> createState() => _BestFutureScreenState();
}

class _BestFutureScreenState extends State<BestFutureScreen> {
  final _areas = {
    for (final a in PersonalSystemProvider.bestFutureAreas)
      a.$1: TextEditingController(),
  };
  final _step = TextEditingController();
  int _years = 1;
  final _saves = 0;

  @override
  void dispose() {
    for (final c in [..._areas.values, _step]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final last = system.bestFuture;
    const years = [1, 3, 5];
    return UnsavedGuard(
        changesOnly: true,
        saves: _saves,
        fields: [..._areas.values, _step],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Best possible future · 15 minutes',
      title: 'Your life, when it goes well',
      subtitle:
          'Imagine everything has gone as well as it realistically could. You worked hard and it paid off. Write what you see — in the present tense, as if it is already true.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_areas.values.every((c) => c.text.trim().isEmpty)) {
          toast(context, 'Write at least one part.');
          return;
        }
        system.saveBestFuture(
          years: _years,
          areas: {for (final e in _areas.entries) e.key: e.value.text},
          step: _step.text,
        );
        toast(context, 'Saved. Read it again on a hard day.');
        _close(context);
      }),
      children: [
        const SectionHeader('How far ahead?'),
        Segmented(
          labels: [for (final y in years) y == 1 ? '1 year' : '$y years'],
          index: years.indexOf(_years),
          onChanged: (i) => setState(() => _years = years[i]),
        ),
        for (final a in PersonalSystemProvider.bestFutureAreas)
          _field(_areas[a.$1]!, a.$2, 'It is ${timeNow().year + _years}. …',
              minLines: 3),
        _field(_step, 'One thing that future asks of you this week',
            'Small enough to do by Sunday'),
        if (last != null) ...[
          SectionHeader('Last time · ${shortDate(last.date)}'),
          OnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in PersonalSystemProvider.bestFutureAreas)
                  if ((last.data['areas'] as Map?)?[a.$1] case final String t)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.$2, style: AppText.eyebrow()),
                          const SizedBox(height: 2),
                          Text(t, style: AppText.body(color: AppColors.white)),
                        ],
                      ),
                    ),
                TextButton(
                  onPressed: () => context.push(
                      '/goals/edit?title=${Uri.encodeComponent(((last.data['areas'] as Map?)?.values.first ?? '').toString().split('.').first)}'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Make part of it a goal'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    ));
  }
}

// ── Kindness day ───────────────────────────────────────────────────────

/// Five small acts of kindness on one chosen day a week.
class KindnessScreen extends StatefulWidget {
  const KindnessScreen({super.key});

  @override
  State<KindnessScreen> createState() => _KindnessScreenState();
}

class _KindnessScreenState extends State<KindnessScreen> {
  final _act = TextEditingController();
  final _cause = TextEditingController();

  @override
  void dispose() {
    _act.dispose();
    _cause.dispose();
    super.dispose();
  }

  void _add(PersonalSystemProvider system) {
    if (_act.text.trim().isEmpty) return;
    system.logKindness(_act.text);
    _act.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = timeNow();
    final today = system.kindnessOn(now);
    final day = system.kindnessDay;
    const goal = PersonalSystemProvider.kindnessPerDay;
    return OnoPage(
      showBack: true,
      eyebrow: 'Kindness day',
      title: 'Five kind acts, one day',
      subtitle:
          'Pick one day a week and do five small kind things that day — a coffee, a thank-you, an hour of help. Bunched into one day, they lift you more than the same acts spread out.',
      children: [
        const SectionHeader('Your day'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var w = DateTime.monday; w <= DateTime.sunday; w++)
              ChoiceChip(
                label: Text(weekdayName(w).substring(0, 3)),
                selected: day == w,
                showCheckmark: false,
                onSelected: (on) => system.setKindnessDay(on ? w : null),
              ),
          ],
        ),
        SectionHeader('Today · ${today.length}/$goal'),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in today)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          size: 16, color: AppColors.social),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(k.text,
                              style: AppText.body(color: AppColors.white))),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _act,
                      onSubmitted: (_) => _add(system),
                      style: AppText.body(color: AppColors.white),
                      decoration: const InputDecoration(
                          hintText: 'What did you do, for whom?'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add',
                    onPressed: () => _add(system),
                    icon: const Icon(Icons.add_circle_rounded,
                        color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('This week: ${system.kindnessInWeek(now)} acts.',
            style: AppText.small()),
        const SectionHeader('Giving time'),
        Text('Time for a cause beyond your own circle: a charity, a school, your street, a club.',
            style: AppText.small()),
        const SizedBox(height: 8),
        TextField(
          key: const Key('giving-cause'),
          controller: _cause,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Where you gave time'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final h in PersonalSystemProvider.givingHours)
              ActionChip(
                key: Key('giving-$h'),
                label: Text('$h h'),
                onPressed: () {
                  if (system.logGiving(_cause.text, h.toDouble()) == null) {
                    toast(context, 'Say where first.');
                    return;
                  }
                  _cause.clear();
                  toast(context, 'Logged $h h.');
                },
              ),
          ],
        ),
        if (system.givingThisYear.$1 > 0) ...[
          const SizedBox(height: 8),
          Text(
              'In the last year: ${system.givingThisYear.$1.round()} h · ${system.givingThisYear.$2.take(4).join(', ')}',
              style: AppText.small(color: AppColors.social)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Worry time ─────────────────────────────────────────────────────────

/// Park worries when they come; deal with them in one slot a day.
class WorryScreen extends StatefulWidget {
  const WorryScreen({super.key});

  @override
  State<WorryScreen> createState() => _WorryScreenState();
}

class _WorryScreenState extends State<WorryScreen> {
  final _worry = TextEditingController();

  @override
  void dispose() {
    _worry.dispose();
    super.dispose();
  }

  void _park(PersonalSystemProvider system) {
    if (_worry.text.trim().isEmpty) return;
    system.parkWorry(_worry.text);
    _worry.clear();
    toast(context, system.worryTime == null
        ? 'Parked. Set a worry time to come back to it.'
        : 'Parked until ${_clock(system.worryTime!)}.');
  }

  Future<void> _pickTime(PersonalSystemProvider system) async {
    final t = system.worryTime ?? 18 * 60;
    final picked = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: t ~/ 60, minute: t % 60));
    if (picked != null) system.setWorryTime(picked.hour * 60 + picked.minute);
  }

  Future<void> _resolve(PersonalSystemProvider system, LogEntry w) async {
    final step = TextEditingController();
    final outcome = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.text, style: AppText.title()),
            const SizedBox(height: 8),
            Text('Can you do something about it?', style: AppText.small()),
            const SizedBox(height: 12),
            TextField(
              controller: step,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  hintText: 'The smallest next step, if there is one'),
            ),
            const SizedBox(height: 14),
            for (final o in PersonalSystemProvider.worryOutcomes.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: o.key == 'acted'
                      ? FilledButton(
                          onPressed: () => Navigator.pop(ctx, o.key),
                          child: Text(o.value))
                      : OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, o.key),
                          child: Text(o.value)),
                ),
              ),
          ],
        ),
      ),
    );
    if (outcome == null) return;
    if (outcome == 'acted' && step.text.trim().isEmpty) {
      if (mounted) toast(context, 'Write the step, or let it go.');
      return;
    }
    system.resolveWorry(w.id, outcome: outcome, step: step.text);
    if (mounted && outcome == 'acted') {
      toast(context, 'Added to today\'s priorities if there was room.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final parked = system.parkedWorries;
    final time = system.worryTime;
    final due = system.worryTimeDue(timeNow());
    return OnoPage(
      showBack: true,
      eyebrow: 'Worry time',
      title: due ? 'Your worry time' : 'Park it for later',
      subtitle:
          'When a worry comes, write it down and let it wait. Once a day, at a set time, give each one a few minutes: a next step, or let it go. Worry you postpone tends to shrink.',
      children: [
        const SizedBox(height: 12),
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.schedule_rounded,
            color: AppColors.mind,
            title: time == null ? 'Set your worry time' : 'Worry time ${_clock(time)}',
            subtitle: '15 minutes, not in the hour before bed',
            onTap: () => _pickTime(system),
          ),
        ),
        const SectionHeader('Park a worry'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _worry,
                onSubmitted: (_) => _park(system),
                style: AppText.body(color: AppColors.white),
                decoration:
                    const InputDecoration(hintText: 'What\'s on your mind?'),
              ),
            ),
            IconButton(
              onPressed: () => _park(system),
              tooltip: 'Park it',
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.accent),
            ),
          ],
        ),
        SectionHeader('Parked · ${parked.length}'),
        if (parked.isEmpty)
          Text('Nothing parked.', style: AppText.small())
        else
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, w) in parked.indexed) ...[
                  if (i > 0) const Divider(indent: 16),
                  ListTile(
                    title: Text(w.text,
                        style: AppText.body(color: AppColors.white)),
                    subtitle: Text(shortDate(w.date), style: AppText.small()),
                    trailing: TextButton(
                      onPressed: () => _resolve(system, w),
                      child: const Text('Deal with it'),
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

// ── Life chapters ──────────────────────────────────────────────────────

/// Your life as chapters: a high point, a low point and what each taught,
/// then the chapter you're in and the title of the next.
class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  static const _keys = ['title', 'years', 'high', 'low', 'taught'];
  late final List<Map<String, TextEditingController>> _chapters;
  late final TextEditingController _now;
  late final TextEditingController _next;
  final _saves = 0;

  Map<String, TextEditingController> _blank([Map<String, String>? from]) =>
      {for (final k in _keys) k: TextEditingController(text: from?[k] ?? '')};

  @override
  void initState() {
    super.initState();
    final system = context.read<PersonalSystemProvider>();
    final saved = system.lifeChapters;
    _chapters = [for (final c in saved) _blank(c)];
    if (_chapters.isEmpty) _chapters.addAll([_blank(), _blank()]);
    _now = TextEditingController(
        text: system.lifeStory?.str('now') ?? '');
    _next = TextEditingController(
        text: system.lifeStory?.str('next') ?? '');
  }

  @override
  void dispose() {
    for (final c in _chapters) {
      for (final t in c.values) {
        t.dispose();
      }
    }
    _now.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return UnsavedGuard(
        changesOnly: true,
        saves: _saves,
        fields: [_now, _next, for (final c in _chapters) ...c.values],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Life chapters',
      title: 'The story so far',
      subtitle:
          'Split your life into a few chapters. For each: a high point, a low point, and what it taught you. People who see growth in their own story tend to do better.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        system.saveLifeStory(
          chapters: [
            for (final c in _chapters)
              {for (final e in c.entries) e.key: e.value.text},
          ],
          now: _now.text,
          next: _next.text,
        );
        toast(context, 'Saved. Come back to it when a chapter turns.');
        _close(context);
      }),
      children: [
        for (final (i, c) in _chapters.indexed) ...[
          SectionHeader('Chapter ${i + 1}'),
          OnoCard(
            child: Column(
              children: [
                TextField(
                  controller: c['title'],
                  style: AppText.heading(),
                  decoration: const InputDecoration(
                      labelText: 'Title', hintText: 'e.g. Leaving home'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: c['years'],
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      labelText: 'When', hintText: 'e.g. 2012–2016'),
                ),
                for (final (k, label, hint) in const [
                  ('high', 'A high point', 'A moment you felt most alive'),
                  ('low', 'A low point', 'A moment that was hard'),
                  ('taught', 'What it taught you', 'What you carry from it'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: c[k],
                      minLines: 1,
                      maxLines: 4,
                      style: AppText.body(color: AppColors.white),
                      decoration: InputDecoration(labelText: label, hintText: hint),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (_chapters.length < 8)
          TextButton.icon(
            onPressed: () => setState(() => _chapters.add(_blank())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Another chapter'),
          ),
        _field(_now, 'The chapter you\'re in now', 'What it is about'),
        _field(_next, 'The title of the next chapter', 'The one you want to write',
            minLines: 1),
        const SizedBox(height: 16),
      ],
    ));
  }
}

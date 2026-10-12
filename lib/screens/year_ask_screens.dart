import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

// ── Year in review ─────────────────────────────────────────────────────

/// Close the calendar year: what it added up to, six questions, and one
/// word to carry into the next.
class YearReviewScreen extends StatefulWidget {
  const YearReviewScreen({super.key});

  @override
  State<YearReviewScreen> createState() => _YearReviewScreenState();
}

class _YearReviewScreenState extends State<YearReviewScreen> {
  final _answers = {
    for (final q in PersonalSystemProvider.yearQuestions)
      q.$1: TextEditingController()
  };
  final _word = TextEditingController();
  late int _year;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    _year = system.yearOnScreen;
    final r = system.yearReviewFor(_year);
    for (final e in _answers.entries) {
      e.value.text = r?.str(e.key) ?? '';
    }
    _word.text = r?.text ?? '';
  }

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final y = system.yearSummary(_year);
    final pct = y.counted == 0 ? null : (y.held * 100 / y.counted).round();
    final canClose = system.canCloseYear(_year);
    return OnoPage(
      showBack: true,
      eyebrow: canClose ? 'Year in review · 20 minutes' : 'Year in review',
      title: canClose ? 'Close $_year' : '$_year so far',
      subtitle: canClose
          ? 'Look at what the year added up to before you answer — memory keeps the last few weeks and the worst days. Then choose one word for the next.'
          : 'What the year has added up to so far, from what you logged.',
      bottomBar: !canClose
          ? null
          : PrimaryButton('Save the review', icon: Icons.check_rounded,
              onPressed: () {
              final answers = {
                for (final e in _answers.entries) e.key: e.value.text
              };
              if (answers.values.every((a) => a.trim().isEmpty) &&
                  _word.text.trim().isEmpty) {
                toast(context, 'Answer one question first.');
                return;
              }
              system.saveYearReview(_year, answers: answers, word: _word.text);
              toast(context, '$_year closed. It\'s in your journal.');
              context.canPop() ? context.pop() : context.go('/home');
            }),
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile(
                    pct == null ? '—' : '$pct%',
                    y.counted == 0
                        ? 'days held'
                        : 'days held (${y.held} of ${y.counted})')),
            Expanded(child: StatTile('${y.wins}', 'wins')),
            Expanded(child: StatTile('${y.goalsReached}', 'goals reached')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: StatTile('${y.reps}', 'practice reps')),
            Expanded(child: StatTile('${y.focusHours}', 'deep-work hours')),
            Expanded(child: StatTile('${y.promisesKept}', 'promises kept')),
          ],
        ),
        if (y.topWins.isNotEmpty) ...[
          const SectionHeader('Your wins, in order'),
          for (final w in y.topWins.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $w', style: AppText.body(color: AppColors.white)),
            ),
          if (y.topWins.length > 12)
            Text('and ${y.topWins.length - 12} more', style: AppText.small()),
        ],
        if (y.lessons.isNotEmpty) ...[
          const SectionHeader('What you wrote down along the way'),
          for (final l in y.lessons.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $l', style: AppText.body(color: AppColors.white)),
            ),
        ],
        if (!canClose) ...[
          const SizedBox(height: 20),
          Text(
              'You can close $_year from 15 December. The questions will be here then.',
              style: AppText.small()),
        ] else ...[
          for (final q in PersonalSystemProvider.yearQuestions) ...[
            SectionHeader(q.$2),
            TextField(
              controller: _answers[q.$1],
              minLines: 2,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
            ),
          ],
          const SectionHeader('One word for next year'),
          TextField(
            controller: _word,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                hintText: 'e.g. Steady, Brave, Home, Build'),
          ),
          const SizedBox(height: 8),
          Text('It shows on Me through the year and reaches your weekly brief.',
              style: AppText.small()),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Ask for help ───────────────────────────────────────────────────────

/// Write down who you'll ask, guess the chance of a yes, then note the
/// answer. People guess about half as many yeses as they get.
class AsksScreen extends StatefulWidget {
  const AsksScreen({super.key});

  @override
  State<AsksScreen> createState() => _AsksScreenState();
}

class _AsksScreenState extends State<AsksScreen> {
  final _what = TextEditingController();
  final _of = TextEditingController();
  double _guess = 50;

  @override
  void dispose() {
    _what.dispose();
    _of.dispose();
    super.dispose();
  }

  void _add(PersonalSystemProvider system) {
    if (_what.text.trim().isEmpty) {
      toast(context, 'Write what you\'ll ask for.');
      return;
    }
    system.addAsk(what: _what.text, of: _of.text, guess: _guess.round());
    _what.clear();
    _of.clear();
    setState(() => _guess = 50);
    FocusManager.instance.primaryFocus?.unfocus();
    toast(context, 'Now ask — today if you can. Note the answer here.');
  }

  Future<void> _close(PersonalSystemProvider system, LogEntry a) async {
    final outcome = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.text, style: AppText.title()),
              Text(
                  '${(a.str('of') ?? '').isEmpty ? '' : '${a.str('of')} · '}you guessed ${a.number('guess')?.toInt() ?? 50}%',
                  style: AppText.small()),
              const SizedBox(height: 14),
              for (final o in PersonalSystemProvider.askOutcomes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: o.key == 'yes'
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
      ),
    );
    if (outcome == null) return;
    system.closeAsk(a.id, outcome);
    if (mounted) {
      toast(
          context,
          outcome == 'no'
              ? 'Noted. A no is about the ask, not about you — ask someone else.'
              : 'Noted. Thank them — and remember this next time.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final open = system.openAsks;
    final record = system.askRecord();
    final answered = [
      for (final a in system.logsOf('ask'))
        if (a.str('status') != 'asked') a
    ];
    return OnoPage(
      showBack: true,
      eyebrow: 'Ask for help',
      title: 'Ask, then count the yeses',
      subtitle:
          'People expect about half as many yeses as they get, so they don\'t ask. Guess the chance before you ask, note the answer after — your own numbers fix the guess.',
      children: [
        if (record != null) ...[
          const SizedBox(height: 14),
          OnoCard(
            child: Row(
              children: [
                Expanded(
                    child: StatTile(
                        '${(record.yes * 100 / record.asked).round()}%',
                        'said yes or partly (${record.yes} of ${record.asked})',
                        color: AppColors.accent)),
                Expanded(child: StatTile('${record.guess}%', 'you expected')),
              ],
            ),
          ),
        ],
        const SectionHeader('A new ask'),
        TextField(
          controller: _what,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              labelText: 'What you\'ll ask for',
              hintText: 'Specific: "20 minutes on my draft by Friday"'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _of,
          style: AppText.body(color: AppColors.white),
          decoration:
              const InputDecoration(labelText: 'Who', hintText: 'Optional'),
        ),
        const SizedBox(height: 12),
        Text('How likely are they to say yes? ${_guess.round()}%',
            style: AppText.small(color: AppColors.white)),
        Slider(
          value: _guess,
          max: 100,
          divisions: 20,
          onChanged: (v) => setState(() => _guess = v),
        ),
        Text(
            'Ask in person or by name, say why it matters, make it easy to say yes.',
            style: AppText.small()),
        const SizedBox(height: 10),
        GhostButton('Add the ask',
            icon: Icons.add_rounded, onPressed: () => _add(system)),
        SectionHeader('Waiting for an answer · ${open.length}'),
        if (open.isEmpty)
          Text('Nothing waiting.', style: AppText.small())
        else
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, a) in open.indexed) ...[
                  if (i > 0) const Divider(indent: 16),
                  ListTile(
                    title: Text(a.text,
                        style: AppText.body(color: AppColors.white)),
                    subtitle: Text(
                        '${(a.str('of') ?? '').isEmpty ? '' : '${a.str('of')} · '}guessed ${a.number('guess')?.toInt() ?? 50}% · ${shortDate(a.date)}',
                        style: AppText.small()),
                    trailing: TextButton(
                      onPressed: () => _close(system, a),
                      child: const Text('Answer'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (answered.isNotEmpty) ...[
          const SectionHeader('Answered'),
          for (final a in answered.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${PersonalSystemProvider.askOutcomes[a.str('status')] ?? a.str('status')} · ${a.text}${(a.str('of') ?? '').isEmpty ? '' : ' (${a.str('of')})'}',
                  style: AppText.small(
                      color: a.str('status') == 'no'
                          ? AppColors.grey
                          : AppColors.white)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

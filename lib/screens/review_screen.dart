import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Spaced repetition on ONO's own deck: domain facts, the thesis, protocols,
/// every Feynman note and your own cards, scheduled with SM-2. Spaced
/// retrieval beats re-reading by a wide margin; five minutes a day is enough.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<StudyCard> _queue;
  int _index = 0;
  int _reviewed = 0;
  bool _showBack = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _queue = context.read<PersonalSystemProvider>().dueCards(DateTime.now());
  }

  void _grade(int grade) {
    final system = context.read<PersonalSystemProvider>();
    final card = _queue[_index];
    system.gradeCard(card.id, grade);
    HapticFeedback.selectionClick();
    setState(() {
      _reviewed++;
      // "Again" comes back at the end of this session.
      if (grade < 3) _queue.add(card);
      _index++;
      _showBack = false;
    });
    if (_index >= _queue.length) system.finishReview(_reviewed);
  }

  Future<void> _addCard() async {
    final front = TextEditingController();
    final back = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New card', style: AppText.title()),
            const SizedBox(height: 12),
            TextField(
                controller: front,
                maxLines: null,
                decoration: const InputDecoration(
                    hintText: 'Question — e.g. "Kaspi QR acceptance?"')),
            const SizedBox(height: 10),
            TextField(
                controller: back,
                maxLines: null,
                decoration: const InputDecoration(hintText: 'Answer')),
            const SizedBox(height: 16),
            PrimaryButton('Add card',
                onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      context
          .read<PersonalSystemProvider>()
          .addCustomCard(front.text, back.text);
      toast(context, 'Card added — it appears in a coming session.');
    }
    front.dispose();
    back.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final stats = system.deckStats;
    final done = _index >= _queue.length;
    final card = done ? null : _queue[_index];
    return OnoPage(
      showBack: true,
      eyebrow: 'Spaced repetition · ${stats.total} cards',
      title: 'Review',
      subtitle: done
          ? null
          : 'Answer in your head first, then reveal. Be honest — "Again" is how it sticks.',
      actions: [
        IconButton(
          tooltip: 'Add a card',
          onPressed: _addCard,
          icon: const Icon(Icons.add_rounded, color: AppColors.white),
        ),
      ],
      bottomBar: done
          ? PrimaryButton('Back',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'))
          : !_showBack
              ? PrimaryButton('Show answer',
                  onPressed: () => setState(() => _showBack = true))
              : Row(
                  children: [
                    for (final (g, label) in [
                      (0, 'Again'),
                      (3, 'Hard'),
                      (4, 'Good'),
                      (5, 'Easy')
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _GradeButton(
                            label: label,
                            hint: g == 0
                                ? 'today'
                                : '${system.previewInterval(card!.id, g)} d',
                            primary: g == 4,
                            onTap: () => _grade(g),
                          ),
                        ),
                      ),
                  ],
                ),
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: StatTile(
                    '${(_queue.length - _index).clamp(0, 999)}', 'left today')),
            Expanded(child: StatTile('${stats.learning}', 'learning')),
            Expanded(child: StatTile('${stats.mature}', 'mature (21 d+)')),
          ],
        ),
        const SizedBox(height: 14),
        if (done)
          OnoCard(
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_reviewed == 0 ? 'NOTHING DUE' : 'SESSION DONE',
                    style: AppText.eyebrow(color: AppColors.accent)),
                const SizedBox(height: 8),
                Text(
                    _reviewed == 0
                        ? 'All caught up. New cards arrive $newCardsPerDay a day; every Feynman note becomes one.'
                        : '$_reviewed reviews. Spacing does the rest — see you tomorrow.',
                    style: AppText.serif(size: 22)),
              ],
            ),
          )
        else ...[
          OnoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    switch (card!.source) {
                      'feynman' => 'YOUR FEYNMAN NOTE',
                      'custom' => 'YOUR CARD',
                      _ => system.scheduleOf(card.id) == null
                          ? 'NEW CARD'
                          : 'REVIEW',
                    },
                    style: AppText.eyebrow(color: AppColors.accent)),
                const SizedBox(height: 10),
                Text(card.front, style: AppText.serif(size: 24)),
                if (_showBack) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),
                  Text(card.back, style: AppText.body(color: AppColors.white)),
                ],
              ],
            ),
          ),
          if (card.source == 'custom' && _showBack)
            TextButton(
              onPressed: () {
                system.removeCustomCard(card.id);
                setState(() => _queue.removeAt(_index));
              },
              child: const Text('Delete this card'),
            ),
        ],
      ],
    );
  }
}

class _GradeButton extends StatelessWidget {
  final String label;
  final String hint;
  final bool primary;
  final VoidCallback onTap;
  const _GradeButton(
      {required this.label,
      required this.hint,
      required this.primary,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.accent : AppColors.cardLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppText.small(
                          color: primary ? AppColors.ink : AppColors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(hint,
                  style: AppText.small(
                          color: primary ? AppColors.ink : AppColors.grey)
                      .copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

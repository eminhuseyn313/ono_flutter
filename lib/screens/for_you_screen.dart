import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// For you: books, films, podcasts, practices, steps and tools chosen from
/// what the person told ONO (life wheel, goal, role, this month's area).
/// Each can be put to use in one tap, or set aside with "Not for me".
class ForYouScreen extends StatefulWidget {
  /// Straight after the plan builder: ends with "Go to Today".
  final bool first;
  const ForYouScreen({super.key, this.first = false});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  static const _shownAreas = 3;
  static const _perArea = 4;

  String? _kind;
  final _expanded = <String>{};
  final _openAreas = <String>{};

  static IconData _icon(String kind) => switch (kind) {
        'read' => Icons.menu_book_outlined,
        'watch' => Icons.movie_outlined,
        'listen' => Icons.headphones_outlined,
        'course' => Icons.school_outlined,
        'daily' => Icons.repeat_rounded,
        'step' => Icons.flag_outlined,
        _ => Icons.open_in_new_rounded,
      };

  static String _action(String kind) => switch (kind) {
        'read' || 'watch' || 'listen' || 'course' => 'Add to my list',
        'daily' => 'Add as a daily item',
        'step' => 'Add to this week',
        _ => 'Open',
      };

  void _take(PersonalSystemProvider system, Suggestion s) {
    if (s.kind == 'tool') {
      context.push(s.route);
      return;
    }
    final r = system.takeSuggestion(s);
    if (r.message.isNotEmpty) toast(context, r.message);
  }

  Widget _card(PersonalSystemProvider system, Suggestion s) {
    final taken = system.suggestionTaken(s);
    return OnoCard(
      key: Key('suggest-${s.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(s.kind), color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(suggestionKinds[s.kind] ?? s.kind, color: AppColors.accent),
                    const SizedBox(height: 6),
                    Text(s.title, style: AppText.heading()),
                    if (s.by.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(s.by, style: AppText.small()),
                    ],
                    const SizedBox(height: 6),
                    Text(s.why, style: AppText.small(color: AppColors.greyLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (taken)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 6, bottom: 4),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Flexible(child: Text('Added', style: AppText.small(color: AppColors.accent))),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    key: Key('suggest-take-${s.id}'),
                    onPressed: () => _take(system, s),
                    child: Text(_action(s.kind)),
                  ),
                  TextButton(
                    key: Key('suggest-off-${s.id}'),
                    onPressed: () => system.dismissSuggestion(s),
                    style: TextButton.styleFrom(foregroundColor: AppColors.grey),
                    child: const Text('Not for me'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _group(PersonalSystemProvider system, SuggestionGroup g, {required bool lead}) {
    final items = [for (final s in g.items) if (_kind == null || s.kind == _kind) s];
    if (items.isEmpty) return const [];
    final all = _expanded.contains(g.area.id);
    final shown = all ? items : items.take(_perArea).toList();
    return [
      SectionHeader(g.area.name),
      if (lead)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
              g.reasons.isEmpty ? 'A good place to start.' : 'Because ${g.reasons.join(', and ')}.',
              style: AppText.small()),
        ),
      for (final s in shown) ...[_card(system, s), const SizedBox(height: 10)],
      if (!all && items.length > _perArea)
        GhostButton('Show ${items.length - _perArea} more',
            icon: Icons.expand_more_rounded,
            onPressed: () => setState(() => _expanded.add(g.area.id))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final groups = system.suggestionGroups();
    final lead = groups.take(_shownAreas).toList();
    final more = groups.skip(_shownAreas).toList();
    return OnoPage(
      showBack: !widget.first,
      eyebrow: 'For you',
      title: widget.first ? 'Here\'s what you get' : 'Ideas for you',
      subtitle:
          'Picked from what you told ONO: your life wheel, your goal, where you\'re heading and this month\'s area. Add what fits in one tap; skip the rest.',
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in [null, ...suggestionKinds.keys])
              ChoiceChip(
                key: Key('suggest-kind-${k ?? 'all'}'),
                label: Text(k == null ? 'All' : suggestionKinds[k]!),
                selected: _kind == k,
                showCheckmark: false,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        for (final g in lead) ..._group(system, g, lead: true),
        if (more.isNotEmpty) ...[
          const SectionHeader('Other parts of life'),
          for (final g in more)
            if (_openAreas.contains(g.area.id))
              ..._group(system, g, lead: false)
            else
              LinkRow(
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.accent,
                title: g.area.name,
                subtitle: g.area.prompt,
                onTap: () => setState(() => _openAreas.add(g.area.id)),
              ),
        ],
        if (system.dismissedSuggestions > 0)
          TextButton(
            key: const Key('suggest-restore'),
            onPressed: system.restoreSuggestions,
            child: Text('Show the ${system.dismissedSuggestions} I set aside'),
          ),
        const SizedBox(height: 12),
        if (widget.first)
          PrimaryButton('Go to Today',
              icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/home')),
        const SizedBox(height: 16),
      ],
    );
  }
}

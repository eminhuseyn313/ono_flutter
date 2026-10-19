import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Every lesson you wrote, in your own words, gathered from practice,
/// reviews, books, goals and hard conversations — a playbook of how you
/// work best. Pin the ones to live by; retire what no longer holds.
class PlaybookScreen extends StatefulWidget {
  const PlaybookScreen({super.key});

  @override
  State<PlaybookScreen> createState() => _PlaybookScreenState();
}

class _PlaybookScreenState extends State<PlaybookScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final q = _search.text.trim().toLowerCase();
    final all = system.playbook();
    final shown = [
      for (final e in all)
        if (q.isEmpty || e.text.toLowerCase().contains(q) || e.from.toLowerCase().contains(q)) e
    ];
    final pinned = shown.where((e) => e.pinned).toList();
    final rest = shown.where((e) => !e.pinned).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Practice · ${all.length} lesson${all.length == 1 ? '' : 's'}',
      title: 'Your playbook',
      subtitle:
          'What you learned, in your own words — from practice, reviews, books, goals and hard conversations. Pin the ones to live by.',
      children: [
        const SizedBox(height: 14),
        if (all.isEmpty)
          const EmptyNote(
              'Lessons you write after a practice rep, an after-action review, a month review or a finished book gather here.',
              icon: Icons.menu_book_outlined)
        else ...[
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                hintText: 'Search your lessons', prefixIcon: Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 8),
          GhostButton('Copy the playbook', icon: Icons.copy_rounded, onPressed: () {
            Clipboard.setData(ClipboardData(text: system.playbookText()));
            toast(context, 'Copied.');
          }),
          if (pinned.isNotEmpty) ...[
            const SectionHeader('To live by'),
            for (final e in pinned) _entry(system, e),
          ],
          if (rest.isNotEmpty) ...[
            SectionHeader(pinned.isEmpty ? 'Lessons' : 'Everything else'),
            for (final e in rest) _entry(system, e),
          ],
          if (shown.isEmpty) const EmptyNote('Nothing matches.', icon: Icons.search_off_rounded),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _entry(PersonalSystemProvider system, PlayEntry e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OnoCard(
          accent: e.pinned ? AppColors.accent : null,
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.text, style: AppText.body(color: AppColors.white)),
                    const SizedBox(height: 4),
                    Text('${e.from} · ${shortDate(e.date)}', style: AppText.small()),
                  ],
                ),
              ),
              IconButton(
                key: Key('pin-${e.key}'),
                tooltip: e.pinned ? 'Unpin' : 'Pin as a rule to live by',
                icon: Icon(e.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 18),
                color: e.pinned ? AppColors.accent : AppColors.faint,
                onPressed: () => system.pinPlay(e.key, !e.pinned),
              ),
              IconButton(
                tooltip: 'No longer true for me',
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.faint,
                onPressed: () {
                  system.retirePlay(e.key, true);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: const Text('Taken out of the playbook.'),
                      action: SnackBarAction(
                          label: 'Undo', onPressed: () => system.retirePlay(e.key, false)),
                    ));
                },
              ),
            ],
          ),
        ),
      );
}

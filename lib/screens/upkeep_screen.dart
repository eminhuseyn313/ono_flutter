import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Recurring checkups you set yourself, and when each is next due.
class UpkeepScreen extends StatefulWidget {
  const UpkeepScreen({super.key});

  @override
  State<UpkeepScreen> createState() => _UpkeepScreenState();
}

class _UpkeepScreenState extends State<UpkeepScreen> {
  final _name = TextEditingController();
  int _every = 365;

  static const _intervals = [(90, '3 months'), (180, '6 months'), (365, 'Yearly'), (730, 'Every 2 years')];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _due(PersonalSystemProvider system, LogEntry u) {
    final next = system.upkeepNextDue(u);
    if (next == null) return 'Not done yet';
    final days = next.difference(dayOnly(DateTime.now())).inDays;
    if (days < 0) return 'Overdue by ${-days} d';
    if (days == 0) return 'Due today';
    return days < 60 ? 'Due in $days d' : 'Next ${shortDate(next)}';
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final items = system.upkeep;
    final missing = [
      for (final s in PersonalSystemProvider.upkeepSuggestions)
        if (!items.any((u) => u.text == s.$1)) s
    ];
    return OnoPage(
      showBack: true,
      eyebrow: 'Health upkeep',
      title: 'Look after the basics',
      subtitle:
          'The checkups that slip when life is busy. You choose how often — with your doctor; ONO only remembers the dates.',
      children: [
        const SizedBox(height: 14),
        if (items.isNotEmpty)
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Column(
              children: [
                for (final u in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.text, style: AppText.heading()),
                              Text(_due(system, u),
                                  style: AppText.small(
                                      color: system.upkeepDue.contains(u)
                                          ? AppColors.warning
                                          : AppColors.grey)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            system.markUpkeepDone(u.id);
                            toast(context, 'Done. Next one is remembered.');
                          },
                          child: const Text('Done'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.faint,
                          onPressed: () => system.removeUpkeep(u.id),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (missing.isNotEmpty) ...[
          const SectionHeader('Common ones'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in missing)
                ActionChip(
                  label: Text(s.$1),
                  onPressed: () => system.addUpkeep(s.$1, s.$2),
                ),
            ],
          ),
        ],
        const SectionHeader('Your own'),
        TextField(
          controller: _name,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'e.g. Skin check, physio review, flu jab'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in _intervals)
              ChoiceChip(
                label: Text(i.$2),
                selected: _every == i.$1,
                onSelected: (_) => setState(() => _every = i.$1),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GhostButton('Add', icon: Icons.add_rounded, onPressed: () {
          if (system.addUpkeep(_name.text, _every) != null) {
            _name.clear();
            FocusManager.instance.primaryFocus?.unfocus();
          }
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

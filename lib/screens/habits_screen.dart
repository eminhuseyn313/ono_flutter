import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

/// Monthly automaticity check: "I do it without having to think", per
/// Daily 10 item. An item counts as automatic when it is rated 4+ *and* was
/// done on 80% of the last 30 days; it then moves to a quiet group on Today
/// and its reminder switches off.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late Map<String, int> _ratings;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _ratings = Map.of(
        context.read<PersonalSystemProvider>().automaticityRatings);
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = dayOnly(timeNow());
    final days = [
      for (var i = 1; i <= 30; i++) today.minusDays(i)
    ].where((d) => !d.isBefore(system.programStart)).toList();
    final rates = system.itemRates(days);
    return OnoPage(
      showBack: true,
      eyebrow: 'Monthly · 1 minute',
      title: 'Is it a habit yet?',
      subtitle:
          'Rate each: "I do it without having to think." Habits take a median of 66 days — some far longer. Automatic ones go quiet.',
      bottomBar: PrimaryButton('Save check',
          icon: Icons.check_rounded,
          onPressed: _ratings.length < system.dailyCount
              ? null
              : () {
                  system.saveAutomaticity(_ratings);
                  HapticFeedback.mediumImpact();
                  final n = system.automaticItems.length;
                  toast(
                      context,
                      n == 0
                          ? 'Saved. Nothing automatic yet — keep the cues.'
                          : '$n automatic — their reminders are now off.');
                  context.canPop() ? context.pop() : context.go('/profile');
                }),
      children: [
        for (final n in system.dailyItems)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OnoCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LaneDot(n.lane),
                      const SizedBox(width: 8),
                      Expanded(child: Text(n.title, style: AppText.heading())),
                      if (system.isAutomatic(n.id))
                        const Tag('Automatic', color: AppColors.body),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      days.isEmpty
                          ? 'No history yet'
                          : 'Done ${((rates[n.id] ?? 0) * 100).round()}% of the last ${days.length} days',
                      style: AppText.small().copyWith(fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var v = 1; v <= 5; v++)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _ratings[n.id] = v);
                              },
                              child: Container(
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _ratings[n.id] == v
                                      ? AppColors.accent
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$v',
                                    style: AppText.small(
                                            color: _ratings[n.id] == v
                                                ? AppColors.ink
                                                : AppColors.grey)
                                        .copyWith(
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Effortful',
                          style: AppText.small().copyWith(fontSize: 11)),
                      const Spacer(),
                      Text('Automatic',
                          style: AppText.small().copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

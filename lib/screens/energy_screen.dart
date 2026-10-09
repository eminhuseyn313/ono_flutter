import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// When you are sharpest, from your own ratings: quick energy check-ins
/// and how sharp each focus block felt. The hardest work goes there.
class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final map = system.energyMap;
    final peak = system.energyPeak;
    final weekdays = system.energyByWeekday;
    final total = map.values.fold<int>(0, (s, b) => s + b.n);
    return OnoPage(
      showBack: true,
      eyebrow: 'Energy map',
      title: 'When you are sharpest',
      subtitle:
          'Rate your energy a few times a day for two weeks, and how sharp each focus block felt. Then give your best hours to your hardest work.',
      children: [
        const SizedBox(height: 14),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  peak == null
                      ? 'No clear peak yet'
                      : 'Your peak: ${peak.label.toLowerCase()}, ${peak.from}:00–${peak.to}:00',
                  style: AppText.heading()),
              const SizedBox(height: 4),
              Text(
                  peak == null
                      ? '$total ratings so far. A band needs ${PersonalSystemProvider.minEnergySamples} before it counts, and two bands must differ.'
                      : 'Protect it: your hardest thinking goes here, meetings and admin go elsewhere. A pattern from your ratings, not a law.',
                  style: AppText.small()),
            ],
          ),
        ),
        const SectionHeader('Energy right now'),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () {
                      system.logEnergy(i);
                      toast(context, 'Saved for ${DateTime.now().hour}:00.');
                    },
                    child: Text('$i'),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('1 = drained · 5 = sharp', style: AppText.small()),
        ),
        const SectionHeader('By time of day · last 60 days'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              for (final b in PersonalSystemProvider.energyBands)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        child: Text(b.label,
                            style: AppText.small(
                                color: peak?.id == b.id ? AppColors.accent : AppColors.white)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: (map[b.id]!.avg ?? 0) / 5,
                            backgroundColor: AppColors.cardLight,
                            color: peak?.id == b.id
                                ? AppColors.accent
                                : AppColors.mind.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        child: Text(
                            map[b.id]!.avg == null
                                ? '—'
                                : '${map[b.id]!.avg!.toStringAsFixed(1)} · ${map[b.id]!.n}',
                            textAlign: TextAlign.right,
                            style: AppText.small()),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (weekdays.isNotEmpty) ...[
          const SectionHeader('Morning energy by weekday'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                if (weekdays[d] != null)
                  Chip(label: Text('${_days[d - 1]} ${weekdays[d]!.toStringAsFixed(1)}')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('From your morning check-ins.', style: AppText.small()),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

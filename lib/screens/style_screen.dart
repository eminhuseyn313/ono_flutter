import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class StyleScreen extends StatelessWidget {
  const StyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final bought =
        wardrobe.where((w) => system.isDone('wardrobe:${w.id}')).toList();
    final spent = bought.fold<int>(0, (s, w) => s + w.maxPrice);
    final budget = wardrobe.fold<int>(0, (s, w) => s + w.maxPrice);
    final month = system.programMonth;

    return OnoPage(
      showBack: true,
      eyebrow: 'Playbook',
      title: 'Style system',
      subtitle:
          'Quiet, dark, precise. "Does this person belong in every room today?"',
      children: [
        // Each part shows only when the plan has it.
        if (outfits.isEmpty &&
            watchRule.isEmpty &&
            wardrobe.isEmpty &&
            faceNotes.isEmpty &&
            beardSpec.isEmpty &&
            groomingRoutine.isEmpty &&
            skincarePlan.isEmpty) ...[
          const SizedBox(height: 12),
          Text('Your plan has no style section yet. A full plan can add outfit formulas, a wardrobe to build and a grooming routine.',
              style: AppText.body()),
        ],
        if (outfits.isNotEmpty) const SectionHeader('Outfit formulas'),
        for (final o in outfits)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconTile(o.icon, color: AppColors.social, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.occasion, style: AppText.heading()),
                        const SizedBox(height: 2),
                        Text(o.formula, style: AppText.small()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (watchRule.isNotEmpty) ...[
          const SectionHeader('Watch rule'),
          OnoCard(
            child: Column(
              children: [
                for (final w in watchRule) KeyValueRow(w[0], w[1], labelWidth: 80)
              ],
            ),
          ),
        ],
        if (wardrobe.isNotEmpty) ...[
          const SectionHeader('Capsule wardrobe — buy order'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('${bought.length} of ${wardrobe.length} bought',
                          style: AppText.heading()),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('$spent of $budget planned',
                          textAlign: TextAlign.end, style: AppText.small()),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ThinBar(
                    value: bought.length / wardrobe.length,
                    color: AppColors.social),
                const SizedBox(height: 6),
                for (final w in wardrobe)
                  CheckRow(
                    checked: system.isDone('wardrobe:${w.id}'),
                    title: w.item,
                    subtitle:
                        '${w.week} · ${w.minPrice == w.maxPrice ? '${w.minPrice}' : '${w.minPrice}–${w.maxPrice}'} · ${w.where}',
                    onChanged: (_) => system.toggleDone('wardrobe:${w.id}'),
                  ),
              ],
            ),
          ),
        ],
        if (faceNotes.isNotEmpty) ...[
          const SectionHeader('What works for you'),
          OnoCard(
            child: Column(
              children: [
                for (final f in faceNotes) KeyValueRow(f[0], f[1]),
              ],
            ),
          ),
        ],
        if (beardSpec.isNotEmpty) ...[
          const SectionHeader('Beard — exact shape'),
          OnoCard(
            child: Column(
              children: [
                for (final b in beardSpec) KeyValueRow(b[0], b[1], labelWidth: 84),
              ],
            ),
          ),
        ],
        if (groomingRoutine.isNotEmpty) ...[
          const SectionHeader('Grooming'),
          OnoCard(
            child: Column(
              children: [
                for (final g in groomingRoutine)
                  KeyValueRow(g[0], g[1], labelWidth: 120),
              ],
            ),
          ),
        ],
        if (skincarePlan.isNotEmpty) ...[
          const SectionHeader('Skincare build'),
          OnoCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < skincarePlan.length; i++)
                  _StepRow(
                    label: skincarePlan[i][0],
                    text: skincarePlan[i][1],
                    active: i == 0
                        ? month <= 2
                        : i == 1
                            ? month == 3
                            : month >= 4,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final String text;
  final bool active;

  const _StepRow(
      {required this.label, required this.text, required this.active});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.accent : AppColors.divider,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 84,
              child: Text(label,
                  style: AppText.small(
                          color: active ? AppColors.accent : AppColors.grey)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(child: Text(text, style: AppText.body())),
          ],
        ),
      );
}

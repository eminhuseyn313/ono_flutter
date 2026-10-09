import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The case for the target role, assembled from what has been practised,
/// heard and shipped — honest about the gaps.
class CaseScreen extends StatelessWidget {
  const CaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Career · ${activeProfile.targetRole}',
      title: 'Your case',
      subtitle:
          'Built from your reps, feedback, artifacts and wins. Read it before a career conversation; copy it to prepare one.',
      children: [
        for (final a in growthAreas.where((a) => !a.personal)) _area(system, a),
        const SizedBox(height: 14),
        GhostButton('Copy the whole case',
            icon: Icons.copy_rounded,
            onPressed: () => copyText(context, system.caseText())),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _area(PersonalSystemProvider system, GrowthArea a) {
    final c = system.caseFor(a.id);
    final atBar = (c.rating ?? 0) >= readinessBar;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        accent: c.rating == null
            ? null
            : atBar
                ? AppColors.body
                : AppColors.warning,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(a.name, style: AppText.heading())),
                Text(c.rating == null ? 'not rated' : '${c.rating}/5',
                    style: AppText.small(
                        color: c.rating == null
                            ? AppColors.faint
                            : atBar
                                ? AppColors.body
                                : AppColors.warning)),
              ],
            ),
            Text(a.bar, style: AppText.small()),
            const SizedBox(height: 6),
            if (c.reps.isEmpty && c.feedback.isEmpty)
              Text('Nothing logged yet — practise it in a growth month.',
                  style: AppText.small(color: AppColors.faint))
            else ...[
              for (final r in c.reps.take(2))
                Text('• ${(r.str('lesson') ?? '').isNotEmpty ? r.str('lesson') : r.text}',
                    style: AppText.small(color: AppColors.greyLight)),
              for (final f in c.feedback.take(1))
                Text('• ${f.str('from')}: "${f.text}"',
                    style: AppText.small(color: AppColors.greyLight)),
              Text('${c.reps.length} reps · ${c.feedback.length} feedback',
                  style: AppText.small(color: AppColors.faint)),
            ],
          ],
        ),
      ),
    );
  }
}

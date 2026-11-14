import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// A full plan someone prepared — a coach, a programme, or your own saved
/// copy — loaded into your data. It adds a schedule, training plan, daily
/// items, growth areas, reading and more; what you logged stays as it is.
class PlanFileScreen extends StatefulWidget {
  const PlanFileScreen({super.key});

  @override
  State<PlanFileScreen> createState() => _PlanFileScreenState();
}

class _PlanFileScreenState extends State<PlanFileScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final loaded = system.hasPersonalPlan;
    final p = plan;
    return OnoPage(
      showBack: true,
      eyebrow: 'Your plan',
      title: loaded ? 'A full plan is loaded' : 'Load a full plan',
      subtitle: loaded
          ? 'Made for ${p.profile?.name ?? 'you'}. It lives in your data, syncs to your devices and travels with your backups.'
          : 'If someone prepared a plan for you, or you saved your own, paste it here. It adds to what you set up; nothing you logged changes.',
      children: [
        if (loaded) ...[
          const SizedBox(height: 10),
          OnoCard(
            child: Text(
                [
                  '${p.dailyItems.length} daily items',
                  if (p.schedule.isNotEmpty) 'a day in ${p.schedule.length} blocks',
                  if (p.gym.isNotEmpty) '${p.gym.length} training days',
                  if (p.growthAreas.isNotEmpty) '${p.growthAreas.length} growth areas',
                  if (p.books.isNotEmpty) '${p.books.length + p.novels.length} books',
                  if (p.reminders.isNotEmpty) '${p.reminders.length} reminders',
                ].join(' · '),
                key: const Key('plan-summary'),
                style: AppText.body(color: AppColors.white)),
          ),
          const SizedBox(height: 12),
          GhostButton('Copy my plan', icon: Icons.copy_rounded, onPressed: () {
            final t = system.planText();
            if (t == null) return;
            Clipboard.setData(ClipboardData(text: t));
            toast(context, 'Copied. Keep it somewhere safe; paste it here to load it again.');
          }),
          const SizedBox(height: 8),
          GhostButton('Remove the plan', icon: Icons.remove_circle_outline_rounded,
              onPressed: () async {
            final sure = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remove the plan?'),
                content: const Text(
                    'ONO goes back to what you set up yourself. Everything you logged stays. Copy the plan first if you may want it back.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep it')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
                ],
              ),
            );
            if (sure == true) {
              system.setPersonalPlan(null);
              if (context.mounted) toast(context, 'Removed.');
            }
          }),
          const SectionHeader('Replace it'),
        ] else
          const SizedBox(height: 10),
        TextField(
          key: const Key('plan-paste'),
          controller: _text,
          minLines: 4,
          maxLines: 8,
          style: AppText.small(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Paste the plan here (it starts with {)'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PrimaryButton(loaded ? 'Load this one instead' : 'Load the plan',
            icon: Icons.download_done_rounded,
            onPressed: _text.text.trim().isEmpty
                ? null
                : () {
                    final ok = system.importPlanText(_text.text.trim());
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (!ok) {
                      toast(context, 'That isn\'t a plan ONO can read. Paste the whole file, from { to }.');
                      return;
                    }
                    _text.clear();
                    toast(context, 'Loaded. Today and Program now follow it.');
                  }),
        const SizedBox(height: 16),
      ],
    );
  }
}

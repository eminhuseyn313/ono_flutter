import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/plan_packs.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Plans to start from, and a way to pass yours on. A pack carries areas,
/// a goal shape, daily items with cues and things to stop — never names,
/// logs or numbers.
class PacksScreen extends StatelessWidget {
  const PacksScreen({super.key});

  Future<void> _preview(BuildContext context, PlanPack pack) async {
    final system = context.read<PersonalSystemProvider>();
    var replace = false;
    var withGoal = pack.goal != null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(pack.name, style: AppText.title()),
              if (pack.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(pack.summary, style: AppText.small()),
              ],
              if (pack.areas.isNotEmpty) ...[
                const SectionHeader('Growth areas'),
                for (final a in pack.areas)
                  Text('• ${a.name} · ${a.drills.length} drills',
                      style: AppText.body(color: AppColors.white)),
              ],
              if (pack.goal != null) ...[
                const SectionHeader('Goal'),
                Text(pack.goal!.title, style: AppText.heading()),
                if (pack.goal!.plan.isNotEmpty)
                  Text(pack.goal!.plan, style: AppText.small()),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: withGoal,
                  onChanged: (v) => setState(() => withGoal = v),
                  title: Text('Add this goal', style: AppText.body(color: AppColors.white)),
                ),
              ],
              if (pack.daily.isNotEmpty) ...[
                const SectionHeader('Every day'),
                for (final d in pack.daily)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title, style: AppText.body(color: AppColors.white)),
                        if (d.cue.isNotEmpty) Text(d.cue, style: AppText.small()),
                      ],
                    ),
                  ),
                if (pack.daily.length >= PersonalSystemProvider.minDailyItems)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: replace,
                    onChanged: (v) => setState(() => replace = v),
                    title: Text('Replace my daily list',
                        style: AppText.body(color: AppColors.white)),
                    subtitle: Text(
                        replace
                            ? 'Your current items are retired; you can bring them back.'
                            : 'Added to your ${system.dailyCount} current items.',
                        style: AppText.small()),
                  ),
              ],
              if (pack.stops.isNotEmpty) ...[
                const SectionHeader('Stop doing'),
                for (final s in pack.stops)
                  Text('• $s', style: AppText.body(color: AppColors.white)),
              ],
              const SizedBox(height: 18),
              PrimaryButton('Use this plan', icon: Icons.check_rounded, onPressed: () {
                final r = system.applyPack(pack, replaceDaily: replace, withGoal: withGoal);
                Navigator.of(ctx).pop();
                toast(context,
                    'Added ${r.areas} area${r.areas == 1 ? '' : 's'}, ${r.items} daily item${r.items == 1 ? '' : 's'}${r.goal ? ' and the goal' : ''}.');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _paste(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (!context.mounted) return;
    final pack = PlanPack.fromText(data?.text ?? '');
    if (pack == null) {
      toast(context, 'No plan found. Copy the whole message someone sent you, then try again.');
      return;
    }
    await _preview(context, pack);
  }

  Future<void> _share(BuildContext context, PersonalSystemProvider system) async {
    final pack = system.myPack();
    await Clipboard.setData(ClipboardData(text: pack.toText()));
    if (context.mounted) {
      toast(context,
          'Copied: ${pack.areas.length} areas, ${pack.daily.length} daily items${pack.goal == null ? '' : ', your goal'}. No names, logs or numbers.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Plan packs',
      title: 'Start from a plan',
      subtitle:
          'Ready-made plans to add to yours, or one a friend shared. Everything stays editable.',
      children: [
        const SizedBox(height: 14),
        for (final p in planPacks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              onTap: () => _preview(context, p),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppText.heading()),
                  Text(p.forWho, style: AppText.small()),
                ],
              ),
            ),
          ),
        const SectionHeader('Share'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.content_paste_rounded,
                color: AppColors.accent,
                title: 'Use a plan someone sent you',
                subtitle: 'Copy their message, then tap here',
                onTap: () => _paste(context),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.ios_share_rounded,
                color: AppColors.accent,
                title: 'Copy my plan to share',
                subtitle: 'Your own areas, daily items, goal and stops — nothing personal',
                onTap: () => _share(context, system),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// PLAYBOOK — everything that defines who you are becoming: manifesto,
/// protocols, evidence, library, style, career. Reference, not tasks.
class PlaybookScreen extends StatefulWidget {
  const PlaybookScreen({super.key});

  @override
  State<PlaybookScreen> createState() => _PlaybookScreenState();
}

class _PlaybookScreenState extends State<PlaybookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonalSystemProvider>().load(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final month = system.programMonth;
    final milestoneKeys = [
      for (final m in careerMilestones)
        for (var i = 0; i < m.targets.length; i++) m.targetId(i)
    ];
    final wardrobeKeys = wardrobe.map((w) => 'wardrobe:${w.id}');

    return OnoPage(
      eyebrow: 'Playbook',
      title: EminIdentity.archetype,
      subtitle: EminIdentity.tagline,
      children: [
        const SizedBox(height: 20),
        _ManifestoHero(onTap: () => context.push('/manifesto')),
        const SizedBox(height: 12),
        _PathCard(month: month),
        const SectionHeader('Operate'),
        _EntryTile(
          icon: Icons.bolt_rounded,
          color: AppColors.mind,
          title: 'Protocols',
          subtitle: 'Sigh · "I am excited" · BLUF · Six deep · Feynman · Pause',
          trailing: '${protocols.length}',
          route: '/protocols',
        ),
        _EntryTile(
          icon: Icons.inventory_2_outlined,
          color: AppColors.steel,
          title: 'Evidence Archive',
          subtitle: 'Add Sunday. Read Monday. Proof against the impostor.',
          trailing: '${system.evidenceCount}',
          route: '/evidence',
        ),
        _EntryTile(
          icon: Icons.assignment_outlined,
          color: AppColors.accent,
          title: 'Sunday report',
          subtitle: 'Five answers → next week\'s plan.',
          trailing: '${system.reports.length}',
          route: '/weekly-coaching',
        ),
        const SectionHeader('Become'),
        _EntryTile(
          icon: Icons.menu_book_rounded,
          color: AppColors.mind,
          title: 'Library',
          subtitle:
              'Now: ${currentBook(month).title} · films · podcasts · sources',
          route: '/library',
        ),
        _EntryTile(
          icon: Icons.checkroom_rounded,
          color: AppColors.social,
          title: 'Style system',
          subtitle: 'Outfits · beard · grooming · capsule wardrobe',
          trailing:
              '${system.doneCount(wardrobeKeys)}/${wardrobe.length}',
          route: '/style',
        ),
        _EntryTile(
          icon: Icons.trending_up_rounded,
          color: AppColors.skill,
          title: 'Career & signal',
          subtitle: 'Thesis · LinkedIn · certificates · 18-month milestones',
          trailing:
              '${system.doneCount(milestoneKeys)}/${milestoneKeys.length}',
          route: '/career',
        ),
        const SectionHeader('The four lanes'),
        for (final lane in laneFocus) _LaneCard(lane: lane),
        const SectionHeader('More'),
        const _EntryTile(
          icon: Icons.edit_note_rounded,
          color: AppColors.grey,
          title: 'Journal',
          subtitle: 'Feynman writes, Pennebaker sessions, Sunday synthesis',
          route: '/journal',
        ),
        const _EntryTile(
          icon: Icons.insights_rounded,
          color: AppColors.grey,
          title: 'Progress',
          subtitle: 'Lane scores and history',
          route: '/progress',
        ),
        const _EntryTile(
          icon: Icons.grid_view_rounded,
          color: AppColors.grey,
          title: 'All features',
          subtitle: 'Every screen in the app',
          route: '/features',
        ),
      ],
    );
  }
}

class _ManifestoHero extends StatelessWidget {
  final VoidCallback onTap;
  const _ManifestoHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OnoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      color: AppColors.cardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANIFESTO', style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 14),
          Text(
            'I do not need to know everything to be competent.',
            style: AppText.title().copyWith(fontSize: 22, height: 1.3),
          ),
          const SizedBox(height: 10),
          Text(
            'I speak from position, not permission.',
            style: AppText.body(color: AppColors.greyLight),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Read in full',
                  style: AppText.small(color: AppColors.accent)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final int month;
  const _PathCard({required this.month});

  @override
  Widget build(BuildContext context) {
    return OnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE PATH', style: AppText.eyebrow()),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < EminIdentity.path.length; i++) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? AppColors.accent
                              : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        EminIdentity.path[i],
                        style: AppText.small(
                          color: i == 0 ? AppColors.white : AppColors.grey,
                        ).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                if (i < EminIdentity.path.length - 1)
                  const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ThinBar(value: (month / 18).clamp(0, 1)),
          const SizedBox(height: 8),
          Text('Month $month of 18 · career decision from strength',
              style: AppText.small()),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;
  final String route;

  const _EntryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push(route),
        child: Row(
          children: [
            IconTile(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading()),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppText.small(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(trailing!,
                  style: AppText.small(color: AppColors.greyLight)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}

class _LaneCard extends StatefulWidget {
  final LaneFocus lane;
  const _LaneCard({required this.lane});

  @override
  State<_LaneCard> createState() => _LaneCardState();
}

class _LaneCardState extends State<_LaneCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final lane = widget.lane;
    final color = AppColors.lane(lane.lane);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        accent: color,
        onTap: () => setState(() => _open = !_open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(lane.name, style: AppText.heading()),
                const Spacer(),
                Text('${lane.actions.length} daily actions',
                    style: AppText.small()),
                Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.grey),
              ],
            ),
            const SizedBox(height: 6),
            Text(lane.problem, style: AppText.small()),
            if (_open) ...[
              const SizedBox(height: 12),
              for (final a in lane.actions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: LaneDot(lane.lane, size: 5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a, style: AppText.body())),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final month = system.programMonth;

    return OnoPage(
      showBack: true,
      eyebrow: 'Playbook',
      title: 'Career & signal',
      subtitle:
          '${activeProfile.roleLine}\n${activeProfile.organisation} · ${activeProfile.location}',
      children: [
        const SectionHeader('Your thesis'),
        OnoCard(
          color: AppColors.cardLight,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"$domainThesis"',
                  style: AppText.title().copyWith(
                      fontSize: 19, height: 1.4, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => copyText(context, domainThesis),
                child: Text('Copy',
                    style: AppText.small(color: AppColors.accent)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SectionHeader('Key data to own'),
        OnoCard(
          child: Column(
            children: [
              for (final d in keyData) KeyValueRow(d[0], d[1], labelWidth: 96),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.work_outline_rounded,
            color: AppColors.accent,
            title: 'Career cockpit',
            subtitle: system.readinessGap == null
                ? '1:1s, decision journal, readiness'
                : 'Gap: ${system.readinessGap!.name}',
            onTap: () => context.push('/cockpit'),
          ),
        ),
        const SizedBox(height: 12),
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.assignment_ind_outlined,
            color: AppColors.skill,
            title: 'Your ${activeProfile.targetRole} case',
            subtitle: 'Reps, feedback, artifacts and wins per dimension',
            onTap: () => context.push('/case'),
          ),
        ),
        const SectionHeader('LinkedIn — exact rewrites'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.campaign_outlined,
                color: AppColors.skill,
                title: 'Post log',
                subtitle: system.programMonth >= 2
                    ? '2 posts a week — log each one'
                    : 'Cadence starts in month 2',
                trailing: '${system.countOf('linkedin')}',
                onTap: () => context.push('/tool/linkedin'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.description_outlined,
                color: AppColors.skill,
                title: 'Artifact of the month',
                subtitle: artifactFor(system.programMonth),
                trailing: '${system.countOf('artifact')}',
                onTap: () => context.push('/tool/artifact'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _CopyBlock(
          title: 'Headline',
          text: linkedinHeadline,
          doneKey: 'li:headline',
          doneLabel: 'Headline live',
        ),
        const _CopyBlock(
          title: 'About',
          text: linkedinAbout,
          doneKey: 'li:about',
          doneLabel: 'About section live',
          collapsed: true,
        ),
        const _CopyBlock(
          title: 'Current role',
          text: linkedinRole,
          doneKey: 'li:role',
          doneLabel: 'Role description live',
          collapsed: true,
        ),
        const _CopyBlock(
          title: 'First post — publish this week',
          text: linkedinFirstPost,
          doneKey: 'li:post1',
          doneLabel: 'Published',
          collapsed: true,
        ),
        const SectionHeader('18-month milestones'),
        for (final m in careerMilestones)
          _MilestoneCard(milestone: m, currentMonth: month),
        const SectionHeader('Certificates — priority order'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            children: [
              for (var i = 0; i < certificates.length; i++) ...[
                _CertRow(cert: certificates[i]),
                if (i < certificates.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyBlock extends StatefulWidget {
  final String title;
  final String text;
  final String doneKey;
  final String doneLabel;
  final bool collapsed;

  const _CopyBlock({
    required this.title,
    required this.text,
    required this.doneKey,
    required this.doneLabel,
    this.collapsed = false,
  });

  @override
  State<_CopyBlock> createState() => _CopyBlockState();
}

class _CopyBlockState extends State<_CopyBlock> {
  late bool _open = !widget.collapsed;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final done = system.isDone(widget.doneKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        accent: done ? AppColors.body : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  Expanded(
                      child: Text(widget.title, style: AppText.heading())),
                  if (done) const Tag('Live', color: AppColors.body),
                  Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.grey),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.text,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: AppText.body(color: AppColors.greyLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => copyText(context, widget.text,
                      message: '${widget.title} copied'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10)),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => system.toggleDone(widget.doneKey),
                  child: Text(done ? 'Undo' : 'Mark: ${widget.doneLabel}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final CareerMilestone milestone;
  final int currentMonth;

  const _MilestoneCard({required this.milestone, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final ids = [
      for (var i = 0; i < milestone.targets.length; i++) milestone.targetId(i)
    ];
    final done = system.doneCount(ids);
    final isCurrent = currentMonth <= milestone.month &&
        careerMilestones
            .where((m) => m.month >= currentMonth)
            .first
            .month ==
            milestone.month;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnoCard(
        highlight: isCurrent,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('MONTH ${milestone.month}',
                    style: AppText.eyebrow(
                        color:
                            isCurrent ? AppColors.accent : AppColors.grey)),
                const SizedBox(width: 8),
                if (isCurrent) const Tag('NOW', color: AppColors.accent),
                const Spacer(),
                Text('$done/${ids.length}',
                    style: AppText.small(
                            color: done == ids.length
                                ? AppColors.body
                                : AppColors.grey)
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < milestone.targets.length; i++)
              CheckRow(
                checked: system.isDone(ids[i]),
                title: milestone.targets[i],
                padding: const EdgeInsets.symmetric(vertical: 8),
                onChanged: (_) => system.toggleDone(ids[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final Certificate cert;
  const _CertRow({required this.cert});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final done = system.isDone('cert:${cert.id}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.accent : AppColors.cardLight,
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.ink)
                : Text('${cert.priority}',
                    style: AppText.small(color: AppColors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: () => system.toggleDone('cert:${cert.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cert.name, style: AppText.heading()),
                  Text('${cert.org} · ${cert.timing}',
                      style: AppText.small()),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open',
            onPressed: () => openLink(cert.url),
            icon: const Icon(Icons.north_east_rounded,
                size: 18, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

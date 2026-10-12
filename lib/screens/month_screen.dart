import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// One month of the 18: what it unlocks, its milestones, and — once it has
/// begun — an honest review against the month before.
class MonthScreen extends StatefulWidget {
  final int month;
  const MonthScreen({super.key, required this.month});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  final _carry = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _carry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final m = widget.month.clamp(1, system.programMonths);
    final phase = system.phaseOfMonth(m);
    final started = system.hasStarted && m <= system.programMonth;
    final stats = system.statsForMonth(m);
    final prev = m > 1 ? system.statsForMonth(m - 1) : null;
    final review = system
        .logsOf('month_review')
        .where((l) => system.atMonth(l, m))
        .firstOrNull;
    if (!_loaded && review != null) {
      _carry.text = review.text;
      _loaded = true;
    }
    final milestone = careerMilestones.where((c) => c.month == m).firstOrNull;
    final start = system.monthStart(m);
    final end = system.monthStart(m + 1).subtract(const Duration(days: 1));
    final artifacts = system
        .logsOf('artifact')
        .where((a) => system.atMonth(a, m))
        .toList();

    return OnoPage(
      showBack: true,
      eyebrow: '${phase.name} · ${shortDate(start)} – ${shortDate(end)}',
      title: 'Month $m',
      subtitle: monthThemes[m],
      children: [
        if (!started) ...[
          const SizedBox(height: 16),
          OnoCard(
            color: AppColors.navy,
            child: Row(
              children: [
                const Icon(Icons.lock_clock_outlined,
                    color: AppColors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Opens ${shortDate(start)}. Everything below unlocks then — no need to think about it yet.',
                      style: AppText.body()),
                ),
              ],
            ),
          ),
        ],
        const SectionHeader('Unlocks'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              for (final u in unlocksFor(m))
                u.doneKey == null
                    ? LinkRowLite(
                        title: u.title,
                        subtitle: u.detail,
                        onTap: u.route == null
                            ? null
                            : () => context.push(u.route!))
                    : CheckRow(
                        checked: system.isDone(u.doneKey!),
                        title: u.title,
                        subtitle: u.detail,
                        onChanged: (_) => system.toggleDone(u.doneKey!),
                        onOpen: u.route == null
                            ? null
                            : () => context.push(u.route!),
                      ),
            ],
          ),
        ),
        if (milestone != null) ...[
          const SectionHeader('Milestones'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                for (var i = 0; i < milestone.targets.length; i++)
                  CheckRow(
                    checked: system.isDone(milestone.targetId(i)),
                    title: milestone.targets[i],
                    onChanged: (_) =>
                        system.toggleDone(milestone.targetId(i)),
                  ),
              ],
            ),
          ),
        ],
        SectionHeader('Artifact', action: 'Log progress',
            onAction: () => context.push('/tool/artifact?month=$m')),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(artifactFor(m), style: AppText.heading()),
              const SizedBox(height: 6),
              if (artifacts.isEmpty)
                Text('Nothing logged yet.', style: AppText.small())
              else
                for (final a in artifacts)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Tag(a.str('status') ?? 'draft',
                            color: a.str('status') == 'shipped'
                                ? AppColors.body
                                : AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(a.str('title') ?? a.text,
                                style: AppText.small(
                                    color: AppColors.greyLight))),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        if (started) ...[
          const SectionHeader('Review'),
          OnoCard(
            child: Column(
              children: [
                _cmp('Daily 10 average', stats.daily10Average,
                    prev?.daily10Average, digits: 1),
                _cmp('Days held (7+/10)', stats.daysHeld.toDouble(),
                    prev?.daysHeld.toDouble()),
                _cmp('Gym sessions', stats.gymSessions.toDouble(),
                    prev?.gymSessions.toDouble()),
                _cmp('Protocol uses', stats.protocolUses.toDouble(),
                    prev?.protocolUses.toDouble()),
                _cmp('Notes written', stats.notes.toDouble(),
                    prev?.notes.toDouble()),
                _cmp('Evidence added', stats.evidenceAdded.toDouble(),
                    prev?.evidenceAdded.toDouble()),
                _cmp('LinkedIn posts', stats.posts.toDouble(),
                    prev?.posts.toDouble()),
                if (stats.weightEnd != null)
                  _cmp('Weight (end)', stats.weightEnd!, prev?.weightEnd,
                      digits: 1, lowerIsBetter: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
              '${stats.daysElapsed} of 30 days elapsed${prev == null ? '' : ' · compared with month ${m - 1}'}.',
              style: AppText.small()),
          const SectionHeader('Carry into next month'),
          TextField(
            controller: _carry,
            minLines: 3,
            maxLines: 6,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                hintText:
                    'One rule you\'re keeping, one you\'re changing, one thing to start.'),
          ),
          const SizedBox(height: 12),
          PrimaryButton('Save review', onPressed: () {
            if (review != null) {
              system.updateLog(review.copyWith(text: _carry.text.trim()));
            } else {
              system.addLog('month_review',
                  text: _carry.text.trim(), data: {'month': m});
            }
            toast(context, 'Month $m review saved');
          }),
        ],
      ],
    );
  }

  Widget _cmp(String label, double value, double? prev,
      {int digits = 0, bool lowerIsBetter = false}) {
    final delta = prev == null ? null : value - prev;
    final good = delta == null
        ? null
        : (lowerIsBetter ? delta < 0 : delta > 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body())),
          Text(value.toStringAsFixed(digits),
              style: AppText.number(size: 17)),
          SizedBox(
            width: 64,
            child: Text(
              delta == null || delta == 0
                  ? ''
                  : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(digits)}',
              textAlign: TextAlign.right,
              style: AppText.small(
                  color: good == true ? AppColors.body : AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain tappable row used where no tick applies.
class LinkRowLite extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const LinkRowLite(
      {super.key, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.arrow_outward_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.body(color: AppColors.white)
                            .copyWith(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

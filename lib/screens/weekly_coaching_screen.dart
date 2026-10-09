import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Sunday report → weekly brief. The two numbers fill themselves; three
/// answers are written; the brief comes back with next week's tasks, a
/// domain brief, coaching on the situation and plan adjustments.
class WeeklyCoachingScreen extends StatefulWidget {
  const WeeklyCoachingScreen({super.key});

  @override
  State<WeeklyCoachingScreen> createState() => _WeeklyCoachingScreenState();
}

class _WeeklyCoachingScreenState extends State<WeeklyCoachingScreen> {
  final _best = TextEditingController();
  final _hardest = TextEditingController();
  final _situation = TextEditingController();
  bool _initialised = false;
  bool _editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final r =
        context.read<PersonalSystemProvider>().reportForWeek(DateTime.now());
    if (r != null) {
      _best.text = r.bestMoment;
      _hardest.text = r.hardestMoment;
      _situation.text = r.workSituation;
    }
  }

  @override
  void dispose() {
    _best.dispose();
    _hardest.dispose();
    _situation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final week = weekStartOf(now);
    final nextWeek = week.add(const Duration(days: 7));
    final report = system.reportForWeek(now);
    final nextBrief = system.briefForWeek(nextWeek);
    final thisBrief = system.briefForWeek(now);
    final showForm = report == null || _editing;
    final avg = system.weekAverage(now);
    final gym = system.gymSessionsInWeek(now);

    return OnoPage(
      showBack: true,
      eyebrow: 'Week of ${shortDate(week)}',
      title: 'Sunday report',
      subtitle:
          'Five things. The brief for next week comes straight back and is pinned to Today from Monday.',
      children: [
        if (thisBrief != null) ...[
          const SectionHeader('This week\'s brief'),
          _BriefView(brief: thisBrief),
        ],
        if (showForm) ...[
          const SectionHeader('Report'),
          Row(
            children: [
              Expanded(
                child: OnoCard(
                  child: StatTile(avg.toStringAsFixed(1),
                      '1 · Daily average', unit: '/${system.dailyCount}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OnoCard(
                  child: StatTile('$gym', '2 · Gym sessions', unit: '/3'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WeekReview(week: week),
          const SizedBox(height: 16),
          _field(_best, '3 · Best moment of the week',
              'What went right — be specific.'),
          _field(_hardest, '4 · Hardest moment',
              'What was hard, and what it revealed.'),
          _field(_situation, '5 · One work situation to coach through',
              'People, stakes, what you\'re unsure of.'),
          const SizedBox(height: 6),
          PrimaryButton(
            system.isGeneratingBrief ? 'Writing your brief…' : 'Send report → get brief',
            loading: system.isGeneratingBrief,
            onPressed: () async {
              final r = WeeklyReport(
                id: 'wr_${dateKey(week)}',
                weekStart: week,
                nonNegotiableAverage: avg,
                gymSessions: gym,
                bestMoment: _best.text.trim(),
                hardestMoment: _hardest.text.trim(),
                workSituation: _situation.text.trim(),
                createdAt: now,
              );
              final b = await system.submitReport(r);
              if (!context.mounted) return;
              setState(() => _editing = false);
              toast(
                  context,
                  b == null
                      ? 'Report saved. Brief failed: ${system.briefError}'
                      : 'Brief for next week is ready.');
            },
          ),
        ] else ...[
          const SizedBox(height: 18),
          OnoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.body),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Report sent ${shortDate(report.createdAt)} · ${report.nonNegotiableAverage.toStringAsFixed(1)}/10 · gym ${report.gymSessions}/3',
                      style: AppText.body()),
                ),
                TextButton(
                    onPressed: () => setState(() => _editing = true),
                    child: const Text('Edit')),
              ],
            ),
          ),
        ],
        if (nextBrief != null) ...[
          SectionHeader('Brief · week of ${shortDate(nextWeek)}'),
          _BriefView(brief: nextBrief),
          const SizedBox(height: 10),
          GhostButton('Copy report + brief',
              icon: Icons.copy_rounded,
              onPressed: () => copyText(
                  context,
                  '${report?.toCoachingMessage() ?? ''}\n\n'
                  '${nextBrief.headline}\n- ${nextBrief.tasks.join('\n- ')}')),
        ],
        if (system.briefs.length > 1) ...[
          const SectionHeader('Earlier briefs'),
          for (final b in system.briefs.where((b) =>
              dateKey(b.weekStart) != dateKey(nextWeek) &&
              dateKey(b.weekStart) != dateKey(week)))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week of ${shortDate(b.weekStart)}',
                        style: AppText.small()),
                    Text(b.headline, style: AppText.heading()),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String label, String hint) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppText.eyebrow()),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              minLines: 3,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
              decoration: InputDecoration(hintText: hint),
            ),
          ],
        ),
      );
}

class _BriefView extends StatelessWidget {
  final WeeklyBrief brief;
  const _BriefView({required this.brief});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnoCard(
          color: AppColors.navy,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      brief.source == 'ai'
                          ? Icons.auto_awesome_rounded
                          : Icons.smartphone_rounded,
                      size: 15,
                      color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        brief.source == 'ai'
                            ? 'WRITTEN BY YOUR AI COACH'
                            : 'WRITTEN ON THIS DEVICE FROM YOUR DATA',
                        style: AppText.eyebrow(color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(brief.headline, style: AppText.serif(size: 24)),
              const SizedBox(height: 8),
              for (var i = 0; i < brief.tasks.length; i++)
                CheckRow(
                  checked: system.isDone('brief:${brief.id}:$i'),
                  title: brief.tasks[i],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onChanged: (_) => system.toggleDone('brief:${brief.id}:$i'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _section('Domain brief', brief.domainBrief),
        _section('Coaching', brief.coaching),
        if (brief.adjustments.isNotEmpty)
          _section('Plan adjustments',
              brief.adjustments.map((a) => '• $a').join('\n')),
      ],
    );
  }

  Widget _section(String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: AppText.eyebrow()),
              const SizedBox(height: 8),
              Text(text, style: AppText.body()),
            ],
          ),
        ),
      );
}

/// The week's Big 3 at report time, and a way to plan the next one.
class _WeekReview extends StatelessWidget {
  final DateTime week;
  const _WeekReview({required this.week});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final o = system.weekOutcomes(week);
    final (done, set) = system.weekOutcomeScore(week);
    final next = week.add(const Duration(days: 7));
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(set == 0 ? 'BIG 3 · NOT SET THIS WEEK' : 'BIG 3 · $done OF $set DONE',
              style: AppText.eyebrow()),
          for (var i = 0; i < 3; i++)
            if (o[i].trim().isNotEmpty)
              CheckRow(
                checked: system.weekOutcomeDone(week, i),
                title: o[i],
                padding: const EdgeInsets.symmetric(vertical: 6),
                onChanged: (_) => system.toggleWeekOutcome(week, i),
              ),
          TextButton(
            onPressed: () => context.push('/week'),
            child: Text(system.hasWeekPlan(next)
                ? 'Next week\'s Big 3 are set — review'
                : 'Plan next week\'s Big 3'),
          ),
        ],
      ),
    );
  }
}

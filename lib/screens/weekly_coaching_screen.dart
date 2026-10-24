import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

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
  final _shipped = TextEditingController();
  final _learned = TextEditingController();
  bool _initialised = false;
  bool _editing = false;
  int _saves = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final system = context.read<PersonalSystemProvider>();
    final week = system.reportWeekFor(timeNow());
    _shipped.text = system.shippedInWeek(week)?.text ?? '';
    _learned.text = system.learnedInWeek(week)?.text ?? '';
    final r = system.reportForWeek(week);
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
    _shipped.dispose();
    _learned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = timeNow();
    // Usually this week; on Monday and Tuesday, last week if it wasn't
    // reported (its brief is then for this week).
    final week = system.reportWeekFor(now);
    final nextWeek = week.plusDays(7);
    final report = system.reportForWeek(week);
    final nextBrief = system.briefForWeek(nextWeek);
    final thisBrief = system.briefForWeek(now);
    final showForm = report == null || _editing;
    final avg = system.weekAverage(week);
    final builtIn = system.isBuiltInPerson;
    // Without the built-in training plan, the second number is movement and
    // the report records strength days.
    final gym = builtIn ? system.gymSessionsInWeek(week) : system.strengthDaysInWeek(week);

    return UnsavedGuard(
        changesOnly: true,
        saves: _saves,
        fields: [_best, _hardest, _situation, _shipped, _learned],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Week of ${shortDate(week)}',
      title: 'Sunday report',
      subtitle:
          'Five things. The brief for next week comes straight back and is pinned to Today from Monday.',
      children: [
        // (Closing last week late, its brief is this week's: shown below.)
        if (thisBrief != null && nextWeek != weekStartOf(now)) ...[
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
                  child: builtIn
                      ? StatTile('$gym', '2 · Gym sessions', unit: '/3')
                      : system.logsOf('move').isEmpty
                          // Movement isn't measured until they log it.
                          ? StatTile('${system.countBetween('win', week, week.plusDays(7))}', '2 · Wins logged')
                          : StatTile('${system.moveMinutesInWeek(week)}', '2 · Minutes moved', unit: '/150'),
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
          _field(_situation, '5 · One situation to coach through',
              'At work or at home: people, stakes, what you\'re unsure of.'),
          _line(_shipped, 'What you finished this week (optional)', 'A launch, a document, a fixed thing — it joins your wins',
              const Key('week-shipped')),
          _line(_learned, 'What you learned this week (optional)', 'One sentence — it joins your playbook',
              const Key('week-learned')),
          const SizedBox(height: 10),
          // A fresh space for a fresh week: optional, a tick and nothing more.
          CheckRow(
            key: const Key('space-reset'),
            checked: system.isDone('reset:${dateKey(week)}'),
            title: '15 minutes to reset your space',
            subtitle: [
              'Desk, bag, one room',
              for (final u in system.upkeepDue)
                if (system.careKindOf(u) == 'home') u.text,
            ].join(' · '),
            onChanged: (v) => system.setDone('reset:${dateKey(week)}', v),
          ),
          _Savour(week: week),
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
              system.saveWeekLines(week, shipped: _shipped.text, learned: _learned.text);
              setState(() => _saves++);
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
                      'Report sent ${shortDate(report.createdAt)} · ${report.nonNegotiableAverage.toStringAsFixed(1)}/${system.dailyCount}${builtIn ? ' · gym ${report.gymSessions}/3' : ''}',
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
    ));
  }

  Widget _line(TextEditingController c, String label, String hint, Key key) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          key: key,
          controller: c,
          minLines: 1,
          maxLines: 3,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

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
        _section(system.isBuiltInPerson ? 'Domain brief' : 'This week\'s practice',
            brief.domainBrief),
        _section('Coaching', brief.coaching),
        if (brief.adjustments.isNotEmpty)
          _section('Worth changing',
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
    final next = week.plusDays(7);
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(set == 0 ? 'THE WEEK\'S THREE · NOT SET' : 'THE WEEK\'S THREE · $done OF $set DONE',
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
                ? 'Next week\'s three are set — review'
                : 'Plan next week\'s three'),
          ),
        ],
      ),
    );
  }
}

/// Once a week, stay with one good thing for a minute: what made it good,
/// and who you told. Optional; nothing is scored.
class _Savour extends StatefulWidget {
  final DateTime week;
  const _Savour({required this.week});

  @override
  State<_Savour> createState() => _SavourState();
}

class _SavourState extends State<_Savour> {
  final _good = TextEditingController();
  final _told = TextEditingController();
  String? _picked;

  @override
  void dispose() {
    _good.dispose();
    _told.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final wins = system.winsInWeek(widget.week).take(5).toList();
    if (wins.isEmpty) return const SizedBox.shrink();
    final done = system.savouredInWeek(widget.week);
    if (done != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Text('You stayed with: ${done.text} — ${done.str('savoured')}',
            style: AppText.small(color: AppColors.body)),
      );
    }
    final picked = wins.where((w) => w.id == _picked).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stay with one good thing (optional)', style: AppText.heading()),
          Text('Pick one of this week\'s wins and give it a minute.', style: AppText.small()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in wins)
                ChoiceChip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(w.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  selected: _picked == w.id,
                  onSelected: (_) => setState(() => _picked = w.id),
                ),
            ],
          ),
          if (picked != null) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('savour-good'),
              controller: _good,
              minLines: 1,
              maxLines: 4,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(
                  labelText: 'What made it good?', hintText: 'Where you were, who was there, how it felt'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _told,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'Who did you tell? (optional)'),
            ),
            const SizedBox(height: 8),
            GhostButton('Keep it', key: const Key('savour-keep'), icon: Icons.check_rounded, onPressed: () {
              if (_good.text.trim().isEmpty) {
                toast(context, 'Write what made it good first.');
                return;
              }
              system.savourWin(picked, good: _good.text, told: _told.text);
              FocusScope.of(context).unfocus();
            }),
          ],
        ],
      ),
    );
  }
}

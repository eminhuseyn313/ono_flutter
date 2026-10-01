import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Sunday report: the two numbers are filled from tracked data, the three
/// answers are written. Saved per week and copyable as a coaching message.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final existing =
        context.read<PersonalSystemProvider>().reportForWeek(DateTime.now());
    if (existing != null) {
      _best.text = existing.bestMoment;
      _hardest.text = existing.hardestMoment;
      _situation.text = existing.workSituation;
    }
  }

  @override
  void dispose() {
    _best.dispose();
    _hardest.dispose();
    _situation.dispose();
    super.dispose();
  }

  WeeklyReport _build(PersonalSystemProvider system) {
    final now = DateTime.now();
    return WeeklyReport(
      id: 'wr_${dateKey(weekStartOf(now))}',
      weekStart: weekStartOf(now),
      nonNegotiableAverage: system.weekAverage(now),
      gymSessions: system.gymSessionsInWeek(now),
      bestMoment: _best.text.trim(),
      hardestMoment: _hardest.text.trim(),
      workSituation: _situation.text.trim(),
      createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final avg = system.weekAverage(now);
    final gym = system.gymSessionsInWeek(now);
    final past = system.reports
        .where((r) => dateKey(r.weekStart) != dateKey(weekStartOf(now)))
        .toList();

    return OnoPage(
      showBack: true,
      eyebrow: 'Every Sunday evening',
      title: 'Sunday report',
      subtitle:
          'Report five things. The response: next week\'s tasks, a domain brief, coaching on one real situation, and plan adjustments.',
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: '1 · Non-negotiables',
                value: avg.toStringAsFixed(1),
                unit: '/10 avg',
                progress: avg / 10,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: '2 · Gym sessions',
                value: '$gym',
                unit: '/3',
                progress: gym / 3,
                color: AppColors.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Filled automatically from your Daily 10 and gym logs.',
            style: AppText.small()),
        const SectionHeader('3 · Best moment of the week'),
        _Field(controller: _best, hint: 'What went right — be specific.'),
        const SectionHeader('4 · Hardest moment'),
        _Field(controller: _hardest, hint: 'What was hard, and what it revealed.'),
        const SectionHeader('5 · Work situation to coach through'),
        _Field(
            controller: _situation,
            hint: 'One real situation — people, stakes, what you\'re unsure of.'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => copyText(
                    context, _build(system).toCoachingMessage(),
                    message: 'Report copied — paste it to your coach'),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  system.saveReport(_build(system));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Week saved')));
                },
                child: const Text('Save this week'),
              ),
            ),
          ],
        ),
        if (past.isNotEmpty) ...[
          const SectionHeader('Past weeks'),
          for (final r in past)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OnoCard(
                padding: const EdgeInsets.all(16),
                onTap: () => copyText(context, r.toCoachingMessage()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Week of ${r.weekStart.day} ${monthName(r.weekStart.month)}',
                            style: AppText.heading()),
                        const Spacer(),
                        Tag('${r.nonNegotiableAverage.toStringAsFixed(1)}/10',
                            color: AppColors.accent),
                        const SizedBox(width: 6),
                        Tag('Gym ${r.gymSessions}/3', color: AppColors.body),
                      ],
                    ),
                    if (r.bestMoment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r.bestMoment,
                          style: AppText.small(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => OnoCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AppText.eyebrow().copyWith(fontSize: 10)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppText.number(size: 28)),
                const SizedBox(width: 4),
                Text(unit, style: AppText.small()),
              ],
            ),
            const SizedBox(height: 10),
            ThinBar(value: progress, color: color),
          ],
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Field({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint),
      );
}

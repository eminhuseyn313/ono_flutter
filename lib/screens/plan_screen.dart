import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// PLAN — the exact schedule: today's timeline, the weekly rotation
/// (podcasts, domain scans, training), the RA-safe gym plan and health.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonalSystemProvider>().load(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tabs = ['Day', 'Week', 'Train', 'Health'];

    return OnoPage(
      eyebrow: 'Plan',
      title: 'The system',
      subtitle: '06:00 wake · 22:30 sleep · three gym days · one rotation.',
      children: [
        const SizedBox(height: 20),
        _Segmented(
          labels: tabs,
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              0 => _DayTimeline(now: now),
              1 => _WeekView(now: now),
              2 => _TrainView(now: now),
              _ => const _HealthView(),
            },
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _Segmented(
      {required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        i == index ? AppColors.cardLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: AppText.small(
                      color: i == index ? AppColors.white : AppColors.grey,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Day ──

class _DayTimeline extends StatelessWidget {
  final DateTime now;
  const _DayTimeline({required this.now});

  @override
  Widget build(BuildContext context) {
    final current = currentBlock(now);
    final nowMin = now.hour * 60 + now.minute;
    final gym = gymDayFor(now);

    String detailFor(ScheduleBlock b) {
      switch (b.title) {
        case 'Drive':
          final p = podcastFor(now);
          return '${p.title} — ${p.detail}';
        case 'Desk arrival':
          final s = domainScanFor(now);
          return 'Breakfast + supplements. Domain scan: ${s.title}.';
        case 'Train or deep work':
          return eveningFocus(now.weekday);
        default:
          return b.detail;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${weekdayName(now.weekday)}${gym != null ? ' · Gym day ${gym.letter}' : ''}',
            style: AppText.heading()),
        const SizedBox(height: 14),
        for (var i = 0; i < dailySchedule.length; i++)
          _TimelineRow(
            block: dailySchedule[i],
            detail: detailFor(dailySchedule[i]),
            isCurrent: dailySchedule[i] == current,
            isPast: dailySchedule[i].minuteOfDay < nowMin &&
                dailySchedule[i] != current,
            isLast: i == dailySchedule.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final ScheduleBlock block;
  final String detail;
  final bool isCurrent;
  final bool isPast;
  final bool isLast;

  const _TimelineRow({
    required this.block,
    required this.detail,
    required this.isCurrent,
    required this.isPast,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final lane = AppColors.lane(block.lane);
    final textColor = isPast ? AppColors.grey : AppColors.white;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(block.timeLabel,
                  style: AppText.small(
                    color: isCurrent ? AppColors.accent : AppColors.grey,
                  ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: isCurrent ? 12 : 8,
                  height: isCurrent ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.accent
                        : isPast
                            ? AppColors.divider
                            : lane,
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 4,
                            strokeAlign: BorderSide.strokeAlignOutside)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 6),
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: isCurrent
                    ? BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5)),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(block.title,
                              style: AppText.heading(color: textColor)),
                        ),
                        if (isCurrent)
                          const Tag('NOW', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(detail,
                        style: AppText.small(
                            color: isPast
                                ? AppColors.grey.withValues(alpha: 0.7)
                                : AppColors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week ──

class _WeekView extends StatelessWidget {
  final DateTime now;
  const _WeekView({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final days = system.weekDays(now);

    return Column(
      children: [
        for (final d in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _WeekDayCard(
              date: d,
              isToday: d.day == now.day && d.month == now.month,
              score: system.scoreFor(d),
              gymDone: system.gymDone(d),
            ),
          ),
      ],
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int score;
  final bool gymDone;

  const _WeekDayCard({
    required this.date,
    required this.isToday,
    required this.score,
    required this.gymDone,
  });

  @override
  Widget build(BuildContext context) {
    final podcast = podcastFor(date);
    final scan = domainScanFor(date);
    final gym = gymDayFor(date);

    return OnoCard(
      highlight: isToday,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(weekdayName(date.weekday), style: AppText.heading()),
              const SizedBox(width: 8),
              if (isToday) const Tag('TODAY', color: AppColors.accent),
              const Spacer(),
              if (gym != null)
                Tag(gymDone ? 'Gym ${gym.letter} ✓' : 'Gym ${gym.letter}',
                    color: gymDone ? AppColors.body : AppColors.grey),
              const SizedBox(width: 6),
              Text('$score/10',
                  style: AppText.small(
                          color: score >= 7
                              ? AppColors.accent
                              : AppColors.grey)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _mini(Icons.podcasts_rounded, podcast.title),
          _mini(Icons.travel_explore_rounded, scan.title),
          _mini(Icons.nightlight_outlined, eveningFocus(date.weekday)),
        ],
      ),
    );
  }

  Widget _mini(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppText.small())),
          ],
        ),
      );
}

// ── Train ──

class _TrainView extends StatefulWidget {
  final DateTime now;
  const _TrainView({required this.now});

  @override
  State<_TrainView> createState() => _TrainViewState();
}

class _TrainViewState extends State<_TrainView> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = gymDayFor(widget.now)?.id ??
        gymPlan
            .firstWhere((g) => g.weekday > widget.now.weekday,
                orElse: () => gymPlan.first)
            .id;
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final day = gymPlan.firstWhere((g) => g.id == _selected);
    final sessions = system.gymSessionsInWeek(widget.now);
    final isToday = day.weekday == widget.now.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final g in gymPlan)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: g == gymPlan.last ? 0 : 8),
                  child: OnoCard(
                    highlight: g.id == _selected,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    onTap: () => setState(() => _selected = g.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY ${g.letter}',
                            style: AppText.eyebrow(
                                color: g.id == _selected
                                    ? AppColors.accent
                                    : AppColors.grey)),
                        const SizedBox(height: 6),
                        Text(g.name, style: AppText.heading()),
                        Text(weekdayName(g.weekday).substring(0, 3),
                            style: AppText.small()),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OnoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ScoreRing(
                progress: sessions / 3,
                size: 44,
                stroke: 4,
                color: AppColors.body,
                center: Text('$sessions',
                    style: AppText.number(size: 15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('$sessions of 3 sessions this week',
                    style: AppText.heading()),
              ),
              if (isToday)
                FilledButton(
                  onPressed: () => system.toggleGym(widget.now),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    backgroundColor: system.gymDone(widget.now)
                        ? AppColors.cardLight
                        : AppColors.accent,
                    foregroundColor: system.gymDone(widget.now)
                        ? AppColors.white
                        : AppColors.ink,
                  ),
                  child:
                      Text(system.gymDone(widget.now) ? 'Logged ✓' : 'Log'),
                ),
            ],
          ),
        ),
        const SectionHeader('Exercises'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < day.exercises.length; i++) ...[
                _ExerciseRow(index: i + 1, exercise: day.exercises[i]),
                if (i < day.exercises.length - 1) const Divider(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        OnoCard(
          accent: AppColors.body,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.favorite_border_rounded,
                  color: AppColors.body, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.finisher, style: AppText.heading()),
                    Text(
                        'Conversational pace. Builds the energy base beta thalassemia takes away.',
                        style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('RA modifications'),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEVER', style: AppText.eyebrow(color: AppColors.danger)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in raRemove) Tag(r, color: AppColors.danger)
                ],
              ),
              const SizedBox(height: 16),
              Text('INSTEAD', style: AppText.eyebrow(color: AppColors.body)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in raReplace) Tag(r, color: AppColors.body)
                ],
              ),
              const SizedBox(height: 16),
              Text(
                  'Face pulls 3×15 every session — protects the rotator cuff and builds the posture people read as presence.',
                  style: AppText.small(color: AppColors.greyLight)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final Exercise exercise;

  const _ExerciseRow({required this.index, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text('$index',
                style: AppText.small(
                        color: exercise.keyLift
                            ? AppColors.accent
                            : AppColors.grey)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                    style: AppText.body(
                            color: exercise.keyLift
                                ? AppColors.accent
                                : AppColors.white)
                        .copyWith(fontWeight: FontWeight.w600)),
                if (exercise.note != null)
                  Text(exercise.note!, style: AppText.small()),
              ],
            ),
          ),
          Text(exercise.sets,
              style: AppText.small(color: AppColors.greyLight)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Health ──

class _HealthView extends StatelessWidget {
  const _HealthView();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final bloodDone = system.doneCount(bloodwork.map((b) => 'blood:$b'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnoCard(
          child: Row(
            children: [
              _Stat('83', 'kg now'),
              _Stat('76–78', 'kg target'),
              _Stat('150g', 'protein / day'),
              _Stat('7.5h', 'sleep min'),
            ],
          ),
        ),
        const SectionHeader('Bloodwork — urgent'),
        OnoCard(
          accent: bloodDone == bloodwork.length
              ? AppColors.body
              : AppColors.danger,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$bloodDone of ${bloodwork.length} tested',
                  style: AppText.heading()),
              const SizedBox(height: 2),
              Text(
                  'Low ferritin is common with thalassemia and worsens fatigue. Book the test.',
                  style: AppText.small()),
              const SizedBox(height: 6),
              for (final b in bloodwork)
                CheckRow(
                  checked: system.isDone('blood:$b'),
                  title: b,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onChanged: (_) => system.toggleDone('blood:$b'),
                ),
            ],
          ),
        ),
        const SectionHeader('Supplements'),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.wb_sunny_outlined,
                    size: 16, color: AppColors.skill),
                const SizedBox(width: 8),
                Text('With breakfast · 07:45', style: AppText.heading()),
              ]),
              const SizedBox(height: 8),
              for (final s in supplementsMorning)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Text(s, style: AppText.body()),
                ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.nightlight_outlined,
                    size: 16, color: AppColors.mind),
                const SizedBox(width: 8),
                Text('With dinner · 20:30', style: AppText.heading()),
              ]),
              const SizedBox(height: 8),
              for (final s in supplementsNight)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Text(s, style: AppText.body()),
                ),
            ],
          ),
        ),
        const SectionHeader('Sleep protocol'),
        const OnoCard(
          child: Column(
            children: [
              KeyValueRow('In bed', '22:30 — 7.5 hours minimum'),
              KeyValueRow('Breathing', 'Nasal strip every night'),
              KeyValueRow('Phone', 'Outside the bedroom'),
              KeyValueRow('Room', '18–19°C'),
              KeyValueRow('22:00', 'No screens. Lay out tomorrow\'s outfit.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: AppText.number(size: 18)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AppText.small().copyWith(fontSize: 11)),
          ],
        ),
      );
}

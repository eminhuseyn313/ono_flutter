import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../data/general_program.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';

/// PROGRAM — the 18 months and everything the plan contains.
class ProgramScreen extends StatefulWidget {
  final int initialTab;
  const ProgramScreen({super.key, this.initialTab = 0});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(ProgramScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.isLoaded) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    final now = DateTime.now();
    return OnoPage(
      eyebrow: system.hasStarted
          ? 'Month ${system.programMonth} of ${system.programMonths} · ${system.phase.name}'
          : 'Starts ${shortDate(system.programStart)}',
      title: 'Program',
      children: [
        const SizedBox(height: 18),
        // Schedule, training plan and reference belong to the built-in
        // plan; someone with their own plan sees the journey.
        if (!system.isBuiltInPerson)
          const _Journey()
        else ...[
          Segmented(
            labels: const ['Journey', 'Schedule', 'Body', 'Reference'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: switch (_tab) {
                0 => const _Journey(),
                1 => _Schedule(now: now),
                2 => _Body(now: now),
                _ => const _Reference(),
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Journey ────────────────────────────────────────────────────────────

class _Journey extends StatelessWidget {
  const _Journey();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final month = system.programMonth;
    final today = dayOnly(DateTime.now());
    final builtIn = system.isBuiltInPerson;
    final profile = activeProfile;

    final spine = [
      for (var m = 1; m <= system.programMonths; m++)
        SpineMonth(
          month: m,
          milestonesDone: builtIn
              ? _milestones(m).where((id) => system.isDone(id)).length
              : 0,
          milestonesTotal: builtIn ? _milestones(m).length : 0,
          scores: [
            for (var d = 0; d < 30; d++)
              () {
                final day = system.monthStart(m).plusDays(d);
                if (day.isAfter(today) || day.isBefore(system.programStart)) {
                  return null;
                }
                return system.scoreOutOf10(day);
              }()
          ],
        ),
    ];

    final phase = system.phase;
    final unlocks = unlocksFor(month);
    final openUnlocks =
        unlocks.where((u) => u.doneKey == null || !system.isDone(u.doneKey!));
    final stats = system.statsForMonth(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spine(
          months: spine,
          currentMonth: month,
          currentPhaseId: system.phase.id,
          steps: builtIn
              ? pathSteps
              : [
                  if (profile.currentRole.isNotEmpty)
                    [profile.currentRole, '1'],
                  if (profile.targetRole.isNotEmpty)
                    [
                      profile.targetRole,
                      '${(system.programMonths * 2 ~/ 3) + 1}'
                    ],
                ],
          onMonthTap: (m) => builtIn ? context.push('/month/$m') : null,
        ),
        const SizedBox(height: 8),
        Text(
            builtIn
                ? 'Dots: milestones. Squares: every day\'s Daily 10 — the brighter, the higher. Tap a month.'
                : 'Each square is a day — the brighter, the more of your daily list you held.',
            style: AppText.small().copyWith(fontSize: 11.5)),
        const SizedBox(height: 18),
        OnoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PHASE · ${system.phaseSpanLabel(phase).toUpperCase()}',
                  style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(height: 6),
              Text(phase.name, style: AppText.title()),
              const SizedBox(height: 6),
              Text(
                  builtIn
                      ? phase.promise
                      : generalPhasePromises[phase.id] ?? '',
                  style: AppText.body()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: StatTile(
                          system.hasStarted ? '${system.dayOfMonth}' : '0',
                          'day of month $month',
                          unit: '/30')),
                  Expanded(
                      child: StatTile(
                          stats.daily10Average.toStringAsFixed(1), 'Daily avg',
                          unit: '/${system.dailyCount}')),
                  // Same count as the month review: excused days left out.
                  Expanded(
                      child: StatTile('${system.monthHeld(month).held}',
                          'of ${system.monthHeld(month).counted} days held')),
                ],
              ),
              const SizedBox(height: 14),
              ThinBar(value: system.dayOfMonth / 30),
            ],
          ),
        ),
        if (!builtIn) ...[
          SectionHeader('Month $month'),
          OnoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                LinkRow(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.accent,
                  title:
                      system.focusArea()?.name ?? 'Choose this month\'s area',
                  subtitle: system.focusArea() == null
                      ? 'One thing to practise for 30 days'
                      : '${system.repsIn(system.focusArea()!.id, month).length} reps this month',
                  onTap: () => context.push('/growth'),
                ),
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.flag_circle_outlined,
                  color: AppColors.accent,
                  title: system.activeGoals.isEmpty
                      ? 'Set your first goal'
                      : 'Goals',
                  subtitle: system.activeGoals.isEmpty
                      ? 'The outcome all of this serves'
                      : system.activeGoals.map((g) => g.text).join(' · '),
                  onTap: () => context.push('/goals'),
                ),
                // Offered once a month can be closed, not on day one.
                // Offered when a month can actually be closed (from day 27).
                if (system.monthToReview != null) ...[
                  const Divider(indent: 66),
                  LinkRow(
                    icon: Icons.fact_check_outlined,
                    color: AppColors.accent,
                    title: 'Close the month',
                    subtitle: system.monthReviewFor(
                                system.monthToReview ?? month) ==
                            null
                        ? 'What held, one lesson, what comes with you'
                        : 'Month ${system.monthToReview ?? month} reviewed · ${system.monthReviewFor(system.monthToReview ?? month)!.text}',
                    onTap: () => context.push('/month-review'),
                  ),
                ],
              ],
            ),
          ),
          // Their own path, month by month: what they grew, how far, what
          // they took from it.
          if (month > 1) ...[
            const SectionHeader('Your months'),
            OnoCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  for (var m = month - 1; m >= 1; m--)
                    Padding(
                      key: Key('your-month-$m'),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text('$m',
                                style: AppText.serif(size: 20, color: AppColors.accent)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(system.monthGrowthLine(m) ?? 'No area chosen',
                                    style: AppText.body(color: AppColors.white)),
                                Text(
                                    [
                                      'held ${system.monthHeld(m).held} of ${system.monthHeld(m).counted}',
                                      if ((system.monthReviewFor(m)?.str('lesson') ?? '').trim().isNotEmpty)
                                        '"${system.monthReviewFor(m)!.str('lesson')!.trim()}"',
                                    ].join(' · '),
                                    style: AppText.small()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ] else ...[
          SectionHeader('Month $month',
              action: 'Open', onAction: () => context.push('/month/$month')),
          Text(monthThemes[month] ?? '', style: AppText.body()),
          const SizedBox(height: 12),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (final u in unlocks) _UnlockRow(unlock: u),
              ],
            ),
          ),
          if (openUnlocks.isEmpty) ...[
            const SizedBox(height: 10),
            Text('Everything this month is done. Review the month.',
                style: AppText.small(color: AppColors.body)),
          ],
          if (system.dayOfMonth >= 24 || month > 1) ...[
            const SizedBox(height: 14),
            GhostButton(
                system.dayOfMonth >= 24
                    ? 'Month $month review'
                    : 'Review month ${month - 1}',
                icon: Icons.fact_check_outlined,
                onPressed: () => context.push(
                    '/month/${system.dayOfMonth >= 24 ? month : month - 1}')),
          ],
        ],
      ],
    );
  }

  static List<String> _milestones(int month) {
    final m = careerMilestones.where((c) => c.month == month);
    if (m.isEmpty) return const [];
    final cm = m.first;
    return [for (var i = 0; i < cm.targets.length; i++) cm.targetId(i)];
  }
}

class _UnlockRow extends StatelessWidget {
  final Unlock unlock;
  const _UnlockRow({required this.unlock});

  static const _icons = {
    'book': Icons.menu_book_rounded,
    'novel': Icons.auto_stories_outlined,
    'film': Icons.movie_outlined,
    'wardrobe': Icons.checkroom_rounded,
    'skincare': Icons.spa_outlined,
    'linkedin': Icons.campaign_outlined,
    'artifact': Icons.description_outlined,
    'certificate': Icons.workspace_premium_outlined,
    'protocol': Icons.edit_note_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final done = unlock.doneKey != null && system.isDone(unlock.doneKey!);
    return InkWell(
      onTap: unlock.route == null ? null : () => context.push(unlock.route!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(_icons[unlock.kind] ?? Icons.circle_outlined,
                size: 20, color: done ? AppColors.faint : AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unlock.title,
                      style: AppText.body(
                              color: done ? AppColors.grey : AppColors.white)
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(unlock.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small()),
                ],
              ),
            ),
            if (unlock.doneKey != null)
              IconButton(
                tooltip: 'Mark done',
                onPressed: () => system.toggleDone(unlock.doneKey!),
                icon: Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: done ? AppColors.accent : AppColors.faint),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

// ── Schedule ───────────────────────────────────────────────────────────

class _Schedule extends StatefulWidget {
  final DateTime now;
  const _Schedule({required this.now});

  @override
  State<_Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<_Schedule> {
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final w in [false, true])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(w ? 'This week' : 'Today'),
                  selected: _week == w,
                  showCheckmark: false,
                  selectedColor: AppColors.cardLight,
                  onSelected: (_) => setState(() => _week = w),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _week ? _WeekPlan(now: widget.now) : _DayTimeline(now: widget.now),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final DateTime now;
  const _DayTimeline({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final current = currentBlock(now);
    final nowMin = now.hour * 60 + now.minute;

    String detailFor(ScheduleBlock b) {
      switch (b.title) {
        case 'Drive':
          final p = podcastFor(now);
          return '${p.title} — ${p.detail}';
        case 'Desk arrival':
          return 'Breakfast + supplements. Domain scan: ${domainScanFor(now).title}.';
        case 'Lunch':
          return 'Eat 20 min. Read ${system.planBook == PersonalSystemProvider.noPlanBook ? 'your book' : system.planBook.title} 20 min. Feynman write 5 min.';
        case 'Train or deep work':
          final g = system.gymDayOn(now);
          return g == null
              ? eveningFocus(now.weekday)
                  .replaceAll(RegExp(r'Gym — .*'), 'Deep work')
              : 'Gym — Day ${g.letter} ${g.name}';
        default:
          return b.detail;
      }
    }

    return Column(
      children: [
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(block.timeLabel,
                  style: AppText.small(
                          color: isCurrent ? AppColors.accent : AppColors.grey)
                      .copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 15),
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
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 6),
                        color: AppColors.divider),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: isCurrent
                    ? BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6)),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.title,
                        style: AppText.heading(
                            color: isPast ? AppColors.grey : AppColors.white)),
                    const SizedBox(height: 2),
                    Text(detail, style: AppText.small()),
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

class _WeekPlan extends StatelessWidget {
  final DateTime now;
  const _WeekPlan({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final days = system.weekDays(now);
    return Column(
      children: [
        OnoCard(
          child: WeekBars(
            scores: [
              for (final d in days)
                d.isAfter(now) ? null : system.scoreOutOf10(d)
            ],
            todayIndex: now.weekday - 1,
          ),
        ),
        const SizedBox(height: 12),
        for (final d in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              highlight: dateKey(d) == dateKey(now),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(weekdayName(d.weekday), style: AppText.heading()),
                      const Spacer(),
                      if (system.gymDayOn(d) != null)
                        Tag('Gym ${system.gymDayOn(d)!.letter}${system.gymDone(d) ? ' ✓' : ''}',
                            color: system.gymDone(d)
                                ? AppColors.body
                                : AppColors.grey),
                      const SizedBox(width: 8),
                      Text(
                          d.isAfter(now)
                              ? '—'
                              : '${system.scoreFor(d)}/${system.dailyCount}',
                          style: AppText.small(color: AppColors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _mini(Icons.podcasts_rounded, podcastFor(d).title),
                  _mini(Icons.travel_explore_rounded, domainScanFor(d).title),
                  _mini(
                      Icons.nightlight_outlined,
                      system.gymDayOn(d) != null
                          ? 'Gym — Day ${system.gymDayOn(d)!.letter} ${system.gymDayOn(d)!.name}'
                          : eveningFocus(d.weekday)
                              .replaceAll(RegExp(r'Gym — .*'), 'Deep work')),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _mini(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppText.small())),
          ],
        ),
      );
}

// ── Body ───────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final DateTime now;
  const _Body({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final weights = system.weightSeries;
    final sessions = system.logsOf('gym');
    final next = system.nextGymDay(now);
    final bloodDone = bloodwork.where((b) => system.latestBlood(b) != null);
    final today = dayOnly(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Training
        OnoCard(
          highlight:
              dateKey(next.date) == dateKey(today) && !system.gymDone(today),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  dateKey(next.date) == dateKey(today)
                      ? 'TODAY · 19:00'
                      : 'NEXT · ${weekdayName(next.date.weekday).toUpperCase()}',
                  style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(height: 6),
              Text('Day ${next.day.letter} — ${next.day.name}',
                  style: AppText.title()),
              const SizedBox(height: 10),
              TickSegments(
                  total: 3,
                  filled: system.gymSessionsInWeek(now),
                  color: AppColors.body),
              const SizedBox(height: 6),
              Text('${system.gymSessionsInWeek(now)} of 3 this week',
                  style: AppText.small()),
              const SizedBox(height: 14),
              PrimaryButton(
                  system.gymDone(today)
                      ? 'Session logged — view'
                      : 'Start session',
                  icon: Icons.fitness_center_rounded,
                  onPressed: () => context.push('/gym/${next.day.id}')),
            ],
          ),
        ),
        const SectionHeader('Plan · RA-safe'),
        for (final g in gymPlan)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/gym/${g.id}'),
              child: Row(
                children: [
                  Text(g.letter,
                      style: AppText.serif(size: 30, color: AppColors.body)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: AppText.heading()),
                        Text(
                            '${weekdayName(system.gymDays[gymPlan.indexOf(g)])} · ${g.exercises.length} exercises · ${g.finisher}',
                            style: AppText.small()),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.faint),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        OnoCard(
          accent: AppColors.danger,
          padding: const EdgeInsets.all(14),
          child: Text(
              'Never: ${raRemove.join(', ').toLowerCase()}. Instead: ${raReplace.join(', ').toLowerCase()}. Face pulls 3×15 every session.',
              style: AppText.small(color: AppColors.greyLight)),
        ),
        if (sessions.isNotEmpty) ...[
          const SectionHeader('Recent sessions'),
          OnoCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final s in sessions.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(
                            gymPlan
                                .firstWhere((g) => g.id == s.str('day'),
                                    orElse: () => gymPlan.first)
                                .letter,
                            style:
                                AppText.serif(size: 22, color: AppColors.body)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                '${weekdayName(s.date.weekday)} ${shortDate(s.date)}${s.data['zone2'] == true ? ' · Zone 2' : ''}',
                                style: AppText.body())),
                        Text(
                            '${((s.number('volume') ?? 0) / 1000).toStringAsFixed(1)} t',
                            style: AppText.small(color: AppColors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        SectionHeader('Weight',
            action: 'Log', onAction: () => context.push('/log?add=weight')),
        OnoCard(
          child: weights.length < 2
              ? EmptyNote(weights.isEmpty
                  ? 'No weigh-ins yet. Log one each Monday morning.'
                  : 'One weigh-in (${weights.first.number('kg')} kg). The trend appears after the second.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrendLine(
                      points: [
                        for (final w in weights)
                          (x: w.date, y: (w.number('kg') ?? 0).toDouble())
                      ],
                      bandLow: 76,
                      bandHigh: 78,
                      unit: ' kg',
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Band: target 76–78 kg. Change since start: ${((system.latestWeight ?? 0) - (system.startWeight ?? 0)).toStringAsFixed(1)} kg.',
                        style: AppText.small()),
                  ],
                ),
        ),
        SectionHeader('Bloodwork',
            action: 'Add result',
            onAction: () => context.push('/log?add=blood')),
        OnoCard(
          accent: bloodDone.length == bloodwork.length
              ? AppColors.body
              : AppColors.danger,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              for (final b in bloodwork)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(b, style: AppText.body())),
                      Text(
                          system.latestBlood(b) == null
                              ? 'not tested'
                              : '${system.latestBlood(b)!.number('value')} ${system.latestBlood(b)!.str('unit') ?? ''} · ${shortDate(system.latestBlood(b)!.date)}',
                          style: AppText.small(
                              color: system.latestBlood(b) == null
                                  ? AppColors.danger
                                  : AppColors.white)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader('Supplements today'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              CheckRow(
                checked: system.isChecked(today, 'supp_am'),
                title: 'Morning: ${supplementsMorning.join(' · ')}',
                subtitle: 'With breakfast, 07:45',
                onChanged: (_) => system.toggleCheck(today, 'supp_am'),
              ),
              CheckRow(
                checked: system.isChecked(today, 'supp_pm'),
                title: 'Evening: ${supplementsNight.join(' · ')}',
                subtitle: 'With dinner, 20:30',
                onChanged: (_) => system.toggleCheck(today, 'supp_pm'),
              ),
              CheckRow(
                checked: system.isChecked(today, 'nasal'),
                title: 'Nasal strip on',
                subtitle: 'Phone outside · room 18–19°C · in bed 22:30',
                onChanged: (_) => system.toggleCheck(today, 'nasal'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reference ──────────────────────────────────────────────────────────

class _Reference extends StatelessWidget {
  const _Reference();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final wardrobeKeys = wardrobe.map((w) => 'wardrobe:${w.id}');
    final milestoneKeys = [
      for (final m in careerMilestones)
        for (var i = 0; i < m.targets.length; i++) m.targetId(i)
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnoCard(
          onTap: () => context.push('/manifesto'),
          color: AppColors.navy,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MANIFESTO',
                  style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(height: 10),
              Text('I do not need to know everything to be competent.',
                  style: AppText.serif(size: 26)),
              const SizedBox(height: 8),
              Text('I speak from position, not permission.',
                  style: AppText.body()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.bolt_rounded,
                color: AppColors.mind,
                title: 'Protocols',
                subtitle: 'Guided tools with mastery levels',
                trailing: '${protocols.length}',
                onTap: () => context.push('/protocols'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.inventory_2_outlined,
                color: AppColors.steel,
                title: 'Evidence Archive',
                subtitle: 'Add Sunday · read Monday',
                trailing: '${system.evidenceCount}',
                onTap: () => context.push('/evidence'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.menu_book_rounded,
                color: AppColors.mind,
                title: 'Library',
                subtitle: 'Books by month · novels · films · podcasts',
                onTap: () => context.push('/library'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.checkroom_rounded,
                color: AppColors.social,
                title: 'Style system',
                subtitle: 'Outfits · wardrobe · beard · grooming',
                trailing:
                    '${system.doneCount(wardrobeKeys)}/${wardrobe.length}',
                onTap: () => context.push('/style'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.trending_up_rounded,
                color: AppColors.skill,
                title: 'Career & signal',
                subtitle: 'Thesis · LinkedIn · certificates · milestones',
                trailing:
                    '${system.doneCount(milestoneKeys)}/${milestoneKeys.length}',
                onTap: () => context.push('/career'),
              ),
            ],
          ),
        ),
        const SectionHeader('The four lanes'),
        for (final lane in laneFocus)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LaneCard(lane: lane),
          ),
      ],
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
    final l = widget.lane;
    return OnoCard(
      accent: AppColors.lane(l.lane),
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.name, style: AppText.serif(size: 22)),
              const Spacer(),
              Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.problem, style: AppText.small()),
          if (_open)
            for (final a in l.actions)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LaneDot(l.lane, size: 5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(a, style: AppText.body())),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

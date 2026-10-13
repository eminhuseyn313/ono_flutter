import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_personal_content.dart';
import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/auth_provider.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';
import 'goals_screen.dart' show GoalTile;

/// TODAY — changes with the time of day: ritual first in the morning,
/// tools for pressure moments at work, closing the day in the evening,
/// the report on Sunday. Yesterday stays editable.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Mode { morning, work, evening, sunday }

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  bool _yesterday = false;
  int _lastScore = -1;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final system = context.read<PersonalSystemProvider>();
    await system.load(context.read<AuthProvider>().userId);
    if (mounted && !system.isCommissioned) context.go('/start');
    await system.syncHealth();
    await system.syncCalendar();
    await system.refreshWidget();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  _Mode get _mode {
    final m = _now.hour * 60 + _now.minute;
    // Sunday afternoon is for the report; once it's sent, the evening
    // (shutdown, ticking the three) is back.
    final system = context.read<PersonalSystemProvider>();
    if (_now.weekday == DateTime.sunday &&
        m >= 16 * 60 &&
        system.weekWorthReviewing(_now) &&
        system.reportForWeek(_now) == null) {
      return _Mode.sunday;
    }
    // After midnight it is still the evening before, not morning.
    if (_now.hour < PersonalSystemProvider.dayEndsAt) return _Mode.evening;
    if (m < 10 * 60 + 30) return _Mode.morning;
    if (m < 18 * 60) return _Mode.work;
    return _Mode.evening;
  }

  String get _greeting => switch (_mode) {
        _Mode.morning => 'Good morning, ${activeProfile.firstName}.',
        _Mode.work => 'Stay deliberate, ${activeProfile.firstName}.',
        _Mode.evening => 'Good evening, ${activeProfile.firstName}.',
        _Mode.sunday => 'Sunday, ${activeProfile.firstName}. Review the week.',
      };

  void _celebrate(PersonalSystemProvider system, DateTime date) {
    final score = system.scoreFor(date);
    final total = system.itemIdsOn(date).length;
    final target = system.targetFor(date);
    if (_lastScore >= 0 && score > _lastScore) {
      if (score == total) {
        HapticFeedback.heavyImpact();
        _showHeld(context, score: score, total: total, target: target);
      } else if (score == target) {
        HapticFeedback.heavyImpact();
        _showHeld(context, score: score, total: total, target: target);
      }
    }
    _lastScore = score;
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.isLoaded || !system.isCommissioned) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final today = dayOnly(_now);
    final date = _yesterday ? today.minusDays(1) : today;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _celebrate(system, date));

    final bottom = MediaQuery.of(context).padding.bottom;
    final brief = system.briefForWeek(today);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            setState(() => _now = DateTime.now());
            final system = context.read<PersonalSystemProvider>();
            await system.syncHealth();
            await system.syncCalendar();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpace.gutter, 12, AppSpace.gutter, bottom + 110),
            children: [
              _Header(
                now: _now,
                system: system,
                greeting: _greeting,
              ),
              const SizedBox(height: 14),
              _DateSwitch(
                yesterday: _yesterday,
                onChanged: (v) => setState(() {
                  _yesterday = v;
                  _lastScore = -1;
                }),
              ),
              const SizedBox(height: 18),
              if (!system.hasStarted)
                _CountdownCard(days: system.daysUntilStart)
              else ...[
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/program?tab=1'),
                    child: DayDial(
                      now: _now,
                      // A smaller dial on short phones keeps the daily list
                      // closer to the top.
                      size: MediaQuery.sizeOf(context).height < 700 ? 220 : 280,
                      schedule: system.isBuiltInPerson
                          ? dailySchedule
                          : system.personalSchedule,
                      ticks: [
                        for (final n in system.dailyItems)
                          (lane: n.lane, done: system.isChecked(date, n.id))
                      ],
                      center: _DialCenter(
                          now: _now,
                          score: system.scoreFor(date),
                          total: system.itemIdsOn(date).length,
                          target: system.targetFor(date),
                          label: system.isBuiltInPerson
                              ? null
                              : _nextUp(system, date)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!_yesterday) ...[
                  if (system.freshStartFor(today) case final fs?
                      when !system.isDone(fs.key)) ...[
                    _FreshStartCard(fs: fs),
                    const SizedBox(height: 12),
                  ],
                  _ModeCard(mode: _mode, now: _now),
                  _CheckinCard(now: _now),
                ],
              ],
              if (!_yesterday && system.hasStarted && system.isRecoveryDay) ...[
                const SizedBox(height: 12),
                _RecoveryCard(
                    yesterdayScore: system.scoreFor(today.minusDays(1)),
                    streak: system.streak,
                    onFillYesterday: () => setState(() {
                          _yesterday = true;
                          _lastScore = -1;
                        })),
              ],
              if (!_yesterday && system.isRestDay(today)) ...[
                const SizedBox(height: 12),
                _RestCard(day: today),
              ],
              if (!_yesterday && system.hasStarted) _Prompts(now: _now),
              SectionHeader('Daily ${system.dailyCount}',
                  action: 'Edit', onAction: () => context.push('/daily')),
              if (system.hasStarted &&
                  (system.hardDayOn(date) != null ||
                      system.isReentryDay(date))) ...[
                _HardDayCard(date: date),
                const SizedBox(height: 10),
              ],
              _DailyTen(date: date),
              SectionHeader(_now.hour >= 18 && !_yesterday
                  ? 'Did the three happen?'
                  : 'Three priorities'),
              _Priorities(
                key: ValueKey(dateKey(date)),
                date: date,
                review: _now.hour >= 18 || _yesterday,
              ),
              if (!_yesterday && system.hasStarted)
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/need'),
                    icon: const Icon(Icons.support_rounded, size: 18),
                    label: const Text('What do you need right now?'),
                  ),
                ),
              // Everything that isn't today's next action: one tap away.
              if (!_yesterday && system.hasStarted) ...[
                // A new brief stays in view until it has been opened once.
                if (brief != null &&
                    !system.isDone(_planOpenKey) &&
                    !system.isDone('brief:seen:${brief.id}')) ...[
                  const SizedBox(height: 12),
                  _BriefCard(brief: brief),
                ],
                _PlanToggle(now: _now),
                if (system.isDone(_planOpenKey)) ...[
                  const _GoalsCard(),
                  _GrowthCard(now: _now),
                  _WeekCard(now: _now),
                  _MeetingsCard(now: _now),
                  if (brief != null) ...[
                    const SizedBox(height: 12),
                    _BriefCard(brief: brief),
                  ],
                  const SectionHeader('Today\'s inputs'),
                  if (system.isBuiltInPerson)
                    _InputsStrip(date: today, month: system.programMonth)
                  else
                    _GeneralInputs(date: today),
                  if (system.isBuiltInPerson) ...[
                    const SectionHeader('Body'),
                    _BodyCard(date: today),
                  ],
                  const SectionHeader('Carry this'),
                  if (system.isBuiltInPerson)
                    _CoachNote(day: system.programDay)
                  else
                    const _QuestionCard(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showHeld(BuildContext context,
    {required int score, required int total, required int target}) {
  final perfect = score >= total;
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'held',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      });
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScoreRing(
                progress:
                    total == 0 ? 1 : (score / total).clamp(0, 1).toDouble(),
                size: 140,
                stroke: 12,
                center: Text('$score',
                    style: AppText.serif(size: 54, color: AppColors.accent)),
              ),
              const SizedBox(height: 20),
              Text(perfect ? 'All $total.' : 'Day held.',
                  style: AppText.display()),
              const SizedBox(height: 6),
              Text(
                  perfect
                      ? 'Not performing. Building.'
                      : '$target of $total — the streak is safe.',
                  style: AppText.body()),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: child),
    ),
  );
}

class _Header extends StatelessWidget {
  final DateTime now;
  final PersonalSystemProvider system;
  final String greeting;

  const _Header(
      {required this.now, required this.system, required this.greeting});

  @override
  Widget build(BuildContext context) {
    final day = system.hasStarted
        ? system.programComplete
            ? 'Program complete'
            : 'Day ${system.programDay} · ${system.phase.name}'
        : 'Starts in ${system.daysUntilStart}d';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                  '${weekdayName(now.weekday).substring(0, 3)} ${shortDate(now)} · $day',
                  style: AppText.small(color: AppColors.grey)),
            ),
            // The streak badge appears once there has been a streak.
            if (system.bestStreak > 0)
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 15,
                          color: system.streak > 0
                              ? AppColors.accent
                              : AppColors.faint),
                      const SizedBox(width: 4),
                      Text('${system.streak}',
                          style: AppText.small(color: AppColors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(greeting, style: AppText.title()),
      ],
    );
  }
}

class _DateSwitch extends StatelessWidget {
  final bool yesterday;
  final ValueChanged<bool> onChanged;

  const _DateSwitch({required this.yesterday, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final y in [true, false])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(y ? 'Yesterday' : 'Today'),
              selected: yesterday == y,
              showCheckmark: false,
              selectedColor: AppColors.cardLight,
              side: BorderSide(
                  color:
                      yesterday == y ? AppColors.greyLight : AppColors.divider),
              labelStyle: AppText.small(
                      color: yesterday == y ? AppColors.white : AppColors.grey)
                  .copyWith(fontWeight: FontWeight.w700),
              onSelected: (_) => onChanged(y),
            ),
          ),
        if (yesterday)
          Expanded(
            child: Text(
                context.read<PersonalSystemProvider>().isBuiltInPerson
                    ? 'Fill in what you missed — bed, protein, Feynman.'
                    : 'Fill in what you missed yesterday.',
                style: AppText.small().copyWith(fontSize: 11.5)),
          ),
      ],
    );
  }
}

/// The next unticked item for this part of the day, for a plan without a
/// built-in schedule.
({String eyebrow, String title}) _nextUp(
    PersonalSystemProvider system, DateTime date) {
  final h = DateTime.now().hour;
  final part = h < 12 ? 'morning' : (h < 18 ? 'day' : 'evening');
  final open = [
    for (final n in system.dailyItems)
      if (!system.isChecked(date, n.id)) n
  ];
  final now = open.where((n) => n.when == part).firstOrNull;
  final next = now ?? open.firstOrNull;
  final block = system.personalBlockAt(DateTime.now());
  // The label follows the item: one meant for later in the day is "next",
  // not "this morning".
  final when = now != null ? part : next?.when;
  return (
    eyebrow: block != null && now != null
        ? '${block.title.toUpperCase()} · NOW'
        : now == null
            ? 'NEXT'
            : switch (when) {
                'morning' => 'THIS MORNING',
                'day' => 'TODAY',
                _ => 'THIS EVENING'
              },
    title: next?.title ?? 'All done for today',
  );
}

class _DialCenter extends StatelessWidget {
  final DateTime now;
  final int score;
  final int total;
  final int target;

  /// Without a built-in schedule: what's next on their own list.
  final ({String eyebrow, String title})? label;
  const _DialCenter(
      {required this.now,
      required this.score,
      required this.total,
      required this.target,
      this.label});

  @override
  Widget build(BuildContext context) {
    final block = currentBlock(now);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label?.eyebrow ?? '${block.timeLabel} · NOW',
            style: AppText.eyebrow(color: AppColors.accent)),
        const SizedBox(height: 4),
        Text(label?.title ?? block.title,
            textAlign: TextAlign.center, maxLines: 2, style: AppText.heading()),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$score',
                style: AppText.serif(
                    size: 52,
                    color:
                        score >= target ? AppColors.accent : AppColors.white)),
            Text('/$total', style: AppText.small()),
          ],
        ),
        Text(
            score >= target
                ? 'Today counts'
                : '${target - score} more and today counts',
            style: AppText.small().copyWith(fontSize: 11.5)),
      ],
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final int days;
  const _CountdownCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final builtIn = context.read<PersonalSystemProvider>().isBuiltInPerson;
    return OnoCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAY 1 IN $days ${days == 1 ? 'DAY' : 'DAYS'}',
              style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 10),
          Text('Use the runway.', style: AppText.title()),
          const SizedBox(height: 8),
          Text(
              builtIn
                  ? 'Book the bloodwork, order the navy merino, fill the Evidence Archive, and read the manifesto each morning so Day 1 isn\'t the first time.'
                  : 'Try your daily items once before they count, set your first goal, and write down what you\'ve already built, so Day 1 isn\'t the first time.',
              style: AppText.body()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: builtIn
                    ? GhostButton('Bloodwork',
                        icon: Icons.bloodtype_outlined,
                        onPressed: () => context.go('/program?tab=2'))
                    : GhostButton('Goals',
                        icon: Icons.flag_circle_outlined,
                        onPressed: () => context.push('/goals')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GhostButton('Evidence',
                    icon: Icons.inventory_2_outlined,
                    onPressed: () => context.push('/evidence')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What this moment asks for.
class _ModeCard extends StatelessWidget {
  final _Mode mode;
  final DateTime now;
  const _ModeCard({required this.mode, required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    // After midnight the evening card belongs to the day just ended.
    final today = mode == _Mode.evening && now.hour < PersonalSystemProvider.dayEndsAt
        ? system.logicalToday
        : dayOnly(now);
    if (!system.isBuiltInPerson) return _general(context, system, today);
    switch (mode) {
      case _Mode.morning:
        final ritualDone = system.logsOn(today, 'ritual').isNotEmpty;
        if (now.weekday == DateTime.monday && !ritualDone) {
          return _action(
            context,
            eyebrow: 'Monday',
            title: 'Ritual, then your evidence',
            body:
                'Five minutes of ritual, then read the ${system.evidenceCount} items of proof before the first meeting.',
            cta: 'Start the ritual',
            route: '/ritual-flow/ritual_morning_default',
          );
        }
        return ritualDone
            ? _action(
                context,
                eyebrow: 'Morning',
                title: 'Desk at 07:45 — domain scan',
                body:
                    '${domainScanFor(now).title}: ${domainScanFor(now).detail}. 15 minutes, one insight saved.',
                cta: 'Start the scan',
                route: '/tool/scan',
              )
            : _action(
                context,
                eyebrow: 'Morning ritual · 5 min',
                title: 'Water. Manifesto. Three priorities. Sigh. Statement.',
                body: activeProfile.identityStatement,
                cta: 'Start the ritual',
                route: '/ritual-flow/ritual_morning_default',
              );
      case _Mode.work:
        return OnoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BEFORE THE NEXT HARD MOMENT', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              Row(
                children: [
                  _tool(context, Icons.air_rounded, 'Sigh', '/tool/sigh',
                      AppColors.mind),
                  _tool(context, Icons.layers_rounded, '6Q prep', '/tool/sixq',
                      AppColors.skill),
                  _tool(context, Icons.vertical_align_top_rounded, 'BLUF',
                      '/tool/bluf', AppColors.skill),
                  _tool(context, Icons.pause_circle_outline_rounded, 'Pause',
                      '/tool/pause', AppColors.social),
                ],
              ),
            ],
          ),
        );
      case _Mode.evening:
        final gym = system.gymDayOn(today);
        if (gym != null && !system.gymDone(today) && now.hour < 21) {
          return _action(
            context,
            eyebrow: '19:00 · Day ${gym.letter}',
            title: '${gym.name} — ${gym.exercises.length} exercises',
            body: 'Face pulls 3×15 never skipped. Zone 2 cooldown 15 min.',
            cta: 'Start session',
            route: '/gym',
          );
        }
        if (system.shutdownFor(today) == null) {
          final open = system.carryOverFrom(today).length;
          return _action(
            context,
            eyebrow: '21:30 · Shutdown',
            title: 'Close the day in three minutes',
            body: open == 0
                ? 'Write tomorrow\'s three and empty your head. Tomorrow on paper means faster sleep tonight.'
                : '$open of today\'s three still open — they carry over. Write tomorrow\'s three, then let the day go.',
            cta: 'Start shutdown',
            route: '/shutdown',
          );
        }
        final tomorrow = today.plusDays(1);
        return _action(
          context,
          eyebrow: '22:00 · Close the day',
          title: 'Tomorrow: ${outfitFor(tomorrow).occasion}',
          body:
              '${outfitFor(tomorrow).formula}. Lay it out, phone outside the bedroom, nasal strip, lights out 22:30.',
          cta: 'Log a win from today',
          route: '/log?add=win',
        );
      case _Mode.sunday:
        final done = system.reportForWeek(now) != null;
        return _action(
          context,
          eyebrow: 'Sunday report',
          title: done ? 'Report sent — read your brief' : 'Five answers',
          body: done
              ? 'Next week\'s plan is pinned to Today from Monday.'
              : 'Daily 10 average and gym count fill themselves. Your brief for next week comes back immediately.',
          cta: done ? 'Open the brief' : 'Write the report',
          route: '/weekly-coaching',
        );
    }
  }

  /// The same moments for someone with their own plan: no built-in
  /// schedule, ritual or training plan.
  Widget _general(
      BuildContext context, PersonalSystemProvider system, DateTime today) {
    switch (mode) {
      case _Mode.morning:
        if (system.checkinFor(today) == null) {
          return _action(context,
              eyebrow: 'Morning',
              title: 'How are you this morning?',
              body:
                  'Thirty seconds: energy, mood, sleep. It shapes what today should ask of you.',
              cta: 'Check in',
              route: '/checkin');
        }
        final next = system.dailyItems
            .where((n) => n.when == 'morning' && !system.isChecked(today, n.id))
            .firstOrNull;
        if (next == null) {
          // What last night's shutdown decided comes back in the morning.
          final first = system.prioritiesFor(today)
              .where((p) => p.trim().isNotEmpty)
              .firstOrNull;
          final open = (system.shutdownFor(today.minusDays(1))?.str('open') ?? '').trim();
          if (first != null) {
            return _action(context,
                eyebrow: 'Last night you decided',
                title: first,
                body: open.isEmpty
                    ? 'Do it before the day decides for you.'
                    : 'Also on your mind last night: ${open.length > 90 ? '${open.substring(0, 89)}…' : open}',
                cta: 'Start a focus block',
                route: '/focus');
          }
          if (system.weekOutcomeScore(today).$2 > 0) {
            return _action(context,
                eyebrow: 'Morning',
                title: 'What must be true by tonight?',
                body: 'Write today\'s three below — each one moving the week\'s three.',
                cta: 'See the week',
                route: '/week');
          }
        }
        return _action(context,
            eyebrow: 'Morning',
            title: next == null ? 'Set the week\'s three' : next.title,
            body: next == null
                ? 'Three outcomes that would make this week a win; today\'s priorities below serve them.'
                : system.cueFor(next.id).isEmpty
                    ? 'The first thing on your list this morning.'
                    : system.cueFor(next.id),
            cta: next == null
                ? 'Plan the week'
                : next.route == null
                    ? 'See your daily items'
                    : 'Start it',
            route: next == null ? '/week' : next.route ?? '/daily');
      case _Mode.work:
        return OnoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHEN IT GETS HARD', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              Row(
                children: [
                  _tool(context, Icons.air_rounded, 'Breathe', '/tool/sigh',
                      AppColors.mind),
                  _tool(context, Icons.center_focus_strong_rounded, 'Focus',
                      '/focus', AppColors.skill),
                  _tool(context, Icons.pause_circle_outline_rounded, 'Pause',
                      '/tool/pause', AppColors.social),
                  _tool(context, Icons.zoom_out_map_rounded, 'Step back',
                      '/stepback', AppColors.warning),
                ],
              ),
            ],
          ),
        );
      case _Mode.evening:
        if (system.shutdownFor(today) == null) {
          return _action(context,
              eyebrow: 'Evening',
              title: 'Close the day in three minutes',
              body:
                  'Tick what happened, write tomorrow\'s three, empty your head. Then stop.',
              cta: 'Start shutdown',
              route: '/shutdown');
        }
        return _action(context,
            eyebrow: 'Evening',
            title: 'One good thing from today',
            body:
                'Name it before you sleep. Small wins are what keep people going.',
            cta: 'Log a win',
            route: '/log?add=win');
      case _Mode.sunday:
        final done = system.reportForWeek(now) != null;
        return _action(context,
            eyebrow: 'Sunday',
            title: done
                ? 'Report sent — read your brief'
                : 'Five answers about your week',
            body: done
                ? 'Next week\'s plan comes from it.'
                : 'Your daily average fills itself. Your brief for next week comes back straight away.',
            cta: done ? 'Open the brief' : 'Write the report',
            route: '/weekly-coaching');
    }
  }

  Widget _tool(BuildContext context, IconData icon, String label, String route,
          Color color) =>
      Expanded(
        child: GestureDetector(
          onTap: () => context.push(route),
          child: Column(
            children: [
              IconTile(icon, color: color, size: 48),
              const SizedBox(height: 6),
              Text(label,
                  style: AppText.small(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _action(BuildContext context,
      {required String eyebrow,
      required String title,
      required String body,
      required String cta,
      required String route}) {
    return OnoCard(
      highlight: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 8),
          Text(title, style: AppText.serif(size: 24)),
          const SizedBox(height: 6),
          Text(body, style: AppText.body()),
          const SizedBox(height: 16),
          PrimaryButton(cta,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(route)),
        ],
      ),
    );
  }
}

/// Monday, a new month, a new phase: a moment to restart on purpose.
class _FreshStartCard extends StatelessWidget {
  final FreshStart fs;
  const _FreshStartCard({required this.fs});

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return OnoCard(
      color: AppColors.navy,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(fs.eyebrow.toUpperCase(),
                    style: AppText.eyebrow(color: AppColors.accent)),
              ),
              GestureDetector(
                onTap: () => system.setDone(fs.key, true),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(fs.title, style: AppText.serif(size: 24)),
          const SizedBox(height: 6),
          Text(fs.body, style: AppText.body()),
          const SizedBox(height: 16),
          PrimaryButton(fs.cta,
              icon: fs.route == null
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded, onPressed: () {
            HapticFeedback.mediumImpact();
            system.setDone(fs.key, true);
            if (fs.route != null) context.push(fs.route!);
          }),
        ],
      ),
    );
  }
}

/// A planned rest day: permission, and one question about switching off.
class _RestCard extends StatelessWidget {
  final DateTime day;
  const _RestCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final r = system.restOn(day)!;
    final level = system.detachmentOn(day);
    return OnoCard(
      accent: AppColors.body,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              (PersonalSystemProvider.restKinds[r.str('kind')] ?? 'Rest')
                  .toUpperCase(),
              style: AppText.eyebrow(color: AppColors.body)),
          const SizedBox(height: 4),
          Text('Rest is part of the plan. Your streak is safe today.',
              style: AppText.heading()),
          if (r.text.isNotEmpty) Text(r.text, style: AppText.small()),
          const SizedBox(height: 10),
          Text('Did you switch off from work?', style: AppText.small()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final (i, label)
                  in const ['Not really', 'Partly', 'Fully'].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: level == i + 1,
                  showCheckmark: false,
                  onSelected: (_) => system.logDetachment(day, i + 1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _planOpenKey = 'today:plan_open';

/// "Your plan": goals, growth, the week, meetings and inputs, collapsed to
/// one summary line until opened. Today remembers the choice.
class _PlanToggle extends StatelessWidget {
  final DateTime now;
  const _PlanToggle({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final open = system.isDone(_planOpenKey);
    final (done, set) = system.weekOutcomeScore(now);
    final meetings = system
        .meetingsFor(now)
        .where(PersonalSystemProvider.isRealMeeting)
        .length;
    final summary = [
      if (system.activeGoals.isNotEmpty)
        '${system.activeGoals.length} goal${system.activeGoals.length == 1 ? '' : 's'}',
      if (system.focusArea() != null) system.focusArea()!.name,
      if (set > 0) 'week $done/$set',
      if (meetings > 0) '$meetings meeting${meetings == 1 ? '' : 's'}',
    ].join(' · ');
    // While folded, the one thing the plan asks next stays in view.
    String? next;
    if (!open) {
      final outcomes = system.weekOutcomes(now);
      for (final (i, o) in outcomes.indexed) {
        if (o.trim().isNotEmpty && !system.weekOutcomeDone(now, i)) {
          next = 'Next: $o';
          break;
        }
      }
      final area = system.focusArea();
      if (next == null && area != null) {
        final drill = system.drillFor(area, now);
        final reps = system.drillRepsThisWeek(area, drill, now);
        if (reps < PersonalSystemProvider.repsPerDrill) {
          next = 'Practice: ${drill.title} · $reps of ${PersonalSystemProvider.repsPerDrill} this week';
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: OnoCard(
        key: const Key('plan-toggle'),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        onTap: () => system.setDone(_planOpenKey, !open),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR PLAN', style: AppText.eyebrow()),
                  const SizedBox(height: 2),
                  Text(
                      summary.isEmpty
                          ? 'Goals, growth, the week, inputs'
                          : summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(color: AppColors.white)),
                  if (next != null) ...[
                    const SizedBox(height: 2),
                    Text(next,
                        key: const Key('plan-next'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small(color: AppColors.accent)),
                  ],
                ],
              ),
            ),
            Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}

/// The active goals, compact: everything else on Today serves these.
class _GoalsCard extends StatelessWidget {
  const _GoalsCard();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final goals = system.activeGoals;
    if (goals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Goals',
            action: 'All', onAction: () => context.push('/goals')),
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GoalTile(goal: g, compact: true),
          ),
      ],
    );
  }
}

/// What he is growing this month and this week's drill. Development is
/// the main thread; the job is where it's practised.
class _GrowthCard extends StatelessWidget {
  final DateTime now;
  const _GrowthCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final area = system.focusArea();
    if (area == null) return const SizedBox.shrink();
    final drill = system.drillFor(area, now);
    final reps = system.repsIn(area.id, system.programMonth).length;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        accent: AppColors.accent,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        onTap: () => context.push('/growth'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GROWING · ${area.name.toUpperCase()}',
                style: AppText.eyebrow(color: AppColors.accent)),
            const SizedBox(height: 6),
            Text(drill.title, style: AppText.heading()),
            const SizedBox(height: 2),
            Text(drill.how,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.small()),
            const SizedBox(height: 8),
            Text(
                reps == 0
                    ? 'No reps yet this month — do it once, then reflect.'
                    : '$reps rep${reps == 1 ? '' : 's'} this month',
                style: AppText.small(color: AppColors.body)),
          ],
        ),
      ),
    );
  }
}

/// This week's Big 3, tickable from Today; a prompt to set them if empty.
class _WeekCard extends StatelessWidget {
  final DateTime now;
  const _WeekCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final outcomes = system.weekOutcomes(now);
    final (done, set) = system.weekOutcomeScore(now);
    if (set == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.flag_rounded,
            color: AppColors.accent,
            title: 'Set this week\'s Big 3',
            subtitle: 'Three outcomes that would make the week a win',
            onTap: () => context.push('/week'),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('This week · $done/$set',
            action: 'Edit', onAction: () => context.push('/week')),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                if (outcomes[i].trim().isNotEmpty)
                  CheckRow(
                    checked: system.weekOutcomeDone(now, i),
                    title: outcomes[i],
                    onChanged: (_) => system.toggleWeekOutcome(now, i),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Today's real meetings from the iPhone calendar, with the prep each needs.
class _MeetingsCard extends StatelessWidget {
  final DateTime now;
  const _MeetingsCard({required this.now});

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final all = system
        .meetingsFor(now)
        .where(PersonalSystemProvider.isRealMeeting)
        .toList();
    final ahead = all.where((m) => m.end.isAfter(now)).toList();
    final debriefs = system.debriefsDue(now);
    final free = system.freeBlocks(now, minMinutes: 60);
    if (ahead.isEmpty && debriefs.isEmpty && free.isEmpty) {
      return const SizedBox.shrink();
    }
    final hours = system.meetingHours(now);
    final notes = [
      all.isEmpty
          ? 'No meetings today'
          : '${all.length} meeting${all.length == 1 ? '' : 's'} · ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} h',
      if (system.lunchReadAtRisk(now))
        'one covers the 12:00 read — move the read, don\'t drop it',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Meetings'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(notes.join(' · '),
              style: AppText.small(
                  color:
                      notes.length > 1 ? AppColors.warning : AppColors.grey)),
        ),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          child: Column(
            children: [
              for (final m in debriefs.take(1))
                _MeetingRow(
                    time: 'Debrief',
                    title: m.title,
                    keyMeeting: true,
                    now: true,
                    action: 'Log',
                    route: '/cockpit'),
              for (final b in free.take(1))
                _MeetingRow(
                    time: '${_hm(b.start)}–${_hm(b.end)}',
                    title: 'Free — deep work block',
                    keyMeeting: false,
                    now: false,
                    action: 'Focus',
                    route: '/focus'),
              for (final m in ahead.take(4))
                _MeetingRow(
                    time: '${_hm(m.start)}–${_hm(m.end)}',
                    title: m.title,
                    keyMeeting: PersonalSystemProvider.isKeyMeeting(m),
                    now: !m.start.isAfter(now)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeetingRow extends StatelessWidget {
  final String time;
  final String title;
  final bool keyMeeting;
  final bool now;
  final String? action;
  final String? route;
  const _MeetingRow(
      {required this.time,
      required this.title,
      required this.keyMeeting,
      required this.now,
      this.action,
      this.route});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(now ? 'Now' : time,
              style: AppText.small(
                  color: now ? AppColors.accent : AppColors.grey)),
        ),
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                  color: keyMeeting ? AppColors.white : AppColors.greyLight)),
        ),
        TextButton(
          onPressed: () =>
              context.push(route ?? (keyMeeting ? '/tool/sixq' : '/tool/sigh')),
          child: Text(action ?? (keyMeeting ? '6 Qs' : 'Sigh')),
        ),
      ],
    );
  }
}

/// What's waiting on you: decisions to review, 1:1 follow-ups, and the
/// monthly habit and readiness checks.
class _Prompts extends StatefulWidget {
  final DateTime now;
  const _Prompts({required this.now});

  @override
  State<_Prompts> createState() => _PromptsState();
}

class _PromptsState extends State<_Prompts> {
  bool _all = false;

  /// At most this many prompts show before "more": one or two clear next
  /// steps beat a wall of cards (choice overload drives people away).
  static const _visible = 2;

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final system = context.watch<PersonalSystemProvider>();
    final reviews = system.dueDecisionReviews(now);
    final followUps = system.openFollowUps;
    final first = system.firstWeekStep;
    // Ranked: direction first, then what is due, then the rest.
    final setup = <Widget>[
      if (system.planBuildSuggested &&
          !_snoozed(system, 'plan'))
        _setupRow(
            context,
            system,
            'plan',
            Icons.auto_awesome_outlined,
            AppColors.accent,
            'Build your plan in 5 minutes',
            'Who you are becoming, one goal, a few daily actions',
            '/start'),
      if (system.activeGoals.isEmpty && !system.planBuildSuggested &&
          !_snoozed(system, 'goal'))
        _setupRow(
            context,
            system,
            'goal',
            Icons.flag_circle_outlined,
            AppColors.accent,
            'Set your first goal',
            'The outcome everything else here serves',
            '/goals'),
      if (system.focusArea() == null &&
          !_snoozed(system, 'area'))
        _setupRow(
            context,
            system,
            'area',
            Icons.trending_up_rounded,
            AppColors.accent,
            'What are you growing this month?',
            'Suggested: ${system.suggestedArea.name}',
            '/growth'),
      if (!system.isBuiltInPerson &&
          system.dayShape == null &&
          system.programDay >= 2 &&
          !_snoozed(system, 'day'))
        _setupRow(context, system, 'day', Icons.schedule_rounded, AppColors.mind, 'Shape your day',
            system.remindersSupported
                ? 'Wake, work, bed — your dial and reminders follow it'
                : 'Wake, work, bed — your day dial follows it',
            '/day'),
      if (system.values.isEmpty &&
          system.programDay >= 7 &&
          system.programDay <= 30 &&
          !_snoozed(system, 'values'))
        _setupRow(
            context,
            system,
            'values',
            Icons.diamond_outlined,
            AppColors.mind,
            'What do you stand for?',
            'Name three to five values — decisions and your brief use them',
            '/values'),
    ];
    final cards = <Widget>[
      // The first week: one small step a day, ahead of everything else.
      if (first != null)
        _row(
            context,
            Icons.wb_sunny_outlined,
            AppColors.accent,
            'First week · ${first.title}',
            '${first.why} (${system.firstWeekProgress} of ${PersonalSystemProvider.firstWeekSteps.length} done)',
            first.route),
      if (system.programComplete)
        _row(
            context,
            Icons.flag_circle_rounded,
            AppColors.accent,
            'Program ${system.cycle} is complete',
            'Look back, then start the next — everything stays',
            '/next-program'),
      // Dated things first: they only matter today.
      for (final b in system.birthdaysSoon(now).take(1))
        _row(
            context,
            Icons.cake_outlined,
            AppColors.social,
            system.birthdayOf(b) == (now.month, now.day)
                ? 'It\'s ${b.text}\'s birthday today'
                : '${b.text}\'s birthday is tomorrow',
            system.askAboutOf(b).isEmpty
                ? 'A message in your own words beats a reminder app\'s'
                : 'Ask about ${system.askAboutOf(b)}',
            '/people?id=${b.id}'),
      if (system.conversationsDue(now).firstOrNull case final c?)
        _row(
            context,
            Icons.forum_outlined,
            AppColors.social,
            'The conversation with ${c.str('with')}',
            'Have it today, or debrief it if it happened',
            '/conversations'),
      if (system.promisesDue(now).firstOrNull case final p?)
        _row(
            context,
            Icons.handshake_outlined,
            AppColors.social,
            '${system.promiseOverdue(p) ? 'A promise is past its date' : 'A promise is due today'}${(p.str('to') ?? '').isEmpty ? '' : ' · ${p.str('to')}'}',
            system.promiseOverdue(p)
                ? '${p.text} — kept late, or missed? Say it, then make it right'
                : '${p.text} — keep it, or say a new date now',
            '/promises'),
      if (system.worryTimeDue(now))
        _row(
            context,
            Icons.local_parking_rounded,
            AppColors.mind,
            'Worry time',
            '${system.worriesDue(now).length} parked — a next step or let go',
            '/worry'),
      // Then at most one set-up step a day; each can wait a week.
      ...setup.take(1),
      if (reviews.isNotEmpty)
        _row(
            context,
            Icons.balance_rounded,
            AppColors.accent,
            'Decision review due',
            '"${reviews.first.text}" — was the call right?',
            '/cockpit?tab=1'),
      if (system.monthReviewDue)
        _row(
            context,
            Icons.fact_check_outlined,
            AppColors.accent,
            'Close month ${system.monthToReview}',
            'Ten minutes: what held, one lesson, what comes with you',
            system.isBuiltInPerson
                ? '/month/${system.monthToReview}'
                : '/month-review'),
      if (system.upkeepDue
              .where((u) => system.upkeepNextDue(u) != null)
              .firstOrNull
          case final u?)
        _row(
            context,
            Icons.health_and_safety_outlined,
            AppColors.body,
            '${u.text} is due',
            'Book it this week — it only takes a call',
            '/upkeep'),
      if (system.moneyCheckDue)
        _row(context, Icons.savings_outlined, AppColors.body, 'Money check-in',
            'Ten minutes: in, out, set aside, one decision', '/money'),
      if (system.goalsToReflect.firstOrNull case final g?)
        _row(
            context,
            Icons.emoji_events_outlined,
            AppColors.accent,
            g.str('status') == 'achieved'
                ? 'You reached "${g.text}"'
                : 'Look back at "${g.text}"',
            'Two minutes: what made the difference',
            '/goals/view?id=${g.id}'),
      if (system.lastWeekReportDue)
        _row(context, Icons.assignment_outlined, AppColors.accent,
            'Close last week',
            'Five answers — then this week gets its brief', '/weekly-coaching'),
      if (system.yearReviewDue)
        _row(
            context,
            Icons.celebration_outlined,
            AppColors.accent,
            'Close ${system.yearToReview}',
            'Twenty minutes: what the year added up to, and one word for the next',
            '/year'),
      if (system.asksToClose.firstOrNull case final a?)
        _row(
            context,
            Icons.pan_tool_alt_outlined,
            AppColors.social,
            'Did ${(a.str('of') ?? '').isEmpty ? 'they' : a.str('of')} say yes?',
            '${a.text} — note the answer',
            '/asks'),
      if (system.kindnessDue(now))
        _row(
            context,
            Icons.volunteer_activism_outlined,
            AppColors.social,
            'Kindness day',
            '${system.kindnessOn(now).length} of ${PersonalSystemProvider.kindnessPerDay} kind acts today',
            '/kindness'),
      if (system.partnerCheckinDue)
        _row(
            context,
            Icons.handshake_outlined,
            AppColors.social,
            'Check in with ${system.partner!.text.split(' ').first}',
            'Send your update, record how you both did',
            '/partner'),
      if (system.roundDue)
        _row(
            context,
            Icons.groups_2_outlined,
            AppColors.social,
            'Ask three people one question',
            'Your quarterly feedback round — 5 minutes to send',
            '/360'),
      if (system.quarterReviewDue)
        _row(
            context,
            Icons.donut_large_rounded,
            AppColors.accent,
            'Quarterly review',
            'Quarter ${system.quarterToReview} ends — 15 minutes to look at your whole life',
            '/quarter'),
      if (system.noteDue(now))
        _row(
            context,
            Icons.send_rounded,
            AppColors.social,
            'Send your progress note',
            'Five lines to ${activeProfile.manager.isEmpty ? 'one person' : activeProfile.manager} — written for you from this week',
            '/note'),
      for (final e in system.experimentsToClose.take(1))
        _row(context, Icons.science_outlined, AppColors.mind,
            'Experiment finished: keep or drop?', e.text, '/experiments'),
      for (final l in system.experimentsToReview.take(1))
        _row(
            context,
            Icons.science_outlined,
            AppColors.skill,
            'How did the experiment go?',
            l.str('experiment') ?? '',
            '/learning'),
      for (final g in system.goalsAtDecision.take(1))
        _row(
            context,
            Icons.flag_circle_outlined,
            AppColors.accent,
            system.goalPace(g) == 'reached'
                ? 'Target reached: ${g.text}'
                : '${g.text} has reached its date',
            system.goalPace(g) == 'reached'
                ? 'Close it as achieved, and write down what made it happen'
                : 'Achieved, a new date, or drop it on purpose',
            '/goals/view?id=${g.id}'),
      for (final g in system.goalsToMeasure.take(1))
        _row(
            context,
            Icons.straighten_rounded,
            AppColors.accent,
            'Measure: ${g.text}',
            '${system.daysSinceGoalUpdate(g)} days since the last number',
            '/goals/view?id=${g.id}'),
      for (final c in system.commitmentsDue(now).take(1))
        _row(
            context,
            Icons.handshake_outlined,
            AppColors.accent,
            'You committed: ${c.str('will')}',
            'Kept it, or drop it on purpose?',
            '/coach'),
      if (now.weekday == DateTime.sunday &&
          system.values.isNotEmpty &&
          system.valuesCheck(now).isEmpty)
        _row(
            context,
            Icons.diamond_outlined,
            AppColors.mind,
            'Did this week reflect your values?',
            '${system.values.map((v) => v.name).join(' · ')} · 1 minute',
            '/values'),
      if (system.lettersToOpen.isNotEmpty)
        _row(
            context,
            Icons.mark_email_unread_outlined,
            AppColors.accent,
            'A letter is ready to open',
            'Written to you in month ${system.lettersToOpen.first.number('month') ?? '–'}. Read it today.',
            '/letters'),
      if (system.peopleDue.firstOrNull case final p?)
        _row(
            context,
            Icons.group_outlined,
            AppColors.social,
            'Reach out: ${p.text}${system.ritualOf(p).isEmpty ? '' : ' — ${system.ritualOf(p)}'}',
            system.askAboutOf(p).isNotEmpty
                ? 'Ask about ${system.askAboutOf(p)}'
                : '${system.lastContact(p) == null ? 'No contact logged yet' : '${system.daysSinceContact(p)} days since you were in touch'} · every ${system.cadenceOf(p)} days',
            '/people?id=${p.id}'),
      if (system.automaticityDue)
        _row(context, Icons.autorenew_rounded, AppColors.body,
            'Is it a habit yet?', 'Monthly check · 1 minute', '/habits'),
      if (system.isBuiltInPerson &&
          system.dayOfMonth >= 25 &&
          system.readinessDueThisMonth)
        _row(
            context,
            Icons.trending_up_rounded,
            AppColors.skill,
            '${activeProfile.targetRole} readiness',
            'Rate this month against the bar',
            '/cockpit?tab=2'),
    ];
    return Column(
      children: [
        for (final c in _all ? cards : cards.take(_visible)) ...[
          const SizedBox(height: 12),
          c
        ],
        if (cards.length > _visible || followUps.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('prompts-more'),
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all
                  ? 'Show less'
                  : '${(cards.length - _visible).clamp(0, 99) + (followUps.isEmpty ? 0 : 1)} more for today'),
            ),
          ),
        if (followUps.isNotEmpty && _all) ...[
          const SizedBox(height: 12),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('YOUR 1:1 FOLLOW-UPS · ${followUps.length}',
                          style: AppText.eyebrow()),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/cockpit'),
                      child: Text('All',
                          style: AppText.small(color: AppColors.accent)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                for (final f in followUps.take(3))
                  CheckRow(
                    checked: false,
                    title: f.text,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onChanged: (_) => system.setDone(f.key, true),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _snoozeKey(String id, DateTime now) =>
      'snooze:$id:${dateKey(weekStartOf(now))}';

  bool _snoozed(PersonalSystemProvider system, String id) =>
      system.isDone(_snoozeKey(id, widget.now));

  /// A set-up step with "Not now": it comes back next week.
  Widget _setupRow(BuildContext context, PersonalSystemProvider system,
          String id, IconData icon, Color color, String title, String body,
          String route) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _row(context, icon, color, title, body, route),
          TextButton(
            key: Key('snooze-$id'),
            onPressed: () => system.setDone(_snoozeKey(id, widget.now), true),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Not now', style: AppText.small()),
          ),
        ],
      );

  Widget _row(BuildContext context, IconData icon, Color color, String title,
          String body, String route) =>
      OnoCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        onTap: route.isEmpty ? null : () => context.push(route),
        child: Row(
          children: [
            IconTile(icon, color: color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading()),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small()),
                ],
              ),
            ),
            if (route.isNotEmpty)
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
          ],
        ),
      );
}

/// Never miss twice: yesterday slipped, today decides.
class _RecoveryCard extends StatelessWidget {
  final int yesterdayScore;
  final int streak;
  final VoidCallback onFillYesterday;
  const _RecoveryCard(
      {required this.yesterdayScore,
      required this.streak,
      required this.onFillYesterday});

  @override
  Widget build(BuildContext context) {
    return OnoCard(
      accent: AppColors.warning,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECOVERY DAY',
              style: AppText.eyebrow(color: AppColors.warning)),
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final system = context.read<PersonalSystemProvider>();
            final now = DateTime.now();
            final was = system.itemIdsOn(dayOnly(now).minusDays(1)).length;
            final hold = system.targetFor(now);
            return Text(
                streak > 0
                    ? 'Yesterday slipped ($yesterdayScore/$was). Hold $hold today and your $streak-day streak carries on.'
                    : 'Yesterday slipped ($yesterdayScore/$was). Hold $hold today to start again.',
                style: AppText.heading().copyWith(fontSize: 15.5));
          }),
          const SizedBox(height: 4),
          Text(
              'One miss is noise. Two in a row is a pattern — never miss twice.',
              style: AppText.small()),
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                key: const Key('fill-yesterday'),
                onPressed: onFillYesterday,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Did it but forgot to tick?'),
              ),
              TextButton(
                onPressed: () => context.push('/setback'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Reset in 3 minutes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fifteen-second morning check-in; afterwards, today's adjustment.
class _CheckinCard extends StatelessWidget {
  final DateTime now;
  const _CheckinCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = dayOnly(now);
    final c = system.checkinFor(today);
    if (c == null) {
      if (now.hour >= 14) return const SizedBox.shrink();
      // Before 10:30 the morning card above already asks anyone but the
      // built-in person to check in; don't ask twice.
      if (!system.isBuiltInPerson &&
          now.hour * 60 + now.minute < 10 * 60 + 30) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          onTap: () => context.push('/checkin'),
          child: Row(
            children: [
              const IconTile(Icons.wb_twilight_rounded,
                  color: AppColors.body, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning check-in', style: AppText.heading()),
                    Text(
                        system.isBuiltInPerson
                            ? 'Energy, mood, sleep, shoulders · 30 s'
                            : 'Energy, mood, sleep · 30 s',
                        style: AppText.small()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
            ],
          ),
        ),
      );
    }
    // A low morning changes what today asks: scaling the plan down keeps
    // the habit through bad days.
    final energy = c.number('energy')?.toInt();
    final sleep = c.number('sleep')?.toDouble();
    final low = (energy != null && energy <= 2) || (sleep != null && sleep > 0 && sleep < 6);
    final lowKey = 'lowday:${dateKey(today)}';
    if (low &&
        system.hardDayOn(today) == null &&
        !system.isExcused(today) &&
        !system.isDone(lowKey)) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OnoCard(
          key: const Key('low-morning'),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A low morning', style: AppText.heading()),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                    '${energy != null && energy <= 2 ? 'Energy $energy/5' : 'Under 6 hours of sleep'}. Make today a minimum day? ${system.minimumTarget} of ${system.dailyCount} counts, smallest versions are fine.',
                    style: AppText.small()),
              ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => system.setHardDay(today, 'minimum'),
                    child: const Text('Make it a minimum day'),
                  ),
                  TextButton(
                    onPressed: () => system.setDone(lowKey, true),
                    child: const Text('Full plan today'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (!system.shoulderFlag(today)) return const SizedBox.shrink();
    final gym = system.gymDayOn(today);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        accent: AppColors.warning,
        padding: const EdgeInsets.all(14),
        onTap: gym == null ? null : () => context.push('/gym'),
        child: Text(
            gym == null
                ? 'Shoulders flagged this morning. Keep pressing and overhead work off the menu today.'
                : 'Shoulder-sparing day: Day ${gym.letter} swaps presses, flyes and pulldowns for legs and trunk work.',
            style: AppText.small(color: AppColors.greyLight)),
      ),
    );
  }
}

class _BriefCard extends StatelessWidget {
  final WeeklyBrief brief;
  const _BriefCard({required this.brief});

  @override
  Widget build(BuildContext context) {
    final (outDone, outSet) =
        context.watch<PersonalSystemProvider>().weekOutcomeScore(DateTime.now());
    return OnoCard(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('THIS WEEK\'S BRIEF',
                  style: AppText.eyebrow(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          Text(brief.headline, style: AppText.heading()),
          const SizedBox(height: 4),
          // The brief's ideas, not a second checklist: what's ticked is the
          // week's three.
          for (final t in brief.tasks.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('• $t', style: AppText.small(color: AppColors.white)),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () {
                  context.read<PersonalSystemProvider>()
                      .setDone('brief:seen:${brief.id}', true);
                  context.push('/week');
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(outSet == 0
                    ? 'Plan the week\'s three →'
                    : 'The week\'s three: $outDone of $outSet →'),
              ),
              TextButton(
                onPressed: () {
                  context.read<PersonalSystemProvider>()
                      .setDone('brief:seen:${brief.id}', true);
                  context.push('/weekly-coaching');
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('The full brief →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyTen extends StatelessWidget {
  final DateTime date;
  const _DailyTen({required this.date});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final score = system.scoreFor(date);
    final target = system.targetFor(date);
    final minimum = system.isMinimumDay(date);
    final excused = system.isExcused(date);
    final automatic = system.automaticItems;
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TickSegments(
              total: system.dailyCount,
              filled: system.dailyCount,
              height: 6,
              colors: [
                for (final n in system.dailyItems)
                  system.isChecked(date, n.id)
                      ? AppColors.lane(n.lane)
                      : AppColors.cardLight
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
              excused
                  ? '$score of ${system.itemIdsOn(date).length} · nothing is expected today'
                  : score >= target
                      ? '$score of ${system.itemIdsOn(date).length} — today counts'
                      : '$score of ${system.itemIdsOn(date).length} done${minimum ? ' · a minimum day: $target counts' : ''}',
              style: AppText.small()),
          for (final g in nonNegotiableGroups)
            if (system.dailyItems
                .any((n) => n.when == g[0] && !automatic.contains(n.id))) ...[
              const SizedBox(height: 14),
              Text(g[1].toUpperCase(), style: AppText.eyebrow()),
              for (final n in system.dailyItems
                  .where((n) => n.when == g[0] && !automatic.contains(n.id)))
                CheckRow(
                  checked: system.isChecked(date, n.id),
                  title: n.title,
                  subtitle: system.isChecked(date, n.id)
                      ? null
                      : minimum && system.minimumFor(n.id).isNotEmpty
                          ? 'Minimum: ${system.minimumFor(n.id)}'
                          : system.cueFor(n.id),
                  lane: n.lane,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  onChanged: (_) => system.toggleCheck(date, n.id),
                  onOpen: n.route == null ? null : () => context.push(n.route!),
                ),
            ],
          if (automatic.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('AUTOMATIC · NO REMINDERS',
                style: AppText.eyebrow(color: AppColors.body)),
            for (final n
                in system.dailyItems.where((n) => automatic.contains(n.id)))
              CheckRow(
                checked: system.isChecked(date, n.id),
                title: n.title,
                lane: n.lane,
                padding: const EdgeInsets.symmetric(vertical: 7),
                onChanged: (_) => system.toggleCheck(date, n.id),
              ),
          ],
          // Not on the first days: there's nothing to be hard yet.
          if (system.hasStarted &&
              system.hardDayOn(date) == null &&
              (system.programDay >= 3 || DateTime.now().hour >= 17))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showHardDaySheet(context, date),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(dayOnly(date) == dayOnly(DateTime.now())
                    ? 'Hard day? Choose how today counts'
                    : 'Was it a hard day? Choose how it counts'),
              ),
            ),
        ],
      ),
    );
  }
}

/// How a hard day counts: the smallest version, sick, or an emergency skip.
Future<void> showHardDaySheet(BuildContext context, DateTime date) {
  final system = context.read<PersonalSystemProvider>();
  Widget option(String kind, IconData icon, String title, String body,
          {bool enabled = true}) =>
      ListTile(
        enabled: enabled,
        contentPadding: EdgeInsets.zero,
        leading:
            Icon(icon, color: enabled ? AppColors.accent : AppColors.faint),
        title: Text(title, style: AppText.heading()),
        subtitle: Text(body, style: AppText.small()),
        onTap: () {
          // The sheet sits above the tabs, on the root navigator.
          Navigator.of(context, rootNavigator: true).pop();
          if (!system.setHardDay(date, kind)) {
            toast(context, 'No emergency skips left this month.');
          }
        },
      );
  return showModalBottomSheet<void>(
      useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Some days the plan can\'t happen', style: AppText.title()),
            const SizedBox(height: 4),
            Text(
                'That\'s part of any plan worth keeping. Pick what fits today — what matters is coming back tomorrow.',
                style: AppText.small()),
            const SizedBox(height: 10),
            option('minimum', Icons.compress_rounded, 'Minimum day',
                'Swamped or low. Do the smallest version of each item; ${system.minimumTarget} of ${system.itemIdsOn(date).length} holds the day.'),
            option('sick', Icons.healing_outlined, 'Sick day',
                'Rest is the plan. Nothing is expected; your streak waits for you.'),
            option('pass', Icons.flash_on_outlined, 'Emergency skip',
                'Something you couldn\'t plan for. ${system.passesLeft} of ${system.passesPerMonth} left this month; your streak waits.',
                enabled: system.passesLeft > 0),
          ],
        ),
      ),
    ),
  );
}

class _HardDayCard extends StatelessWidget {
  final DateTime date;
  const _HardDayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final kind = system.hardDayOn(date);
    final sickRun = system.sickDaysInRow(date);
    final (title, body) = switch (kind) {
      'minimum' => (
          'Minimum day',
          'The smallest version of each item counts. ${system.targetFor(date)} of ${system.itemIdsOn(date).length} holds the day — showing up is the point.'
        ),
      'sick' => (
          'Sick day — rest is the plan',
          sickRun >= PersonalSystemProvider.pauseAfterSickDays
              ? 'Day $sickRun. The program clock is paused while you recover — your day ${system.programDay} waits for you. If it isn\'t getting better, see a doctor.'
              : sickRun >= 3
                  ? 'Day $sickRun. Nothing is expected. If it isn\'t getting better, see a doctor. Your streak waits.'
                  : 'Nothing is expected today. Sleep, water, rest. Your streak waits for you.'
        ),
      'pass' => (
          'Emergency skip',
          'Today is set aside. ${system.passesLeft} left this month. Tomorrow, start with the first item.'
        ),
      _ => (
          'Welcome back',
          'First day back counts on the minimum: ${system.targetFor(date)} of ${system.itemIdsOn(date).length}, smallest versions are fine. Full plan from tomorrow.'
        ),
    };
    return OnoCard(
      accent: kind == 'sick' ? AppColors.body : AppColors.accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heading()),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(body, style: AppText.small()),
          ),
          if (kind != null)
            TextButton(
              onPressed: () => system.setHardDay(date, null),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Undo — it\'s a normal day'),
            ),
          if (kind == null) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Priorities extends StatefulWidget {
  final DateTime date;
  final bool review;
  const _Priorities({super.key, required this.date, required this.review});

  @override
  State<_Priorities> createState() => _PrioritiesState();
}

class _PrioritiesState extends State<_Priorities> {
  late final List<TextEditingController> _c;
  final _focus = List.generate(3, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalSystemProvider>().prioritiesFor(widget.date);
    _c = List.generate(3, (i) => TextEditingController(text: p[i]));
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = system.prioritiesFor(widget.date);
    // A priority set elsewhere (a setback's next step, a worry acted on,
    // another device) shows here — unless they are typing in that field.
    for (var i = 0; i < 3; i++) {
      if (!_focus[i].hasFocus && _c[i].text != p[i]) _c[i].text = p[i];
    }
    final anySet = p.any((x) => x.isNotEmpty);
    if (widget.review && anySet) {
      return OnoCard(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              if (p[i].isNotEmpty)
                CheckRow(
                  checked: system.priorityDone(widget.date, i),
                  title: p[i],
                  onChanged: (_) => system.togglePriority(widget.date, i),
                ),
          ],
        ),
      );
    }
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outcomes, not tasks. What must be true by tonight?',
              style: AppText.small()),
          for (var i = 0; i < 3; i++)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: AppText.serif(size: 20, color: AppColors.accent)),
                ),
                Expanded(
                  child: TextField(
                    controller: _c[i],
                    focusNode: _focus[i],
                    style: AppText.body(color: AppColors.white),
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => system.setPriority(widget.date, i, v),
                    decoration: InputDecoration(
                      hintText: const [
                        'The outcome that matters most',
                        'Second outcome',
                        'Third outcome'
                      ][i],
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Inputs for someone with their own plan: review, deep work, movement
/// and what they are learning.
class _GeneralInputs extends StatelessWidget {
  final DateTime date;
  const _GeneralInputs({required this.date});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final due = system.dueCards(date).length;
    final focusH = system.focusMinutesInWeek(date) / 60;
    final moved = system.moveMinutesInWeek(date);
    final learning = system.learningWith('active');
    final tiles = [
      (
        Icons.style_rounded,
        AppColors.mind,
        'Review',
        due == 0 ? 'All caught up' : '$due cards due',
        'Your lessons, spaced · 5 min',
        '/review'
      ),
      (
        Icons.center_focus_strong_rounded,
        AppColors.skill,
        'Deep work',
        system.focusArea()?.name ?? 'One block, one thing',
        '${focusH.toStringAsFixed(focusH % 1 == 0 ? 0 : 1)} h this week',
        '/focus'
      ),
      (
        Icons.directions_walk_rounded,
        AppColors.body,
        'Move',
        '$moved of 150 min',
        '${system.strengthDaysInWeek(date)} of 2 strength days',
        '/move'
      ),
      (
        Icons.school_outlined,
        AppColors.skill,
        'Learning',
        learning.isEmpty ? 'Nothing active' : learning.first.text,
        'Learn it, then apply it',
        '/learning'
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                for (final t in tiles.sublist(i, i + 2)) ...[
                  Expanded(
                    child: OnoCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.push(t.$6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(t.$1, size: 18, color: t.$2),
                              const SizedBox(width: 6),
                              Text(t.$3.toUpperCase(),
                                  style:
                                      AppText.eyebrow().copyWith(fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(t.$4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.heading().copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(t.$5,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.small()),
                        ],
                      ),
                    ),
                  ),
                  if (t == tiles[i]) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InputsStrip extends StatelessWidget {
  final DateTime date;
  final int month;
  const _InputsStrip({required this.date, required this.month});

  @override
  Widget build(BuildContext context) {
    final podcast = podcastFor(date);
    final scan = domainScanFor(date);
    final book = currentBook(month);
    final outfit = outfitFor(date);
    final system = context.watch<PersonalSystemProvider>();
    final due = system.dueCards(date).length;
    final focusH = system.focusMinutesInWeek(date) / 60;
    final tiles = [
      (
        Icons.style_rounded,
        AppColors.mind,
        'Review',
        due == 0 ? 'All caught up' : '$due cards due',
        'Spaced repetition · 5 min',
        '/review' as String?
      ),
      (
        Icons.center_focus_strong_rounded,
        AppColors.skill,
        'Deep work',
        artifactFor(month),
        '${focusH.toStringAsFixed(focusH % 1 == 0 ? 0 : 1)} h this week',
        '/focus' as String?
      ),
      (
        Icons.podcasts_rounded,
        AppColors.skill,
        'Drive',
        podcast.title,
        podcast.detail,
        null as String?
      ),
      (
        Icons.travel_explore_rounded,
        AppColors.steel,
        'Scan · 07:45',
        scan.title,
        scan.detail,
        '/tool/scan'
      ),
      (
        Icons.menu_book_rounded,
        AppColors.mind,
        'Lunch read',
        book.title,
        book.chapters,
        '/tool/read'
      ),
      (
        outfit.icon,
        AppColors.social,
        'Wear',
        outfit.occasion,
        outfit.formula,
        '/style'
      ),
    ];
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = tiles[i];
          return SizedBox(
            width: 170,
            child: OnoCard(
              padding: const EdgeInsets.all(14),
              onTap: t.$6 == null ? null : () => context.push(t.$6!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(t.$1, size: 18, color: t.$2),
                      const SizedBox(width: 6),
                      Text(t.$3.toUpperCase(),
                          style: AppText.eyebrow().copyWith(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(t.$4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading().copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(t.$5,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  final DateTime date;
  const _BodyCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final protein = system.proteinFor(date);
    final weight = system.latestWeight;
    final weighedThisWeek =
        system.logsOf('weight').any((l) => !l.date.isBefore(weekStartOf(date)));
    final gym = system.gymDayOn(date);
    final sessions = system.gymSessionsInWeek(date);

    return OnoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile('$protein', 'protein today',
                    unit: '/150 g',
                    color: protein >= 150 ? AppColors.body : AppColors.white),
              ),
              Expanded(
                child: StatTile(
                    weight == null ? '—' : weight.toStringAsFixed(1),
                    'latest weight',
                    unit: 'kg'),
              ),
              Expanded(
                child: StatTile('$sessions', 'gym this week', unit: '/3'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ThinBar(
              value: protein / 150,
              color: protein >= 150 ? AppColors.body : AppColors.accent),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in [20, 30, 40])
                ActionChip(
                  label: Text('+$g g protein'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    system.addProtein(date, g);
                  },
                ),
              if (!weighedThisWeek)
                ActionChip(
                  avatar: const Icon(Icons.monitor_weight_outlined, size: 16),
                  label: const Text('Weigh-in'),
                  onPressed: () => context.push('/log?add=weight'),
                ),
              ActionChip(
                avatar: Icon(
                    system.gymDone(date)
                        ? Icons.check_rounded
                        : Icons.fitness_center_rounded,
                    size: 16),
                label: Text(gym == null
                    ? 'Extra session'
                    : system.gymDone(date)
                        ? 'Day ${gym.letter} logged'
                        : 'Day ${gym.letter} · ${gym.name}'),
                onPressed: () => context.push('/gym'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachNote extends StatefulWidget {
  final int day;
  const _CoachNote({required this.day});

  @override
  State<_CoachNote> createState() => _CoachNoteState();
}

/// One question a day, answered in a line, saved as a note.
class _QuestionCard extends StatefulWidget {
  const _QuestionCard();

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _answer = TextEditingController();
  String? _loadedFor;

  /// Loads today's answer whenever the question changes (e.g. past
  /// midnight with ONO open).
  void _sync(PersonalSystemProvider system) {
    final q = system.questionOfTheDay.$2;
    if (_loadedFor == q) return;
    _loadedFor = q;
    _answer.text = system.questionAnswer?.text ?? '';
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    _sync(system);
    final q = system.questionOfTheDay;
    return OnoCard(
      accent: AppColors.mind,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUESTION OF THE DAY',
              style: AppText.eyebrow(color: AppColors.mind)),
          const SizedBox(height: 8),
          Text(q.$2, style: AppText.serif(size: 22)),
          const SizedBox(height: 10),
          TextField(
            controller: _answer,
            minLines: 1,
            maxLines: 4,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'A line is enough'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (_answer.text.trim().isEmpty) {
                  toast(context, 'Write a line first.');
                  return;
                }
                system.answerQuestion(_answer.text);
                FocusManager.instance.primaryFocus?.unfocus();
                toast(context, 'Saved to your notes.');
              },
              child: Text(system.questionAnswer == null ? 'Save' : 'Update'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachNoteState extends State<_CoachNote> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tip = coachTipForDay(widget.day < 1 ? 1 : widget.day);
    return OnoCard(
      accent: AppColors.lane(tip.lane),
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.lane.toUpperCase(),
              style: AppText.eyebrow(color: AppColors.lane(tip.lane))),
          const SizedBox(height: 8),
          Text(tip.title, style: AppText.serif(size: 22)),
          const SizedBox(height: 8),
          Text(tip.content,
              maxLines: _open ? null : 2,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: AppText.body()),
          if (!_open)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Read',
                  style: AppText.small(color: AppColors.accent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

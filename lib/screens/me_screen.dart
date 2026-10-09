import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/auth_provider.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';

/// ME — who you are becoming, measured. Every figure comes from your own
/// check-offs and logs. Settings that actually do something.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.isLoaded) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    final today = dayOnly(DateTime.now());
    final weeks =
        ((today.difference(weekStartOf(system.programStart)).inDays) ~/ 7 + 1)
            .clamp(1, 26);
    final heatFrom =
        weekStartOf(today).subtract(Duration(days: (weeks - 1) * 7));
    final keyLifts = [
      'Dumbbell Shoulder Press',
      'Lat Pulldown',
      'Goblet Squat',
      'Romanian Deadlift',
      'Face Pulls',
    ];

    return OnoPage(
      eyebrow: EminIdentity.archetype,
      title: EminIdentity.name,
      subtitle: '${EminIdentity.role}\n${EminIdentity.company}',
      children: [
        const SizedBox(height: 20),
        OnoCard(
          color: AppColors.navy,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: StatTile(
                          system.hasStarted ? '${system.programDay}' : '0',
                          'day of $programDays')),
                  Expanded(child: StatTile('${system.streak}', 'streak')),
                  Expanded(
                      child: StatTile('${system.bestStreak}', 'best streak')),
                  Expanded(child: StatTile('${system.daysHeld}', 'days held')),
                ],
              ),
              const SizedBox(height: 16),
              ThinBar(
                  value:
                      system.hasStarted ? system.programDay / programDays : 0),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                      '${system.daysHeldThisMonth} held this month · one slip is forgiven',
                      style: AppText.small().copyWith(fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Month ${system.programMonth} · ${system.phase.name}',
                      style: AppText.small()),
                  const Spacer(),
                  Text(
                      'Ends ${shortDate(system.programStart.add(const Duration(days: programDays - 1)))}',
                      style: AppText.small()),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader('Every day so far'),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeatGrid(
                from: heatFrom,
                weeks: weeks < 8 ? 8 : weeks,
                scoreFor: (d) =>
                    d.isBefore(system.programStart) ? null : system.scoreFor(d),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Less', style: AppText.small().copyWith(fontSize: 11)),
                  const SizedBox(width: 6),
                  for (final s in [0, 3, 6, 8, 10])
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                          color: heatColor(s),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  Text('more · Daily 10',
                      style: AppText.small().copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader('Protocol mastery'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            children: [
              for (final p in protocols)
                InkWell(
                  onTap: () =>
                      context.push(protocolTools[p.id] ?? '/protocols'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(p.icon, size: 18, color: AppColors.lane(p.lane)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.name, style: AppText.body())),
                        Text('${system.usesOf(p.id)}',
                            style: AppText.small(color: AppColors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 86,
                          child: Text(system.masteryOf(p.id),
                              textAlign: TextAlign.right,
                              style: AppText.small(
                                  color: system.usesOf(p.id) >= 20
                                      ? AppColors.accent
                                      : AppColors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionHeader('Mornings',
            action: 'Check in', onAction: () => context.push('/checkin')),
        const _Mornings(),
        const _AppleHealth(),
        const _CalendarLink(),
        const SectionHeader('What moves your day'),
        const _Patterns(),
        const SectionHeader('Body'),
        OnoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                        system.latestWeight?.toStringAsFixed(1) ?? '—',
                        'kg now',
                        unit: 'kg'),
                  ),
                  Expanded(
                    child: StatTile(
                        system.startWeight == null ||
                                system.latestWeight == null
                            ? '—'
                            : (system.latestWeight! - system.startWeight!)
                                .toStringAsFixed(1),
                        'since Day 1'),
                  ),
                  Expanded(
                      child: StatTile('${system.countOf('gym')}', 'sessions')),
                ],
              ),
              const SizedBox(height: 14),
              for (final l in keyLifts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(l, style: AppText.small())),
                      Text(
                          system.bestLift(l) > 0
                              ? '${system.bestLift(l).toStringAsFixed(1)} kg'
                              : '—',
                          style: AppText.small(color: AppColors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader('Growth'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.flag_circle_outlined,
                color: AppColors.accent,
                title: 'Goals',
                subtitle: system.activeGoals.isEmpty
                    ? 'The outcomes everything else serves'
                    : system.activeGoals.map((g) => g.text).join(' · '),
                onTap: () => context.push('/goals'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.trending_up_rounded,
                color: AppColors.accent,
                title: 'Growth plan',
                subtitle: system.focusArea() == null
                    ? 'Choose this month\'s area'
                    : '${system.focusArea()!.name} · ${system.repsIn(system.focusArea()!.id, system.programMonth).length} reps this month',
                onTap: () => context.push('/growth'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.autorenew_rounded,
                color: AppColors.body,
                title: 'Is it a habit yet?',
                subtitle:
                    '${system.automaticItems.length} of ${nonNegotiables.length} automatic',
                onTap: () => context.push('/habits'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.trending_up_rounded,
                color: AppColors.skill,
                title: '${activeProfile.targetRole} readiness',
                subtitle: system.readiness.isEmpty
                    ? 'Not rated yet'
                    : system.readinessGap == null
                        ? 'At the bar on every dimension'
                        : 'Gap: ${system.readinessGap!.name}',
                onTap: () => context.push('/cockpit?tab=2'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.diamond_outlined,
                color: AppColors.mind,
                title: 'Your values',
                subtitle: system.values.isEmpty
                    ? 'Three to five, in your own words'
                    : system.values.map((v) => v.name).join(' · '),
                onTap: () => context.push('/values'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.send_rounded,
                color: AppColors.social,
                title: 'Progress note',
                subtitle: system.noteSentInWeek(DateTime.now())
                    ? 'Sent this week'
                    : 'Tell one person how the week went',
                onTap: () => context.push('/note'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.replay_rounded,
                color: AppColors.warning,
                title: 'It slipped — reset',
                subtitle: 'Kindness, facts, the smallest next step',
                onTap: () => context.push('/setback'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.psychology_alt_outlined,
                color: AppColors.mind,
                title: 'Think it through',
                subtitle: 'Coach yourself on a problem that keeps circling',
                onTap: () => context.push('/coach'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.group_outlined,
                color: AppColors.social,
                title: 'People',
                subtitle: system.people.isEmpty
                    ? 'Who you invest in, and how often'
                    : '${system.people.length} people · ${system.peopleDue.length} due',
                onTap: () => context.push('/people'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.center_focus_strong_rounded,
                color: AppColors.skill,
                title: 'Deep work',
                subtitle:
                    '${(system.focusMinutesInWeek(DateTime.now()) / 60).toStringAsFixed(1)} h this week · ${(system.artifactMinutesThisMonth / 60).toStringAsFixed(1)} h on the artifact this month',
                onTap: () => context.push('/focus'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.mail_outline_rounded,
                color: AppColors.accent,
                title: 'Letters to future you',
                subtitle: system.letters.isEmpty
                    ? 'Seal one for the next phase or day 540'
                    : '${system.letters.where((l) => !system.letterIsOpen(l)).length} sealed · ${system.letters.where(system.letterIsOpen).length} opened',
                onTap: () => context.push('/letters'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.style_rounded,
                color: AppColors.mind,
                title: 'Review deck',
                subtitle:
                    '${system.deckStats.total} cards · ${system.deckStats.mature} mature',
                onTap: () => context.push('/review'),
              ),
            ],
          ),
        ),
        const SectionHeader('Settings'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.event_rounded,
                color: AppColors.accent,
                title: 'Program start',
                subtitle:
                    '${weekdayName(system.programStart.weekday)} ${shortDate(system.programStart)} ${system.programStart.year}',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: system.programStart,
                    firstDate: today.subtract(const Duration(days: 540)),
                    lastDate: today.add(const Duration(days: 60)),
                  );
                  if (picked != null) system.setProgramStart(picked);
                },
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.fitness_center_rounded,
                color: AppColors.body,
                title: 'Gym days',
                subtitle: [
                  for (var i = 0; i < 3; i++)
                    '${gymPlan[i].letter} ${weekdayName(system.gymDays[i]).substring(0, 3)}'
                ].join(' · '),
                onTap: () => _gymDaysSheet(context, system),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.notifications_none_rounded,
                color: AppColors.mind,
                title: 'Reminders',
                subtitle:
                    '${reminderDefs.where((r) => system.reminderOn(r.id)).length} of ${reminderDefs.length} on',
                onTap: () => _remindersSheet(context),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.ios_share_rounded,
                color: AppColors.steel,
                title: 'Export backup',
                subtitle: 'Everything as a JSON file you keep',
                onTap: () async {
                  final json = system.exportJson();
                  try {
                    await Share.share(json,
                        subject: 'ONO backup ${dateKey(today)}');
                  } catch (_) {
                    if (context.mounted) {
                      await copyText(context, json,
                          message: 'Backup copied to clipboard');
                    }
                  }
                },
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.restore_rounded,
                color: AppColors.steel,
                title: 'Restore from clipboard',
                subtitle: 'Paste an exported backup',
                onTap: () => _restore(context, system),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.logout_rounded,
                color: AppColors.danger,
                title: 'Sign out',
                subtitle: 'Your data stays on this device',
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
            'Data is stored on this device. Export a backup before deleting the app or changing phones.',
            style: AppText.small()),
      ],
    );
  }

  Future<void> _restore(
      BuildContext context, PersonalSystemProvider system) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Replace all data?', style: AppText.title()),
        content: Text(
            'This overwrites everything with the backup on your clipboard (${text.length} characters).',
            style: AppText.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    toast(
        context,
        system.importJson(text)
            ? 'Backup restored.'
            : 'That isn\'t an ONO backup.');
  }

  void _gymDaysSheet(BuildContext context, PersonalSystemProvider system) {
    var days = List<int>.from(system.gymDays);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gym days', style: AppText.title()),
              const SizedBox(height: 14),
              for (var i = 0; i < 3; i++) ...[
                Text(
                    'DAY ${gymPlan[i].letter} · ${gymPlan[i].name.toUpperCase()}',
                    style: AppText.eyebrow()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      ChoiceChip(
                        label: Text(weekdayName(d).substring(0, 3)),
                        selected: days[i] == d,
                        onSelected: days.contains(d) && days[i] != d
                            ? null
                            : (_) => set(() => days[i] = d),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton('Save', onPressed: () {
                system.setGymDays(days);
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _remindersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer<PersonalSystemProvider>(
        builder: (ctx, system, _) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text('Reminders', style: AppText.title()),
              const SizedBox(height: 6),
              Text('Each opens the tool for that moment.',
                  style: AppText.small()),
              const SizedBox(height: 10),
              for (final r in reminderDefs)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: system.reminderOn(r.id),
                  onChanged: (v) => system.setReminder(r.id, v),
                  title: Text(r.label,
                      style: AppText.body(color: AppColors.white)
                          .copyWith(fontSize: 14.5)),
                  subtitle: Text(
                      r.id == 'gym'
                          ? '18:45 on gym days'
                          : '${r.timeLabel}${r.weekdays == null ? ' daily' : ' · ${r.weekdays!.map((d) => weekdayName(d).substring(0, 3)).join(', ')}'}',
                      style: AppText.small()),
                ),
              const SizedBox(height: 8),
              GhostButton('Allow notifications',
                  icon: Icons.notifications_active_outlined,
                  onPressed: () async {
                final ok = await system.requestReminderPermission();
                if (ctx.mounted) {
                  toast(ctx,
                      ok ? 'Notifications on.' : 'Enable in Settings › ONO.');
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last 7 days of check-ins: energy, sleep and shoulders, plus the pain
/// trend for 30 days — the log to bring to the rheumatologist.
/// Personal patterns from his own logs: days with a habit vs without.
class _Patterns extends StatelessWidget {
  const _Patterns();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final found = system.patterns();
    if (found.isEmpty) {
      return const EmptyNote(
          'Patterns show here once there are 5+ days with and without a habit: '
          'sleep vs your Daily 10, bedtime vs morning energy, caffeine vs sleep. '
          'Morning check-ins make them appear sooner.',
          icon: Icons.insights_rounded);
    }
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in found.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: Icon(
                        p.delta >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color:
                            p.delta >= 0 ? AppColors.body : AppColors.warning),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.habit} → ${p.outcome} ${p.fmt(p.withHabit)}',
                            style: AppText.body(color: AppColors.white)),
                        Text(
                            'vs ${p.fmt(p.without)} without · ${p.daysWith} vs ${p.daysWithout} days',
                            style: AppText.small().copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text('Last 60 days of your own logs. Patterns, not proof.',
              style:
                  AppText.small(color: AppColors.faint).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Mornings extends StatelessWidget {
  const _Mornings();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = DateTime.now();
    final week = system.checkinsEnding(today, 7);
    if (week.isEmpty) {
      return const EmptyNote(
          'No check-ins yet. Fifteen seconds each morning shows how sleep, energy and your shoulders move together.',
          icon: Icons.wb_twilight_rounded);
    }
    String avg(String key, int digits) {
      final v = system.averageOf(week, key);
      return v == null ? '—' : v.toStringAsFixed(digits);
    }

    final month = system.checkinsEnding(today, 30);
    final flags = system.flagDaysInWeekEnding(today);
    return OnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: StatTile(avg('energy', 1), 'energy', unit: '/5')),
              Expanded(child: StatTile(avg('sleep', 1), 'sleep', unit: 'h')),
              Expanded(
                  child:
                      StatTile(avg('pain', 1), 'shoulder pain', unit: '/10')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Averages of the last ${week.length} check-ins',
              style: AppText.small().copyWith(fontSize: 11.5)),
          if (month.length >= 2) ...[
            const SizedBox(height: 14),
            Text('SHOULDER PAIN · 30 DAYS', style: AppText.eyebrow()),
            const SizedBox(height: 8),
            TrendLine(
              points: [
                for (final c in month)
                  (x: c.date, y: (c.number('pain') ?? 0).toDouble())
              ],
              color: AppColors.warning,
              height: 110,
              unit: '/10',
            ),
          ],
          if (flags >= 3) ...[
            const SizedBox(height: 12),
            OnoCard(
              accent: AppColors.warning,
              padding: const EdgeInsets.all(12),
              child: Text(
                  'Shoulders flagged on $flags of the last 7 mornings. Worth mentioning to your rheumatologist — this log shows the pattern.',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Apple Health link: last night's sleep, HRV and resting heart rate.
/// Sleep before 22:45 ticks "In bed by 10:30pm" automatically.
/// Calendar link for meeting prep; meetings stay on the phone.
class _CalendarLink extends StatelessWidget {
  const _CalendarLink();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.calendarSupported) return const SizedBox.shrink();
    final on = system.calendarConnected;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        padding: EdgeInsets.zero,
        child: LinkRow(
          icon: Icons.event_rounded,
          color: AppColors.skill,
          title: on ? 'Calendar connected' : 'Connect your calendar',
          subtitle: on
              ? 'Today shows your meetings; a nudge 10 min before each. Tap to disconnect.'
              : 'Today shows your meetings; 10 min before each: sigh, or six questions for ${activeProfile.keyPeopleNames}. Read-only, stays on the phone.',
          onTap: () async {
            if (on) {
              await system.disconnectCalendar();
              if (context.mounted) toast(context, 'Calendar disconnected.');
              return;
            }
            final err = await system.connectCalendar();
            if (context.mounted) {
              toast(context, err ?? 'Connected — today\'s meetings are on Today.');
            }
          },
        ),
      ),
    );
  }
}

class _AppleHealth extends StatelessWidget {
  const _AppleHealth();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.healthSupported) return const SizedBox.shrink();
    if (!system.healthConnected) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.favorite_outline_rounded,
            color: AppColors.danger,
            title: 'Connect Apple Health',
            subtitle:
                'Sleep fills the check-in and ticks "bed by 22:30"; HRV and resting heart rate; weigh-ins go to Health',
            onTap: () async {
              final err = await system.connectHealth();
              if (context.mounted) {
                toast(context, err ?? 'Connected — last 3 nights synced.');
              }
            },
          ),
        ),
      );
    }
    final today = dayOnly(DateTime.now());
    final sleep = system.logsOn(today, 'sleep');
    final vitals = system.logsOf('vitals');
    final v = vitals.isEmpty ? null : vitals.first;
    final bed = sleep.isEmpty
        ? null
        : DateTime.tryParse(sleep.last.str('bed_start') ?? '');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text('APPLE HEALTH', style: AppText.eyebrow())),
                GestureDetector(
                  onTap: () async {
                    await system.syncHealth();
                    if (context.mounted) toast(context, 'Synced.');
                  },
                  child: Text('Sync',
                      style: AppText.small(color: AppColors.accent)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        sleep.isEmpty
                            ? '—'
                            : '${sleep.last.number('asleep_h')}',
                        'asleep last night',
                        unit: 'h')),
                Expanded(
                    child: StatTile(
                        v?.number('hrv') == null ? '—' : '${v!.number('hrv')}',
                        'HRV',
                        unit: 'ms')),
                Expanded(
                    child: StatTile(
                        v?.number('rhr') == null ? '—' : '${v!.number('rhr')}',
                        'resting HR')),
              ],
            ),
            if (bed != null) ...[
              const SizedBox(height: 6),
              Text(
                  'In bed ${bed.hour.toString().padLeft(2, '0')}:${bed.minute.toString().padLeft(2, '0')}${bed.hour < 22 || (bed.hour == 22 && bed.minute <= 45) ? ' — "bed by 22:30" ticked' : ''}',
                  style: AppText.small().copyWith(fontSize: 12)),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: system.disconnectHealth,
              child: Text('Disconnect',
                  style: AppText.small().copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

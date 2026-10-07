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
    final weeks = ((today.difference(weekStartOf(system.programStart)).inDays) ~/ 7 + 1)
        .clamp(1, 26);
    final heatFrom = weekStartOf(today).subtract(Duration(days: (weeks - 1) * 7));
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
                  value: system.hasStarted
                      ? system.programDay / programDays
                      : 0),
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
                scoreFor: (d) => d.isBefore(system.programStart)
                    ? null
                    : system.scoreFor(d),
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
                  onTap: () => context.push(protocolTools[p.id] ?? '/protocols'),
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
                        system.startWeight == null || system.latestWeight == null
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
                Text('DAY ${gymPlan[i].letter} · ${gymPlan[i].name.toUpperCase()}',
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
                  child: StatTile(avg('pain', 1), 'shoulder pain',
                      unit: '/10')),
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

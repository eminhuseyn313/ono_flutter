import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_personal_content.dart';
import '../data/emin_system.dart';
import '../providers/auth_provider.dart';
import '../providers/personal_system_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// TODAY — the daily operating screen.
///
/// Answers, in order: where am I in the day, what must I do (the Daily 10
/// and 3 priorities), what am I feeding my mind today (podcast, domain scan,
/// book), how do I train, and one idea to carry.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loaded = false;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    final system = context.read<PersonalSystemProvider>();
    if (userId != null) {
      final profile = context.read<UserProfileProvider>();
      await profile.loadProfile(userId);
      if (mounted && !profile.isOnboarded) {
        context.go('/archetype');
        return;
      }
    }
    await system.load(userId);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = DateTime(_now.year, _now.month, _now.day);

    if (!system.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final day = system.programDay;
    final month = system.programMonth;

    return OnoPage(
      eyebrow:
          '${weekdayName(_now.weekday)} · ${_now.day} ${monthName(_now.month)}',
      title: '$_greeting, ${EminIdentity.firstName}.',
      subtitle: 'Day $day · Month $month of 18 · ${EminIdentity.archetype}',
      actions: [
        _StreakPill(streak: system.streak),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person_outline_rounded,
              color: AppColors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card,
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
      ],
      onRefresh: () async => setState(() => _now = DateTime.now()),
      children: [
        const SizedBox(height: 24),
        _NowCard(now: _now),
        if (_now.hour < 11 && !system.isChecked(today, 'manifesto')) ...[
          const SizedBox(height: 12),
          const _RitualCard(),
        ],
        if (_now.weekday == DateTime.monday) ...[
          const SizedBox(height: 12),
          _NudgeCard(
            icon: Icons.inventory_2_outlined,
            title: 'Read your Evidence Archive',
            body: 'Before your first meeting. ${system.evidenceCount} items of proof.',
            route: '/evidence',
          ),
        ],
        if (_now.weekday == DateTime.sunday) ...[
          const SizedBox(height: 12),
          _NudgeCard(
            icon: Icons.assignment_outlined,
            title: system.reportForWeek(today) == null
                ? 'Sunday report is due'
                : 'Sunday report sent',
            body: 'Five answers. Get next week\'s plan back.',
            route: '/weekly-coaching',
          ),
        ],
        const SectionHeader('Daily 10'),
        _DailyTen(date: today),
        const SectionHeader('Three priorities'),
        _Priorities(date: today),
        const SectionHeader('Today\'s inputs'),
        _InputsCard(date: today, month: month),
        const SectionHeader('Training'),
        _TrainingCard(date: today),
        const SectionHeader('Carry this'),
        _CoachNote(day: day),
        const SizedBox(height: 12),
        _ProtocolOfDay(day: day),
        const SizedBox(height: 28),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/features'),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Explore every feature'),
          ),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 16,
              color: streak > 0 ? AppColors.accent : AppColors.grey),
          const SizedBox(width: 4),
          Text('$streak',
              style: AppText.small(color: AppColors.white)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NowCard extends StatelessWidget {
  final DateTime now;
  const _NowCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final block = currentBlock(now);
    final next = nextBlock(now);
    final nowMin = now.hour * 60 + now.minute;
    var span = next.minuteOfDay - block.minuteOfDay;
    var elapsed = nowMin - block.minuteOfDay;
    if (span <= 0) span += 24 * 60;
    if (elapsed < 0) elapsed += 24 * 60;
    final progress = (elapsed / span).clamp(0.0, 1.0);
    final laneColor = AppColors.lane(block.lane);

    var detail = block.detail;
    if (block.title == 'Drive') {
      detail = '${podcastFor(now).title} — ${podcastFor(now).detail}';
    } else if (block.title == 'Train or deep work') {
      detail = eveningFocus(now.weekday);
    }

    return OnoCard(
      highlight: true,
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('NOW', style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(width: 8),
              Text(block.timeLabel, style: AppText.eyebrow()),
              const Spacer(),
              Icon(block.icon, color: laneColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(block.title, style: AppText.title()),
          const SizedBox(height: 6),
          Text(detail, style: AppText.body()),
          const SizedBox(height: 16),
          ThinBar(value: progress, color: laneColor, height: 3),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Next  ', style: AppText.small()),
              Text('${next.timeLabel}  ${next.title}',
                  style: AppText.small(color: AppColors.greyLight)
                      .copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard();

  @override
  Widget build(BuildContext context) {
    final total =
        eminMorningRitual.fold<int>(0, (s, r) => s + r.durationSeconds);
    return OnoCard(
      color: AppColors.accent.withValues(alpha: 0.08),
      onTap: () => context.push('/ritual-flow/ritual_morning_default'),
      child: Row(
        children: [
          const IconTile(Icons.wb_sunny_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start the morning ritual', style: AppText.heading()),
                const SizedBox(height: 2),
                Text(
                    'Water · manifesto · 3 priorities · sigh · statement — ${(total / 60).ceil()} min',
                    style: AppText.small()),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.accent, size: 32),
        ],
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String route;

  const _NudgeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return OnoCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          IconTile(icon, color: AppColors.steel),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading()),
                const SizedBox(height: 2),
                Text(body, style: AppText.small()),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
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
    final verdict = score >= 9
        ? 'Elite day.'
        : score >= 7
            ? 'Solid. Streak protected.'
            : score >= 4
                ? 'Keep stacking.'
                : 'Start with one.';

    return OnoCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(
                progress: score / 10,
                size: 58,
                center: Text('$score',
                    style: AppText.number(size: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$score of 10 non-negotiables',
                        style: AppText.heading()),
                    const SizedBox(height: 2),
                    Text(verdict, style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          for (final n in nonNegotiables)
            CheckRow(
              checked: system.isChecked(date, n.id),
              title: n.title,
              lane: n.lane,
              onChanged: (_) => system.toggleCheck(date, n.id),
            ),
        ],
      ),
    );
  }
}

class _Priorities extends StatefulWidget {
  final DateTime date;
  const _Priorities({required this.date});

  @override
  State<_Priorities> createState() => _PrioritiesState();
}

class _PrioritiesState extends State<_Priorities> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalSystemProvider>().prioritiesFor(widget.date);
    _controllers = List.generate(3, (i) => TextEditingController(text: p[i]));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outcomes, not tasks. What must be true by 6pm?',
              style: AppText.small()),
          const SizedBox(height: 6),
          for (var i = 0; i < 3; i++)
            Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}',
                      style: AppText.number(
                          size: 16, color: AppColors.accent)),
                ),
                Expanded(
                  child: TextField(
                    controller: _controllers[i],
                    style: AppText.body(color: AppColors.white),
                    textInputAction: TextInputAction.done,
                    onChanged: (v) => system.setPriority(widget.date, i, v),
                    decoration: InputDecoration(
                      hintText: const [
                        'The one outcome that matters most',
                        'Second outcome',
                        'Third outcome',
                      ][i],
                      filled: false,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
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

class _InputsCard extends StatelessWidget {
  final DateTime date;
  final int month;
  const _InputsCard({required this.date, required this.month});

  @override
  Widget build(BuildContext context) {
    final podcast = podcastFor(date);
    final scan = domainScanFor(date);
    final book = currentBook(month);
    final outfit = outfitFor(date);

    Widget row(IconData icon, Color color, String label, String title,
        String detail,
        {VoidCallback? onTap, IconData? trailing}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              IconTile(icon, color: color, size: 38),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        style: AppText.eyebrow().copyWith(fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(title, style: AppText.heading()),
                    const SizedBox(height: 1),
                    Text(detail, style: AppText.small()),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing, color: AppColors.grey, size: 18),
            ],
          ),
        ),
      );
    }

    return OnoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          row(Icons.podcasts_rounded, AppColors.skill, 'Commute podcast',
              podcast.title, podcast.detail),
          const Divider(indent: 18, endIndent: 18),
          row(Icons.travel_explore_rounded, AppColors.steel,
              'Domain scan · 15 min', scan.title, scan.detail,
              onTap: scan.url == null ? null : () => openLink(scan.url!),
              trailing: scan.url == null ? null : Icons.north_east_rounded),
          const Divider(indent: 18, endIndent: 18),
          row(Icons.menu_book_rounded, AppColors.mind, 'Lunch read · 20 min',
              book.title, '${book.author} · ${book.chapters}',
              onTap: () => context.push('/library'),
              trailing: Icons.chevron_right_rounded),
          const Divider(indent: 18, endIndent: 18),
          row(outfit.icon, AppColors.social, 'Wear', outfit.occasion,
              outfit.formula,
              onTap: () => context.push('/style'),
              trailing: Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final DateTime date;
  const _TrainingCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final gym = gymDayFor(date);
    final sessions = system.gymSessionsInWeek(date);

    if (gym == null) {
      return OnoCard(
        onTap: () => context.go('/plan'),
        child: Row(
          children: [
            const IconTile(Icons.self_improvement_rounded,
                color: AppColors.body),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No gym today', style: AppText.heading()),
                  const SizedBox(height: 2),
                  Text('19:00 — ${eveningFocus(date.weekday)}',
                      style: AppText.small()),
                ],
              ),
            ),
            Text('$sessions/3', style: AppText.number(size: 18)),
          ],
        ),
      );
    }

    final done = system.gymDone(date);
    return OnoCard(
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(Icons.fitness_center_rounded,
                  color: AppColors.body),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${gym.letter} — ${gym.name}',
                        style: AppText.heading()),
                    const SizedBox(height: 2),
                    Text(
                        '19:00 · ${gym.exercises.length} exercises · RA-safe · $sessions/3 this week',
                        style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in gym.exercises.take(4)) Tag(e.name),
              Tag('+ ${gym.exercises.length - 4} more'),
              const Tag('Face pulls 3×15', color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: done
                ? OutlinedButton.icon(
                    onPressed: () => system.toggleGym(date),
                    icon: const Icon(Icons.check_rounded,
                        color: AppColors.body, size: 18),
                    label: const Text('Session logged'),
                  )
                : FilledButton(
                    onPressed: () => system.toggleGym(date),
                    child: const Text('Log session + Zone 2'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CoachNote extends StatelessWidget {
  final int day;
  const _CoachNote({required this.day});

  @override
  Widget build(BuildContext context) {
    final tip = eminCoachTips[(day - 1) % eminCoachTips.length];
    return OnoCard(
      accent: AppColors.lane(tip.lane),
      onTap: () => context.push('/ai-coach'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAY ${((day - 1) % 30) + 1} · ${tip.lane.toUpperCase()}',
                  style: AppText.eyebrow(color: AppColors.lane(tip.lane))),
            ],
          ),
          const SizedBox(height: 10),
          Text(tip.title, style: AppText.heading()),
          const SizedBox(height: 8),
          Text(tip.content, style: AppText.body()),
        ],
      ),
    );
  }
}

class _ProtocolOfDay extends StatelessWidget {
  final int day;
  const _ProtocolOfDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final p = protocols[(day - 1) % protocols.length];
    return OnoCard(
      onTap: () => context.push('/protocols'),
      child: Row(
        children: [
          IconTile(p.icon, color: AppColors.lane(p.lane)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROTOCOL OF THE DAY',
                    style: AppText.eyebrow().copyWith(fontSize: 10)),
                const SizedBox(height: 3),
                Text(p.name, style: AppText.heading()),
                const SizedBox(height: 2),
                Text(p.what,
                    style: AppText.small(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
        ],
      ),
    );
  }
}

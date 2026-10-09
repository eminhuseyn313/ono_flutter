import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Commission — the program's opening ceremony. Five short steps that set
/// up the 18 months: identity, start date, anchors, reminders, signature.
class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  final _pages = PageController();
  int _step = 0;

  late DateTime _start;
  List<int> _gymDays = [DateTime.monday, DateTime.wednesday, DateTime.thursday];
  final _weight = TextEditingController(text: '83');
  final Map<String, bool> _reminders = {
    for (final r in reminderDefs) r.id: r.defaultOn,
  };
  bool _permissionAsked = false;

  static const _steps = 5;

  @override
  void initState() {
    super.initState();
    final today = dayOnly(DateTime.now());
    final toMonday = (DateTime.monday - today.weekday) % 7;
    _start = toMonday == 0 ? today : today.add(Duration(days: toMonday));
  }

  @override
  void dispose() {
    _pages.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_step < _steps - 1) {
      setState(() => _step++);
      _pages.animateToPage(_step,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pages.animateToPage(_step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    final system = context.read<PersonalSystemProvider>();
    await system.commission(
      start: _start,
      gymDays: _gymDays,
      weightKg: double.tryParse(_weight.text.replaceAll(',', '.')),
      reminders: _reminders,
    );
    HapticFeedback.heavyImpact();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _step == 0 ? null : _back,
                    icon: Icon(Icons.arrow_back_rounded,
                        color: _step == 0
                            ? Colors.transparent
                            : AppColors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TickSegments(
                          total: _steps, filled: _step + 1, height: 4)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _identity(),
                  _startDate(),
                  _anchors(),
                  _remindersPage(),
                  _sign(),
                ],
              ),
            ),
            if (_step < _steps - 1)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
                child: PrimaryButton(
                  const ['This is me', 'Set the start', 'Confirm anchors',
                      'Continue', ''][_step],
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page(String eyebrow, String title, String? sub, List<Widget> body) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Text(eyebrow.toUpperCase(),
            style: AppText.eyebrow(color: AppColors.accent)),
        const SizedBox(height: 10),
        Text(title, style: AppText.display()),
        if (sub != null) ...[
          const SizedBox(height: 12),
          Text(sub, style: AppText.body(color: AppColors.grey)),
        ],
        const SizedBox(height: 28),
        ...body,
      ],
    );
  }

  Widget _identity() => _page(
        'Commission · 1 of 5',
        activeProfile.archetype,
        activeProfile.tagline,
        [
          OnoCard(
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activeProfile.name, style: AppText.serif(size: 26)),
                const SizedBox(height: 4),
                Text(activeProfile.roleLine, style: AppText.body()),
                Text('${activeProfile.organisation} · ${activeProfile.location}',
                    style: AppText.small()),
                const SizedBox(height: 18),
                Text('THE PATH', style: AppText.eyebrow()),
                const SizedBox(height: 8),
                for (final s in pathSteps)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s == pathSteps.first
                                ? AppColors.accent
                                : AppColors.navyLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(s[0], style: AppText.body(
                                color: AppColors.white))),
                        Text('Month ${s[1]}', style: AppText.small()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
              'Eighteen months, four phases: Foundation, Craft, Signal, Leverage. '
              'Everything in this app comes from your profile — nothing generic, '
              'no sample numbers.',
              style: AppText.body(color: AppColors.grey)),
        ],
      );

  Widget _startDate() {
    final today = dayOnly(DateTime.now());
    final options = <(String, DateTime)>[
      ('Today', today),
      (
        'Next Monday',
        today.add(Duration(days: ((DateTime.monday - today.weekday) % 7) == 0
            ? 7
            : (DateTime.monday - today.weekday) % 7))
      ),
    ];
    return _page(
      'Commission · 2 of 5',
      'Day 1',
      'Months are counted in 30-day blocks from this date. Starting on a Monday keeps weeks and gym days aligned.',
      [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OnoCard(
              highlight: dateKey(_start) == dateKey(o.$2),
              onTap: () => setState(() => _start = o.$2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$1, style: AppText.heading()),
                        Text(
                            '${weekdayName(o.$2.weekday)}, ${shortDate(o.$2)}',
                            style: AppText.small()),
                      ],
                    ),
                  ),
                  if (dateKey(_start) == dateKey(o.$2))
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.accent),
                ],
              ),
            ),
          ),
        GhostButton('Pick another date', icon: Icons.event_rounded,
            onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _start,
            firstDate: today.subtract(const Duration(days: 365)),
            lastDate: today.add(const Duration(days: 60)),
          );
          if (picked != null) setState(() => _start = dayOnly(picked));
        }),
        const SizedBox(height: 16),
        Text(
            'Program ends ${shortDate(_start.add(const Duration(days: programDays - 1)))} ${_start.add(const Duration(days: programDays - 1)).year}.',
            style: AppText.small()),
      ],
    );
  }

  Widget _anchors() => _page(
        'Commission · 3 of 5',
        'Anchors',
        'Your day is fixed by the profile: wake 06:00, ritual 06:05, desk 07:45, lunch read 12:00, gym 19:00, bed 22:30. Confirm the gym days and today\'s weight.',
        [
          for (var i = 0; i < 3; i++) ...[
            Text('DAY ${gymPlan[i].letter} · ${gymPlan[i].name.toUpperCase()}',
                style: AppText.eyebrow()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  ChoiceChip(
                    label: Text(weekdayName(d).substring(0, 3)),
                    selected: _gymDays[i] == d,
                    showCheckmark: false,
                    selectedColor: AppColors.accent,
                    labelStyle: AppText.small(
                            color: _gymDays[i] == d
                                ? AppColors.ink
                                : AppColors.greyLight)
                        .copyWith(fontWeight: FontWeight.w700),
                    onSelected: _gymDays.contains(d) && _gymDays[i] != d
                        ? null
                        : (_) => setState(() => _gymDays = [
                              for (var j = 0; j < 3; j++)
                                j == i ? d : _gymDays[j]
                            ]),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text('WEIGHT TODAY', style: AppText.eyebrow()),
          const SizedBox(height: 8),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppText.number(size: 22),
            decoration: const InputDecoration(suffixText: 'kg'),
          ),
          const SizedBox(height: 8),
          Text('Target 76–78 kg over 5–6 months, keeping the muscle.',
              style: AppText.small()),
        ],
      );

  Widget _remindersPage() => _page(
        'Commission · 4 of 5',
        'Reminders',
        'ONO taps you at the moments the system runs on. Each one opens the exact tool for that moment.',
        [
          OnoCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final r in reminderDefs)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _reminders[r.id] ?? true,
                    onChanged: (v) => setState(() => _reminders[r.id] = v),
                    title: Text(r.label,
                        style: AppText.body(color: AppColors.white)
                            .copyWith(fontSize: 14.5)),
                    subtitle: Text(
                        '${r.id == 'gym' ? '18:45 on gym days' : r.timeLabel}${r.weekdays != null && r.id != 'gym' ? ' · ${r.weekdays!.map((d) => weekdayName(d).substring(0, 3)).join(', ')}' : ''}',
                        style: AppText.small()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GhostButton(
            _permissionAsked ? 'Permission requested' : 'Allow notifications',
            icon: Icons.notifications_active_outlined,
            onPressed: _permissionAsked
                ? null
                : () async {
                    final ok = await context
                        .read<PersonalSystemProvider>()
                        .requestReminderPermission();
                    setState(() => _permissionAsked = true);
                    if (!ok && mounted) {
                      toast(context,
                          'Not granted here — enable later in Settings › ONO.');
                    }
                  },
          ),
        ],
      );

  Widget _sign() => _page(
        'Commission · 5 of 5',
        'Sign it',
        'Read it once, slowly. Then press and hold to sign.',
        [
          for (final stanza in manifestoStanzas) ...[
            for (final line in stanza)
              Text(line,
                  style: AppText.serif(
                      size: 21,
                      color: stanza == manifestoStanzas.last
                          ? AppColors.accent
                          : AppColors.white)),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          _HoldToSign(onSigned: _finish),
          const SizedBox(height: 12),
          Text(
              'Day 1 is ${weekdayName(_start.weekday)} ${shortDate(_start)}.',
              textAlign: TextAlign.center,
              style: AppText.small()),
        ],
      );
}

/// Press-and-hold signature: fills over 1.2 s, heavy haptic when complete.
class _HoldToSign extends StatefulWidget {
  final Future<void> Function() onSigned;
  const _HoldToSign({required this.onSigned});

  @override
  State<_HoldToSign> createState() => _HoldToSignState();
}

class _HoldToSignState extends State<_HoldToSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..addStatusListener((s) async {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        await widget.onSigned();
      }
    });
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _c.forward();
      },
      onTapUp: (_) {
        if (!_done) _c.reverse();
      },
      onTapCancel: () {
        if (!_done) _c.reverse();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _c.value,
                child: Container(color: AppColors.accent),
              ),
              Center(
                child: Text(
                  _done ? 'Signed. Day 1 begins.' : 'Hold to sign',
                  style: AppText.heading(
                      color: _c.value > 0.5
                          ? AppColors.ink
                          : AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

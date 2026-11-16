import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../time.dart';
import '../widgets/ono_ui.dart';

/// Plan the day: give today's three and deep work a time, beside your
/// meetings. ONO nudges you when each block starts.
class DayPlanScreen extends StatelessWidget {
  const DayPlanScreen({super.key});

  static int _minuteOf(DateTime t) => t.hour * 60 + t.minute;

  Future<void> _place(BuildContext context, PersonalSystemProvider system,
      {required String title, required String kind, int minutes = 50, String? id}) async {
    final day = system.logicalToday;
    var length = minutes;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final slots = system.openSlots(day, length);
          void pick(int start) {
            system.setDayBlock(day, id: id, title: title, start: start, minutes: length, kind: kind);
            Navigator.of(ctx).pop();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title(), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Text('How long?', style: AppText.eyebrow()),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final m in const [25, 50, 90, 30, 60])
                        ChoiceChip(
                          label: Text('$m min'),
                          selected: length == m,
                          showCheckmark: false,
                          onSelected: (_) => set(() => length = m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Free times', style: AppText.eyebrow()),
                  const SizedBox(height: 6),
                  if (slots.isEmpty)
                    Text('No free time left today for that long. Pick a time yourself.', style: AppText.small())
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in slots)
                          ActionChip(
                            key: Key('slot-$s'),
                            label: Text('${DayBlock.clock(s)}–${DayBlock.clock(s + length)}'),
                            onPressed: () => pick(s),
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  GhostButton('Pick a time', icon: Icons.schedule_rounded, onPressed: () async {
                    final now = timeNow();
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
                    );
                    if (t != null) pick(t.hour * 60 + t.minute);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = timeNow();
    final day = system.logicalToday;
    final blocks = system.dayPlanFor(day);
    final meetings = system.meetingsFor(day);
    final nowMin = _minuteOf(now);
    final toPlace = system.unplacedThree(day);
    // Meetings and blocks in one timeline, by start.
    final rows = <(int, int, String, String, String?)>[
      for (final m in meetings) (_minuteOf(m.start), _minuteOf(m.end), m.title, 'meeting', null),
      for (final b in blocks) (b.start, b.start + b.minutes, b.title, b.kind, b.id),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return OnoPage(
      showBack: true,
      eyebrow: 'Plan the day',
      title: blocks.isEmpty ? 'Give today a shape' : 'Your day',
      subtitle:
          'A time for what matters, beside your meetings. ONO nudges you when each block starts. Plans that name a time happen far more often.',
      children: [
        ...[
          const SectionHeader('Give these a time'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in toPlace)
                ActionChip(
                  key: Key('place-$t'),
                  avatar: Icon(Icons.flag_outlined, size: 16, color: AppColors.accent),
                  label: Text(t, overflow: TextOverflow.ellipsis),
                  onPressed: () => _place(context, system, title: t, kind: 'three', minutes: 50),
                ),
              ActionChip(
                key: const Key('place-focus'),
                avatar: Icon(Icons.timer_outlined, size: 16, color: AppColors.accent),
                label: const Text('Deep work'),
                onPressed: () => _place(context, system, title: 'Deep work', kind: 'focus', minutes: 50),
              ),
              ActionChip(
                key: const Key('place-other'),
                avatar: Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                label: const Text('Something else'),
                onPressed: () async {
                  final title = await _askTitle(context);
                  if (title != null && context.mounted) {
                    await _place(context, system, title: title, kind: 'other', minutes: 30);
                  }
                },
              ),
            ],
          ),
          if (system.prioritiesFor(day).every((p) => p.trim().isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Write today\'s three on Today and they appear here.', style: AppText.small()),
            ),
        ],
        const SectionHeader('Today'),
        if (rows.isEmpty)
          const EmptyNote('Nothing on the timeline yet. Give one of today\'s three a time.',
              icon: Icons.view_timeline_outlined)
        else
          OnoCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final r in rows)
                  _Row(
                    from: r.$1,
                    to: r.$2,
                    title: r.$3,
                    kind: r.$4,
                    now: nowMin >= r.$1 && nowMin < r.$2,
                    past: nowMin >= r.$2,
                    onMove: r.$5 == null
                        ? null
                        : () => _place(context, system,
                            title: r.$3, kind: r.$4, minutes: r.$2 - r.$1, id: r.$5),
                    onRemove: r.$5 == null ? null : () => system.removeDayBlock(day, r.$5!),
                  ),
              ],
            ),
          ),
        if (meetings.isEmpty && !system.calendarConnected)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Connect your calendar under Me → Settings to see meetings here.', style: AppText.small()),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  static Future<String?> _askTitle(BuildContext context) async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What is it?'),
        content: TextField(
          key: const Key('place-title'),
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'A walk, a call, an errand…'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(c.text), child: const Text('Next')),
        ],
      ),
    );
    return r == null || r.trim().isEmpty ? null : r.trim();
  }
}

class _Row extends StatelessWidget {
  final int from;
  final int to;
  final String title;
  final String kind;
  final bool now;
  final bool past;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;
  const _Row(
      {required this.from,
      required this.to,
      required this.title,
      required this.kind,
      required this.now,
      required this.past,
      this.onMove,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    final meeting = kind == 'meeting';
    final color = meeting ? AppColors.grey : AppColors.accent;
    return Opacity(
      opacity: past ? 0.55 : 1,
      child: InkWell(
        onTap: onMove,
        child: Container(
          color: now ? AppColors.accentDeep : null,
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(DayBlock.clock(from), style: AppText.small(color: AppColors.white).copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(width: 3, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(color: AppColors.white)),
                    Text(
                      [
                        '${DayBlock.clock(from)}–${DayBlock.clock(to)}',
                        if (now) 'now',
                        switch (kind) {
                          'meeting' => 'meeting',
                          'three' => 'one of today\'s three',
                          'focus' => 'deep work',
                          _ => '',
                        },
                      ].where((t) => t.isNotEmpty).join(' · '),
                      style: AppText.small(),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Take it off the plan',
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

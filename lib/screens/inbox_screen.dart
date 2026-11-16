import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../time.dart';
import '../widgets/ono_ui.dart';

/// The notification centre: what ONO sent today, what each one asked, and
/// whether it's done — with the action right there. Tapping a notification
/// about the day itself opens here, on that notification.
class InboxScreen extends StatelessWidget {
  /// The notification that was tapped, shown first and open.
  final String? focus;
  const InboxScreen({super.key, this.focus});

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final all = system.inboxToday();
    final focused = all.where((i) => i.id == focus).firstOrNull;
    final now = timeNow();
    final sent = [for (final i in all) if (!i.at.isAfter(now) && i != focused) i];
    final later = [for (final i in all) if (i.at.isAfter(now) && i != focused) i];
    final open = sent.where((i) => !i.done).length;
    return OnoPage(
      showBack: true,
      eyebrow: 'Notifications',
      title: open == 0 ? 'All caught up' : '$open still open today',
      subtitle: system.remindersSupported
          ? 'Everything ONO sends you today, and what each one asks. Switch any off under Me → Settings → Reminders.'
          : 'On the web ONO can\'t send notifications; here is what your phone and Mac get today.',
      children: [
        if (focused != null) ...[
          const SizedBox(height: 12),
          _Entry(item: focused, open: true, time: _time(focused.at)),
        ],
        if (sent.isNotEmpty) ...[
          const SectionHeader('Earlier today'),
          for (final i in sent) ...[_Entry(item: i, time: _time(i.at)), const SizedBox(height: 10)],
        ],
        if (later.isNotEmpty) ...[
          const SectionHeader('Later today'),
          for (final i in later) ...[_Entry(item: i, time: _time(i.at), quiet: true), const SizedBox(height: 10)],
        ],
        if (all.isEmpty)
          const EmptyNote(
              'No notifications today. Choose which ones you want under Me → Settings → Reminders.',
              icon: Icons.notifications_none_rounded),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  final InboxItem item;
  final String time;

  /// The tapped one: its action is the big button.
  final bool open;

  /// Not sent yet: shown lighter.
  final bool quiet;
  const _Entry({required this.item, required this.time, this.open = false, this.quiet = false});

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    final day = system.logicalToday;
    final title = item.title == 'ONO' ? item.body : item.title;
    final body = item.title == 'ONO' ? '' : item.body;
    final cue = item.itemId == null ? '' : system.cueFor(item.itemId!);
    void tick() => system.setCheck(day, item.itemId!, true);
    final actionLabel = item.itemId != null
        ? 'Mark it done'
        : item.route == '/home'
            ? 'Open today'
            : 'Open';
    void act() => item.itemId != null ? tick() : context.push(item.route);
    return Opacity(
      opacity: quiet ? 0.7 : 1,
      child: OnoCard(
        key: Key('inbox-${item.id}'),
        color: open ? AppColors.navy : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    item.done
                        ? Icons.check_circle_rounded
                        : quiet
                            ? Icons.schedule_rounded
                            : Icons.notifications_active_outlined,
                    size: 18,
                    color: item.done ? AppColors.accent : AppColors.grey),
                const SizedBox(width: 8),
                Text(time, style: AppText.small()),
                const SizedBox(width: 8),
                if (item.done)
                  Text('Done', style: AppText.small(color: AppColors.accent))
                else if (!quiet)
                  Text('Open', style: AppText.small(color: AppColors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: AppText.heading()),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(body, style: AppText.body(color: AppColors.greyLight)),
            ],
            if (cue.trim().isNotEmpty && !item.done) ...[
              const SizedBox(height: 6),
              Text('Your plan: $cue', style: AppText.small()),
            ],
            if (!item.done || item.itemId == null) ...[
              const SizedBox(height: 10),
              if (open)
                PrimaryButton(actionLabel,
                    key: Key('inbox-act-${item.id}'),
                    icon: item.itemId != null ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    onPressed: act)
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('inbox-act-${item.id}'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: act,
                    child: Text(actionLabel),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The bell on Today and the sidebar: opens the notification centre, with
/// how many of today's are still open.
class InboxBell extends StatelessWidget {
  const InboxBell({super.key});

  @override
  Widget build(BuildContext context) {
    final open = context.watch<PersonalSystemProvider>().inboxOpen;
    return Semantics(
      button: true,
      label: open == 0 ? 'Notifications' : 'Notifications, $open open',
      child: InkWell(
        key: const Key('inbox-bell'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/inbox'),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, color: AppColors.greyLight, size: 22),
              if (open > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
                    alignment: Alignment.center,
                    child: Text('$open',
                        style: AppText.small(color: AppColors.ink).copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

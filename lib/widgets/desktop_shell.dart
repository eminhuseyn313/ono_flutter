import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app.dart' show PhoneFrame;
import '../data/emin_system.dart';
import '../providers/auth_provider.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../time.dart';
import 'ono_ui.dart';

/// ONO on a big screen (the Mac app, the web app on a laptop): a sidebar
/// to every part of ONO, the page in a comfortable reading column, and —
/// on a wide window — today at a glance beside it. On a phone-sized
/// window it is the phone app, unchanged.
class DesktopShell extends StatefulWidget {
  /// From this width the window gets the sidebar.
  static const minWidth = 900.0;

  /// From this width it also gets the today panel.
  static const panelWidth = 1240.0;

  static const sidebarWidth = 232.0;
  static const columnWidth = 760.0;
  static const glanceWidth = 320.0;

  /// Before sign-in and while setting up, the page stays one calm column.
  static const setupPaths = {
    '/splash', '/welcome', '/sign-in', '/sign-up', '/forgot-password',
    '/new-password', '/start', '/commission',
  };

  final GoRouter router;
  final Widget child;
  const DesktopShell({super.key, required this.router, required this.child});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  // The sidebar and the panel sit outside the pages' navigator: they get
  // their own overlay (tooltips) and material (ink).
  // A new entry each time the window turns desktop; dropped with its
  // overlay when it turns phone-sized.
  OverlayEntry? _entry;

  // The pages move between the phone and desktop layouts without being
  // rebuilt (their navigator and state stay).
  final _pages = GlobalKey(debugLabel: 'ono-pages');
  Widget get _child => KeyedSubtree(key: _pages, child: widget.child);
  String _path = '';

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRoute);
    _path = _currentPath;
  }

  @override
  void didUpdateWidget(DesktopShell old) {
    super.didUpdateWidget(old);
    if (old.router != widget.router) {
      old.router.routerDelegate.removeListener(_onRoute);
      widget.router.routerDelegate.addListener(_onRoute);
    }
    if (_entry?.mounted ?? false) _entry!.markNeedsBuild();
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  String get _currentPath {
    try {
      // The page on top: a tool opened over a tab counts, not the tab.
      final c = widget.router.routerDelegate.currentConfiguration;
      return c.isEmpty ? '' : Uri.parse(c.last.matchedLocation).path;
    } catch (_) {
      return '';
    }
  }

  /// The router can change during a build: update after the frame.
  void _onRoute() {
    void apply() {
      if (!mounted) return;
      final p = _currentPath;
      if (p == _path) return;
      setState(() => _path = p);
      if (_entry?.mounted ?? false) _entry!.markNeedsBuild();
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      apply();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    }
  }

  bool _inApp(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final system = context.watch<PersonalSystemProvider>();
    return auth.isAuthenticated &&
        system.isLoaded &&
        system.isCommissioned &&
        !DesktopShell.setupPaths.contains(_path);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < DesktopShell.minWidth || !_inApp(context)) {
      _entry = null;
      return PhoneFrame(child: _child);
    }
    final entry = _entry ??= OverlayEntry(builder: _desktop);
    if (entry.mounted) entry.markNeedsBuild();
    return Overlay(key: ObjectKey(entry), initialEntries: [entry]);
  }

  Widget _desktop(BuildContext context) {
    final media = MediaQuery.of(context);
    final wide = media.size.width >= DesktopShell.panelWidth;
    final room = media.size.width - DesktopShell.sidebarWidth - (wide ? DesktopShell.glanceWidth : 0);
    final column = room.clamp(PhoneFrame.maxWidth, DesktopShell.columnWidth).toDouble();
    return Material(
      color: AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(router: widget.router, path: _path),
          VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: Center(
              child: SizedBox(
                width: column,
                child: MediaQuery(
                  data: media.copyWith(size: Size(column, media.size.height)),
                  child: DesktopScope(child: ClipRect(child: _child)),
                ),
              ),
            ),
          ),
          if (wide) ...[
            VerticalDivider(width: 1, color: AppColors.divider),
            SizedBox(width: DesktopShell.glanceWidth, child: _Glance(router: widget.router)),
          ],
        ],
      ),
    );
  }
}

/// Tells the pages they sit beside the sidebar: the tab bar steps aside.
class DesktopScope extends InheritedWidget {
  const DesktopScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopScope>() != null;

  @override
  bool updateShouldNotify(DesktopScope oldWidget) => false;
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String route;

  /// The four tabs replace the page stack; tools open over it.
  final bool tab;
  const _NavEntry(this.label, this.icon, this.route, {this.tab = false});
}

const _main = [
  _NavEntry('Today', Icons.wb_sunny_outlined, '/home', tab: true),
  _NavEntry('Program', Icons.timeline_rounded, '/program', tab: true),
  _NavEntry('Log', Icons.edit_note_rounded, '/log', tab: true),
  _NavEntry('Me', Icons.person_outline_rounded, '/profile', tab: true),
];

const _grow = [
  _NavEntry('Ask ONO', Icons.chat_bubble_outline_rounded, '/ask'),
  _NavEntry('Ideas for you', Icons.auto_awesome_outlined, '/for-you'),
  _NavEntry('Goals', Icons.flag_circle_outlined, '/goals'),
  _NavEntry('Growth plan', Icons.trending_up_rounded, '/growth'),
  _NavEntry('The week', Icons.view_week_outlined, '/week'),
  _NavEntry('Deep work', Icons.timer_outlined, '/focus'),
  _NavEntry('People', Icons.people_outline_rounded, '/people'),
  _NavEntry('Learning', Icons.menu_book_outlined, '/learning'),
  _NavEntry('Review deck', Icons.style_outlined, '/review'),
];

class _Sidebar extends StatelessWidget {
  final GoRouter router;
  final String path;
  const _Sidebar({required this.router, required this.path});

  void _open(_NavEntry e) => e.tab ? router.go(e.route) : router.push(e.route);

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = activeProfile;
    Widget item(_NavEntry e) {
      final on = e.tab ? path.startsWith(e.route) : path == e.route.split('?').first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Material(
          color: on ? AppColors.accentDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key('side-${e.route}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open(e),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(e.icon, size: 19, color: on ? AppColors.accent : AppColors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(color: on ? AppColors.white : AppColors.greyLight).copyWith(
                              fontSize: 14.5, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: DesktopShell.sidebarWidth,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 16, 4),
              child: Text('ONO', style: AppText.title().copyWith(letterSpacing: 2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 16, 14),
              child: Text(
                [
                  if (p.firstName.trim().isNotEmpty) p.firstName,
                  if (system.hasStarted) 'day ${system.programDay} of ${system.programDays}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.small(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: InkWell(
                key: const Key('side-search'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => router.push('/tools?focus=1'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: AppColors.grey),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Search', style: AppText.small())),
                      Text(Theme.of(context).platform == TargetPlatform.macOS ? '⌘K' : 'Ctrl K',
                          style: AppText.small(color: AppColors.faint).copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final e in _main) item(e),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 16, 6),
                    child: Text('GROW', style: AppText.eyebrow()),
                  ),
                  for (final e in _grow) item(e),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 6),
            item(const _NavEntry('Settings', Icons.settings_outlined, '/me/section?id=settings')),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Today at a glance: what to do now, today's three, the list, the week
/// and the goals — live, beside whatever page is open.
class _Glance extends StatelessWidget {
  final GoRouter router;
  const _Glance({required this.router});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final day = system.logicalToday;
    final now = system.ask('now', timeNow());
    final pr = system.prioritiesFor(day);
    // Today's own list: a day off leaves out work-day-only items.
    final ids = system.itemIdsOn(day);
    final items = [for (final n in system.dailyItems) if (ids.contains(n.id)) n];
    final done = items.where((n) => system.isChecked(day, n.id)).length;
    final target = system.targetFor(day);
    final week = system.weekOutcomes(day);
    final goals = system.activeGoals;
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        left: false,
        child: ListView(
          key: const Key('desktop-glance'),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            Text('TODAY AT A GLANCE', style: AppText.eyebrow()),
            const SizedBox(height: 10),
            OnoCard(
              color: AppColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Now', style: AppText.small()),
                  const SizedBox(height: 4),
                  Text(now.lines.first, style: AppText.heading()),
                  if (now.actions.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => router.push(now.actions.last.$2),
                      child: Text(now.actions.last.$1),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Heading('Today\'s three', onTap: () => router.go('/home')),
            if (pr.every((t) => t.trim().isEmpty))
              Text('Not set yet. Write them on Today.', style: AppText.small())
            else
              for (var i = 0; i < 3; i++)
                if (pr[i].trim().isNotEmpty)
                  CheckRow(
                    checked: system.priorityDone(day, i),
                    title: pr[i],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onChanged: (v) => system.setCheck(day, 'p$i', v),
                  ),
            const SizedBox(height: 16),
            _Heading('Your list', onTap: () => router.go('/home')),
            Text('$done of ${items.length} done · $target holds the day', style: AppText.small()),
            const SizedBox(height: 8),
            ThinBar(value: items.isEmpty ? 0 : done / items.length),
            const SizedBox(height: 8),
            for (final n in items.where((n) => !system.isChecked(day, n.id)).take(5))
              CheckRow(
                checked: false,
                title: n.title,
                padding: const EdgeInsets.symmetric(vertical: 5),
                onChanged: (v) => system.setCheck(day, n.id, v),
              ),
            const SizedBox(height: 16),
            _Heading('The week', onTap: () => router.push('/week')),
            if (week.every((t) => t.trim().isEmpty))
              Text('Choose the week\'s three.', style: AppText.small())
            else
              for (var i = 0; i < 3; i++)
                if (week[i].trim().isNotEmpty)
                  CheckRow(
                    checked: system.weekOutcomeDone(day, i),
                    title: week[i],
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onChanged: (_) => system.toggleWeekOutcome(day, i),
                  ),
            if (goals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Heading('Goals', onTap: () => router.push('/goals')),
              for (final g in goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.text, style: AppText.body(color: AppColors.white).copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        [
                          if (system.goalPace(g) case final pace?) pace,
                          if (system.goalNextStep(g) case final next?) 'Next: $next',
                        ].join(' · '),
                        style: AppText.small(),
                      ),
                    ],
                  ),
                ),
            ],
            if (system.streak > 0) ...[
              const SizedBox(height: 8),
              Text('Streak: ${system.streak} days', style: AppText.small()),
            ],
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Heading(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(text, style: AppText.heading())),
          IconButton(
            tooltip: 'Open $text',
            icon: Icon(Icons.chevron_right_rounded, color: AppColors.grey),
            onPressed: onTap,
          ),
        ],
      );
}

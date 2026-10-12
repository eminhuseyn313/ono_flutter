import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'gateways/auth_gateway.dart';
import 'gateways/personal_system_gateway.dart';
import 'providers/auth_provider.dart';
import 'providers/personal_system_provider.dart';
import 'router.dart';
import 'services/app_shortcuts.dart';
import 'services/brief_generator.dart';
import 'services/calendar_service.dart';
import 'services/health_service.dart';
import 'services/reminder_service.dart';
import 'services/widget_sync.dart';
import 'theme/app_theme.dart';

/// The app, independent of where data lives. `main.dart` wires it to
/// on-device storage; `main_production.dart` to Supabase.
class OnoApp extends StatefulWidget {
  final AuthGateway authGateway;
  final PersonalSystemGateway personalGateway;
  final ReminderService reminders;
  final BriefGenerator? briefGenerator;
  final HealthService? health;
  final WidgetSync? widgets;
  final AppShortcuts shortcuts;
  final CalendarService? calendar;

  const OnoApp({
    super.key,
    required this.authGateway,
    required this.personalGateway,
    required this.reminders,
    this.briefGenerator,
    this.health,
    this.widgets,
    this.shortcuts = const NoopAppShortcuts(),
    this.calendar,
  });

  @override
  State<OnoApp> createState() => _OnoAppState();
}

class _OnoAppState extends State<OnoApp> {
  late final AuthProvider _auth;
  late final PersonalSystemProvider _system;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(gateway: widget.authGateway);
    _system = PersonalSystemProvider(
      gateway: widget.personalGateway,
      reminders: widget.reminders,
      briefGenerator: widget.briefGenerator,
      health: widget.health,
      widgets: widget.widgets,
      calendar: widget.calendar,
    );
    _router = createRouter(_auth);
    _auth.addListener(_onAuth);
    _auth.init();
    widget.reminders.init(onOpen: _open);
    widget.shortcuts.init(onOpen: _open);
  }

  /// A route from a notification or Home Screen shortcut. On a cold start
  /// sign-in isn't restored yet, so it waits for it.
  String? _pendingRoute;

  void _open(String route) {
    if (_auth.status == AuthStatus.authenticated) {
      _router.push(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<void> _onAuth() async {
    if (_auth.status != AuthStatus.authenticated) return;
    await _system.load(_auth.userId);
    final route = _pendingRoute;
    _pendingRoute = null;
    if (route == null || !_system.isCommissioned) return;
    // Today underneath, so Back from the shortcut's screen lands there.
    _router.go('/home');
    _router.push(route);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    _auth.dispose();
    _system.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<PersonalSystemProvider>.value(value: _system),
      ],
      child: MaterialApp.router(
        title: 'ONO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        // The iPhone number pad has no Return key: tapping outside a field
        // is the only way to close it.
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: PhoneFrame(child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}

/// ONO is laid out for a phone. On a wider window (the web app on a
/// laptop) it keeps a phone-width column in the middle, so cards and
/// sheets don't stretch across the screen.
class PhoneFrame extends StatelessWidget {
  static const maxWidth = 480.0;
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth + 40) return child;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}

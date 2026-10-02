import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'gateways/auth_gateway.dart';
import 'gateways/personal_system_gateway.dart';
import 'providers/auth_provider.dart';
import 'providers/personal_system_provider.dart';
import 'router.dart';
import 'services/brief_generator.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';

/// The app, independent of where data lives. `main.dart` wires it to
/// on-device storage; `main_production.dart` to Supabase.
class OnoApp extends StatefulWidget {
  final AuthGateway authGateway;
  final PersonalSystemGateway personalGateway;
  final ReminderService reminders;
  final BriefGenerator? briefGenerator;

  const OnoApp({
    super.key,
    required this.authGateway,
    required this.personalGateway,
    required this.reminders,
    this.briefGenerator,
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
    );
    _router = createRouter(_auth);
    _auth.addListener(_onAuth);
    _auth.init();
    widget.reminders.init(onOpen: (route) {
      if (_auth.status == AuthStatus.authenticated) _router.push(route);
    });
  }

  void _onAuth() {
    if (_auth.status == AuthStatus.authenticated) _system.load(_auth.userId);
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
          child: child,
        ),
      ),
    );
  }
}

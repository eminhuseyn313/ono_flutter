import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'gateways/mock_auth_gateway.dart';
import 'gateways/mock_personal_system_gateway.dart';
import 'services/app_shortcuts.dart';
import 'services/health_service.dart';
import 'services/reminder_service.dart';
import 'services/widget_sync.dart';

export 'app.dart';

/// Offline mode: sign-in and all data live on this device.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(OnoApp(
    authGateway: MockAuthGateway(),
    personalGateway: MockPersonalSystemGateway(),
    reminders: kIsWeb ? NoopReminderService() : LocalReminderService(),
    health: createHealthService(),
    widgets: createWidgetSync(),
    shortcuts: kIsWeb ? const NoopAppShortcuts() : QuickActionShortcuts(),
  ));
}

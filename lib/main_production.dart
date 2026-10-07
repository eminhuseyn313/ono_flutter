/// Production entry point: Supabase auth, the personal system mirrored to
/// the `personal_system` table, and the Claude-written weekly brief from the
/// `weekly-brief` edge function.
///
/// Setup (once):
///   supabase db push                      # applies supabase/migrations
///   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
///   supabase functions deploy weekly-brief
///
/// Run: flutter run -t lib/main_production.dart
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'gateways/supabase_auth_gateway.dart';
import 'gateways/supabase_personal_system_gateway.dart';
import 'services/brief_generator.dart';
import 'services/app_shortcuts.dart';
import 'services/calendar_service.dart';
import 'services/health_service.dart';
import 'services/reminder_service.dart';
import 'services/widget_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://kkgkbfxvovrtmnoezcha.supabase.co',
    // Publishable (anon) key — safe in the client; RLS protects the data.
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrZ2tiZnh2b3ZydG1ub2V6Y2hhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU4NzA0NDMsImV4cCI6MjEwMTQ0NjQ0M30.d_a-m0D73Bv_mCcvgopurhI0axvHQj3Ng26A4tedhIk',
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final client = Supabase.instance.client;
  runApp(OnoApp(
    authGateway: SupabaseAuthGateway(client),
    personalGateway: SyncedPersonalSystemGateway(client),
    reminders: kIsWeb ? NoopReminderService() : LocalReminderService(),
    health: createHealthService(),
    widgets: createWidgetSync(),
    calendar: createCalendarService(),
    shortcuts: kIsWeb ? const NoopAppShortcuts() : QuickActionShortcuts(),
    briefGenerator: RemoteBriefGenerator((body) async {
      final res = await client.functions.invoke('weekly-brief', body: body);
      return Map<String, dynamic>.from(res.data as Map);
    }),
  ));
}

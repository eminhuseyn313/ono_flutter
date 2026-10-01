/// Production entry point for Ono.
///
/// This file shows how to initialise Supabase and wire in the production
/// gateways. To use it:
///   1. Run the migration in supabase/migrations/ against your project.
///   2. Deploy the generate-blueprint Edge Function.
///   3. Set ANTHROPIC_API_KEY as a secret on your Supabase project.
///   4. Replace the Supabase URL and anon key below with your own.
///   5. Build with: flutter run --target lib/main_production.dart
///
/// The mock entry point (lib/main.dart) continues to work offline with no
/// backend — useful for UI iteration and testing.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';

// Gateways
import 'gateways/auth_gateway.dart';
import 'gateways/supabase_auth_gateway.dart';
import 'gateways/profile_gateway.dart';
import 'gateways/supabase_profile_gateway.dart';
import 'gateways/actions_gateway.dart';
import 'gateways/supabase_actions_gateway.dart';
import 'gateways/progress_gateway.dart';
import 'gateways/supabase_progress_gateway.dart';
import 'gateways/blueprint_gateway.dart';
import 'gateways/supabase_blueprint_gateway.dart';

// Sprint 1 gateways
import 'gateways/reflections_gateway.dart';
import 'gateways/mock_reflections_gateway.dart'; // TODO: SupabaseReflectionsGateway
import 'gateways/apprentice_gateway.dart';
import 'gateways/mock_apprentice_gateway.dart'; // TODO: SupabaseApprenticeGateway
import 'gateways/time_capsule_gateway.dart';
import 'gateways/mock_time_capsule_gateway.dart'; // TODO: SupabaseTimeCapsuleGateway

// Sprint 2 gateways
import 'gateways/monk_mode_gateway.dart';
import 'gateways/mock_monk_mode_gateway.dart'; // TODO: SupabaseMonkModeGateway
import 'gateways/legacy_score_gateway.dart';
import 'gateways/mock_legacy_score_gateway.dart'; // TODO: SupabaseLegacyScoreGateway
import 'gateways/notification_gateway.dart';
import 'gateways/mock_notification_gateway.dart'; // TODO: SupabaseNotificationGateway
import 'gateways/becoming_arc_gateway.dart';
import 'gateways/mock_becoming_arc_gateway.dart'; // TODO: SupabaseBecomingArcGateway

// Sprint 4 gateways
import 'gateways/ghost_mode_gateway.dart';
import 'gateways/mock_ghost_mode_gateway.dart'; // TODO: SupabaseGhostModeGateway
import 'gateways/ritual_gateway.dart';
import 'gateways/mock_ritual_gateway.dart'; // TODO: SupabaseRitualGateway
import 'gateways/council_gateway.dart';
import 'gateways/mock_council_gateway.dart'; // TODO: SupabaseCouncilGateway

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/daily_actions_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/blueprint_provider.dart';
import 'providers/theme_provider.dart';

// Sprint 1 providers
import 'providers/reflections_provider.dart';
import 'providers/apprentice_provider.dart';
import 'providers/time_capsule_provider.dart';

// Sprint 2 providers
import 'providers/monk_mode_provider.dart';
import 'providers/legacy_score_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/becoming_arc_provider.dart';
import 'providers/ghost_mode_provider.dart';
import 'providers/ritual_provider.dart';
import 'providers/council_provider.dart';

// Sprint 5
import 'providers/time_mode_provider.dart';
import 'gateways/brotherhood_gateway.dart';
import 'gateways/mock_brotherhood_gateway.dart'; // TODO: SupabaseBrotherhoodGateway
import 'providers/brotherhood_provider.dart';
import 'gateways/radio_gateway.dart';
import 'gateways/mock_radio_gateway.dart'; // TODO: SupabaseRadioGateway
import 'providers/radio_provider.dart';
import 'gateways/trending_gateway.dart';
import 'gateways/mock_trending_gateway.dart'; // TODO: SupabaseTrendingGateway
import 'providers/trending_provider.dart';

// Sprint 6
import 'gateways/mirror_match_gateway.dart';
import 'gateways/mock_mirror_match_gateway.dart'; // TODO: SupabaseMirrorMatchGateway
import 'providers/mirror_match_provider.dart';
import 'gateways/forge_gateway.dart';
import 'gateways/mock_forge_gateway.dart'; // TODO: SupabaseForgeGateway
import 'providers/forge_provider.dart';
import 'gateways/adaptive_engine_gateway.dart';
import 'gateways/mock_adaptive_engine_gateway.dart'; // TODO: SupabaseAdaptiveEngineGateway
import 'providers/adaptive_engine_provider.dart';

// Sprint 7
import 'gateways/wakz_gateway.dart';
import 'gateways/mock_wakz_gateway.dart'; // TODO: SupabaseWakzGateway
import 'providers/wakz_provider.dart';

// Sprint 8
import 'gateways/accountability_gateway.dart';
import 'gateways/mock_accountability_gateway.dart'; // TODO: SupabaseAccountabilityGateway
import 'providers/accountability_provider.dart';
import 'gateways/vault_gateway.dart';
import 'gateways/mock_vault_gateway.dart'; // TODO: SupabaseVaultGateway
import 'providers/vault_provider.dart';
import 'gateways/gamification_gateway.dart';
import 'gateways/mock_gamification_gateway.dart'; // TODO: SupabaseGamificationGateway
import 'providers/gamification_provider.dart';

// Sprint 9
import 'gateways/planner_gateway.dart';
import 'gateways/mock_planner_gateway.dart'; // TODO: SupabasePlannerGateway
import 'providers/planner_provider.dart';
import 'gateways/vision_board_gateway.dart';
import 'gateways/mock_vision_board_gateway.dart'; // TODO: SupabaseVisionBoardGateway
import 'providers/vision_board_provider.dart';
import 'gateways/power_rankings_gateway.dart';
import 'gateways/mock_power_rankings_gateway.dart'; // TODO: SupabasePowerRankingsGateway
import 'providers/power_rankings_provider.dart';

// Sprint 10
import 'gateways/settings_gateway.dart';
import 'gateways/mock_settings_gateway.dart'; // TODO: SupabaseSettingsGateway
import 'providers/settings_provider.dart';
import 'gateways/onboarding_gateway.dart';
import 'gateways/mock_onboarding_gateway.dart'; // TODO: SupabaseOnboardingGateway
import 'providers/onboarding_provider.dart';
import 'gateways/dashboard_gateway.dart';
import 'gateways/mock_dashboard_gateway.dart'; // TODO: SupabaseDashboardGateway
import 'providers/dashboard_provider.dart';

// Sprint 11
import 'gateways/achievement_gateway.dart';
import 'gateways/mock_achievement_gateway.dart'; // TODO: SupabaseAchievementGateway
import 'providers/achievement_provider.dart';
import 'gateways/analytics_gateway.dart';
import 'gateways/mock_analytics_gateway.dart'; // TODO: SupabaseAnalyticsGateway
import 'providers/analytics_provider.dart';
import 'gateways/weekly_review_gateway.dart';
import 'gateways/mock_weekly_review_gateway.dart'; // TODO: SupabaseWeeklyReviewGateway
import 'providers/weekly_review_provider.dart';

// Sprint 12
import 'gateways/social_feed_gateway.dart';
import 'gateways/mock_social_feed_gateway.dart'; // TODO: SupabaseSocialFeedGateway
import 'providers/social_feed_provider.dart';
import 'gateways/habit_streak_gateway.dart';
import 'gateways/mock_habit_streak_gateway.dart'; // TODO: SupabaseHabitStreakGateway
import 'providers/habit_streak_provider.dart';
import 'gateways/daily_checkin_gateway.dart';
import 'gateways/mock_daily_checkin_gateway.dart'; // TODO: SupabaseDailyCheckinGateway
import 'providers/daily_checkin_provider.dart';

// Sprint 13
import 'gateways/ai_coach_gateway.dart';
import 'gateways/mock_ai_coach_gateway.dart'; // TODO: SupabaseAiCoachGateway
import 'providers/ai_coach_provider.dart';
import 'gateways/content_library_gateway.dart';
import 'gateways/mock_content_library_gateway.dart'; // TODO: SupabaseContentLibraryGateway
import 'providers/content_library_provider.dart';
import 'gateways/community_challenge_gateway.dart';
import 'gateways/mock_community_challenge_gateway.dart'; // TODO: SupabaseCommunityChallengeGateway
import 'providers/community_challenge_provider.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase ─────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: 'https://kkgkbfxvovrtmnoezcha.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrZ2tiZnh2b3ZydG1ub2V6Y2hhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU4NzA0NDMsImV4cCI6MjEwMTQ0NjQ0M30.d_a-m0D73Bv_mCcvgopurhI0axvHQj3Ng26A4tedhIk',
  );

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const OnoApp());
}

class OnoApp extends StatefulWidget {
  const OnoApp({super.key});

  @override
  State<OnoApp> createState() => _OnoAppState();
}

class _OnoAppState extends State<OnoApp> {
  late final SupabaseClient _supabase;

  // ── Core Gateways ────────────────────────────────────────────────────
  late final AuthGateway _authGateway;
  late final ProfileGateway _profileGateway;
  late final ActionsGateway _actionsGateway;
  late final ProgressGateway _progressGateway;
  late final BlueprintGateway _blueprintGateway;

  // ── Sprint 1 Gateways ───────────────────────────────────────────────
  late final ReflectionsGateway _reflectionsGateway;
  late final ApprenticeGateway _apprenticeGateway;
  late final TimeCapsuleGateway _timeCapsuleGateway;

  // ── Sprint 2 Gateways ───────────────────────────────────────────────
  late final MonkModeGateway _monkModeGateway;
  late final LegacyScoreGateway _legacyScoreGateway;
  late final NotificationGateway _notificationGateway;
  late final BecomingArcGateway _becomingArcGateway;

  // ── Sprint 4 Gateways ───────────────────────────────────────────────
  late final GhostModeGateway _ghostModeGateway;
  late final RitualGateway _ritualGateway;
  late final CouncilGateway _councilGateway;

  // ── Sprint 5 Gateways ───────────────────────────────────────────────
  late final BrotherhoodGateway _brotherhoodGateway;
  late final RadioGateway _radioGateway;
  late final TrendingGateway _trendingGateway;

  // ── Sprint 6 Gateways ───────────────────────────────────────────────
  late final MirrorMatchGateway _mirrorMatchGateway;
  late final ForgeGateway _forgeGateway;
  late final AdaptiveEngineGateway _adaptiveEngineGateway;

  // ── Sprint 7 Gateways ───────────────────────────────────────────────
  late final WakzGateway _wakzGateway;

  // ── Sprint 8 Gateways ───────────────────────────────────────────────
  late final AccountabilityGateway _accountabilityGateway;
  late final VaultGateway _vaultGateway;
  late final GamificationGateway _gamificationGateway;

  // ── Sprint 9 Gateways ───────────────────────────────────────────────
  late final PlannerGateway _plannerGateway;
  late final VisionBoardGateway _visionBoardGateway;
  late final PowerRankingsGateway _powerRankingsGateway;

  // ── Sprint 10 Gateways ──────────────────────────────────────────────
  late final SettingsGateway _settingsGateway;
  late final OnboardingGateway _onboardingGateway;
  late final DashboardGateway _dashboardGateway;

  // ── Sprint 11 Gateways ──────────────────────────────────────────────
  late final AchievementGateway _achievementGateway;
  late final AnalyticsGateway _analyticsGateway;
  late final WeeklyReviewGateway _weeklyReviewGateway;

  // ── Sprint 12 Gateways ──────────────────────────────────────────────
  late final SocialFeedGateway _socialFeedGateway;
  late final HabitStreakGateway _habitStreakGateway;
  late final DailyCheckinGateway _dailyCheckinGateway;

  // ── Sprint 13 Gateways ──────────────────────────────────────────────
  late final AiCoachGateway _aiCoachGateway;
  late final ContentLibraryGateway _contentLibraryGateway;
  late final CommunityChallengeGateway _communityChallengeGateway;

  // ── Core Providers ──────────────────────────────────────────────────
  late final AuthProvider _authProvider;
  late final UserProfileProvider _profileProvider;
  late final DailyActionsProvider _actionsProvider;
  late final ProgressProvider _progressProvider;
  late final BlueprintProvider _blueprintProvider;
  late final ThemeProvider _themeProvider;

  // ── Sprint 1 Providers ──────────────────────────────────────────────
  late final ReflectionsProvider _reflectionsProvider;
  late final ApprenticeProvider _apprenticeProvider;
  late final TimeCapsuleProvider _timeCapsuleProvider;

  // ── Sprint 2 Providers ──────────────────────────────────────────────
  late final MonkModeProvider _monkModeProvider;
  late final LegacyScoreProvider _legacyScoreProvider;
  late final NotificationProvider _notificationProvider;
  late final BecomingArcProvider _becomingArcProvider;

  // ── Sprint 4 Providers ──────────────────────────────────────────────
  late final GhostModeProvider _ghostModeProvider;
  late final RitualProvider _ritualProvider;
  late final CouncilProvider _councilProvider;

  // ── Sprint 5 Providers ──────────────────────────────────────────────
  late final TimeModeProvider _timeModeProvider;
  late final BrotherhoodProvider _brotherhoodProvider;
  late final RadioProvider _radioProvider;
  late final TrendingProvider _trendingProvider;

  // ── Sprint 6 Providers ──────────────────────────────────────────────
  late final MirrorMatchProvider _mirrorMatchProvider;
  late final ForgeProvider _forgeProvider;
  late final AdaptiveEngineProvider _adaptiveEngineProvider;

  // ── Sprint 7 Providers ──────────────────────────────────────────────
  late final WakzProvider _wakzProvider;

  // ── Sprint 8 Providers ──────────────────────────────────────────────
  late final AccountabilityProvider _accountabilityProvider;
  late final VaultProvider _vaultProvider;
  late final GamificationProvider _gamificationProvider;

  // ── Sprint 9 Providers ──────────────────────────────────────────────
  late final PlannerProvider _plannerProvider;
  late final VisionBoardProvider _visionBoardProvider;
  late final PowerRankingsProvider _powerRankingsProvider;

  // ── Sprint 10 Providers ─────────────────────────────────────────────
  late final SettingsProvider _settingsProvider;
  late final OnboardingProvider _onboardingProvider;
  late final DashboardProvider _dashboardProvider;

  // ── Sprint 11 Providers ─────────────────────────────────────────────
  late final AchievementProvider _achievementProvider;
  late final AnalyticsProvider _analyticsProvider;
  late final WeeklyReviewProvider _weeklyReviewProvider;

  // ── Sprint 12 Providers ─────────────────────────────────────────────
  late final SocialFeedProvider _socialFeedProvider;
  late final HabitStreakProvider _habitStreakProvider;
  late final DailyCheckinProvider _dailyCheckinProvider;

  // ── Sprint 13 Providers ─────────────────────────────────────────────
  late final AiCoachProvider _aiCoachProvider;
  late final ContentLibraryProvider _contentLibraryProvider;
  late final CommunityChallengeProvider _communityChallengeProvider;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _supabase = Supabase.instance.client;

    // ── Core: Production gateways — all talk to Supabase ──────────────
    _authGateway = SupabaseAuthGateway(_supabase);
    _profileGateway = SupabaseProfileGateway(_supabase);
    _actionsGateway = SupabaseActionsGateway(_supabase);
    _progressGateway = SupabaseProgressGateway(_supabase);
    _blueprintGateway = SupabaseBlueprintGateway(_supabase);

    // ── Sprint 1: Mock for now — swap with Supabase impls when ready ──
    _reflectionsGateway = MockReflectionsGateway();
    _apprenticeGateway = MockApprenticeGateway();
    _timeCapsuleGateway = MockTimeCapsuleGateway();

    // ── Sprint 2: Mock for now — swap with Supabase impls when ready ──
    _monkModeGateway = MockMonkModeGateway();
    _legacyScoreGateway = MockLegacyScoreGateway();
    _notificationGateway = MockNotificationGateway();
    _becomingArcGateway = MockBecomingArcGateway();

    // ── Sprint 4: Mock for now — swap with Supabase impls when ready ──
    _ghostModeGateway = MockGhostModeGateway();
    _ritualGateway = MockRitualGateway();
    _councilGateway = MockCouncilGateway();

    // ── Sprint 5: Mock for now — swap with Supabase impls when ready ──
    _brotherhoodGateway = MockBrotherhoodGateway();
    _radioGateway = MockRadioGateway();
    _trendingGateway = MockTrendingGateway();

    // ── Sprint 6: Mock for now — swap with Supabase impls when ready ──
    _mirrorMatchGateway = MockMirrorMatchGateway();
    _forgeGateway = MockForgeGateway();
    _adaptiveEngineGateway = MockAdaptiveEngineGateway();

    // ── Sprint 7: Mock for now — swap with Supabase impls when ready ──
    _wakzGateway = MockWakzGateway();

    // ── Sprint 8: Mock for now — swap with Supabase impls when ready ──
    _accountabilityGateway = MockAccountabilityGateway();
    _vaultGateway = MockVaultGateway();
    _gamificationGateway = MockGamificationGateway();

    // ── Sprint 9: Mock for now — swap with Supabase impls when ready ──
    _plannerGateway = MockPlannerGateway();
    _visionBoardGateway = MockVisionBoardGateway();
    _powerRankingsGateway = MockPowerRankingsGateway();

    // ── Sprint 10: Mock for now — swap with Supabase impls when ready ──
    _settingsGateway = MockSettingsGateway();
    _onboardingGateway = MockOnboardingGateway();
    _dashboardGateway = MockDashboardGateway();

    // ── Sprint 11: Mock for now — swap with Supabase impls when ready ──
    _achievementGateway = MockAchievementGateway();
    _analyticsGateway = MockAnalyticsGateway();
    _weeklyReviewGateway = MockWeeklyReviewGateway();

    // ── Sprint 12: Mock for now — swap with Supabase impls when ready ──
    _socialFeedGateway = MockSocialFeedGateway();
    _habitStreakGateway = MockHabitStreakGateway();
    _dailyCheckinGateway = MockDailyCheckinGateway();

    // ── Sprint 13: Mock for now — swap with Supabase impls when ready ──
    _aiCoachGateway = MockAiCoachGateway();
    _contentLibraryGateway = MockContentLibraryGateway();
    _communityChallengeGateway = MockCommunityChallengeGateway();

    // ── Core Providers ────────────────────────────────────────────────
    _authProvider = AuthProvider(gateway: _authGateway);
    _profileProvider = UserProfileProvider(gateway: _profileGateway);
    _actionsProvider = DailyActionsProvider(gateway: _actionsGateway);
    _progressProvider = ProgressProvider(gateway: _progressGateway);
    _blueprintProvider = BlueprintProvider(_blueprintGateway);
    _themeProvider = ThemeProvider();

    // ── Sprint 1 Providers ────────────────────────────────────────────
    _reflectionsProvider = ReflectionsProvider(gateway: _reflectionsGateway);
    _apprenticeProvider = ApprenticeProvider(gateway: _apprenticeGateway);
    _timeCapsuleProvider = TimeCapsuleProvider(_timeCapsuleGateway);

    // ── Sprint 2 Providers ────────────────────────────────────────────
    _monkModeProvider = MonkModeProvider(gateway: _monkModeGateway);
    _legacyScoreProvider = LegacyScoreProvider(gateway: _legacyScoreGateway);
    _notificationProvider = NotificationProvider(gateway: _notificationGateway);
    _becomingArcProvider = BecomingArcProvider(gateway: _becomingArcGateway);

    // ── Sprint 4 Providers ────────────────────────────────────────────
    _ghostModeProvider = GhostModeProvider(gateway: _ghostModeGateway);
    _ritualProvider = RitualProvider(gateway: _ritualGateway);
    _councilProvider = CouncilProvider(gateway: _councilGateway);

    // ── Sprint 5 Providers ────────────────────────────────────────────
    _timeModeProvider = TimeModeProvider();
    _brotherhoodProvider = BrotherhoodProvider(gateway: _brotherhoodGateway);
    _radioProvider = RadioProvider(gateway: _radioGateway);
    _trendingProvider = TrendingProvider(gateway: _trendingGateway);

    // ── Sprint 6 Providers ────────────────────────────────────────────
    _mirrorMatchProvider = MirrorMatchProvider(gateway: _mirrorMatchGateway);
    _forgeProvider = ForgeProvider(gateway: _forgeGateway);
    _adaptiveEngineProvider =
        AdaptiveEngineProvider(gateway: _adaptiveEngineGateway);

    // ── Sprint 7 Providers ────────────────────────────────────────────
    _wakzProvider = WakzProvider(gateway: _wakzGateway);

    // ── Sprint 8 Providers ────────────────────────────────────────────
    _accountabilityProvider =
        AccountabilityProvider(gateway: _accountabilityGateway);
    _vaultProvider = VaultProvider(gateway: _vaultGateway);
    _gamificationProvider =
        GamificationProvider(gateway: _gamificationGateway);

    // ── Sprint 9 Providers ────────────────────────────────────────────
    _plannerProvider = PlannerProvider(gateway: _plannerGateway);
    _visionBoardProvider = VisionBoardProvider(gateway: _visionBoardGateway);
    _powerRankingsProvider =
        PowerRankingsProvider(gateway: _powerRankingsGateway);

    // ── Sprint 10 Providers ────────────────────────────────────────────
    _settingsProvider = SettingsProvider(gateway: _settingsGateway);
    _onboardingProvider = OnboardingProvider(gateway: _onboardingGateway);
    _dashboardProvider = DashboardProvider(gateway: _dashboardGateway);

    // ── Sprint 11 Providers ────────────────────────────────────────────
    _achievementProvider = AchievementProvider(gateway: _achievementGateway);
    _analyticsProvider = AnalyticsProvider(gateway: _analyticsGateway);
    _weeklyReviewProvider = WeeklyReviewProvider(gateway: _weeklyReviewGateway);

    // ── Sprint 12 Providers ────────────────────────────────────────────
    _socialFeedProvider = SocialFeedProvider(gateway: _socialFeedGateway);
    _habitStreakProvider = HabitStreakProvider(gateway: _habitStreakGateway);
    _dailyCheckinProvider = DailyCheckinProvider(gateway: _dailyCheckinGateway);

    // ── Sprint 13 Providers ────────────────────────────────────────────
    _aiCoachProvider = AiCoachProvider(gateway: _aiCoachGateway);
    _contentLibraryProvider = ContentLibraryProvider(gateway: _contentLibraryGateway);
    _communityChallengeProvider = CommunityChallengeProvider(gateway: _communityChallengeGateway);

    // Router
    _router = createRouter(_authProvider);

    // Kick off auth
    _authProvider.init();
    _authProvider.listenToAuthChanges();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _profileProvider.dispose();
    _actionsProvider.dispose();
    _progressProvider.dispose();
    _blueprintProvider.dispose();

    // Sprint 1
    _reflectionsProvider.dispose();
    _apprenticeProvider.dispose();
    _timeCapsuleProvider.dispose();

    // Sprint 2
    _monkModeProvider.dispose();
    _legacyScoreProvider.dispose();
    _notificationProvider.dispose();
    _becomingArcProvider.dispose();

    // Sprint 4
    _ghostModeProvider.dispose();
    _ritualProvider.dispose();
    _councilProvider.dispose();

    // Sprint 5
    _timeModeProvider.dispose();
    _brotherhoodProvider.dispose();
    _radioProvider.dispose();
    _trendingProvider.dispose();

    // Sprint 6
    _mirrorMatchProvider.dispose();
    _forgeProvider.dispose();
    _adaptiveEngineProvider.dispose();

    // Sprint 7
    _wakzProvider.dispose();

    // Sprint 8
    _accountabilityProvider.dispose();
    _vaultProvider.dispose();
    _gamificationProvider.dispose();

    // Sprint 9
    _plannerProvider.dispose();
    _visionBoardProvider.dispose();
    _powerRankingsProvider.dispose();

    // Sprint 10
    _settingsProvider.dispose();
    _onboardingProvider.dispose();
    _dashboardProvider.dispose();

    // Sprint 11
    _achievementProvider.dispose();
    _analyticsProvider.dispose();
    _weeklyReviewProvider.dispose();

    // Sprint 12
    _socialFeedProvider.dispose();
    _habitStreakProvider.dispose();
    _dailyCheckinProvider.dispose();

    // Sprint 13
    _aiCoachProvider.dispose();
    _contentLibraryProvider.dispose();
    _communityChallengeProvider.dispose();

    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Core ──────────────────────────────────────────────────────
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        Provider<AuthGateway>.value(value: _authGateway),
        ChangeNotifierProvider<UserProfileProvider>.value(
            value: _profileProvider),
        Provider<ProfileGateway>.value(value: _profileGateway),
        ChangeNotifierProvider<DailyActionsProvider>.value(
            value: _actionsProvider),
        Provider<ActionsGateway>.value(value: _actionsGateway),
        ChangeNotifierProvider<ProgressProvider>.value(
            value: _progressProvider),
        Provider<ProgressGateway>.value(value: _progressGateway),
        ChangeNotifierProvider<BlueprintProvider>.value(
            value: _blueprintProvider),
        Provider<BlueprintGateway>.value(value: _blueprintGateway),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),

        // ── Sprint 1 ─────────────────────────────────────────────────
        ChangeNotifierProvider<ReflectionsProvider>.value(
            value: _reflectionsProvider),
        Provider<ReflectionsGateway>.value(value: _reflectionsGateway),
        ChangeNotifierProvider<ApprenticeProvider>.value(
            value: _apprenticeProvider),
        Provider<ApprenticeGateway>.value(value: _apprenticeGateway),
        ChangeNotifierProvider<TimeCapsuleProvider>.value(
            value: _timeCapsuleProvider),
        Provider<TimeCapsuleGateway>.value(value: _timeCapsuleGateway),

        // ── Sprint 2 ─────────────────────────────────────────────────
        ChangeNotifierProvider<MonkModeProvider>.value(
            value: _monkModeProvider),
        Provider<MonkModeGateway>.value(value: _monkModeGateway),
        ChangeNotifierProvider<LegacyScoreProvider>.value(
            value: _legacyScoreProvider),
        Provider<LegacyScoreGateway>.value(value: _legacyScoreGateway),
        ChangeNotifierProvider<NotificationProvider>.value(
            value: _notificationProvider),
        Provider<NotificationGateway>.value(value: _notificationGateway),

        // ── Sprint 3 ─────────────────────────────────────────────────
        ChangeNotifierProvider<BecomingArcProvider>.value(
            value: _becomingArcProvider),
        Provider<BecomingArcGateway>.value(value: _becomingArcGateway),

        // ── Sprint 4 ─────────────────────────────────────────────────
        ChangeNotifierProvider<GhostModeProvider>.value(
            value: _ghostModeProvider),
        Provider<GhostModeGateway>.value(value: _ghostModeGateway),
        ChangeNotifierProvider<RitualProvider>.value(
            value: _ritualProvider),
        Provider<RitualGateway>.value(value: _ritualGateway),
        ChangeNotifierProvider<CouncilProvider>.value(
            value: _councilProvider),
        Provider<CouncilGateway>.value(value: _councilGateway),

        // ── Sprint 5 ─────────────────────────────────────────────────
        ChangeNotifierProvider<TimeModeProvider>.value(
            value: _timeModeProvider),
        ChangeNotifierProvider<BrotherhoodProvider>.value(
            value: _brotherhoodProvider),
        Provider<BrotherhoodGateway>.value(value: _brotherhoodGateway),
        ChangeNotifierProvider<RadioProvider>.value(
            value: _radioProvider),
        Provider<RadioGateway>.value(value: _radioGateway),
        ChangeNotifierProvider<TrendingProvider>.value(
            value: _trendingProvider),
        Provider<TrendingGateway>.value(value: _trendingGateway),

        // ── Sprint 6 ─────────────────────────────────────────────────
        ChangeNotifierProvider<MirrorMatchProvider>.value(
            value: _mirrorMatchProvider),
        Provider<MirrorMatchGateway>.value(value: _mirrorMatchGateway),
        ChangeNotifierProvider<ForgeProvider>.value(
            value: _forgeProvider),
        Provider<ForgeGateway>.value(value: _forgeGateway),
        ChangeNotifierProvider<AdaptiveEngineProvider>.value(
            value: _adaptiveEngineProvider),
        Provider<AdaptiveEngineGateway>.value(value: _adaptiveEngineGateway),

        // ── Sprint 7 ─────────────────────────────────────────────────
        ChangeNotifierProvider<WakzProvider>.value(
            value: _wakzProvider),
        Provider<WakzGateway>.value(value: _wakzGateway),

        // ── Sprint 8 ─────────────────────────────────────────────────
        ChangeNotifierProvider<AccountabilityProvider>.value(
            value: _accountabilityProvider),
        Provider<AccountabilityGateway>.value(value: _accountabilityGateway),
        ChangeNotifierProvider<VaultProvider>.value(
            value: _vaultProvider),
        Provider<VaultGateway>.value(value: _vaultGateway),
        ChangeNotifierProvider<GamificationProvider>.value(
            value: _gamificationProvider),
        Provider<GamificationGateway>.value(value: _gamificationGateway),

        // ── Sprint 9 ─────────────────────────────────────────────────
        ChangeNotifierProvider<PlannerProvider>.value(
            value: _plannerProvider),
        Provider<PlannerGateway>.value(value: _plannerGateway),
        ChangeNotifierProvider<VisionBoardProvider>.value(
            value: _visionBoardProvider),
        Provider<VisionBoardGateway>.value(value: _visionBoardGateway),
        ChangeNotifierProvider<PowerRankingsProvider>.value(
            value: _powerRankingsProvider),
        Provider<PowerRankingsGateway>.value(value: _powerRankingsGateway),

        // ── Sprint 10 ─────────────────────────────────────────────────
        ChangeNotifierProvider<SettingsProvider>.value(
            value: _settingsProvider),
        Provider<SettingsGateway>.value(value: _settingsGateway),
        ChangeNotifierProvider<OnboardingProvider>.value(
            value: _onboardingProvider),
        Provider<OnboardingGateway>.value(value: _onboardingGateway),
        ChangeNotifierProvider<DashboardProvider>.value(
            value: _dashboardProvider),
        Provider<DashboardGateway>.value(value: _dashboardGateway),

        // ── Sprint 11 ─────────────────────────────────────────────────
        ChangeNotifierProvider<AchievementProvider>.value(
            value: _achievementProvider),
        Provider<AchievementGateway>.value(value: _achievementGateway),
        ChangeNotifierProvider<AnalyticsProvider>.value(
            value: _analyticsProvider),
        Provider<AnalyticsGateway>.value(value: _analyticsGateway),
        ChangeNotifierProvider<WeeklyReviewProvider>.value(
            value: _weeklyReviewProvider),
        Provider<WeeklyReviewGateway>.value(value: _weeklyReviewGateway),

        // ── Sprint 12 ─────────────────────────────────────────────────
        ChangeNotifierProvider<SocialFeedProvider>.value(
            value: _socialFeedProvider),
        Provider<SocialFeedGateway>.value(value: _socialFeedGateway),
        ChangeNotifierProvider<HabitStreakProvider>.value(
            value: _habitStreakProvider),
        Provider<HabitStreakGateway>.value(value: _habitStreakGateway),
        ChangeNotifierProvider<DailyCheckinProvider>.value(
            value: _dailyCheckinProvider),
        Provider<DailyCheckinGateway>.value(value: _dailyCheckinGateway),

        // ── Sprint 13 ─────────────────────────────────────────────────
        ChangeNotifierProvider<AiCoachProvider>.value(
            value: _aiCoachProvider),
        Provider<AiCoachGateway>.value(value: _aiCoachGateway),
        ChangeNotifierProvider<ContentLibraryProvider>.value(
            value: _contentLibraryProvider),
        Provider<ContentLibraryGateway>.value(value: _contentLibraryGateway),
        ChangeNotifierProvider<CommunityChallengeProvider>.value(
            value: _communityChallengeProvider),
        Provider<CommunityChallengeGateway>.value(value: _communityChallengeGateway),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp.router(
          title: 'Ono',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/archetype_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/blueprint_loading_screen.dart';
import 'screens/blueprint_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/weekly_review_screen.dart';
import 'screens/role_models_screen.dart';
import 'screens/role_model_detail_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/habit_heat_map_screen.dart';
import 'screens/morning_ritual_screen.dart';
import 'screens/lane_analytics_screen.dart';

// Sprint 2 screens
import 'screens/monk_mode_screen.dart';
import 'screens/legacy_score_screen.dart';
import 'screens/notification_center_screen.dart';

// Sprint 3 screens
import 'screens/becoming_arc_screen.dart';
import 'screens/arc_layer_screen.dart';
import 'screens/self_assessment_screen.dart';
import 'screens/notification_feed_screen.dart';
import 'models/becoming_arc.dart';

// Sprint 4 screens
import 'screens/ghost_mode_screen.dart';
import 'screens/ritual_flow_screen.dart';
import 'screens/ritual_setup_screen.dart';
import 'screens/council_screen.dart';
import 'screens/phase_transition_screen.dart';
import 'models/phase_transition.dart';

// Sprint 5 screens
import 'screens/time_mode_screen.dart';
import 'screens/brotherhood_screen.dart';
import 'screens/radio_screen.dart';
import 'screens/trending_screen.dart';

// Sprint 6 screens
import 'screens/mirror_match_screen.dart';
import 'screens/forge_screen.dart';
import 'screens/forge_course_screen.dart';
import 'screens/forge_lesson_screen.dart';
import 'screens/adaptive_settings_screen.dart';

// Sprint 7 screens
import 'screens/wakz_challenges_screen.dart';
import 'screens/forge_analytics_screen.dart';

// Sprint 8 screens
import 'screens/accountability_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/gamification_screen.dart';

// Sprint 9 screens
import 'screens/planner_screen.dart';
import 'screens/vision_board_screen.dart';
import 'screens/power_rankings_screen.dart';

// Sprint 10 screens
import 'screens/settings_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'screens/dashboard_screen.dart';

// Sprint 11 screens
import 'screens/achievement_hub_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/weekly_review_flow_screen.dart';

// Sprint 12 screens
import 'screens/social_feed_screen.dart';
import 'screens/habit_streak_screen.dart';
import 'screens/daily_checkin_screen.dart';

// Sprint 13 screens
import 'screens/ai_coach_screen.dart';
import 'screens/content_library_screen.dart';
import 'screens/community_challenge_screen.dart';

// Personal system
import 'screens/plan_screen.dart';
import 'screens/playbook_screen.dart';
import 'screens/manifesto_screen.dart';
import 'screens/protocols_screen.dart';
import 'screens/evidence_archive_screen.dart';
import 'screens/library_screen.dart';
import 'screens/style_screen.dart';
import 'screens/career_screen.dart';
import 'screens/weekly_coaching_screen.dart';
import 'screens/features_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      // While initialising, stay on splash
      if (status == AuthStatus.uninitialized) {
        return location == '/splash' ? null : '/splash';
      }

      // After init completes, leave splash
      if (location == '/splash') {
        return status == AuthStatus.authenticated ? '/home' : '/welcome';
      }

      // Auth guard: unauthenticated users can only access onboarding routes
      final onboardingRoutes = ['/welcome', '/sign-up', '/sign-in', '/forgot-password', '/archetype'];
      final isOnboardingRoute = onboardingRoutes.contains(location) ||
          location.startsWith('/assessment') ||
          location.startsWith('/loading') ||
          location.startsWith('/blueprint');

      if (status == AuthStatus.unauthenticated && !isOnboardingRoute) {
        return '/welcome';
      }

      // Authenticated users shouldn't see welcome or auth screens
      if (status == AuthStatus.authenticated &&
          (location == '/welcome' ||
           location == '/sign-in' ||
           location == '/sign-up')) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Splash (shown during AuthProvider.init) ──
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Onboarding flow ──
      GoRoute(
        path: '/welcome',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: OnboardingWelcomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: SignUpScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: SignInScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ForgotPasswordScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/archetype',
        builder: (_, __) => const ArchetypeScreen(),
      ),
      GoRoute(
        path: '/assessment/:archetypeId',
        builder: (_, state) => AssessmentScreen(
          archetypeId: state.pathParameters['archetypeId']!,
        ),
      ),
      GoRoute(
        path: '/loading/:archetypeId',
        builder: (_, state) => BlueprintLoadingScreen(
          archetypeId: state.pathParameters['archetypeId']!,
          answers: state.extra as Map<int, int>? ?? {},
        ),
      ),
      GoRoute(
        path: '/blueprint/:archetypeId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: BlueprintScreen(
            archetypeId: state.pathParameters['archetypeId']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Weekly review (full screen, no bottom nav) ──
      GoRoute(
        path: '/weekly-review',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: WeeklyReviewScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Role Model Journeys (full screen, no bottom nav) ──
      GoRoute(
        path: '/role-models',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: RoleModelsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/role-model/:id',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: RoleModelDetailScreen(
            roleModelId: state.pathParameters['id']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Achievements (full screen, no bottom nav) ──
      GoRoute(
        path: '/achievements',
        pageBuilder: (_, state) {
          return CustomTransitionPage(
            child: const AchievementsScreen(),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // ── Habit Heat Map (full screen, no bottom nav) ──
      GoRoute(
        path: '/heat-map',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: HabitHeatMapScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Morning Ritual (full screen, no bottom nav) ──
      GoRoute(
        path: '/morning-ritual',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: MorningRitualScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Lane Analytics (full screen, no bottom nav) ──
      GoRoute(
        path: '/lane-analytics',
        pageBuilder: (_, state) {
          final laneName = state.extra as String?;
          return CustomTransitionPage(
            child: LaneAnalyticsScreen(laneName: laneName),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // ── Sprint 2: Monk Mode (full screen, no bottom nav) ──
      GoRoute(
        path: '/monk-mode',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: MonkModeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 2: Legacy Score (full screen, no bottom nav) ──
      GoRoute(
        path: '/legacy-score',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: LegacyScoreScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 2: Notification Settings (full screen, no bottom nav) ──
      GoRoute(
        path: '/notification-settings',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: NotificationCenterScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 3: Becoming Arc (full screen, no bottom nav) ──
      GoRoute(
        path: '/becoming-arc',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: BecomingArcScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/arc-layer',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: ArcLayerScreen(
              layer: extra['layer'] as ArcLayer,
              arcId: extra['arcId'] as String,
            ),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
      GoRoute(
        path: '/arc/:arcId/assessment/:dayNumber',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: SelfAssessmentScreen(
            arcId: state.pathParameters['arcId']!,
            dayNumber: int.parse(state.pathParameters['dayNumber']!),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 3: Notification Feed (full screen, no bottom nav) ──
      GoRoute(
        path: '/notification-feed',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: NotificationFeedScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 4: Ghost Mode (full screen, no bottom nav) ──
      GoRoute(
        path: '/ghost-mode',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: GhostModeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 4: Ritual Flow (full screen, no bottom nav) ──
      GoRoute(
        path: '/ritual-flow/:ritualId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: RitualFlowScreen(
            ritualId: state.pathParameters['ritualId']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 4: Ritual Setup (full screen, no bottom nav) ──
      GoRoute(
        path: '/ritual-setup',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: RitualSetupScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 4: The Council (full screen, no bottom nav) ──
      GoRoute(
        path: '/council',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: CouncilScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 4: Phase Transition (full screen, no bottom nav) ──
      GoRoute(
        path: '/phase-transition',
        pageBuilder: (_, state) {
          final transition = state.extra as PhaseTransition;
          return CustomTransitionPage(
            child: PhaseTransitionScreen(transition: transition),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // ── Sprint 5: Time Mode Settings (full screen, no bottom nav) ──
      GoRoute(
        path: '/time-mode',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: TimeModeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 5: Brotherhood (full screen, no bottom nav) ──
      GoRoute(
        path: '/brotherhood',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: BrotherhoodScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 5: Role Model Radio (full screen, no bottom nav) ──
      GoRoute(
        path: '/radio',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: RadioScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/radio/:roleModelId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: RadioScreen(
            roleModelId: state.pathParameters['roleModelId']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 5: Trending / The Pulse (full screen, no bottom nav) ──
      GoRoute(
        path: '/trending',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: TrendingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 6: Mirror Match (full screen, no bottom nav) ──
      GoRoute(
        path: '/mirror-match',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: MirrorMatchScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 6: The Forge (full screen, no bottom nav) ──
      GoRoute(
        path: '/forge',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ForgeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/forge/:courseId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: ForgeCourseScreen(
            courseId: state.pathParameters['courseId']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/forge/:courseId/lesson/:lessonId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: ForgeLessonScreen(
            courseId: state.pathParameters['courseId']!,
            lessonId: state.pathParameters['lessonId']!,
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 6: Adaptive Settings (full screen, no bottom nav) ──
      GoRoute(
        path: '/adaptive-settings',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: AdaptiveSettingsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 7: Wakz Challenges (full screen, no bottom nav) ──
      GoRoute(
        path: '/wakz-challenges',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: WakzChallengesScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 7: Forge Analytics (full screen, no bottom nav) ──
      GoRoute(
        path: '/forge-analytics',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ForgeAnalyticsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 8: Accountability Partners (full screen, no bottom nav) ──
      GoRoute(
        path: '/accountability',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: AccountabilityScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 8: The Vault (full screen, no bottom nav) ──
      GoRoute(
        path: '/vault',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: VaultScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 8: Gamification Hub (full screen, no bottom nav) ──
      GoRoute(
        path: '/gamification',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: GamificationScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 9: Daily Planner (full screen, no bottom nav) ──
      GoRoute(
        path: '/planner',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: PlannerScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 9: Vision Board (full screen, no bottom nav) ──
      GoRoute(
        path: '/vision-board',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: VisionBoardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 9: Power Rankings (full screen, no bottom nav) ──
      GoRoute(
        path: '/power-rankings',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: PowerRankingsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 10: Settings (full screen, no bottom nav) ──
      GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: SettingsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 10: Onboarding Flow (full screen, no bottom nav) ──
      GoRoute(
        path: '/onboarding-flow',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: OnboardingFlowScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 10: Dashboard (full screen, no bottom nav) ──
      GoRoute(
        path: '/dashboard',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: DashboardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 11: Achievement Hub (full screen, no bottom nav) ──
      GoRoute(
        path: '/achievement-hub',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: AchievementHubScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 11: Analytics Dashboard (full screen, no bottom nav) ──
      GoRoute(
        path: '/analytics',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: AnalyticsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 11: Weekly Review Flow (full screen, no bottom nav) ──
      GoRoute(
        path: '/weekly-review-flow',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: WeeklyReviewFlowScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 12: Social Feed ──
      GoRoute(
        path: '/social-feed',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: SocialFeedScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 12: Habit Streaks ──
      GoRoute(
        path: '/habit-streaks',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: HabitStreakScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 12: Daily Check-in ──
      GoRoute(
        path: '/daily-checkin',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: DailyCheckinScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 13: AI Coach ──
      GoRoute(
        path: '/ai-coach',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: AiCoachScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 13: Content Library ──
      GoRoute(
        path: '/content-library',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ContentLibraryScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Sprint 13: Community Challenges ──
      GoRoute(
        path: '/community-challenges',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: CommunityChallengeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Personal system detail pages ──
      GoRoute(
        path: '/manifesto',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ManifestoScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/protocols',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: ProtocolsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/evidence',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: EvidenceArchiveScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/library',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: LibraryScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/style',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: StyleScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/career',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: CareerScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/weekly-coaching',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: WeeklyCoachingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/features',
        pageBuilder: (_, __) => const CustomTransitionPage(
          child: FeaturesScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Main app (bottom nav shell) ──
      ShellRoute(
        builder: (_, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/plan',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PlanScreen(),
            ),
          ),
          GoRoute(
            path: '/playbook',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: PlaybookScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/area_editor_screen.dart';
import 'screens/career_screen.dart';
import 'screens/case_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/cockpit_screen.dart';
import 'screens/commission_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/evidence_archive_screen.dart';
import 'screens/experiments_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/gym_session_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/growth_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/letters_screen.dart';
import 'screens/library_screen.dart';
import 'screens/log_screen.dart';
import 'screens/main_screen.dart';
import 'screens/manifesto_screen.dart';
import 'screens/me_screen.dart';
import 'screens/month_screen.dart';
import 'screens/note_screen.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/people_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/program_screen.dart';
import 'screens/protocols_screen.dart';
import 'screens/quarter_screen.dart';
import 'screens/review_screen.dart';
import 'screens/ritual_flow_screen.dart';
import 'screens/setback_screen.dart';
import 'screens/shutdown_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/style_screen.dart';
import 'screens/tool_screens.dart';
import 'screens/week_screen.dart';
import 'screens/values_screen.dart';
import 'screens/weekly_coaching_screen.dart';

/// Every route in the app. Tabs: Today · Program · Log · Me.
const appRoutes = [
  '/home',
  '/program',
  '/log',
  '/profile',
  '/commission',
  '/manifesto',
  '/protocols',
  '/evidence',
  '/library',
  '/style',
  '/career',
  '/weekly-coaching',
  '/ritual-flow/ritual_morning_default',
  '/gym',
  '/month/1',
  '/tool/sigh',
  '/tool/excited',
  '/tool/pause',
  '/tool/still',
  '/tool/bluf',
  '/tool/sixq',
  '/tool/read',
  '/tool/feynman',
  '/tool/scan',
  '/tool/pennebaker',
  '/tool/anki',
  '/tool/artifact',
  '/tool/linkedin',
  '/checkin',
  '/plans',
  '/review',
  '/habits',
  '/cockpit',
  '/cockpit?tab=1',
  '/cockpit?tab=2',
  '/shutdown',
  '/focus',
  '/letters',
  '/week',
  '/people',
  '/growth',
  '/goals',
  '/note',
  '/setback',
  '/quarter',
  '/profile/edit',
  '/daily',
  '/learning',
  '/experiments',
  '/goals/edit',
  '/growth/area',
  '/growth/area?template=t_strength',
  '/values',
  '/coach',
  '/case',
];

GoRouter createRouter(AuthProvider authProvider,
    {GlobalKey<NavigatorState>? navigatorKey}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      if (status == AuthStatus.uninitialized) {
        return location == '/splash' ? null : '/splash';
      }
      if (location == '/splash') {
        return status == AuthStatus.authenticated ? '/home' : '/welcome';
      }
      const open = ['/welcome', '/sign-up', '/sign-in', '/forgot-password'];
      if (status == AuthStatus.unauthenticated && !open.contains(location)) {
        return '/welcome';
      }
      if (status == AuthStatus.authenticated &&
          (location == '/welcome' ||
              location == '/sign-in' ||
              location == '/sign-up')) {
        return '/home';
      }
      return null;
    },
    routes: [
      _fade('/splash', (_) => const SplashScreen()),
      _fade('/welcome', (_) => const OnboardingWelcomeScreen()),
      _fade('/sign-up', (_) => const SignUpScreen()),
      _fade('/sign-in', (_) => const SignInScreen()),
      _fade('/forgot-password', (_) => const ForgotPasswordScreen()),
      _fade('/commission', (_) => const CommissionScreen()),
      _slide('/manifesto', (_) => const ManifestoScreen()),
      _slide('/protocols', (_) => const ProtocolsScreen()),
      _slide('/evidence', (_) => const EvidenceArchiveScreen()),
      _slide('/library', (_) => const LibraryScreen()),
      _slide('/style', (_) => const StyleScreen()),
      _slide('/career', (_) => const CareerScreen()),
      _slide('/weekly-coaching', (_) => const WeeklyCoachingScreen()),
      _slide('/checkin', (_) => const CheckinScreen()),
      _slide('/plans', (_) => const PlansScreen()),
      _slide('/review', (_) => const ReviewScreen()),
      _slide('/habits', (_) => const HabitsScreen()),
      _slide('/shutdown', (_) => const ShutdownScreen()),
      _slide('/focus', (_) => const FocusScreen()),
      _slide('/letters', (_) => const LettersScreen()),
      _slide('/week', (_) => const WeekScreen()),
      _slide('/people', (_) => const PeopleScreen()),
      _slide('/growth', (_) => const GrowthScreen()),
      _slide('/goals', (_) => const GoalsScreen()),
      _slide('/note', (_) => const NoteScreen()),
      _slide('/setback', (_) => const SetbackScreen()),
      _slide('/quarter', (_) => const QuarterScreen()),
      _slide('/profile/edit', (_) => const ProfileEditScreen()),
      _slide('/daily', (_) => const DailyScreen()),
      _slide('/learning', (_) => const LearningScreen()),
      _slide('/experiments', (_) => const ExperimentsScreen()),
      _slide(
          '/goals/edit',
          (s) => GoalEditScreen(
              key: ValueKey(s.uri.toString()),
              id: s.uri.queryParameters['id'],
              title: s.uri.queryParameters['title'])),
      _slide('/goals/view',
          (s) => GoalScreen(id: s.uri.queryParameters['id'] ?? '')),
      _slide(
          '/growth/area',
          (s) => AreaEditorScreen(
              key: ValueKey(s.uri.toString()),
              areaId: s.uri.queryParameters['id'],
              templateId: s.uri.queryParameters['template'])),
      _slide('/values', (_) => const ValuesScreen()),
      _slide('/coach', (_) => const CoachScreen()),
      _slide('/case', (_) => const CaseScreen()),
      _slide(
          '/cockpit',
          (s) => CockpitScreen(
              initialTab:
                  int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0)),
      _slide('/ritual-flow/:ritualId',
          (s) => RitualFlowScreen(ritualId: s.pathParameters['ritualId']!)),
      _slide('/gym', (_) => const GymSessionScreen()),
      _slide('/gym/:dayId',
          (s) => GymSessionScreen(dayId: s.pathParameters['dayId'])),
      _slide('/month/:m',
          (s) => MonthScreen(month: int.tryParse(s.pathParameters['m']!) ?? 1)),
      _slide(
          '/tool/:id',
          (s) => ToolScreen(
              id: s.pathParameters['id']!, params: s.uri.queryParameters)),
      ShellRoute(
        builder: (_, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/program',
            pageBuilder: (_, s) => NoTransitionPage(
                child: ProgramScreen(
                    initialTab:
                        int.tryParse(s.uri.queryParameters['tab'] ?? '') ??
                            0)),
          ),
          GoRoute(
            path: '/log',
            pageBuilder: (_, s) => NoTransitionPage(
                child: LogScreen(add: s.uri.queryParameters['add'])),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: MeScreen()),
          ),
        ],
      ),
    ],
  );
}

GoRoute _fade(String path, Widget Function(GoRouterState) build) => GoRoute(
      path: path,
      pageBuilder: (_, s) => CustomTransitionPage(
        child: build(s),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

GoRoute _slide(String path, Widget Function(GoRouterState) build) => GoRoute(
      path: path,
      pageBuilder: (_, s) => CustomTransitionPage(
        child: build(s),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0.08, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a, child: child),
        ),
      ),
    );

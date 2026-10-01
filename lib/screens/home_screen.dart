import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/gradient_progress_ring.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_actions_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/blueprint_provider.dart';
import '../providers/progress_provider.dart';
import '../gateways/actions_gateway.dart';
import '../widgets/streak_celebration.dart';
import '../models/challenge.dart';
import '../widgets/reflection_sheet.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list.dart';
import '../models/role_model.dart';
import '../models/journey.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily motivational quotes — one shown per day, cycling through the list.
const _quotes = [
  '"The person you want to be is built one small action at a time."',
  '"Discipline is choosing between what you want now and what you want most."',
  '"Small daily improvements are the key to staggering long-term results."',
  '"You don\'t have to be extreme — just consistent."',
  '"A year from now you\'ll wish you had started today."',
  '"The only bad workout is the one that didn\'t happen."',
  '"Champions aren\'t made in gyms — they\'re made from things deep inside."',
  '"Success is the sum of small efforts repeated day in and day out."',
  '"What you do every day matters more than what you do once in a while."',
  '"Your future self is watching you through memories. Make him proud."',
  '"Growth is uncomfortable, but so is staying the same."',
  '"The secret of getting ahead is getting started."',
  '"Be the man you needed when you were younger."',
  '"Progress, not perfection."',
  '"Every master was once a disaster."',
  '"Hard choices, easy life. Easy choices, hard life."',
  '"You\'re not behind — you\'re just getting started."',
  '"The grind is the gift."',
  '"Confidence comes from keeping promises to yourself."',
  '"Day by day, what you do is who you become."',
  '"The strongest men are those who fight battles nobody sees."',
  '"It always seems impossible until it\'s done."',
  '"Stop wishing, start doing."',
  '"Invest in yourself — it pays the best interest."',
  '"The best time to plant a tree was 20 years ago. The second best is now."',
  '"Don\'t count the days. Make the days count."',
  '"You were born to be real, not to be perfect."',
  '"Energy flows where attention goes."',
  '"The comeback is always stronger than the setback."',
  '"Be so good they can\'t ignore you."',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _loaded = false;
  int _previousStreak = -1;
  RoleModel? _activeJourney;
  int _journeyDay = 0;

  late final AnimationController _headerFade;
  late final Animation<double> _headerFadeIn;

  @override
  void initState() {
    super.initState();
    _headerFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeIn = CurvedAnimation(
      parent: _headerFade,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Load profile and check onboarding
    final profileProvider = context.read<UserProfileProvider>();
    await profileProvider.loadProfile(userId);
    if (mounted && !profileProvider.isOnboarded) {
      context.go('/archetype');
      return;
    }

    // Load active journey
    await _loadJourney();

    // Load progress (lane scores)
    if (mounted) {
      context.read<ProgressProvider>().loadProgress(userId);
    }

    final actionsProvider = context.read<DailyActionsProvider>();
    await actionsProvider.loadToday(userId);

    // Auto-seed: if no actions today but user has a blueprint, re-seed
    if (actionsProvider.actions.isEmpty) {
      await _autoSeedActions(userId);
    }

    if (mounted) _headerFade.forward();
  }

  /// Loads the active blueprint and calls the seed-actions Edge Function
  /// to populate today's daily actions from it.
  Future<void> _autoSeedActions(String userId) async {
    try {
      final blueprintProvider = context.read<BlueprintProvider>();
      await blueprintProvider.loadBlueprint(userId);
      final blueprint = blueprintProvider.blueprint;
      if (blueprint == null || blueprint.lanes.isEmpty) return;

      // Build lanes payload for the Edge Function
      final lanesPayload = blueprint.lanes.map((lane) => {
            'id': lane.id,
            'actions': lane.actions
                .map((a) => {
                      'id': a.id,
                      'title': a.title,
                      'subtitle': a.subtitle,
                      'laneId': a.laneId,
                      'orderIndex': a.orderIndex,
                    })
                .toList(),
          }).toList();

      await Supabase.instance.client.functions.invoke(
        'seed-actions',
        body: {
          'userId': userId,
          'blueprintId': null,
          'lanes': lanesPayload,
        },
      );

      // Reload actions after seeding
      if (mounted) {
        await context.read<DailyActionsProvider>().loadToday(userId);
      }
    } catch (_) {
      // Best-effort — don't block home screen if seeding fails
    }
  }

  Future<void> _loadJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('active_journey_id');
    final startStr = prefs.getString('active_journey_start');
    if (id != null && startStr != null && mounted) {
      final model = getRoleModelById(id);
      final start = DateTime.tryParse(startStr);
      if (model != null && start != null) {
        final day = DateTime.now().difference(start).inDays + 1;
        setState(() {
          _activeJourney = model;
          _journeyDay = day.clamp(1, model.journeyDays);
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await Future.wait([
        context.read<DailyActionsProvider>().loadToday(userId),
        context.read<ProgressProvider>().loadProgress(userId),
      ]);
    }
  }

  /// Check if the streak just hit a milestone and celebrate.
  void _checkStreakCelebration(int newStreak) {
    if (_previousStreak >= 0 && newStreak > _previousStreak) {
      final milestone = getMilestone(newStreak);
      if (milestone != null && mounted) {
        // Slight delay so the UI updates first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) showStreakCelebration(context, milestone);
        });
      }
    }
    _previousStreak = newStreak;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late night grind';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Night owl mode';
  }

  String get _motivationalSubtext {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'The world sleeps while you build.';
    if (hour < 9) return 'Early hours shape great men.';
    if (hour < 12) return 'Make today count.';
    if (hour < 17) return 'Stay locked in.';
    if (hour < 21) return 'Finish what you started.';
    return 'Rest is earned, not given.';
  }

  String get _todayQuote {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  @override
  void dispose() {
    _headerFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyActionsProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final progressProvider = context.watch<ProgressProvider>();
    final actions = provider.actions;
    final streak = provider.streak;
    final completedCount = actions.where((a) => a.completed).length;
    final progress = actions.isEmpty ? 0.0 : completedCount / actions.length;
    final displayName = profileProvider.profile?.displayName;
    final laneScores = progressProvider.laneScores;

    // Check for streak milestone celebrations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStreakCelebration(streak);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0A1E),
              Color(0xFF0A0C14),
              Color(0xFF0A1014),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orb — top left
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Ambient glow orb — bottom right
            Positioned(
              bottom: -120,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: provider.isLoading
                  ? const HomeScreenSkeleton()
                  : FadeTransition(
                      opacity: _headerFadeIn,
                      child: RefreshIndicator(
                        color: AppColors.purple,
                        backgroundColor: AppColors.card,
                        onRefresh: _onRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // ── HEADER ──────────────────────────
                              _buildHeader(displayName, streak),
                              const SizedBox(height: 6),
                              Text(
                                _motivationalSubtext,
                                style: TextStyle(
                                  color: AppColors.grey.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── PROGRESS HERO ───────────────────
                              if (actions.isEmpty)
                                _buildEmptyState()
                              else ...[
                                _buildProgressHero(
                                    completedCount, actions.length, progress,
                                    streak),

                                // ── LANE SCORES ────────────────────
                                if (laneScores.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildLaneScores(laneScores),
                                ],

                                // ── ACTIVE JOURNEY ─────────────────
                                if (_activeJourney != null) ...[
                                  const SizedBox(height: 16),
                                  _buildActiveJourneyCard(),
                                ],

                                // ── DAILY CHALLENGE ────────────────
                                const SizedBox(height: 16),
                                _buildChallengeCard(getTodayChallenge(), false),

                                // ── TODAY'S ACTIONS ────────────────
                                const SizedBox(height: 24),
                                _buildActionsHeader(
                                    completedCount, actions.length),
                                const SizedBox(height: 12),
                                StaggeredList(
                                  children: actions
                                      .map((action) =>
                                          _buildActionCard(action))
                                      .toList(),
                                ),

                                // ── WEEKLY CHALLENGE ───────────────
                                const SizedBox(height: 8),
                                _buildChallengeCard(getWeeklyChallenge(), true),
                              ],

                              // ── EXPLORE JOURNEYS ────────────────
                              const SizedBox(height: 16),
                              _buildExploreJourneysCard(),

                              // ── DAILY WISDOM ────────────────────
                              const SizedBox(height: 16),
                              _buildDailyWisdom(),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  HEADER                                                        ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildHeader(String? displayName, int streak) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName ?? 'King',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Streak badge — glassmorphic
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/progress');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warning.withValues(alpha: 0.15),
                      AppColors.card.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          streak == 1 ? 'day' : 'days',
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  PROGRESS HERO                                                  ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildProgressHero(
      int completedCount, int totalCount, double progress, int streak) {
    final allDone = completedCount == totalCount && totalCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allDone
              ? [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.card.withValues(alpha: 0.8),
                ]
              : [
                  AppColors.purple.withValues(alpha: 0.15),
                  AppColors.card.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: allDone
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          GradientProgressRing(
            progress: progress,
            radius: 50,
            strokeWidth: 9,
            gradientColors: allDone
                ? const [Color(0xFF34D399), Color(0xFF6EE7B7), Color(0xFFA7F3D0)]
                : const [Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFFC4B5FD)],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allDone ? '✓' : '$completedCount',
                  style: TextStyle(
                    color: allDone ? AppColors.success : AppColors.white,
                    fontSize: allDone ? 28 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!allDone)
                  Text(
                    'of $totalCount',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'All done today! 🎉' : 'Today\'s progress',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allDone
                      ? 'Streak extended. You showed up.'
                      : '${totalCount - completedCount} action${totalCount - completedCount == 1 ? '' : 's'} remaining',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone ? AppColors.success : AppColors.purple,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).round()}% complete',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  LANE SCORES                                                    ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildLaneScores(Map<String, double> laneScores) {
    const lanes = [
      ('mind', '🧠', 'Mind', AppColors.purple),
      ('body', '💪', 'Body', AppColors.green),
      ('social', '🗣', 'Social', AppColors.warning),
      ('skill', '📚', 'Skill', AppColors.cyan),
    ];

    return Row(
      children: lanes.map((lane) {
        final score = laneScores[lane.$1] ?? 0.0;
        final isLast = lane == lanes.last;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lane.$4.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Text(lane.$2, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  '${(score * 100).round()}',
                  style: TextStyle(
                    color: lane.$4,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lane.$3,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Mini bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: score.clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      lane.$4.withValues(alpha: 0.8),
                    ),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  ACTIVE JOURNEY CARD                                            ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildActiveJourneyCard() {
    final model = _activeJourney!;
    final journeyProgress = _journeyDay / model.journeyDays;

    // Find current phase from the journey system
    final journey = getJourneyForRoleModel(model.id);
    JourneyPhase? currentPhase;
    if (journey != null) {
      currentPhase = getPhaseForDay(journey, _journeyDay);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        GoRouter.of(context).push('/role-model/${model.id}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.success.withValues(alpha: 0.12),
                  AppColors.card.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Role model avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success.withValues(alpha: 0.2),
                            AppColors.success.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(model.emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE JOURNEY',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            journey?.title ?? model.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Day counter
                    Column(
                      children: [
                        Text(
                          'Day',
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_journeyDay',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Current phase info
                if (currentPhase != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentPhase.title,
                            style: const TextStyle(
                              color: AppColors.greyLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Day ${currentPhase.startDay}–${currentPhase.endDay}',
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: journeyProgress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.success),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(journeyProgress * 100).round()}% complete',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${model.journeyDays - _journeyDay} days remaining',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  CHALLENGE CARD (inline for old Challenge model)               ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildChallengeCard(Challenge challenge, bool isWeekly) {
    final laneColors = {
      ChallengeLane.mind: const Color(0xFF8B5CF6),
      ChallengeLane.body: const Color(0xFF22D3EE),
      ChallengeLane.social: const Color(0xFF34D399),
      ChallengeLane.skill: const Color(0xFFF59E0B),
    };
    final color = laneColors[challenge.lane] ?? const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWeekly ? Icons.calendar_today : Icons.bolt,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isWeekly ? "Weekly Challenge" : "Today's Challenge",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "+${challenge.xp} XP",
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            challenge.title,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.description,
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  ACTIONS HEADER                                                 ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildActionsHeader(int completedCount, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Today\'s actions',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: const TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          _currentDate(),
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  EXPLORE JOURNEYS                                               ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildExploreJourneysCard() {
    // Pick 3 featured role models to show as avatars
    final featured = allRoleModels.take(5).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        GoRouter.of(context).push('/role-models');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  AppColors.purple.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.25),
                            AppColors.purple.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🏛', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role Model Journeys',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Walk in the footsteps of greatness',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.grey, size: 14),
                  ],
                ),
                const SizedBox(height: 16),
                // Avatar row
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Stacked emoji avatars
                      ...featured.asMap().entries.map((entry) {
                        return Transform.translate(
                          offset: Offset(-entry.key * 6.0, 0),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(entry.value.emoji,
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '${allRoleModels.length}+ role models',
                        style: TextStyle(
                          color: AppColors.purpleSoft.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  DAILY WISDOM                                                   ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildDailyWisdom() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'DAILY WISDOM',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _todayQuote,
            style: const TextStyle(
              color: AppColors.purpleSoft,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  EMPTY STATE                                                    ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.08),
            AppColors.card.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your journey starts here',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your personal blueprint to unlock\ndaily actions tailored to your goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF7C3AED),
                    Color(0xFF6D28D9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/archetype'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create my blueprint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  ACTION CARDS                                                   ║
  // ╚══════════════════════════════════════════════════════════════════╝

  void _toggleAction(DailyAction action) {
    HapticFeedback.lightImpact();
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final completing = !action.completed;
    context
        .read<DailyActionsProvider>()
        .toggleAction(userId, action.id, completing);

    // Show reflection sheet when completing an action
    if (completing) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          showReflectionSheet(
            context,
            actionId: action.id,
            actionTitle: action.title,
            lane: action.lane,
            onSave: (note, prompt) async {
              // TODO: persist reflection notes to Supabase
              debugPrint('Reflection for ${action.id}: $note');
            },
          );
        }
      });
    }
  }

  Widget _buildActionCard(DailyAction action) {
    final laneColor = _laneColor(action.lane);
    final emoji = _laneEmoji(action.lane);
    final laneName = _laneName(action.lane);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: action.completed
            ? laneColor.withValues(alpha: 0.08)
            : AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: action.completed
              ? laneColor.withValues(alpha: 0.25)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Lane color dot
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: laneColor.withValues(alpha: action.completed ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laneName.toUpperCase(),
                  style: TextStyle(
                    color: action.completed
                        ? laneColor.withValues(alpha: 0.7)
                        : laneColor.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.title,
                  style: TextStyle(
                    color: action.completed
                        ? AppColors.grey.withValues(alpha: 0.6)
                        : AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: action.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.grey.withValues(alpha: 0.4),
                  ),
                ),
                if (action.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle!,
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: action.completed
                  ? laneColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: action.completed
                    ? laneColor
                    : AppColors.grey.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: action.completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        ],
      ),
    );

    // Swipe right to toggle completion
    if (!action.completed) {
      return Dismissible(
        key: ValueKey('swipe_${action.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          HapticFeedback.heavyImpact();
          _toggleAction(action);
          return false; // Don't actually dismiss — the card stays with updated state
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.25),
                AppColors.success.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 24),
              SizedBox(width: 8),
              Text(
                'Complete',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => _toggleAction(action),
          child: card,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _toggleAction(action),
      child: card,
    );
  }

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  HELPERS                                                        ║
  // ╚══════════════════════════════════════════════════════════════════╝

  Color _laneColor(String lane) {
    switch (lane) {
      case 'mind':
        return AppColors.purple;
      case 'body':
        return AppColors.green;
      case 'social':
        return AppColors.warning;
      case 'skill':
        return AppColors.cyan;
      default:
        return AppColors.purple;
    }
  }

  String _laneEmoji(String lane) {
    switch (lane) {
      case 'mind':
        return '🧠';
      case 'body':
        return '💪';
      case 'social':
        return '🗣';
      case 'skill':
        return '📚';
      default:
        return '⚡';
    }
  }

  String _laneName(String lane) {
    switch (lane) {
      case 'mind':
        return 'Mind';
      case 'body':
        return 'Body';
      case 'social':
        return 'Social';
      case 'skill':
        return 'Skill';
      default:
        return lane[0].toUpperCase() + lane.substring(1);
    }
  }

  String _currentDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }
}

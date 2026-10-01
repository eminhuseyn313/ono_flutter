import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/daily_actions_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/role_model.dart';
import '../models/achievement.dart';
import '../widgets/gradient_progress_ring.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String? _activeJourneyId;
  String? _activeJourneyStart;

  late final List<AnimationController> _sectionControllers;
  late final List<Animation<double>> _sectionAnimations;

  static const int _sectionCount = 6;

  @override
  void initState() {
    super.initState();
    _loadJourneyData();

    _sectionControllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _sectionAnimations = _sectionControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOut);
    }).toList();

    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() {
    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) {
          _sectionControllers[i].forward();
        }
      });
    }
  }

  Future<void> _loadJourneyData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeJourneyId = prefs.getString('active_journey_id');
        _activeJourneyStart = prefs.getString('active_journey_start');
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final actionsProvider = context.watch<DailyActionsProvider>();

    final displayName = profileProvider.profile?.displayName ?? 'User';
    final archetype = profileProvider.archetypeId ?? 'executive';
    final email = authProvider.user?.email ?? '';
    final streak = actionsProvider.streak;
    final actions = actionsProvider.actions;
    final completedActions = actions.where((a) => a.completed).toList();
    final totalProgress =
        actions.isEmpty ? 0.0 : completedActions.length / actions.length;

    final mindActions = actions.where((a) => a.lane == 'mind').toList();
    final bodyActions = actions.where((a) => a.lane == 'body').toList();
    final socialActions = actions.where((a) => a.lane == 'social').toList();
    final skillActions = actions.where((a) => a.lane == 'skill').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D0F),
      body: Stack(
        children: [
          // Ambient gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF111214),
                  Color(0xFF0C0D0F),
                  Color(0xFF0E1012),
                ],
              ),
            ),
          ),

          // Ambient glow orb — top-right, purple
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.12),
                    AppColors.purple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Ambient glow orb — bottom-left, cyan
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8EA4D2).withValues(alpha: 0.08),
                    const Color(0xFF8EA4D2).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 0: Profile Header
                  _buildAnimatedSection(
                    0,
                    _buildProfileHeader(displayName, email, archetype),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Stats Row
                  _buildAnimatedSection(
                    1,
                    _buildStatsRow(
                        streak, completedActions.length, totalProgress),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Active Journey (conditional)
                  if (_activeJourneyId != null) ...[
                    _buildAnimatedSection(
                      2,
                      _buildActiveJourneyCard(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section 3: Achievements
                  _buildAnimatedSection(
                    3,
                    _buildAchievementsShowcase(),
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Lane Breakdown
                  _buildAnimatedSection(
                    4,
                    _buildLaneBreakdown(
                      mindActions,
                      bodyActions,
                      socialActions,
                      skillActions,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 5: Settings
                  _buildAnimatedSection(
                    5,
                    _buildSettingsSection(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    if (index >= _sectionCount) return child;
    return FadeTransition(
      opacity: _sectionAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_sectionAnimations[index]),
        child: child,
      ),
    );
  }

  // ─── Glass card helper ────────────────────────────────────────────

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double borderRadius = 16,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── 1. Profile Header ────────────────────────────────────────────

  Widget _buildProfileHeader(
      String displayName, String email, String archetype) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.purple, AppColors.purpleDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                archetype,
                style: const TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. Stats Cards Row ───────────────────────────────────────────

  Widget _buildStatsRow(int streak, int completedCount, double progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            emoji: '🔥',
            value: streak,
            label: 'days',
            sublabel: 'Streak',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            emoji: '✅',
            value: completedCount,
            label: 'done',
            sublabel: 'Actions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCardWithRing(progress),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required int value,
    required String label,
    required String sublabel,
  }) {
    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return Text(
                '$animValue',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              color: AppColors.greyLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithRing(double progress) {
    final percent = (progress * 100).round();
    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: GradientProgressRing(
              progress: progress,
              strokeWidth: 4,
              center: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, animValue, _) {
                  return Text(
                    '$animValue%',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lane',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Score',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Active Journey Card ───────────────────────────────────────

  Widget _buildActiveJourneyCard() {
    if (_activeJourneyId == null) return const SizedBox.shrink();

    final roleModel = getRoleModelById(_activeJourneyId!);
    if (roleModel == null) return const SizedBox.shrink();

    int dayNumber = 1;
    if (_activeJourneyStart != null) {
      final startDate = DateTime.tryParse(_activeJourneyStart!);
      if (startDate != null) {
        dayNumber = DateTime.now().difference(startDate).inDays + 1;
      }
    }
    const totalDays = 21;
    final journeyProgress = (dayNumber / totalDays).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/role-model/$_activeJourneyId');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Text(roleModel.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleModel.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day $dayNumber of $totalDays',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: journeyProgress,
                          minHeight: 6,
                          backgroundColor: AppColors.cardLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 4. Achievements Showcase ─────────────────────────────────────

  Widget _buildAchievementsShowcase() {
    final provider = context.watch<AchievementProvider>();
    final previewAchievements = provider.achievements.take(4).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/achievements');
              },
              child: const Text(
                'See All →',
                style: TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewAchievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final achievement = previewAchievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return _glassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.35,
              child: Icon(
                achievement.icon,
                size: 28,
                color: achievement.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. Lane Breakdown ────────────────────────────────────────────

  Widget _buildLaneBreakdown(
    List<dynamic> mind,
    List<dynamic> body,
    List<dynamic> social,
    List<dynamic> skill,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lane Progress',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildLaneRow('🧠', 'Mind', mind, AppColors.purple),
              const SizedBox(height: 14),
              _buildLaneRow('💪', 'Body', body, AppColors.success),
              const SizedBox(height: 14),
              _buildLaneRow('🗣', 'Social', social, AppColors.warning),
              const SizedBox(height: 14),
              _buildLaneRow('📚', 'Skill', skill, const Color(0xFF4A9EFF)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLaneRow(
    String emoji,
    String name,
    List<dynamic> laneActions,
    Color color,
  ) {
    final total = laneActions.length;
    final completed = laneActions.where((a) => a.completed).length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.greyLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animValue,
                  minHeight: 8,
                  backgroundColor: AppColors.cardLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            '$completed/$total',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 6. Settings Section ──────────────────────────────────────────

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingsRow(
                emoji: '🔔',
                label: 'Notifications',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              const Divider(color: AppColors.divider, height: 1, indent: 50),
              _buildSettingsRow(
                emoji: '🎨',
                label: 'Theme',
                trailing: const Text(
                  'Dark',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              const Divider(color: AppColors.divider, height: 1, indent: 50),
              _buildSettingsRow(
                emoji: '📊',
                label: 'Export Data',
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              const Divider(color: AppColors.divider, height: 1, indent: 50),
              _buildSettingsRow(
                emoji: '🚪',
                label: 'Sign Out',
                onTap: _handleSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required String emoji,
    required String label,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────

  void _handleSignOut() {
    HapticFeedback.lightImpact();
    context.read<AuthProvider>().signOut();
    context.go('/welcome');
  }
}

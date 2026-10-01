import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Load achievements if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AchievementProvider>();
      if (provider.achievements.isEmpty) {
        provider.loadAll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _categoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return AppColors.warning;
      case AchievementCategory.actions:
        return AppColors.green;
      case AchievementCategory.lanes:
        return AppColors.cyan;
      case AchievementCategory.social:
        return AppColors.purpleSoft;
      case AchievementCategory.milestones:
        return AppColors.purple;
      case AchievementCategory.special:
        return const Color(0xFFEF4444);
    }
  }

  String _categoryLabel(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.actions:
        return 'Actions';
      case AchievementCategory.lanes:
        return 'Lanes';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  void _onCategorySelected(AchievementCategory? category) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
  }

  void _onBackPressed() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, provider, _) {
        final achievements = _selectedCategory == null
            ? provider.achievements
            : provider.achievementsByCategory(_selectedCategory!);
        final unlockedCount = provider.unlockedAchievements.length;
        final totalCount = provider.achievements.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0A1E),
                  Color(0xFF0A0C14),
                  Color(0xFF0A1014),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: _GlowOrb(color: AppColors.purple, size: 260),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: _GlowOrb(color: AppColors.cyan, size: 300),
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        _buildHeader(unlockedCount, totalCount),
                        const SizedBox(height: 8),
                        _buildCategoryFilters(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: provider.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.purple,
                                  ),
                                )
                              : achievements.isEmpty
                                  ? const _EmptyState()
                                  : GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 32,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 0.78,
                                      ),
                                      itemCount: achievements.length,
                                      itemBuilder: (context, index) {
                                        final achievement = achievements[index];
                                        return _AchievementCard(
                                          achievement: achievement,
                                          accentColor: _categoryColor(
                                            achievement.category,
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int unlockedCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _onBackPressed,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$unlockedCount of $totalCount unlocked',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
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

  Widget _buildCategoryFilters() {
    final categories = AchievementCategory.values;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _CategoryChip(
            label: 'All',
            color: AppColors.purple,
            selected: _selectedCategory == null,
            onTap: () => _onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            _CategoryChip(
              label: _categoryLabel(category),
              color: _categoryColor(category),
              selected: _selectedCategory == category,
              onTap: () => _onCategorySelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: AppColors.card.withValues(alpha: 0.5),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(icon, color: AppColors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: selected
              ? color.withValues(alpha: 0.22)
              : AppColors.card.withValues(alpha: 0.5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.7)
                      : AppColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.greyLight,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final Color accentColor;

  const _AchievementCard({
    required this.achievement,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final progress = achievement.progressPercent;

    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unlocked
                    ? accentColor.withValues(alpha: 0.5)
                    : AppColors.divider.withValues(alpha: 0.6),
                width: unlocked ? 1.4 : 1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      achievement.icon,
                      size: 34,
                      color: achievement.color.withValues(
                        alpha: unlocked ? 1.0 : 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      achievement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked ? AppColors.white : AppColors.greyLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (unlocked)
                      _UnlockedBadge(color: accentColor)
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.divider.withValues(alpha: 0.6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${achievement.currentProgress} / ${achievement.requiredProgress}',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!unlocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: AppColors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockedBadge extends StatelessWidget {
  final Color color;
  const _UnlockedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            'Unlocked!',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'No achievements here yet',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back after exploring more categories',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

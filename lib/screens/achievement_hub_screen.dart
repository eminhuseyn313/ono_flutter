import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_progress_card.dart';
import '../widgets/badge_card.dart';

class AchievementHubScreen extends StatefulWidget {
  const AchievementHubScreen({super.key});

  @override
  State<AchievementHubScreen> createState() => _AchievementHubScreenState();
}

class _AchievementHubScreenState extends State<AchievementHubScreen> {
  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementProvider>().loadAll();
    });
  }

  List<Achievement> _filteredAchievements(AchievementProvider provider) {
    if (_selectedCategory == null) {
      return provider.achievements;
    }
    return provider.achievementsByCategory(_selectedCategory!);
  }

  Future<void> _onRefresh() async {
    await context.read<AchievementProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Achievements',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.achievements.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.purple,
              ),
            );
          }

          if (provider.error != null && provider.achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: const Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load achievements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.loadAll(),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final filtered = _filteredAchievements(provider);
          // Sort: unlocked first, then by progress desc
          final sorted = List<Achievement>.from(filtered)
            ..sort((a, b) {
              if (a.isUnlocked && !b.isUnlocked) return -1;
              if (!a.isUnlocked && b.isUnlocked) return 1;
              if (a.isUnlocked && b.isUnlocked) {
                return (b.unlockedAt ?? DateTime(2000))
                    .compareTo(a.unlockedAt ?? DateTime(2000));
              }
              return b.progressPercent.compareTo(a.progressPercent);
            });

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Stats header
                if (provider.stats != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _StatsHeader(stats: provider.stats!),
                    ),
                  ),

                // Recently unlocked section
                if (provider.stats != null &&
                    provider.stats!.recentlyUnlocked.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _RecentlyUnlockedSection(
                        achievements: provider.stats!.recentlyUnlocked,
                      ),
                    ),
                  ),

                // Progress card
                if (provider.stats != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: AchievementProgressCard(
                        stats: provider.stats!,
                        lockedAchievements: provider.lockedAchievements,
                      ),
                    ),
                  ),

                // Category filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: _CategoryFilterChips(
                      selected: _selectedCategory,
                      onSelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  ),
                ),

                // Achievement grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return BadgeCard(
                          achievement: sorted[index],
                        );
                      },
                      childCount: sorted.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final AchievementStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleDark.withValues(alpha: 0.4),
            AppColors.card.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.emoji_events,
            iconColor: AppColors.warning,
            value: '${stats.unlockedCount}/${stats.totalAchievements}',
            label: 'Unlocked',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _StatItem(
            icon: Icons.bolt,
            iconColor: AppColors.purple,
            value: '${stats.totalXpEarned}',
            label: 'Total XP',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _StatItem(
            icon: Icons.diamond,
            iconColor: _rarityIconColor(stats.highestRarity),
            value: _rarityLabel(stats.highestRarity),
            label: 'Best Rarity',
          ),
        ],
      ),
    );
  }

  Color _rarityIconColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return AppColors.grey;
      case AchievementRarity.rare:
        return AppColors.cyan;
      case AchievementRarity.epic:
        return AppColors.purple;
      case AchievementRarity.legendary:
        return AppColors.warning;
    }
  }

  String _rarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

class _RecentlyUnlockedSection extends StatelessWidget {
  final List<Achievement> achievements;

  const _RecentlyUnlockedSection({required this.achievements});

  Color _rarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return AppColors.grey;
      case AchievementRarity.rare:
        return AppColors.cyan;
      case AchievementRarity.epic:
        return AppColors.purple;
      case AchievementRarity.legendary:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Unlocked',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final glowColor = _rarityColor(achievement.rarity);
              return Container(
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: achievement.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        achievement.icon,
                        color: achievement.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        achievement.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onSelected;

  const _CategoryFilterChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [null, ...AchievementCategory.values];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          final label = category == null ? 'All' : _categoryLabel(category);

          return GestureDetector(
            onTap: () => onSelected(category),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple
                    : AppColors.cardLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.divider,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
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
}

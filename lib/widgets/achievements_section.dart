import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';

/// A section that displays unlocked and locked achievement badges.
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext buildContext) {
    return Consumer<AchievementProvider>(
      builder: (context, provider, _) {
        final unlocked = provider.unlockedAchievements;
        final locked = provider.lockedAchievements;
        final total = provider.achievements.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${unlocked.length}/$total',
                    style: const TextStyle(
                      color: AppColors.purpleSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Unlocked badges
            if (unlocked.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked
                    .map((a) => _BadgeTile(achievement: a, unlocked: true))
                    .toList(),
              ),
              if (locked.isNotEmpty) const SizedBox(height: 12),
            ],

            // Locked badges
            if (locked.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: locked
                    .map((a) => _BadgeTile(achievement: a, unlocked: false))
                    .toList(),
              ),

            if (unlocked.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(Icons.military_tech_rounded, size: 32, color: AppColors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'Start completing actions to earn badges!',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _BadgeTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? AppColors.purple.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            unlocked
                ? Icon(achievement.icon, size: 24, color: achievement.color)
                : Icon(Icons.lock_rounded, size: 24, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? AppColors.white : AppColors.grey,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(
              unlocked ? achievement.icon : Icons.lock_rounded,
              size: 48,
              color: unlocked ? achievement.color : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: TextStyle(
                color: unlocked ? AppColors.white : AppColors.grey,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unlocked ? 'Unlocked' : 'Not yet unlocked',
              style: TextStyle(
                color: unlocked ? AppColors.success : AppColors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: AppColors.purple)),
          ),
        ],
      ),
    );
  }
}

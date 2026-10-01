import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/gamification.dart';

class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardRow({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.purple.withValues(alpha: 0.12)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.purple.withValues(alpha: 0.4)
              : AppColors.divider,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildRank(),
          const SizedBox(width: 14),
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(child: _buildUserInfo()),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildRank() {
    final isTopThree = entry.rank <= 3;
    return SizedBox(
      width: 32,
      child: Center(
        child: isTopThree
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _rankColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _rankColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _rankEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
            : Text(
                '#${entry.rank}',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  String get _rankEmoji {
    switch (entry.rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.grey;
    }
  }

  Widget _buildAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.purple.withValues(alpha: 0.2)
            : AppColors.cardLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.purple.withValues(alpha: 0.5)
              : AppColors.divider,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          entry.avatar,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.username,
          style: TextStyle(
            color: entry.isCurrentUser ? AppColors.purpleSoft : AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Lv ${entry.level}',
                style: TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.totalXp} XP',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: AppColors.cyan,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '+${entry.weeklyXp}',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔥',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 3),
            Text(
              '${entry.streak}d',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

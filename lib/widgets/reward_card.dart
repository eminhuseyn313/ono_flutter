import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/gamification.dart';

class RewardCard extends StatelessWidget {
  final RewardItem reward;
  final int userTotalXp;
  final VoidCallback? onPurchase;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userTotalXp,
    this.onPurchase,
  });

  bool get _canAfford => userTotalXp >= reward.xpCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: reward.isUnlocked ? 1.5 : 1,
        ),
        boxShadow: _buildShadow(),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildInfo(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
          if (!reward.isUnlocked && !_canAfford) _buildLockOverlay(),
          if (reward.isUnlocked) _buildOwnedBadge(),
        ],
      ),
    );
  }

  Color get _borderColor {
    if (reward.isUnlocked) {
      return AppColors.green.withValues(alpha: 0.5);
    }
    if (_canAfford) {
      return reward.rarity.color.withValues(alpha: 0.6);
    }
    return AppColors.divider;
  }

  List<BoxShadow> _buildShadow() {
    if (!_canAfford || reward.isUnlocked) return [];
    return [
      BoxShadow(
        color: reward.rarity.color.withValues(alpha: 0.2),
        blurRadius: 12,
        spreadRadius: 1,
      ),
    ];
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: reward.rarity.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              reward.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        _buildRarityBadge(),
      ],
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: reward.rarity.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: reward.rarity.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        reward.rarity.label,
        style: TextStyle(
          color: reward.rarity.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reward.name,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          reward.description,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (reward.isUnlocked) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Owned',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: AppColors.purple,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${reward.xpCost} XP',
              style: TextStyle(
                color: _canAfford ? AppColors.purpleSoft : AppColors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_canAfford)
          GestureDetector(
            onTap: onPurchase,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.purpleDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Unlock',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_rounded,
              color: AppColors.grey,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnedBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

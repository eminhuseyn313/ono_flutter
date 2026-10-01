// widgets/partner_card.dart

import 'package:flutter/material.dart';
import '../models/accountability.dart';
import '../theme/app_theme.dart';

class PartnerCard extends StatelessWidget {
  final AccountabilityPartner partner;
  final VoidCallback onCheckIn;
  final VoidCallback onSendProof;
  final VoidCallback onPause;

  const PartnerCard({
    super.key,
    required this.partner,
    required this.onCheckIn,
    required this.onSendProof,
    required this.onPause,
  });

  String _formatLastActive(DateTime? lastCheckIn) {
    if (lastCheckIn == null) return 'No check-ins yet';
    final diff = DateTime.now().difference(lastCheckIn);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Color _statusColor() {
    switch (partner.status) {
      case PartnerStatus.active:
        return AppColors.green;
      case PartnerStatus.paused:
        return AppColors.warning;
      case PartnerStatus.pending:
        return AppColors.cyan;
      case PartnerStatus.ended:
        return AppColors.grey;
    }
  }

  String _statusLabel() {
    switch (partner.status) {
      case PartnerStatus.active:
        return 'Active';
      case PartnerStatus.paused:
        return 'Paused';
      case PartnerStatus.pending:
        return 'Pending';
      case PartnerStatus.ended:
        return 'Ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.purpleDark.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    partner.partnerAvatar,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            partner.partnerName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: TextStyle(
                                color: _statusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Lvl ${partner.partnerLevel}',
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.grey.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatLastActive(partner.lastCheckInAt),
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    value: '${partner.sharedStreak}',
                    label: 'Streak',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.divider,
                  ),
                  _StatItem(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.warning,
                    value: '${partner.longestStreak}',
                    label: 'Best',
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.divider,
                  ),
                  _StatItem(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.cyan,
                    value: '${partner.partnerXp}',
                    label: 'XP',
                  ),
                ],
              ),
            ),
            if (partner.status == PartnerStatus.active ||
                partner.status == PartnerStatus.paused) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Check In',
                      color: AppColors.purple,
                      onTap: partner.status == PartnerStatus.active
                          ? onCheckIn
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Send Proof',
                      color: AppColors.cyan,
                      onTap: partner.status == PartnerStatus.active
                          ? onSendProof
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: partner.status == PartnerStatus.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: partner.status == PartnerStatus.paused
                          ? 'Resume'
                          : 'Pause',
                      color: AppColors.warning,
                      onTap: onPause,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.cardLight.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isDisabled ? AppColors.grey.withValues(alpha: 0.5) : color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? AppColors.grey.withValues(alpha: 0.5)
                    : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

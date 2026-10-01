import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_center_screen.dart';
import '../theme/app_theme.dart';

/// Compact card for the profile/settings screen summarizing notification
/// status, with a quick "all on/off" toggle and a link to the full
/// settings screen.
class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push('/notification-settings');
  }

  List<_CategoryStatus> _activeCategories(NotificationPreferences prefs) {
    final all = <_CategoryStatus>[
      _CategoryStatus(NotificationType.streakRisk, prefs.streakAlerts),
      _CategoryStatus(NotificationType.roleModel, prefs.roleModelAlerts),
      _CategoryStatus(NotificationType.socialProof, prefs.socialProof),
      _CategoryStatus(NotificationType.milestone, prefs.milestoneAlerts),
    ];
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final prefs = provider.preferences;
        final categories = _activeCategories(prefs);
        final activeCount = categories.where((c) => c.active).length;

        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: () => _openSettings(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.purpleSoft.withValues(alpha: 0.25),
                                    AppColors.purple.withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                prefs.enabled
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_rounded,
                                color: prefs.enabled
                                    ? AppColors.purpleSoft
                                    : AppColors.grey,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prefs.enabled
                                        ? '$activeCount of ${categories.length} types on'
                                        : 'All muted',
                                    style: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: prefs.enabled,
                              activeTrackColor: AppColors.purple,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                provider.updatePreferences(
                                  NotificationCenterScreen.userId,
                                  prefs.copyWith(enabled: v),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final cat in categories) ...[
                              Expanded(child: _CategoryChip(status: cat)),
                              if (cat != categories.last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Manage notification settings',
                              style: TextStyle(
                                color: AppColors.purpleSoft,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.purpleSoft,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryStatus {
  final NotificationType type;
  final bool active;

  const _CategoryStatus(this.type, this.active);
}

class _CategoryChip extends StatelessWidget {
  final _CategoryStatus status;

  const _CategoryChip({required this.status});

  Color _color(NotificationType type) {
    switch (type) {
      case NotificationType.streakRisk:
        return const Color(0xFFD9774A);
      case NotificationType.roleModel:
        return AppColors.purple;
      case NotificationType.socialProof:
        return AppColors.cyan;
      case NotificationType.milestone:
        return AppColors.warning;
      case NotificationType.reminder:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(status.type);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: status.active
            ? color.withValues(alpha: 0.14)
            : AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status.active
              ? color.withValues(alpha: 0.3)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(status.type.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 3),
          Text(
            status.type.label.split(' ').first,
            style: TextStyle(
              color: status.active ? color : AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

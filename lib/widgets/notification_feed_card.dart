import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notification_model.dart';
import '../theme/app_theme.dart';

/// Individual notification card used in the notification feed.
///
/// Shows a colored left indicator strip, type emoji, title, body,
/// relative timestamp, and an unread dot. Supports swipe-to-dismiss
/// and a staggered entrance animation.
class NotificationFeedCard extends StatefulWidget {
  const NotificationFeedCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.animationDelay = Duration.zero,
  });

  final OnoNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  /// Stagger delay for the entrance animation.
  final Duration animationDelay;

  @override
  State<NotificationFeedCard> createState() => _NotificationFeedCardState();
}

class _NotificationFeedCardState extends State<NotificationFeedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Returns the accent color for the notification type.
  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.streakRisk:
        return AppColors.warning;
      case NotificationType.roleModel:
        return AppColors.purple;
      case NotificationType.socialProof:
        return AppColors.cyan;
      case NotificationType.milestone:
        return const Color(0xFF6FA386); // emerald
      case NotificationType.reminder:
        return AppColors.grey;
    }
  }

  /// Returns the emoji for the notification type.
  String _typeEmoji(NotificationType type) {
    switch (type) {
      case NotificationType.streakRisk:
        return '🔥';
      case NotificationType.roleModel:
        return '💬';
      case NotificationType.socialProof:
        return '🏆';
      case NotificationType.milestone:
        return '🎯';
      case NotificationType.reminder:
        return '⏰';
    }
  }

  /// Formats a DateTime into a relative time string.
  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final accentColor = _typeColor(n.type);
    final isUnread = !n.isRead;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            HapticFeedback.lightImpact();
            widget.onDismiss();
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.warning, size: 22),
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.purple.withValues(alpha: 0.08)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread
                      ? AppColors.purple.withValues(alpha: 0.2)
                      : AppColors.divider,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Left color indicator strip.
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                        ),

                        // Content.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Type emoji.
                                Text(
                                  _typeEmoji(n.type),
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),

                                // Title, body, time.
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 14,
                                                fontWeight: isUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                height: 1.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isUnread) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.purple,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.body,
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _relativeTime(n.createdAt),
                                        style: TextStyle(
                                          color: AppColors.grey.withValues(alpha: 0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

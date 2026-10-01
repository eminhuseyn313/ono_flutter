import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_feed_card.dart';

/// Full notification history/feed screen showing all past notifications
/// with filtering, grouping, and swipe-to-dismiss.
class NotificationFeedScreen extends StatefulWidget {
  const NotificationFeedScreen({super.key});

  @override
  State<NotificationFeedScreen> createState() => _NotificationFeedScreenState();
}

class _NotificationFeedScreenState extends State<NotificationFeedScreen> {
  NotificationType? _activeFilter;

  /// Labels for the filter chips.
  static const Map<NotificationType?, String> _filterLabels = {
    null: 'All',
    NotificationType.streakRisk: 'Streak',
    NotificationType.roleModel: 'Role Model',
    NotificationType.socialProof: 'Social',
    NotificationType.milestone: 'Milestone',
  };

  /// Groups notifications by date bucket.
  Map<String, List<OnoNotification>> _groupByDate(
    List<OnoNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<OnoNotification>>{};

    for (final n in notifications) {
      final nDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String bucket;

      if (nDate == today) {
        bucket = 'Today';
      } else if (nDate == yesterday) {
        bucket = 'Yesterday';
      } else if (nDate.isAfter(weekAgo)) {
        bucket = 'This Week';
      } else {
        bucket = 'Earlier';
      }

      groups.putIfAbsent(bucket, () => []).add(n);
    }

    return groups;
  }

  /// Ordered bucket keys for display.
  static const List<String> _bucketOrder = [
    'Today',
    'Yesterday',
    'This Week',
    'Earlier',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final allNotifications = provider.notifications;
          final unreadCount =
              allNotifications.where((n) => !n.isRead).length;

          // Apply filter.
          final filtered = _activeFilter == null
              ? allNotifications
              : allNotifications
                  .where((n) => n.type == _activeFilter)
                  .toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App bar.
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.markAllRead('user1');
                      },
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Filter chips.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filterLabels.entries.map((entry) {
                      final isActive = _activeFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isActive,
                          label: Text(entry.value),
                          labelStyle: TextStyle(
                            color: isActive ? AppColors.white : AppColors.grey,
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                          backgroundColor: AppColors.card,
                          selectedColor: AppColors.purple.withValues(alpha: 0.3),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.purple.withValues(alpha: 0.5)
                                : AppColors.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          showCheckmark: false,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _activeFilter =
                                  _activeFilter == entry.key ? null : entry.key;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Content: grouped list or empty state.
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                ..._buildGroupedList(filtered, provider),
            ],
          );
        },
      ),
    );
  }

  /// Builds the grouped notification list as slivers.
  List<Widget> _buildGroupedList(
    List<OnoNotification> notifications,
    NotificationProvider provider,
  ) {
    final groups = _groupByDate(notifications);
    final slivers = <Widget>[];

    for (final bucket in _bucketOrder) {
      final items = groups[bucket];
      if (items == null || items.isEmpty) continue;

      // Section header.
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              bucket,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );

      // Notification cards.
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = items[index];
                return NotificationFeedCard(
                  notification: notification,
                  animationDelay: Duration(milliseconds: index * 60),
                  onTap: () {
                    provider.markRead('user1', notification.id);
                    if (notification.actionRoute != null) {
                      context.push(notification.actionRoute!);
                    }
                  },
                  onDismiss: () {
                    provider.markRead('user1', notification.id);
                  },
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      );
    }

    // Bottom padding.
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

    return slivers;
  }

  /// Builds the empty-state view with an emoji-based illustration.
  Widget _buildEmptyState() {
    final hasFilter = _activeFilter != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji composition.
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '🔔',
                  style: TextStyle(
                    fontSize: 56,
                    color: AppColors.grey.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Text(
                    hasFilter ? '🔍' : '✨',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No matching notifications' : 'All caught up',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try a different filter or check back later.'
                  : 'You\'ve seen everything. Go build something.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

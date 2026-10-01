import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notification_model.dart';
import '../theme/app_theme.dart';

/// An animated slide-in banner surfaced at the top of the screen when a
/// new notification arrives. Auto-dismisses after 4 seconds, supports
/// swipe-to-dismiss, and taps through to [onTap] / actionRoute.
///
/// Typically shown via [NotificationBanner.show], which handles inserting
/// and removing an [OverlayEntry] for you.
class NotificationBanner extends StatefulWidget {
  final OnoNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final Duration displayDuration;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismissed,
    this.displayDuration = const Duration(seconds: 4),
  });

  /// Shows a banner as an overlay above the current route. Returns a
  /// closure that force-dismisses it early, if needed.
  static VoidCallback show(
    BuildContext context, {
    required OnoNotification notification,
    VoidCallback? onTap,
  }) {
    late OverlayEntry entry;
    final overlay = Overlay.of(context, rootOverlay: true);

    void remove() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: NotificationBanner(
            notification: notification,
            onTap: () {
              remove();
              onTap?.call();
            },
            onDismissed: remove,
          ),
        ),
      ),
    );

    overlay.insert(entry);
    return remove;
  }

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _dismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    HapticFeedback.lightImpact();
    _controller.forward();

    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _dismiss();
    widget.onTap?.call();
  }

  Color _laneColor(String? lane) {
    switch (lane) {
      case 'mind':
        return AppColors.purple;
      case 'body':
        return AppColors.green;
      case 'social':
        return const Color(0xFFD9774A);
      case 'skill':
        return AppColors.cyan;
      default:
        return _typeColor(widget.notification.type);
    }
  }

  Color _typeColor(NotificationType type) {
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
    final notif = widget.notification;
    final accent = _laneColor(notif.lane);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Dismissible(
              key: ValueKey('banner_${notif.id}'),
              direction: DismissDirection.up,
              onDismissed: (_) {
                _dismissTimer?.cancel();
                widget.onDismissed?.call();
              },
              child: GestureDetector(
                onTap: _handleTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  bottomLeft: Radius.circular(18),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        notif.type.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            notif.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.grey.withValues(alpha: 0.6),
                                      size: 20,
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
        ),
      ),
    );
  }
}

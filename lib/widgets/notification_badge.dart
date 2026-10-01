import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small badge overlay for a bell icon or bottom-nav item, showing the
/// unread notification count (capped display at "9+"). Pulses briefly
/// whenever [pulse] flips true, signalling a fresh arrival.
class NotificationBadge extends StatefulWidget {
  final Widget child;
  final int count;

  /// When true, the badge briefly pulses to draw attention. The caller
  /// is responsible for clearing this back to false after it fires
  /// (e.g. via a provider's `clearNewFlag`).
  final bool pulse;

  /// Renders a small red dot instead of a numeric count.
  final bool dotOnly;

  const NotificationBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.pulse = false,
    this.dotOnly = false,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 2,
      ),
    ]).animate(_pulseController);

    if (widget.pulse) {
      _pulseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !oldWidget.pulse) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _displayCount => widget.count > 9 ? '9+' : '${widget.count}';

  @override
  Widget build(BuildContext context) {
    final showBadge = widget.count > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (showBadge)
          Positioned(
            top: -4,
            right: -4,
            child: AnimatedBuilder(
              animation: _scale,
              builder: (context, child) {
                return Transform.scale(scale: _scale.value, child: child);
              },
              child: widget.dotOnly
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316)
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316)
                                .withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        _displayCount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

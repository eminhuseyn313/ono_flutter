import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/time_mode.dart';
import '../theme/app_theme.dart';

/// A reusable animated gradient background that transitions smoothly between
/// time-of-day mode gradients.
///
/// Includes a subtle shimmer effect (slow-moving highlight) for visual polish.
/// Wrap any widget tree to apply the current mode's gradient behind it.
class TimeModeGradient extends StatefulWidget {
  const TimeModeGradient({
    super.key,
    required this.config,
    required this.child,
    this.borderRadius,
  });

  final TimeModeConfig config;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<TimeModeGradient> createState() => _TimeModeGradientState();
}

class _TimeModeGradientState extends State<TimeModeGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.config.gradient,
        ),
      ),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // A slow-moving translucent highlight to add life.
          final value = _shimmerController.value;
          final dx = math.cos(value * 2 * math.pi) * 0.3;
          final dy = math.sin(value * 2 * math.pi) * 0.3;

          return ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: Stack(
              children: [
                // Shimmer overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(dx, dy),
                        radius: 1.2,
                        colors: [
                          AppColors.white.withValues(alpha: 0.06),
                          AppColors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actual child content
                child!,
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}


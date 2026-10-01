import 'package:flutter/material.dart';

import '../models/becoming_arc.dart';
import '../services/adaptive_difficulty_engine.dart';
import '../theme/app_theme.dart';

/// Compact inline widget that shows the current difficulty level as 1–4
/// coloured dots. The active dot pulses continuously.
///
/// Designed to sit on step cards inside the arc screens.
class DifficultyIndicator extends StatefulWidget {
  final DifficultyAdjustment adjustment;
  final ArcLayer layer;

  /// Whether to display a text label next to the dots.
  final bool showLabel;

  const DifficultyIndicator({
    super.key,
    required this.adjustment,
    required this.layer,
    this.showLabel = false,
  });

  @override
  State<DifficultyIndicator> createState() => _DifficultyIndicatorState();
}

class _DifficultyIndicatorState extends State<DifficultyIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.adjustment.intensityFor(widget.layer);
    final activeCount = intensity.dotCount;
    final layerColor = widget.layer.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(4, (index) {
          final isActive = index < activeCount;
          final isLast = index == activeCount - 1;

          Widget dot = Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? layerColor
                  : layerColor.withValues(alpha: 0.15),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: layerColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          );

          // Pulse only the highest active dot.
          if (isLast && isActive) {
            dot = AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Transform.scale(
                    scale: 0.85 + _pulseAnimation.value * 0.25,
                    child: child,
                  ),
                );
              },
              child: dot,
            );
          }

          return dot;
        }),
        if (widget.showLabel) ...[
          const SizedBox(width: 6),
          Text(
            intensity.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: layerColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }
}

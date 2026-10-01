import 'package:flutter/material.dart';

import '../models/ghost_mode.dart';
import '../theme/app_theme.dart';

/// Animated dual-bar chart comparing current progress against the ghost.
///
/// Ghost bars are rendered with a translucent fill; current bars use the solid
/// accent color. Each lane animates in with a staggered delay.
class GhostComparisonChart extends StatefulWidget {
  final GhostComparison comparison;

  const GhostComparisonChart({super.key, required this.comparison});

  @override
  State<GhostComparisonChart> createState() => _GhostComparisonChartState();
}

class _GhostComparisonChartState extends State<GhostComparisonChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void didUpdateWidget(GhostComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comparison != widget.comparison) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lanes = widget.comparison.current.laneScores.keys.toList();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: List.generate(lanes.length, (index) {
            final lane = lanes[index];
            // Stagger: each lane starts 0.15 later than the previous.
            final begin = (index * 0.15).clamp(0.0, 0.6);
            final end = (begin + 0.4).clamp(0.0, 1.0);
            final curvedValue = Curves.easeOutCubic.transform(
              Interval(begin, end).transform(_controller.value),
            );

            final currentScore =
                widget.comparison.current.laneScores[lane] ?? 0.0;
            final ghostScore =
                widget.comparison.ghost.laneScores[lane] ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _LaneBarPair(
                lane: lane,
                currentScore: currentScore * curvedValue,
                ghostScore: ghostScore * curvedValue,
                currentLabel: '${(currentScore * 100).round()}%',
                ghostLabel: '${(ghostScore * 100).round()}%',
              ),
            );
          }),
        );
      },
    );
  }
}

class _LaneBarPair extends StatelessWidget {
  final String lane;
  final double currentScore;
  final double ghostScore;
  final String currentLabel;
  final String ghostLabel;

  const _LaneBarPair({
    required this.lane,
    required this.currentScore,
    required this.ghostScore,
    required this.currentLabel,
    required this.ghostLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lane label
        Text(
          lane,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        // Ghost bar
        _BarRow(
          label: ghostLabel,
          fraction: ghostScore,
          color: AppColors.purple.withValues(alpha: 0.3),
          labelColor: AppColors.grey,
          tag: 'Ghost',
        ),
        const SizedBox(height: 4),

        // Current bar
        _BarRow(
          label: currentLabel,
          fraction: currentScore,
          color: AppColors.purple,
          labelColor: AppColors.white,
          tag: 'You',
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;
  final Color labelColor;
  final String tag;

  const _BarRow({
    required this.label,
    required this.fraction,
    required this.color,
    required this.labelColor,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tag label (fixed width for alignment).
        SizedBox(
          width: 42,
          child: Text(
            tag,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Bar
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * fraction.clamp(0.0, 1.0);
              return Stack(
                children: [
                  // Track
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Filled portion
                  Container(
                    height: 18,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Percentage label
        SizedBox(
          width: 38,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/phase_transition.dart';
import '../theme/app_theme.dart';

/// A horizontal bar split into three connected segments representing the
/// Foundation / Growth / Mastery phases of a 30-day Becoming Arc.
///
/// The current phase fills proportionally based on [currentDay], completed
/// phases are fully filled, and future phases are dimmed. Small diamond
/// milestone markers sit at the phase boundaries (day 10 and day 20).
class PhaseProgressBar extends StatefulWidget {
  /// The user's current day (1–30).
  final int currentDay;

  /// Total number of days in the arc (default 30).
  final int totalDays;

  const PhaseProgressBar({
    super.key,
    required this.currentDay,
    this.totalDays = 30,
  });

  @override
  State<PhaseProgressBar> createState() => _PhaseProgressBarState();
}

class _PhaseProgressBarState extends State<PhaseProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOut),
    );
    _fillController.forward();
  }

  @override
  void didUpdateWidget(covariant PhaseProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDay != widget.currentDay) {
      _fillController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.currentDay.clamp(1, widget.totalDays);
    final phases = ArcPhaseInfo.phases;
    final currentPhaseNumber = ArcPhaseInfo.phaseNumberForDay(day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Phase labels ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: List.generate(phases.length, (i) {
              final phase = phases[i];
              final isCurrent = phase.phaseNumber == currentPhaseNumber;
              final isCompleted = phase.phaseNumber < currentPhaseNumber;

              return Expanded(
                child: Text(
                  phase.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? phase.themeColor
                        : isCompleted
                            ? phase.themeColor.withValues(alpha: 0.7)
                            : AppColors.grey.withValues(alpha: 0.5),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // --- Bar segments ---
        AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, _) {
            return SizedBox(
              height: 28,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final segmentWidth = totalWidth / phases.length;

                  return Stack(
                    children: [
                      // Background track
                      Positioned.fill(
                        child: Row(
                          children: List.generate(phases.length, (i) {
                            final isFirst = i == 0;
                            final isLast = i == phases.length - 1;
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: isFirst ? 0 : 1,
                                  right: isLast ? 0 : 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.horizontal(
                                    left: isFirst
                                        ? const Radius.circular(8)
                                        : Radius.zero,
                                    right: isLast
                                        ? const Radius.circular(8)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Filled segments
                      ...List.generate(phases.length, (i) {
                        final phase = phases[i];
                        final phaseStart = i * 10 + 1;
                        final phaseEnd = (i + 1) * 10;
                        final isFirst = i == 0;
                        final isLast = i == phases.length - 1;

                        double fillFraction;
                        if (day >= phaseEnd) {
                          // Phase completed.
                          fillFraction = 1.0;
                        } else if (day < phaseStart) {
                          // Phase not yet started.
                          fillFraction = 0.0;
                        } else {
                          // In progress.
                          fillFraction =
                              (day - phaseStart + 1) / (phaseEnd - phaseStart + 1);
                        }

                        final animatedFill = fillFraction * _fillAnimation.value;
                        final left = i * segmentWidth + (i > 0 ? 1 : 0);
                        final width =
                            (segmentWidth - (i > 0 ? 1 : 0) - (isLast ? 0 : 1)) *
                                animatedFill;

                        if (width <= 0) return const SizedBox.shrink();

                        return Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          width: width,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  phase.themeColor.withValues(alpha: 0.9),
                                  phase.themeColor.withValues(alpha: 0.65),
                                ],
                              ),
                              borderRadius: BorderRadius.horizontal(
                                left: isFirst
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                right: (isLast && animatedFill >= 1.0)
                                    ? const Radius.circular(8)
                                    : const Radius.circular(2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: phase.themeColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Milestone markers at phase boundaries
                      ..._buildMilestoneMarkers(
                          segmentWidth, day, currentPhaseNumber),
                    ],
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 6),

        // --- Day range labels ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: List.generate(phases.length, (i) {
              final phase = phases[i];
              final isCurrent = phase.phaseNumber == currentPhaseNumber;

              return Expanded(
                child: Text(
                  'Day ${phase.dayRange}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCurrent
                        ? AppColors.grey
                        : AppColors.grey.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Builds diamond-shaped milestone markers at the boundaries between phases.
  List<Widget> _buildMilestoneMarkers(
    double segmentWidth,
    int currentDay,
    int currentPhase,
  ) {
    final markers = <Widget>[];

    // Boundaries sit at the end of phase 1 (day 10) and phase 2 (day 20).
    for (int i = 1; i < ArcPhaseInfo.phases.length; i++) {
      final boundaryX = i * segmentWidth;
      final passed = currentDay > i * 10;
      final color =
          passed ? ArcPhaseInfo.phases[i - 1].themeColor : AppColors.grey;

      markers.add(
        Positioned(
          left: boundaryX - 7,
          top: 7,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: passed ? color : AppColors.card,
                border: Border.all(
                  color: color.withValues(alpha: passed ? 0.9 : 0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: passed
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }
}

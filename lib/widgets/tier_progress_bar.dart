import 'package:flutter/material.dart';

import '../models/legacy_score.dart';
import '../theme/app_theme.dart';

/// A horizontal bar showing progress from [currentTier]'s floor to the next
/// tier's floor, with a glowing marker at the current score and tier labels
/// at each boundary. Animates its fill whenever [progress] changes.
class TierProgressBar extends StatefulWidget {
  final LegacyTier currentTier;
  final double progress; // 0.0 - 1.0
  final int currentScore;
  final double height;

  const TierProgressBar({
    super.key,
    required this.currentTier,
    required this.progress,
    required this.currentScore,
    this.height = 14,
  });

  @override
  State<TierProgressBar> createState() => _TierProgressBarState();
}

class _TierProgressBarState extends State<TierProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fillAnimation;
  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _lastProgress = widget.progress;
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant TierProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fillAnimation = Tween<double>(
        begin: _lastProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _lastProgress = widget.progress;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.currentTier.next;
    final tierColor = widget.currentTier.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, _) {
            final fill = _fillAnimation.value.clamp(0.0, 1.0);
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final markerX = (width * fill).clamp(0.0, width);

                return SizedBox(
                  height: widget.height + 16,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Track.
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: widget.height,
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(widget.height / 2),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Fill.
                      Positioned(
                        top: 8,
                        left: 0,
                        child: Container(
                          height: widget.height,
                          width: markerX,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.height / 2),
                            gradient: LinearGradient(
                              colors: [
                                tierColor.withValues(alpha: 0.7),
                                tierColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Glowing marker at the current score.
                      Positioned(
                        top: 0,
                        left: (markerX - 11).clamp(-11.0, width - 11),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            border: Border.all(color: tierColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withValues(alpha: 0.7),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.currentTier.emoji} ${widget.currentTier.label}',
              style: TextStyle(
                color: tierColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (next != null)
              Text(
                '${next.emoji} ${next.label}',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                'Peak reached',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A thinner, no-label variant of the fill visual for use inside compact
/// cards (see [LegacyScoreCard]).
class MiniTierProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const MiniTierProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: height,
                width: constraints.maxWidth,
                color: AppColors.cardLight,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                height: height,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/xp_system.dart';

class XpProgressBar extends StatefulWidget {
  final int totalXp;
  final double height;

  const XpProgressBar({
    super.key,
    required this.totalXp,
    this.height = 28,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: XpSystem.progressToNext(widget.totalXp),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalXp != widget.totalXp) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: XpSystem.progressToNext(widget.totalXp),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = XpSystem.levelFor(widget.totalXp);
    final nextLevelIndex = currentLevel.level < XpSystem.levels.length
        ? currentLevel.level
        : currentLevel.level - 1;
    final nextLevel = XpSystem.levels[nextLevelIndex];
    final xpToNext = XpSystem.xpToNextLevel(widget.totalXp);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              currentLevel.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder2(
                listenable: _progressAnimation,
                builder: (context, child) {
                  return _buildBar(_progressAnimation.value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              nextLevel.emoji,
              style: TextStyle(
                fontSize: 24,
                color: AppColors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          currentLevel.level < XpSystem.levels.length
              ? '$xpToNext XP to Level ${nextLevel.level}'
              : 'Max Level Reached',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double progress) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2),
        color: AppColors.cardLight,
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.cyan],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: AppColors.background.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

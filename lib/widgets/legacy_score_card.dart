import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/legacy_score.dart';
import '../theme/app_theme.dart';
import 'tier_progress_bar.dart';

/// Compact glassmorphic card for the home screen: animated score count-up,
/// tier badge with emoji, mini progress bar, and a tap target that navigates
/// to the full Legacy Score screen.
class LegacyScoreCard extends StatefulWidget {
  final int score;
  final LegacyTier tier;
  final double progressToNextTier;
  final VoidCallback? onTap;

  const LegacyScoreCard({
    super.key,
    required this.score,
    required this.tier,
    required this.progressToNextTier,
    this.onTap,
  });

  @override
  State<LegacyScoreCard> createState() => _LegacyScoreCardState();
}

class _LegacyScoreCardState extends State<LegacyScoreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  late AnimationController _countController;
  late Animation<int> _countAnimation;
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _countAnimation = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );
    _lastScore = widget.score;
    _countController.forward();
  }

  @override
  void didUpdateWidget(covariant LegacyScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _countAnimation = IntTween(begin: _lastScore, end: widget.score).animate(
        CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
      );
      _lastScore = widget.score;
      _countController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = widget.tier.color;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _handleTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purpleSoft.withValues(alpha: 0.22),
                  AppColors.purple.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'LEGACY SCORE',
                            style: TextStyle(
                              color: AppColors.purpleSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          _tierBadge(tierColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _countAnimation,
                        builder: (context, _) {
                          return Text(
                            '${_countAnimation.value}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      MiniTierProgressBar(
                        progress: widget.progressToNextTier,
                        color: tierColor,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 13,
                            color: AppColors.grey.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.tier.next == null
                                  ? 'Peak tier reached'
                                  : 'Toward ${widget.tier.next!.label}',
                              style: TextStyle(
                                color: AppColors.grey.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.grey.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tierBadge(Color tierColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.tier.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            widget.tier.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

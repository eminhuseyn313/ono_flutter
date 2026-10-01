import 'package:flutter/material.dart';

import '../models/council.dart';
import '../theme/app_theme.dart';

class CouncilResponseCard extends StatefulWidget {
  final CouncilResponse response;
  final int animationDelay;

  const CouncilResponseCard({
    super.key,
    required this.response,
    this.animationDelay = 0,
  });

  @override
  State<CouncilResponseCard> createState() => _CouncilResponseCardState();
}

class _CouncilResponseCardState extends State<CouncilResponseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _toneColor(CouncilTone tone) {
    switch (tone) {
      case CouncilTone.toughLove:
        return const Color(0xFFEF4444);
      case CouncilTone.philosophical:
        return AppColors.purpleSoft;
      case CouncilTone.practical:
        return AppColors.green;
      case CouncilTone.scientific:
        return AppColors.cyan;
      case CouncilTone.motivational:
        return AppColors.warning;
    }
  }

  Color _toneBadgeBackground(CouncilTone tone) {
    switch (tone) {
      case CouncilTone.toughLove:
        return const Color(0xFFEF4444).withValues(alpha: 0.15);
      case CouncilTone.philosophical:
        return AppColors.purpleSoft.withValues(alpha: 0.15);
      case CouncilTone.practical:
        return AppColors.green.withValues(alpha: 0.15);
      case CouncilTone.scientific:
        return AppColors.cyan.withValues(alpha: 0.15);
      case CouncilTone.motivational:
        return AppColors.warning.withValues(alpha: 0.15);
    }
  }

  String _memberEmoji(String memberId) {
    return CouncilMember.findById(memberId)?.avatarEmoji ?? '🔮';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toneColor = _toneColor(widget.response.tone);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.card.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(color: toneColor, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: toneColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.01),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.5),
                        ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      // Emoji avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: toneColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _memberEmoji(widget.response.memberId),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          widget.response.memberName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColorsLight.white,
                          ),
                        ),
                      ),
                      // Tone badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _toneBadgeBackground(widget.response.tone),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.response.tone.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: toneColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Advice body ──
                  Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? AppColors.divider
                              : AppColorsLight.divider,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.response.advice,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? AppColors.greyLight : AppColorsLight.greyLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

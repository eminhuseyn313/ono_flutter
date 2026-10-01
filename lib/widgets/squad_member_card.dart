import 'dart:math';

import 'package:flutter/material.dart';

import '../models/brotherhood.dart';
import '../theme/app_theme.dart';

class SquadMemberCard extends StatefulWidget {
  final BrotherhoodMember member;
  final bool isTopPerformer;
  final VoidCallback? onSendEncouragement;

  const SquadMemberCard({
    super.key,
    required this.member,
    this.isTopPerformer = false,
    this.onSendEncouragement,
  });

  @override
  State<SquadMemberCard> createState() => _SquadMemberCardState();
}

class _SquadMemberCardState extends State<SquadMemberCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isFallingBehind => widget.member.completionRate < 0.50;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isFallingBehind) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final percentage = (member.completionRate * 100).round();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isFallingBehind ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: member.isCurrentUser
                ? AppColors.purple
                : _isFallingBehind
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
            width: member.isCurrentUser ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (widget.isTopPerformer)
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            if (_isFallingBehind)
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background.withValues(alpha: 0.6),
                      border: Border.all(
                        color: widget.isTopPerformer
                            ? AppColors.green.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        member.avatarEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    member.anonymousName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight:
                          member.isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (member.isCurrentUser)
                    Text(
                      '(You)',
                      style: TextStyle(
                        color: AppColors.purple.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${member.streakDays}d',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Circular progress
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: member.completionRate,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        progressColor: _isFallingBehind
                            ? AppColors.warning
                            : widget.isTopPerformer
                                ? AppColors.green
                                : AppColors.purple,
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Encouragement button (not for self)
                  if (!member.isCurrentUser)
                    GestureDetector(
                      onTap: widget.onSendEncouragement,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Send 💪',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Falling behind badge
            if (_isFallingBehind)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    '⚠️',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),

            // Top performer glow badge
            if (widget.isTopPerformer)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeWidth = 4.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

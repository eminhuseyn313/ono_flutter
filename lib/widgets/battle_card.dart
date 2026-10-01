// widgets/battle_card.dart
// 1v1 battle display card with progress circles and versus layout

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/wakz_challenge.dart';
import '../theme/app_theme.dart';

class BattleCard extends StatelessWidget {
  final ChallengeBattle battle;

  const BattleCard({
    super.key,
    required this.battle,
  });

  String _formatTimeRemaining() {
    final remaining = battle.timeRemaining;
    if (remaining.isNegative) return 'Ended';
    if (remaining.inDays > 0) {
      final hours = remaining.inHours % 24;
      return '\${remaining.inDays}d \${hours}h left';
    }
    if (remaining.inHours > 0) {
      final minutes = remaining.inMinutes % 60;
      return '\${remaining.inHours}h \${minutes}m left';
    }
    return '\${remaining.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final isWinning = battle.myProgress > battle.opponentProgress;
    final isTied = battle.myProgress == battle.opponentProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Timer + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: AppColors.purple,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Battle',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppColors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(),
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // VS Layout
            Row(
              children: [
                // You
                Expanded(
                  child: _BattleSide(
                    name: 'You',
                    emoji: '\u{1F525}',
                    progress: battle.myProgress,
                    target: battle.targetCount,
                    progressPercent: battle.myProgressPercent,
                    color: AppColors.cyan,
                    isLeading: isWinning,
                    showCrown: battle.isFinished &&
                        battle.winnerId == 'me',
                  ),
                ),

                // VS separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.purple.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Opponent
                Expanded(
                  child: _BattleSide(
                    name: battle.opponentName,
                    emoji: battle.opponentEmoji,
                    progress: battle.opponentProgress,
                    target: battle.targetCount,
                    progressPercent: battle.opponentProgressPercent,
                    color: const Color(0xFFE0605A),
                    isLeading: !isWinning && !isTied,
                    showCrown: battle.isFinished &&
                        battle.winnerId == 'opponent',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWinning
                    ? AppColors.success.withValues(alpha: 0.1)
                    : isTied
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : const Color(0xFFE0605A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                battle.isFinished
                    ? (battle.winnerId == 'me'
                        ? 'You won!'
                        : 'Better luck next time')
                    : isWinning
                        ? 'You\'re in the lead!'
                        : isTied
                            ? 'All tied up!'
                            : 'Pick up the pace!',
                style: TextStyle(
                  color: isWinning
                      ? AppColors.success
                      : isTied
                          ? AppColors.warning
                          : const Color(0xFFE0605A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleSide extends StatelessWidget {
  final String name;
  final String emoji;
  final int progress;
  final int target;
  final double progressPercent;
  final Color color;
  final bool isLeading;
  final bool showCrown;

  const _BattleSide({
    required this.name,
    required this.emoji,
    required this.progress,
    required this.target,
    required this.progressPercent,
    required this.color,
    required this.isLeading,
    required this.showCrown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Crown for winner
        if (showCrown)
          const Text(
            '\u{1F451}',
            style: TextStyle(fontSize: 20),
          )
        else
          const SizedBox(height: 24),

        const SizedBox(height: 4),

        // Progress circle
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _ProgressCirclePainter(
              progress: progressPercent,
              color: color,
              backgroundColor: AppColors.white.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Name
        Text(
          name,
          style: TextStyle(
            color: isLeading ? color : AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Progress count
        Text(
          '\$progress/\$target',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ProgressCirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressCirclePainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

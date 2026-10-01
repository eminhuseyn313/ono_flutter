import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Streak milestones and their celebration messages.
class StreakMilestone {
  final int days;
  final String emoji;
  final String title;
  final String subtitle;

  const StreakMilestone({
    required this.days,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

const _milestones = [
  StreakMilestone(
    days: 3,
    emoji: '🔥',
    title: '3-Day Fire!',
    subtitle: 'You\'re building momentum. Keep the flame alive.',
  ),
  StreakMilestone(
    days: 7,
    emoji: '⚡',
    title: 'One Week Strong!',
    subtitle: 'A full week of showing up. You\'re different now.',
  ),
  StreakMilestone(
    days: 14,
    emoji: '💎',
    title: 'Two-Week Diamond!',
    subtitle: 'Consistency is becoming your superpower.',
  ),
  StreakMilestone(
    days: 21,
    emoji: '🧬',
    title: 'Habit Formed!',
    subtitle: '21 days — science says this is who you are now.',
  ),
  StreakMilestone(
    days: 30,
    emoji: '👑',
    title: '30-Day King!',
    subtitle: 'A full month of discipline. Most people never get here.',
  ),
  StreakMilestone(
    days: 60,
    emoji: '🏔',
    title: '60-Day Summit!',
    subtitle: 'Two months of relentless growth. Legendary.',
  ),
  StreakMilestone(
    days: 100,
    emoji: '🏆',
    title: '100-Day Legend!',
    subtitle: 'Triple digits. You are built different.',
  ),
  StreakMilestone(
    days: 365,
    emoji: '🌟',
    title: 'One Year Titan!',
    subtitle: 'A full year of transformation. Unstoppable.',
  ),
];

/// Returns the milestone for the given streak, or null if not a milestone day.
StreakMilestone? getMilestone(int streak) {
  try {
    return _milestones.firstWhere((m) => m.days == streak);
  } catch (_) {
    return null;
  }
}

/// Shows a celebration dialog with confetti-like animation.
Future<void> showStreakCelebration(BuildContext context, StreakMilestone milestone) async {
  HapticFeedback.heavyImpact();
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => _CelebrationDialog(milestone: milestone),
    transitionBuilder: (_, animation, __, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class _CelebrationDialog extends StatefulWidget {
  final StreakMilestone milestone;
  const _CelebrationDialog({required this.milestone});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    final rng = Random();
    _particles = List.generate(30, (_) => _ConfettiParticle(rng));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) => CustomPaint(
              size: const Size(300, 400),
              painter: _ConfettiPainter(
                _particles,
                _confettiController.value,
              ),
            ),
          ),
          // Card
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.purple.withValues(alpha: 0.3),
                  AppColors.card,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.milestone.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.milestone.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.milestone.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Let\'s keep going',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -- Confetti particles -------------------------------------------------------

class _ConfettiParticle {
  final double x; // 0..1
  final double speed; // how fast it falls
  final double size;
  final double drift; // horizontal drift
  final Color color;

  _ConfettiParticle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.3 + rng.nextDouble() * 0.7,
        size = 4 + rng.nextDouble() * 6,
        drift = (rng.nextDouble() - 0.5) * 0.3,
        color = [
          AppColors.purple,
          AppColors.purpleSoft,
          AppColors.success,
          AppColors.warning,
          const Color(0xFFFF6B6B),
          const Color(0xFF48DBFB),
          const Color(0xFFFECA57),
        ][rng.nextInt(7)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = -20 + (size.height + 40) * progress * p.speed;
      final x = p.x * size.width + sin(progress * pi * 4 + p.x * 10) * 15 * p.drift;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 1.5),
          Radius.circular(p.size * 0.3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

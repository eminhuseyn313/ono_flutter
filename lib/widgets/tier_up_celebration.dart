import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/legacy_score.dart';
import '../theme/app_theme.dart';

/// Full-screen celebration overlay shown when a user's Legacy Score crosses
/// into a new [LegacyTier]. Includes a particle/confetti burst, a scale-in
/// reveal of the new tier's emoji and name, and a "Continue" dismiss action.
///
/// Usage: push via [showTierUpCelebration], or embed directly as a Stack
/// child gated by a boolean.
class TierUpCelebration extends StatefulWidget {
  final LegacyTier tier;
  final VoidCallback onContinue;

  const TierUpCelebration({
    super.key,
    required this.tier,
    required this.onContinue,
  });

  @override
  State<TierUpCelebration> createState() => _TierUpCelebrationState();
}

class _TierUpCelebrationState extends State<TierUpCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  late final AnimationController _particleController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final random = Random();
    final tierColor = widget.tier.color;
    _particles = List.generate(28, (i) {
      return _Particle(
        angle: random.nextDouble() * 2 * pi,
        distance: 120 + random.nextDouble() * 220,
        size: 4 + random.nextDouble() * 8,
        delay: random.nextDouble() * 0.3,
        color: [
          tierColor,
          AppColors.purpleSoft,
          AppColors.cyan,
          AppColors.warning,
        ][i % 4],
      );
    });

    HapticFeedback.heavyImpact();

    _fadeController.forward();
    _particleController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = widget.tier.color;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.black.withValues(alpha: 0.75),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow behind everything.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      tierColor.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Particle burst.
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // Main content card.
            ScaleTransition(
              scale: _scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.card.withValues(alpha: 0.95),
                          AppColors.cardLight.withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.35),
                          blurRadius: 50,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TIER UNLOCKED',
                          style: TextStyle(
                            color: tierColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.tier.emoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.tier.label,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.tier.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.95),
                            fontSize: 15,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tierColor,
                                  tierColor.withValues(alpha: 0.75),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: tierColor.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color: AppColors.white,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents [TierUpCelebration] as a full-screen dialog overlay.
Future<void> showTierUpCelebration(
  BuildContext context, {
  required LegacyTier tier,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return TierUpCelebration(
        tier: tier,
        onContinue: () => Navigator.of(context).pop(),
      );
    },
  );
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final Color color;

  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);

    for (final particle in particles) {
      final localProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final eased = Curves.easeOutCubic.transform(localProgress);
      final fade = (1 - localProgress).clamp(0.0, 1.0);
      final travel = particle.distance * eased;

      final dx = center.dx + cos(particle.angle) * travel;
      final dy = center.dy + sin(particle.angle) * travel + (eased * eased * 60);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: fade * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), particle.size * (1 - eased * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

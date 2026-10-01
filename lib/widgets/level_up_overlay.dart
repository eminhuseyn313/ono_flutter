import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/xp_system.dart';

/// Full-screen celebration overlay shown when the user reaches a new XP level.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => LevelUpOverlay(level: newLevel),
/// );
/// ```
class LevelUpOverlay extends StatefulWidget {
  final XpLevel level;
  const LevelUpOverlay({super.key, required this.level});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _burstController;
  late AnimationController _badgeController;
  late AnimationController _textController;

  late Animation<double> _burstScale;
  late Animation<double> _badgeFade;
  late Animation<double> _badgeScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    // Generate burst particles
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 80 + _random.nextDouble() * 200,
        size: 3 + _random.nextDouble() * 6,
        color: [
          AppColors.purple,
          AppColors.purpleSoft,
          AppColors.cyan,
          AppColors.green,
          const Color(0xFFF59E0B),
        ][_random.nextInt(5)],
      ));
    }

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _burstScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _burstController, curve: Curves.easeOutExpo),
    );

    _badgeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeOut),
    );
    _badgeScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Sequenced entrance
    _burstController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _badgeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _burstController.dispose();
    _badgeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particle burst
              AnimatedBuilder(
                animation: _burstController,
                builder: (_, __) {
                  return CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _burstScale.value,
                    ),
                  );
                },
              ),

              // Radial glow
              FadeTransition(
                opacity: _badgeFade,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.3),
                        AppColors.purple.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  FadeTransition(
                    opacity: _badgeFade,
                    child: ScaleTransition(
                      scale: _badgeScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF6D28D9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.level.emoji,
                            style: const TextStyle(fontSize: 52),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6)],
                            ).createShader(bounds),
                            child: const Text(
                              'LEVEL UP!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Level ${widget.level.level}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.level.title,
                            style: TextStyle(
                              color: AppColors.purpleSoft.withValues(alpha: 0.9),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: AppColors.grey.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final dist = p.speed * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      final offset = Offset(
        center.dx + cos(p.angle) * dist,
        center.dy + sin(p.angle) * dist,
      );
      canvas.drawCircle(offset, p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

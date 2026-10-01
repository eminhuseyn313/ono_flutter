import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// An animated in-app celebration banner that slides down from the top,
/// displays for 3 seconds, then slides back up.
///
/// Usage:
/// ```dart
/// CelebrationBanner.show(
///   context,
///   title: '7-Day Streak!',
///   subtitle: 'You showed up every single day.',
///   emoji: '🔥',
/// );
/// ```
class CelebrationBanner extends StatefulWidget {
  const CelebrationBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.gradientStart,
    this.gradientEnd,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final Color? gradientStart;
  final Color? gradientEnd;
  final VoidCallback onDismiss;

  /// Shows the celebration banner as an overlay on top of the current screen.
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => CelebrationBanner(
        title: title,
        subtitle: subtitle,
        emoji: emoji,
        gradientStart: gradientStart,
        gradientEnd: gradientEnd,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<CelebrationBanner> createState() => _CelebrationBannerState();
}

class _CelebrationBannerState extends State<CelebrationBanner>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  late final AnimationController _particleController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation with bounce.
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Scale animation.
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Particle sparkle loop.
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _enter();
  }

  Future<void> _enter() async {
    HapticFeedback.mediumImpact();
    _slideController.forward();
    _scaleController.forward();

    // Auto-dismiss after 3 seconds.
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _exit();
  }

  Future<void> _exit() async {
    await _slideController.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final gradientStart = widget.gradientStart ?? AppColors.purple;
    final gradientEnd = widget.gradientEnd ?? AppColors.cyan;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -200) _exit();
            },
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 8,
                left: 16,
                right: 16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        foregroundPainter: _SparklePainter(
                          progress: _particleController.value,
                          color: AppColors.white,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gradientStart.withValues(alpha: 0.85),
                            gradientEnd.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: AppColors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints subtle sparkle particles over the banner surface.
class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for deterministic positions.
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Each particle has its own phase offset.
      final phase = (progress + i * 0.08) % 1.0;
      final opacity = (sin(phase * pi * 2) * 0.5 + 0.5) * 0.6;
      final radius = 1.2 + sin(phase * pi * 2) * 0.8;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(baseX, baseY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

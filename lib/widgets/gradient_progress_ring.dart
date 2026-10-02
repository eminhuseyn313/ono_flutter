import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated circular progress ring with gradient stroke and optional pulse on completion.
class GradientProgressRing extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final double radius;
  final double strokeWidth;
  final Widget? center;
  final Duration animationDuration;
  final List<Color>? gradientColors;

  const GradientProgressRing({
    super.key,
    required this.progress,
    this.radius = 48,
    this.strokeWidth = 8,
    this.center,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.gradientColors,
  });

  @override
  State<GradientProgressRing> createState() => _GradientProgressRingState();
}

class _GradientProgressRingState extends State<GradientProgressRing>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Pulse for 100% completion
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    _progressController.forward();

    if (widget.progress >= 1.0) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(GradientProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _oldProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _oldProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController
        ..reset()
        ..forward();

      if (widget.progress >= 1.0 && _pulseController == null) {
        _startPulse();
      } else if (widget.progress < 1.0) {
        _stopPulse();
      }
    }
  }

  void _startPulse() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _pulseController!.repeat(reverse: true);
  }

  void _stopPulse() {
    _pulseController?.dispose();
    _pulseController = null;
    _pulseAnimation = null;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget ring = AnimatedBuilder(
      animation: _progressController,
      builder: (_, __) {
        return CustomPaint(
          size: Size.square(widget.radius * 2),
          painter: _GradientRingPainter(
            progress: _progressAnimation.value,
            strokeWidth: widget.strokeWidth,
            gradientColors: widget.gradientColors ??
                const [
                  Color(0xFFA86D35),
                  Color(0xFFC8894A),
                  Color(0xFFE8C9A3),
                ],
            trackColor: AppColors.divider,
          ),
          child: SizedBox(
            width: widget.radius * 2,
            height: widget.radius * 2,
            child: Center(child: widget.center),
          ),
        );
      },
    );

    // Wrap with pulse if at 100%
    if (_pulseAnimation != null) {
      ring = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnimation!.value,
          child: child,
        ),
        child: ring,
      );
    }

    return ring;
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;

  _GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: gradientColors,
      // Avoid tileMode issues by distributing stops within the sweep
      stops: List.generate(
        gradientColors.length,
        (i) => i / (gradientColors.length - 1),
      ),
      transform: const GradientRotation(-math.pi / 2),
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);

    // Glow dot at the tip
    if (progress > 0.05) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final glowPaint = Paint()
        ..color = gradientColors.last.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) =>
      old.progress != progress;
}

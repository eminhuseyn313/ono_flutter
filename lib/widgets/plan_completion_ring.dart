import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/planner.dart';
import '../theme/app_theme.dart';

class PlanCompletionRing extends StatefulWidget {
  final double completionRate;
  final int completedCount;
  final int totalCount;
  final Map<TimeBlock, double> blockCompletions;
  final double size;

  const PlanCompletionRing({
    super.key,
    required this.completionRate,
    required this.completedCount,
    required this.totalCount,
    this.blockCompletions = const {},
    this.size = 120,
  });

  @override
  State<PlanCompletionRing> createState() => _PlanCompletionRingState();
}

class _PlanCompletionRingState extends State<PlanCompletionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousRate = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.completionRate,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(PlanCompletionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completionRate != widget.completionRate) {
      _previousRate = oldWidget.completionRate;
      _progressAnimation = Tween<double>(
        begin: _previousRate,
        end: widget.completionRate,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _CompletionRingPainter(
                  progress: _progressAnimation.value,
                  strokeWidth: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.completedCount}/${widget.totalCount}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.blockCompletions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildBlockBreakdown(),
        ],
      ],
    );
  }

  Widget _buildBlockBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TimeBlock.values.map((block) {
        final completion = widget.blockCompletions[block] ?? 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Text(
                block.emoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 32,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: completion,
                    backgroundColor: AppColors.card,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _blockColor(completion),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(completion * 100).round()}%',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _blockColor(double completion) {
    if (completion >= 0.8) return const Color(0xFF34D399);
    if (completion >= 0.5) return const Color(0xFF22D3EE);
    if (completion > 0) return const Color(0xFFF59E0B);
    return AppColors.grey;
  }
}

class _CompletionRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _CompletionRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF202B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFF8B5CF6),
        Color(0xFF22D3EE),
        Color(0xFF34D399),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, strokeWidth / 2 + 1, dotPaint);
  }

  @override
  bool shouldRepaint(_CompletionRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

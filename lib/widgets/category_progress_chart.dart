import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vision_board.dart';
import '../theme/app_theme.dart';

class CategoryProgressChart extends StatefulWidget {
  final Map<VisionCategory, double> categoryProgress;
  final double size;

  const CategoryProgressChart({
    super.key,
    required this.categoryProgress,
    this.size = 260,
  });

  @override
  State<CategoryProgressChart> createState() => _CategoryProgressChartState();
}

class _CategoryProgressChartState extends State<CategoryProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryProgress != widget.categoryProgress) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Category Progress',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _RadarChartPainter(
                  categoryProgress: widget.categoryProgress,
                  animationValue: _animation.value,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    final categories = VisionCategory.values;

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: categories.map((category) {
        final progress = widget.categoryProgress[category] ?? 0.0;
        final percentage = (progress * 100).round();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(category.colorValue),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${category.emoji} ${category.label}',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$percentage%',
              style: TextStyle(
                color: Color(category.colorValue),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<VisionCategory, double> categoryProgress;
  final double animationValue;

  _RadarChartPainter({
    required this.categoryProgress,
    required this.animationValue,
  });

  static const int _sides = 5;
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    final categories = VisionCategory.values;

    _drawGridLines(canvas, center, radius);
    _drawAxes(canvas, center, radius);
    _drawProgressPolygon(canvas, center, radius, categories);
    _drawLabels(canvas, center, radius, categories, size);
    _drawDataPoints(canvas, center, radius, categories);
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final path = Path();

      for (int i = 0; i <= _sides; i++) {
        final angle = _startAngle + (2 * math.pi / _sides) * i;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius) {
    final axisPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < _sides; i++) {
      final angle = _startAngle + (2 * math.pi / _sides) * i;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);
    }
  }

  void _drawProgressPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    List<VisionCategory> categories,
  ) {
    final fillPath = Path();
    final strokePath = Path();

    for (int i = 0; i <= _sides; i++) {
      final index = i % _sides;
      final category = categories[index];
      final progress = (categoryProgress[category] ?? 0.0) * animationValue;
      final angle = _startAngle + (2 * math.pi / _sides) * i;
      final pointRadius = radius * progress;

      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      if (i == 0) {
        fillPath.moveTo(x, y);
        strokePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        strokePath.lineTo(x, y);
      }
    }

    fillPath.close();
    strokePath.close();

    final fillPaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, strokePaint);
  }

  void _drawDataPoints(
    Canvas canvas,
    Offset center,
    double radius,
    List<VisionCategory> categories,
  ) {
    for (int i = 0; i < _sides; i++) {
      final category = categories[i];
      final progress = (categoryProgress[category] ?? 0.0) * animationValue;
      final angle = _startAngle + (2 * math.pi / _sides) * i;
      final pointRadius = radius * progress;

      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      final dotColor = Color(category.colorValue);

      final outerPaint = Paint()
        ..color = dotColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 6, outerPaint);

      final innerPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3.5, innerPaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double radius,
    List<VisionCategory> categories,
    Size size,
  ) {
    for (int i = 0; i < _sides; i++) {
      final category = categories[i];
      final angle = _startAngle + (2 * math.pi / _sides) * i;
      final labelRadius = radius + 24;

      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: category.emoji,
          style: const TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.categoryProgress != categoryProgress;
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ono/theme/app_theme.dart';

class LaneProjectionCard extends StatelessWidget {
  final String laneEmoji;
  final String laneName;
  final Color laneColor;
  final double currentScore;
  final List<double> sparklineData;
  final double animationValue;

  const LaneProjectionCard({
    super.key,
    required this.laneEmoji,
    required this.laneName,
    required this.laneColor,
    required this.currentScore,
    required this.sparklineData,
    this.animationValue = 1.0,
  });

  double _project(double score, int days) {
    final dailyRate = score / 10000;
    return math.min(math.pow(1 + dailyRate, days).toDouble() * score, 100);
  }

  @override
  Widget build(BuildContext context) {
    final proj30 = _project(currentScore, 30);
    final proj90 = _project(currentScore, 90);
    final proj365 = _project(currentScore, 365);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: laneColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: laneColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      laneEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        laneName,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Current score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: laneColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(currentScore * animationValue).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: laneColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sparkline
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      data: sparklineData,
                      color: laneColor,
                      animationValue: animationValue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Projections row
                Row(
                  children: [
                    _ProjectionChip(
                      label: '30d',
                      value: proj30,
                      color: laneColor,
                      animationValue: animationValue,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                    _ProjectionChip(
                      label: '90d',
                      value: proj90,
                      color: laneColor,
                      animationValue: animationValue,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                    _ProjectionChip(
                      label: '1yr',
                      value: proj365,
                      color: laneColor,
                      animationValue: animationValue,
                      highlighted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectionChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double animationValue;
  final bool highlighted;

  const _ProjectionChip({
    required this.label,
    required this.value,
    required this.color,
    required this.animationValue,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value * animationValue).clamp(0, 100);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withValues(alpha: 0.12)
              : AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: highlighted
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayValue.toStringAsFixed(0),
              style: TextStyle(
                color: highlighted ? color : AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double animationValue;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final effectiveData = data.length > 1 ? data : [data.first, data.first];
    final maxVal = effectiveData.reduce(math.max).clamp(1.0, double.infinity);
    final minVal = effectiveData.reduce(math.min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final path = Path();
    final fillPath = Path();
    final pointCount = effectiveData.length;
    final stepX = size.width / (pointCount - 1);

    for (int i = 0; i < pointCount; i++) {
      final x = i * stepX;
      final normalizedY = (effectiveData[i] - minVal) / range;
      final y = size.height - normalizedY * size.height * 0.85 - size.height * 0.05;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve using cubic bezier
        final prevX = (i - 1) * stepX;
        final prevNormY = (effectiveData[i - 1] - minVal) / range;
        final prevY = size.height - prevNormY * size.height * 0.85 - size.height * 0.05;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Clip to animation progress
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * animationValue, size.height));

    // Fill gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Endpoint dot
    if (animationValue >= 0.95 && effectiveData.isNotEmpty) {
      final lastX = (pointCount - 1) * stepX;
      final lastNormY = (effectiveData.last - minVal) / range;
      final lastY = size.height - lastNormY * size.height * 0.85 - size.height * 0.05;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 3, dotPaint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 6, glowPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/analytics.dart';
import '../theme/app_theme.dart';

enum TrendDirection { up, down, neutral }

class StatChartCard extends StatelessWidget {
  final String title;
  final String value;
  final TrendDirection trend;
  final List<DataPoint> dataPoints;
  final Color color;

  const StatChartCard({
    super.key,
    required this.title,
    required this.value,
    this.trend = TrendDirection.neutral,
    this.dataPoints = const [],
    this.color = AppColors.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
              ),
              _buildTrendIcon(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          if (dataPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _SparklinePainter(
                  dataPoints: dataPoints,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIcon() {
    switch (trend) {
      case TrendDirection.up:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, size: 14, color: AppColors.success),
          ],
        );
      case TrendDirection.down:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward, size: 14, color: const Color(0xFFE0605A)),
          ],
        );
      case TrendDirection.neutral:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove, size: 14, color: AppColors.grey),
          ],
        );
    }
  }
}

class _SparklinePainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final Color color;

  _SparklinePainter({
    required this.dataPoints,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final values = dataPoints.map((dp) => dp.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final effectiveRange = range == 0 ? 1.0 : range;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / effectiveRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw end dot
    if (values.isNotEmpty) {
      final lastX = size.width;
      final lastY = size.height -
          ((values.last - minVal) / effectiveRange) * size.height;
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.color != color;
  }
}

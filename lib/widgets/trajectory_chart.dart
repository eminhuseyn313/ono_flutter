import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mirror_match.dart';
import '../theme/app_theme.dart';

/// Draws overlaid line charts of "my" trajectory vs the mirror's trajectory
/// so the user can see proof that transformation works.
class TrajectoryChart extends StatelessWidget {
  final List<TrajectoryPoint> myPoints;
  final List<TrajectoryPoint> mirrorPoints;
  final double height;

  const TrajectoryChart({
    super.key,
    required this.myPoints,
    required this.mirrorPoints,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrajectoryPainter(
          myPoints: myPoints,
          mirrorPoints: mirrorPoints,
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  final List<TrajectoryPoint> myPoints;
  final List<TrajectoryPoint> mirrorPoints;

  _TrajectoryPainter({
    required this.myPoints,
    required this.mirrorPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (myPoints.isEmpty && mirrorPoints.isEmpty) return;

    final allPoints = [...myPoints, ...mirrorPoints];
    final maxDay = allPoints
        .map((p) => p.dayNumber)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxScore = allPoints
        .map((p) => p.overallScore)
        .reduce((a, b) => a > b ? a : b);
    final minScore = allPoints
        .map((p) => p.overallScore)
        .reduce((a, b) => a < b ? a : b);
    final scoreRange = (maxScore - minScore).clamp(0.1, double.infinity);

    const padding = EdgeInsets.only(left: 36, right: 16, top: 16, bottom: 28);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    Offset toPixel(TrajectoryPoint p) {
      final x = padding.left + (p.dayNumber / maxDay) * chartW;
      final y = padding.top +
          chartH -
          ((p.overallScore - minScore) / scoreRange) * chartH;
      return Offset(x, y);
    }

    // ── Grid lines ──
    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = padding.top + (chartH / 4) * i;
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
    }

    // ── Axis labels ──
    final labelStyle = TextStyle(
      color: AppColors.grey.withValues(alpha: 0.6),
      fontSize: 10,
    );

    // Y-axis labels
    for (var i = 0; i <= 4; i++) {
      final score = minScore + (scoreRange / 4) * (4 - i);
      final y = padding.top + (chartH / 4) * i;
      final tp = TextPainter(
        text: TextSpan(text: score.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding.left - tp.width - 4, y - tp.height / 2));
    }

    // X-axis labels
    final dayStep = (maxDay / 4).ceil();
    for (var d = 0; d <= maxDay; d += dayStep) {
      final x = padding.left + (d / maxDay) * chartW;
      final tp = TextPainter(
        text: TextSpan(text: 'D$d', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(x - tp.width / 2, size.height - padding.bottom + 8));
    }

    // ── Mirror line (full trajectory, dashed cyan) ──
    if (mirrorPoints.length >= 2) {
      _drawLine(
        canvas,
        mirrorPoints.map(toPixel).toList(),
        AppColors.cyan.withValues(alpha: 0.7),
        dashed: true,
      );

      // Fill area under mirror line
      _drawFill(
        canvas,
        mirrorPoints.map(toPixel).toList(),
        AppColors.cyan.withValues(alpha: 0.06),
        padding.top + chartH,
      );
    }

    // ── My line (solid purple) ──
    if (myPoints.length >= 2) {
      _drawLine(
        canvas,
        myPoints.map(toPixel).toList(),
        AppColors.purple,
        dashed: false,
      );

      // Fill area under my line
      _drawFill(
        canvas,
        myPoints.map(toPixel).toList(),
        AppColors.purple.withValues(alpha: 0.1),
        padding.top + chartH,
      );

      // Current position dot
      final last = toPixel(myPoints.last);
      canvas.drawCircle(last, 5, Paint()..color = AppColors.purple);
      canvas.drawCircle(
        last,
        3,
        Paint()..color = AppColors.white,
      );
    }

    // ── Legend ──
    final legendY = size.height - 6;
    _drawLegendDot(canvas, Offset(padding.left, legendY), AppColors.purple,
        'You', false);
    _drawLegendDot(canvas, Offset(padding.left + 60, legendY), AppColors.cyan,
        'Mirror', true);
  }

  void _drawLine(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    required bool dashed,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    } else {
      // Dashed line
      const dashLen = 6.0;
      const gapLen = 4.0;
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final dx = p1.dx - p0.dx;
        final dy = p1.dy - p0.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        final nx = dx / dist;
        final ny = dy / dist;

        var drawn = 0.0;
        var isDash = true;
        while (drawn < dist) {
          final seg = isDash ? dashLen : gapLen;
          final end = math.min(drawn + seg, dist);
          if (isDash) {
            canvas.drawLine(
              Offset(p0.dx + nx * drawn, p0.dy + ny * drawn),
              Offset(p0.dx + nx * end, p0.dy + ny * end),
              paint,
            );
          }
          drawn = end;
          isDash = !isDash;
        }
      }
    }
  }

  void _drawFill(
      Canvas canvas, List<Offset> points, Color color, double baseline) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, baseline);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, baseline);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawLegendDot(
      Canvas canvas, Offset pos, Color color, String label, bool dashed) {
    canvas.drawCircle(pos, 4, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: AppColors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx + 8, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) =>
      old.myPoints != myPoints || old.mirrorPoints != mirrorPoints;
}

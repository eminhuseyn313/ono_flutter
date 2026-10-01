import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ono/theme/app_theme.dart';

class CompoundChart extends StatefulWidget {
  final int currentDay;
  final double dailyRate;
  final double animationValue;
  final ValueChanged<int>? onDaySelected;

  const CompoundChart({
    super.key,
    required this.currentDay,
    required this.dailyRate,
    this.animationValue = 1.0,
    this.onDaySelected,
  });

  @override
  State<CompoundChart> createState() => _CompoundChartState();
}

class _CompoundChartState extends State<CompoundChart> {
  int? _touchedDay;
  double? _touchX;
  double? _touchY;

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final chartArea = _chartArea(constraints);
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;

    if (localX >= chartArea.left && localX <= chartArea.right) {
      final fraction = (localX - chartArea.left) / chartArea.width;
      final day = (fraction * 365).round().clamp(0, 365);
      setState(() {
        _touchedDay = day;
        _touchX = localX;
        _touchY = localY;
      });
      HapticFeedback.selectionClick();
      widget.onDaySelected?.call(day);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _touchedDay = null;
      _touchX = null;
      _touchY = null;
    });
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) {
    final chartArea = _chartArea(constraints);
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;

    if (localX >= chartArea.left && localX <= chartArea.right) {
      final fraction = (localX - chartArea.left) / chartArea.width;
      final day = (fraction * 365).round().clamp(0, 365);
      setState(() {
        _touchedDay = day;
        _touchX = localX;
        _touchY = localY;
      });
      HapticFeedback.lightImpact();
      widget.onDaySelected?.call(day);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _touchedDay = null;
            _touchX = null;
            _touchY = null;
          });
        }
      });
    }
  }

  Rect _chartArea(BoxConstraints constraints) {
    const leftPadding = 52.0;
    const rightPadding = 16.0;
    const topPadding = 16.0;
    const bottomPadding = 40.0;
    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      constraints.maxWidth - rightPadding,
      constraints.maxHeight - bottomPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (d) => _handlePanUpdate(d, constraints),
          onPanEnd: _handlePanEnd,
          onTapUp: (d) => _handleTapUp(d, constraints),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CompoundChartPainter(
              currentDay: widget.currentDay,
              dailyRate: widget.dailyRate,
              animationValue: widget.animationValue,
              touchedDay: _touchedDay,
              touchX: _touchX,
              touchY: _touchY,
            ),
          ),
        );
      },
    );
  }
}

class _CompoundChartPainter extends CustomPainter {
  final int currentDay;
  final double dailyRate;
  final double animationValue;
  final int? touchedDay;
  final double? touchX;
  final double? touchY;

  static const _leftPadding = 52.0;
  static const _rightPadding = 16.0;
  static const _topPadding = 16.0;
  static const _bottomPadding = 40.0;

  _CompoundChartPainter({
    required this.currentDay,
    required this.dailyRate,
    required this.animationValue,
    this.touchedDay,
    this.touchX,
    this.touchY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTRB(
      _leftPadding,
      _topPadding,
      size.width - _rightPadding,
      size.height - _bottomPadding,
    );

    final maxMultiplier = math.pow(1 + dailyRate, 365).toDouble();
    final yMax = (maxMultiplier * 1.15).ceilToDouble();

    _drawGrid(canvas, chartRect, yMax);
    _drawAxes(canvas, chartRect, yMax);
    _drawLinearLine(canvas, chartRect, yMax);
    _drawCompoundCurve(canvas, chartRect, yMax);
    _drawYouAreHereMarker(canvas, chartRect, yMax);
    if (touchedDay != null && touchX != null) {
      _drawTooltip(canvas, chartRect, yMax, size);
    }
  }

  void _drawGrid(Canvas canvas, Rect chart, double yMax) {
    final gridPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    final ySteps = _calcYSteps(yMax);
    for (final yVal in ySteps) {
      final y = _mapY(yVal, chart, yMax);
      _drawDashedLine(
        canvas,
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
        dashWidth: 4,
        gapWidth: 4,
      );
    }

    // Vertical grid lines at key day marks
    for (final day in [30, 90, 180, 365]) {
      final x = _mapX(day.toDouble(), chart);
      _drawDashedLine(
        canvas,
        Offset(x, chart.top),
        Offset(x, chart.bottom),
        gridPaint,
        dashWidth: 4,
        gapWidth: 4,
      );
    }
  }

  List<double> _calcYSteps(double yMax) {
    final steps = <double>[];
    double step;
    if (yMax <= 5) {
      step = 1;
    } else if (yMax <= 20) {
      step = 5;
    } else if (yMax <= 50) {
      step = 10;
    } else {
      step = (yMax / 5).ceilToDouble();
    }
    for (double v = step; v < yMax; v += step) {
      steps.add(v);
    }
    return steps;
  }

  void _drawAxes(Canvas canvas, Rect chart, double yMax) {
    final textStyle = ui.TextStyle(
      color: AppColors.grey,
      fontSize: 10,
      fontFamily: 'Inter',
    );

    // Y axis labels
    final ySteps = _calcYSteps(yMax);
    // Always show 1x baseline
    _drawYLabel(canvas, chart, yMax, 1, '1x', textStyle);
    for (final yVal in ySteps) {
      _drawYLabel(canvas, chart, yMax, yVal, '${yVal.toStringAsFixed(yVal == yVal.roundToDouble() ? 0 : 1)}x', textStyle);
    }

    // X axis labels
    for (final entry in {0: '0', 30: '30d', 90: '90d', 180: '6mo', 365: '1yr'}.entries) {
      final x = _mapX(entry.key.toDouble(), chart);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 10,
      ))
        ..pushStyle(textStyle)
        ..addText(entry.value);
      final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 40));
      canvas.drawParagraph(paragraph, Offset(x - 20, chart.bottom + 8));
    }
  }

  void _drawYLabel(Canvas canvas, Rect chart, double yMax, double value, String label, ui.TextStyle style) {
    final y = _mapY(value, chart, yMax);
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.right,
      fontSize: 10,
    ))
      ..pushStyle(style)
      ..addText(label);
    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 44));
    canvas.drawParagraph(paragraph, Offset(0, y - 7));
  }

  void _drawLinearLine(Canvas canvas, Rect chart, double yMax) {
    final linearPaint = Paint()
      ..color = AppColors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final linearEnd = 1 + dailyRate * 365;
    final path = Path();
    final totalPoints = (365 * animationValue).round();

    for (int day = 0; day <= totalPoints; day++) {
      final value = 1 + dailyRate * day;
      final x = _mapX(day.toDouble(), chart);
      final y = _mapY(value, chart, yMax);
      if (day == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    _drawDashedPath(canvas, path, linearPaint, dashWidth: 6, gapWidth: 4);
  }

  void _drawCompoundCurve(Canvas canvas, Rect chart, double yMax) {
    final totalPoints = (365 * animationValue).round();
    if (totalPoints < 1) return;

    final path = Path();
    final glowPath = Path();
    final points = <Offset>[];

    for (int day = 0; day <= totalPoints; day++) {
      final value = math.pow(1 + dailyRate, day).toDouble();
      final x = _mapX(day.toDouble(), chart);
      final y = _mapY(value, chart, yMax);
      points.add(Offset(x, y));
      if (day == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    // Glow effect
    final glowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chart.left, 0),
        Offset(chart.right, 0),
        [
          AppColors.purpleSoft.withValues(alpha: 0.3),
          AppColors.purple.withValues(alpha: 0.3),
        ],
      )
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(glowPath, glowPaint);

    // Fill area under curve
    if (points.isNotEmpty) {
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, chart.bottom);
      fillPath.lineTo(chart.left, chart.bottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chart.top),
          Offset(0, chart.bottom),
          [
            AppColors.purpleSoft.withValues(alpha: 0.12),
            AppColors.purple.withValues(alpha: 0.02),
          ],
        );
      canvas.drawPath(fillPath, fillPaint);
    }

    // Main curve stroke
    final curvePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chart.left, 0),
        Offset(chart.right, 0),
        [AppColors.purpleSoft, AppColors.purple],
      )
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, curvePaint);
  }

  void _drawYouAreHereMarker(Canvas canvas, Rect chart, double yMax) {
    if (currentDay <= 0 || currentDay > 365 * animationValue) return;

    final value = math.pow(1 + dailyRate, currentDay).toDouble();
    final x = _mapX(currentDay.toDouble(), chart);
    final y = _mapY(value, chart, yMax);

    // Vertical line
    final linePaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    _drawDashedLine(
      canvas,
      Offset(x, chart.top),
      Offset(x, chart.bottom),
      linePaint,
      dashWidth: 4,
      gapWidth: 3,
    );

    // Outer pulse ring
    final pulseRadius = 12.0 + 4.0 * math.sin(animationValue * math.pi * 4);
    final pulsePaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pulseRadius, pulsePaint);

    // Middle ring
    final midPaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 7, midPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = AppColors.purple
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 4, dotPaint);

    // White center
    final centerPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 1.5, centerPaint);

    // "You are here" label
    final labelStyle = ui.TextStyle(
      color: AppColors.purpleSoft,
      fontSize: 9,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    );
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 9,
    ))
      ..pushStyle(labelStyle)
      ..addText('YOU ARE HERE');
    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 80));

    final labelX = x - 40;
    final labelY = y - 26;
    canvas.drawParagraph(paragraph, Offset(labelX, labelY));
  }

  void _drawTooltip(Canvas canvas, Rect chart, double yMax, Size size) {
    if (touchedDay == null || touchX == null) return;

    final compoundValue = math.pow(1 + dailyRate, touchedDay!).toDouble();
    final linearValue = 1 + dailyRate * touchedDay!;
    final x = _mapX(touchedDay!.toDouble(), chart);
    final y = _mapY(compoundValue, chart, yMax);

    // Vertical highlight line
    final highlightPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), highlightPaint);

    // Dot on curve
    final dotPaint = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 5, dotPaint);
    final dotBorder = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(x, y), 5, dotBorder);

    // Tooltip box
    final tooltipText = 'Day ${touchedDay!}\n${compoundValue.toStringAsFixed(2)}x compound\n${linearValue.toStringAsFixed(2)}x linear';
    final tooltipStyle = ui.TextStyle(
      color: AppColors.white,
      fontSize: 11,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );
    final tooltipBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 11,
      maxLines: 3,
    ))
      ..pushStyle(tooltipStyle)
      ..addText(tooltipText);
    final paragraph = tooltipBuilder.build()..layout(const ui.ParagraphConstraints(width: 130));

    final tooltipWidth = 142.0;
    final tooltipHeight = paragraph.height + 16;
    var tooltipX = x - tooltipWidth / 2;
    var tooltipY = y - tooltipHeight - 16;

    // Keep tooltip in bounds
    if (tooltipX < chart.left) tooltipX = chart.left;
    if (tooltipX + tooltipWidth > chart.right) tooltipX = chart.right - tooltipWidth;
    if (tooltipY < chart.top) tooltipY = y + 16;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(8),
    );

    // Tooltip background
    final bgPaint = Paint()..color = AppColors.cardLight.withValues(alpha: 0.95);
    canvas.drawRRect(tooltipRect, bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(tooltipRect, borderPaint);

    canvas.drawParagraph(paragraph, Offset(tooltipX + 8, tooltipY + 8));
  }

  double _mapX(double day, Rect chart) {
    return chart.left + (day / 365) * chart.width;
  }

  double _mapY(double value, Rect chart, double yMax) {
    final fraction = (value - 1) / (yMax - 1);
    return chart.bottom - fraction * chart.height;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 3,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    double dist = 0;
    bool drawing = true;
    while (dist < length) {
      final segLen = drawing ? dashWidth : gapWidth;
      final clamped = math.min(dist + segLen, length);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * dist, start.dy + unitY * dist),
          Offset(start.dx + unitX * clamped, start.dy + unitY * clamped),
          paint,
        );
      }
      dist = clamped;
      drawing = !drawing;
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 3,
  }) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool drawing = true;
      while (dist < metric.length) {
        final segLen = drawing ? dashWidth : gapWidth;
        final end = math.min(dist + segLen, metric.length);
        if (drawing) {
          final extracted = metric.extractPath(dist, end);
          canvas.drawPath(extracted, paint);
        }
        dist = end;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompoundChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.touchedDay != touchedDay ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.dailyRate != dailyRate;
  }
}

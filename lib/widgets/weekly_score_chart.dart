import 'package:flutter/material.dart';

import '../models/power_rankings.dart';
import '../theme/app_theme.dart';

class WeeklyScoreChart extends StatefulWidget {
  final List<RankingHistory> history;
  final int? highlightWeekIndex;

  const WeeklyScoreChart({
    super.key,
    required this.history,
    this.highlightWeekIndex,
  });

  @override
  State<WeeklyScoreChart> createState() => _WeeklyScoreChartState();
}

class _WeeklyScoreChartState extends State<WeeklyScoreChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: AppColors.purple,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Score Trend',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(
                    history: widget.history,
                    animationValue: _animation.value,
                    highlightIndex: widget.highlightWeekIndex,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildTierLegend(),
        ],
      ),
    );
  }

  Widget _buildTierLegend() {
    final tiers = [
      (PerformanceTier.elite, '85+'),
      (PerformanceTier.strong, '70+'),
      (PerformanceTier.growing, '50+'),
      (PerformanceTier.needsWork, '30+'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tiers.map((tier) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tier.$1.color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${tier.$1.displayName} ${tier.$2}',
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RankingHistory> history;
  final double animationValue;
  final int? highlightIndex;

  _ChartPainter({
    required this.history,
    required this.animationValue,
    this.highlightIndex,
  });

  static const double _leftPadding = 30;
  static const double _rightPadding = 10;
  static const double _topPadding = 10;
  static const double _bottomPadding = 24;
  static const double _minScore = 0;
  static const double _maxScore = 100;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _topPadding - _bottomPadding;

    _drawTierThresholds(canvas, size, chartWidth, chartHeight);
    _drawYAxisLabels(canvas, size, chartHeight);
    _drawGradientFill(canvas, size, chartWidth, chartHeight);
    _drawLine(canvas, size, chartWidth, chartHeight);
    _drawDots(canvas, size, chartWidth, chartHeight);
    _drawWeekLabels(canvas, size, chartWidth, chartHeight);
  }

  double _scoreToY(double score, double chartHeight) {
    return _topPadding +
        chartHeight * (1 - (score - _minScore) / (_maxScore - _minScore));
  }

  double _indexToX(int index, double chartWidth) {
    if (history.length == 1) return _leftPadding + chartWidth / 2;
    return _leftPadding + (index / (history.length - 1)) * chartWidth;
  }

  void _drawTierThresholds(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final thresholds = [
      (85.0, const Color(0xFFC8894A)),
      (70.0, const Color(0xFF7DB495)),
      (50.0, const Color(0xFF7C9CC4)),
      (30.0, const Color(0xFFE2B354)),
    ];

    for (final threshold in thresholds) {
      final y = _scoreToY(threshold.$1, chartHeight);
      final paint = Paint()
        ..color = threshold.$2.withValues(alpha: 0.12)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final path = Path();
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      var startX = _leftPadding;

      while (startX < _leftPadding + chartWidth) {
        path.moveTo(startX, y);
        path.lineTo(
            (startX + dashWidth).clamp(0, _leftPadding + chartWidth), y);
        startX += dashWidth + dashSpace;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawYAxisLabels(Canvas canvas, Size size, double chartHeight) {
    final labels = [0, 25, 50, 75, 100];
    for (final label in labels) {
      final y = _scoreToY(label.toDouble(), chartHeight);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$label',
          style: TextStyle(
            color: const Color(0xFF8E8A82).withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas, Offset(_leftPadding - textPainter.width - 6, y - 6));
    }
  }

  void _drawGradientFill(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    if (history.length < 2) return;

    final animatedCount = (history.length * animationValue).ceil();
    if (animatedCount < 2) return;

    final path = Path();
    final bottomY = _scoreToY(_minScore, chartHeight);

    path.moveTo(_indexToX(0, chartWidth), bottomY);

    for (var i = 0; i < animatedCount; i++) {
      final x = _indexToX(i, chartWidth);
      final y = _scoreToY(history[i].overallScore.toDouble(), chartHeight);
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = _indexToX(i - 1, chartWidth);
        final controlX = (prevX + x) / 2;
        final prevY =
            _scoreToY(history[i - 1].overallScore.toDouble(), chartHeight);
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    path.lineTo(_indexToX(animatedCount - 1, chartWidth), bottomY);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFC8894A).withValues(alpha: 0.25 * animationValue),
        const Color(0xFFC8894A).withValues(alpha: 0.0),
      ],
    );

    final rect = Rect.fromLTWH(
        _leftPadding, _topPadding, chartWidth, chartHeight);
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  void _drawLine(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    if (history.length < 2) return;

    final animatedCount = (history.length * animationValue).ceil();
    if (animatedCount < 2) return;

    final path = Path();

    for (var i = 0; i < animatedCount; i++) {
      final x = _indexToX(i, chartWidth);
      final y = _scoreToY(history[i].overallScore.toDouble(), chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = _indexToX(i - 1, chartWidth);
        final controlX = (prevX + x) / 2;
        final prevY =
            _scoreToY(history[i - 1].overallScore.toDouble(), chartHeight);
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    final paint = Paint()
      ..color = const Color(0xFFC8894A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawDots(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final animatedCount = (history.length * animationValue).ceil();

    for (var i = 0; i < animatedCount; i++) {
      final x = _indexToX(i, chartWidth);
      final y = _scoreToY(history[i].overallScore.toDouble(), chartHeight);
      final isHighlighted =
          highlightIndex != null ? i == highlightIndex : i == history.length - 1;

      if (isHighlighted) {
        final glowPaint = Paint()
          ..color = const Color(0xFFC8894A).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 8, glowPaint);
      }

      final dotPaint = Paint()
        ..color =
            isHighlighted ? const Color(0xFFC8894A) : const Color(0xFFE8C9A3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), isHighlighted ? 5 : 3, dotPaint);

      if (isHighlighted || i % 3 == 0 || history.length <= 6) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${history[i].overallScore}',
            style: TextStyle(
              color: isHighlighted
                  ? const Color(0xFFF3EFE7)
                  : const Color(0xFF8E8A82).withValues(alpha: 0.7),
              fontSize: isHighlighted ? 11 : 9,
              fontWeight:
                  isHighlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, y - 18));
      }
    }
  }

  void _drawWeekLabels(
      Canvas canvas, Size size, double chartWidth, double chartHeight) {
    final animatedCount = (history.length * animationValue).ceil();
    final bottomY = _scoreToY(_minScore, chartHeight) + 8;

    for (var i = 0; i < animatedCount; i++) {
      if (history.length > 8 && i % 2 != 0 && i != history.length - 1) {
        continue;
      }

      final x = _indexToX(i, chartWidth);
      final weekNum = i + 1;
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'W$weekNum',
          style: TextStyle(
            color: const Color(0xFF8E8A82).withValues(alpha: 0.5),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, bottomY));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.history != history ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

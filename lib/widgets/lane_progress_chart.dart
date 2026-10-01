import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/analytics.dart';
import '../theme/app_theme.dart';

class LaneProgressChart extends StatefulWidget {
  final LaneAnalytics lane;
  final VoidCallback? onTap;

  const LaneProgressChart({
    super.key,
    required this.lane,
    this.onTap,
  });

  @override
  State<LaneProgressChart> createState() => _LaneProgressChartState();
}

class _LaneProgressChartState extends State<LaneProgressChart>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.lane.currentScore / 100,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant LaneProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lane.currentScore != widget.lane.currentScore) {
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: widget.lane.currentScore / 100,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ));
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = Color(widget.lane.colorValue);
    final isPositive = widget.lane.trend >= 0;

    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconData(widget.lane.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: laneColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lane.laneName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.lane.actionsCompleted} actions completed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.lane.currentScore.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : const Color(0xFFE0605A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: isPositive
                            ? AppColors.success
                            : const Color(0xFFE0605A),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.lane.trend.abs().toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? AppColors.success
                              : const Color(0xFFE0605A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Animated progress bar
            AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _fillAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  laneColor,
                                  laneColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Expanded mini bar chart
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 80,
                  child: CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: _MiniBarChartPainter(
                      dataPoints: widget.lane.history,
                      color: laneColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final Color color;

  _MiniBarChartPainter({
    required this.dataPoints,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final values = dataPoints.map((dp) => dp.value).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final barWidth = (size.width - (values.length - 1) * 4) / values.length;
    final barRadius = Radius.circular(3);

    for (int i = 0; i < values.length; i++) {
      final x = i * (barWidth + 4);
      final barHeight = (values[i] / effectiveMax) * (size.height - 4);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        barRadius,
      );

      final paint = Paint()
        ..color = i == values.length - 1
            ? color
            : color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints || oldDelegate.color != color;
  }
}

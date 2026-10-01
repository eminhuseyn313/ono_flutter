import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weekly_review.dart';
import '../theme/app_theme.dart';

class ReviewLaneCard extends StatefulWidget {
  final LaneReviewScore laneScore;
  final ValueChanged<double> onScoreChanged;

  const ReviewLaneCard({
    super.key,
    required this.laneScore,
    required this.onScoreChanged,
  });

  @override
  State<ReviewLaneCard> createState() => _ReviewLaneCardState();
}

class _ReviewLaneCardState extends State<ReviewLaneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fillAnimation;
  late double _currentScore;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.laneScore.score;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0, end: _currentScore / 10)
        .animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void didUpdateWidget(ReviewLaneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.laneScore.score != widget.laneScore.score) {
      _currentScore = widget.laneScore.score;
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: _currentScore / 10,
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
    final laneColor = Color(widget.laneScore.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: laneColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    IconData(
                      widget.laneScore.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: laneColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.laneScore.laneName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: laneColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.laneScore.actionsCompleted} actions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: laneColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentScore.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: laneColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _fillAnimation.value,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(laneColor),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: laneColor,
                inactiveTrackColor: AppColors.divider,
                thumbColor: laneColor,
                overlayColor: laneColor.withValues(alpha: 0.15),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: _currentScore,
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    _currentScore = value;
                  });
                  widget.onScoreChanged(value);
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.laneScore.highlight,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

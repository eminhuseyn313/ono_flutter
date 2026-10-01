import 'package:flutter/material.dart';

import '../models/power_rankings.dart';
import '../theme/app_theme.dart';

class LaneRankCard extends StatefulWidget {
  final LaneRanking ranking;
  final VoidCallback? onTap;

  const LaneRankCard({
    super.key,
    required this.ranking,
    this.onTap,
  });

  @override
  State<LaneRankCard> createState() => _LaneRankCardState();
}

class _LaneRankCardState extends State<LaneRankCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scoreAnimation;
  late final Animation<double> _fadeAnimation;
  bool _showTip = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.ranking.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
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
    final ranking = widget.ranking;

    return GestureDetector(
      onTap: () {
        setState(() => _showTip = !_showTip);
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ranking.laneColor.withValues(alpha: 0.15),
                  AppColors.card,
                ],
              ),
              border: Border.all(
                color: ranking.laneColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ranking.laneColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(ranking),
                  const SizedBox(height: 12),
                  _buildScoreSection(ranking),
                  const SizedBox(height: 10),
                  _buildCompletionBar(ranking),
                  const SizedBox(height: 8),
                  _buildTopAction(ranking),
                  if (_showTip) ...[
                    const SizedBox(height: 8),
                    _buildImprovementTip(ranking),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(LaneRanking ranking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              ranking.laneEmoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              ranking.lane.substring(0, 1).toUpperCase() +
                  ranking.lane.substring(1),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        _buildRankBadge(ranking),
      ],
    );
  }

  Widget _buildRankBadge(LaneRanking ranking) {
    final isFirst = ranking.rank == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isFirst
            ? const LinearGradient(
                colors: [Color(0xFFD9B45E), Color(0xFFD9A040)],
              )
            : null,
        color: isFirst ? null : AppColors.cardLight,
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: const Color(0xFFD9B45E).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('🏅', style: TextStyle(fontSize: 12)),
            ),
          Text(
            '#${ranking.rank}',
            style: TextStyle(
              color: isFirst ? Colors.black : AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(LaneRanking ranking) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _scoreAnimation,
          builder: (context, child) {
            return Text(
              _scoreAnimation.value.round().toString(),
              style: TextStyle(
                color: ranking.laneColor,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '/100',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        FadeTransition(
          opacity: _fadeAnimation,
          child: _buildTrendIndicator(ranking),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(LaneRanking ranking) {
    final delta = ranking.scoreDelta;
    final prefix = delta > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: ranking.trend.color.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ranking.trend.icon,
            color: ranking.trend.color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$prefix$delta',
            style: TextStyle(
              color: ranking.trend.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBar(LaneRanking ranking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion',
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(ranking.completionRate * 100).round()}%',
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: ranking.completionRate * _controller.value,
                  backgroundColor: AppColors.cardLight,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ranking.laneColor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAction(LaneRanking ranking) {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          color: ranking.laneColor.withValues(alpha: 0.6),
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            ranking.topAction,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementTip(LaneRanking ranking) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: ranking.laneColor.withValues(alpha: 0.08),
        border: Border.all(
          color: ranking.laneColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: ranking.laneColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ranking.improvementTip,
              style: TextStyle(
                color: AppColors.greyLight.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

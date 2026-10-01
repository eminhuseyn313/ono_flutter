import 'package:flutter/material.dart';

import '../models/trending.dart';
import '../theme/app_theme.dart';

/// Card for each mini-challenge in the detail view.
class TrendingChallengeCard extends StatefulWidget {
  final TrendingChallenge challenge;
  final bool isLocked;
  final VoidCallback onComplete;

  const TrendingChallengeCard({
    super.key,
    required this.challenge,
    required this.isLocked,
    required this.onComplete,
  });

  @override
  State<TrendingChallengeCard> createState() => _TrendingChallengeCardState();
}

class _TrendingChallengeCardState extends State<TrendingChallengeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  bool _justCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.challenge.isCompleted || _justCompleted;
    final laneIcon = _laneIcon(widget.challenge.lane);
    final laneLabel = _laneLabel(widget.challenge.lane);
    final laneColor = _laneColor(widget.challenge.lane);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.green.withValues(alpha: 0.08)
            : widget.isLocked
                ? AppColors.card.withValues(alpha: 0.5)
                : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.green.withValues(alpha: 0.3)
              : widget.isLocked
                  ? AppColors.divider.withValues(alpha: 0.3)
                  : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Day badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Day ${widget.challenge.dayNumber}',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Lane badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: laneColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(laneIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      laneLabel,
                      style: TextStyle(
                        color: laneColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.isLocked)
                Icon(
                  Icons.lock,
                  color: AppColors.grey.withValues(alpha: 0.4),
                  size: 18,
                ),
              if (isCompleted)
                ScaleTransition(
                  scale: _justCompleted
                      ? _checkScale
                      : const AlwaysStoppedAnimation(1.0),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.green,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.challenge.title,
            style: TextStyle(
              color: widget.isLocked
                  ? AppColors.grey.withValues(alpha: 0.5)
                  : AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.challenge.description,
            style: TextStyle(
              color: widget.isLocked
                  ? AppColors.grey.withValues(alpha: 0.3)
                  : AppColors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (!isCompleted && !widget.isLocked) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _justCompleted = true);
                  _checkController.forward();
                  widget.onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Complete Challenge ✓',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _laneIcon(String lane) => switch (lane) {
        'mind' => '🧠',
        'body' => '💪',
        'social' => '👥',
        'skill' => '🎯',
        _ => '⭐',
      };

  String _laneLabel(String lane) => switch (lane) {
        'mind' => 'Mind',
        'body' => 'Body',
        'social' => 'Social',
        'skill' => 'Skill',
        _ => lane,
      };

  Color _laneColor(String lane) => switch (lane) {
        'mind' => AppColors.purple,
        'body' => AppColors.green,
        'social' => AppColors.cyan,
        'skill' => AppColors.warning,
        _ => AppColors.grey,
      };
}

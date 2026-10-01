import 'package:flutter/material.dart';

import '../models/planner.dart';
import '../theme/app_theme.dart';

class PlannerTimelineItem extends StatefulWidget {
  final PlannerItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const PlannerTimelineItem({
    super.key,
    required this.item,
    this.isFirst = false,
    this.isLast = false,
    required this.onToggleComplete,
    required this.onDelete,
    this.onTap,
  });

  @override
  State<PlannerTimelineItem> createState() => _PlannerTimelineItemState();
}

class _PlannerTimelineItemState extends State<PlannerTimelineItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PlannerTimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isCompleted != widget.item.isCompleted &&
        widget.item.isCompleted) {
      _checkController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color get _laneColor {
    if (widget.item.lane != null) {
      return Color(widget.item.lane!.colorValue);
    }
    switch (widget.item.type) {
      case PlannerItemType.breakTime:
        return const Color(0xFF9AA6B2);
      case PlannerItemType.custom:
        return AppColors.purple;
      default:
        return AppColors.purple;
    }
  }

  Color get _priorityColor {
    switch (widget.item.priority) {
      case PlannerPriority.high:
        return const Color(0xFFEF4444);
      case PlannerPriority.medium:
        return const Color(0xFFF59E0B);
      case PlannerPriority.low:
        return const Color(0xFF34D399);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFEF4444),
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeline(),
              const SizedBox(width: 12),
              _buildTimeLabel(),
              const SizedBox(width: 12),
              Expanded(child: _buildCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          if (!widget.isFirst)
            Expanded(
              child: Container(
                width: 2,
                color: _laneColor.withValues(alpha: 0.3),
              ),
            )
          else
            const Spacer(),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.item.isCompleted
                  ? _laneColor
                  : Colors.transparent,
              border: Border.all(
                color: _laneColor,
                width: 2,
              ),
            ),
            child: widget.item.isCompleted
                ? const Icon(
                    Icons.check,
                    size: 8,
                    color: Colors.white,
                  )
                : null,
          ),
          if (!widget.isLast)
            Expanded(
              child: Container(
                width: 2,
                color: _laneColor.withValues(alpha: 0.3),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTimeLabel() {
    final timeText = widget.item.formattedTime;
    return SizedBox(
      width: 56,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          timeText.isNotEmpty ? timeText : '--:--',
          style: TextStyle(
            color: timeText.isNotEmpty ? AppColors.grey : AppColors.grey.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.item.isCompleted
            ? AppColors.card.withValues(alpha: 0.6)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.item.isCompleted
              ? _laneColor.withValues(alpha: 0.2)
              : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.item.emoji,
            style: TextStyle(
              fontSize: 24,
              color: widget.item.isCompleted
                  ? Colors.white.withValues(alpha: 0.4)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          color: widget.item.isCompleted
                              ? AppColors.grey
                              : AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: widget.item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.grey,
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _priorityColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildDurationBadge(),
                    const SizedBox(width: 8),
                    _buildTypeBadge(),
                    if (widget.item.lane != null) ...[
                      const SizedBox(width: 8),
                      _buildLaneBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCheckbox(),
        ],
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.item.formattedDuration,
        style: TextStyle(
          color: AppColors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _laneColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.item.type.label,
        style: TextStyle(
          color: _laneColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLaneBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(widget.item.lane!.colorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.item.lane!.label,
        style: TextStyle(
          color: Color(widget.item.lane!.colorValue),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onToggleComplete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.item.isCompleted
                ? _laneColor
                : Colors.transparent,
            border: Border.all(
              color: widget.item.isCompleted
                  ? _laneColor
                  : AppColors.grey.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: widget.item.isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

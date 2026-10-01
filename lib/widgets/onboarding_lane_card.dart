import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding.dart';
import '../theme/app_theme.dart';

/// A glassmorphic lane card used in the onboarding lane reorder step.
///
/// Displays the lane icon, title, description, and a priority number badge.
/// Has a colored left border matching the lane color. Designed to be used
/// inside a [ReorderableListView].
class OnboardingLaneCard extends StatelessWidget {
  final String laneId;
  final String title;
  final String description;
  final int priority;
  final bool isDragging;
  final VoidCallback? onTap;

  const OnboardingLaneCard({
    super.key,
    required this.laneId,
    required this.title,
    required this.description,
    required this.priority,
    this.isDragging = false,
    this.onTap,
  });

  Color get _laneColor => OnboardingLanes.colorForLane(laneId);
  IconData get _laneIcon => OnboardingLanes.iconForLane(laneId);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDragging ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDragging
                ? _laneColor.withValues(alpha: 0.6)
                : AppColors.divider,
            width: isDragging ? 1.5 : 1,
          ),
          color: isDragging
              ? AppColors.cardLight.withValues(alpha: 0.95)
              : AppColors.card.withValues(alpha: 0.8),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: _laneColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Colored left accent bar.
                  _buildLeftAccent(),
                  // Card content.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          // Lane icon.
                          _buildLaneIcon(),
                          const SizedBox(width: 14),
                          // Title & description.
                          Expanded(child: _buildTextContent()),
                          const SizedBox(width: 12),
                          // Priority badge.
                          _buildPriorityBadge(),
                          const SizedBox(width: 8),
                          // Drag handle.
                          _buildDragHandle(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftAccent() {
    return Container(
      width: 4,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _laneColor,
            _laneColor.withValues(alpha: 0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildLaneIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _laneColor.withValues(alpha: 0.15),
        border: Border.all(
          color: _laneColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _laneIcon,
        color: _laneColor,
        size: 22,
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _laneColor.withValues(alpha: 0.2),
        border: Border.all(
          color: _laneColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$priority',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _laneColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Icon(
      Icons.drag_indicator_rounded,
      color: AppColors.grey.withValues(alpha: 0.5),
      size: 20,
    );
  }
}

/// A compact version of the lane card used in the goal setting step.
class OnboardingLaneCardCompact extends StatelessWidget {
  final String laneId;
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget? expandedContent;

  const OnboardingLaneCardCompact({
    super.key,
    required this.laneId,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    this.expandedContent,
  });

  Color get _laneColor => OnboardingLanes.colorForLane(laneId);
  IconData get _laneIcon => OnboardingLanes.iconForLane(laneId);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? _laneColor.withValues(alpha: 0.5)
              : AppColors.divider,
          width: isExpanded ? 1.5 : 1,
        ),
        color: AppColors.card.withValues(alpha: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row — always visible.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(isExpanded ? 0 : 14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _laneColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        _laneIcon,
                        color: _laneColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _laneColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable content.
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: expandedContent ?? const SizedBox.shrink(),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}

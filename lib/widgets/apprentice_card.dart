import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/apprentice_mode.dart';

/// A glassmorphic card displaying the active apprentice binding for a lane.
///
/// Shows the role model emoji + name, a purple "APPRENTICE MODE" badge,
/// and an expandable list of suggested actions as checkable items.
class ApprenticeCard extends StatefulWidget {
  final ApprenticeBinding binding;
  final List<String> actions;
  final Color laneColor;
  final ValueChanged<int>? onActionToggled;
  final VoidCallback? onDeactivate;

  const ApprenticeCard({
    super.key,
    required this.binding,
    required this.actions,
    required this.laneColor,
    this.onActionToggled,
    this.onDeactivate,
  });

  @override
  State<ApprenticeCard> createState() => _ApprenticeCardState();
}

class _ApprenticeCardState extends State<ApprenticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _expanded = false;
  final Set<int> _checkedActions = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  void _toggleAction(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_checkedActions.contains(index)) {
        _checkedActions.remove(index);
      } else {
        _checkedActions.add(index);
      }
    });
    widget.onActionToggled?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withValues(alpha: 0.15),
                  AppColors.purple.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 12),
                      _buildTagline(),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _buildActionList(),
                        crossFadeState: _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                        sizeCurve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Role model emoji + name.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.binding.roleModelEmoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                widget.binding.roleModelName,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // "APPRENTICE MODE" badge with purple glow.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple,
                AppColors.purple.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            'APPRENTICE MODE',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'What would ${widget.binding.roleModelName} do today?',
      style: TextStyle(
        color: AppColors.purpleSoft.withValues(alpha: 0.9),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildActionList() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          ...List.generate(widget.actions.length, (index) {
            final checked = _checkedActions.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleAction(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: checked
                        ? AppColors.purple.withValues(alpha: 0.15)
                        : AppColors.card.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: checked
                          ? AppColors.purple.withValues(alpha: 0.4)
                          : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: checked
                              ? AppColors.purple
                              : Colors.transparent,
                          border: Border.all(
                            color: checked
                                ? AppColors.purple
                                : AppColors.grey,
                            width: 2,
                          ),
                        ),
                        child: checked
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.actions[index],
                          style: TextStyle(
                            color: checked
                                ? AppColors.white
                                : AppColors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // Deactivate button.
          if (widget.onDeactivate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onDeactivate!();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.grey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Deactivate Apprentice Mode',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

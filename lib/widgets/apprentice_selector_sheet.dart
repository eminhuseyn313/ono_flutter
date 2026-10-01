import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/apprentice_mode.dart';

/// Bottom sheet for selecting a role model for a specific lane.
///
/// Displays a grid of role model options with selectable cards.
/// The selected card receives a purple border glow. An "Activate
/// Apprentice Mode" button confirms the selection.
class ApprenticeSelectorSheet extends StatefulWidget {
  final String lane;
  final ValueChanged<RoleModel> onSelected;

  const ApprenticeSelectorSheet({
    super.key,
    required this.lane,
    required this.onSelected,
  });

  /// Show the selector sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String lane,
    required ValueChanged<RoleModel> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApprenticeSelectorSheet(
        lane: lane,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ApprenticeSelectorSheet> createState() =>
      _ApprenticeSelectorSheetState();
}

class _ApprenticeSelectorSheetState extends State<ApprenticeSelectorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  String? _selectedId;

  static const Map<String, String> _laneEmojis = {
    'mind': '🧠',
    'body': '💪',
    'social': '🗣',
    'skill': '📚',
  };

  static const Map<String, Color> _laneColors = {
    'mind': AppColors.purple,
    'body': AppColors.green,
    'social': Color(0xFFF97316),
    'skill': AppColors.cyan,
  };

  static const Map<String, List<RoleModel>> _roleModelsByLane = {
    'mind': [
      RoleModel(id: 'marcus_aurelius', name: 'Marcus Aurelius', emoji: '🏛', lane: 'mind'),
      RoleModel(id: 'naval_ravikant_mind', name: 'Naval Ravikant', emoji: '🧭', lane: 'mind'),
      RoleModel(id: 'sam_harris', name: 'Sam Harris', emoji: '🧠', lane: 'mind'),
      RoleModel(id: 'cal_newport', name: 'Cal Newport', emoji: '📖', lane: 'mind'),
    ],
    'body': [
      RoleModel(id: 'david_goggins', name: 'David Goggins', emoji: '🔥', lane: 'body'),
      RoleModel(id: 'andrew_huberman', name: 'Andrew Huberman', emoji: '🧪', lane: 'body'),
      RoleModel(id: 'arnold', name: 'Arnold', emoji: '💪', lane: 'body'),
      RoleModel(id: 'wim_hof', name: 'Wim Hof', emoji: '❄️', lane: 'body'),
    ],
    'social': [
      RoleModel(id: 'chris_voss', name: 'Chris Voss', emoji: '🎯', lane: 'social'),
      RoleModel(id: 'dale_carnegie', name: 'Dale Carnegie', emoji: '🤝', lane: 'social'),
      RoleModel(id: 'jordan_peterson', name: 'Jordan Peterson', emoji: '🗣', lane: 'social'),
      RoleModel(id: 'simon_sinek', name: 'Simon Sinek', emoji: '⭕', lane: 'social'),
    ],
    'skill': [
      RoleModel(id: 'elon_musk', name: 'Elon Musk', emoji: '🚀', lane: 'skill'),
      RoleModel(id: 'james_clear', name: 'James Clear', emoji: '⚡', lane: 'skill'),
      RoleModel(id: 'tim_ferriss', name: 'Tim Ferriss', emoji: '⏱', lane: 'skill'),
      RoleModel(id: 'naval_ravikant_skill', name: 'Naval Ravikant', emoji: '🧭', lane: 'skill'),
    ],
  };

  List<RoleModel> get _roleModels =>
      _roleModelsByLane[widget.lane] ?? [];

  RoleModel? get _selectedModel {
    if (_selectedId == null) return null;
    return _roleModels.where((m) => m.id == _selectedId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectModel(RoleModel model) {
    HapticFeedback.selectionClick();
    setState(() => _selectedId = model.id);
  }

  void _activate() {
    final model = _selectedModel;
    if (model == null) return;
    HapticFeedback.mediumImpact();
    widget.onSelected(model);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final laneEmoji = _laneEmojis[widget.lane] ?? '📌';
    final laneColor = _laneColors[widget.lane] ?? AppColors.purple;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: laneColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle.
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(laneEmoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      const Text(
                        'Choose your mentor',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a role model to guide your ${widget.lane} lane',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Role model grid.
                  _buildGrid(laneColor),
                  const SizedBox(height: 24),
                  // Activate button.
                  _buildActivateButton(laneColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(Color laneColor) {
    final models = _roleModels;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final selected = model.id == _selectedId;
        return _buildModelCard(model, selected, laneColor);
      },
    );
  }

  Widget _buildModelCard(RoleModel model, bool selected, Color laneColor) {
    return GestureDetector(
      onTap: () => _selectModel(model),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.cardLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.7)
                : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(model.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                model.name,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.greyLight,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivateButton(Color laneColor) {
    final enabled = _selectedId != null;
    return GestureDetector(
      onTap: enabled ? _activate : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.purple, Color(0xFF7C3AED)],
                )
              : null,
          color: enabled ? null : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            'Activate Apprentice Mode',
            style: TextStyle(
              color: enabled
                  ? AppColors.white
                  : AppColors.grey.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

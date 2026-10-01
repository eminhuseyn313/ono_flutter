import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CreateCapsuleSheet extends StatefulWidget {
  final Future<bool> Function({
    required String message,
    String? lane,
    required DateTime unlockAt,
    String? mood,
  }) onCreateCapsule;

  const CreateCapsuleSheet({
    super.key,
    required this.onCreateCapsule,
  });

  @override
  State<CreateCapsuleSheet> createState() => _CreateCapsuleSheetState();
}

class _CreateCapsuleSheetState extends State<CreateCapsuleSheet>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  String? _selectedMood;
  int _selectedDurationDays = 60;
  String? _selectedLane;
  bool _isSubmitting = false;
  bool _showCustomPicker = false;
  DateTime? _customDate;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  static const _moods = ['😤', '😐', '😊', '🔥', '👑'];
  static const _durationOptions = [30, 60, 90];
  static const _lanes = [
    {'key': 'mind', 'label': '🧠 Mind'},
    {'key': 'body', 'label': '💪 Body'},
    {'key': 'social', 'label': '🗣 Social'},
    {'key': 'skill', 'label': '📚 Skill'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  DateTime get _unlockDate {
    if (_showCustomPicker && _customDate != null) {
      return _customDate!;
    }
    return DateTime.now().add(Duration(days: _selectedDurationDays));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final success = await widget.onCreateCapsule(
      message: _messageController.text,
      lane: _selectedLane,
      unlockAt: _unlockDate,
      mood: _selectedMood,
    );

    if (mounted) {
      if (success) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              onPrimary: AppColors.white,
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
            dialogBackgroundColor: AppColors.card,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _customDate = picked;
        _showCustomPicker = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Write to your future self ✉️',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This letter will be sealed until the unlock date.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Message input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      maxLength: 500,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Dear future me...',
                        hintStyle: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mood selector
              const Text(
                'How are you feeling right now?',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMood = isSelected ? null : mood;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.purple.withValues(alpha: 0.2)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purple
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          mood,
                          style: TextStyle(
                            fontSize: isSelected ? 26 : 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Duration selector
              const Text(
                'When should it unlock?',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._durationOptions.map((days) {
                    final isSelected =
                        !_showCustomPicker && _selectedDurationDays == days;
                    return _buildChip(
                      label: '$days days',
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDurationDays = days;
                          _showCustomPicker = false;
                        });
                      },
                    );
                  }),
                  _buildChip(
                    label: _showCustomPicker && _customDate != null
                        ? _formatDate(_customDate!)
                        : 'Custom',
                    isSelected: _showCustomPicker,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _pickCustomDate();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lane tag selector
              const Text(
                'Tag a lane (optional)',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _lanes.map((lane) {
                  final key = lane['key']!;
                  final isSelected = _selectedLane == key;
                  return _buildChip(
                    label: lane['label']!,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedLane = isSelected ? null : key;
                      });
                    },
                    activeColor: _laneColor(key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Unlock date preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(
                      'Opens on ${_formatDate(_unlockDate)}',
                      style: TextStyle(
                        color: AppColors.purpleSoft,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _messageController.text.trim().isEmpty ? 0.5 : 1.0,
                  child: GestureDetector(
                    onTap: _messageController.text.trim().isEmpty || _isSubmitting
                        ? null
                        : _submit,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.purple,
                            Color(0xFF7C3AED),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                'Seal this capsule 🔒',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppColors.purple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.grey,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Color _laneColor(String lane) {
    switch (lane) {
      case 'mind':
        return AppColors.purple;
      case 'body':
        return AppColors.green;
      case 'social':
        return const Color(0xFFF97316);
      case 'skill':
        return AppColors.cyan;
      default:
        return AppColors.purple;
    }
  }
}

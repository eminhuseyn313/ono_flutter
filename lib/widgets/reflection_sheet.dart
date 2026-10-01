import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Lane-specific prompts that feel personal and relevant.
const _lanePrompts = <String, List<String>>{
  'mind': [
    'What did your mind reveal to you?',
    'What thought pattern did you notice?',
    'How did this shift your perspective?',
    'What would your wisest self say about this?',
    'What mental barrier did you push through?',
  ],
  'body': [
    'Where did you feel the breakthrough?',
    'What signal did your body give you today?',
    'How does your body feel right now vs. before?',
    'What did pushing through teach you?',
    'Which part challenged you most physically?',
  ],
  'social': [
    'Who did you connect with and how did it feel?',
    'What did you learn about someone today?',
    'How did showing up for others change your energy?',
    'What conversation left a mark on you?',
    'How did this interaction stretch your comfort zone?',
  ],
  'skill': [
    'What clicked for you today?',
    'What\'s one thing you can now do that you couldn\'t before?',
    'Where did deep focus take you?',
    'What skill gap did you close today?',
    'How would you teach what you just learned?',
  ],
};

const _defaultPrompts = [
  'How did that feel?',
  'What did you learn?',
  'What was the hardest part?',
  'Would you do it differently?',
  'One word to describe it:',
];

/// Bottom sheet for adding a quick reflection note after completing an action.
/// Now with lane-specific prompts, persistence wiring, and optional display.
class ReflectionSheet extends StatefulWidget {
  final String actionId;
  final String actionTitle;
  final String lane;
  final Future<void> Function(String note, String prompt) onSave;

  const ReflectionSheet({
    super.key,
    required this.actionId,
    required this.actionTitle,
    required this.lane,
    required this.onSave,
  });

  @override
  State<ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<ReflectionSheet>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final String _prompt;
  bool _isSaving = false;
  bool _saved = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    // Pick a lane-specific prompt
    final prompts = _lanePrompts[widget.lane] ?? _defaultPrompts;
    final idx = DateTime.now().millisecondsSinceEpoch % prompts.length;
    _prompt = prompts[idx];

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Color get _laneColor {
    switch (widget.lane) {
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

  String get _laneEmoji {
    switch (widget.lane) {
      case 'mind':
        return '🧠';
      case 'body':
        return '💪';
      case 'social':
        return '🗣';
      case 'skill':
        return '📚';
      default:
        return '⚡';
    }
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await widget.onSave(text, _prompt);
      if (mounted) {
        setState(() {
          _saved = true;
          _isSaving = false;
        });
        // Brief success flash before closing
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: _laneColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title row
                  Row(
                    children: [
                      Text(_laneEmoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Reflection',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.actionTitle,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lane-specific prompt
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _laneColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _laneColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _prompt,
                      style: TextStyle(
                        color: _laneColor.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text input
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 3,
                    maxLength: 280,
                    enabled: !_isSaving && !_saved,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Write a quick thought...',
                      hintStyle: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _laneColor),
                      ),
                      counterStyle:
                          const TextStyle(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  if (_saved)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '✅ Reflection saved!',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.divider),
                              ),
                              child: const Center(
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _handleSave,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _laneColor,
                                    _laneColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save reflection ✨',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the reflection bottom sheet.
/// Set [forceShow] to false to make the sheet optional (only shows on first
/// completion of the day per lane, or randomly 30% of the time).
void showReflectionSheet(
  BuildContext context, {
  required String actionId,
  required String actionTitle,
  required String lane,
  required Future<void> Function(String note, String prompt) onSave,
  bool forceShow = false,
  int todayLaneReflectionCount = 0,
}) {
  // Optional display logic: show if forced, first lane completion today,
  // or ~30% chance otherwise.
  if (!forceShow && todayLaneReflectionCount > 0) {
    final shouldShow = DateTime.now().millisecond % 10 < 3;
    if (!shouldShow) return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReflectionSheet(
      actionId: actionId,
      actionTitle: actionTitle,
      lane: lane,
      onSave: onSave,
    ),
  );
}

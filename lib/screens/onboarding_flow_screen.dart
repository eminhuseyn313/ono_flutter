import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/onboarding.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_lane_card.dart';
import '../widgets/onboarding_progress_bar.dart';

/// Multi-step onboarding flow screen with 5 pages.
///
/// Steps: Name/Motivation -> Lane Selection -> Goal Setting ->
///        Schedule Setup -> Ready to Go
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onNextPressed(OnboardingProvider provider) {
    if (!provider.canProceed) return;

    if (provider.isLastStep) {
      provider.completeOnboarding().then((_) {
        if (provider.currentStep == OnboardingStep.complete &&
            mounted) {
          // TODO: Navigate to main app screen.
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
      return;
    }

    provider.goToNextStep();
    _pageController.animateToPage(
      provider.currentPageIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onBackPressed(OnboardingProvider provider) {
    provider.goToPreviousStep();
    _pageController.animateToPage(
      provider.currentPageIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onStepTapped(OnboardingProvider provider, OnboardingStep step) {
    provider.goToStep(step);
    _pageController.animateToPage(
      provider.currentPageIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: !provider.canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && provider.canGoBack) {
              _onBackPressed(provider);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Progress bar.
                    OnboardingProgressBar(
                      currentStep: provider.currentStep,
                      completedSteps: provider.profile.completedSteps,
                      onStepTapped: (step) =>
                          _onStepTapped(provider, step),
                    ),
                    const SizedBox(height: 8),
                    // Page content.
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _NameMotivationStep(provider: provider),
                          _LaneSelectionStep(provider: provider),
                          _GoalSettingStep(provider: provider),
                          _ScheduleSetupStep(provider: provider),
                          _ReadyToGoStep(provider: provider),
                        ],
                      ),
                    ),
                    // Navigation buttons.
                    _buildBottomNav(provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(OnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button.
          if (provider.canGoBack)
            TextButton.icon(
              onPressed: () => _onBackPressed(provider),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          // Next / Complete button.
          _buildNextButton(provider),
        ],
      ),
    );
  }

  Widget _buildNextButton(OnboardingProvider provider) {
    final isLast = provider.isLastStep;
    final canProceed = provider.canProceed;
    final isLoading = provider.isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed:
            (canProceed && !isLoading) ? () => _onNextPressed(provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canProceed ? AppColors.purple : AppColors.divider,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.grey,
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: canProceed ? 4 : 0,
          shadowColor: AppColors.purple.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Start Your Transformation' : 'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

// =============================================================================
// Step 1: Name & Motivation
// =============================================================================

class _NameMotivationStep extends StatefulWidget {
  final OnboardingProvider provider;

  const _NameMotivationStep({required this.provider});

  @override
  State<_NameMotivationStep> createState() => _NameMotivationStepState();
}

class _NameMotivationStepState extends State<_NameMotivationStep> {
  late final TextEditingController _nameController;

  static const _motivations = [
    'Build discipline',
    'Level up skills',
    'Get fit',
    'Find my path',
  ];

  static const _motivationIcons = [
    Icons.bolt_rounded,
    Icons.trending_up_rounded,
    Icons.fitness_center_rounded,
    Icons.explore_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.provider.profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Title.
          Text(
            'What should we\ncall you?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Name input card.
          _buildGlassmorphicCard(
            child: TextField(
              controller: _nameController,
              onChanged: widget.provider.updateName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.purple.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 36),
          // Motivation section.
          Text(
            'What brings you to ONO?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose what resonates most',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // Motivation chips.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_motivations.length, (index) {
              final motivation = _motivations[index];
              final isSelected =
                  widget.provider.profile.motivation == motivation;
              return _buildMotivationChip(
                label: motivation,
                icon: _motivationIcons[index],
                isSelected: isSelected,
                onTap: () => widget.provider.updateMotivation(motivation),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMotivationChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isSelected
              ? AppColors.purple.withValues(alpha: 0.2)
              : AppColors.card,
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.purpleSoft : AppColors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.purpleSoft : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Step 2: Lane Selection (Drag-to-Reorder)
// =============================================================================

class _LaneSelectionStep extends StatefulWidget {
  final OnboardingProvider provider;

  const _LaneSelectionStep({required this.provider});

  @override
  State<_LaneSelectionStep> createState() => _LaneSelectionStepState();
}

class _LaneSelectionStepState extends State<_LaneSelectionStep> {
  int? _draggingIndex;

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    final prefs =
        List<LanePreference>.from(widget.provider.profile.lanePreferences);
    final item = prefs.removeAt(oldIndex);
    prefs.insert(newIndex, item);

    // Re-assign priorities based on new order.
    final updated = prefs
        .asMap()
        .entries
        .map((e) => e.value.copyWith(priority: e.key + 1))
        .toList();

    widget.provider.updateLanePreferences(updated);
    setState(() => _draggingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.provider.profile.lanePreferences;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Prioritize your\nlanes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag to reorder by importance to you',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ReorderableListView.builder(
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  listenable: animation,
                  builder: (context, child) {
                    final elevation = lerpDouble(0, 8, animation.value)!;
                    return Material(
                      color: Colors.transparent,
                      elevation: elevation,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorderStart: (index) {
                setState(() => _draggingIndex = index);
              },
              onReorderEnd: (_) {
                setState(() => _draggingIndex = null);
              },
              onReorder: _onReorder,
              itemCount: prefs.length,
              itemBuilder: (context, index) {
                final pref = prefs[index];
                final laneData = OnboardingLanes.defaults.firstWhere(
                  (l) => l['id'] == pref.laneId,
                  orElse: () => OnboardingLanes.defaults.first,
                );
                return OnboardingLaneCard(
                  key: ValueKey(pref.laneId),
                  laneId: pref.laneId,
                  title: laneData['name'] as String,
                  description: laneData['description'] as String,
                  priority: index + 1,
                  isDragging: _draggingIndex == index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to lerp doubles (needed for proxy decorator).
double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

/// AnimatedBuilder wrapper (Flutter uses AnimatedBuilder in newer versions).
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

// =============================================================================
// Step 3: Goal Setting
// =============================================================================

class _GoalSettingStep extends StatefulWidget {
  final OnboardingProvider provider;

  const _GoalSettingStep({required this.provider});

  @override
  State<_GoalSettingStep> createState() => _GoalSettingStepState();
}

class _GoalSettingStepState extends State<_GoalSettingStep> {
  String? _expandedLaneId;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final lane in OnboardingLanes.defaults) {
      final laneId = lane['id'] as String;
      final existingGoal = widget.provider.profile.goals
          .where((g) => g.lane == laneId)
          .toList();
      _controllers[laneId] = TextEditingController(
        text: existingGoal.isNotEmpty ? existingGoal.first.title : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onGoalChanged(String laneId, String value) {
    final existing =
        widget.provider.profile.goals.where((g) => g.lane == laneId).toList();

    if (value.trim().isEmpty) {
      // Remove goal if text is cleared.
      if (existing.isNotEmpty) {
        widget.provider.removeGoal(existing.first.id);
      }
      return;
    }

    if (existing.isNotEmpty) {
      widget.provider.updateGoal(existing.first.copyWith(title: value.trim()));
    } else {
      widget.provider.addGoal(OnboardingGoal(
        id: 'goal_${laneId}_${DateTime.now().millisecondsSinceEpoch}',
        title: value.trim(),
        lane: laneId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Set your first\ngoals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One goal per lane — totally optional',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          // Lane cards with expandable goal inputs.
          ...OnboardingLanes.defaults.map((lane) {
            final laneId = lane['id'] as String;
            final laneName = lane['name'] as String;
            final isExpanded = _expandedLaneId == laneId;
            final hasGoal = _controllers[laneId]?.text.isNotEmpty ?? false;

            return OnboardingLaneCardCompact(
              laneId: laneId,
              title: laneName,
              isExpanded: isExpanded,
              onTap: () {
                setState(() {
                  _expandedLaneId = isExpanded ? null : laneId;
                });
              },
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: _controllers[laneId],
                    onChanged: (v) => _onGoalChanged(laneId, v),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Meditate daily for 10 minutes',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.grey.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppColors.background.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: OnboardingLanes.colorForLane(laneId)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.divider,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: OnboardingLanes.colorForLane(laneId),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: hasGoal
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Skip hint.
          Center(
            child: Text(
              'You can always add goals later',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.grey.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 4: Schedule Setup
// =============================================================================

class _ScheduleSetupStep extends StatefulWidget {
  final OnboardingProvider provider;

  const _ScheduleSetupStep({required this.provider});

  @override
  State<_ScheduleSetupStep> createState() => _ScheduleSetupStepState();
}

class _ScheduleSetupStepState extends State<_ScheduleSetupStep> {
  static const _sessionLengths = [15, 30, 45, 60];

  SchedulePreference get _schedule =>
      widget.provider.profile.schedule ?? const SchedulePreference();

  void _updateSchedule(SchedulePreference updated) {
    widget.provider.updateSchedule(updated);
  }

  Future<void> _pickTime(BuildContext context, bool isWakeUp) async {
    final currentTime = isWakeUp ? _schedule.wakeUpTime : _schedule.bedTime;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              onPrimary: AppColors.white,
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isWakeUp) {
        _updateSchedule(_schedule.copyWith(wakeUpTime: timeStr));
      } else {
        _updateSchedule(_schedule.copyWith(bedTime: timeStr));
      }
    }
  }

  void _toggleDay(int day) {
    final days = List<int>.from(_schedule.activeDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
      days.sort();
    }
    _updateSchedule(_schedule.copyWith(activeDays: days));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'When do you\nshow up?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll build your schedule around your life',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 28),

          // Wake / Sleep time.
          _buildSectionLabel('Your rhythm'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: 'Wake up',
                  time: _schedule.wakeUpTime,
                  icon: Icons.wb_sunny_rounded,
                  color: AppColors.warning,
                  onTap: () => _pickTime(context, true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTimePicker(
                  label: 'Bed time',
                  time: _schedule.bedTime,
                  icon: Icons.bedtime_rounded,
                  color: AppColors.purple,
                  onTap: () => _pickTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Session length.
          _buildSectionLabel('Session length'),
          const SizedBox(height: 12),
          Row(
            children: _sessionLengths.map((minutes) {
              final isSelected =
                  _schedule.preferredSessionLength == minutes;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: minutes != _sessionLengths.last ? 10 : 0,
                  ),
                  child: _buildSessionChip(
                    label: '${minutes}m',
                    isSelected: isSelected,
                    onTap: () => _updateSchedule(
                      _schedule.copyWith(preferredSessionLength: minutes),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Active days.
          _buildSectionLabel('Active days'),
          const SizedBox(height: 12),
          _buildDayGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.purple.withValues(alpha: 0.2)
              : AppColors.card,
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.purpleSoft : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (day) {
        final isActive = _schedule.activeDays.contains(day);
        return GestureDetector(
          onTap: () => _toggleDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.purple.withValues(alpha: 0.25)
                  : AppColors.card,
              border: Border.all(
                color: isActive ? AppColors.purple : AppColors.divider,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                SchedulePreference.dayName(day).substring(0, 1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.purpleSoft : AppColors.grey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Step 5: Ready to Go
// =============================================================================

class _ReadyToGoStep extends StatefulWidget {
  final OnboardingProvider provider;

  const _ReadyToGoStep({required this.provider});

  @override
  State<_ReadyToGoStep> createState() => _ReadyToGoStepState();
}

class _ReadyToGoStepState extends State<_ReadyToGoStep>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _checkController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Generate particles.
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.3 + 0.1,
        color: [
          AppColors.purple,
          AppColors.purpleSoft,
          AppColors.cyan,
          AppColors.green,
          const Color(0xFFF59E0B),
        ][_random.nextInt(5)],
      ));
    }

    // Stagger the check animation start.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.provider.profile;

    return Stack(
      children: [
        // Particle animation layer.
        AnimatedBuilder(
          listenable: _particleController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleController.value,
              ),
            );
          },
        ),
        // Content.
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'You\'re all set,\n${profile.name.isNotEmpty ? profile.name : 'Champion'}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s your personalized plan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Summary cards.
              _buildSummaryCard(
                icon: Icons.bolt_rounded,
                title: 'Motivation',
                value: profile.motivation.isNotEmpty
                    ? profile.motivation
                    : 'Not set',
                color: AppColors.purple,
                delay: 0,
              ),
              _buildSummaryCard(
                icon: Icons.reorder_rounded,
                title: 'Top Lane',
                value: profile.lanePreferences.isNotEmpty
                    ? _laneDisplayName(profile.lanePreferences.first.laneId)
                    : 'Not set',
                color: profile.lanePreferences.isNotEmpty
                    ? OnboardingLanes.colorForLane(
                        profile.lanePreferences.first.laneId)
                    : AppColors.grey,
                delay: 1,
              ),
              _buildSummaryCard(
                icon: Icons.flag_rounded,
                title: 'Goals Set',
                value: '${profile.goals.length} goal${profile.goals.length != 1 ? 's' : ''}',
                color: AppColors.green,
                delay: 2,
              ),
              _buildSummaryCard(
                icon: Icons.schedule_rounded,
                title: 'Session Length',
                value: profile.schedule != null
                    ? '${profile.schedule!.preferredSessionLength} minutes'
                    : '30 minutes',
                color: AppColors.cyan,
                delay: 3,
              ),
              _buildSummaryCard(
                icon: Icons.calendar_today_rounded,
                title: 'Active Days',
                value: profile.schedule != null
                    ? '${profile.schedule!.activeDays.length} days/week'
                    : '5 days/week',
                color: const Color(0xFFF59E0B),
                delay: 4,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  String _laneDisplayName(String laneId) {
    final lane = OnboardingLanes.defaults.firstWhere(
      (l) => l['id'] == laneId,
      orElse: () => OnboardingLanes.defaults.first,
    );
    return lane['name'] as String;
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required int delay,
  }) {
    return AnimatedBuilder(
      listenable: _checkController,
      builder: (context, child) {
        final delayedProgress =
            ((_checkController.value - delay * 0.12).clamp(0.0, 1.0) / 0.5)
                .clamp(0.0, 1.0);
        final curvedProgress =
            Curves.easeOutBack.transform(delayedProgress);

        return Opacity(
          opacity: delayedProgress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curvedProgress)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.card.withValues(alpha: 0.8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle_rounded,
              color: color.withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Particle Animation
// =============================================================================

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yOffset = (p.y + progress * p.speed) % 1.0;
      final opacity = (sin(progress * pi * 2 + p.x * pi) * 0.3 + 0.5)
          .clamp(0.1, 0.6);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, yOffset * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// =============================================================================
// Shared Helpers
// =============================================================================

Widget _buildGlassmorphicCard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.card.withValues(alpha: 0.7),
      border: Border.all(
        color: AppColors.divider.withValues(alpha: 0.6),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

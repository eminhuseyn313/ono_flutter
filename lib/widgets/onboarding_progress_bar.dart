import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding.dart';
import '../theme/app_theme.dart';

/// Animated segmented progress bar for the onboarding flow.
///
/// Displays 5 segments that fill with a purple gradient as the user
/// progresses through onboarding steps. Step labels appear below.
class OnboardingProgressBar extends StatelessWidget {
  final OnboardingStep currentStep;
  final Set<OnboardingStep> completedSteps;
  final ValueChanged<OnboardingStep>? onStepTapped;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    this.onStepTapped,
  });

  static const _visibleSteps = [
    OnboardingStep.welcome,
    OnboardingStep.laneSelection,
    OnboardingStep.goalSetting,
    OnboardingStep.scheduleSetup,
    OnboardingStep.tutorial,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step counter text.
          _buildStepCounter(),
          const SizedBox(height: 12),
          // Segmented bar.
          _buildSegmentedBar(),
          const SizedBox(height: 8),
          // Step labels.
          _buildStepLabels(),
        ],
      ),
    );
  }

  Widget _buildStepCounter() {
    final currentIndex = _visibleSteps.indexOf(currentStep);
    final stepNumber = currentIndex >= 0 ? currentIndex + 1 : 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Step $stepNumber of ${_visibleSteps.length}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
        Text(
          currentStep.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.purpleSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedBar() {
    return Row(
      children: List.generate(_visibleSteps.length, (index) {
        final step = _visibleSteps[index];
        final isCompleted = completedSteps.contains(step);
        final isCurrent = step == currentStep;
        final isReachable =
            isCompleted || isCurrent || step.stepIndex <= currentStep.stepIndex;

        return Expanded(
          child: GestureDetector(
            onTap: isReachable ? () => onStepTapped?.call(step) : null,
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _visibleSteps.length - 1 ? 4 : 0,
              ),
              child: _AnimatedSegment(
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepLabels() {
    return Row(
      children: List.generate(_visibleSteps.length, (index) {
        final step = _visibleSteps[index];
        final isCompleted = completedSteps.contains(step);
        final isCurrent = step == currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < _visibleSteps.length - 1 ? 4 : 0,
            ),
            child: Text(
              step.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? AppColors.white
                    : isCompleted
                        ? AppColors.purpleSoft
                        : AppColors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// A single animated segment of the progress bar.
class _AnimatedSegment extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;

  const _AnimatedSegment({
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      height: isCurrent ? 6 : 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: (isCompleted || isCurrent)
            ? const LinearGradient(
                colors: [
                  AppColors.purple,
                  AppColors.purpleSoft,
                ],
              )
            : null,
        color: (isCompleted || isCurrent) ? null : AppColors.divider,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

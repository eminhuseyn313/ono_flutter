import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/becoming_arc.dart';
import '../providers/becoming_arc_provider.dart';
import '../theme/app_theme.dart';

/// Main Becoming Arc overview screen.
///
/// When the user has an active arc it displays the 5-layer vertical progress
/// path, today's steps with checkboxes, and self-assessment CTAs on milestone
/// days (1, 15, 30). When no arc is active it shows an arc-selection grid.
class BecomingArcScreen extends StatefulWidget {
  const BecomingArcScreen({super.key});

  @override
  State<BecomingArcScreen> createState() => _BecomingArcScreenState();
}

class _BecomingArcScreenState extends State<BecomingArcScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BecomingArcProvider>();
      provider.loadArcs();
      provider.loadUserProgress('user_1');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: const Text(
          'The Becoming Arc',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<BecomingArcProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.arcs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          // Find the first active (non-completed) arc.
          final activeEntry = provider.activeArcs.entries
              .where((e) => !e.value.isComplete)
              .toList();

          if (activeEntry.isEmpty) {
            return _ArcSelectionView(provider: provider);
          }

          final progress = activeEntry.first.value;
          final arc = provider.getArc(progress.arcId);
          if (arc == null) {
            return _ArcSelectionView(provider: provider);
          }

          return _ActiveArcView(
            arc: arc,
            progress: progress,
            provider: provider,
            pulseAnimation: _pulseAnimation,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Arc Selection View — shown when no arc is active
// =============================================================================

class _ArcSelectionView extends StatelessWidget {
  const _ArcSelectionView({required this.provider});

  final BecomingArcProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Choose Your Becoming Arc',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a 30-day transformation journey to begin.',
          style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        ...provider.arcs.map((arc) => _ArcSelectionCard(arc: arc)),
      ],
    );
  }
}

class _ArcSelectionCard extends StatelessWidget {
  const _ArcSelectionCard({required this.arc});

  final BecomingArc arc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arc.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  arc.description,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: '${arc.totalDays} days',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.layers,
                      label: '${arc.steps.length} steps',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context
                          .read<BecomingArcProvider>()
                          .startArc('user_1', arc.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Begin This Arc',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.purple, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.purple, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Active Arc View — the main journey screen
// =============================================================================

class _ActiveArcView extends StatelessWidget {
  const _ActiveArcView({
    required this.arc,
    required this.progress,
    required this.provider,
    required this.pulseAnimation,
  });

  final BecomingArc arc;
  final UserArcProgress progress;
  final BecomingArcProvider provider;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final todaySteps = arc.stepsForDay(progress.currentDay);
    final assessmentDay = progress.nextAssessmentDay;
    final overallPct = (progress.overallProgress * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // ----- Journey Info Card -----
        _JourneyInfoCard(arc: arc, progress: progress),
        const SizedBox(height: 24),

        // ----- Self-Assessment CTA -----
        if (assessmentDay != null) ...[
          _AssessmentCTACard(
            arcId: arc.id,
            dayNumber: assessmentDay,
            pulseAnimation: pulseAnimation,
          ),
          const SizedBox(height: 24),
        ],

        // ----- 5-Layer Progress Path -----
        Row(
          children: [
            const Text(
              'Transformation Layers',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$overallPct% complete',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LayerProgressPath(
          arcId: arc.id,
          progress: progress,
          provider: provider,
        ),
        const SizedBox(height: 28),

        // ----- Today's Steps -----
        Text(
          'Today\'s Steps — Day ${progress.currentDay}',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (todaySteps.isEmpty)
          _EmptyStepsCard()
        else
          ...todaySteps.map(
            (step) => _StepCheckCard(
              step: step,
              isCompleted: provider.isStepCompleted(arc.id, step.id),
              onToggle: () {
                HapticFeedback.mediumImpact();
                provider.completeStep('user_1', arc.id, step.id);
              },
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Journey Info Card
// =============================================================================

class _JourneyInfoCard extends StatelessWidget {
  const _JourneyInfoCard({required this.arc, required this.progress});

  final BecomingArc arc;
  final UserArcProgress progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purple.withValues(alpha: 0.25),
                AppColors.card.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.purple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arc.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day ${progress.currentDay} of ${arc.totalDays}',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.overallProgress,
                  minHeight: 8,
                  backgroundColor: AppColors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.completedStepCount} steps completed',
                    style: TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  Text(
                    '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
}

// =============================================================================
// Self-Assessment CTA Card
// =============================================================================

class _AssessmentCTACard extends StatelessWidget {
  const _AssessmentCTACard({
    required this.arcId,
    required this.dayNumber,
    required this.pulseAnimation,
  });

  final String arcId;
  final int dayNumber;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(
                  alpha: 0.25 * pulseAnimation.value,
                ),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cyan.withValues(alpha: 0.2),
                  AppColors.card.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assessment_outlined,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time for your Day $dayNumber assessment',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check in on your growth across all layers.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push(
                      '/arc/$arcId/assessment/$dayNumber',
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.cyan,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 5-Layer Vertical Progress Path
// =============================================================================

class _LayerProgressPath extends StatelessWidget {
  const _LayerProgressPath({
    required this.arcId,
    required this.progress,
    required this.provider,
  });

  final String arcId;
  final UserArcProgress progress;
  final BecomingArcProvider provider;

  @override
  Widget build(BuildContext context) {
    const layers = ArcLayer.values;
    return Column(
      children: List.generate(layers.length, (index) {
        final layer = layers[index];
        final layerProg = provider.getLayerProgress(arcId, layer);
        final pctString = (layerProg * 100).toStringAsFixed(0);
        final isCompleted = layerProg >= 1.0;
        final isActive = layerProg > 0.0 && layerProg < 1.0;
        final isLast = index == layers.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical connector line + node
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    // Node
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/arc/$arcId/layer/${layer.name}');
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? layer.color
                              : isActive
                                  ? layer.color.withValues(alpha: 0.25)
                                  : AppColors.card,
                          border: Border.all(
                            color: isActive || isCompleted
                                ? layer.color
                                : AppColors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: layer.glowColor,
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 20,
                              )
                            : Text(
                                layer.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    // Connecting line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: isCompleted
                              ? layer.color.withValues(alpha: 0.5)
                              : AppColors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Layer info
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/arc/$arcId/layer/${layer.name}');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? layer.color.withValues(alpha: 0.3)
                            : AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                layer.label,
                                style: TextStyle(
                                  color: isActive || isCompleted
                                      ? AppColors.white
                                      : AppColors.grey,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$pctString%',
                              style: TextStyle(
                                color: layer.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: layerProg,
                            minHeight: 5,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation(layer.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Today's Step Card with Checkbox
// =============================================================================

class _StepCheckCard extends StatelessWidget {
  const _StepCheckCard({
    required this.step,
    required this.isCompleted,
    required this.onToggle,
  });

  final ArcStep step;
  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? step.layer.color.withValues(alpha: 0.3)
                    : AppColors.divider.withValues(alpha: 0.4),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isCompleted ? null : onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? step.layer.color
                              : Colors.transparent,
                          border: Border.all(
                            color: isCompleted
                                ? step.layer.color
                                : AppColors.grey.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  step.layer.emoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: TextStyle(
                                      color: isCompleted
                                          ? AppColors.grey
                                          : AppColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              style: TextStyle(
                                color: AppColors.grey.withValues(
                                  alpha: isCompleted ? 0.6 : 1.0,
                                ),
                                fontSize: 12,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.grey,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${step.estimatedDuration.inMinutes} min',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ...List.generate(
                                  step.difficulty,
                                  (_) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      color: AppColors.warning,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}

// =============================================================================
// Empty Steps Card
// =============================================================================

class _EmptyStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.cyan.withValues(alpha: 0.6),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'No steps scheduled for today',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy the rest or revisit previous layers.',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

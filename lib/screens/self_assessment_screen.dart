import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/becoming_arc.dart';
import '../providers/becoming_arc_provider.dart';
import '../theme/app_theme.dart';

/// Self-assessment screen for Day 1/15/30 milestone checkpoints.
///
/// Presents five sliders (one per [ArcLayer]) scored 1-10, an optional
/// freeform note field, and — on Day 15 or 30 — a "before vs now" bar-chart
/// comparison against prior assessments. Submitting triggers a brief
/// celebration animation.
class SelfAssessmentScreen extends StatefulWidget {
  const SelfAssessmentScreen({
    super.key,
    required this.arcId,
    required this.dayNumber,
  });

  final String arcId;
  final int dayNumber;

  @override
  State<SelfAssessmentScreen> createState() => _SelfAssessmentScreenState();
}

class _SelfAssessmentScreenState extends State<SelfAssessmentScreen>
    with SingleTickerProviderStateMixin {
  final Map<ArcLayer, double> _scores = {
    for (final layer in ArcLayer.values) layer: 5.0,
  };
  final TextEditingController _notesController = TextEditingController();
  bool _submitted = false;

  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;
  late final Animation<double> _celebrationOpacity;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _celebrationOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.heavyImpact();

    final provider = context.read<BecomingArcProvider>();
    final assessment = SelfAssessment(
      id: 'assess_${widget.arcId}_day${widget.dayNumber}_${DateTime.now().millisecondsSinceEpoch}',
      dayNumber: widget.dayNumber,
      takenAt: DateTime.now(),
      scores: _scores.map((k, v) => MapEntry(k, v.round())),
      freeformNote: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await provider.submitAssessment('user_1', widget.arcId, assessment);

    if (!mounted) return;

    setState(() => _submitted = true);
    _celebrationController.forward();

    // Auto-pop after celebration.
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) context.pop();
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
        title: Text(
          'Day ${widget.dayNumber} Self-Assessment',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Consumer<BecomingArcProvider>(
            builder: (context, provider, _) {
              final progress = provider.getProgress(widget.arcId);
              final previousAssessments = progress?.assessments
                      .where((a) => a.dayNumber < widget.dayNumber)
                      .toList() ??
                  [];

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Header
                  _HeaderCard(dayNumber: widget.dayNumber),
                  const SizedBox(height: 24),

                  // Comparison chart (Day 15 or 30)
                  if (widget.dayNumber > 1 &&
                      previousAssessments.isNotEmpty) ...[
                    const Text(
                      'Your Growth',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ComparisonChart(
                      previousAssessments: previousAssessments,
                      currentScores: _scores.map(
                        (k, v) => MapEntry(k, v.round()),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Sliders
                  const Text(
                    'Rate Yourself',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be honest — growth starts with awareness.',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ArcLayer.values.map(
                    (layer) => _LayerSlider(
                      layer: layer,
                      value: _scores[layer]!,
                      onChanged: _submitted
                          ? null
                          : (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _scores[layer] = v);
                            },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Freeform notes
                  const Text(
                    'Reflections',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.4),
                          ),
                        ),
                        child: TextField(
                          controller: _notesController,
                          enabled: !_submitted,
                          maxLines: 5,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'What have you noticed about yourself? Any breakthroughs or struggles?',
                            hintStyle: TextStyle(
                              color: AppColors.grey.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitted ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.purple.withValues(alpha: 0.3),
                        disabledForegroundColor:
                            AppColors.white.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _submitted ? 'Submitted' : 'Submit Assessment',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),

          // Celebration overlay
          if (_submitted)
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, _) {
                return IgnorePointer(
                  child: Opacity(
                    opacity: _celebrationOpacity.value,
                    child: Center(
                      child: Transform.scale(
                        scale: _celebrationScale.value,
                        child: _CelebrationBurst(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header Card
// =============================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.dayNumber});

  final int dayNumber;

  String get _subtitle {
    switch (dayNumber) {
      case 1:
        return 'Establish your starting point. Be brutally honest — this snapshot is for you.';
      case 15:
        return 'You are halfway through. See how far you have come and where to push harder.';
      case 30:
        return 'The arc is complete. Measure the distance between who you were and who you are.';
      default:
        return 'Check in on your progress across all five transformation layers.';
    }
  }

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
                AppColors.purple.withValues(alpha: 0.2),
                AppColors.card.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayNumber == 30
                      ? '🏆'
                      : dayNumber == 15
                          ? '🔄'
                          : '📊',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $dayNumber Checkpoint',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Layer Slider Row
// =============================================================================

class _LayerSlider extends StatelessWidget {
  const _LayerSlider({
    required this.layer,
    required this.value,
    required this.onChanged,
  });

  final ArcLayer layer;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      layer.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      layer.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: layer.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value.round().toString(),
                        style: TextStyle(
                          color: layer.color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: layer.color,
                    inactiveTrackColor: layer.color.withValues(alpha: 0.15),
                    thumbColor: layer.color,
                    overlayColor: layer.color.withValues(alpha: 0.12),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: onChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Struggling',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Thriving',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Before vs Now Comparison Chart
// =============================================================================

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({
    required this.previousAssessments,
    required this.currentScores,
  });

  final List<SelfAssessment> previousAssessments;
  final Map<ArcLayer, int> currentScores;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              Row(
                children: [
                  ...previousAssessments.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.grey.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Day ${a.dayNumber}',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Now',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bar chart per layer
              ...ArcLayer.values.map((layer) {
                final currentVal = currentScores[layer] ?? 5;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            layer.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            layer.label,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Previous assessment bars
                      ...previousAssessments.map((a) {
                        final prevVal = a.scores[layer] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _BarRow(
                            value: prevVal,
                            maxValue: 10,
                            color: AppColors.grey.withValues(alpha: 0.35),
                            label: 'Day ${a.dayNumber}: $prevVal',
                          ),
                        );
                      }),
                      // Current bar
                      _BarRow(
                        value: currentVal,
                        maxValue: 10,
                        color: layer.color,
                        label: 'Now: $currentVal',
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.label,
  });

  final int value;
  final int maxValue;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = value / maxValue;
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 14,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Celebration Burst Overlay
// =============================================================================

class _CelebrationBurst extends StatelessWidget {
  static const _emojis = ['🎉', '✨', '🌟', '💪', '🔥', '⚡', '💎', '🏆'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central message
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              const Text(
                'Assessment Complete!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep going, keep growing.',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Scattered emojis
          ..._buildScatteredEmojis(),
        ],
      ),
    );
  }

  List<Widget> _buildScatteredEmojis() {
    final rng = Random(42);
    return List.generate(8, (i) {
      final angle = (i / 8) * 2 * pi;
      final radius = 100.0 + rng.nextDouble() * 30;
      return Positioned(
        left: 140 + cos(angle) * radius - 12,
        top: 140 + sin(angle) * radius - 12,
        child: Text(
          _emojis[i],
          style: const TextStyle(fontSize: 22),
        ),
      );
    });
  }
}

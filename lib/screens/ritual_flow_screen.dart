import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ritual.dart';
import '../providers/ritual_provider.dart';
import '../theme/app_theme.dart';

/// Full-screen ritual flow — a timed PageView through each ritual step,
/// ending with a celebration screen.
class RitualFlowScreen extends StatefulWidget {
  final String ritualId;

  const RitualFlowScreen({super.key, required this.ritualId});

  @override
  State<RitualFlowScreen> createState() => _RitualFlowScreenState();
}

class _RitualFlowScreenState extends State<RitualFlowScreen> {
  late PageController _pageController;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initRitual();
  }

  Future<void> _initRitual() async {
    final provider = context.read<RitualProvider>();
    await provider.startRitual(widget.ritualId);
    if (mounted) setState(() => _started = true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onStepComplete() {
    final provider = context.read<RitualProvider>();
    provider.advanceStep();
    final nextIndex = provider.currentStepIndex;
    // +1 because page 0 is step 0, and the last page is the completion screen.
    if (nextIndex >= provider.totalSteps) {
      _goToPage(provider.totalSteps); // completion page
    } else {
      _goToPage(nextIndex);
    }
  }

  void _onSkip() {
    final provider = context.read<RitualProvider>();
    provider.skipStep();
    final nextIndex = provider.currentStepIndex;
    if (nextIndex >= provider.totalSteps) {
      _goToPage(provider.totalSteps);
    } else {
      _goToPage(nextIndex);
    }
  }

  Future<void> _onComplete() async {
    final provider = context.read<RitualProvider>();
    await provider.completeRitual();
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<RitualProvider>();
    if (!provider.isInProgress) return true;

    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Exit ritual?',
          style: Theme.of(ctx).textTheme.headlineMedium,
        ),
        content: Text(
          'Progress will be lost.',
          style: Theme.of(ctx).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );

    if (exit == true) {
      provider.cancelRitual();
    }
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _started ? _buildFlow() : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.purple),
    );
  }

  Widget _buildFlow() {
    return Consumer<RitualProvider>(
      builder: (context, provider, _) {
        if (provider.activeRitual == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final steps = provider.activeRitual!.steps;
        final totalPages = steps.length + 1; // steps + completion

        return Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    Color(0xFF10122A),
                    AppColors.background,
                  ],
                ),
              ),
            ),
            // Ambient purple glow
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _ProgressDots(
                    total: steps.length,
                    current: provider.currentStepIndex,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalPages,
                      itemBuilder: (context, index) {
                        if (index < steps.length) {
                          return _StepPage(
                            step: steps[index],
                            stepIndex: index,
                            totalSteps: steps.length,
                            onComplete: _onStepComplete,
                            onSkip: _onSkip,
                          );
                        }
                        return _CompletionPage(
                          session: provider.activeSession,
                          ritual: provider.activeRitual!,
                          onDone: _onComplete,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.grey),
                onPressed: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Progress dots
// ---------------------------------------------------------------------------

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;

  const _ProgressDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final isActive = i == current;
          final isDone = i < current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDone
                  ? AppColors.purple
                  : isActive
                      ? AppColors.purpleSoft
                      : AppColors.grey.withValues(alpha: 0.3),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual step page
// ---------------------------------------------------------------------------

class _StepPage extends StatefulWidget {
  final RitualStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _StepPage({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.step.durationSeconds),
    );
    _timerController.forward();
    _autoAdvanceTimer = Timer(
      Duration(seconds: widget.step.durationSeconds),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Color _laneColor() {
    switch (widget.step.lane) {
      case RitualLane.mind:
        return AppColors.purple;
      case RitualLane.body:
        return AppColors.cyan;
      case RitualLane.social:
        return AppColors.green;
      case RitualLane.skill:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = _laneColor();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Circular countdown around icon
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CountdownRingPainter(
                    progress: _timerController.value,
                    color: laneColor,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: laneColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    widget.step.iconData,
                    size: 44,
                    color: laneColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Lane pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: laneColor.withValues(alpha: 0.15),
            ),
            child: Text(
              widget.step.lane.name.toUpperCase(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: laneColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            widget.step.title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.step.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Glassmorphic instruction card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  widget.step.instruction,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.greyLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Countdown text
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) {
              final remaining = widget.step.durationSeconds -
                  (_timerController.value * widget.step.durationSeconds)
                      .round();
              final m = remaining ~/ 60;
              final s = remaining % 60;
              return Text(
                '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const Spacer(flex: 2),
          // Complete early / skip row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.step.isOptional)
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: laneColor.withValues(alpha: 0.2),
                  foregroundColor: laneColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown ring painter
// ---------------------------------------------------------------------------

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CountdownRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Completion / celebration page
// ---------------------------------------------------------------------------

class _CompletionPage extends StatefulWidget {
  final RitualSession? session;
  final Ritual ritual;
  final VoidCallback onDone;

  const _CompletionPage({
    required this.session,
    required this.ritual,
    required this.onDone,
  });

  @override
  State<_CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<_CompletionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrateController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _celebrateController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _celebrateController,
      curve: Curves.easeIn,
    );
    _celebrateController.forward();
  }

  @override
  void dispose() {
    _celebrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.session?.stepsCompleted.length ?? 0;
    final totalSteps = widget.ritual.steps.length;
    final elapsed = widget.session != null
        ? DateTime.now().difference(widget.session!.startedAt)
        : Duration.zero;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Confetti-style burst
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _ConfettiBurst(),
            ),
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _scaleAnim,
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              'Ritual Complete',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              widget.ritual.type == RitualType.morning
                  ? 'Your morning is set. Go make it count.'
                  : 'Your evening is at peace. Rest well.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          // Stats row
          FadeTransition(
            opacity: _fadeAnim,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        value: '$completedCount/$totalSteps',
                        label: 'Steps',
                        color: AppColors.purple,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      _StatColumn(
                        value:
                            '${minutes}m ${seconds.toString().padLeft(2, '0')}s',
                        label: 'Duration',
                        color: AppColors.cyan,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat column
// ---------------------------------------------------------------------------

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti burst — decorative radial dots
// ---------------------------------------------------------------------------

class _ConfettiBurst extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.purple,
      AppColors.cyan,
      AppColors.green,
      AppColors.warning,
      AppColors.purpleSoft,
    ];
    final random = Random(7);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(20, (i) {
          final angle = (2 * pi / 20) * i;
          final radius = 50.0 + random.nextDouble() * 50;
          final size = 4.0 + random.nextDouble() * 6;
          return Positioned(
            left: 100 + cos(angle) * radius - size / 2,
            top: 100 + sin(angle) * radius - size / 2,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i % colors.length].withValues(alpha: 0.7),
              ),
            ),
          );
        }),
      ),
    );
  }
}

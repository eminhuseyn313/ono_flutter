import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/phase_transition.dart';
import '../theme/app_theme.dart';

/// Full-screen celebration shown when the user transitions between arc phases.
///
/// Expects a [PhaseTransition] passed via GoRouter's `extra` parameter.
class PhaseTransitionScreen extends StatefulWidget {
  final PhaseTransition transition;

  const PhaseTransitionScreen({super.key, required this.transition});

  @override
  State<PhaseTransitionScreen> createState() => _PhaseTransitionScreenState();
}

class _PhaseTransitionScreenState extends State<PhaseTransitionScreen>
    with TickerProviderStateMixin {
  // -----------------------------------------------------------------------
  // Animation controllers
  // -----------------------------------------------------------------------

  late final AnimationController _bgController;
  late final AnimationController _phaseNumberController;
  late final AnimationController _contentController;
  late final AnimationController _rewardsController;
  late final AnimationController _ctaController;
  late final AnimationController _pulseController;

  // Tweens driven by the controllers above.
  late final Animation<double> _bgProgress;
  late final Animation<double> _numberScale;
  late final Animation<double> _numberOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _ctaOpacity;
  late final Animation<double> _ctaScale;

  // Typewriter state.
  String _visibleTitle = '';
  String _visibleDescription = '';
  Timer? _titleTimer;
  Timer? _descriptionTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    // --- Background gradient shift (1.2 s) ---
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bgProgress = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    // --- Phase number scale-in (800 ms) ---
    _phaseNumberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _numberScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _phaseNumberController, curve: Curves.elasticOut),
    );
    _numberOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _phaseNumberController, curve: Curves.easeIn),
    );

    // --- Title + description area (600 ms) ---
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    // --- Rewards stagger (managed per item; controller just tracks overall) ---
    _rewardsController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300 + widget.transition.rewards.length * 200,
      ),
    );

    // --- CTA button (500 ms) ---
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ctaOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctaController, curve: Curves.easeOut),
    );
    _ctaScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctaController, curve: Curves.easeOut),
    );

    // --- Continuous background pulse ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  Future<void> _runSequence() async {
    // 1. Background gradient
    _bgController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // 2. Phase number scale-in
    _phaseNumberController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // 3. Content slide + typewriter title
    _contentController.forward();
    _startTypewriter();
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // 4. Rewards stagger
    _rewardsController.forward();
    await Future<void>.delayed(
      Duration(milliseconds: 200 + widget.transition.rewards.length * 200),
    );

    // 5. CTA button
    _ctaController.forward();
  }

  // -----------------------------------------------------------------------
  // Typewriter effect
  // -----------------------------------------------------------------------

  void _startTypewriter() {
    final toPhaseInfo = _toPhaseInfo;
    final fullTitle = toPhaseInfo.title;
    final fullDescription = widget.transition.milestoneDescription;

    int titleIdx = 0;
    _titleTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (titleIdx >= fullTitle.length) {
        timer.cancel();
        _startDescriptionTypewriter(fullDescription);
        return;
      }
      titleIdx++;
      if (mounted) {
        setState(() => _visibleTitle = fullTitle.substring(0, titleIdx));
      }
    });
  }

  void _startDescriptionTypewriter(String fullDescription) {
    int descIdx = 0;
    _descriptionTimer =
        Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (descIdx >= fullDescription.length) {
        timer.cancel();
        return;
      }
      descIdx++;
      if (mounted) {
        setState(
            () => _visibleDescription = fullDescription.substring(0, descIdx));
      }
    });
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  ArcPhaseInfo get _fromPhaseInfo =>
      ArcPhaseInfo.phases[widget.transition.fromPhase.clamp(1, 3) - 1];

  ArcPhaseInfo get _toPhaseInfo =>
      ArcPhaseInfo.phases[widget.transition.toPhase.clamp(1, 3) - 1];

  @override
  void dispose() {
    _bgController.dispose();
    _phaseNumberController.dispose();
    _contentController.dispose();
    _rewardsController.dispose();
    _ctaController.dispose();
    _pulseController.dispose();
    _titleTimer?.cancel();
    _descriptionTimer?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgProgress,
          _numberScale,
          _contentOpacity,
          _rewardsController,
          _ctaOpacity,
          _pulseController,
        ]),
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final fromColor = _fromPhaseInfo.themeColor;
    final toColor = _toPhaseInfo.themeColor;

    final bgColor =
        Color.lerp(fromColor, toColor, _bgProgress.value) ?? toColor;

    final pulseValue = _pulseController.value;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            bgColor.withValues(alpha: 0.25 + pulseValue * 0.1),
            AppColors.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildPhaseNumber(bgColor),
              const SizedBox(height: 32),
              _buildTitleSection(),
              const SizedBox(height: 24),
              _buildStatsSummary(),
              if (widget.transition.rewards.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildRewardsList(),
              ],
              const SizedBox(height: 40),
              _buildCtaButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Phase number with scale-in ---

  Widget _buildPhaseNumber(Color accentColor) {
    return Opacity(
      opacity: _numberOpacity.value,
      child: Transform.scale(
        scale: _numberScale.value,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withValues(alpha: 0.4),
                accentColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.transition.toPhase}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: 0.6),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Title with typewriter effect ---

  Widget _buildTitleSection() {
    return SlideTransition(
      position: _contentSlide,
      child: FadeTransition(
        opacity: _contentOpacity,
        child: Column(
          children: [
            Text(
              'Phase ${widget.transition.toPhase}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _visibleTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _visibleDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Stats summary ---

  Widget _buildStatsSummary() {
    final transition = widget.transition;
    final daysCompleted = (transition.toPhase - 1) * 10;
    final layersActive = ArcPhaseInfo.phases.length;

    return FadeTransition(
      opacity: _contentOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(label: 'Days', value: '$daysCompleted'),
            Container(width: 1, height: 32, color: AppColors.divider),
            _StatItem(
              label: 'Steps',
              value: '${transition.fromPhase * 5}+',
            ),
            Container(width: 1, height: 32, color: AppColors.divider),
            _StatItem(label: 'Layers', value: '$layersActive'),
          ],
        ),
      ),
    );
  }

  // --- Rewards list with staggered fade-in ---

  Widget _buildRewardsList() {
    final rewards = widget.transition.rewards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _contentOpacity,
          child: const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'REWARDS UNLOCKED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        ...List.generate(rewards.length, (index) {
          final itemProgress = _rewardsController.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(
                curve: Interval(
                  (index / rewards.length).clamp(0.0, 1.0),
                  ((index + 1) / rewards.length).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          );

          return AnimatedBuilder(
            animation: itemProgress,
            builder: (context, child) {
              return Opacity(
                opacity: itemProgress.value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - itemProgress.value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _toPhaseInfo.themeColor.withValues(alpha: 0.2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: _toPhaseInfo.themeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rewards[index],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- CTA button ---

  Widget _buildCtaButton(BuildContext context) {
    return FadeTransition(
      opacity: _ctaOpacity,
      child: ScaleTransition(
        scale: _ctaScale,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _toPhaseInfo.themeColor,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small stat item used in the summary row
// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

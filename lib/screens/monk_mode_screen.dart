import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/monk_session.dart';
import '../providers/monk_mode_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/monk_mode_timer.dart';
import '../widgets/session_complete_card.dart';

/// Full-screen, immersive Monk Mode experience.
///
/// Three phases live on one screen so state (duration choice, in-flight
/// timer, completed session) never gets lost to a route transition:
/// SETUP → SESSION → COMPLETE.
class MonkModeScreen extends StatefulWidget {
  const MonkModeScreen({super.key});

  @override
  State<MonkModeScreen> createState() => _MonkModeScreenState();
}

class _MonkModeScreenState extends State<MonkModeScreen>
    with TickerProviderStateMixin {
  // TODO: replace with real auth user id
  static const _userId = 'demo-user';

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  bool _showExitFriction = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_entranceFade);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonkModeProvider>().loadInitialData(_userId);
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleExitAttempt(MonkModeProvider provider) async {
    if (!provider.isActive) {
      Navigator.of(context).maybePop();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _showExitFriction = true);
  }

  Future<void> _confirmAbandon(MonkModeProvider provider) async {
    HapticFeedback.heavyImpact();
    setState(() => _showExitFriction = false);
    await provider.abandonSession();
  }

  void _dismissExitFriction() {
    HapticFeedback.selectionClick();
    setState(() => _showExitFriction = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonkModeProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: !provider.isActive,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleExitAttempt(provider);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                _buildAmbientBackground(provider),
                Positioned.fill(
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _entranceFade,
                      child: SlideTransition(
                        position: _entranceSlide,
                        child: _buildPhaseContent(provider),
                      ),
                    ),
                  ),
                ),
                if (provider.phase != MonkSessionPhase.completed)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    child: _CloseButton(
                      onTap: () => _handleExitAttempt(provider),
                    ),
                  ),
                if (_showExitFriction)
                  _ExitFrictionOverlay(
                    message: provider.exitFrictionMessage,
                    onStay: _dismissExitFriction,
                    onLeaveAnyway: () => _confirmAbandon(provider),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmbientBackground(MonkModeProvider provider) {
    return Positioned.fill(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.3,
                colors: [
                  AppColors.purple.withValues(alpha: 0.10),
                  AppColors.background,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _GlowOrb(color: AppColors.cyan, size: 220, opacity: 0.10),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: _GlowOrb(color: AppColors.purple, size: 260, opacity: 0.14),
          ),
          if (provider.phase == MonkSessionPhase.active)
            const Positioned.fill(
              child: IgnorePointer(child: _AmbientFlame()),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(MonkModeProvider provider) {
    switch (provider.phase) {
      case MonkSessionPhase.idle:
        return _SetupPhase(provider: provider);
      case MonkSessionPhase.active:
        return _SessionPhase(provider: provider);
      case MonkSessionPhase.completed:
        return _CompletePhase(
          provider: provider,
          onReturnHome: () {
            provider.reset();
            Navigator.of(context).maybePop();
          },
        );
    }
  }
}

// ──────────────────────────────────────────
// SETUP PHASE
// ──────────────────────────────────────────
class _SetupPhase extends StatelessWidget {
  final MonkModeProvider provider;

  const _SetupPhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.purpleSoft, AppColors.purple],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Monk Mode',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your phone goes quiet. You sit with yourself.\nNo notifications, no escape, just breath.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'CHOOSE YOUR DURATION',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: kMonkDurationOptions.map((minutes) {
              final selected = provider.selectedMinutes == minutes;
              return _DurationChip(
                minutes: minutes,
                selected: selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.selectDuration(minutes);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 44),
          _StatsRow(stats: provider.stats),
          const SizedBox(height: 44),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Begin Session',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.25)
              : AppColors.cardLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.7)
                : AppColors.divider,
            width: 1.4,
          ),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.grey,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final MonkModeStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '${stats.currentStreak}',
                  label: 'Day streak',
                ),
              ),
              _divider(),
              Expanded(
                child: _MiniStat(
                  value: '${stats.totalSessions}',
                  label: 'Sessions',
                ),
              ),
              _divider(),
              Expanded(
                child: _MiniStat(
                  value: '${stats.totalMinutes}',
                  label: 'Minutes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.divider);
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.purpleSoft,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// SESSION PHASE
// ──────────────────────────────────────────
class _SessionPhase extends StatelessWidget {
  final MonkModeProvider provider;

  const _SessionPhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MonkModeTimer(
          progress: provider.progress,
          timeLabel: provider.remainingLabel,
        ),
        const SizedBox(height: 56),
        BreathingCircle(
          running: provider.isActive,
          onCycleComplete: provider.registerBreathCycle,
        ),
        const SizedBox(height: 56),
        Text(
          '${provider.breathCycles} breath ${provider.breathCycles == 1 ? 'cycle' : 'cycles'} completed',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// COMPLETE PHASE
// ──────────────────────────────────────────
class _CompletePhase extends StatelessWidget {
  final MonkModeProvider provider;
  final VoidCallback onReturnHome;

  const _CompletePhase({required this.provider, required this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    final session = provider.lastCompletedSession;
    final duration = session?.durationMinutes ?? provider.selectedMinutes;
    final cycles = session?.breathCycles ?? provider.breathCycles;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SessionCompleteCard(
        durationMinutes: duration,
        breathCycles: cycles,
        onReturnHome: onReturnHome,
        onShare: () {}, // UI-only for v1
      ),
    );
  }
}

// ──────────────────────────────────────────
// EXIT FRICTION OVERLAY
// ──────────────────────────────────────────
class _ExitFrictionOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onStay;
  final VoidCallback onLeaveAnyway;

  const _ExitFrictionOverlay({
    required this.message,
    required this.onStay,
    required this.onLeaveAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 250),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: AppColors.background.withValues(alpha: 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.warning,
                    size: 40,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Stay the Course',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: onLeaveAnyway,
                    child: Text(
                      'Leave anyway',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

// ──────────────────────────────────────────
// SHARED CHROME
// ──────────────────────────────────────────
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Ambient animated flame/candle effect, self-contained with its own
/// [AnimationController] (properly disposed) — no image assets needed
/// for v1. Painted as a soft flickering teardrop shape near the
/// bottom of the screen.
class _AmbientFlame extends StatefulWidget {
  const _AmbientFlame();

  @override
  State<_AmbientFlame> createState() => _AmbientFlameState();
}

class _AmbientFlameState extends State<_AmbientFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 20s loop expressed as seconds-of-elapsed-time for the painter's
        // multi-frequency sine flicker.
        final t = _controller.value * 20;
        return CustomPaint(
          painter: _FlamePainter(t: t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double t;

  _FlamePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final baseX = size.width / 2;
    final baseY = size.height - 120;

    final flicker = sin(t * 6) * 4 + sin(t * 2.3) * 2;
    final flameHeight = 70 + sin(t * 3.1) * 6;
    final flameWidth = 34 + cos(t * 4.2) * 4;

    void drawFlame(double heightScale, double widthScale, Color color,
        double alpha, double blur) {
      final path = Path();
      final h = flameHeight * heightScale;
      final w = flameWidth * widthScale;
      final tipX = baseX + flicker * heightScale;

      path.moveTo(baseX, baseY);
      path.quadraticBezierTo(
          baseX - w, baseY - h * 0.5, tipX, baseY - h);
      path.quadraticBezierTo(
          baseX + w, baseY - h * 0.5, baseX, baseY);
      path.close();

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

      canvas.drawPath(path, paint);
    }

    // Outer glow.
    drawFlame(1.5, 2.2, AppColors.warning, 0.06, 40);
    drawFlame(1.2, 1.6, AppColors.warning, 0.10, 22);
    // Mid flame body.
    drawFlame(1.0, 1.0, const Color(0xFFFF8A3D), 0.35, 10);
    // Inner hot core.
    drawFlame(0.55, 0.55, AppColors.purpleSoft, 0.55, 6);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.t != t;
}

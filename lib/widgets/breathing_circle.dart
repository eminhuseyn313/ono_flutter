import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/monk_mode_provider.dart' show BreathPhase, kBreathPhaseSeconds;
import '../theme/app_theme.dart';

/// The core Monk Mode breathing animation: a glowing circle that
/// expands over 4s (inhale), holds for 4s, and contracts over 4s
/// (exhale) — on a continuous loop for as long as [running] is true.
///
/// Fires [onCycleComplete] once per full inhale-hold-exhale cycle and
/// pulses haptics at every phase transition.
class BreathingCircle extends StatefulWidget {
  final bool running;
  final VoidCallback? onCycleComplete;
  final double size;

  const BreathingCircle({
    super.key,
    required this.running,
    this.onCycleComplete,
    this.size = 260,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late final AnimationController _phaseController;
  BreathPhase _phase = BreathPhase.inhale;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: kBreathPhaseSeconds),
    )..addStatusListener(_onPhaseTick);

    if (widget.running) _phaseController.forward();
  }

  @override
  void didUpdateWidget(covariant BreathingCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !oldWidget.running) {
      _resetCycle();
      _phaseController.forward();
    } else if (!widget.running && oldWidget.running) {
      _phaseController.stop();
    }
  }

  void _resetCycle() {
    _phase = BreathPhase.inhale;
    _phaseController.value = 0;
  }

  void _onPhaseTick(AnimationStatus status) {
    if (status != AnimationStatus.completed || !widget.running) return;

    HapticFeedback.lightImpact();

    setState(() {
      switch (_phase) {
        case BreathPhase.inhale:
          _phase = BreathPhase.hold;
          break;
        case BreathPhase.hold:
          _phase = BreathPhase.exhale;
          break;
        case BreathPhase.exhale:
          _phase = BreathPhase.inhale;
          HapticFeedback.mediumImpact();
          widget.onCycleComplete?.call();
          break;
      }
    });

    _phaseController.value = 0;
    _phaseController.forward();
  }

  String get _label {
    switch (_phase) {
      case BreathPhase.inhale:
        return 'Breathe In';
      case BreathPhase.hold:
        return 'Hold';
      case BreathPhase.exhale:
        return 'Breathe Out';
    }
  }

  /// 0.35 (contracted) .. 1.0 (expanded), eased per phase.
  double get _scaleForPhase {
    final t = Curves.easeInOut.transform(_phaseController.value);
    switch (_phase) {
      case BreathPhase.inhale:
        return lerpDouble(0.55, 1.0, t)!;
      case BreathPhase.hold:
        return 1.0;
      case BreathPhase.exhale:
        return lerpDouble(1.0, 0.55, t)!;
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseController,
      builder: (context, _) {
        final scale = _scaleForPhase;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft glow ring, largest and most transparent.
              Transform.scale(
                scale: scale * 1.35,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.22),
                        AppColors.purple.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Mid concentric ring.
              Transform.scale(
                scale: scale * 1.12,
                child: Container(
                  width: widget.size * 0.82,
                  height: widget.size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.purpleSoft.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Core glowing circle.
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        AppColors.purpleSoft,
                        AppColors.purple,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.55),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Phase label, cross-fading between states.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _label,
                  key: ValueKey(_label),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

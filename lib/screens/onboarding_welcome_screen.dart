import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_button.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _pillsController;
  late AnimationController _buttonsController;
  late AnimationController _pulseController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _pillsFade;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pillsController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));

    _pillsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pillsController, curve: Curves.easeOut),
    );

    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut));

    // Stagger the animations
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _pillsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _pillsController.dispose();
    _buttonsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFF111214),
              Color(0xFF0C0D0F),
              Color(0xFF0E1012),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated glow orbs
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final pulse = 0.12 + (_pulseController.value * 0.08);
                  return Stack(
                    children: [
                      Positioned(
                        top: 40,
                        right: -50,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.purple.withValues(alpha: pulse),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 120,
                        left: -70,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.cyan.withValues(alpha: pulse * 0.6),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 300,
                        left: 100,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppColors.green.withValues(alpha: pulse * 0.4),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 36),

                            // Top bar
                            FadeTransition(
                              opacity: _heroFade,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFE8C9A3), Color(0xFFC8894A)],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'ONO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6,
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.card.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: AppColors.divider),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Global benchmark',
                                              style: TextStyle(
                                                color: AppColors.greyLight,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 52),

                            // Hero text
                            FadeTransition(
                              opacity: _heroFade,
                              child: SlideTransition(
                                position: _heroSlide,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Who do you\nwant to\nbecome?',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Build your complete blueprint for performance,\npresence, and purpose — one day at a time.',
                                      style: TextStyle(
                                        color: AppColors.grey.withValues(alpha: 0.85),
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Lane pills
                            FadeTransition(
                              opacity: _pillsFade,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _LanePill(
                                    emoji: '🧠',
                                    label: 'Mind',
                                    color: AppColors.purple,
                                    delay: 0,
                                    controller: _pillsController,
                                  ),
                                  _LanePill(
                                    emoji: '💪',
                                    label: 'Body',
                                    color: AppColors.green,
                                    delay: 1,
                                    controller: _pillsController,
                                  ),
                                  _LanePill(
                                    emoji: '🗣',
                                    label: 'Social',
                                    color: const Color(0xFFD9774A),
                                    delay: 2,
                                    controller: _pillsController,
                                  ),
                                  _LanePill(
                                    emoji: '📚',
                                    label: 'Skill',
                                    color: AppColors.cyan,
                                    delay: 3,
                                    controller: _pillsController,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 44),

                            // CTA
                            FadeTransition(
                              opacity: _buttonsFade,
                              child: SlideTransition(
                                position: _buttonsSlide,
                                child: Column(
                                  children: [
                                    OnoButton(
                                      label: 'Begin my transformation',
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        context.go('/sign-up');
                                      },
                                      icon: Icons.arrow_forward_rounded,
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          context.go('/sign-in');
                                        },
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                                color: AppColors.grey, fontSize: 14),
                                            children: [
                                              TextSpan(
                                                  text: 'Already have an account? '),
                                              TextSpan(
                                                text: 'Sign in',
                                                style: TextStyle(
                                                  color: AppColors.purpleSoft,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lane pill with glassmorphic background and staggered entrance.
class _LanePill extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final int delay;
  final AnimationController controller;

  const _LanePill({
    required this.emoji,
    required this.label,
    required this.color,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

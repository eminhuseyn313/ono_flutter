import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ono/theme/app_theme.dart';

import '../widgets/compound_chart.dart';
import '../widgets/lane_projection_card.dart';

class CompoundEffectScreen extends StatefulWidget {
  const CompoundEffectScreen({super.key});

  @override
  State<CompoundEffectScreen> createState() => _CompoundEffectScreenState();
}

class _CompoundEffectScreenState extends State<CompoundEffectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _chartController;
  late final AnimationController _contentController;
  late final AnimationController _pulseController;
  late final Animation<double> _chartAnimation;
  late final Animation<double> _heroFade;
  late final Animation<double> _lanesFade;
  late final Animation<double> _quoteFade;

  // Mock data — in production these come from a provider
  final double _completionRate = 0.78;
  final int _currentDay = 47;
  final Map<String, _LaneData> _laneData = {
    'mind': _LaneData(
      emoji: '\u{1F9E0}',
      name: 'Mind',
      color: AppColors.purple,
      score: 72,
      sparkline: [58, 60, 63, 61, 67, 70, 72],
    ),
    'body': _LaneData(
      emoji: '\u{1F4AA}',
      name: 'Body',
      color: AppColors.green,
      score: 65,
      sparkline: [50, 52, 55, 58, 60, 63, 65],
    ),
    'social': _LaneData(
      emoji: '\u{1F5E3}',
      name: 'Social',
      color: const Color(0xFFD9774A),
      score: 58,
      sparkline: [45, 48, 50, 52, 55, 56, 58],
    ),
    'skill': _LaneData(
      emoji: '\u{1F4DA}',
      name: 'Skill',
      color: AppColors.cyan,
      score: 81,
      sparkline: [65, 68, 72, 74, 76, 79, 81],
    ),
  };

  final List<_Quote> _quotes = [
    _Quote(
      text: 'Small daily improvements over time lead to stunning results.',
      author: 'Robin Sharma',
    ),
    _Quote(
      text: 'Success is the sum of small efforts, repeated day in and day out.',
      author: 'Robert Collier',
    ),
    _Quote(
      text: 'The compound effect is the principle of reaping huge rewards from small, seemingly insignificant actions.',
      author: 'Darren Hardy',
    ),
    _Quote(
      text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      author: 'Aristotle',
    ),
    _Quote(
      text: 'Dripping water hollows out stone not through force but through persistence.',
      author: 'Ovid',
    ),
  ];

  late _Quote _currentQuote;
  int _quoteIndex = 0;

  double get _dailyRate => _completionRate / 100;
  double get _yearMultiplier => math.pow(1 + _dailyRate, 365).toDouble();

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[0];

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _heroFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _lanesFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _quoteFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Staggered start
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _chartController.forward();
    });

    // Rotate quotes
    _startQuoteRotation();
  }

  void _startQuoteRotation() {
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        _currentQuote = _quotes[_quoteIndex];
      });
      _startQuoteRotation();
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.purple.withValues(alpha: 0.08),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            bottom: 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '\u{1F4C8} ',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        'The Compound Effect',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),

                      // Hero stat card
                      FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(_heroFade),
                          child: _buildHeroCard(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Chart
                      AnimatedBuilder(
                        animation: _chartAnimation,
                        builder: (context, _) {
                          return Container(
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.divider.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.card.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: CompoundChart(
                                    currentDay: _currentDay,
                                    dailyRate: _dailyRate,
                                    animationValue: _chartAnimation.value,
                                    onDaySelected: (day) {
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Lane breakdown header
                      FadeTransition(
                        opacity: _lanesFade,
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.purpleSoft, AppColors.purple],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lane Projections',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lane cards grid
                      FadeTransition(
                        opacity: _lanesFade,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(_lanesFade),
                          child: AnimatedBuilder(
                            animation: _lanesFade,
                            builder: (context, _) {
                              return _buildLaneGrid(_lanesFade.value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Motivational quote
                      FadeTransition(
                        opacity: _quoteFade,
                        child: _buildQuoteSection(),
                      ),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final displayRate = _completionRate;
    final multiplierText = _yearMultiplier.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.1),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purpleSoft.withValues(alpha: 0.08),
                  AppColors.purple.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'YOUR 1% DAILY',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "You're improving ",
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _contentController,
                      builder: (context, _) {
                        final val = (displayRate * _heroFade.value)
                            .toStringAsFixed(1);
                        return Text(
                          '${val}%',
                          style: TextStyle(
                            color: AppColors.purple,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    Text(
                      ' daily',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.cyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'At this rate, you\'ll be ',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, _) {
                          final val = (_yearMultiplier * _heroFade.value)
                              .toStringAsFixed(1);
                          return Text(
                            '${val}x',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                      Text(
                        ' better in one year',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Progress markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat('Day', '$_currentDay', AppColors.white),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.divider,
                    ),
                    _buildMiniStat(
                      '30-Day',
                      '${math.pow(1 + _dailyRate, 30).toStringAsFixed(1)}x',
                      AppColors.purpleSoft,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.divider,
                    ),
                    _buildMiniStat(
                      '90-Day',
                      '${math.pow(1 + _dailyRate, 90).toStringAsFixed(1)}x',
                      AppColors.purple,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.divider,
                    ),
                    _buildMiniStat(
                      '1 Year',
                      '${_yearMultiplier.toStringAsFixed(1)}x',
                      AppColors.cyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLaneGrid(double animValue) {
    final lanes = _laneData.values.toList();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LaneProjectionCard(
                laneEmoji: lanes[0].emoji,
                laneName: lanes[0].name,
                laneColor: lanes[0].color,
                currentScore: lanes[0].score,
                sparklineData: lanes[0].sparkline,
                animationValue: animValue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LaneProjectionCard(
                laneEmoji: lanes[1].emoji,
                laneName: lanes[1].name,
                laneColor: lanes[1].color,
                currentScore: lanes[1].score,
                sparklineData: lanes[1].sparkline,
                animationValue: animValue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LaneProjectionCard(
                laneEmoji: lanes[2].emoji,
                laneName: lanes[2].name,
                laneColor: lanes[2].color,
                currentScore: lanes[2].score,
                sparklineData: lanes[2].sparkline,
                animationValue: animValue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LaneProjectionCard(
                laneEmoji: lanes[3].emoji,
                laneName: lanes[3].name,
                laneColor: lanes[3].color,
                currentScore: lanes[3].score,
                sparklineData: lanes[3].sparkline,
                animationValue: animValue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
        color: AppColors.card.withValues(alpha: 0.3),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Column(
          key: ValueKey(_quoteIndex),
          children: [
            Text(
              '\u{201C}',
              style: TextStyle(
                color: AppColors.purple.withValues(alpha: 0.5),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentQuote.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u{2014} ${_currentQuote.author}',
              style: TextStyle(
                color: AppColors.purpleSoft.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaneData {
  final String emoji;
  final String name;
  final Color color;
  final double score;
  final List<double> sparkline;

  const _LaneData({
    required this.emoji,
    required this.name,
    required this.color,
    required this.score,
    required this.sparkline,
  });
}

class _Quote {
  final String text;
  final String author;

  const _Quote({required this.text, required this.author});
}

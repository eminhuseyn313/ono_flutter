import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class StreakFlameCard extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakFlameCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  State<StreakFlameCard> createState() => _StreakFlameCardState();
}

class _StreakFlameCardState extends State<StreakFlameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isRecord => widget.currentStreak >= widget.longestStreak;

  Color _flameColor() {
    if (widget.currentStreak >= 30) return const Color(0xFFEF4444);
    if (widget.currentStreak >= 14) return AppColors.warning;
    if (widget.currentStreak >= 7) return const Color(0xFFFB923C);
    return const Color(0xFFFBBF24);
  }

  @override
  Widget build(BuildContext context) {
    final flameColor = _flameColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flameColor.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.1),
            AppColors.card.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flameColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: flameColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated flame
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFBBF24),
                  flameColor,
                  AppColors.purple,
                ],
              ).createShader(bounds),
              child: Icon(
                Icons.local_fire_department,
                size: widget.currentStreak >= 14 ? 72 : 56,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Streak count
          Text(
            '${widget.currentStreak}',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 52,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'day streak',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          if (_isRecord) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    flameColor.withValues(alpha: 0.3),
                    AppColors.purple.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: flameColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: flameColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'NEW RECORD!',
                    style: GoogleFonts.plusJakartaSans(
                      color: flameColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Personal best: ${widget.longestStreak} days',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shimmer animation widget — wraps a child in a sweeping highlight effect.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1B1D22),
                Color(0xFF2A2D33),
                Color(0xFF1B1D22),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmer bone — rounded rectangle placeholder.
class ShimmerBone extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBone({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Full home screen skeleton — shown while actions are loading.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBone(width: 100, height: 14),
                    SizedBox(height: 8),
                    ShimmerBone(width: 160, height: 28),
                  ],
                ),
                const ShimmerBone(width: 90, height: 40, borderRadius: 14),
              ],
            ),
            const SizedBox(height: 28),
            // Progress ring skeleton
            const ShimmerBone(height: 120, borderRadius: 20),
            const SizedBox(height: 20),
            // Challenge skeleton
            const ShimmerBone(height: 140, borderRadius: 16),
            const SizedBox(height: 12),
            const ShimmerBone(height: 140, borderRadius: 16),
            const SizedBox(height: 28),
            // Actions header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBone(width: 130, height: 18),
                ShimmerBone(width: 50, height: 14),
              ],
            ),
            const SizedBox(height: 12),
            // Action card skeletons
            ...List.generate(4, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBone(height: 80, borderRadius: 16),
            )),
          ],
        ),
      ),
    );
  }
}

/// Progress screen skeleton.
class ProgressScreenSkeleton extends StatelessWidget {
  const ProgressScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const ShimmerBone(width: 120, height: 28),
            const SizedBox(height: 4),
            const ShimmerBone(width: 220, height: 14),
            const SizedBox(height: 28),
            // Stat cards
            Row(
              children: const [
                Expanded(child: ShimmerBone(height: 110, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBone(height: 110, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBone(height: 110, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 28),
            const ShimmerBone(width: 100, height: 18),
            const SizedBox(height: 16),
            const ShimmerBone(height: 200, borderRadius: 16),
            const SizedBox(height: 28),
            const ShimmerBone(width: 130, height: 18),
            const SizedBox(height: 16),
            ...List.generate(4, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBone(height: 70, borderRadius: 14),
            )),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated equalizer bars — decorative element for the Radio screen header.
class EqualizerAnimation extends StatefulWidget {
  final int barCount;
  final double width;
  final double height;
  final Color? color;

  const EqualizerAnimation({
    super.key,
    this.barCount = 5,
    this.width = 40,
    this.height = 24,
    this.color,
  });

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(300)),
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (final c in _controllers) {
      c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.width / (widget.barCount * 2 - 1);
    final color = widget.color ?? AppColors.purple;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i < widget.barCount - 1 ? barWidth : 0),
            child: AnimatedBuilder(
              animation: _animations[i],
              builder: (_, __) {
                return Container(
                  width: barWidth,
                  height: widget.height * _animations[i].value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

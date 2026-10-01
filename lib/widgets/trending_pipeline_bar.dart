// widgets/trending_pipeline_bar.dart — Pipeline status bar (~100 lines)

import 'package:flutter/material.dart';
import '../models/trending.dart';
import '../theme/app_theme.dart';

class TrendingPipelineBar extends StatelessWidget {
  final TrendingPipelineStatus? status;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const TrendingPipelineBar({
    super.key,
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
  });

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'now';
    if (duration.inDays > 0) {
      return '\${duration.inDays}d \${duration.inHours.remainder(24)}h';
    }
    if (duration.inHours > 0) {
      return '\${duration.inHours}h \${duration.inMinutes.remainder(60)}m';
    }
    return '\${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const SizedBox.shrink();
    }

    final hasError = status!.lastError != null;
    final lastRunAgo = status!.lastRunAt != null
        ? DateTime.now().difference(status!.lastRunAt!)
        : null;
    final nextRunIn = status!.nextRunAt != null
        ? status!.nextRunAt!.difference(DateTime.now())
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFE0605A).withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? const Color(0xFFE0605A).withValues(alpha: 0.3)
              : AppColors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot or error icon
          if (status!.isRunning || isRefreshing)
            _PulsingDot(color: AppColors.cyan)
          else if (hasError)
            Icon(Icons.error_outline,
                size: 16, color: const Color(0xFFE0605A))
          else
            Icon(Icons.bolt, size: 16, color: AppColors.purple),
          const SizedBox(width: 8),

          // Status text
          Expanded(
            child: Text(
              _buildStatusText(lastRunAgo, nextRunIn, hasError),
              style: TextStyle(
                color: hasError
                    ? const Color(0xFFE0605A)
                    : AppColors.greyLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Refresh button
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: isRefreshing ? null : onRefresh,
              padding: EdgeInsets.zero,
              icon: isRefreshing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.purple,
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.purple,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildStatusText(
      Duration? lastRunAgo, Duration? nextRunIn, bool hasError) {
    if (status!.isRunning || isRefreshing) {
      return 'AI Pipeline scanning...';
    }
    if (hasError) {
      return 'Pipeline error: \${status!.lastError}';
    }
    final parts = <String>[];
    if (lastRunAgo != null) {
      parts.add('Last scan: \${_formatDuration(lastRunAgo)} ago');
    }
    if (nextRunIn != null) {
      parts.add('Next: \${_formatDuration(nextRunIn)}');
    }
    return parts.join(' · ');
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.4 + (_controller.value * 0.6),
            ),
          ),
        );
      },
    );
  }
}

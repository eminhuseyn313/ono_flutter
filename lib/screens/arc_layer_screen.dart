import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/becoming_arc.dart';
import '../providers/becoming_arc_provider.dart';
import '../theme/app_theme.dart';

/// Detail screen for a single [ArcLayer] within an active arc.
///
/// Displays the layer's progress, a motivational quote, and every step
/// belonging to the layer grouped by day.
class ArcLayerScreen extends StatelessWidget {
  const ArcLayerScreen({
    super.key,
    required this.layer,
    required this.arcId,
  });

  final ArcLayer layer;
  final String arcId;

  static const Map<ArcLayer, String> _quotes = {
    ArcLayer.identity:
        '"Knowing yourself is the beginning of all wisdom." — Aristotle',
    ArcLayer.habit:
        '"We are what we repeatedly do. Excellence is not an act, but a habit." — Will Durant',
    ArcLayer.knowledge:
        '"An investment in knowledge pays the best interest." — Benjamin Franklin',
    ArcLayer.challenge:
        '"A smooth sea never made a skilled sailor." — Franklin D. Roosevelt',
    ArcLayer.reflection:
        '"The unexamined life is not worth living." — Socrates',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BecomingArcProvider>(
        builder: (context, provider, _) {
          final arc = provider.getArc(arcId);
          final progress = provider.getProgress(arcId);

          if (arc == null || progress == null) {
            return const Center(
              child: Text(
                'Arc not found.',
                style: TextStyle(color: AppColors.grey),
              ),
            );
          }

          final layerSteps = arc.stepsForLayer(layer);
          final layerProg = provider.getLayerProgress(arcId, layer);
          final pctString = (layerProg * 100).toStringAsFixed(0);

          // Group steps by day.
          final Map<int, List<ArcStep>> byDay = {};
          for (final step in layerSteps) {
            byDay.putIfAbsent(step.dayNumber, () => []).add(step);
          }
          final sortedDays = byDay.keys.toList()..sort();

          return CustomScrollView(
            slivers: [
              // ----- Header with gradient -----
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          layer.color.withValues(alpha: 0.35),
                          AppColors.background,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji + Name
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: layer.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          layer.color.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    layer.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        layer.label,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$pctString% complete · ${layerSteps.length} steps',
                                        style: TextStyle(
                                          color: layer.color,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: layerProg,
                                minHeight: 8,
                                backgroundColor:
                                    AppColors.white.withValues(alpha: 0.1),
                                valueColor:
                                    AlwaysStoppedAnimation(layer.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ----- Motivational Quote -----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: layer.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: layer.color.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: layer.color.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _quotes[layer] ?? '',
                                style: TextStyle(
                                  color:
                                      AppColors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ----- Layer description -----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    layer.description,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // ----- Steps grouped by day -----
              ...sortedDays.expand((day) {
                final steps = byDay[day]!;
                final isPast = day < progress.currentDay;
                final isCurrent = day == progress.currentDay;
                final isFuture = day > progress.currentDay;

                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? layer.color.withValues(alpha: 0.15)
                                  : AppColors.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent
                                  ? Border.all(
                                      color:
                                          layer.color.withValues(alpha: 0.3),
                                    )
                                  : null,
                            ),
                            child: Text(
                              'Day $day',
                              style: TextStyle(
                                color: isCurrent
                                    ? layer.color
                                    : isPast
                                        ? AppColors.grey
                                        : AppColors.grey.withValues(
                                            alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final step = steps[index];
                        final completed =
                            provider.isStepCompleted(arcId, step.id);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _LayerStepCard(
                            step: step,
                            isCompleted: completed,
                            isDimmed: isFuture && !completed,
                            layerColor: layer.color,
                            onToggle: isFuture && !isPast && !isCurrent
                                ? null
                                : () {
                                    if (!completed) {
                                      HapticFeedback.mediumImpact();
                                      provider.completeStep(
                                        'user_1',
                                        arcId,
                                        step.id,
                                      );
                                    }
                                  },
                          ),
                        );
                      },
                      childCount: steps.length,
                    ),
                  ),
                ];
              }),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Layer Step Card
// =============================================================================

class _LayerStepCard extends StatelessWidget {
  const _LayerStepCard({
    required this.step,
    required this.isCompleted,
    required this.isDimmed,
    required this.layerColor,
    this.onToggle,
  });

  final ArcStep step;
  final bool isCompleted;
  final bool isDimmed;
  final Color layerColor;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final contentAlpha = isDimmed ? 0.4 : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: isDimmed ? 0.3 : 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? layerColor.withValues(alpha: 0.3)
                  : AppColors.divider.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status indicator
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isCompleted ? layerColor : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? layerColor
                              : AppColors.grey.withValues(
                                  alpha: isDimmed ? 0.2 : 0.4),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              color: AppColors.white.withValues(
                                alpha: contentAlpha,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: TextStyle(
                              color: AppColors.grey.withValues(
                                alpha: contentAlpha,
                              ),
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: AppColors.grey.withValues(
                                  alpha: contentAlpha,
                                ),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${step.estimatedDuration.inMinutes} min',
                                style: TextStyle(
                                  color: AppColors.grey.withValues(
                                    alpha: contentAlpha,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 10),
                              ...List.generate(
                                step.difficulty,
                                (_) => Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    Icons.local_fire_department,
                                    color: AppColors.warning.withValues(
                                      alpha: contentAlpha,
                                    ),
                                    size: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/adaptive_engine.dart';
import '../providers/adaptive_engine_provider.dart';
import '../theme/app_theme.dart';

/// Shows per-lane difficulty levels, pending adjustments, history,
/// and auto-adjust toggle.
class AdaptiveSettingsScreen extends StatefulWidget {
  const AdaptiveSettingsScreen({super.key});

  @override
  State<AdaptiveSettingsScreen> createState() => _AdaptiveSettingsScreenState();
}

class _AdaptiveSettingsScreenState extends State<AdaptiveSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdaptiveEngineProvider>().load('current');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Adaptive Difficulty',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<AdaptiveEngineProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.state == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.state == null) {
            return Center(
              child: Text(
                provider.error ?? 'Unable to load adaptive state.',
                style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6)),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // ── Overall level hero ──
              _buildOverallHero(provider),
              const SizedBox(height: 24),

              // ── Auto-adjust toggle ──
              _buildAutoAdjustToggle(provider),
              const SizedBox(height: 24),

              // ── Pending adjustments ──
              if (provider.pendingAdjustments.isNotEmpty) ...[
                _sectionTitle('Recommended Changes'),
                const SizedBox(height: 12),
                ...provider.pendingAdjustments.map(
                    (a) => _buildAdjustmentCard(provider, a)),
                const SizedBox(height: 24),
              ],

              // ── Lane levels ──
              _sectionTitle('Lane Levels'),
              const SizedBox(height: 12),
              ...provider.laneLevels.entries.map(
                  (e) => _buildLaneLevelCard(provider, e.key, e.value)),
              const SizedBox(height: 24),

              // ── Performance snapshot ──
              _sectionTitle('Performance Snapshot'),
              const SizedBox(height: 12),
              ...provider.lanePerformance.entries.map(
                  (e) => _buildPerformanceCard(e.key, e.value)),
              const SizedBox(height: 24),

              // ── History ──
              if (provider.appliedHistory.isNotEmpty) ...[
                _sectionTitle('Recent History'),
                const SizedBox(height: 12),
                ...provider.appliedHistory.take(5).map(_buildHistoryTile),
              ],

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ────────────────────────── Sections ──────────────────────────

  Widget _buildOverallHero(AdaptiveEngineProvider provider) {
    final level = provider.overallLevel;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.15),
            AppColors.cyan.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            level.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Overall Difficulty',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip(
                '${provider.lanesReadyToAdvance}',
                'Ready to advance',
                AppColors.green,
              ),
              const SizedBox(width: 16),
              _statChip(
                '${provider.lanesNeedingHelp}',
                'Needs attention',
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAdjustToggle(AdaptiveEngineProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_fix_high,
            color: provider.autoAdjustEnabled
                ? AppColors.purple
                : AppColors.grey.withValues(alpha: 0.4),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Adjust Difficulty',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Automatically suggest level changes based on your performance.',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: provider.autoAdjustEnabled,
            activeColor: AppColors.purple,
            onChanged: (_) => provider.toggleAutoAdjust(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentCard(
      AdaptiveEngineProvider provider, DifficultyAdjustment adj) {
    final isUp = adj.isIncrease;
    final color = isUp ? AppColors.green : AppColors.warning;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_laneEmoji(adj.lane)} ${_laneLabel(adj.lane)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${adj.currentLevel.label} → ${adj.recommendedLevel.label}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              adj.reason,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.dismissAdjustment(adj),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey,
                      side: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Dismiss',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => provider.applyAdjustment(adj),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(isUp ? 'Level Up' : 'Ease Off',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaneLevelCard(
      AdaptiveEngineProvider provider, String lane, DifficultyLevel level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(_laneEmoji(lane), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _laneLabel(lane),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${level.emoji} ${level.label} · ${level.intensityMultiplier}x intensity',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<DifficultyLevel>(
              icon: Icon(Icons.tune,
                  color: AppColors.grey.withValues(alpha: 0.5), size: 20),
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (newLevel) =>
                  provider.setLaneLevel(lane, newLevel),
              itemBuilder: (_) => DifficultyLevel.values
                  .map((dl) => PopupMenuItem(
                        value: dl,
                        child: Row(
                          children: [
                            Text(dl.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              dl.label,
                              style: TextStyle(
                                color: dl == level
                                    ? AppColors.purple
                                    : AppColors.white,
                                fontWeight: dl == level
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (dl == level) ...[
                              const Spacer(),
                              const Icon(Icons.check,
                                  color: AppColors.purple, size: 18),
                            ],
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String lane, LanePerformance perf) {
    final completionPct = (perf.completionRate * 100).round();
    final scorePct = (perf.averageScore * 100).round();
    Color statusColor;
    String statusText;
    if (perf.isExcelling) {
      statusColor = AppColors.green;
      statusText = 'Excelling';
    } else if (perf.isStruggling) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Struggling';
    } else {
      statusColor = AppColors.grey;
      statusText = 'On Track';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_laneEmoji(lane), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  _laneLabel(lane),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat('$completionPct%', 'Completion'),
                _miniStat('$scorePct%', 'Score'),
                _miniStat('${perf.streakDays}d', 'Streak'),
                _miniStat(
                    '${perf.completedActions}/${perf.totalActions}', 'Actions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(DifficultyAdjustment adj) {
    final isUp = adj.isIncrease;
    final ago = DateTime.now().difference(adj.recommendedAt);
    String timeAgo;
    if (ago.inDays > 0) {
      timeAgo = '${ago.inDays}d ago';
    } else if (ago.inHours > 0) {
      timeAgo = '${ago.inHours}h ago';
    } else {
      timeAgo = '${ago.inMinutes}m ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              color: isUp ? AppColors.green : AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_laneEmoji(adj.lane)} ${_laneLabel(adj.lane)}: '
                '${adj.currentLevel.label} → ${adj.recommendedLevel.label}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              timeAgo,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────── Helpers ──────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.grey.withValues(alpha: 0.6),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  String _laneEmoji(String lane) => switch (lane) {
        'mind' => '🧠',
        'body' => '💪',
        'social' => '👥',
        'skill' => '🎯',
        _ => '📋',
      };

  String _laneLabel(String lane) => switch (lane) {
        'mind' => 'Mind',
        'body' => 'Body',
        'social' => 'Social',
        'skill' => 'Skill',
        _ => lane,
      };
}

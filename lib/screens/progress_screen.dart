import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_actions_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/user_profile_provider.dart';
import '../gateways/actions_gateway.dart';
import '../widgets/shimmer_loading.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  bool _loaded = false;
  List<DayRecord> _weekHistory = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    context.read<ProgressProvider>().loadProgress(userId);

    // Load last 7 days for the chart
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final history = await context
        .read<DailyActionsProvider>()
        .loadHistory(userId, from: weekAgo, to: now);

    if (mounted) {
      setState(() => _weekHistory = history);
    }

    // Fire-and-forget: generate weekly snapshot
    _generateWeeklySnapshot(userId);
  }

  Future<void> _generateWeeklySnapshot(String userId) async {
    try {
      await Supabase.instance.client.functions.invoke('weekly-snapshot');
    } catch (_) {
      // Best-effort — don't block progress screen
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final actions = context.watch<DailyActionsProvider>();
    final profile = context.watch<UserProfileProvider>();
    final streak = actions.streak;
    final laneScores = progress.laneScores;
    final overallScore = progress.overallScore;

    final createdAt = profile.profile?.createdAt;
    final daysActive =
        createdAt != null ? DateTime.now().difference(createdAt).inDays : 0;
    final daysRemaining = (90 - daysActive).clamp(0, 90);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0A1E), Color(0xFF0A0C14), Color(0xFF0A1014)],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: progress.isLoading
                    ? const ProgressScreenSkeleton()
                    : RefreshIndicator(
                        color: AppColors.purple,
                        backgroundColor: AppColors.card,
                        onRefresh: _loadAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The Shift',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Your transformation in numbers',
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 14),
                              ),
                              const SizedBox(height: 28),

                              // Stat cards
                              Row(
                                children: [
                                  _buildStatCard(
                                      '🔥', '$streak', 'Current\nStreak'),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                    '📈',
                                    '${(overallScore * 100).toInt()}%',
                                    'Overall\nScore',
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                      '📅', '$daysActive', 'Days\nActive'),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Weekly completion chart
                              const Text(
                                'This Week',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildWeeklyChart(),
                              const SizedBox(height: 28),

                              // Lane progress
                              const Text(
                                'Lane Progress',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...laneScores.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildLaneProgress(
                                      _laneEmoji(entry.key),
                                      _laneName(entry.key),
                                      entry.value,
                                      _laneColor(entry.key),
                                    ),
                                  )),
                              if (laneScores.isEmpty)
                                _buildGlassCard(
                                  child: const Text(
                                    'Complete your first day to see lane progress here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.grey, fontSize: 14),
                                  ),
                                ),
                              const SizedBox(height: 28),

                              // Strongest / weakest lane callout
                              if (progress.strongestLane != null) ...[
                                _buildGlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '💪  Strongest: ${_laneName(progress.strongestLane!)}',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '🎯  Focus area: ${_laneName(progress.weakestLane!)}',
                                        style: const TextStyle(
                                          color: AppColors.purpleSoft,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                              ],

                              // Weekly review button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  GoRouter.of(context).push('/weekly-review');
                                },
                                child: _buildGlassCard(
                                  borderColor:
                                      AppColors.purple.withValues(alpha: 0.3),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.purple
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Text('📊',
                                              style:
                                                  TextStyle(fontSize: 22)),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Weekly Review',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'See your full weekly breakdown',
                                              style: TextStyle(
                                                color: AppColors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          color: AppColors.grey, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Days counter
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.purple
                                              .withValues(alpha: 0.2),
                                          AppColors.card
                                              .withValues(alpha: 0.5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.purple
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$daysActive',
                                          style: const TextStyle(
                                            color: AppColors.purple,
                                            fontSize: 64,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const Text(
                                          'days into your transformation',
                                          style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$daysRemaining days until Version 2.0',
                                          style: const TextStyle(
                                            color: AppColors.purpleSoft,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Glass card helper ─────────────────────────────────────────────────

  Widget _buildGlassCard({required Widget child, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? AppColors.divider),
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Weekly chart ──────────────────────────────────────────────────────

  Widget _buildWeeklyChart() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: _weekHistory.isEmpty
              ? const Center(
                  child: Text(
                    'Complete actions to see your weekly trend',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: AppColors.purple,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        tooltipMargin: 6,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final record = _weekHistory[group.x.toInt()];
                          return BarTooltipItem(
                            '${record.completedCount}/${record.totalCount}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= _weekHistory.length) {
                              return const SizedBox.shrink();
                            }
                            final weekday =
                                _weekHistory[idx].date.weekday; // 1=Mon
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayLabels[weekday - 1],
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: List.generate(_weekHistory.length, (i) {
                      final record = _weekHistory[i];
                      final rate = record.completionRate;
                      final isToday = i == _weekHistory.length - 1;

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: rate > 0 ? rate : 0.03, // min visible bar
                            color: record.totalCount == 0
                                ? AppColors.divider
                                : rate >= 1.0
                                    ? AppColors.purple
                                    : isToday
                                        ? AppColors.purpleSoft
                                        : AppColors.purple
                                            .withValues(alpha: 0.5),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaneProgress(
      String emoji, String name, double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value.clamp(0.0, 1.0),
                        backgroundColor:
                            AppColors.divider.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _laneColor(String lane) {
    switch (lane) {
      case 'mind':
        return AppColors.purple;
      case 'body':
        return AppColors.green;
      case 'social':
        return AppColors.warning;
      case 'skill':
        return AppColors.cyan;
      default:
        return AppColors.purple;
    }
  }

  String _laneEmoji(String lane) {
    switch (lane) {
      case 'mind':
        return '🧠';
      case 'body':
        return '💪';
      case 'social':
        return '🗣';
      case 'skill':
        return '📚';
      default:
        return '⚡';
    }
  }

  String _laneName(String lane) {
    switch (lane) {
      case 'mind':
        return 'Mind';
      case 'body':
        return 'Body';
      case 'social':
        return 'Social';
      case 'skill':
        return 'Skill';
      default:
        return lane[0].toUpperCase() + lane.substring(1);
    }
  }
}

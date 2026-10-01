import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_actions_provider.dart';
import '../providers/progress_provider.dart';
import '../gateways/actions_gateway.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen>
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
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    context.read<ProgressProvider>().loadProgress(userId);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final history = await context
        .read<DailyActionsProvider>()
        .loadHistory(userId, from: weekAgo, to: now);

    if (mounted) {
      setState(() => _weekHistory = history);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _weekRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[start.month]} ${start.day} – ${months[now.month]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final actions = context.watch<DailyActionsProvider>();
    final laneScores = progress.laneScores;
    final overallScore = progress.overallScore;
    final streak = actions.streak;

    // Find best day
    String bestDay = '—';
    double bestRate = 0;
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final record in _weekHistory) {
      if (record.completionRate > bestRate) {
        bestRate = record.completionRate;
        bestDay = dayNames[record.date.weekday - 1];
      }
    }

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
              bottom: 50,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(),
                      const SizedBox(height: 8),
                      Text(
                        _weekRange(),
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildOverallScore(overallScore),
                      const SizedBox(height: 28),
                      _buildWeeklyChart(),
                      const SizedBox(height: 28),
                      _buildLaneBreakdown(laneScores),
                      const SizedBox(height: 28),
                      _buildInsights(
                        bestDay: bestDay,
                        bestRate: bestRate,
                        strongest: progress.strongestLane,
                        weakest: progress.weakestLane,
                        streak: streak,
                      ),
                      const SizedBox(height: 28),
                      _buildMotivation(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.greyLight, size: 16),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Weekly Review',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScore(double score) {
    final percent = (score * 100).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withValues(alpha: 0.15),
                AppColors.card.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'Overall Score',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: score.clamp(0, 1),
                        strokeWidth: 8,
                        backgroundColor:
                            AppColors.divider.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.purple),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: percent),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => Text(
                        '$val%',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                score >= 0.8
                    ? 'Outstanding week! 🔥'
                    : score >= 0.5
                        ? 'Solid progress! 💪'
                        : 'Room to grow 🌱',
                style: const TextStyle(
                  color: AppColors.purpleSoft,
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

  Widget _buildWeeklyChart() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Completion',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
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
                        'No data for this week yet',
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
                            getTooltipItem: (group, gi, rod, ri) {
                              final rec = _weekHistory[group.x.toInt()];
                              return BarTooltipItem(
                                '${rec.completedCount}/${rec.totalCount}',
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
                                final wd = _weekHistory[idx].date.weekday;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayLabels[wd - 1],
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
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups:
                            List.generate(_weekHistory.length, (i) {
                          final rec = _weekHistory[i];
                          final rate = rec.completionRate;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: rate > 0 ? rate : 0.03,
                                color: rec.totalCount == 0
                                    ? AppColors.divider
                                    : rate >= 1.0
                                        ? AppColors.green
                                        : AppColors.purple
                                            .withValues(alpha: 0.7),
                                width: 24,
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
        ),
      ],
    );
  }

  Widget _buildLaneBreakdown(Map<String, double> laneScores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lane Breakdown',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildLaneCard('🧠', 'Mind', laneScores['mind'] ?? 0, AppColors.purple),
            const SizedBox(width: 12),
            _buildLaneCard('💪', 'Body', laneScores['body'] ?? 0, AppColors.green),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLaneCard('🗣', 'Social', laneScores['social'] ?? 0, AppColors.warning),
            const SizedBox(width: 12),
            _buildLaneCard('📚', 'Skill', laneScores['skill'] ?? 0, AppColors.cyan),
          ],
        ),
      ],
    );
  }

  Widget _buildLaneCard(String emoji, String name, double score, Color color) {
    final percent = (score * 100).toInt();
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsights({
    required String bestDay,
    required double bestRate,
    String? strongest,
    String? weakest,
    required int streak,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insights',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          '📅',
          'Best Day',
          bestRate > 0 ? '$bestDay — ${(bestRate * 100).toInt()}% completion' : 'Not enough data yet',
          AppColors.green,
        ),
        const SizedBox(height: 12),
        if (strongest != null) ...[
          _buildInsightCard(
            '💪',
            'Strongest Lane',
            _laneName(strongest),
            AppColors.purple,
          ),
          const SizedBox(height: 12),
        ],
        if (weakest != null) ...[
          _buildInsightCard(
            '🎯',
            'Focus Area',
            '${_laneName(weakest)} — needs more attention',
            AppColors.warning,
          ),
          const SizedBox(height: 12),
        ],
        _buildInsightCard(
          '🔥',
          'Streak',
          streak > 0 ? '$streak day${streak == 1 ? '' : 's'} and counting!' : 'Start your streak today',
          AppColors.cyan,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String emoji, String title, String detail, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.8),
                        fontSize: 13,
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

  Widget _buildMotivation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withValues(alpha: 0.12),
                AppColors.cyan.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.2)),
          ),
          child: const Column(
            children: [
              Text('💭', style: TextStyle(fontSize: 32)),
              SizedBox(height: 12),
              Text(
                '"Small daily improvements over time\nlead to stunning results."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '— Robin Sharma',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _laneName(String lane) {
    switch (lane) {
      case 'mind':
        return 'Mind 🧠';
      case 'body':
        return 'Body 💪';
      case 'social':
        return 'Social 🗣';
      case 'skill':
        return 'Skill 📚';
      default:
        return lane[0].toUpperCase() + lane.substring(1);
    }
  }
}

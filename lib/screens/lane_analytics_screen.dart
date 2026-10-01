import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

/// Deep-dive analytics for a single lane: 7-day trend line, 30-day bar
/// chart, and insight cards.
///
/// Pass the lane name via the constructor or as extra in GoRouter.
class LaneAnalyticsScreen extends StatefulWidget {
  final String? laneName;
  const LaneAnalyticsScreen({super.key, this.laneName});

  @override
  State<LaneAnalyticsScreen> createState() => _LaneAnalyticsScreenState();
}

class _LaneAnalyticsScreenState extends State<LaneAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  final _lanes = [
    _Lane('Mind', '🧠', AppColors.purple),
    _Lane('Body', '💪', AppColors.green),
    _Lane('Social', '🗣', const Color(0xFFD9774A)),
    _Lane('Skill', '📚', AppColors.cyan),
  ];

  int _selectedLane = 0;
  List<double> _weekData = List.filled(7, 0);
  List<double> _monthData = List.filled(30, 0);
  int _totalActions = 0;
  int _bestDay = 0;
  double _avgPerDay = 0;

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

    // If a lane name is passed, select it
    if (widget.laneName != null) {
      final idx =
          _lanes.indexWhere((l) => l.name.toLowerCase() == widget.laneName!.toLowerCase());
      if (idx >= 0) _selectedLane = idx;
    }

    _loadData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final lane = _lanes[_selectedLane].name.toLowerCase();
    final raw = prefs.getString('lane_analytics_$lane');

    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final dailyMap =
          (decoded['daily'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {};

      // Build week data (last 7 days)
      final today = DateTime.now();
      _weekData = List.generate(7, (i) {
        final d = today.subtract(Duration(days: 6 - i));
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        return dailyMap[key] ?? 0;
      });

      // Build month data (last 30 days)
      _monthData = List.generate(30, (i) {
        final d = today.subtract(Duration(days: 29 - i));
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        return dailyMap[key] ?? 0;
      });
    } else {
      // Demo data for first-time view
      final rng = Random(42 + _selectedLane);
      _weekData = List.generate(7, (_) => rng.nextInt(5).toDouble());
      _monthData = List.generate(30, (_) => rng.nextInt(6).toDouble());
    }

    _totalActions = _monthData.fold(0, (a, b) => a + b.toInt());
    _bestDay = _monthData.reduce(max).toInt();
    _avgPerDay = _totalActions / 30;

    if (mounted) setState(() {});
  }

  void _selectLane(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLane = index);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final lane = _lanes[_selectedLane];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111214), Color(0xFF0C0D0F), Color(0xFF0E1012)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildLaneSelector(),
                  const SizedBox(height: 28),
                  _buildSummaryCards(lane),
                  const SizedBox(height: 28),
                  _buildSectionTitle('7-Day Trend'),
                  const SizedBox(height: 16),
                  _buildWeekChart(lane),
                  const SizedBox(height: 28),
                  _buildSectionTitle('30-Day Activity'),
                  const SizedBox(height: 16),
                  _buildMonthChart(lane),
                  const SizedBox(height: 28),
                  _buildInsightCards(lane),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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
          'Lane Analytics',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildLaneSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_lanes.length, (i) {
          final lane = _lanes[i];
          final selected = i == _selectedLane;
          return GestureDetector(
            onTap: () => _selectLane(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < _lanes.length - 1 ? 10 : 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? lane.color.withValues(alpha: 0.15)
                    : AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? lane.color.withValues(alpha: 0.5)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lane.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    lane.name,
                    style: TextStyle(
                      color: selected ? lane.color : AppColors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(_Lane lane) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Total Actions',
          value: '$_totalActions',
          color: lane.color,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: 'Best Day',
          value: '$_bestDay',
          color: lane.color,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: 'Avg / Day',
          value: _avgPerDay.toStringAsFixed(1),
          color: lane.color,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildWeekChart(_Lane lane) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = (_weekData.reduce(max) + 1).ceilToDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      return Text(
                        days[i],
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      7, (i) => FlSpot(i.toDouble(), _weekData[i])),
                  isCurved: true,
                  color: lane.color,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: lane.color,
                      strokeColor: AppColors.background,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lane.color.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthChart(_Lane lane) {
    final maxY = (_monthData.reduce(max) + 1).ceilToDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i % 7 != 0) return const SizedBox();
                      return Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: maxY,
              barGroups: List.generate(30, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: _monthData[i],
                      color: lane.color.withValues(alpha: 0.7),
                      width: 6,
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildInsightCards(_Lane lane) {
    final insights = <_InsightData>[];

    if (_avgPerDay >= 3) {
      insights.add(_InsightData(
        icon: Icons.trending_up_rounded,
        title: 'Crushing it!',
        body: 'You\'re averaging ${_avgPerDay.toStringAsFixed(1)} actions per day in ${lane.name}.',
        color: AppColors.green,
      ));
    } else if (_avgPerDay >= 1) {
      insights.add(_InsightData(
        icon: Icons.auto_awesome_rounded,
        title: 'Building momentum',
        body: 'Consistent effort in ${lane.name}. Try adding one more action daily.',
        color: AppColors.cyan,
      ));
    } else {
      insights.add(_InsightData(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Room to grow',
        body: '${lane.name} could use more attention. Start with one small action.',
        color: AppColors.warning,
      ));
    }

    if (_bestDay >= 5) {
      insights.add(_InsightData(
        icon: Icons.emoji_events_rounded,
        title: 'Peak day: $_bestDay actions',
        body: 'You\'ve shown you can go deep. Aim for that intensity again.',
        color: lane.color,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Insights'),
        const SizedBox(height: 12),
        ...insights.map((ins) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ins.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: ins.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(ins.icon, color: ins.color, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ins.title,
                                style: TextStyle(
                                  color: ins.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ins.body,
                                style: TextStyle(
                                  color: AppColors.grey.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _Lane {
  final String name;
  final String emoji;
  final Color color;
  const _Lane(this.name, this.emoji, this.color);
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightData {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _InsightData({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

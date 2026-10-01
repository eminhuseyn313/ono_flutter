import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// A GitHub-style contribution heat map showing daily action completion.
///
/// Data is stored in SharedPreferences under key `heat_map_data` as a
/// JSON map of `"yyyy-MM-dd" → int` (actions completed that day).
class HabitHeatMapScreen extends StatefulWidget {
  const HabitHeatMapScreen({super.key});

  @override
  State<HabitHeatMapScreen> createState() => _HabitHeatMapScreenState();
}

class _HabitHeatMapScreenState extends State<HabitHeatMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  Map<String, int> _data = {};
  DateTime _viewMonth = DateTime.now();
  String? _selectedDay;
  int _totalDays = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;

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
    final raw = prefs.getString('heat_map_data');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _data = decoded.map((k, v) => MapEntry(k, v as int));
    }
    _computeStats();
    if (mounted) setState(() {});
  }

  void _computeStats() {
    _totalDays = _data.values.where((v) => v > 0).length;

    // Streak calculations
    final today = DateTime.now();
    int current = 0;
    int longest = 0;
    int running = 0;

    // Sort dates and walk backwards from today
    final sortedDates = _data.keys.toList()..sort();
    final dateSet = <String>{};
    for (final d in sortedDates) {
      if ((_data[d] ?? 0) > 0) dateSet.add(d);
    }

    // Current streak
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = _dateKey(d);
      if (dateSet.contains(key)) {
        current++;
      } else {
        break;
      }
    }

    // Longest streak
    for (final d in sortedDates) {
      if (dateSet.contains(d)) {
        running++;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
    }

    _currentStreak = current;
    _longestStreak = longest;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _colorForCount(int count) {
    if (count == 0) return AppColors.card.withValues(alpha: 0.6);
    if (count == 1) return AppColors.green.withValues(alpha: 0.2);
    if (count == 2) return AppColors.green.withValues(alpha: 0.35);
    if (count == 3) return AppColors.green.withValues(alpha: 0.5);
    if (count == 4) return AppColors.green.withValues(alpha: 0.7);
    return AppColors.green; // 5+
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
      _selectedDay = null;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 28),
                  _buildStats(),
                  const SizedBox(height: 28),
                  _buildMonthNav(),
                  const SizedBox(height: 16),
                  _buildGrid(),
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 20),
                    _buildDayDetail(),
                  ],
                  const SizedBox(height: 20),
                  _buildLegend(),
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
          'Habit Heat Map',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(
          label: 'Active Days',
          value: '$_totalDays',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.green,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Current Streak',
          value: '$_currentStreak',
          icon: Icons.bolt_rounded,
          color: AppColors.cyan,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Longest Streak',
          value: '$_longestStreak',
          icon: Icons.emoji_events_rounded,
          color: AppColors.purple,
        ),
      ],
    );
  }

  Widget _buildMonthNav() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _changeMonth(-1),
          child: const Icon(Icons.chevron_left_rounded,
              color: AppColors.grey, size: 28),
        ),
        Text(
          '${months[_viewMonth.month - 1]} ${_viewMonth.year}',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () => _changeMonth(1),
          child: const Icon(Icons.chevron_right_rounded,
              color: AppColors.grey, size: 28),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun = 0

    final cells = <Widget>[];

    // Day-of-week headers
    for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(Center(
        child: Text(
          d,
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ));
    }

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month, day);
      final key = _dateKey(date);
      final count = _data[key] ?? 0;
      final isSelected = _selectedDay == key;
      final isToday = _dateKey(DateTime.now()) == key;

      cells.add(GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedDay = _selectedDay == key ? null : key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _colorForCount(count),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? AppColors.green
                  : isToday
                      ? AppColors.purple.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: count > 2
                    ? AppColors.white
                    : AppColors.grey.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetail() {
    final count = _data[_selectedDay] ?? 0;
    // Parse the date for display
    final parts = _selectedDay!.split('-');
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final display = '${months[int.parse(parts[1])]} ${int.parse(parts[2])}, ${parts[0]}';

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
                  color: _colorForCount(count),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    count > 0 ? '✓' : '—',
                    style: TextStyle(
                      color: count > 0 ? AppColors.white : AppColors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count > 0
                          ? '$count action${count == 1 ? '' : 's'} completed'
                          : 'No actions completed',
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        for (int i = 0; i <= 5; i++) ...[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _colorForCount(i),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          'More',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.7),
                    fontSize: 10,
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

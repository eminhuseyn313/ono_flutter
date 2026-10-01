import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/habit_streak_provider.dart';
import '../widgets/streak_flame_card.dart';
import '../widgets/streak_calendar.dart';

class HabitStreakScreen extends StatefulWidget {
  const HabitStreakScreen({super.key});

  @override
  State<HabitStreakScreen> createState() => _HabitStreakScreenState();
}

class _HabitStreakScreenState extends State<HabitStreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitStreakProvider>().loadData();
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
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Streak Tracker',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<HabitStreakProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.streakData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.streakData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: const Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load streak data',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.loadData(),
                    child: Text('Retry',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.purple)),
                  ),
                ],
              ),
            );
          }

          final data = provider.streakData!;
          final streak = data.streak;

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flame card
                  StreakFlameCard(
                    currentStreak: streak.currentStreak,
                    longestStreak: streak.longestStreak,
                  ),

                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('Current', '${streak.currentStreak}',
                              AppColors.green)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _statCard('Longest', '${streak.longestStreak}',
                              AppColors.cyan)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _statCard('Active Days',
                              '${streak.totalActiveDays}', AppColors.purple)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _statCard(
                              'Avg/Day',
                              streak.averageActionsPerDay.toStringAsFixed(1),
                              AppColors.warning)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Lane streaks
                  Text(
                    'Lane Streaks',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _laneStreakCard(
                              'Mind',
                              streak.laneStreaks['Mind'] ?? 0,
                              AppColors.purple,
                              Icons.psychology)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _laneStreakCard(
                              'Body',
                              streak.laneStreaks['Body'] ?? 0,
                              AppColors.cyan,
                              Icons.fitness_center)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _laneStreakCard(
                              'Social',
                              streak.laneStreaks['Social'] ?? 0,
                              AppColors.green,
                              Icons.people)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _laneStreakCard(
                              'Skill',
                              streak.laneStreaks['Skill'] ?? 0,
                              AppColors.warning,
                              Icons.auto_awesome)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Calendar heat map
                  Text(
                    'Activity Map',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: StreakCalendar(days: data.calendarDays),
                  ),

                  const SizedBox(height: 24),

                  // Freeze tokens
                  Text(
                    'Freeze Tokens',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.ac_unit, color: AppColors.cyan, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.freezeTokensAvailable} tokens available',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Protect your streak on rest days',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: data.freezeTokensAvailable > 0
                              ? () {
                                  provider.useFreezeToken(
                                      DateTime.now().toIso8601String());
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                            foregroundColor: AppColors.cyan,
                            disabledBackgroundColor:
                                AppColors.cardLight,
                            disabledForegroundColor: AppColors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Use',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Milestones
                  Text(
                    'Milestones',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.milestones.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final milestone = data.milestones[index];
                        return _milestoneCard(milestone);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _laneStreakCard(String name, int days, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$days',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard(milestone) {
    final color = milestone.isReached ? AppColors.green : AppColors.grey;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: milestone.isReached
            ? AppColors.green.withValues(alpha: 0.1)
            : AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: milestone.isReached ? 0.4 : 0.15),
        ),
        boxShadow: milestone.isReached
            ? [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconData(milestone.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: color,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            '${milestone.days}d',
            style: GoogleFonts.plusJakartaSans(
              color: milestone.isReached ? AppColors.white : AppColors.grey,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            milestone.title,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.grey,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

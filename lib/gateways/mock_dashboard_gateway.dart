import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import 'dashboard_gateway.dart';

/// Mock implementation of [DashboardGateway] for development and testing.
/// Returns rich, realistic mock data with simulated network delays.
class MockDashboardGateway implements DashboardGateway {
  @override
  Future<DashboardSummary> loadDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return DashboardSummary(
      greeting: greeting,
      todayDate: now,
      streakDays: 14,
      totalXp: 2340,
      level: 5,
      levelTitle: 'Warrior',
      progressToNext: 0.68,
      todayTasksCompleted: 6,
      todayTasksTotal: 10,
      weeklyScore: 74,
      motivationalQuote:
          'The only way to do great work is to love what you do.',
      quoteAuthor: 'Steve Jobs',
    );
  }

  @override
  Future<List<QuickAccessItem>> loadQuickAccessItems() async {
    await Future.delayed(const Duration(milliseconds: 180));

    return [
      QuickAccessItem(
        id: 'qa_planner',
        title: 'Daily Planner',
        subtitle: 'Plan your conquest',
        iconCodePoint: Icons.calendar_today_rounded.codePoint,
        route: '/planner',
        colorValue: 0xFF8B5CF6,
        badgeCount: 3,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_vision',
        title: 'Vision Board',
        subtitle: 'Visualize your future',
        iconCodePoint: Icons.visibility_rounded.codePoint,
        route: '/vision-board',
        colorValue: 0xFF8B5CF6,
        badgeCount: 0,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_rankings',
        title: 'Power Rankings',
        subtitle: 'Track your standing',
        iconCodePoint: Icons.leaderboard_rounded.codePoint,
        route: '/power-rankings',
        colorValue: 0xFFF59E0B,
        badgeCount: 0,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_vault',
        title: 'The Vault',
        subtitle: 'Journal your journey',
        iconCodePoint: Icons.lock_rounded.codePoint,
        route: '/vault',
        colorValue: 0xFF8B5CF6,
        badgeCount: 0,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_gamification',
        title: 'Gamification Hub',
        subtitle: 'Earn XP & rewards',
        iconCodePoint: Icons.emoji_events_rounded.codePoint,
        route: '/gamification',
        colorValue: 0xFFF59E0B,
        badgeCount: 2,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_accountability',
        title: 'Accountability',
        subtitle: 'Your battle partners',
        iconCodePoint: Icons.handshake_rounded.codePoint,
        route: '/accountability',
        colorValue: 0xFF34D399,
        badgeCount: 1,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_forge',
        title: 'The Forge',
        subtitle: 'Level up your skills',
        iconCodePoint: Icons.local_fire_department_rounded.codePoint,
        route: '/forge',
        colorValue: 0xFFF59E0B,
        badgeCount: 0,
        isNew: true,
      ),
      QuickAccessItem(
        id: 'qa_council',
        title: 'The Council',
        subtitle: 'AI mentor wisdom',
        iconCodePoint: Icons.psychology_rounded.codePoint,
        route: '/council',
        colorValue: 0xFF8B5CF6,
        badgeCount: 0,
        isNew: true,
      ),
      QuickAccessItem(
        id: 'qa_ghost',
        title: 'Ghost Mode',
        subtitle: 'Deep focus sessions',
        iconCodePoint: Icons.visibility_off_rounded.codePoint,
        route: '/ghost-mode',
        colorValue: 0xFF22D3EE,
        badgeCount: 0,
        isNew: false,
      ),
      QuickAccessItem(
        id: 'qa_brotherhood',
        title: 'Brotherhood',
        subtitle: 'Join the community',
        iconCodePoint: Icons.groups_rounded.codePoint,
        route: '/brotherhood',
        colorValue: 0xFF34D399,
        badgeCount: 5,
        isNew: false,
      ),
    ];
  }

  @override
  Future<List<DailyHighlight>> loadDailyHighlights() async {
    await Future.delayed(const Duration(milliseconds: 150));

    return [
      DailyHighlight(
        id: 'hl_streak',
        type: 'streak',
        title: '14-Day Streak!',
        description: 'You\'re on fire! Keep the momentum going to hit 21 days.',
        iconCodePoint: Icons.local_fire_department_rounded.codePoint,
        colorValue: 0xFFF59E0B,
        actionRoute: '/gamification',
      ),
      DailyHighlight(
        id: 'hl_levelup',
        type: 'levelUp',
        title: 'Level 6 is Close',
        description:
            'Only 660 XP to reach Gladiator rank. Complete today\'s tasks!',
        iconCodePoint: Icons.arrow_upward_rounded.codePoint,
        colorValue: 0xFF8B5CF6,
        actionRoute: '/gamification',
      ),
      DailyHighlight(
        id: 'hl_milestone',
        type: 'milestone',
        title: 'First Vision Board',
        description:
            'You created your vision board yesterday. Review it daily for impact.',
        iconCodePoint: Icons.star_rounded.codePoint,
        colorValue: 0xFF34D399,
        actionRoute: '/vision-board',
      ),
      DailyHighlight(
        id: 'hl_reminder',
        type: 'reminder',
        title: 'Evening Reflection',
        description:
            'Don\'t forget to journal in The Vault before bed tonight.',
        iconCodePoint: Icons.edit_note_rounded.codePoint,
        colorValue: 0xFF22D3EE,
        actionRoute: '/vault',
      ),
    ];
  }

  @override
  Future<List<LaneSummary>> loadLaneSummaries() async {
    await Future.delayed(const Duration(milliseconds: 170));

    return const [
      LaneSummary(
        lane: 'Mind',
        score: 82,
        trend: 'up',
        tasksToday: 3,
        colorValue: 0xFF8B5CF6,
      ),
      LaneSummary(
        lane: 'Body',
        score: 65,
        trend: 'stable',
        tasksToday: 2,
        colorValue: 0xFF22D3EE,
      ),
      LaneSummary(
        lane: 'Social',
        score: 71,
        trend: 'up',
        tasksToday: 3,
        colorValue: 0xFF34D399,
      ),
      LaneSummary(
        lane: 'Skill',
        score: 58,
        trend: 'down',
        tasksToday: 2,
        colorValue: 0xFFF59E0B,
      ),
    ];
  }
}

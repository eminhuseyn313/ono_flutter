import '../models/dashboard.dart';

/// Abstract gateway for dashboard data operations.
/// Implementations can be mock (for development) or Supabase (for production).
abstract class DashboardGateway {
  /// Loads the overall dashboard summary including XP, streak, tasks, and quote.
  Future<DashboardSummary> loadDashboardSummary();

  /// Loads the list of quick access feature items for the grid.
  Future<List<QuickAccessItem>> loadQuickAccessItems();

  /// Loads daily highlights such as streaks, level ups, and reminders.
  Future<List<DailyHighlight>> loadDailyHighlights();

  /// Loads the summary for each life lane (Mind, Body, Social, Skill).
  Future<List<LaneSummary>> loadLaneSummaries();
}

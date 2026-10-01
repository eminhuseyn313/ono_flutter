import 'package:flutter/foundation.dart';

import '../gateways/dashboard_gateway.dart';
import '../models/dashboard.dart';

/// Provider for dashboard state management.
/// Loads and exposes all dashboard data sections via [DashboardGateway].
class DashboardProvider extends ChangeNotifier {
  final DashboardGateway _gateway;

  DashboardProvider({required DashboardGateway gateway}) : _gateway = gateway;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  DashboardSummary? _summary;
  List<QuickAccessItem> _quickAccessItems = [];
  List<DailyHighlight> _highlights = [];
  List<LaneSummary> _laneSummaries = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  DashboardSummary? get summary => _summary;
  List<QuickAccessItem> get quickAccessItems =>
      List.unmodifiable(_quickAccessItems);
  List<DailyHighlight> get highlights => List.unmodifiable(_highlights);
  List<LaneSummary> get laneSummaries => List.unmodifiable(_laneSummaries);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _summary != null;

  /// Convenience: the task completion ratio as a 0-1 double.
  double get taskCompletionRatio {
    if (_summary == null || _summary!.todayTasksTotal == 0) return 0.0;
    return _summary!.todayTasksCompleted / _summary!.todayTasksTotal;
  }

  /// Convenience: formatted task string e.g. "6/10".
  String get taskProgressLabel {
    if (_summary == null) return '0/0';
    return '${_summary!.todayTasksCompleted}/${_summary!.todayTasksTotal}';
  }

  /// Convenience: percentage label e.g. "60%".
  String get taskPercentageLabel {
    return '${(taskCompletionRatio * 100).round()}%';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads all dashboard data sections in parallel.
  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadDashboardSummary(),
        _gateway.loadQuickAccessItems(),
        _gateway.loadDailyHighlights(),
        _gateway.loadLaneSummaries(),
      ]);

      _summary = results[0] as DashboardSummary;
      _quickAccessItems = results[1] as List<QuickAccessItem>;
      _highlights = results[2] as List<DailyHighlight>;
      _laneSummaries = results[3] as List<LaneSummary>;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes only the summary section (lighter than full reload).
  Future<void> refreshSummary() async {
    try {
      _summary = await _gateway.loadDashboardSummary();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh summary: $e');
    }
  }

  /// Full refresh — reloads all data. Suitable for pull-to-refresh.
  Future<void> refresh() async {
    _errorMessage = null;
    // Don't set _isLoading to true for refresh — keeps existing data visible.
    try {
      final results = await Future.wait([
        _gateway.loadDashboardSummary(),
        _gateway.loadQuickAccessItems(),
        _gateway.loadDailyHighlights(),
        _gateway.loadLaneSummaries(),
      ]);

      _summary = results[0] as DashboardSummary;
      _quickAccessItems = results[1] as List<QuickAccessItem>;
      _highlights = results[2] as List<DailyHighlight>;
      _laneSummaries = results[3] as List<LaneSummary>;
    } catch (e) {
      _errorMessage = 'Failed to refresh dashboard: $e';
      debugPrint(_errorMessage);
    } finally {
      notifyListeners();
    }
  }

  /// Clears all loaded data (e.g. on logout).
  void clear() {
    _summary = null;
    _quickAccessItems = [];
    _highlights = [];
    _laneSummaries = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../gateways/vision_board_gateway.dart';
import '../models/vision_board.dart';

class VisionBoardProvider extends ChangeNotifier {
  final VisionBoardGateway gateway;

  VisionBoardProvider({required this.gateway});

  List<VisionGoal> _goals = [];
  List<VisionGoal> get goals => _filteredGoals;

  List<VisionGoal> get allGoals => List.unmodifiable(_goals);

  VisionBoardStats _stats = const VisionBoardStats();
  VisionBoardStats get stats => _stats;

  List<VisionSnapshot> _snapshots = [];
  List<VisionSnapshot> get snapshots => List.unmodifiable(_snapshots);

  List<VisionQuote> _quotes = [];
  List<VisionQuote> get quotes => List.unmodifiable(_quotes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VisionCategory? _selectedCategory;
  VisionCategory? get selectedCategory => _selectedCategory;

  GoalStatus? _selectedStatus;
  GoalStatus? get selectedStatus => _selectedStatus;

  GoalTimeframe? _selectedTimeframe;
  GoalTimeframe? get selectedTimeframe => _selectedTimeframe;

  List<VisionGoal> get _filteredGoals {
    var filtered = List<VisionGoal>.from(_goals);

    if (_selectedCategory != null) {
      filtered =
          filtered.where((g) => g.category == _selectedCategory).toList();
    }

    if (_selectedStatus != null) {
      filtered =
          filtered.where((g) => g.status == _selectedStatus).toList();
    }

    if (_selectedTimeframe != null) {
      filtered =
          filtered.where((g) => g.timeframe == _selectedTimeframe).toList();
    }

    return List.unmodifiable(filtered);
  }

  void setSelectedCategory(VisionCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedStatus(GoalStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSelectedTimeframe(GoalTimeframe? timeframe) {
    _selectedTimeframe = timeframe;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedStatus = null;
    _selectedTimeframe = null;
    notifyListeners();
  }

  Future<void> loadGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = List.from(await gateway.getGoals());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load goals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(VisionGoal goal) async {
    try {
      await gateway.saveGoal(goal);
      _goals.add(goal);
      notifyListeners();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to add goal: $e';
      notifyListeners();
    }
  }

  Future<void> updateGoal(VisionGoal goal) async {
    try {
      await gateway.saveGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index >= 0) {
        _goals[index] = goal;
      }
      notifyListeners();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to update goal: $e';
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await gateway.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to delete goal: $e';
      notifyListeners();
    }
  }

  Future<void> toggleMilestone(
    String goalId,
    String milestoneId,
    bool isCompleted,
  ) async {
    try {
      await gateway.updateMilestone(goalId, milestoneId, isCompleted);
      final goalIndex = _goals.indexWhere((g) => g.id == goalId);
      if (goalIndex >= 0) {
        final goal = _goals[goalIndex];
        final updatedMilestones = goal.milestones.map((m) {
          if (m.id == milestoneId) {
            return m.copyWith(
              isCompleted: isCompleted,
              completedAt: isCompleted ? DateTime.now() : null,
            );
          }
          return m;
        }).toList();

        final completedCount =
            updatedMilestones.where((m) => m.isCompleted).length;
        final newProgress = updatedMilestones.isNotEmpty
            ? completedCount / updatedMilestones.length
            : 0.0;

        _goals[goalIndex] = goal.copyWith(
          milestones: updatedMilestones,
          progress: newProgress,
          status: newProgress >= 1.0
              ? GoalStatus.achieved
              : newProgress > 0
                  ? GoalStatus.in_progress
                  : GoalStatus.not_started,
          achievedAt: newProgress >= 1.0 ? DateTime.now() : null,
        );
      }
      notifyListeners();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to update milestone: $e';
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await gateway.getStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stats: $e';
      notifyListeners();
    }
  }

  Future<void> loadSnapshots() async {
    try {
      _snapshots = List.from(await gateway.getSnapshots());
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load snapshots: $e';
      notifyListeners();
    }
  }

  Future<void> loadQuotes() async {
    try {
      _quotes = List.from(await gateway.getQuotes());
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load quotes: $e';
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        gateway.getGoals(),
        gateway.getStats(),
        gateway.getSnapshots(),
        gateway.getQuotes(),
      ]);

      _goals = List.from(results[0] as List<VisionGoal>);
      _stats = results[1] as VisionBoardStats;
      _snapshots = List.from(results[2] as List<VisionSnapshot>);
      _quotes = List.from(results[3] as List<VisionQuote>);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load vision board: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  int get goalCountForCategory {
    if (_selectedCategory == null) return _goals.length;
    return _goals.where((g) => g.category == _selectedCategory).length;
  }
}

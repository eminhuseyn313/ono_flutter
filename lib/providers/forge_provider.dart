// providers/forge_provider.dart — Forge Provider v2

import 'package:flutter/foundation.dart';
import '../models/forge.dart';
import '../gateways/forge_gateway.dart';

enum ForgeSortOption { recommended, newest, rating, difficulty }

class ForgeProvider extends ChangeNotifier {
  final ForgeGateway _gateway;

  ForgeProvider({required ForgeGateway gateway}) : _gateway = gateway;

  // ── v1 state ──
  List<ForgeCourse> _courses = [];
  List<ForgeCourse> _allCourses = [];
  ForgeProgress? _progress;
  bool _loading = false;
  String? _error;
  String? _selectedLane;
  String? _selectedRoleModel;

  // ── v2 state ──
  List<ForgeRecommendation> _recommendations = [];
  Map<String, ForgeLaneStats> _laneStats = {};
  String? _selectedDifficulty;
  ForgeSortOption _sortBy = ForgeSortOption.recommended;
  String _searchQuery = '';

  // ── v1 getters ──
  List<ForgeCourse> get courses => _courses;
  List<ForgeCourse> get allCourses => _allCourses;
  ForgeProgress? get progress => _progress;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedLane => _selectedLane;
  String? get selectedRoleModel => _selectedRoleModel;

  /// Unique role models across all courses (v1-compatible record format).
  List<({String id, String name, String emoji})> get roleModels {
    final seen = <String>{};
    final result = <({String id, String name, String emoji})>[];
    for (final c in _allCourses) {
      if (seen.add(c.roleModelId)) {
        result.add((
          id: c.roleModelId,
          name: c.roleModelName,
          emoji: c.roleModelEmoji,
        ));
      }
    }
    return result;
  }

  int get totalLessonsCompleted =>
      _allCourses.fold<int>(0, (s, c) => s + c.completedCount);

  int get totalLessons =>
      _allCourses.fold<int>(0, (s, c) => s + c.lessonCount);

  // ── v2 getters ──
  List<ForgeRecommendation> get recommendations => _recommendations;
  Map<String, ForgeLaneStats> get laneStats => _laneStats;
  String? get selectedDifficulty => _selectedDifficulty;
  ForgeSortOption get sortBy => _sortBy;
  String get searchQuery => _searchQuery;

  double get averageRating {
    if (_allCourses.isEmpty) return 0.0;
    final total = _allCourses.fold<double>(0.0, (sum, c) => sum + c.rating);
    return total / _allCourses.length;
  }

  List<ForgeCourse> get coursesInProgress {
    return _allCourses.where((course) {
      final hasCompleted = course.lessons.any((l) => l.isCompleted);
      final allCompleted = course.lessons.every((l) => l.isCompleted);
      return hasCompleted && !allCompleted;
    }).toList();
  }

  // ── v1 methods ──

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _allCourses = await _gateway.loadCourses();
      _progress = await _gateway.loadProgress();
      _laneStats = _progress?.laneStats ?? {};
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void filterByLane(String? lane) {
    _selectedLane = lane;
    _applyFilters();
    notifyListeners();
  }

  void filterByRoleModel(String? roleModelId) {
    _selectedRoleModel = roleModelId;
    _applyFilters();
    notifyListeners();
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    await _gateway.completeLesson(courseId, lessonId);
    _progress = await _gateway.loadProgress();
    _laneStats = _progress?.laneStats ?? {};
    notifyListeners();
  }

  // ── v2 methods ──

  Future<void> loadRecommendations() async {
    try {
      _recommendations = await _gateway.getRecommendations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void searchCourses(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(ForgeSortOption option) {
    _sortBy = option;
    _applyFilters();
    notifyListeners();
  }

  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  Future<void> saveWorksheetAnswers(
    String courseId,
    String lessonId,
    String blockId,
    List<String> answers,
  ) async {
    await _gateway.saveWorksheetAnswers(courseId, lessonId, blockId, answers);
    notifyListeners();
  }

  Future<void> toggleChecklistItem(
    String courseId,
    String lessonId,
    String blockId,
    int itemIndex,
  ) async {
    await _gateway.toggleChecklistItem(courseId, lessonId, blockId, itemIndex);
    notifyListeners();
  }

  // ── Private helpers ──

  void _applyFilters() {
    var filtered = List<ForgeCourse>.of(_allCourses);

    // Lane filter
    if (_selectedLane != null) {
      filtered = filtered.where((c) => c.lane == _selectedLane).toList();
    }

    // Role model filter
    if (_selectedRoleModel != null) {
      filtered =
          filtered.where((c) => c.roleModelId == _selectedRoleModel).toList();
    }

    // Difficulty filter
    if (_selectedDifficulty != null) {
      filtered =
          filtered.where((c) => c.difficulty == _selectedDifficulty).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.roleModelName.toLowerCase().contains(query);
      }).toList();
    }

    _courses = filtered;
    _applySortAndSearch();
  }

  void _applySortAndSearch() {
    switch (_sortBy) {
      case ForgeSortOption.recommended:
        // Keep default order
        break;
      case ForgeSortOption.newest:
        _courses = _courses.reversed.toList();
        break;
      case ForgeSortOption.rating:
        _courses.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ForgeSortOption.difficulty:
        const order = {'beginner': 0, 'intermediate': 1, 'advanced': 2};
        _courses.sort((a, b) =>
            (order[a.difficulty] ?? 0).compareTo(order[b.difficulty] ?? 0));
        break;
    }
  }
}

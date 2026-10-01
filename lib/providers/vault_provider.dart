import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vault.dart';
import '../gateways/vault_gateway.dart';

class VaultProvider extends ChangeNotifier {
  final VaultGateway gateway;

  VaultProvider({required this.gateway});

  List<VaultEntry> _entries = [];
  List<VaultInsight> _insights = [];
  List<GrowthPattern> _patterns = [];
  List<MoodDataPoint> _moodTimeline = [];
  VaultStats? _stats;

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  String _searchQuery = '';
  VaultMood? _selectedMood;
  VaultTag? _selectedTag;
  String? _selectedLane;

  Timer? _searchDebounce;

  // Getters
  List<VaultEntry> get entries => _entries;
  List<VaultInsight> get insights => _insights;
  List<GrowthPattern> get patterns => _patterns;
  List<MoodDataPoint> get moodTimeline => _moodTimeline;
  VaultStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  VaultMood? get selectedMood => _selectedMood;
  VaultTag? get selectedTag => _selectedTag;
  String? get selectedLane => _selectedLane;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedMood != null ||
      _selectedTag != null ||
      _selectedLane != null;

  List<VaultEntry> get filteredEntries {
    var result = List<VaultEntry>.from(_entries);

    if (_selectedMood != null) {
      result = result.where((e) => e.mood == _selectedMood).toList();
    }

    if (_selectedTag != null) {
      result = result.where((e) => e.tags.contains(_selectedTag)).toList();
    }

    if (_selectedLane != null) {
      result = result.where((e) => e.lane == _selectedLane).toList();
    }

    return result;
  }

  List<VaultEntry> get bookmarkedEntries =>
      _entries.where((e) => e.isBookmarked).toList();

  List<VaultEntry> get favoriteEntries =>
      _entries.where((e) => e.isFavorite).toList();

  // Load all data
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        gateway.loadEntries(),
        gateway.loadInsights(),
        gateway.loadPatterns(),
        gateway.loadStats(),
        gateway.loadMoodTimeline(),
      ]);

      _entries = results[0] as List<VaultEntry>;
      _insights = results[1] as List<VaultInsight>;
      _patterns = results[2] as List<GrowthPattern>;
      _stats = results[3] as VaultStats;
      _moodTimeline = results[4] as List<MoodDataPoint>;
    } catch (e) {
      _error = 'Failed to load vault data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntries() async {
    try {
      _entries = await gateway.loadEntries();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load entries: $e';
      notifyListeners();
    }
  }

  Future<void> loadInsights() async {
    try {
      _insights = await gateway.loadInsights();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load insights: $e';
      notifyListeners();
    }
  }

  Future<void> loadPatterns() async {
    try {
      _patterns = await gateway.loadPatterns();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load patterns: $e';
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await gateway.loadStats();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load stats: $e';
      notifyListeners();
    }
  }

  // Search with debounce
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      _isSearching = false;
      loadEntries();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _entries = await gateway.searchEntries(query);
      } catch (e) {
        _error = 'Search failed: $e';
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  // Filters
  void setMoodFilter(VaultMood? mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  void setTagFilter(VaultTag? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void setLaneFilter(String? lane) {
    _selectedLane = lane;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedMood = null;
    _selectedTag = null;
    _selectedLane = null;
    _searchDebounce?.cancel();
    _isSearching = false;
    loadEntries();
  }

  // CRUD
  Future<void> createEntry(VaultEntry entry) async {
    try {
      final created = await gateway.createEntry(entry);
      _entries.insert(0, created);
      notifyListeners();
      await loadStats();
    } catch (e) {
      _error = 'Failed to create entry: $e';
      notifyListeners();
    }
  }

  Future<void> updateEntry(VaultEntry entry) async {
    try {
      final updated = await gateway.updateEntry(entry);
      final index = _entries.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _entries[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update entry: $e';
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await gateway.deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      await loadStats();
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String id) async {
    try {
      final updated = await gateway.toggleBookmark(id);
      final index = _entries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entries[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle bookmark: $e';
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final updated = await gateway.toggleFavorite(id);
      final index = _entries.indexWhere((e) => e.id == id);
      if (index != -1) {
        _entries[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

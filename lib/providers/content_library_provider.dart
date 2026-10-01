import 'package:flutter/foundation.dart';

import '../gateways/content_library_gateway.dart';
import '../models/content_library.dart';

class ContentLibraryProvider extends ChangeNotifier {
  final ContentLibraryGateway _gateway;

  ContentLibraryProvider({required ContentLibraryGateway gateway})
      : _gateway = gateway;

  ContentLibraryData? _libraryData;
  List<ContentItem> _filteredItems = [];
  String _selectedLane = 'All';
  ContentType? _selectedType;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  ContentLibraryData? get libraryData => _libraryData;
  List<ContentItem> get filteredItems => _filteredItems;
  String get selectedLane => _selectedLane;
  ContentType? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLibrary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _libraryData = await _gateway.loadLibrary();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLaneFilter(String lane) {
    _selectedLane = lane;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(ContentType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _gateway.searchContent(query);
      _filteredItems = results;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String itemId) async {
    try {
      await _gateway.toggleBookmark(itemId);
      if (_libraryData != null) {
        final updated = _libraryData!.items.map((i) {
          if (i.id == itemId) return i.copyWith(isBookmarked: !i.isBookmarked);
          return i;
        }).toList();
        final bookmarked = updated.where((i) => i.isBookmarked).length;
        _libraryData = _libraryData!.copyWith(
          items: updated,
          bookmarkedCount: bookmarked,
        );
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markCompleted(String itemId) async {
    try {
      await _gateway.markCompleted(itemId);
      if (_libraryData != null) {
        final updated = _libraryData!.items.map((i) {
          if (i.id == itemId) {
            return i.copyWith(isCompleted: true, progress: 1.0);
          }
          return i;
        }).toList();
        final completed = updated.where((i) => i.isCompleted).length;
        _libraryData = _libraryData!.copyWith(
          items: updated,
          completedItems: completed,
        );
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _applyFilters() {
    if (_libraryData == null) return;
    var items = _libraryData!.items;
    if (_selectedLane != 'All') {
      items = items.where((i) => i.lane == _selectedLane).toList();
    }
    if (_selectedType != null) {
      items = items.where((i) => i.type == _selectedType).toList();
    }
    _filteredItems = items;
  }
}

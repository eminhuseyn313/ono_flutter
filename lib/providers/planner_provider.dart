import 'package:flutter/foundation.dart';

import '../gateways/planner_gateway.dart';
import '../models/planner.dart';

class PlannerProvider extends ChangeNotifier {
  final PlannerGateway gateway;

  PlannerProvider({required this.gateway});

  DailyPlan? _currentPlan;
  List<PlannerTemplate> _templates = [];
  List<PlannerItem> _suggestedItems = [];
  PlannerStats? _stats;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingTemplates = false;
  bool _isLoadingStats = false;
  bool _isLoadingSuggestions = false;
  String? _errorMessage;

  DailyPlan? get currentPlan => _currentPlan;
  List<PlannerTemplate> get templates => _templates;
  List<PlannerItem> get suggestedItems => _suggestedItems;
  PlannerStats? get stats => _stats;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isLoadingTemplates => _isLoadingTemplates;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get errorMessage => _errorMessage;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  double get completionRate => _currentPlan?.completionRate ?? 0.0;

  int get completedCount => _currentPlan?.completedCount ?? 0;

  int get totalCount => _currentPlan?.items.length ?? 0;

  List<PlannerItem> itemsForBlock(TimeBlock block) {
    return _currentPlan?.itemsForBlock(block) ?? [];
  }

  Future<void> loadTodayPlan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPlan = await gateway.getTodayPlan();
      _selectedDate = DateTime.now();
    } catch (e) {
      _errorMessage = 'Failed to load today\'s plan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlanForDate(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedDate = date;
    notifyListeners();

    try {
      _currentPlan = await gateway.getPlanForDate(date);
    } catch (e) {
      _errorMessage = 'Failed to load plan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleItemComplete(String itemId) async {
    if (_currentPlan == null) return;

    final items = _currentPlan!.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    _currentPlan = _currentPlan!.copyWith(items: items);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to save changes: $e';
      notifyListeners();
    }
  }

  Future<void> addItem(PlannerItem item) async {
    if (_currentPlan == null) return;

    final items = List<PlannerItem>.from(_currentPlan!.items)..add(item);
    _currentPlan = _currentPlan!.copyWith(items: items);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to add item: $e';
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_currentPlan == null) return;

    final items = _currentPlan!.items.where((item) => item.id != itemId).toList();
    _currentPlan = _currentPlan!.copyWith(items: items);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to remove item: $e';
      notifyListeners();
    }
  }

  Future<void> reorderItems(TimeBlock block, int oldIndex, int newIndex) async {
    if (_currentPlan == null) return;

    final blockItems = List<PlannerItem>.from(itemsForBlock(block));
    if (oldIndex < 0 || oldIndex >= blockItems.length) return;
    if (newIndex < 0 || newIndex > blockItems.length) return;

    if (newIndex > oldIndex) newIndex--;
    final movedItem = blockItems.removeAt(oldIndex);
    blockItems.insert(newIndex, movedItem);

    final otherItems = _currentPlan!.items
        .where((item) => item.timeBlock != block)
        .toList();
    final allItems = [...otherItems, ...blockItems];

    final sortedItems = <PlannerItem>[];
    for (final tb in TimeBlock.values) {
      sortedItems.addAll(allItems.where((item) => item.timeBlock == tb));
    }

    _currentPlan = _currentPlan!.copyWith(items: sortedItems);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to reorder items: $e';
      notifyListeners();
    }
  }

  Future<void> updateMorningIntention(String intention) async {
    if (_currentPlan == null) return;

    _currentPlan = _currentPlan!.copyWith(morningIntention: intention);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to save intention: $e';
      notifyListeners();
    }
  }

  Future<void> updateEveningReflection(String reflection) async {
    if (_currentPlan == null) return;

    _currentPlan = _currentPlan!.copyWith(eveningReflection: reflection);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to save reflection: $e';
      notifyListeners();
    }
  }

  Future<void> loadTemplates() async {
    _isLoadingTemplates = true;
    notifyListeners();

    try {
      _templates = await gateway.getTemplates();
    } catch (e) {
      _errorMessage = 'Failed to load templates: $e';
    } finally {
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<void> applyTemplate(String templateId) async {
    if (_currentPlan == null) return;

    final template = _templates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    final now = DateTime.now();
    final newItems = template.items.map((item) {
      return item.copyWith(
        id: 'item_${now.millisecondsSinceEpoch}_${item.id}',
        isCompleted: false,
      );
    }).toList();

    _currentPlan = _currentPlan!.copyWith(items: newItems);
    notifyListeners();

    try {
      await gateway.savePlan(_currentPlan!);
    } catch (e) {
      _errorMessage = 'Failed to apply template: $e';
      notifyListeners();
    }
  }

  Future<void> saveAsTemplate(String name, String emoji, String description) async {
    if (_currentPlan == null || _currentPlan!.items.isEmpty) return;

    final template = PlannerTemplate(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      description: description,
      items: _currentPlan!.items,
      isDefault: false,
    );

    try {
      await gateway.saveTemplate(template);
      await loadTemplates();
    } catch (e) {
      _errorMessage = 'Failed to save template: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await gateway.deleteTemplate(templateId);
      _templates = _templates.where((t) => t.id != templateId).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete template: $e';
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _stats = await gateway.getStats();
    } catch (e) {
      _errorMessage = 'Failed to load stats: $e';
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadSuggestedItems() async {
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      _suggestedItems = await gateway.getSuggestedItems();
    } catch (e) {
      _errorMessage = 'Failed to load suggestions: $e';
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

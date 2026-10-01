import 'package:flutter/foundation.dart';

import '../gateways/power_rankings_gateway.dart';
import '../models/power_rankings.dart';

class PowerRankingsProvider extends ChangeNotifier {
  final PowerRankingsGateway gateway;

  PowerRankingsProvider({required this.gateway});

  WeeklyDigest? _currentDigest;
  WeeklyDigest? _selectedDigest;
  List<RankingHistory> _history = [];
  PowerRankingsStats? _stats;
  RecapCard? _recapCard;

  bool _isLoadingDigest = false;
  bool _isLoadingHistory = false;
  bool _isLoadingStats = false;
  bool _isGeneratingRecap = false;
  String? _error;
  DateTime? _selectedWeek;

  WeeklyDigest? get currentDigest => _currentDigest;
  WeeklyDigest? get selectedDigest => _selectedDigest;
  WeeklyDigest? get activeDigest => _selectedDigest ?? _currentDigest;
  List<RankingHistory> get history => _history;
  PowerRankingsStats? get stats => _stats;
  RecapCard? get recapCard => _recapCard;

  bool get isLoadingDigest => _isLoadingDigest;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingStats => _isLoadingStats;
  bool get isGeneratingRecap => _isGeneratingRecap;
  bool get isLoading => _isLoadingDigest || _isLoadingHistory || _isLoadingStats;
  String? get error => _error;
  DateTime? get selectedWeek => _selectedWeek;

  Future<void> loadCurrentDigest() async {
    _isLoadingDigest = true;
    _error = null;
    notifyListeners();

    try {
      _currentDigest = await gateway.getCurrentWeekDigest();
      _selectedDigest = null;
      _selectedWeek = null;
    } catch (e) {
      _error = 'Failed to load current digest: $e';
    } finally {
      _isLoadingDigest = false;
      notifyListeners();
    }
  }

  Future<void> loadDigestForWeek(DateTime weekStart) async {
    _isLoadingDigest = true;
    _error = null;
    _selectedWeek = weekStart;
    notifyListeners();

    try {
      _selectedDigest = await gateway.getDigestForWeek(weekStart);
    } catch (e) {
      _error = 'Failed to load digest for week: $e';
    } finally {
      _isLoadingDigest = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory({int weeks = 12}) async {
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      _history = await gateway.getHistory(weeks);
    } catch (e) {
      _error = 'Failed to load history: $e';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    _isLoadingStats = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await gateway.getStats();
    } catch (e) {
      _error = 'Failed to load stats: $e';
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> generateRecap() async {
    final digest = activeDigest;
    if (digest == null) return;

    _isGeneratingRecap = true;
    _error = null;
    notifyListeners();

    try {
      _recapCard = await gateway.generateRecapCard(digest.id);
    } catch (e) {
      _error = 'Failed to generate recap card: $e';
    } finally {
      _isGeneratingRecap = false;
      notifyListeners();
    }
  }

  void clearSelectedWeek() {
    _selectedDigest = null;
    _selectedWeek = null;
    notifyListeners();
  }

  void clearRecapCard() {
    _recapCard = null;
    notifyListeners();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadCurrentDigest(),
      loadHistory(),
      loadStats(),
    ]);
  }
}

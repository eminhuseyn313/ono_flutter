import 'package:flutter/foundation.dart';

import '../gateways/council_gateway.dart';
import '../models/council.dart';

class CouncilProvider extends ChangeNotifier {
  final CouncilGateway gateway;

  CouncilProvider({required this.gateway});

  // ─── STATE ──────────────────────────────────────────────────────────────

  CouncilSession? _currentSession;
  List<CouncilSession> _history = [];
  CouncilQuota? _quota;
  bool _isAsking = false;
  bool _isLoadingHistory = false;
  String? _error;
  final Set<String> _selectedMembers = {};

  // ─── GETTERS ────────────────────────────────────────────────────────────

  CouncilSession? get currentSession => _currentSession;
  List<CouncilSession> get history => List.unmodifiable(_history);
  CouncilQuota? get quota => _quota;
  bool get isAsking => _isAsking;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  Set<String> get selectedMembers => Set.unmodifiable(_selectedMembers);

  bool get canAsk =>
      _selectedMembers.length >= 2 && (_quota?.canAsk ?? true) && !_isAsking;

  // ─── MEMBER SELECTION ───────────────────────────────────────────────────

  void toggleMember(String memberId) {
    if (_selectedMembers.contains(memberId)) {
      _selectedMembers.remove(memberId);
    } else if (_selectedMembers.length < 4) {
      _selectedMembers.add(memberId);
    }
    notifyListeners();
  }

  bool isMemberSelected(String memberId) =>
      _selectedMembers.contains(memberId);

  void clearSelection() {
    _selectedMembers.clear();
    notifyListeners();
  }

  // ─── ASK QUESTION ───────────────────────────────────────────────────────

  Future<void> askQuestion(String question, List<String> memberIds) async {
    if (question.trim().isEmpty || memberIds.length < 2) return;

    _isAsking = true;
    _error = null;
    _currentSession = null;
    notifyListeners();

    try {
      final session = await gateway.askCouncil(question.trim(), memberIds);
      _currentSession = session;
      _history.insert(0, session);
      _quota = await gateway.getQuota();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isAsking = false;
      notifyListeners();
    }
  }

  // ─── HISTORY ────────────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      _history = await gateway.loadHistory();
      _quota = await gateway.getQuota();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ─── FAVORITES ──────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String sessionId) async {
    try {
      final updated = await gateway.toggleFavorite(sessionId);
      final index = _history.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _history[index] = updated;
      }
      if (_currentSession?.id == sessionId) {
        _currentSession = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── VIEW SESSION ───────────────────────────────────────────────────────

  void viewSession(CouncilSession session) {
    _currentSession = session;
    notifyListeners();
  }

  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }
}

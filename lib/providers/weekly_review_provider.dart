import 'package:flutter/foundation.dart';

import '../gateways/weekly_review_gateway.dart';
import '../models/weekly_review.dart';

class WeeklyReviewProvider extends ChangeNotifier {
  final WeeklyReviewGateway _gateway;

  WeeklyReviewProvider({required WeeklyReviewGateway gateway})
      : _gateway = gateway;

  WeeklyReviewData? _currentReview;
  ReviewHistory? _history;
  bool _isLoading = false;
  String? _error;
  bool _isCompleted = false;

  WeeklyReviewData? get currentReview => _currentReview;
  ReviewHistory? get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCompleted => _isCompleted;

  Future<void> loadCurrentReview() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentReview = await _gateway.loadCurrentWeekData();
      _isCompleted = _currentReview!.isCompleted;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _gateway.loadReviewHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMood(ReviewMood mood) async {
    if (_currentReview == null) return;

    try {
      await _gateway.updateMood(_currentReview!.id, mood);
      _currentReview = _currentReview!.copyWith(mood: mood);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addWin(String title, String lane) async {
    if (_currentReview == null) return;

    final win = WeeklyWin(
      id: 'win_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      lane: lane,
      date: DateTime.now(),
    );

    final updatedWins = [..._currentReview!.wins, win];
    _currentReview = _currentReview!.copyWith(wins: updatedWins);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeWin(String id) async {
    if (_currentReview == null) return;

    final updatedWins =
        _currentReview!.wins.where((w) => w.id != id).toList();
    _currentReview = _currentReview!.copyWith(wins: updatedWins);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addLesson(String content, String category) async {
    if (_currentReview == null) return;

    final lesson = WeeklyLesson(
      id: 'lesson_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      category: category,
      isActionable: true,
    );

    final updatedLessons = [..._currentReview!.lessons, lesson];
    _currentReview = _currentReview!.copyWith(lessons: updatedLessons);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateLaneScore(String laneName, double score) async {
    if (_currentReview == null) return;

    final updatedScores = _currentReview!.laneScores.map((s) {
      if (s.laneName == laneName) {
        return s.copyWith(score: score);
      }
      return s;
    }).toList();

    _currentReview = _currentReview!.copyWith(laneScores: updatedScores);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addGoal(String title, String lane, int priority) async {
    if (_currentReview == null) return;

    final goal = WeeklyGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      lane: lane,
      isCompleted: false,
      priority: priority,
    );

    final updatedGoals = [..._currentReview!.nextWeekGoals, goal];
    _currentReview = _currentReview!.copyWith(nextWeekGoals: updatedGoals);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setReflection(String text) async {
    if (_currentReview == null) return;

    _currentReview = _currentReview!.copyWith(reflectionNote: text);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setOverallRating(int rating) async {
    if (_currentReview == null) return;

    _currentReview = _currentReview!.copyWith(overallRating: rating);

    try {
      await _gateway.saveReview(_currentReview!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeReview() async {
    if (_currentReview == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentReview = await _gateway.completeReview(_currentReview!.id);
      _isCompleted = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

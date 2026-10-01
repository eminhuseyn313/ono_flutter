import 'package:flutter/foundation.dart';
import '../gateways/achievement_gateway.dart';
import '../models/achievement.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementGateway _gateway;

  AchievementProvider({required AchievementGateway gateway})
      : _gateway = gateway;

  List<Achievement> _achievements = [];
  AchievementStats? _stats;
  bool _isLoading = false;
  String? _error;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  AchievementStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  List<Achievement> achievementsByCategory(AchievementCategory category) =>
      _achievements.where((a) => a.category == category).toList();

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadAchievements(),
        _gateway.loadAchievementStats(),
      ]);
      _achievements = results[0] as List<Achievement>;
      _stats = results[1] as AchievementStats;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claimAchievement(String id) async {
    try {
      final claimed = await _gateway.claimAchievement(id);
      final index = _achievements.indexWhere((a) => a.id == id);
      if (index != -1) {
        _achievements = List.from(_achievements);
        _achievements[index] = claimed;

        if (_stats != null) {
          final updatedCategoryProgress =
              Map<AchievementCategory, int>.from(_stats!.categoryProgress);
          updatedCategoryProgress[claimed.category] =
              (updatedCategoryProgress[claimed.category] ?? 0) + 1;

          final recentlyUnlocked = [claimed, ..._stats!.recentlyUnlocked];
          if (recentlyUnlocked.length > 5) {
            recentlyUnlocked.removeLast();
          }

          _stats = _stats!.copyWith(
            unlockedCount: _stats!.unlockedCount + 1,
            totalXpEarned: _stats!.totalXpEarned + claimed.xpReward,
            categoryProgress: updatedCategoryProgress,
            recentlyUnlocked: recentlyUnlocked,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkNewAchievements() async {
    try {
      final newlyUnlocked = await _gateway.checkForNewAchievements();
      if (newlyUnlocked.isNotEmpty) {
        _achievements = List.from(_achievements);
        for (final achievement in newlyUnlocked) {
          final index =
              _achievements.indexWhere((a) => a.id == achievement.id);
          if (index != -1) {
            _achievements[index] = achievement;
          } else {
            _achievements.add(achievement);
          }
        }
        // Reload stats to get updated counts
        _stats = await _gateway.loadAchievementStats();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import '../gateways/gamification_gateway.dart';
import '../models/gamification.dart';

class GamificationProvider extends ChangeNotifier {
  final GamificationGateway gateway;

  GamificationProvider({required this.gateway});

  GamificationProfile? _profile;
  List<XPTransaction> _transactions = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<RewardItem> _rewards = [];
  List<WeeklyChallenge> _weeklyChallenges = [];
  XPBreakdown? _breakdown;

  bool _isLoading = false;
  bool _dailyBonusClaimed = false;
  String? _error;

  XPSource? _transactionFilter;
  RewardCategory? _rewardCategoryFilter;

  GamificationProfile? get profile => _profile;
  XPBreakdown? get breakdown => _breakdown;
  bool get isLoading => _isLoading;
  bool get dailyBonusClaimed => _dailyBonusClaimed;
  String? get error => _error;
  XPSource? get transactionFilter => _transactionFilter;
  RewardCategory? get rewardCategoryFilter => _rewardCategoryFilter;

  List<XPTransaction> get transactions {
    if (_transactionFilter == null) return _transactions;
    return _transactions
        .where((t) => t.source == _transactionFilter)
        .toList();
  }

  List<LeaderboardEntry> get leaderboard {
    final sorted = List<LeaderboardEntry>.from(_leaderboard);
    sorted.sort((a, b) => a.rank.compareTo(b.rank));
    return sorted;
  }

  List<RewardItem> get rewards {
    if (_rewardCategoryFilter == null) return _rewards;
    return _rewards
        .where((r) => r.category == _rewardCategoryFilter)
        .toList();
  }

  List<WeeklyChallenge> get weeklyChallenges => _weeklyChallenges;

  void setTransactionFilter(XPSource? source) {
    _transactionFilter = source;
    notifyListeners();
  }

  void setRewardCategoryFilter(RewardCategory? category) {
    _rewardCategoryFilter = category;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        gateway.loadProfile(),
        gateway.loadTransactions(),
        gateway.loadLeaderboard(),
        gateway.loadRewards(),
        gateway.loadWeeklyChallenges(),
        gateway.loadXPBreakdown(),
      ]);

      _profile = results[0] as GamificationProfile;
      _transactions = results[1] as List<XPTransaction>;
      _leaderboard = results[2] as List<LeaderboardEntry>;
      _rewards = results[3] as List<RewardItem>;
      _weeklyChallenges = results[4] as List<WeeklyChallenge>;
      _breakdown = results[5] as XPBreakdown;
    } catch (e) {
      _error = 'Failed to load gamification data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _profile = await gateway.loadProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: $e';
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    try {
      _transactions = await gateway.loadTransactions();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load transactions: $e';
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    try {
      _leaderboard = await gateway.loadLeaderboard();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load leaderboard: $e';
      notifyListeners();
    }
  }

  Future<void> loadRewards() async {
    try {
      _rewards = await gateway.loadRewards();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load rewards: $e';
      notifyListeners();
    }
  }

  Future<void> loadWeeklyChallenges() async {
    try {
      _weeklyChallenges = await gateway.loadWeeklyChallenges();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load weekly challenges: $e';
      notifyListeners();
    }
  }

  Future<void> loadXPBreakdown() async {
    try {
      _breakdown = await gateway.loadXPBreakdown();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load XP breakdown: $e';
      notifyListeners();
    }
  }

  Future<bool> purchaseReward(String rewardId) async {
    final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
    if (rewardIndex == -1) return false;

    final reward = _rewards[rewardIndex];
    if (reward.isUnlocked) return false;
    if (_profile == null || _profile!.totalXp < reward.xpCost) return false;

    // Optimistic update
    final updatedReward = reward.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    _rewards[rewardIndex] = updatedReward;
    _profile = _profile!.copyWith(
      totalRewardsUnlocked: _profile!.totalRewardsUnlocked + 1,
    );
    notifyListeners();

    try {
      await gateway.purchaseReward(rewardId);
      return true;
    } catch (e) {
      // Rollback on failure
      _rewards[rewardIndex] = reward;
      _profile = _profile!.copyWith(
        totalRewardsUnlocked: _profile!.totalRewardsUnlocked - 1,
      );
      _error = 'Failed to purchase reward: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> claimDailyBonus() async {
    if (_dailyBonusClaimed) return false;

    try {
      final bonusXp = await gateway.claimDailyBonus();
      _dailyBonusClaimed = true;

      if (_profile != null) {
        final newTotal = _profile!.totalXp + bonusXp;
        _profile = _profile!.copyWith(
          totalXp: newTotal,
          weeklyXp: _profile!.weeklyXp + bonusXp,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to claim daily bonus: $e';
      notifyListeners();
      return false;
    }
  }
}

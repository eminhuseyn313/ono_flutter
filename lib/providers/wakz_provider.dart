// providers/wakz_provider.dart
// State management for Wakz Social Proof Challenges

import 'package:flutter/foundation.dart';
import '../gateways/wakz_gateway.dart';
import '../models/wakz_challenge.dart';

class WakzProvider extends ChangeNotifier {
  final WakzGateway gateway;

  WakzProvider({required this.gateway});

  List<WakzChallenge> _activeChallenges = [];
  List<WakzChallenge> _availableChallenges = [];
  List<ChallengeBattle> _activeBattles = [];
  List<CommunityProof> _communityFeed = [];
  WakzStats _stats = const WakzStats();
  List<WakzBadge> _badges = [];

  bool _isLoading = false;
  String? _errorMessage;

  // --- Getters ---

  List<WakzChallenge> get activeChallenges => _activeChallenges;
  List<WakzChallenge> get availableChallenges => _availableChallenges;
  List<ChallengeBattle> get activeBattles => _activeBattles;
  List<CommunityProof> get communityFeed => _communityFeed;
  WakzStats get stats => _stats;
  List<WakzBadge> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get activeChallengeCount => _activeChallenges.length;

  double get completionRate =>
      _stats.totalChallengesCompleted > 0
          ? _stats.totalVerified / _stats.totalChallengesCompleted
          : 0.0;

  List<WakzChallenge> filterByCategory(ChallengeCategory category) {
    return _availableChallenges
        .where((c) => c.category == category)
        .toList();
  }

  // --- Load Methods ---

  Future<void> loadActiveChallenges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _activeChallenges = await gateway.loadActiveChallenges();
    } catch (e) {
      _errorMessage = 'Failed to load active challenges: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableChallenges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _availableChallenges = await gateway.loadAvailableChallenges();
    } catch (e) {
      _errorMessage = 'Failed to load available challenges: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveBattles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _activeBattles = await gateway.loadActiveBattles();
    } catch (e) {
      _errorMessage = 'Failed to load battles: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCommunityFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _communityFeed = await gateway.loadCommunityFeed();
    } catch (e) {
      _errorMessage = 'Failed to load community feed: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStats() async {
    try {
      _stats = await gateway.loadStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stats: $e';
    }
  }

  Future<void> loadBadges() async {
    try {
      _badges = await gateway.loadBadges();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load badges: $e';
    }
  }

  // --- Action Methods ---

  Future<void> startChallenge(String challengeId) async {
    try {
      final challenge = await gateway.startChallenge(challengeId);
      _activeChallenges = [..._activeChallenges, challenge];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start challenge: $e';
      notifyListeners();
    }
  }

  Future<void> submitProof(String challengeId, String proofPath) async {
    try {
      final updated = await gateway.submitProof(challengeId, proofPath);
      _activeChallenges = _activeChallenges
          .map((c) => c.id == challengeId ? updated : c)
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to submit proof: $e';
      notifyListeners();
    }
  }

  Future<void> completeChallenge(String challengeId) async {
    try {
      final updated = await gateway.completeChallenge(challengeId);
      _activeChallenges = _activeChallenges
          .map((c) => c.id == challengeId ? updated : c)
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to complete challenge: $e';
      notifyListeners();
    }
  }

  Future<void> startBattle(String challengeId, String opponentType) async {
    try {
      final battle = await gateway.startBattle(challengeId, opponentType);
      _activeBattles = [..._activeBattles, battle];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start battle: $e';
      notifyListeners();
    }
  }

  Future<void> likeCommunityProof(String proofId) async {
    // Optimistic toggle
    final index = _communityFeed.indexWhere((p) => p.id == proofId);
    if (index == -1) return;

    final proof = _communityFeed[index];
    final optimistic = proof.copyWith(
      isLiked: !proof.isLiked,
      likesCount: proof.isLiked ? proof.likesCount - 1 : proof.likesCount + 1,
    );
    _communityFeed = List.from(_communityFeed)..[index] = optimistic;
    notifyListeners();

    try {
      await gateway.likeCommunityProof(proofId);
    } catch (e) {
      // Revert on failure
      _communityFeed = List.from(_communityFeed)..[index] = proof;
      notifyListeners();
    }
  }
}

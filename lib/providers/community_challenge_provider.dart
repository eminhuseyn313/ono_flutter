import 'package:flutter/foundation.dart';

import '../gateways/community_challenge_gateway.dart';
import '../models/community_challenge.dart';

class CommunityChallengeProvider extends ChangeNotifier {
  final CommunityChallengeGateway _gateway;

  CommunityChallengeProvider({required CommunityChallengeGateway gateway})
      : _gateway = gateway;

  ChallengeData? _challengeData;
  List<ChallengeParticipant> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  ChallengeData? get challengeData => _challengeData;
  List<ChallengeParticipant> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CommunityChallenge> get activeChallenges =>
      _challengeData?.challenges
          .where((c) => c.status == ChallengeStatus.active)
          .toList() ??
      [];

  List<CommunityChallenge> get upcomingChallenges =>
      _challengeData?.challenges
          .where((c) => c.status == ChallengeStatus.upcoming)
          .toList() ??
      [];

  List<CommunityChallenge> get completedChallenges =>
      _challengeData?.challenges
          .where((c) => c.status == ChallengeStatus.completed)
          .toList() ??
      [];

  List<CommunityChallenge> get myChallenges =>
      _challengeData?.challenges.where((c) => c.isJoined).toList() ?? [];

  Future<void> loadChallenges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _challengeData = await _gateway.loadChallenges();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    try {
      await _gateway.joinChallenge(challengeId);
      if (_challengeData != null) {
        final updated = _challengeData!.challenges.map((c) {
          if (c.id == challengeId) {
            return c.copyWith(
              isJoined: true,
              participantCount: c.participantCount + 1,
            );
          }
          return c;
        }).toList();
        _challengeData = _challengeData!.copyWith(challenges: updated);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveChallenge(String challengeId) async {
    try {
      await _gateway.leaveChallenge(challengeId);
      if (_challengeData != null) {
        final updated = _challengeData!.challenges.map((c) {
          if (c.id == challengeId) {
            return c.copyWith(
              isJoined: false,
              participantCount: c.participantCount - 1,
              myProgress: 0.0,
              myRank: 0,
            );
          }
          return c;
        }).toList();
        _challengeData = _challengeData!.copyWith(challenges: updated);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard(String challengeId) async {
    try {
      _leaderboard = await _gateway.loadLeaderboard(challengeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

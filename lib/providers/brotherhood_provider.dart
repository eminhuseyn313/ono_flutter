import 'package:flutter/foundation.dart';

import '../gateways/brotherhood_gateway.dart';
import '../models/brotherhood.dart';

class BrotherhoodProvider extends ChangeNotifier {
  final BrotherhoodGateway gateway;

  BrotherhoodProvider({required this.gateway});

  BrotherhoodSquad? _squad;
  List<SquadMessage> _messages = [];
  SquadChallenge? _challenge;
  bool _isLoading = false;
  String? _error;

  BrotherhoodSquad? get squad => _squad;
  List<SquadMessage> get messages => _messages;
  SquadChallenge? get challenge => _challenge;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Minimum streak across all active members.
  int get squadStreak {
    if (_squad == null || _squad!.members.isEmpty) return 0;
    return _squad!.members
        .map((m) => m.streakDays)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Members with completion rate below 50%.
  List<BrotherhoodMember> get membersBehind {
    if (_squad == null) return [];
    return _squad!.members
        .where((m) => m.completionRate < 0.50)
        .toList();
  }

  Future<void> loadSquad() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        gateway.loadSquad(),
        gateway.loadSquadMessages(),
        gateway.loadSquadChallenge(),
      ]);

      _squad = results[0] as BrotherhoodSquad;
      _messages = results[1] as List<SquadMessage>;
      _challenge = results[2] as SquadChallenge;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendEncouragement(String memberId) async {
    try {
      await gateway.sendEncouragement(memberId);
      _messages = await gateway.loadSquadMessages();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> joinSquad(String journeyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _squad = await gateway.joinSquad(journeyId);
      _messages = await gateway.loadSquadMessages();
      _challenge = await gateway.loadSquadChallenge();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveSquad() async {
    _isLoading = true;
    notifyListeners();

    try {
      await gateway.leaveSquad();
      _squad = null;
      _messages = [];
      _challenge = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

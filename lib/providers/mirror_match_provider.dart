import 'package:flutter/foundation.dart';

import '../models/mirror_match.dart';
import '../gateways/mirror_match_gateway.dart';

class MirrorMatchProvider extends ChangeNotifier {
  MirrorMatchProvider({required MirrorMatchGateway gateway})
      : _gateway = gateway;

  final MirrorMatchGateway _gateway;

  MirrorMatchData? _data;
  bool _loading = false;
  String? _error;

  MirrorMatchData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  MirrorProfile? get mirror => _data?.mirror;
  List<TrajectoryPoint> get myTrajectory => _data?.myTrajectory ?? [];
  List<MirrorMessage> get messages => _data?.messages ?? [];
  bool get chatUnlocked => _data?.chatUnlocked ?? false;
  bool get hasMatch => _data?.status == MirrorMatchStatus.matched;

  /// Similarity percentage as an int (0–100).
  int get similarityPercent =>
      ((mirror?.similarityScore ?? 0) * 100).round();

  /// Days the mirror is ahead.
  int get daysAhead => mirror?.daysAhead ?? 0;

  /// Load the full match data.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _gateway.loadMatchData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Attempt to find a new match.
  Future<void> findMatch() async {
    _loading = true;
    notifyListeners();

    try {
      final profile = await _gateway.findMatch();
      if (profile != null) {
        await load(); // reload full data
      }
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Send a message to the matched mirror.
  Future<void> sendMessage(String text) async {
    if (mirror == null || text.trim().isEmpty) return;

    try {
      await _gateway.sendMessage(mirror!.id, text.trim());
      // Reload messages
      final msgs = await _gateway.loadMessages(mirror!.id);
      _data = _data?.copyWith(messages: msgs);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Reload messages (for pull-to-refresh or polling).
  Future<void> refreshMessages() async {
    if (mirror == null) return;

    try {
      final msgs = await _gateway.loadMessages(mirror!.id);
      _data = _data?.copyWith(messages: msgs);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Dismiss current match and search for a new one.
  Future<void> dismissMatch() async {
    if (mirror == null) return;

    try {
      await _gateway.dismissMatch(mirror!.id);
      _data = _data?.copyWith(
        status: MirrorMatchStatus.searching,
        mirror: null,
        messages: [],
        chatUnlocked: false,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';

import '../gateways/ai_coach_gateway.dart';
import '../models/ai_coach.dart';

class AiCoachProvider extends ChangeNotifier {
  final AiCoachGateway _gateway;

  AiCoachProvider({required AiCoachGateway gateway}) : _gateway = gateway;

  CoachData? _coachData;
  bool _isLoading = false;
  String? _error;

  CoachData? get coachData => _coachData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CoachInsight> get activeInsights =>
      _coachData?.insights.where((i) => !i.isDismissed).toList() ?? [];
  int get unreadCount =>
      activeInsights.where((i) => !i.isRead).length;
  DailyCoachTip? get dailyTip => _coachData?.dailyTip;

  Future<void> loadCoachData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coachData = await _gateway.loadCoachData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markInsightRead(String insightId) async {
    try {
      await _gateway.markInsightRead(insightId);
      if (_coachData != null) {
        final updated = _coachData!.insights.map((i) {
          if (i.id == insightId) return i.copyWith(isRead: true);
          return i;
        }).toList();
        _coachData = _coachData!.copyWith(insights: updated);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> dismissInsight(String insightId) async {
    try {
      await _gateway.dismissInsight(insightId);
      if (_coachData != null) {
        final updated = _coachData!.insights.map((i) {
          if (i.id == insightId) return i.copyWith(isDismissed: true);
          return i;
        }).toList();
        _coachData = _coachData!.copyWith(insights: updated);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTipBookmark() async {
    if (_coachData?.dailyTip == null) return;
    try {
      await _gateway.toggleTipBookmark(_coachData!.dailyTip.id);
      _coachData = _coachData!.copyWith(
        dailyTip: _coachData!.dailyTip
            .copyWith(isBookmarked: !_coachData!.dailyTip.isBookmarked),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setPreferredTone(CoachTone tone) async {
    try {
      await _gateway.setPreferredTone(tone);
      _coachData = _coachData?.copyWith(preferredTone: tone);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

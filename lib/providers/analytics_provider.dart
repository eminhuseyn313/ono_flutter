import 'package:flutter/foundation.dart';

import '../gateways/analytics_gateway.dart';
import '../models/analytics.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsGateway _gateway;

  AnalyticsProvider({required AnalyticsGateway gateway}) : _gateway = gateway;

  AnalyticsSummary? _summary;
  LaneAnalytics? _laneDetail;
  bool _isLoading = false;
  String? _error;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;

  AnalyticsSummary? get summary => _summary;
  LaneAnalytics? get laneDetail => _laneDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AnalyticsPeriod get selectedPeriod => _selectedPeriod;

  Future<void> loadAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.week,
  }) async {
    _isLoading = true;
    _error = null;
    _selectedPeriod = period;
    notifyListeners();

    try {
      _summary = await _gateway.loadAnalytics(period);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePeriod(AnalyticsPeriod period) async {
    if (period == _selectedPeriod) return;
    _selectedPeriod = period;
    notifyListeners();
    await loadAnalytics(period: period);
  }

  Future<void> loadLaneDetail(String laneName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _laneDetail =
          await _gateway.loadLaneDetail(laneName, _selectedPeriod);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

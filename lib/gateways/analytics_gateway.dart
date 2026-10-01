import '../models/analytics.dart';

abstract class AnalyticsGateway {
  Future<AnalyticsSummary> loadAnalytics(AnalyticsPeriod period);
  Future<LaneAnalytics> loadLaneDetail(String laneName, AnalyticsPeriod period);
  Future<XpAnalytics> loadXpHistory(AnalyticsPeriod period);
}

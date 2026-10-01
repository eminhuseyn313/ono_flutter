import '../models/power_rankings.dart';

abstract class PowerRankingsGateway {
  Future<WeeklyDigest> getCurrentWeekDigest();
  Future<WeeklyDigest> getDigestForWeek(DateTime weekStart);
  Future<List<RankingHistory>> getHistory(int weeks);
  Future<PowerRankingsStats> getStats();
  Future<RecapCard> generateRecapCard(String digestId);
}

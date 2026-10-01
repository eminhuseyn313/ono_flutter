import '../models/daily_checkin.dart';

abstract class DailyCheckinGateway {
  Future<DailyCheckin?> loadTodayCheckin();
  Future<CheckinHistory> loadCheckinHistory();
  Future<DailyCheckin> saveMorningCheckin(DailyCheckin checkin);
  Future<DailyCheckin> saveEveningCheckin(DailyCheckin checkin);
}

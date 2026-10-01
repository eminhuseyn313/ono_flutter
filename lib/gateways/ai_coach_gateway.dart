import '../models/ai_coach.dart';

abstract class AiCoachGateway {
  Future<CoachData> loadCoachData();
  Future<void> markInsightRead(String insightId);
  Future<void> dismissInsight(String insightId);
  Future<void> toggleTipBookmark(String tipId);
  Future<void> setPreferredTone(CoachTone tone);
}

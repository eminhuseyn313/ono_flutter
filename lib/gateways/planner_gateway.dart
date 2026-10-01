import '../models/planner.dart';

abstract class PlannerGateway {
  Future<DailyPlan> getTodayPlan();
  Future<DailyPlan> getPlanForDate(DateTime date);
  Future<void> savePlan(DailyPlan plan);
  Future<List<PlannerTemplate>> getTemplates();
  Future<void> saveTemplate(PlannerTemplate template);
  Future<void> deleteTemplate(String templateId);
  Future<PlannerStats> getStats();
  Future<List<PlannerItem>> getSuggestedItems();
}

// gateways/forge_gateway.dart — Abstract Forge Gateway v2

import '../models/forge.dart';

abstract class ForgeGateway {
  // v1 methods
  Future<List<ForgeCourse>> loadCourses();
  Future<ForgeCourse> loadCourse(String courseId);
  Future<ForgeProgress> loadProgress();
  Future<void> completeLesson(String courseId, String lessonId);
  Future<List<ForgeCourse>> loadCoursesByRoleModel(String roleModelId);
  Future<List<ForgeCourse>> loadCoursesByLane(String lane);

  // v2 methods
  Future<List<ForgeRecommendation>> getRecommendations();
  Future<ForgeLaneStats> getLaneStats(String lane);
  Future<void> saveWorksheetAnswers(
    String courseId,
    String lessonId,
    String blockId,
    List<String> answers,
  );
  Future<void> toggleChecklistItem(
    String courseId,
    String lessonId,
    String blockId,
    int itemIndex,
  );
}

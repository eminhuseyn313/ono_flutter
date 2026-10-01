import '../models/vision_board.dart';

abstract class VisionBoardGateway {
  Future<List<VisionGoal>> getGoals();
  Future<VisionGoal> getGoal(String id);
  Future<void> saveGoal(VisionGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> updateMilestone(String goalId, String milestoneId, bool isCompleted);
  Future<List<VisionSnapshot>> getSnapshots();
  Future<VisionBoardStats> getStats();
  Future<List<VisionQuote>> getQuotes();
}

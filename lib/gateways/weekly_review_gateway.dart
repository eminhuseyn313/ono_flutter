import '../models/weekly_review.dart';

abstract class WeeklyReviewGateway {
  Future<WeeklyReviewData> loadCurrentWeekData();
  Future<ReviewHistory> loadReviewHistory();
  Future<WeeklyReviewData> saveReview(WeeklyReviewData review);
  Future<void> updateMood(String reviewId, ReviewMood mood);
  Future<WeeklyReviewData> completeReview(String reviewId);
}

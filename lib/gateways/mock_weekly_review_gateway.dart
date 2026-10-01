import 'dart:math';

import '../models/weekly_review.dart';
import 'weekly_review_gateway.dart';

class MockWeeklyReviewGateway implements WeeklyReviewGateway {
  WeeklyReviewData? _currentReview;

  @override
  Future<WeeklyReviewData> loadCurrentWeekData() async {
    await Future.delayed(const Duration(milliseconds: 200));

    _currentReview = WeeklyReviewData(
      id: 'review_current_week',
      weekStart: DateTime(2026, 9, 15),
      weekEnd: DateTime(2026, 9, 21),
      mood: ReviewMood.good,
      wins: [
        WeeklyWin(
          id: 'win_1',
          title: 'Completed 5 Mind lane actions',
          description: 'Finished all scheduled meditation and journaling tasks',
          lane: 'Mind',
          date: DateTime(2026, 9, 18),
        ),
        WeeklyWin(
          id: 'win_2',
          title: 'Hit 14-day streak',
          description: 'Two full weeks of consecutive daily actions',
          lane: 'Body',
          date: DateTime(2026, 9, 20),
        ),
        WeeklyWin(
          id: 'win_3',
          title: 'Finished Forge course module 3',
          description: 'Completed the advanced communication module',
          lane: 'Skill',
          date: DateTime(2026, 9, 19),
        ),
      ],
      lessons: [
        const WeeklyLesson(
          id: 'lesson_1',
          content:
              'Consistency beats intensity — small daily actions compound',
          category: 'habit',
          isActionable: true,
        ),
        const WeeklyLesson(
          id: 'lesson_2',
          content: 'Social lane needs more attention',
          category: 'relationship',
          isActionable: true,
        ),
      ],
      laneScores: [
        const LaneReviewScore(
          laneName: 'Mind',
          colorValue: 0xFF8B5CF6,
          iconCodePoint: 0xe0f0,
          score: 8.0,
          actionsCompleted: 5,
          highlight: 'Completed all meditation sessions this week',
        ),
        const LaneReviewScore(
          laneName: 'Body',
          colorValue: 0xFF34D399,
          iconCodePoint: 0xe566,
          score: 7.5,
          actionsCompleted: 4,
          highlight: 'Hit personal best on 5k run time',
        ),
        const LaneReviewScore(
          laneName: 'Social',
          colorValue: 0xFF22D3EE,
          iconCodePoint: 0xe7fb,
          score: 5.0,
          actionsCompleted: 2,
          highlight: 'Had one meaningful conversation with a friend',
        ),
        const LaneReviewScore(
          laneName: 'Skill',
          colorValue: 0xFFF59E0B,
          iconCodePoint: 0xe80c,
          score: 7.0,
          actionsCompleted: 3,
          highlight: 'Completed Forge course module 3',
        ),
      ],
      nextWeekGoals: [
        const WeeklyGoal(
          id: 'goal_1',
          title: 'Complete 3 Social lane actions',
          lane: 'Social',
          isCompleted: false,
          priority: 1,
        ),
        const WeeklyGoal(
          id: 'goal_2',
          title: 'Start Forge module 4',
          lane: 'Skill',
          isCompleted: false,
          priority: 2,
        ),
        const WeeklyGoal(
          id: 'goal_3',
          title: 'Maintain daily meditation streak',
          lane: 'Mind',
          isCompleted: false,
          priority: 1,
        ),
      ],
      reflectionNote: null,
      overallRating: 0,
      isCompleted: false,
      completedAt: null,
    );

    return _currentReview!;
  }

  @override
  Future<ReviewHistory> loadReviewHistory() async {
    await Future.delayed(const Duration(milliseconds: 180));

    final pastReviews = <WeeklyReviewData>[];
    final ratings = [4, 3, 5, 4, 3, 4];
    final moods = [
      ReviewMood.good,
      ReviewMood.neutral,
      ReviewMood.amazing,
      ReviewMood.good,
      ReviewMood.bad,
      ReviewMood.good,
    ];

    for (int i = 0; i < 6; i++) {
      final weekStart =
          DateTime(2026, 9, 15).subtract(Duration(days: (i + 1) * 7));
      pastReviews.add(
        WeeklyReviewData(
          id: 'review_past_$i',
          weekStart: weekStart,
          weekEnd: weekStart.add(const Duration(days: 6)),
          mood: moods[i],
          wins: [
            WeeklyWin(
              id: 'past_win_${i}_1',
              title: 'Completed weekly targets',
              lane: 'Mind',
              date: weekStart.add(const Duration(days: 3)),
            ),
          ],
          lessons: [
            WeeklyLesson(
              id: 'past_lesson_${i}_1',
              content: 'Keep pushing forward with daily habits',
              category: 'habit',
              isActionable: true,
            ),
          ],
          laneScores: [
            LaneReviewScore(
              laneName: 'Mind',
              colorValue: 0xFF8B5CF6,
              iconCodePoint: 0xe0f0,
              score: 5.0 + (i % 4),
              actionsCompleted: 3 + (i % 3),
              highlight: 'Stayed consistent with journaling',
            ),
            LaneReviewScore(
              laneName: 'Body',
              colorValue: 0xFF34D399,
              iconCodePoint: 0xe566,
              score: 4.0 + (i % 5),
              actionsCompleted: 2 + (i % 4),
              highlight: 'Completed workout sessions',
            ),
            LaneReviewScore(
              laneName: 'Social',
              colorValue: 0xFF22D3EE,
              iconCodePoint: 0xe7fb,
              score: 3.0 + (i % 4),
              actionsCompleted: 1 + (i % 3),
              highlight: 'Connected with community',
            ),
            LaneReviewScore(
              laneName: 'Skill',
              colorValue: 0xFFF59E0B,
              iconCodePoint: 0xe80c,
              score: 5.0 + (i % 3),
              actionsCompleted: 2 + (i % 3),
              highlight: 'Progressed on course material',
            ),
          ],
          nextWeekGoals: [],
          overallRating: ratings[i],
          isCompleted: true,
          completedAt: weekStart.add(const Duration(days: 6, hours: 20)),
        ),
      );
    }

    return ReviewHistory(
      pastReviews: pastReviews,
      totalReviewsCompleted: 6,
      averageRating: 3.8,
      currentReviewStreak: 4,
    );
  }

  @override
  Future<WeeklyReviewData> saveReview(WeeklyReviewData review) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentReview = review;
    return review;
  }

  @override
  Future<void> updateMood(String reviewId, ReviewMood mood) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_currentReview != null && _currentReview!.id == reviewId) {
      _currentReview = _currentReview!.copyWith(mood: mood);
    }
  }

  @override
  Future<WeeklyReviewData> completeReview(String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_currentReview != null && _currentReview!.id == reviewId) {
      _currentReview = _currentReview!.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
    }
    return _currentReview!;
  }
}

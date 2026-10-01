import '../data/emin_personal_content.dart';
import '../models/ai_coach.dart';
import 'ai_coach_gateway.dart';

class MockAiCoachGateway implements AiCoachGateway {
  @override
  Future<CoachData> loadCoachData() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return CoachData(
      insights: [
        CoachInsight(
          id: 'ins_1',
          type: InsightType.pattern,
          title: 'Morning consistency detected',
          message:
              'You\'ve completed morning check-ins 7 days in a row. Your mood scores are 23% higher on days you check in before 8 AM.',
          relatedLane: 'Mind',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CoachInsight(
          id: 'ins_2',
          type: InsightType.celebration,
          title: 'Body lane breakthrough!',
          message:
              'Your Body lane score jumped from 58 to 85 this week. That\'s your fastest lane improvement yet. Keep pushing!',
          relatedLane: 'Body',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        CoachInsight(
          id: 'ins_3',
          type: InsightType.nudge,
          title: 'Social lane needs attention',
          message:
              'Your Social lane has been below 60 for 5 days. Try connecting with someone from the Brotherhood or posting a win in the feed today.',
          actionLabel: 'Open Social Feed',
          actionRoute: '/social-feed',
          relatedLane: 'Social',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        CoachInsight(
          id: 'ins_4',
          type: InsightType.tip,
          title: 'Optimize your evening ritual',
          message:
              'Data shows your day ratings are 0.8 points higher when you do evening check-ins. Consider adding a 5-minute reflection habit.',
          actionLabel: 'Evening Check-in',
          actionRoute: '/daily-checkin',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CoachInsight(
          id: 'ins_5',
          type: InsightType.warning,
          title: 'Streak at risk',
          message:
              'You haven\'t logged any Skill lane activity today. Complete one action to protect your 12-day streak.',
          actionLabel: 'Go to Actions',
          actionRoute: '/home',
          relatedLane: 'Skill',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        CoachInsight(
          id: 'ins_6',
          type: InsightType.pattern,
          title: 'Weekend dip detected',
          message:
              'Your activity drops 40% on weekends. Setting up a lighter weekend routine could help maintain momentum without burnout.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
        ),
      ],
      dailyTip: _todaysTip(),
      preferredTone: CoachTone.motivational,
      streakDays: 14,
      overallScore: 72.5,
      laneScores: {
        'Mind': 78.0,
        'Body': 85.0,
        'Social': 55.0,
        'Skill': 72.0,
      },
    );
  }

  @override
  Future<void> markInsightRead(String insightId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> dismissInsight(String insightId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> toggleTipBookmark(String tipId) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> setPreferredTone(CoachTone tone) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Rotates through [eminCoachTips], one per calendar day.
  DailyCoachTip _todaysTip() {
    final now = DateTime.now();
    final dayNumber =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final tip = eminCoachTips[dayNumber % eminCoachTips.length];
    final lane = tip.lane.isEmpty
        ? tip.lane
        : tip.lane[0].toUpperCase() + tip.lane.substring(1);
    return tip.copyWith(lane: lane, date: now);
  }
}

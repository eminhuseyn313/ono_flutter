// ============================================================
// EMIN HUSEYNZADE — RITUAL STEPS AND DAILY COACH NOTES
// ============================================================
// Structured profile content lives in emin_system.dart; this file holds
// the morning ritual steps and the 30 Month-1 coach notes.
// ============================================================

import '../models/ritual.dart';
import '../models/ai_coach.dart';
import '../time.dart';
import 'plan_content.dart';

// ============================================================
// 3. YOUR MORNING RITUAL SEQUENCE
// ============================================================

/// The plan's morning ritual (empty without a plan).
List<RitualStep> get eminMorningRitual => plan.ritual;

/// The plan's daily coach notes, in order.
List<DailyCoachTip> get eminCoachTips {
  final now = timeNow();
  return [for (final m in plan.coachTips) tipFromJson(m, now)];
}

/// The plan's weekly review questions.
List<String> get eminWeeklyReviewQuestions => plan.weeklyReviewQuestions;

/// Coach note for a program day. Days 1–30 follow the Month-1 sequence;
/// after that only notes that don't name a specific day or week repeat.
DailyCoachTip coachTipForDay(int programDay) {
  final tips = eminCoachTips;
  if (tips.isEmpty) {
    return DailyCoachTip(
        id: 'tip_none', title: '', content: '', lane: 'mind', laneColorValue: 0xFF8EA4D2, date: timeNow());
  }
  if (programDay >= 1 && programDay <= tips.length) {
    return tips[programDay - 1];
  }
  final evergreen = tips
      .where((t) =>
          !RegExp(r'\b(Day|Week|Month) ?\d', caseSensitive: false)
              .hasMatch('${t.title} ${t.content}'))
      .toList();
  return evergreen[(programDay - 1) % evergreen.length];
}

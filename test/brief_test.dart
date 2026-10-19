import 'package:flutter_test/flutter_test.dart';

import 'package:ono/models/personal_system.dart';
import 'package:ono/services/brief_generator.dart';

BriefInput _input({
  double avg = 2,
  int itemCount = 5,
  int daysCounted = 7,
  Map<String, String> cues = const {},
  String best = '',
  String hardest = '',
  int excused = 0,
  int week = 1,
}) =>
    BriefInput(
      report: WeeklyReport(
          id: 'r',
          weekStart: DateTime(2026, 10, 5),
          nonNegotiableAverage: avg,
          gymSessions: 0,
          bestMoment: best,
          hardestMoment: hardest,
          workSituation: '',
          createdAt: DateTime(2026, 10, 11)),
      forWeek: DateTime(2026, 10, 12),
      programMonth: 1,
      programWeek: week,
      excusedDays: excused,
      itemRates: const {'d_walk': 0.2, 'd_read': 0.4, 'd_water': 0.9},
      itemTitles: const {'d_walk': 'Walk', 'd_read': 'Read', 'd_water': 'Water'},
      itemCount: itemCount,
      itemCues: cues,
      daysCounted: daysCounted,
      evidenceAddedThisWeek: 0,
      artifactsThisMonth: 0,
      postsThisWeek: 0,
      gymDays: const [],
      openUnlocks: const [],
      builtInPlan: false,
    );

void main() {
  test('a partial first week gets no verdict and no "shrink the list"', () async {
    final b = await DeviceBriefGenerator().generate(_input(daysCounted: 3));
    expect(b.headline, contains('first 3 days'));
    expect(b.headline, isNot(contains('Reset week')));
    expect(b.adjustments.join(' '), isNot(contains('Shrink')));
    final full = await DeviceBriefGenerator().generate(_input());
    expect(full.headline, contains('Reset week'));
    expect(full.adjustments.join(' '), contains('Shrink the list'));
  });

  test('a list already at its minimum is not told to shrink', () async {
    final b = await DeviceBriefGenerator().generate(_input(itemCount: 3, avg: 1));
    expect(b.adjustments.join(' '), isNot(contains('Shrink')));
  });

  test('the brief quotes their own plan and moments', () async {
    final b = await DeviceBriefGenerator().generate(_input(
        cues: const {'d_walk': 'After lunch, I walk around the block'},
        best: 'Finished the draft early',
        hardest: 'Snapped at my brother'));
    expect(b.tasks.join(' '), contains('Your plan: "After lunch, I walk around the block"'));
    expect(b.tasks.join(' '), contains('Protect "Read": tie it'));
    final all = b.adjustments.join(' ');
    expect(all, contains('"Snapped at my brother"'));
    expect(all, contains('Best moment: "Finished the draft early"'));
  });

  test('the device brief asks whether applied learning held', () async {
    final input = BriefInput(
      report: WeeklyReport(
          id: 'r', weekStart: DateTime(2026, 10, 5), nonNegotiableAverage: 4,
          gymSessions: 0, bestMoment: '', hardestMoment: '', workSituation: '',
          createdAt: DateTime(2026, 10, 11)),
      forWeek: DateTime(2026, 10, 12), programMonth: 1, programWeek: 2,
      itemRates: const {'d_walk': 0.8}, itemCount: 5,
      evidenceAddedThisWeek: 0, artifactsThisMonth: 0, postsThisWeek: 0,
      gymDays: const [], openUnlocks: const [], builtInPlan: false,
      learningApplied: const ['Atomic Habits: make it obvious (experiment: shoes by the door)'],
    );
    final b = await DeviceBriefGenerator().generate(input);
    expect(b.adjustments.join(' '),
        contains('You took "make it obvious" from Atomic Habits. Did the experiment hold?'));
  });

  test('the first two weeks: basics and what they did, not every shortfall', () async {
    final input = BriefInput(
      report: WeeklyReport(
          id: 'r', weekStart: DateTime(2026, 10, 5), nonNegotiableAverage: 4,
          gymSessions: 0, bestMoment: '', hardestMoment: '', workSituation: '',
          createdAt: DateTime(2026, 10, 11)),
      forWeek: DateTime(2026, 10, 12), programMonth: 1, programWeek: 1,
      itemRates: const {'d_walk': 0.8}, itemCount: 5,
      evidenceAddedThisWeek: 0, artifactsThisMonth: 0, postsThisWeek: 0,
      gymDays: const [], openUnlocks: const [], builtInPlan: false,
      restPlanned: false, shutdowns: 1,
      wins: const ['Called my sister'],
    );
    final b = await DeviceBriefGenerator().generate(input);
    final all = b.adjustments.join(' ');
    expect(all, isNot(contains('Deep work')));
    expect(all, isNot(contains('No rest planned')));
    expect(all, isNot(contains('Evening shutdown')));
    expect(all, contains('the first: "Called my sister"'));
    expect(input.toJson()['wins_logged_this_week'], 1);
    expect(input.toJson().toString(), isNot(contains('Called my sister')),
        reason: 'only the count leaves the device');
  });

  test('the coach gets the plan type, never built-in fields or weight for others',
      () {
    final json = _input().toJson();
    expect(json['built_in_plan'], isFalse);
    for (final k in ['posts_this_week', 'gym_days', 'open_unlocks', 'artifacts_this_month',
        'shoulder_flag_mornings', 'readiness_gap', 'latest_weight_kg']) {
      expect(json.containsKey(k), isFalse, reason: k);
    }
  });

  test('a week mostly sick or resting gets no verdict and no "shrink"',
      () async {
    final b = await DeviceBriefGenerator().generate(_input(avg: 1, excused: 5, week: 3));
    expect(b.headline, contains('rest or illness'));
    expect(b.adjustments.join(' '), isNot(contains('Shrink')));
  });

  test('reps without feedback get one line', () async {
    final input = _input();
    final b = await DeviceBriefGenerator().generate(BriefInput(
      report: input.report,
      forWeek: input.forWeek,
      programMonth: 1,
      programWeek: 3,
      itemRates: input.itemRates,
      itemTitles: input.itemTitles,
      itemCount: input.itemCount,
      daysCounted: 7,
      evidenceAddedThisWeek: 0,
      artifactsThisMonth: 0,
      postsThisWeek: 0,
      gymDays: const [],
      openUnlocks: const [],
      builtInPlan: false,
      repsWithoutFeedback: (3, 4),
    ));
    expect(b.adjustments.join(' '), contains('no feedback'));
    expect(input.toJson().containsKey('reps_this_month_without_feedback'), isFalse);
  });
}

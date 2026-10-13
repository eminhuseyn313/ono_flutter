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
      programWeek: 1,
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
}

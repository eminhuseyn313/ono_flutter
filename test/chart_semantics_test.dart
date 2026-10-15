import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/widgets/ono_charts.dart';
import 'package:ono/widgets/ono_ui.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 360, child: child)));

void main() {
  testWidgets('charts say what they show to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(Column(children: [
      const WeekBars(scores: [7, 9, null, null, null, null, null], todayIndex: 1),
      TrendLine(
        points: [
          (x: DateTime(2026, 9, 1), y: 82.4),
          (x: DateTime(2026, 10, 1), y: 80.0),
        ],
        bandLow: 76,
        bandHigh: 78,
        unit: 'kg',
      ),
      const ScoreRing(progress: 0.5),
    ])));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Monday: 7 of 10'), findsOneWidget);
    expect(find.bySemanticsLabel('Tuesday, today: 9 of 10'), findsOneWidget);
    expect(find.bySemanticsLabel('Wednesday: nothing yet'), findsOneWidget);
    expect(
        find.bySemanticsLabel('2 entries, from 82.4 kg to 80 kg, target 76 kg to 78 kg'),
        findsOneWidget);
    expect(
        tester.getSemantics(find.byType(ScoreRing)),
        matchesSemantics(value: '50 percent'));
    handle.dispose();
  });
}

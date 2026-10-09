import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ono/data/emin_system.dart';
import 'package:ono/services/brief_generator.dart';
import 'package:ono/models/personal_system.dart';

/// ONO is built to become a general app: features read names, roles and
/// goals from the profile, never from strings in the code. His details
/// live only in lib/data/.
void main() {
  test('screens, logic and the coach never hard-code one person\'s life', () {
    final banned = RegExp(
        r"\bAli\b|Rustam|Business ID|PASHA|Kapital|Bir Ecosystem|BirBank|Head of Product|Azerbaijan|Baku|\bEmin\b");
    final offenders = <String>[];
    for (final dir in ['lib/screens', 'lib/providers', 'lib/services', 'lib/widgets', 'supabase/functions']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') && !f.path.endsWith('.ts')) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (banned.hasMatch(lines[i]) || lines[i].contains('EminIdentity')) {
            offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the profile drives names, roles and the coach', () async {
    expect(activeProfile.manager, 'Ali');
    expect(activeProfile.keyPeopleNames, 'Ali and Rustam');
    expect(keyPeople, ['Ali', 'Rustam']);
    final input = BriefInput(
      report: WeeklyReport(
          id: 'r',
          weekStart: DateTime(2026, 10, 5),
          nonNegotiableAverage: 7,
          gymSessions: 3,
          bestMoment: '',
          hardestMoment: '',
          workSituation: '',
          createdAt: DateTime(2026, 10, 11)),
      forWeek: DateTime(2026, 10, 12),
      programMonth: 2,
      programWeek: 6,
      itemRates: const {'sigh': 0.5, 'bed': 0.9},
      evidenceAddedThisWeek: 0,
      artifactsThisMonth: 0,
      postsThisWeek: 0,
      gymDays: const [1, 3, 5],
      openUnlocks: const [],
      deepWorkHours: 1,
      energyPeak: 'morning (9:00–12:00)',
    );
    expect(input.toJson()['energy_peak'], 'morning (9:00–12:00)');
    final brief = await DeviceBriefGenerator().generate(input);
    expect(brief.adjustments.join(' '), contains('in your morning (9:00–12:00)'));
    final json = input.toJson()['profile'] as Map;
    expect(json['target_role'], activeProfile.targetRole);
    expect((json['key_people'] as List).first['primary'], isTrue);
    expect(json['context'], isNotEmpty);
  });
}

import '../data/emin_system.dart';
import '../models/personal_system.dart';

/// Everything a coach needs to answer a Sunday report.
class BriefInput {
  final WeeklyReport report;
  final DateTime forWeek;
  final int programMonth;
  final int programWeek;
  final Map<String, double> itemRates; // Daily 10 id → completion rate
  final int evidenceAddedThisWeek;
  final int artifactsThisMonth;
  final int postsThisWeek;
  final List<int> gymDays;
  final List<String> openUnlocks;
  final double? latestWeight;

  const BriefInput({
    required this.report,
    required this.forWeek,
    required this.programMonth,
    required this.programWeek,
    required this.itemRates,
    required this.evidenceAddedThisWeek,
    required this.artifactsThisMonth,
    required this.postsThisWeek,
    required this.gymDays,
    required this.openUnlocks,
    this.latestWeight,
  });

  Map<String, dynamic> toJson() => {
        'report': report.toJson(),
        'for_week': dateKey(forWeek),
        'program_month': programMonth,
        'program_week': programWeek,
        'phase': phaseFor(programMonth).name,
        'month_theme': monthThemes[programMonth],
        'artifact_of_month': artifactFor(programMonth),
        'book_of_month': currentBook(programMonth).title,
        'item_rates': itemRates,
        'evidence_added_this_week': evidenceAddedThisWeek,
        'artifacts_this_month': artifactsThisMonth,
        'posts_this_week': postsThisWeek,
        'gym_days': gymDays,
        'open_unlocks': openUnlocks,
        'latest_weight_kg': latestWeight,
      };
}

abstract class BriefGenerator {
  Future<WeeklyBrief> generate(BriefInput input);
}

/// Rule-based coach that runs on the device, from real data only. Used
/// offline and as the fallback when the AI coach is unreachable.
class DeviceBriefGenerator implements BriefGenerator {
  static const _taskFor = {
    'manifesto': 'Manifesto before the phone, every morning — it is step 2 of the 06:05 ritual.',
    'scan': 'Domain scan at 07:45 at your desk, before email. 15 minutes, one insight saved.',
    'sigh': 'Sigh ×3 in the car before entering the office, and before every meeting with Ali.',
    'bluf': 'Rewrite your first Slack/email of each day in BLUF: decision, 3 reasons, ask, deadline.',
    'pause': 'In every meeting: one breath before answering anything challenging.',
    'read': 'Lunch read: 20 minutes, phone face-down, before anything else.',
    'feynman': 'After each read, 5 minutes writing from memory — no notes.',
    'caffeine': 'Last coffee before 13:00. Swap the afternoon one for water.',
    'protein': 'Hit 150g protein: log each meal; front-load breakfast with 40g.',
    'bed': 'In bed 22:30 Sun–Thu. Wind-down alarm at 22:00, phone outside the room.',
  };

  static const _titleFor = {
    'manifesto': 'Manifesto',
    'scan': 'Domain scan',
    'sigh': 'Physiological sigh',
    'bluf': 'BLUF',
    'pause': 'Deliberate pause',
    'read': 'Lunch read',
    'feynman': 'Feynman write',
    'caffeine': 'No caffeine after 1pm',
    'protein': 'Protein',
    'bed': 'Bed by 22:30',
  };

  @override
  Future<WeeklyBrief> generate(BriefInput input) async {
    final r = input.report;
    final avg = r.nonNegotiableAverage;
    final rates = input.itemRates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakest = rates.take(2).map((e) => e.key).toList();
    final strongest = rates.isEmpty ? null : rates.last.key;

    final headline = avg >= 8
        ? 'Strong week (${avg.toStringAsFixed(1)}/10). Hold the line and raise one bar.'
        : avg >= 6
            ? 'Solid week (${avg.toStringAsFixed(1)}/10). Tighten ${_titleFor[weakest.first]} and ${_titleFor[weakest.last]}.'
            : 'Reset week (${avg.toStringAsFixed(1)}/10). Fewer, firmer commitments.';

    final tasks = <String>[
      for (final id in weakest) _taskFor[id]!,
    ];
    if (r.gymSessions < 3) {
      final names = [
        for (var i = 0; i < 3; i++)
          '${_dayName(input.gymDays[i])} ${gymPlan[i].name}'
      ].join(' / ');
      tasks.add('Three sessions at 19:00: $names. Face pulls every time.');
    }
    if (input.openUnlocks.isNotEmpty) {
      tasks.add('This month\'s open item: ${input.openUnlocks.first}.');
    }
    if (input.artifactsThisMonth == 0) {
      tasks.add(
          'Block 2 × 45 min for the artifact of the month: ${artifactFor(input.programMonth)}.');
    }
    if (input.programMonth >= 2 && input.postsThisWeek < 2) {
      tasks.add('Publish 2 LinkedIn posts (Tue + Thu). Hook → insight → example → question.');
    }
    if (r.workSituation.trim().isNotEmpty) {
      tasks.add('Before the meeting about this situation: six-questions-deep prep.');
    }

    // Domain brief: next week's rotation + one fact to own.
    final fact = keyData[input.programWeek % keyData.length];
    final rotation = domainScanRotation
        .where((d) => d.weekday <= DateTime.friday)
        .map((d) => '${_dayName(d.weekday).substring(0, 3)} ${d.title}')
        .join(' · ');
    final domainBrief = 'Scan rotation: $rotation.\n\n'
        'Fact to own this week — ${fact[0]}: ${fact[1]}.\n'
        'Write one sentence connecting it to Business ID and use it in a meeting.';

    final situation = r.workSituation.trim();
    final coaching = situation.isEmpty
        ? 'No work situation reported. Pick the meeting you most want to go well next week and run six-questions-deep on it.'
        : 'Situation: "${_clip(situation, 160)}"\n\n'
            '1. Decide your position and write it as BLUF: the decision first, three reasons, what you need, by when.\n'
            '2. Six questions deep: the six hardest questions Ali could ask about this, your answer to each, and the hardest follow-up.\n'
            '3. In the room: sigh ×3 beforehand, say "I am excited", still body, one breath before every answer, downward inflection.\n'
            '4. Afterwards: log what held and what didn\'t; if it went well, it goes in the Evidence Archive.';

    final adjustments = <String>[
      if (avg < 6)
        'Shrink to the core five next week: manifesto, scan, BLUF, protein, bed. Add the rest back when you hold 5/5.',
      if (r.gymSessions < 2)
        'If a weekday slips, move the session to Saturday morning rather than skipping it.',
      if (input.evidenceAddedThisWeek < 5)
        'Evidence Archive: add ${5 - input.evidenceAddedThisWeek} more items tonight — the impostor feeds on forgetting.',
      if (r.hardestMoment.trim().isNotEmpty)
        'Hardest moment noted. Ask: what would the Product Architect do differently? Write the answer as one rule.',
      if (strongest != null && (input.itemRates[strongest] ?? 0) >= 0.85)
        '${_titleFor[strongest]} is becoming automatic — keep it, stop thinking about it.',
    ];

    return WeeklyBrief(
      id: 'brief_${dateKey(input.forWeek)}',
      weekStart: input.forWeek,
      createdAt: DateTime.now(),
      source: 'device',
      headline: headline,
      tasks: tasks.take(6).toList(),
      domainBrief: domainBrief,
      coaching: coaching,
      adjustments: adjustments,
    );
  }

  static String _dayName(int weekday) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][weekday - 1];

  static String _clip(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n).trimRight()}…';
}

/// Asks the `weekly-brief` Supabase function (Claude) for the brief and
/// falls back to the on-device coach if it is unreachable or not set up.
class RemoteBriefGenerator implements BriefGenerator {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
      invoke;
  final BriefGenerator fallback;

  RemoteBriefGenerator(this.invoke, {BriefGenerator? fallback})
      : fallback = fallback ?? DeviceBriefGenerator();

  @override
  Future<WeeklyBrief> generate(BriefInput input) async {
    try {
      final r = await invoke(input.toJson());
      if (r['error'] != null) throw Exception(r['error']);
      return WeeklyBrief(
        id: 'brief_${dateKey(input.forWeek)}',
        weekStart: input.forWeek,
        createdAt: DateTime.now(),
        source: 'ai',
        headline: r['headline'] as String,
        tasks: List<String>.from(r['tasks'] as List),
        domainBrief: r['domain_brief'] as String,
        coaching: r['coaching'] as String,
        adjustments: List<String>.from(r['adjustments'] as List? ?? const []),
      );
    } catch (_) {
      return fallback.generate(input);
    }
  }
}

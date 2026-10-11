import 'dart:convert';

import 'daily_library.dart';
import 'emin_system.dart';
import 'growth_templates.dart';

/// A goal shape inside a plan pack: no numbers, no dates — the person
/// makes it theirs.
class PackGoal {
  final String title;
  final String obstacle;
  final String plan;
  final int months;
  const PackGoal(this.title, {this.obstacle = '', this.plan = '', this.months = 6});

  Map<String, dynamic> toJson() =>
      {'title': title, 'obstacle': obstacle, 'plan': plan, 'months': months};

  factory PackGoal.fromJson(Map m) => PackGoal('${m['title'] ?? ''}',
      obstacle: '${m['obstacle'] ?? ''}',
      plan: '${m['plan'] ?? ''}',
      months: (m['months'] as num?)?.toInt() ?? 6);
}

/// A plan anyone can start from or pass on: growth areas with drills, a
/// goal shape, daily items with their if–then cues, and things to stop.
/// Never holds names, logs or numbers.
class PlanPack {
  final String name;
  final String forWho;
  final String summary;
  final List<GrowthArea> areas;
  final PackGoal? goal;
  final List<DailyIdea> daily;
  final List<String> stops;
  const PlanPack(this.name,
      {this.forWho = '',
      this.summary = '',
      this.areas = const [],
      this.goal,
      this.daily = const [],
      this.stops = const []});

  static const header = 'ONO plan';

  Map<String, dynamic> toJson() => {
        'v': 1,
        'name': name,
        'for': forWho,
        'summary': summary,
        'areas': [for (final a in areas) a.toJson()],
        if (goal != null) 'goal': goal!.toJson(),
        'daily': [
          for (final d in daily)
            {'title': d.title, 'lane': d.lane, 'when': d.when, 'cue': d.cue}
        ],
        'stops': stops,
      };

  factory PlanPack.fromJson(Map m) => PlanPack(
        '${m['name'] ?? 'A shared plan'}',
        forWho: '${m['for'] ?? ''}',
        summary: '${m['summary'] ?? ''}',
        areas: [
          for (final a in (m['areas'] as List? ?? const []))
            GrowthArea.fromJson(a as Map)
        ],
        goal: m['goal'] is Map ? PackGoal.fromJson(m['goal'] as Map) : null,
        daily: [
          for (final d in (m['daily'] as List? ?? const []))
            if (d is Map && '${d['title'] ?? ''}'.trim().isNotEmpty)
              DailyIdea('${d['title']}', '${d['lane'] ?? 'mind'}',
                  '${d['when'] ?? 'day'}', '', '${d['cue'] ?? ''}')
        ],
        stops: [for (final s in (m['stops'] as List? ?? const [])) '$s'],
      );

  /// Text to paste into a message: a readable first line, then the plan.
  String toText() => '$header: $name\n${jsonEncode(toJson())}';

  /// Reads a pack from pasted text, or null if there is none in it.
  static PlanPack? fromText(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final m = jsonDecode(text.substring(start, end + 1));
      if (m is! Map || m['name'] == null) return null;
      return PlanPack.fromJson(m);
    } catch (_) {
      return null;
    }
  }
}

GrowthArea _template(String id) => areaTemplates.firstWhere((t) => t.id == id);

DailyIdea _idea(String title) => dailyLibrary.firstWhere((d) => d.title == title);

/// Plans to start from. General: nothing here names a person or employer.
final List<PlanPack> planPacks = [
  PlanPack('New people manager',
      forWho: 'Your first months leading a team',
      summary: 'Lead through clear priorities, real conversations and protected thinking time.',
      areas: [_template('t_people_leader')],
      goal: const PackGoal('Lead a team that trusts me and delivers',
          obstacle: 'Doing the work myself instead of growing them',
          plan: 'When I want to take a task back, I ask one coaching question first.'),
      daily: [
        _idea('Write today\'s three priorities'),
        _idea('One focused block on the most important work'),
        const DailyIdea('One real conversation with someone on the team', 'social', 'day', 'career',
            'When I walk past someone\'s desk or open chat, I ask how their week is really going.'),
        _idea('Close the day: tomorrow\'s three on paper'),
      ],
      stops: const ['Answering every message within minutes']),
  PlanPack('First half marathon',
      forWho: 'From running sometimes to race day',
      summary: 'Consistent training, real recovery and the food and sleep to carry it.',
      areas: [_template('t_strength'), _template('t_health')],
      goal: const PackGoal('Finish my first half marathon',
          obstacle: 'Skipping runs when the day gets busy',
          plan: 'When a run day gets busy, I do 20 minutes instead of nothing.',
          months: 6),
      daily: [
        _idea('Move for 30 minutes'),
        _idea('Protein with every meal'),
        _idea('In bed by a fixed time'),
      ],
      stops: const ['Late-night scrolling before a run day']),
  PlanPack('Calmer parent',
      forWho: 'More patience, more presence at home',
      summary: 'Notice the moment before you snap, and give your kids your full attention daily.',
      areas: [_template('t_parenting'), _template('t_calm')],
      goal: const PackGoal('Respond calmly in the hard moments at home',
          obstacle: 'Arriving home already drained',
          plan: 'When I park, I take three slow breaths before I go in.',
          months: 3),
      daily: [
        _idea('Undistracted time with the kids'),
        _idea('Three slow breaths before hard moments'),
        _idea('Write three lines about the day'),
      ],
      stops: const ['Phone at the dinner table']),
  PlanPack('Money reset',
      forWho: 'Out of money worry, towards a safety net',
      summary: 'See where it goes, pause the impulse, and build three months of expenses.',
      areas: [_template('t_money')],
      goal: const PackGoal('Three months of expenses saved',
          obstacle: 'Spending to feel better after a hard day',
          plan: 'When I want to buy after a hard day, I put it on a list for tomorrow.',
          months: 12),
      daily: [
        _idea('Log what I spent today'),
        _idea('A 24-hour pause before any non-essential buy'),
        _idea('Ten minutes outside without the phone'),
      ],
      stops: const ['Shopping apps on the home screen']),
  PlanPack('Learn a language',
      forWho: 'Speak with confidence in a new language',
      summary: 'Short daily practice, real conversations and ideas explained out loud.',
      areas: [_template('t_learning')],
      goal: const PackGoal('Hold a 20-minute conversation in the new language',
          obstacle: 'Studying alone and never speaking',
          plan: 'When I finish a lesson, I say three sentences out loud to someone.'),
      daily: [
        _idea('Practise the skill I\'m building for 20 minutes'),
        _idea('Explain one new idea in my own words'),
        _idea('Read 20 pages'),
      ]),
];

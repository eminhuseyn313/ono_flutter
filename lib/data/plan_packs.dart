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

  factory PackGoal.fromJson(Map m) => PackGoal(_clip(m['title']),
      obstacle: _clip(m['obstacle'], 400),
      plan: _clip(m['plan'], 400),
      months: ((m['months'] is num ? m['months'] as num : 6).toInt()).clamp(1, 18));
}

/// Pasted text is someone else's: kept short, trimmed, never null.
String _clip(Object? v, [int max = 200]) {
  final t = (v ?? '').toString().trim();
  return t.length <= max ? t : t.substring(0, max);
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
            {
              'title': d.title,
              'lane': d.lane,
              'when': d.when,
              'cue': d.cue,
              if (d.minimum.isNotEmpty) 'min': d.minimum,
              if (d.steps.isNotEmpty) 'steps': d.steps,
            }
        ],
        'stops': stops,
      };

  /// Reads a pack, keeping only what makes sense: named areas (at most
  /// 6, 10 drills each), daily items with distinct titles (at most 15),
  /// known lanes and times, and up to 10 distinct stops.
  factory PlanPack.fromJson(Map m) {
    List list(Object? v) => v is List ? v : const [];
    final titles = <String>{};
    final stops = <String>{};
    return PlanPack(
      _clip(m['name'], 80).isEmpty ? 'A shared plan' : _clip(m['name'], 80),
      forWho: _clip(m['for']),
      summary: _clip(m['summary'], 400),
      areas: [
        for (final a in list(m['areas']))
          if (a is Map && _clip(a['name'], 80).isNotEmpty)
            (() {
              final g = GrowthArea.fromJson(a);
              return g.copyWith(
                  name: _clip(g.name, 80), drills: g.drills.take(10).toList());
            })()
      ].take(6).toList(),
      goal: m['goal'] is Map && _clip((m['goal'] as Map)['title']).isNotEmpty
          ? PackGoal.fromJson(m['goal'] as Map)
          : null,
      daily: [
        for (final d in list(m['daily']))
          if (d is Map &&
              _clip(d['title'], 120).isNotEmpty &&
              titles.add(_clip(d['title'], 120).toLowerCase()))
            DailyIdea(
                _clip(d['title'], 120),
                const {'mind', 'body', 'skill', 'social'}.contains(d['lane']) ? '${d['lane']}' : 'mind',
                const {'morning', 'day', 'evening'}.contains(d['when']) ? '${d['when']}' : 'day',
                '',
                _clip(d['cue'], 300),
                minimum: _clip(d['min'], 120),
                steps: [
                  for (final s in list(d['steps']))
                    if (_clip(s, 80).isNotEmpty) _clip(s, 80)
                ].take(12).toList())
      ].take(15).toList(),
      stops: [
        for (final s in list(m['stops']))
          if (_clip(s).isNotEmpty && stops.add(_clip(s).toLowerCase())) _clip(s)
      ].take(10).toList(),
    );
  }

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
            'When I walk past someone\'s desk or open chat, I ask how their week is really going.',
            minimum: 'One genuine question in chat'),
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
  PlanPack('Sleep reset',
      forWho: 'Four weeks to steadier sleep and energy',
      summary: 'Fixed times, screens out, caffeine curfew, morning light.',
      areas: [_template('t_sleep')],
      goal: const PackGoal('Wake rested on most mornings',
          obstacle: 'Scrolling in bed because it feels like the only free time',
          plan: 'When I want to scroll in bed, I read paper for ten minutes instead.',
          months: 3),
      daily: [
        _idea('Lights out at the same time'),
        _idea('Water before coffee'),
        _idea('No phone for the first 30 minutes'),
      ],
      stops: const ['Phone in the bedroom']),
  PlanPack('Founder\'s first year',
      forWho: 'From idea to first paying customers',
      summary: 'Talk to customers weekly, ship small things often, watch one number.',
      areas: [_template('t_founder')],
      goal: const PackGoal('Ten paying customers',
          obstacle: 'Building in private instead of asking',
          plan: 'When I want to add a feature, I talk to a customer first.',
          months: 12),
      daily: [
        _idea('Write today\'s three priorities'),
        _idea('One focused block on the most important work'),
        _idea('Ask someone a real question'),
      ],
      stops: const ['Polishing before anyone has seen it']),
  PlanPack('Exam season',
      forWho: 'Students with exams in the next few months',
      summary: 'Test yourself instead of re-reading, spread it out, and sleep — memory is made at night.',
      areas: [_template('t_learning'), _template('t_sleep')],
      goal: const PackGoal('Walk into my exams prepared and rested',
          obstacle: 'Cramming late and re-reading instead of testing myself',
          plan: 'When I sit down to study, I write what I remember before I open my notes.',
          months: 3),
      daily: [
        const DailyIdea('Test myself on yesterday\'s material', 'skill', 'morning', 'growth',
            'When I open my desk, I close my notes and write what I remember first.',
            minimum: 'Three questions from memory'),
        _idea('One focused block on the most important work'),
        _idea('Move for 30 minutes'),
        _idea('Lights out at the same time'),
      ],
      stops: const ['Studying with the phone on the desk']),
  PlanPack('New parent',
      forWho: 'The first year with a baby',
      summary: 'Stay a team with your partner, rest when you can, and lower the bar on everything else.',
      areas: [_template('t_parenting'), _template('t_relationships')],
      goal: const PackGoal('Come through the first year as a team',
          obstacle: 'Running on empty and snapping at each other',
          plan: 'When we are both at our limit, we say so and take turns for a 20-minute break.',
          months: 12),
      daily: [
        _idea('Ten minutes of full attention for my partner'),
        const DailyIdea('Rest when the baby sleeps, once a day', 'body', 'day', 'health',
            'When the baby goes down for a nap, I lie down before I start any chores.',
            minimum: 'Ten minutes with my eyes closed'),
        _idea('Say one specific thank-you'),
        _idea('Ten minutes outside without the phone'),
      ],
      stops: const ['Keeping score of who did more']),
  PlanPack('Back from burnout',
      forWho: 'Getting your energy back after running empty',
      summary: 'Rest on purpose, protect your evenings, add back one thing at a time — and see a doctor if it doesn\'t lift.',
      areas: [_template('t_calm'), _template('t_health')],
      goal: const PackGoal('Get my energy back and keep it',
          obstacle: 'Saying yes to everything as soon as I feel a little better',
          plan: 'When I\'m asked for something new, I say "let me check my week" and decide tomorrow.',
          months: 6),
      daily: [
        const DailyIdea('Stop work at a set time', 'mind', 'evening', 'mind',
            'When my stop-time alarm goes, I write tomorrow\'s first step and close the laptop.',
            minimum: 'Close the laptop, even if late'),
        _idea('Ten minutes outside without the phone'),
        _idea('Do one thing just for joy'),
        _idea('In bed by a fixed time'),
      ],
      stops: const ['Checking work messages after my stop time']),
  PlanPack('Career change',
      forWho: 'Moving into a new field within a year',
      summary: 'Build the skill in public, talk to people who do the job, and make small bets before the big jump.',
      areas: [_template('t_career_change'), _template('t_learning')],
      goal: const PackGoal('Start working in my new field',
          obstacle: 'Learning alone for months instead of talking to people in the field',
          plan: 'When I finish a module, I message one person who does the job I want.',
          months: 12),
      daily: [
        _idea('Practise the skill I\'m building for 20 minutes'),
        _idea('Explain one new idea in my own words'),
        _idea('Ask someone a real question'),
      ],
      stops: const ['Waiting until I feel ready']),
  PlanPack('Athlete\'s season',
      forWho: 'Building to the key event of your season',
      summary: 'Quality practice, real recovery and honest talk about small injuries before they become big ones.',
      areas: [_template('t_strength'), _template('t_sleep')],
      goal: const PackGoal('Arrive at my key event fit, healthy and sharp',
          obstacle: 'Pushing through small pains until they become injuries',
          plan: 'When something hurts two sessions in a row, I tell my coach and adjust.',
          months: 6),
      daily: [
        _idea('Practise the skill I\'m building for 20 minutes'),
        _idea('Stretch for 10 minutes'),
        _idea('Protein with every meal'),
        _idea('Lights out at the same time'),
      ],
      stops: const ['Skipping the warm-up when short on time']),
];

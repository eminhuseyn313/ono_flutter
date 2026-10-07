// ============================================================
// EMIN HUSEYNZADE — PERSONAL OPERATING SYSTEM
// ============================================================
// Structured version of the "Personal Development Profile v1.0".
// Every screen in the Today / Plan / Playbook tabs reads from here.
// ============================================================

import 'package:flutter/material.dart';

import '../models/personal_system.dart';

// ------------------------------------------------------------
// Content records (static, read-only reference data)
// ------------------------------------------------------------

class ScheduleBlock {
  final int hour;
  final int minute;
  final String title;
  final String detail;
  final String lane;
  final IconData icon;

  const ScheduleBlock(this.hour, this.minute, this.title, this.detail,
      this.lane, this.icon);

  int get minuteOfDay => hour * 60 + minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class Exercise {
  final String name;
  final String sets;
  final String? note;
  final bool keyLift;

  /// Loads the shoulders: skipped on a shoulder-sparing day (RA flare).
  final bool shoulder;

  const Exercise(this.name, this.sets,
      {this.note, this.keyLift = false, this.shoulder = false});
}

class GymDay {
  final String id;
  final String letter;
  final String name;
  final int weekday; // DateTime.monday …
  final List<Exercise> exercises;
  final String finisher;

  const GymDay({
    required this.id,
    required this.letter,
    required this.name,
    required this.weekday,
    required this.exercises,
    required this.finisher,
  });
}

class DailyInput {
  final int weekday;
  final String title;
  final String detail;
  final String? url;

  const DailyInput(this.weekday, this.title, this.detail, {this.url});
}

class Book {
  final String slot; // "Month 1", "Now", "M2" …
  final int? month;
  final String title;
  final String author;
  final String chapters;
  final String why;
  final bool fiction;

  const Book({
    required this.slot,
    required this.month,
    required this.title,
    required this.author,
    required this.chapters,
    required this.why,
    this.fiction = false,
  });
}

class Film {
  final String title;
  final int year;
  final String when;
  final String why;

  const Film(this.title, this.year, this.when, this.why);
}

class Protocol {
  final String id;
  final String name;
  final String lane;
  final IconData icon;
  final String what;
  final String when;
  final String why;
  final String source;
  final String? before;
  final String? after;

  const Protocol({
    required this.id,
    required this.name,
    required this.lane,
    required this.icon,
    required this.what,
    required this.when,
    required this.why,
    required this.source,
    this.before,
    this.after,
  });
}

class WardrobeItem {
  final String id;
  final String week;
  final String item;
  final int minPrice;
  final int maxPrice;
  final String where;

  /// Program month the purchase is due in.
  final int month;

  const WardrobeItem(this.id, this.week, this.item, this.minPrice,
      this.maxPrice, this.where, this.month);
}

class Outfit {
  final String occasion;
  final String formula;
  final IconData icon;

  const Outfit(this.occasion, this.formula, this.icon);
}

class Certificate {
  final String id;
  final int priority;
  final String timing;
  final String name;
  final String org;
  final String url;

  const Certificate(
      this.id, this.priority, this.timing, this.name, this.org, this.url);
}

class CareerMilestone {
  final int month;
  final List<String> targets;

  const CareerMilestone(this.month, this.targets);

  String targetId(int index) => 'ms_${month}_$index';
}

class NonNegotiable {
  final String id;
  final String title;
  final String lane;

  /// 'morning' | 'day' | 'evening' — when it can be done.
  final String when;

  /// Guided tool that completes it (null = a plain tick).
  final String? route;

  const NonNegotiable(this.id, this.title, this.lane, this.when,
      {this.route});
}

class LaneFocus {
  final String lane;
  final String name;
  final String problem;
  final List<String> actions;

  const LaneFocus(this.lane, this.name, this.problem, this.actions);
}

class EvidencePrompt {
  final String section;
  final String title;
  final List<String> prompts;

  const EvidencePrompt(this.section, this.title, this.prompts);
}

// ------------------------------------------------------------
// Identity
// ------------------------------------------------------------

class EminIdentity {
  static const name = 'Emin Huseynzade';
  static const firstName = 'Emin';
  static const role = 'Senior Product Owner — Business ID';
  static const company = 'Bir Ecosystem (PASHA Financial Holding)';
  static const location = 'Baku, Azerbaijan';
  static const archetype = 'The Product Architect';
  static const tagline = 'Builds what others can\'t see yet';
  static const path = [
    'Senior PO',
    'Head of Product',
    'CPO / Tribe Lead',
    'Global Manager',
  ];
  static const identityStatement = 'Today I build something permanent.';
}

// ------------------------------------------------------------
// Manifesto
// ------------------------------------------------------------

const List<List<String>> manifestoStanzas = [
  [
    'I do not need to know everything to be competent.',
    'Competence is knowing how to find answers fast,',
    'make good decisions with incomplete information,',
    'and learn faster than the room.',
  ],
  [
    'I have built real things.',
    'I have solved real problems.',
    'I am not a fraud — I hold myself to a high standard.',
  ],
  [
    'I protect my sleep. I train my body.',
    'I dress with intention. I study my domain.',
    'I speak from position, not permission.',
  ],
  [
    'Today I build something permanent.',
    'Not performing. Building.',
  ],
];

String get manifestoText =>
    manifestoStanzas.map((s) => s.join('\n')).join('\n\n');

// ------------------------------------------------------------
// The 4 lanes
// ------------------------------------------------------------

const List<LaneFocus> laneFocus = [
  LaneFocus(
    'mind',
    'Mind',
    'Knowledge collapses under pressure. Impostor syndrome (Expert + Soloist). '
        'Overthinking. Anxiety before executive meetings.',
    [
      'Read manifesto — 2 min every morning while drinking water',
      'Physiological sigh ×3 before every pressure moment',
      'Say "I am excited" before every high-stakes interaction',
      'Evidence Archive — add items Sunday, read Monday',
      'Pennebaker writing — 15 min every Tuesday for 4 weeks',
    ],
  ),
  LaneFocus(
    'body',
    'Body',
    '83kg / 176cm, skinny-fat, building muscle for a year. Beta thalassemia '
        '(chronic low O₂). RA in shoulders. Snoring / nose breathing issues.',
    [
      'Gym 3× per week — Mon Push / Wed Pull / Thu Legs (RA-safe)',
      'Face pulls 3×15 every session',
      'Zone 2 cooldown 15 min after gym',
      'Protein 150g daily minimum',
      'Nasal strip every night',
      'In bed 10:30pm — 7.5 hours minimum',
      'Supplements: D3 + Creatine + Omega-3 (AM), Magnesium (PM)',
    ],
  ),
  LaneFocus(
    'skill',
    'Skill',
    'Domain knowledge feels inaccessible under pressure. No structured '
        'frameworks. Preparation disappears under stress.',
    [
      'BLUF on every work output — decision first',
      'Six-questions-deep before every meeting with Ali or seniors',
      '15 min domain scan every morning',
      'Read current book at lunch — 20 min',
      'Feynman write after reading — 5 min, from memory',
      'Anki review — 5 min daily, 5 new cards per week',
      'One artifact per month — PR/FAQ, OST, strategy doc',
    ],
  ),
  LaneFocus(
    'social',
    'Social',
    'No public presence. LinkedIn headline describes the old job. No posts '
        'published. Style is functional but has no signal.',
    [
      'Dress check: "Does this person belong in every room today?"',
      'Still body in every meeting — feet flat, hands still, no phone',
      'Deliberate pause before every answer — one breath',
      'Downward vocal inflection on statements',
      'LinkedIn: 2 posts per week from Month 2',
    ],
  ),
];

// ------------------------------------------------------------
// Daily schedule
// ------------------------------------------------------------

const List<ScheduleBlock> dailySchedule = [
  ScheduleBlock(6, 0, 'Wake', '500ml water immediately.', 'body',
      Icons.wb_twilight_rounded),
  ScheduleBlock(
      6,
      5,
      'Morning ritual',
      'Manifesto (2 min) · 3 priorities (3 min) · physiological sigh ×3 · '
          '"Today I build something permanent."',
      'mind',
      Icons.self_improvement_rounded),
  ScheduleBlock(6, 15, 'Get ready', 'With your wife. Dress intentionally. Mirror check.',
      'social', Icons.checkroom_rounded),
  ScheduleBlock(6, 45, 'Drive', 'Drop your wife, continue. Podcast of the day.',
      'skill', Icons.podcasts_rounded),
  ScheduleBlock(7, 45, 'Desk arrival',
      'Breakfast + supplements. Domain scan 10 min.', 'skill',
      Icons.coffee_rounded),
  ScheduleBlock(
      8,
      0,
      'Work',
      'BLUF all outputs. Sigh before pressure. "I am excited" before stakes. '
          'Still body. Deliberate pause.',
      'skill',
      Icons.work_outline_rounded),
  ScheduleBlock(12, 0, 'Lunch',
      'Eat 20 min. Read current book 20 min. Feynman write 5 min.', 'skill',
      Icons.menu_book_rounded),
  ScheduleBlock(13, 0, 'Afternoon work', 'No caffeine after 1pm.', 'skill',
      Icons.work_outline_rounded),
  ScheduleBlock(18, 0, 'Work ends', 'Drive home.', 'mind',
      Icons.directions_car_rounded),
  ScheduleBlock(19, 0, 'Train or deep work',
      'Gym Mon/Wed/Thu · Evening deep work Tue/Fri.', 'body',
      Icons.fitness_center_rounded),
  ScheduleBlock(20, 30, 'Dinner with your wife',
      'Cook together. Magnesium 400mg.', 'social', Icons.restaurant_rounded),
  ScheduleBlock(21, 0, 'Evening work',
      'Craft / domain / LinkedIn by day rotation.', 'skill',
      Icons.edit_note_rounded),
  ScheduleBlock(22, 0, 'Wind down',
      'No screens. Prepare tomorrow\'s outfit.', 'mind',
      Icons.nightlight_round),
  ScheduleBlock(22, 30, 'Sleep',
      'Nasal strip. Phone outside bedroom. Room 18–19°C.', 'body',
      Icons.bedtime_rounded),
];

/// The block that is active at [now] (the last block that has started).
ScheduleBlock currentBlock(DateTime now) {
  final m = now.hour * 60 + now.minute;
  ScheduleBlock active = dailySchedule.last;
  for (final b in dailySchedule) {
    if (b.minuteOfDay <= m) active = b;
  }
  return active;
}

ScheduleBlock nextBlock(DateTime now) {
  final m = now.hour * 60 + now.minute;
  for (final b in dailySchedule) {
    if (b.minuteOfDay > m) return b;
  }
  return dailySchedule.first;
}

// ------------------------------------------------------------
// Gym plan — RA-safe
// ------------------------------------------------------------

const List<GymDay> gymPlan = [
  GymDay(
    id: 'push',
    letter: 'A',
    name: 'Push',
    weekday: DateTime.monday,
    finisher: 'Zone 2 cooldown — 15 min',
    exercises: [
      Exercise('Chest Machine (full lying)', '3×12', shoulder: true),
      Exercise('Butterfly Machine', '3×12', shoulder: true),
      Exercise('Sitting Chest Machine', '3×12', shoulder: true),
      Exercise('Dumbbell Shoulder Press', '3×12',
          note: 'Dumbbells, not barbell', shoulder: true),
      Exercise('Lateral Raise Machine', '3×12', shoulder: true),
      Exercise('Tricep Pushdown (V-bar)', '3×12'),
      Exercise('Cable Rope Overhead Tricep', '3×12',
          note: 'Replaces DB overhead — safer for RA', shoulder: true),
      Exercise('Face Pulls', '3×15', note: 'Never skip', keyLift: true),
    ],
  ),
  GymDay(
    id: 'pull',
    letter: 'B',
    name: 'Pull',
    weekday: DateTime.wednesday,
    finisher: 'Zone 2 cooldown — 15 min',
    exercises: [
      Exercise('Lat Pulldown', '3×12', shoulder: true),
      Exercise('Incline T-bar Row', '3×12'),
      Exercise('Seated Cable Row', '3×12'),
      Exercise('Supinated Bicep Curl', '3×12'),
      Exercise('Cable Bicep Curl', '3×12'),
      Exercise('Hammer Curl', '3×12'),
      Exercise('One-Hand Tricep Pushdown', '3×12'),
      Exercise('Face Pulls + Reverse Cable Fly', '3×15 each', keyLift: true),
    ],
  ),
  GymDay(
    id: 'legs',
    letter: 'C',
    name: 'Legs + Core',
    weekday: DateTime.thursday,
    finisher: 'Zone 2 cooldown — 15 min',
    exercises: [
      Exercise('Goblet Squat', '3×12',
          note: 'DB at chest — zero shoulder load'),
      Exercise('Romanian Deadlift', '3×12'),
      Exercise('Walking Lunges', '3×12 each'),
      Exercise('Leg Press', '3×12'),
      Exercise('Plank', '3×45 sec'),
      Exercise('Dead Bug', '3×10 each'),
      Exercise('Leverage Shoulder Press', '3×12',
          note: 'Light, only if pain-free', shoulder: true),
      Exercise('Face Pulls', '3×15', keyLift: true),
    ],
  ),
];

/// The gym day (A/B/C) that falls on [date]. [days] maps A, B, C to
/// weekdays (default Mon / Wed / Thu, as in the profile).
GymDay? gymDayFor(DateTime date,
    [List<int> days = const [
      DateTime.monday,
      DateTime.wednesday,
      DateTime.thursday
    ]]) {
  for (var i = 0; i < gymPlan.length && i < days.length; i++) {
    if (days[i] == date.weekday) return gymPlan[i];
  }
  return null;
}

/// Added on a shoulder-sparing day: legs, trunk and conditioning carry the
/// session while the shoulders rest.
const List<Exercise> shoulderSparingAddOns = [
  Exercise('Leg Press', '3×12', note: 'Shoulder-sparing swap'),
  Exercise('Goblet Squat', '3×12', note: 'DB at chest — zero shoulder load'),
  Exercise('Dead Bug', '3×10 each', note: 'Shoulder-sparing swap'),
];

const raRemove = [
  'Overhead barbell press',
  'Upright rows',
  'Behind-neck press',
  'Barbell back squat',
];
const raReplace = [
  'DB shoulder press',
  'Cable rope tricep',
  'Goblet squat',
  'Leg press',
];

const supplementsMorning = [
  'Vitamin D3 2000 IU',
  'Creatine 5g',
  'Omega-3 2g',
];
const supplementsNight = ['Magnesium glycinate 400mg'];

const bloodwork = [
  'Ferritin',
  'Hemoglobin',
  'Vitamin D',
  'Testosterone',
  'TSH',
];

/// What the evening (19:00) slot holds, by weekday.
String eveningFocus(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Gym — Day A Push';
    case DateTime.tuesday:
      return 'Evening deep work · Pennebaker writing';
    case DateTime.wednesday:
      return 'Gym — Day B Pull';
    case DateTime.thursday:
      return 'Gym — Day C Legs + Core';
    case DateTime.friday:
      return 'Evening deep work';
    case DateTime.saturday:
      return 'Wardrobe buy · rest';
    default:
      return 'Evidence Archive · grooming · weekly report';
  }
}

// ------------------------------------------------------------
// Podcasts & domain scan
// ------------------------------------------------------------

const List<DailyInput> podcastRotation = [
  DailyInput(DateTime.monday, 'Lenny\'s Podcast',
      'Start: Shreyas Doshi — LNO Framework'),
  DailyInput(DateTime.tuesday, 'Acquired', 'Start: the Visa episode'),
  DailyInput(DateTime.wednesday, 'The Knowledge Project',
      'Start: Mental Models episode'),
  DailyInput(DateTime.thursday, 'Fintech Brainfood', 'Latest episode, always'),
  DailyInput(DateTime.friday, 'Fintech Leaders', 'Start: Kaspi.kz CEO episode'),
  DailyInput(DateTime.saturday, 'Identity at the Center',
      'Latest episode, always'),
  DailyInput(DateTime.sunday, 'Acquired — or silence', 'Any episode'),
];

const List<DailyInput> domainScanRotation = [
  DailyInput(DateTime.monday, 'CIAM Compass', 'Identity & agent identity',
      url: 'https://guptadeepak.com/ciam-compass'),
  DailyInput(DateTime.tuesday, 'Stratechery', 'Platform & ecosystem strategy',
      url: 'https://stratechery.com'),
  DailyInput(DateTime.wednesday, 'Lenny\'s Newsletter',
      'Product craft & leadership',
      url: 'https://www.lennysnewsletter.com'),
  DailyInput(DateTime.thursday, 'Product Compass', 'Modern PM frameworks',
      url: 'https://theproductcompass.substack.com'),
  DailyInput(DateTime.friday, 'Fintech Brainfood', 'Fintech & payments',
      url: 'https://www.fintechbrainfood.com'),
  DailyInput(DateTime.saturday, 'Primary sources',
      'Kaspi · Stripe · Visa · Auth0 blogs'),
  DailyInput(DateTime.sunday, 'Personal synthesis',
      'Write 3 domain insights in your journal'),
];

DailyInput podcastFor(DateTime d) =>
    podcastRotation.firstWhere((p) => p.weekday == d.weekday);

DailyInput domainScanFor(DateTime d) =>
    domainScanRotation.firstWhere((p) => p.weekday == d.weekday);

// ------------------------------------------------------------
// Library
// ------------------------------------------------------------

const List<Book> bookSchedule = [
  Book(
      slot: 'Month 1',
      month: 1,
      title: 'Continuous Discovery Habits',
      author: 'Teresa Torres',
      chapters: 'Ch. 1, 2, 3, 7, 9',
      why: 'You are mid-discovery on the entrepreneur integration now.'),
  Book(
      slot: 'Month 2',
      month: 2,
      title: 'Good Strategy Bad Strategy',
      author: 'Richard Rumelt',
      chapters: 'Ch. 1, 2, 5, 9',
      why: 'Write the real Business ID strategy.'),
  Book(
      slot: 'Month 3',
      month: 3,
      title: 'Working Backwards',
      author: 'Bryar & Carr',
      chapters: 'Ch. 4, 5, 6',
      why: 'PR/FAQ changes how Ali reads your thinking.'),
  Book(
      slot: 'Month 4',
      month: 4,
      title: 'Inspired',
      author: 'Marty Cagan',
      chapters: 'Ch. 1–5, 28, 37',
      why: 'Defines what a great PM actually is.'),
  Book(
      slot: 'Month 5',
      month: 5,
      title: '7 Powers',
      author: 'Hamilton Helmer',
      chapters: 'Ch. 1–3, 5, 8',
      why: 'Explains why Bir\'s ecosystem wins.'),
  Book(
      slot: 'Month 6',
      month: 6,
      title: 'Empowered',
      author: 'Cagan & Jones',
      chapters: 'Ch. 3, 5, 8, 10',
      why: 'The IC → product leader transition.'),
];

const List<Book> fictionSchedule = [
  Book(
      slot: 'Now',
      month: 1,
      title: 'Man\'s Search for Meaning',
      author: 'Viktor Frankl',
      chapters: 'Full book',
      why: 'Enjoyment has been absent — read this weekend.',
      fiction: true),
  Book(
      slot: 'Month 2',
      month: 2,
      title: 'Norwegian Wood',
      author: 'Haruki Murakami',
      chapters: 'Full',
      why: 'Restraint and precision in communication.',
      fiction: true),
  Book(
      slot: 'Month 3',
      month: 3,
      title: 'The Trial',
      author: 'Franz Kafka',
      chapters: 'Full',
      why: 'Capable people in systems that don\'t recognize them.',
      fiction: true),
  Book(
      slot: 'Month 4',
      month: 4,
      title: 'Crime and Punishment',
      author: 'Fyodor Dostoevsky',
      chapters: 'Full',
      why: 'The psychology of self-perception.',
      fiction: true),
  Book(
      slot: 'Month 5',
      month: 5,
      title: 'The Art of War',
      author: 'Sun Tzu',
      chapters: 'Full',
      why: 'Knowing yourself and your environment.',
      fiction: true),
];

Book currentBook(int programMonth) => bookSchedule.firstWhere(
    (b) => b.month == programMonth,
    orElse: () => bookSchedule.last);

Book currentNovel(int programMonth) => fictionSchedule.firstWhere(
    (b) => b.month == programMonth,
    orElse: () => fictionSchedule.last);

const List<Film> filmList = [
  Film('Whiplash', 2014, 'When you want to quit',
      'Why discomfort is necessary for excellence.'),
  Film('The Social Network', 2010, 'Wednesday evening',
      'BLUF communication. Building while underestimated.'),
  Film('Jiro Dreams of Sushi', 2011, 'When progress feels slow',
      'Mastery requires daily discipline over years.'),
  Film('Moneyball', 2011, 'Friday evening',
      'Evidence-based thinking against hierarchy — you at PASHA.'),
  Film('Parasite', 2019, 'Weekend',
      'Performance, ambition, and the gap between presentation and reality.'),
  Film('Steve Jobs', 2015, 'Month 2',
      'How a product leader communicates under pressure.'),
];

// ------------------------------------------------------------
// Protocols
// ------------------------------------------------------------

const List<Protocol> protocols = [
  Protocol(
    id: 'sigh',
    name: 'Physiological Sigh',
    lane: 'mind',
    icon: Icons.air_rounded,
    what:
        'Double inhale through the nose → long exhale through the mouth. 1–3 reps. 30 seconds.',
    when:
        'Before every meeting with Ali. Before any hard conversation. In the car before entering the office.',
    why:
        'Fastest known stress reset. Re-inflates lung alveoli, activates the vagus nerve. Stressed → calm in 60 seconds.',
    source: 'Huberman, Stanford',
  ),
  Protocol(
    id: 'excited',
    name: '"I Am Excited"',
    lane: 'mind',
    icon: Icons.bolt_rounded,
    what: 'Say internally "I am excited" before any high-stakes moment.',
    when:
        'Before presenting. Before difficult conversations. Before entering any important room.',
    why:
        'Anxiety and excitement are physiologically identical. "Calm down" requires changing your state; "I am excited" only reinterprets it. Reappraisal beats suppression.',
    source: 'Brooks, Harvard 2014',
  ),
  Protocol(
    id: 'bluf',
    name: 'BLUF',
    lane: 'skill',
    icon: Icons.vertical_align_top_rounded,
    what:
        'Decision first → 3 supporting reasons → what you need → deadline.',
    when:
        'Every email, every Slack message, every meeting update to Ali or Rustam.',
    why:
        'Executives process top-down. They decide from your first sentence whether the rest is worth reading.',
    source: 'Military writing standard · Amazon narratives',
    before:
        'So after reviewing everything we probably should consider maybe delaying…',
    after:
        'I recommend delaying SA automation to Sprint 5. Affects 12% of users, complexity higher than estimated, DVX is the priority blocker. Need your alignment by Thursday.',
  ),
  Protocol(
    id: 'six_deep',
    name: 'Six Questions Deep',
    lane: 'skill',
    icon: Icons.layers_rounded,
    what:
        'Write the 6 hardest questions Ali could ask. Write your answers. Then write the hardest follow-up to each answer.',
    when: 'Before any meeting with Ali or senior stakeholders.',
    why:
        'Preparation depth is what gravitas actually is. Six deep, nothing in the room surprises you.',
    source: 'Hewlett, CTI',
  ),
  Protocol(
    id: 'feynman',
    name: 'Feynman Technique',
    lane: 'skill',
    icon: Icons.edit_rounded,
    what:
        'After reading, close everything. Write what you just read from memory. 5 minutes.',
    when: 'Right after the 20-minute lunch read.',
    why:
        'Retrieval practice gives ~50% better retention than re-reading. Where you blank = the gap.',
    source: 'Roediger & Karpicke, 2006',
  ),
  Protocol(
    id: 'evidence',
    name: 'Evidence Archive',
    lane: 'mind',
    icon: Icons.inventory_2_rounded,
    what:
        'A running record in 3 sections: Things I built · Problems I solved · Knowledge I have that others don\'t.',
    when: 'Add at least 5 items every Sunday. Read every Monday before the first meeting.',
    why:
        'The Expert + Soloist impostor forgets what they have built. Real evidence interrupts the spiral.',
    source: 'Valerie Young — impostor types',
  ),
  Protocol(
    id: 'pause',
    name: 'Deliberate Pause',
    lane: 'social',
    icon: Icons.pause_circle_outline_rounded,
    what: 'One slow breath before answering any challenging question.',
    when: 'Every meeting, every hard question.',
    why:
        'Immediate answers read as reactive. Paused answers read as deliberate. A 1–2 second pause is a gravitas signal.',
    source: 'Executive presence research',
  ),
  Protocol(
    id: 'still',
    name: 'Still Body',
    lane: 'social',
    icon: Icons.accessibility_new_rounded,
    what:
        'Feet flat on the floor. Hands still on table or lap. Phone face-down or invisible. Eyes on the speaker.',
    when: 'Every meeting.',
    why:
        'Physical stillness is the strongest unconscious signal of authority. Fidgeting signals anxiety.',
    source: 'Nonverbal dominance research',
  ),
  Protocol(
    id: 'pennebaker',
    name: 'Pennebaker Writing',
    lane: 'mind',
    icon: Icons.history_edu_rounded,
    what:
        'Write about your deepest fears and anxieties for 15 minutes without stopping.',
    when: 'Every Tuesday evening, for 4 consecutive weeks.',
    why:
        'Translating emotion into language engages the prefrontal cortex and measurably lowers anxiety.',
    source: 'Pennebaker, UT Austin',
  ),
];

// ------------------------------------------------------------
// Style system
// ------------------------------------------------------------

const faceNotes = [
  ['Shaved head', 'Grade 1 all over, every 2 weeks. Own it completely.'],
  ['Strong nose', 'Do nothing. It photographs with authority. The beard balances it.'],
  ['Soft jaw / chin', 'The beard fixes this — fuller at the chin, sharp neck line.'],
  ['Short neck', 'Posture work at the gym + V-neck / crewneck collars + a precise beard neck line.'],
];

const beardSpec = [
  ['Chin', 'Fuller — the longest point. Adds jaw definition.'],
  ['Cheeks', 'Clean defined line. Not too high, not too low.'],
  ['Neck line', 'Two fingers above the Adam\'s apple. Shave everything below.'],
  ['Sides', '5–8mm, fading down.'],
  ['Maintain', 'Every Sunday evening, 10 minutes.'],
];

const List<WardrobeItem> wardrobe = [
  WardrobeItem('w1', 'Sat 1', 'Navy fine merino crewneck', 40, 50, 'Uniqlo online', 1),
  WardrobeItem('w2', 'Sat 2', 'Charcoal merino + dark chinos (tailored)', 60, 70,
      'Uniqlo + local tailor', 1),
  WardrobeItem('w3', 'Sat 3', 'White Oxford shirt', 30, 50, 'Local or Massimo Dutti', 1),
  WardrobeItem('w4', 'Sat 4', 'White minimal leather sneakers', 40, 70,
      'Adidas Stan Smith', 1),
  WardrobeItem('w5', 'Sat 5–6', 'Navy unstructured blazer', 150, 200,
      'Best Baku tailor', 2),
  WardrobeItem('w6', 'Sat 7', 'Dark brown suede loafers', 60, 100,
      'Best local shoe shop', 2),
  WardrobeItem('w7', 'Sat 8', 'Skincare: Cetaphil + SPF50 + beard oil', 35, 35,
      'Baku pharmacy', 2),
  WardrobeItem('w8', 'Month 3', 'Dark overcoat', 150, 250, 'Tailor or store', 3),
  WardrobeItem('w9', 'Month 3', 'Quality leather backpack', 80, 150, 'Leather shop', 3),
  WardrobeItem('w10', 'Month 3', 'Charcoal suit (tailored)', 300, 400, 'Tailor', 3),
];

const List<Outfit> outfits = [
  Outfit('PASHA meeting', 'Light blue shirt · black trousers · navy blazer · brown loafers · Skagen',
      Icons.business_center_rounded),
  Outfit('Daily office', 'Navy merino · dark chinos · white sneakers · Skagen',
      Icons.apartment_rounded),
  Outfit('Smart casual', 'Charcoal merino · dark chinos · white sneakers',
      Icons.local_cafe_rounded),
  Outfit('Dinner out', 'White shirt (open collar) · dark chinos · loafers · Skagen',
      Icons.wine_bar_rounded),
  Outfit('Weekend', 'Navy merino or plain tee · dark chinos · white sneakers · Casio',
      Icons.weekend_rounded),
  Outfit('Gym', 'Dark fitted training tee · dark shorts/joggers · Apple Watch',
      Icons.fitness_center_rounded),
];

Outfit outfitFor(DateTime d) {
  if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
    return outfits[4];
  }
  return outfits[1];
}

const watchRule = [
  ['Work', 'Skagen — every day, no exceptions'],
  ['Gym', 'Apple Watch'],
  ['Weekend', 'Casio'],
];

const groomingRoutine = [
  ['Every morning · 5 min', 'Cetaphil cleanser → SPF50 moisturizer → beard oil, 3 drops'],
  ['Every Sunday · 15 min', 'Beard edge-up → skincare → lay out Monday\'s outfit'],
  ['Every 2 weeks', 'Grade 1 buzz cut'],
];

const skincarePlan = [
  ['Month 1–2', 'Cetaphil cleanser + Neutrogena SPF50'],
  ['Month 3', 'Add niacinamide serum (The Ordinary)'],
  ['Month 4+', 'Add retinol 2–3 nights per week (night only)'],
];

// ------------------------------------------------------------
// Career: LinkedIn, thesis, data, certificates, milestones
// ------------------------------------------------------------

const linkedinHeadline =
    'Building merchant identity for 5M+ users @ Bir Ecosystem (PASHA) | Payments · Identity · AI Agents';

const linkedinAbout = '''I build the identity layer for ecosystems.

Currently at Bir Ecosystem (PASHA Financial Holding), I'm leading Business ID — a unified merchant identity and SSO platform connecting 5M+ users across Azerbaijan's first fully integrated digital ecosystem: banking, marketplace, payments, and loyalty.

Before this: B2B remittance infrastructure at Guavapay, open banking and BaaS at PASHA Bank, high-traffic transaction systems at Misli. The thread across all of it: complex technical systems where identity, payments, and product strategy intersect.

What I'm focused on now: how merchant identity becomes the connective tissue of super-app ecosystems — and how agentic payments change the trust and permission model for everything.

📍 Baku, Azerbaijan | 🎓 Ca' Foscari University, Venice (110/110 cum laude)
🌐 AZ | RU | TR | EN''';

const linkedinRole = '''Leading product strategy for Business ID — a unified merchant identity and SSO layer across Bir Ecosystem's B2B services: BirBank Business, BirMarket, BirBonus, and BirPay.

→ Serving an ecosystem of 5M+ users across Azerbaijan's first fully integrated digital platform
→ Directing discovery and delivery for merchant onboarding, SSO integration, and identity verification (ASAN İmza, DVX)
→ Working across engineering, compliance, and executive stakeholders to define the identity architecture for agentic commerce use cases''';

const linkedinFirstPost = '''I spent 4 years in payments and iGaming before I understood what identity actually is.

It's not authentication. It's not a login screen.

Identity is the trust layer that decides what a merchant can access, what they can borrow, what they can sell.

At Kaspi: 764,000 merchants. 95% accept Kaspi QR. The reason they can offer those merchants working capital loans isn't just data — it's verified identity tied to transaction history.

That's what we're building with Business ID at Bir.

What's the most underrated layer in your product stack?''';

const domainThesis =
    'The next interface of a super-app is an agent. Ecosystems that turn existing '
    'identity and payment trust into agent permissions will win. '
    'Business ID is Bir\'s answer to this.';

const keyData = [
  ['Kaspi', '764,000 active merchants · 95% accept Kaspi QR · \$97.3B payment volume FY2025'],
  ['Grab', 'Multi-service adoption 12% → 54% · retention 47% → 79% after identity integration'],
  ['NHI', 'Non-human identities outnumber humans 45:1 (CSA, May 2026)'],
  ['Agentic payments', 'Mastercard Agent Pay (Apr 2025) · Visa Intelligent Commerce (Apr 2025) · Stripe SPT (Mar 2026) · Auth0 MCP (May 2026)'],
  ['Bir', '5M+ users · first fully integrated ecosystem in the Caucasus'],
];

const List<Certificate> certificates = [
  Certificate('svpg', 1, 'Month 3–4', 'SVPG Coaching Program',
      'Silicon Valley Product Group', 'https://www.svpg.com'),
  Certificate('aws', 2, 'Month 4–5', 'AWS Cloud Practitioner', 'Amazon',
      'https://aws.amazon.com/training'),
  Certificate('ciam', 3, 'Month 6+', 'CIAM Professional', 'KuppingerCole',
      'https://www.kuppingercole.com'),
  Certificate('pspo', 4, 'Month 9+', 'PSPO', 'Scrum.org', 'https://www.scrum.org'),
];

const List<CareerMilestone> careerMilestones = [
  CareerMilestone(1, [
    'Sleep consistent',
    'Grooming routine',
    'LinkedIn headline changed',
    'Domain scans started',
  ]),
  CareerMilestone(2, [
    'Bloodwork done',
    'Zone 2 base building',
    'BLUF automatic',
    'First 5 LinkedIn posts',
  ]),
  CareerMilestone(3, [
    'Agentic payments thesis owned',
    'PR/FAQ written',
    'Professional headshot taken',
  ]),
  CareerMilestone(4, [
    'Advisory board — first contacts',
    'Style capsule Month 1–2 complete',
    '15 posts published',
  ]),
  CareerMilestone(6, [
    'Full style capsule',
    '2,000+ LinkedIn followers',
    'Signature thesis draft written',
  ]),
  CareerMilestone(9, [
    'Advisory board — 3 seats filled',
    'Internal talk delivered',
    '5,000+ followers',
  ]),
  CareerMilestone(12, [
    'Conference CFP submitted',
    '8,000+ followers',
    'Coaching one junior PM',
  ]),
  CareerMilestone(18, [
    'Career decision made from strength — promotion, international move, or founding path',
  ]),
];

// ------------------------------------------------------------
// Daily 10 non-negotiables
// ------------------------------------------------------------

const List<NonNegotiable> nonNegotiables = [
  NonNegotiable('manifesto', 'Read manifesto this morning', 'mind', 'morning',
      route: '/manifesto'),
  NonNegotiable('scan', 'Domain scan — 15 min', 'skill', 'morning',
      route: '/tool/scan'),
  NonNegotiable('sigh', 'Physiological sigh before pressure', 'mind', 'day',
      route: '/tool/sigh'),
  NonNegotiable('bluf', 'BLUF on at least one output', 'skill', 'day',
      route: '/tool/bluf'),
  NonNegotiable('pause', 'Deliberate pause practiced', 'social', 'day'),
  NonNegotiable('read', 'Read at lunch — 20 min', 'skill', 'day',
      route: '/tool/read'),
  NonNegotiable('feynman', 'Wrote from memory after reading', 'skill', 'day',
      route: '/tool/feynman'),
  NonNegotiable('caffeine', 'No caffeine after 1pm', 'body', 'day'),
  NonNegotiable('protein', 'Protein — 150g', 'body', 'evening',
      route: '/log?add=protein'),
  NonNegotiable('bed', 'In bed by 10:30pm', 'body', 'evening'),
];

/// Default if-then plans (implementation intentions): the cue that
/// triggers each Daily 10 item. Editable on /plans.
const Map<String, String> defaultCues = {
  'manifesto': 'When I switch off the 06:00 alarm → manifesto before the phone',
  'scan': 'When I sit at my desk at 07:45 → scan before opening email',
  'sigh': 'When I park at the office or a hard meeting starts → sigh ×3',
  'bluf': 'When I open Slack the first time → write that message as BLUF',
  'pause': 'When someone challenges me → one breath before I answer',
  'read': 'When lunch arrives → phone face-down, book open',
  'feynman': 'When I close the book → 5 minutes writing from memory',
  'caffeine': 'When it turns 13:00 → water or herbal tea only',
  'protein': 'When I sit down to breakfast → 40 g protein first',
  'bed': 'When the 22:00 alarm rings → phone goes outside the bedroom',
};

const nonNegotiableGroups = [
  ['morning', 'Morning'],
  ['day', 'At work'],
  ['evening', 'Evening'],
];

// ------------------------------------------------------------
// Weekly coaching
// ------------------------------------------------------------

const weeklyCoachingFields = [
  'Non-negotiables — average per day (X/10)',
  'Gym sessions completed (X/3)',
  'Best moment of the week',
  'Hardest moment',
  'One real work situation to coach through',
];

// ------------------------------------------------------------
// Evidence Archive
// ------------------------------------------------------------

const evidenceSections = [
  EvidencePrompt('built', 'Things I built', [
    'Products / features shipped at Bir, Guavapay, PASHA Bank, Misli',
    'Built outside work: Paya, Ono, Zimba, Duyit, Nimat, Okhu, Oruta',
    'Integrations or technical implementations you led',
  ]),
  EvidencePrompt('solved', 'Problems I solved', [
    'When were you the one who unblocked something?',
    'When did your technical background solve what others couldn\'t?',
    'When did your 4 languages give you an advantage no one else had?',
  ]),
  EvidencePrompt('knowledge', 'Knowledge others don\'t have', [
    'Domain depth nobody else in the room has',
    'Rare skills for a PO',
  ]),
];

/// Starter items for "Knowledge I have that most don't" — from the profile.
const evidenceSeeds = [
  'ASAN İmza integration complexity in Azerbaijan\'s regulatory context',
  'DVX verification flows for merchant onboarding at Bir',
  'Data engineering: Airflow, Delta Lake, medallion architecture (rare for POs)',
  'iGaming regulatory environments from direct product work',
  '4 languages: AZ / RU / TR / EN — direct access to CIS, Caucasus and Turkish fintech',
  'Building identity infrastructure for the first super-app ecosystem in the Caucasus',
  '110/110 cum laude Masters — Ca\' Foscari, Venice',
];

// ------------------------------------------------------------
// The 18-month journey
// ------------------------------------------------------------

const programMonths = 18;
const programDays = programMonths * 30;

class Phase {
  final String id;
  final String name;
  final int fromMonth;
  final int toMonth;
  final String promise;

  const Phase(this.id, this.name, this.fromMonth, this.toMonth, this.promise);

  bool contains(int month) => month >= fromMonth && month <= toMonth;
}

const List<Phase> phases = [
  Phase('foundation', 'Foundation', 1, 2,
      'Fix the biological base. Install the system. Stop the energy leak.'),
  Phase('craft', 'Craft', 3, 6,
      'Domain depth, real artifacts, a wardrobe and a voice that match the role.'),
  Phase('signal', 'Signal', 7, 12,
      'The world starts to see it: thesis, talks, advisory board, following.'),
  Phase('leverage', 'Leverage', 13, 18,
      'Options and conversations. Decide the next role from strength.'),
];

Phase phaseFor(int month) =>
    phases.firstWhere((p) => p.contains(month), orElse: () => phases.last);

/// Role steps along the path, with the month each becomes realistic.
const pathSteps = [
  ['Senior PO', '1'],
  ['Head of Product', '9'],
  ['CPO / Tribe Lead', '15'],
  ['Global Manager', '18'],
];

const Map<int, String> monthThemes = {
  1: 'Sleep consistent, ritual installed, protocols in use.',
  2: 'Bloodwork done. Zone 2 base. BLUF automatic. LinkedIn starts.',
  3: 'Own the agentic-payments thesis. PR/FAQ written. Headshot taken.',
  4: 'Advisory board first contacts. 15 posts published.',
  5: 'Cloud fluency (AWS). Read Bir through 7 Powers.',
  6: 'Full style capsule. 2,000+ followers. Signature thesis drafted.',
  7: 'Thesis becomes a talk outline. Build in public.',
  8: 'Deepen the advisory board. Ship the second big artifact.',
  9: 'Advisory board 3 seats. Internal talk delivered. 5,000+ followers.',
  10: 'PSPO certification. Conference talk material.',
  11: 'Coach-ready: write your product principles.',
  12: 'Conference CFP submitted. 8,000+ followers. Coach a junior PM.',
  13: 'Map the options: promotion, international, founding.',
  14: 'Conversations with people one role ahead.',
  15: 'Make the case: a written narrative for the next role.',
  16: 'Test the options in the market.',
  17: 'Negotiate from evidence.',
  18: 'Career decision made from strength.',
};

/// Suggested artifact for each month ("one artifact per month").
const Map<int, String> monthArtifacts = {
  1: 'Opportunity Solution Tree — entrepreneur integration',
  2: 'Business ID strategy: diagnosis, guiding policy, coherent actions',
  3: 'PR/FAQ for Business ID',
  4: 'Product operating model — how Business ID decides',
  5: '7 Powers analysis of Bir Ecosystem',
  6: 'Signature thesis draft — agents & merchant identity',
};

String artifactFor(int month) =>
    monthArtifacts[month] ?? 'One artifact: PR/FAQ, OST, strategy doc or 6-pager';

/// A thing that becomes relevant in a given month.
class Unlock {
  final String kind; // book | novel | film | wardrobe | skincare | linkedin | artifact | certificate | milestone | protocol
  final String title;
  final String detail;
  final String? route;
  final String? doneKey;

  const Unlock(this.kind, this.title, this.detail, {this.route, this.doneKey});
}

List<Unlock> unlocksFor(int month) {
  final list = <Unlock>[];
  for (final b in bookSchedule.where((b) => b.month == month)) {
    list.add(Unlock('book', b.title, '${b.author} · ${b.chapters}',
        route: '/library', doneKey: 'book:${b.title}'));
  }
  for (final b in fictionSchedule.where((b) => b.month == month)) {
    list.add(Unlock('novel', b.title, b.why,
        route: '/library', doneKey: 'book:${b.title}'));
  }
  if (month == 2) {
    list.add(const Unlock('film', 'Steve Jobs (2015)',
        'How a product leader communicates under pressure',
        route: '/library', doneKey: 'film:Steve Jobs'));
  }
  for (final w in wardrobe.where((w) => w.month == month)) {
    list.add(Unlock('wardrobe', w.item, '${w.week} · ${w.where}',
        route: '/style', doneKey: 'wardrobe:${w.id}'));
  }
  if (month == 1) {
    list.add(const Unlock('protocol', 'Pennebaker writing',
        '15 min every Tuesday for 4 weeks',
        route: '/tool/pennebaker'));
    list.add(const Unlock('linkedin', 'New LinkedIn headline + About',
        'Exact rewrites are ready to copy',
        route: '/career', doneKey: 'li:headline'));
  }
  if (month == 2) {
    list.add(const Unlock('linkedin', 'LinkedIn: 2 posts per week',
        'Cadence starts this month', route: '/career'));
  }
  if (month == 3) {
    list.add(const Unlock('skincare', 'Add niacinamide serum',
        'The Ordinary — morning, after cleanser', route: '/style'));
  }
  if (month == 4) {
    list.add(const Unlock('skincare', 'Add retinol 2–3 nights a week',
        'Night only', route: '/style'));
  }
  for (final c in certificates.where((c) => _certStart(c) == month)) {
    list.add(Unlock('certificate', c.name, '${c.org} · ${c.timing}',
        route: '/career', doneKey: 'cert:${c.id}'));
  }
  list.add(Unlock('artifact', 'Artifact of the month', artifactFor(month),
      route: '/tool/artifact'));
  return list;
}

int _certStart(Certificate c) =>
    int.tryParse(RegExp(r'\d+').firstMatch(c.timing)?.group(0) ?? '') ?? 99;

// ------------------------------------------------------------
// Reminders (local notifications)
// ------------------------------------------------------------

class ReminderDef {
  final String id;
  final String label;
  final int hour;
  final int minute;

  /// null = every day; otherwise the weekdays it fires on.
  final List<int>? weekdays;
  final String route;
  final bool defaultOn;

  const ReminderDef(this.id, this.label, this.hour, this.minute,
      {this.weekdays, required this.route, this.defaultOn = true});

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const _weekdays = [
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
];

/// Gym reminder weekdays come from the user's gym days at runtime.
const List<ReminderDef> reminderDefs = [
  ReminderDef('wake', 'Wake — 500ml water', 6, 0, route: '/home'),
  ReminderDef('ritual', 'Morning ritual', 6, 5,
      route: '/ritual-flow/ritual_morning_default'),
  ReminderDef('scan', 'Supplements + domain scan', 7, 45, route: '/tool/scan'),
  ReminderDef('evidence_read', 'Read your evidence before the first meeting',
      7, 55,
      weekdays: [DateTime.monday], route: '/evidence'),
  ReminderDef('read', 'Lunch read + Feynman', 12, 0,
      weekdays: _weekdays, route: '/tool/read'),
  ReminderDef('caffeine', 'Last coffee — nothing after 13:00', 12, 55,
      weekdays: _weekdays, route: '/home', defaultOn: false),
  ReminderDef('gym', 'Gym in 15 minutes', 18, 45, route: '/gym'),
  ReminderDef('pennebaker', 'Pennebaker writing — 15 min', 21, 0,
      weekdays: [DateTime.tuesday], route: '/tool/pennebaker'),
  ReminderDef('winddown', 'Wind down — screens off, lay out the outfit', 22, 0,
      route: '/home'),
  ReminderDef('bed', 'Nasal strip. Lights out 22:30', 22, 25, route: '/home'),
  ReminderDef('evidence_add', 'Add 5 items to the Evidence Archive', 18, 0,
      weekdays: [DateTime.sunday], route: '/evidence'),
  ReminderDef('report', 'Sunday report → next week\'s brief', 19, 0,
      weekdays: [DateTime.sunday], route: '/weekly-coaching'),
  ReminderDef('grooming', 'Beard edge-up, skincare, Monday outfit', 20, 30,
      weekdays: [DateTime.sunday], route: '/style'),
];

// ------------------------------------------------------------
// Protocol mastery
// ------------------------------------------------------------

/// [minimum uses, level name]
const masteryLevels = [
  [0, 'Not started'],
  [1, 'Aware'],
  [5, 'Practised'],
  [20, 'Habitual'],
  [60, 'Automatic'],
];

String masteryFor(int uses) {
  var name = masteryLevels.first[1] as String;
  for (final l in masteryLevels) {
    if (uses >= (l[0] as int)) name = l[1] as String;
  }
  return name;
}

/// Uses needed to reach the next level, or null at the top.
int? nextMasteryAt(int uses) {
  for (final l in masteryLevels) {
    if ((l[0] as int) > uses) return l[0] as int;
  }
  return null;
}

/// Protocol id → guided tool route.
const protocolTools = {
  'sigh': '/tool/sigh',
  'excited': '/tool/excited',
  'bluf': '/tool/bluf',
  'six_deep': '/tool/sixq',
  'feynman': '/tool/feynman',
  'evidence': '/evidence',
  'pause': '/tool/pause',
  'still': '/tool/still',
  'pennebaker': '/tool/pennebaker',
};

/// Protocol id → log type counted for mastery.
const protocolLogTypes = {
  'sigh': 'sigh',
  'excited': 'excited',
  'bluf': 'bluf',
  'six_deep': 'sixq',
  'feynman': 'feynman',
  'evidence': 'evidence',
  'pause': 'pause',
  'still': 'still',
  'pennebaker': 'pennebaker',
};

// ------------------------------------------------------------
// Study deck (spaced repetition) — seed cards from the profile
// ------------------------------------------------------------

List<StudyCard> get seedCards => [
      for (var i = 0; i < keyData.length; i++)
        StudyCard('seed:key:$i', '${keyData[i][0]} — the numbers you quote?',
            keyData[i][1]),
      const StudyCard('seed:thesis', 'Your domain thesis, in one breath?',
          domainThesis),
      for (final p in protocols)
        StudyCard('seed:protocol:${p.id}', '${p.name}: what, and when?',
            '${p.what}\n\nWhen: ${p.when}'),
      StudyCard('seed:ra', 'The four lifts you never do (RA)?',
          raRemove.join(' · ')),
    ];

/// New cards introduced per day; the rest wait.
const newCardsPerDay = 5;

// ------------------------------------------------------------
// Career cockpit
// ------------------------------------------------------------

class ReadinessDimension {
  final String id;
  final String name;

  /// What the Head of Product bar looks like on this dimension.
  final String bar;

  const ReadinessDimension(this.id, this.name, this.bar);
}

/// Head of Product readiness, rated monthly 1–5 against the bar (4 = ready).
const List<ReadinessDimension> readinessDimensions = [
  ReadinessDimension('product_sense', 'Product sense',
      'Picks the right problems for Business ID; a clear point of view on where identity and agentic commerce go.'),
  ReadinessDimension('execution', 'Execution',
      'Ships predictably across teams; unblocks others; decisions backed by data.'),
  ReadinessDimension('leadership', 'Leadership',
      'Leads without authority; grows people; trusted by Ali and Rustam to own an area.'),
  ReadinessDimension('strategy', 'Strategy & business',
      'Links product bets to revenue and ecosystem economics; speaks the P&L.'),
  ReadinessDimension('communication', 'Executive communication',
      'BLUF by default; calm in the room; writes PR/FAQs that change minds.'),
];

const readinessBar = 4;

// ------------------------------------------------------------
// Automaticity — monthly "is it a habit yet?"
// ------------------------------------------------------------

/// Reminder that exists only to prompt a Daily 10 item; switched off once
/// the item is automatic.
const Map<String, String> itemReminder = {
  'scan': 'scan',
  'read': 'read',
  'caffeine': 'caffeine',
  'bed': 'bed',
};

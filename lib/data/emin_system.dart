// ============================================================
// EMIN HUSEYNZADE — PERSONAL OPERATING SYSTEM
// ============================================================
// Structured version of the "Personal Development Profile v1.0".
// Every screen in the Today / Plan / Playbook tabs reads from here.
// ============================================================

import 'package:flutter/material.dart';

import 'plan_content.dart';
import 'profile.dart';

import '../models/personal_system.dart';

export 'plan_content.dart' show plan, planOverride, fallbackPlan, PlanContent;
export 'profile.dart';

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


// ------------------------------------------------------------
// Manifesto
// ------------------------------------------------------------

List<List<String>> get manifestoStanzas => plan.manifesto;

String get manifestoText =>
    manifestoStanzas.map((s) => s.join('\n')).join('\n\n');

// ------------------------------------------------------------
// The 4 lanes
// ------------------------------------------------------------

List<LaneFocus> get laneFocus => plan.laneFocus;

// ------------------------------------------------------------
// Daily schedule
// ------------------------------------------------------------

List<ScheduleBlock> get dailySchedule => plan.schedule;

/// The block that is active at [now] (the last block that has started).
ScheduleBlock currentBlock(DateTime now) {
  final m = now.hour * 60 + now.minute;
  if (dailySchedule.isEmpty) return _openDay;
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
  return dailySchedule.isEmpty ? _openDay : dailySchedule.first;
}

const _openDay = ScheduleBlock(0, 0, 'Your day', '', 'mind', Icons.wb_twilight_rounded);

// ------------------------------------------------------------
// Training plan
// ------------------------------------------------------------

List<GymDay> get gymPlan => plan.gym;

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
List<Exercise> get shoulderSparingAddOns => plan.shoulderSparing;

List<String> get raRemove => plan.avoidLifts;
List<String> get raReplace => plan.liftSwaps;

List<String> get supplementsMorning => plan.supplementsMorning;
List<String> get supplementsNight => plan.supplementsNight;

List<String> get bloodwork => plan.bloodwork;

/// What the evening (19:00) slot holds, by weekday.
String eveningFocus(int weekday) => plan.eveningFocus[weekday] ?? '';

// ------------------------------------------------------------
// Podcasts & domain scan
// ------------------------------------------------------------

List<DailyInput> get podcastRotation => plan.podcasts;

List<DailyInput> get domainScanRotation => plan.domainScans;

const _noInput = DailyInput(0, '', '');

DailyInput podcastFor(DateTime d) =>
    podcastRotation.where((p) => p.weekday == d.weekday).firstOrNull ?? _noInput;

DailyInput domainScanFor(DateTime d) =>
    domainScanRotation.where((p) => p.weekday == d.weekday).firstOrNull ?? _noInput;

// ------------------------------------------------------------
// Library
// ------------------------------------------------------------

List<Book> get bookSchedule => plan.books;

List<Book> get fictionSchedule => plan.novels;

/// The planned book for [programMonth], or null once the plan's books
/// are read (the provider's `planBook` then follows the learning list).
Book? scheduledBook(int programMonth) =>
    bookSchedule.where((b) => b.month == programMonth).firstOrNull;

Book currentBook(int programMonth) =>
    bookSchedule.where((b) => b.month == programMonth).firstOrNull ??
    bookSchedule.lastOrNull ??
    _noBook;

Book currentNovel(int programMonth) =>
    fictionSchedule.where((b) => b.month == programMonth).firstOrNull ??
    fictionSchedule.lastOrNull ??
    _noBook;

const _noBook = Book(slot: '', month: null, title: '', author: '', chapters: '', why: '');

List<Film> get filmList => plan.films;

// ------------------------------------------------------------
// Protocols
// ------------------------------------------------------------

List<Protocol> get protocols => plan.protocols;

// ------------------------------------------------------------
// Style system
// ------------------------------------------------------------

List<List<String>> get faceNotes => plan.faceNotes;

List<List<String>> get beardSpec => plan.beardSpec;

List<WardrobeItem> get wardrobe => plan.wardrobe;

List<Outfit> get outfits => plan.outfits;

const _noOutfit = Outfit('', '', Icons.checkroom_rounded);

Outfit outfitFor(DateTime d) {
  final weekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
  final i = weekend ? plan.weekendOutfit : plan.weekdayOutfit;
  return i >= 0 && i < outfits.length ? outfits[i] : _noOutfit;
}

List<List<String>> get watchRule => plan.watchRule;

List<List<String>> get groomingRoutine => plan.groomingRoutine;

List<List<String>> get skincarePlan => plan.skincarePlan;

// ------------------------------------------------------------
// Career: LinkedIn, thesis, data, certificates, milestones
// ------------------------------------------------------------

String get linkedinHeadline => plan.linkedinHeadline;

String get linkedinAbout => plan.linkedinAbout;

String get linkedinRole => plan.linkedinRole;

String get linkedinFirstPost => plan.linkedinFirstPost;

String get domainThesis => plan.domainThesis;

List<List<String>> get keyData => plan.keyData;

List<Certificate> get certificates => plan.certificates;

List<CareerMilestone> get careerMilestones => plan.careerMilestones;

// ------------------------------------------------------------
// Daily 10 non-negotiables
// ------------------------------------------------------------

/// The profile ONO is configured for. Features read this, never his
/// name or job directly. It is his built-in profile unless he edited it
/// (Me → Profile); onboarding will set it for other people.
Profile get activeProfile => profileOverride ?? builtInProfile;

/// His profile as shipped.
/// The loaded plan's profile (a blank one when no plan is loaded).
Profile get builtInProfile => plan.profile ?? blankProfile;

/// No one yet: the plan builder fills it in.
const blankProfile = Profile(
    name: '',
    firstName: '',
    currentRole: '',
    targetRole: '',
    organisation: '',
    focus: '',
    domain: '',
    identityStatement: '',
    path: [],
    keyPeople: []);

/// People whose meetings get the full six-questions-deep prep.
List<String> get keyPeople => [for (final p in activeProfile.keyPeople) p.name];

List<NonNegotiable> get nonNegotiables => plan.dailyItems;

/// Items that belong to the working day: they rest on days off (Emin's
/// choice, 25 Oct 2026), from [workDayOnlyFrom] so earlier days keep the
/// list they were scored on. Changed per item on /daily.
Set<String> get workDayOnlyItems => plan.workDayOnlyItems;
String get workDayOnlyFrom => plan.workDayOnlyFrom;


/// Default if-then plans (implementation intentions): the cue that
/// triggers each Daily 10 item. Editable on /plans.
Map<String, String> get defaultCues => plan.cues;

/// The smallest version of each Daily 10 item, for a hard day: enough to
/// keep the identity alive, small enough to do when sick or swamped.
Map<String, String> get defaultMinimums => plan.minimums;

const nonNegotiableGroups = [
  ['morning', 'Morning'],
  ['day', 'During the day'],
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

List<EvidencePrompt> get evidenceSections => plan.evidenceSections;

/// Starter items for "Knowledge I have that most don't" — from the profile.
List<String> get evidenceSeeds => plan.evidenceSeeds;

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
List<List<String>> get pathSteps => plan.pathSteps;

Map<int, String> get monthThemes => plan.monthThemes;

/// Suggested artifact for each month ("one artifact per month").
Map<int, String> get monthArtifacts => plan.monthArtifacts;

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

/// What the plan unlocks in [month] (books, style, career steps…).
List<Unlock> unlocksFor(int month) => plan.unlocks[month] ?? const [];

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

  /// Part of the working day: fires on the person's work days (Me → Work
  /// days), whatever [weekdays] says.
  final bool workDaysOnly;
  final String route;
  final bool defaultOn;

  const ReminderDef(this.id, this.label, this.hour, this.minute,
      {this.weekdays, this.workDaysOnly = false, required this.route, this.defaultOn = true});

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Gym reminder weekdays come from the user's gym days at runtime.
List<ReminderDef> get reminderDefs => plan.reminders;

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

List<StudyCard> get seedCards => plan.seedCards;

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
List<ReadinessDimension> get readinessDimensions => plan.readiness;

const readinessBar = 4;

// ------------------------------------------------------------
// Growth plan — one area a month, practised on the real job
// ------------------------------------------------------------

/// A practice rep: what to do this week and how you'll know it worked.
class Drill {
  final String title;
  final String how;
  final String signal;
  const Drill(this.title, this.how, this.signal);

  Map<String, dynamic> toJson() =>
      {'title': title, 'how': how, 'signal': signal};

  factory Drill.fromJson(Map m) =>
      Drill('${m['title'] ?? ''}', '${m['how'] ?? ''}', '${m['signal'] ?? ''}');
}

/// Something to get better at. Professional areas are the Head of Product
/// readiness dimensions; personal ones come from his own diagnosis.
class GrowthArea {
  final String id;
  final String name;
  final bool personal;

  /// What good looks like.
  final String bar;

  /// The feedback question to ask someone who sees you do it.
  final String ask;
  final List<Drill> drills;

  /// Created by him (or from a template), so editable and removable.
  final bool custom;

  /// What levels 1–5 look like, if written for this area; otherwise the
  /// general ladder in [levelsOf] is used.
  final List<String> levels;

  const GrowthArea(this.id, this.name,
      {required this.bar,
      required this.ask,
      required this.drills,
      this.personal = false,
      this.custom = false,
      this.levels = const []});

  GrowthArea copyWith({
    String? id,
    String? name,
    String? bar,
    String? ask,
    List<Drill>? drills,
    bool? personal,
    bool? custom,
    List<String>? levels,
  }) =>
      GrowthArea(id ?? this.id, name ?? this.name,
          bar: bar ?? this.bar,
          ask: ask ?? this.ask,
          drills: drills ?? this.drills,
          personal: personal ?? this.personal,
          custom: custom ?? this.custom,
          levels: levels ?? this.levels);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bar': bar,
        'ask': ask,
        'personal': personal,
        if (levels.isNotEmpty) 'levels': levels,
        'drills': [for (final d in drills) d.toJson()],
      };

  factory GrowthArea.fromJson(Map m) => GrowthArea(
        '${m['id']}',
        '${m['name'] ?? ''}',
        bar: '${m['bar'] ?? ''}',
        ask: '${m['ask'] ?? ''}',
        personal: m['personal'] == true,
        custom: true,
        levels: [for (final l in (m['levels'] as List? ?? const [])) '$l'],
        drills: [
          for (final d in (m['drills'] as List? ?? const []))
            Drill.fromJson(d as Map)
        ],
      );
}

List<GrowthArea> get growthAreas => plan.growthAreas;

/// Values to choose from; he picks 3–5 and says what each means to him.
const valueOptions = [
  'Craft', 'Integrity', 'Family', 'Courage', 'Legacy', 'Growth',
  'Faith', 'Calm', 'Curiosity', 'Excellence', 'Freedom', 'Health',
  'Loyalty', 'Impact', 'Respect', 'Service', 'Independence', 'Honesty',
];

/// What 1–5 means for [area]: its own five levels, or a general ladder
/// whose level 4 is the area's bar. Makes a self-rating a description you
/// recognise rather than a number you guess.
List<String> levelsOf(GrowthArea area) {
  if (area.levels.length == 5) return area.levels;
  return [
    'Aware: you know what good looks like, but rarely do it yet.',
    'Practising: you do it when you remember, or when it\'s easy.',
    'Consistent: you do it most of the time, in normal conditions.',
    'At the bar: ${area.bar.isEmpty ? 'you do it well, even under pressure' : area.bar} Even under pressure.',
    'Role model: others learn it from you; it holds on your worst days.',
  ];
}

GrowthArea growthArea(String id) =>
    growthAreas.where((a) => a.id == id).firstOrNull ??
    growthAreas.firstOrNull ??
    const GrowthArea('none', 'Your area', bar: '', ask: '', drills: []);

// ------------------------------------------------------------
// Automaticity — monthly "is it a habit yet?"
// ------------------------------------------------------------

/// Reminder that exists only to prompt a Daily 10 item; switched off once
/// the item is automatic.
Map<String, String> get itemReminder => plan.itemReminder;

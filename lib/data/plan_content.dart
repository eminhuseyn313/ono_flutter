// A person's full plan as data: the schedule, training plan, daily items,
// growth areas, reminders, reading, protocols, style and program content
// that make ONO theirs. The app ships with none of it; a plan is loaded
// from the person's account (or a file they import) and everything
// person-specific reads from [plan]. Without one, ONO is the general app
// built from what they set up themselves.
import 'package:flutter/material.dart';

import '../models/ai_coach.dart';
import '../models/personal_system.dart';
import '../models/ritual.dart';
import 'emin_system.dart';

/// Icons a plan may use, by name, so release builds keep only these.
const planIcons = <String, IconData>{
  'accessibility_new_rounded': Icons.accessibility_new_rounded,
  'air_rounded': Icons.air_rounded,
  'apartment_rounded': Icons.apartment_rounded,
  'auto_stories': Icons.auto_stories,
  'bedtime_rounded': Icons.bedtime_rounded,
  'bolt_rounded': Icons.bolt_rounded,
  'business_center_rounded': Icons.business_center_rounded,
  'checkroom_rounded': Icons.checkroom_rounded,
  'coffee_rounded': Icons.coffee_rounded,
  'directions_car_rounded': Icons.directions_car_rounded,
  'edit_note_rounded': Icons.edit_note_rounded,
  'edit_rounded': Icons.edit_rounded,
  'fitness_center_rounded': Icons.fitness_center_rounded,
  'flag_outlined': Icons.flag_outlined,
  'history_edu_rounded': Icons.history_edu_rounded,
  'inventory_2_rounded': Icons.inventory_2_rounded,
  'layers_rounded': Icons.layers_rounded,
  'local_cafe_rounded': Icons.local_cafe_rounded,
  'menu_book_rounded': Icons.menu_book_rounded,
  'nightlight_round': Icons.nightlight_round,
  'pause_circle_outline_rounded': Icons.pause_circle_outline_rounded,
  'podcasts_rounded': Icons.podcasts_rounded,
  'record_voice_over': Icons.record_voice_over,
  'restaurant_rounded': Icons.restaurant_rounded,
  'self_improvement': Icons.self_improvement,
  'self_improvement_rounded': Icons.self_improvement_rounded,
  'vertical_align_top_rounded': Icons.vertical_align_top_rounded,
  'water_drop': Icons.water_drop,
  'wb_twilight_rounded': Icons.wb_twilight_rounded,
  'weekend_rounded': Icons.weekend_rounded,
  'wine_bar_rounded': Icons.wine_bar_rounded,
  'work_outline_rounded': Icons.work_outline_rounded,
};

String iconName(IconData i) => planIcons.entries
    .firstWhere((e) => e.value.codePoint == i.codePoint && e.value.fontFamily == i.fontFamily,
        orElse: () => const MapEntry('flag_outlined', Icons.flag_outlined))
    .key;

IconData iconNamed(Object? name) => planIcons['$name'] ?? Icons.flag_outlined;

// ── Small JSON helpers ────────────────────────────────────────────────

List<Map> _maps(Object? v) => [for (final e in (v as List? ?? const [])) if (e is Map) e];
List<String> _strings(Object? v) => [for (final e in (v as List? ?? const [])) '$e'];
List<List<String>> _rows(Object? v) =>
    [for (final e in (v as List? ?? const [])) if (e is List) _strings(e)];
Map<int, String> _intMap(Object? v) => {
      for (final e in (v as Map? ?? const {}).entries)
        if (int.tryParse('${e.key}') != null) int.parse('${e.key}'): '${e.value}'
    };
Map<String, String> _strMap(Object? v) =>
    {for (final e in (v as Map? ?? const {}).entries) '${e.key}': '${e.value}'};
Map<String, String> _intKeys(Map<int, String> m) => {for (final e in m.entries) '${e.key}': e.value};
String? _opt(Object? v) => v == null ? null : '$v';
int _int(Object? v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;

// ── Serialisers for the content records ───────────────────────────────

Map<String, dynamic> scheduleToJson(ScheduleBlock b) => {
      'h': b.hour, 'm': b.minute, 'title': b.title, 'detail': b.detail,
      'lane': b.lane, 'icon': iconName(b.icon),
    };
ScheduleBlock scheduleFromJson(Map m) => ScheduleBlock(_int(m['h']), _int(m['m']),
    '${m['title'] ?? ''}', '${m['detail'] ?? ''}', '${m['lane'] ?? 'mind'}', iconNamed(m['icon']));

Map<String, dynamic> exerciseToJson(Exercise e) => {
      'name': e.name, 'sets': e.sets,
      if (e.note != null) 'note': e.note,
      if (e.keyLift) 'key': true,
      if (e.shoulder) 'shoulder': true,
    };
Exercise exerciseFromJson(Map m) => Exercise('${m['name'] ?? ''}', '${m['sets'] ?? ''}',
    note: _opt(m['note']), keyLift: m['key'] == true, shoulder: m['shoulder'] == true);

Map<String, dynamic> gymDayToJson(GymDay g) => {
      'id': g.id, 'letter': g.letter, 'name': g.name, 'weekday': g.weekday,
      'finisher': g.finisher,
      'exercises': [for (final e in g.exercises) exerciseToJson(e)],
    };
GymDay gymDayFromJson(Map m) => GymDay(
      id: '${m['id']}', letter: '${m['letter'] ?? ''}', name: '${m['name'] ?? ''}',
      weekday: _int(m['weekday'], 1), finisher: '${m['finisher'] ?? ''}',
      exercises: [for (final e in _maps(m['exercises'])) exerciseFromJson(e)],
    );

Map<String, dynamic> inputToJson(DailyInput i) =>
    {'weekday': i.weekday, 'title': i.title, 'detail': i.detail, if (i.url != null) 'url': i.url};
DailyInput inputFromJson(Map m) =>
    DailyInput(_int(m['weekday'], 1), '${m['title'] ?? ''}', '${m['detail'] ?? ''}', url: _opt(m['url']));

Map<String, dynamic> bookToJson(Book b) => {
      'slot': b.slot, if (b.month != null) 'month': b.month, 'title': b.title,
      'author': b.author, 'chapters': b.chapters, 'why': b.why, if (b.fiction) 'fiction': true,
    };
Book bookFromJson(Map m) => Book(
      slot: '${m['slot'] ?? ''}', month: m['month'] == null ? null : _int(m['month']),
      title: '${m['title'] ?? ''}', author: '${m['author'] ?? ''}',
      chapters: '${m['chapters'] ?? ''}', why: '${m['why'] ?? ''}', fiction: m['fiction'] == true,
    );

Map<String, dynamic> filmToJson(Film f) =>
    {'title': f.title, 'year': f.year, 'when': f.when, 'why': f.why};
Film filmFromJson(Map m) =>
    Film('${m['title'] ?? ''}', _int(m['year']), '${m['when'] ?? ''}', '${m['why'] ?? ''}');

Map<String, dynamic> protocolToJson(Protocol p) => {
      'id': p.id, 'name': p.name, 'lane': p.lane, 'icon': iconName(p.icon), 'what': p.what,
      'when': p.when, 'why': p.why, 'source': p.source,
      if (p.before != null) 'before': p.before, if (p.after != null) 'after': p.after,
    };
Protocol protocolFromJson(Map m) => Protocol(
      id: '${m['id']}', name: '${m['name'] ?? ''}', lane: '${m['lane'] ?? 'mind'}',
      icon: iconNamed(m['icon']), what: '${m['what'] ?? ''}', when: '${m['when'] ?? ''}',
      why: '${m['why'] ?? ''}', source: '${m['source'] ?? ''}',
      before: _opt(m['before']), after: _opt(m['after']),
    );

Map<String, dynamic> wardrobeToJson(WardrobeItem w) => {
      'id': w.id, 'week': w.week, 'item': w.item, 'min': w.minPrice, 'max': w.maxPrice,
      'where': w.where, 'month': w.month,
    };
WardrobeItem wardrobeFromJson(Map m) => WardrobeItem('${m['id']}', '${m['week'] ?? ''}',
    '${m['item'] ?? ''}', _int(m['min']), _int(m['max']), '${m['where'] ?? ''}', _int(m['month'], 1));

Map<String, dynamic> outfitToJson(Outfit o) =>
    {'occasion': o.occasion, 'formula': o.formula, 'icon': iconName(o.icon)};
Outfit outfitFromJson(Map m) =>
    Outfit('${m['occasion'] ?? ''}', '${m['formula'] ?? ''}', iconNamed(m['icon']));

Map<String, dynamic> certificateToJson(Certificate c) => {
      'id': c.id, 'priority': c.priority, 'timing': c.timing, 'name': c.name, 'org': c.org, 'url': c.url,
    };
Certificate certificateFromJson(Map m) => Certificate('${m['id']}', _int(m['priority']),
    '${m['timing'] ?? ''}', '${m['name'] ?? ''}', '${m['org'] ?? ''}', '${m['url'] ?? ''}');

Map<String, dynamic> milestoneToJson(CareerMilestone c) => {'month': c.month, 'targets': c.targets};
CareerMilestone milestoneFromJson(Map m) => CareerMilestone(_int(m['month'], 1), _strings(m['targets']));

Map<String, dynamic> itemToJson(NonNegotiable n) => {
      'id': n.id, 'title': n.title, 'lane': n.lane, 'when': n.when, if (n.route != null) 'route': n.route,
    };
NonNegotiable itemFromJson(Map m) => NonNegotiable('${m['id']}', '${m['title'] ?? ''}',
    '${m['lane'] ?? 'mind'}', '${m['when'] ?? 'day'}', route: _opt(m['route']));

Map<String, dynamic> laneFocusToJson(LaneFocus l) =>
    {'lane': l.lane, 'name': l.name, 'problem': l.problem, 'actions': l.actions};
LaneFocus laneFocusFromJson(Map m) => LaneFocus('${m['lane'] ?? 'mind'}', '${m['name'] ?? ''}',
    '${m['problem'] ?? ''}', _strings(m['actions']));

Map<String, dynamic> evidenceToJson(EvidencePrompt e) =>
    {'section': e.section, 'title': e.title, 'prompts': e.prompts};
EvidencePrompt evidenceFromJson(Map m) =>
    EvidencePrompt('${m['section'] ?? ''}', '${m['title'] ?? ''}', _strings(m['prompts']));

Map<String, dynamic> unlockToJson(Unlock u) => {
      'kind': u.kind, 'title': u.title, 'detail': u.detail,
      if (u.route != null) 'route': u.route, if (u.doneKey != null) 'done': u.doneKey,
    };
Unlock unlockFromJson(Map m) => Unlock('${m['kind'] ?? 'milestone'}', '${m['title'] ?? ''}',
    '${m['detail'] ?? ''}', route: _opt(m['route']), doneKey: _opt(m['done']));

Map<String, dynamic> reminderToJson(ReminderDef r) => {
      'id': r.id, 'label': r.label, 'h': r.hour, 'm': r.minute,
      if (r.weekdays != null) 'weekdays': r.weekdays,
      if (r.workDaysOnly) 'work_days_only': true,
      'route': r.route, if (!r.defaultOn) 'default_on': false,
    };
ReminderDef reminderFromJson(Map m) => ReminderDef('${m['id']}', '${m['label'] ?? ''}',
    _int(m['h']), _int(m['m']),
    weekdays: m['weekdays'] is List ? [for (final d in m['weekdays'] as List) _int(d, 1)] : null,
    workDaysOnly: m['work_days_only'] == true, route: '${m['route'] ?? '/home'}',
    defaultOn: m['default_on'] != false);

Map<String, dynamic> readinessToJson(ReadinessDimension r) => {'id': r.id, 'name': r.name, 'bar': r.bar};
ReadinessDimension readinessFromJson(Map m) =>
    ReadinessDimension('${m['id']}', '${m['name'] ?? ''}', '${m['bar'] ?? ''}');

Map<String, dynamic> ritualToJson(RitualStep r) => {
      'id': r.id, 'title': r.title, 'subtitle': r.subtitle, 'lane': r.lane.name,
      'seconds': r.durationSeconds, 'icon': iconName(r.iconData), 'instruction': r.instruction,
      if (r.isOptional) 'optional': true,
    };
RitualStep ritualFromJson(Map m) => RitualStep(
      id: '${m['id']}', title: '${m['title'] ?? ''}', subtitle: '${m['subtitle'] ?? ''}',
      lane: RitualLane.values.firstWhere((l) => l.name == m['lane'], orElse: () => RitualLane.mind),
      durationSeconds: _int(m['seconds'], 60), iconData: iconNamed(m['icon']),
      instruction: '${m['instruction'] ?? ''}', isOptional: m['optional'] == true,
    );

Map<String, dynamic> tipToJson(DailyCoachTip t) =>
    {'id': t.id, 'title': t.title, 'content': t.content, 'lane': t.lane, 'color': t.laneColorValue};
DailyCoachTip tipFromJson(Map m, DateTime date) => DailyCoachTip(
      id: '${m['id']}', title: '${m['title'] ?? ''}', content: '${m['content'] ?? ''}',
      lane: '${m['lane'] ?? 'mind'}', laneColorValue: _int(m['color'], 0xFF8EA4D2), date: date,
    );

GrowthArea areaFromPlanJson(Map m) =>
    GrowthArea.fromJson(m).copyWith(custom: m['custom'] == true);

// ── The plan ──────────────────────────────────────────────────────────

/// Everything that makes a plan one person's. Lists are empty and texts
/// blank in [PlanContent.empty], so screens show only general content.
class PlanContent {
  final Profile? profile;
  final List<List<String>> manifesto;
  final List<LaneFocus> laneFocus;
  final List<ScheduleBlock> schedule;
  final List<GymDay> gym;
  final List<Exercise> shoulderSparing;
  final List<String> avoidLifts;
  final List<String> liftSwaps;
  final List<String> supplementsMorning;
  final List<String> supplementsNight;
  final List<String> bloodwork;
  final Map<int, String> eveningFocus;
  final List<DailyInput> podcasts;
  final List<DailyInput> domainScans;
  final List<Book> books;
  final List<Book> novels;
  final List<Film> films;
  final List<Protocol> protocols;
  final List<List<String>> faceNotes;
  final List<List<String>> beardSpec;
  final List<WardrobeItem> wardrobe;
  final List<Outfit> outfits;
  final int weekdayOutfit;
  final int weekendOutfit;
  final List<List<String>> watchRule;
  final List<List<String>> groomingRoutine;
  final List<List<String>> skincarePlan;
  final String linkedinHeadline;
  final String linkedinAbout;
  final String linkedinRole;
  final String linkedinFirstPost;
  final String domainThesis;
  final List<List<String>> keyData;
  final List<Certificate> certificates;
  final List<CareerMilestone> careerMilestones;
  final List<NonNegotiable> dailyItems;
  final Set<String> workDayOnlyItems;
  final String workDayOnlyFrom;
  final Map<String, String> cues;
  final Map<String, String> minimums;
  final List<EvidencePrompt> evidenceSections;
  final List<String> evidenceSeeds;
  final List<List<String>> pathSteps;
  final Map<int, String> monthThemes;
  final Map<int, String> monthArtifacts;
  final Map<int, List<Unlock>> unlocks;
  final List<ReminderDef> reminders;
  final List<ReadinessDimension> readiness;
  final List<GrowthArea> growthAreas;
  final Map<String, String> itemReminder;
  final List<RitualStep> ritual;
  final List<Map> coachTips;
  final List<String> weeklyReviewQuestions;
  final List<StudyCard> seedCards;

  const PlanContent({
    this.profile,
    this.manifesto = const [],
    this.laneFocus = const [],
    this.schedule = const [],
    this.gym = const [],
    this.shoulderSparing = const [],
    this.avoidLifts = const [],
    this.liftSwaps = const [],
    this.supplementsMorning = const [],
    this.supplementsNight = const [],
    this.bloodwork = const [],
    this.eveningFocus = const {},
    this.podcasts = const [],
    this.domainScans = const [],
    this.books = const [],
    this.novels = const [],
    this.films = const [],
    this.protocols = const [],
    this.faceNotes = const [],
    this.beardSpec = const [],
    this.wardrobe = const [],
    this.outfits = const [],
    this.weekdayOutfit = 0,
    this.weekendOutfit = 0,
    this.watchRule = const [],
    this.groomingRoutine = const [],
    this.skincarePlan = const [],
    this.linkedinHeadline = '',
    this.linkedinAbout = '',
    this.linkedinRole = '',
    this.linkedinFirstPost = '',
    this.domainThesis = '',
    this.keyData = const [],
    this.certificates = const [],
    this.careerMilestones = const [],
    this.dailyItems = const [],
    this.workDayOnlyItems = const {},
    this.workDayOnlyFrom = '',
    this.cues = const {},
    this.minimums = const {},
    this.evidenceSections = const [],
    this.evidenceSeeds = const [],
    this.pathSteps = const [],
    this.monthThemes = const {},
    this.monthArtifacts = const {},
    this.unlocks = const {},
    this.reminders = const [],
    this.readiness = const [],
    this.growthAreas = const [],
    this.itemReminder = const {},
    this.ritual = const [],
    this.coachTips = const [],
    this.weeklyReviewQuestions = const [],
    this.seedCards = const [],
  });

  static const empty = PlanContent();

  /// A person's plan is loaded (rather than the general app's nothing).
  bool get isPersonal => profile != null && profile!.name.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'format': 1,
        if (profile != null) 'profile': profile!.toJson(),
        'manifesto': manifesto,
        'lane_focus': [for (final l in laneFocus) laneFocusToJson(l)],
        'schedule': [for (final b in schedule) scheduleToJson(b)],
        'gym': [for (final g in gym) gymDayToJson(g)],
        'shoulder_sparing': [for (final e in shoulderSparing) exerciseToJson(e)],
        'avoid_lifts': avoidLifts,
        'lift_swaps': liftSwaps,
        'supplements_morning': supplementsMorning,
        'supplements_night': supplementsNight,
        'bloodwork': bloodwork,
        'evening_focus': _intKeys(eveningFocus),
        'podcasts': [for (final i in podcasts) inputToJson(i)],
        'domain_scans': [for (final i in domainScans) inputToJson(i)],
        'books': [for (final b in books) bookToJson(b)],
        'novels': [for (final b in novels) bookToJson(b)],
        'films': [for (final f in films) filmToJson(f)],
        'protocols': [for (final p in protocols) protocolToJson(p)],
        'face_notes': faceNotes,
        'beard_spec': beardSpec,
        'wardrobe': [for (final w in wardrobe) wardrobeToJson(w)],
        'outfits': [for (final o in outfits) outfitToJson(o)],
        'weekday_outfit': weekdayOutfit,
        'weekend_outfit': weekendOutfit,
        'watch_rule': watchRule,
        'grooming_routine': groomingRoutine,
        'skincare_plan': skincarePlan,
        'linkedin_headline': linkedinHeadline,
        'linkedin_about': linkedinAbout,
        'linkedin_role': linkedinRole,
        'linkedin_first_post': linkedinFirstPost,
        'domain_thesis': domainThesis,
        'key_data': keyData,
        'certificates': [for (final c in certificates) certificateToJson(c)],
        'career_milestones': [for (final c in careerMilestones) milestoneToJson(c)],
        'daily_items': [for (final n in dailyItems) itemToJson(n)],
        'work_day_only_items': workDayOnlyItems.toList(),
        'work_day_only_from': workDayOnlyFrom,
        'cues': cues,
        'minimums': minimums,
        'evidence_sections': [for (final e in evidenceSections) evidenceToJson(e)],
        'evidence_seeds': evidenceSeeds,
        'path_steps': pathSteps,
        'month_themes': _intKeys(monthThemes),
        'month_artifacts': _intKeys(monthArtifacts),
        'unlocks': {
          for (final e in unlocks.entries) '${e.key}': [for (final u in e.value) unlockToJson(u)]
        },
        'reminders': [for (final r in reminders) reminderToJson(r)],
        'readiness': [for (final r in readiness) readinessToJson(r)],
        'growth_areas': [for (final a in growthAreas) {...a.toJson(), if (a.custom) 'custom': true}],
        'item_reminder': itemReminder,
        'ritual': [for (final r in ritual) ritualToJson(r)],
        'coach_tips': coachTips,
        'weekly_review_questions': weeklyReviewQuestions,
        'seed_cards': [for (final c in seedCards) c.toJson()],
      };

  factory PlanContent.fromJson(Map m) => PlanContent(
        profile: m['profile'] is Map
            ? Profile.fromJson(Map<String, dynamic>.from(m['profile'] as Map))
            : null,
        manifesto: _rows(m['manifesto']),
        laneFocus: [for (final e in _maps(m['lane_focus'])) laneFocusFromJson(e)],
        schedule: [for (final e in _maps(m['schedule'])) scheduleFromJson(e)],
        gym: [for (final e in _maps(m['gym'])) gymDayFromJson(e)],
        shoulderSparing: [for (final e in _maps(m['shoulder_sparing'])) exerciseFromJson(e)],
        avoidLifts: _strings(m['avoid_lifts']),
        liftSwaps: _strings(m['lift_swaps']),
        supplementsMorning: _strings(m['supplements_morning']),
        supplementsNight: _strings(m['supplements_night']),
        bloodwork: _strings(m['bloodwork']),
        eveningFocus: _intMap(m['evening_focus']),
        podcasts: [for (final e in _maps(m['podcasts'])) inputFromJson(e)],
        domainScans: [for (final e in _maps(m['domain_scans'])) inputFromJson(e)],
        books: [for (final e in _maps(m['books'])) bookFromJson(e)],
        novels: [for (final e in _maps(m['novels'])) bookFromJson(e)],
        films: [for (final e in _maps(m['films'])) filmFromJson(e)],
        protocols: [for (final e in _maps(m['protocols'])) protocolFromJson(e)],
        faceNotes: _rows(m['face_notes']),
        beardSpec: _rows(m['beard_spec']),
        wardrobe: [for (final e in _maps(m['wardrobe'])) wardrobeFromJson(e)],
        outfits: [for (final e in _maps(m['outfits'])) outfitFromJson(e)],
        weekdayOutfit: _int(m['weekday_outfit']),
        weekendOutfit: _int(m['weekend_outfit']),
        watchRule: _rows(m['watch_rule']),
        groomingRoutine: _rows(m['grooming_routine']),
        skincarePlan: _rows(m['skincare_plan']),
        linkedinHeadline: '${m['linkedin_headline'] ?? ''}',
        linkedinAbout: '${m['linkedin_about'] ?? ''}',
        linkedinRole: '${m['linkedin_role'] ?? ''}',
        linkedinFirstPost: '${m['linkedin_first_post'] ?? ''}',
        domainThesis: '${m['domain_thesis'] ?? ''}',
        keyData: _rows(m['key_data']),
        certificates: [for (final e in _maps(m['certificates'])) certificateFromJson(e)],
        careerMilestones: [for (final e in _maps(m['career_milestones'])) milestoneFromJson(e)],
        dailyItems: [for (final e in _maps(m['daily_items'])) itemFromJson(e)],
        workDayOnlyItems: _strings(m['work_day_only_items']).toSet(),
        workDayOnlyFrom: '${m['work_day_only_from'] ?? ''}',
        cues: _strMap(m['cues']),
        minimums: _strMap(m['minimums']),
        evidenceSections: [for (final e in _maps(m['evidence_sections'])) evidenceFromJson(e)],
        evidenceSeeds: _strings(m['evidence_seeds']),
        pathSteps: _rows(m['path_steps']),
        monthThemes: _intMap(m['month_themes']),
        monthArtifacts: _intMap(m['month_artifacts']),
        unlocks: {
          for (final e in (m['unlocks'] as Map? ?? const {}).entries)
            if (int.tryParse('${e.key}') != null)
              int.parse('${e.key}'): [for (final u in _maps(e.value)) unlockFromJson(u)]
        },
        reminders: [for (final e in _maps(m['reminders'])) reminderFromJson(e)],
        readiness: [for (final e in _maps(m['readiness'])) readinessFromJson(e)],
        growthAreas: [for (final e in _maps(m['growth_areas'])) areaFromPlanJson(e)],
        itemReminder: _strMap(m['item_reminder']),
        ritual: [for (final e in _maps(m['ritual'])) ritualFromJson(e)],
        coachTips: _maps(m['coach_tips']),
        weeklyReviewQuestions: _strings(m['weekly_review_questions']),
        seedCards: [
          for (final e in _maps(m['seed_cards']))
            StudyCard('${e['id']}', '${e['front'] ?? ''}', '${e['back'] ?? ''}',
                source: '${e['source'] ?? 'seed'}')
        ],
      );
}

/// The plan in use: the signed-in person's (set by the provider from their
/// data), else [fallbackPlan], else none.
PlanContent? planOverride;

/// Only tests set this: an example plan used when no person's plan is
/// loaded. The app ships with none.
PlanContent? fallbackPlan;

PlanContent get plan => planOverride ?? fallbackPlan ?? PlanContent.empty;

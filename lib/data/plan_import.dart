// Reads a full plan the way people will actually bring one: written by an
// AI tool (ChatGPT, Claude, Gemini…) from the prompt in plan_prompt.dart,
// pasted with code fences around it, with times as "07:30", weekdays as
// names, ids missing, a lane called "career". Everything is normalised into
// the plan document (PlanContent), and the person is told what loaded and
// what was skipped, so a slightly different file never loses a plan.
//
// The format is documented in docs/PLAN_FORMAT.md.
import 'dart:convert';

import 'plan_content.dart';

/// The result of reading a plan: the plan (null when it can't be read), a
/// line per section that loaded, and what was skipped or fixed.
class PlanImportResult {
  final PlanContent? plan;
  final List<String> loaded;
  final List<String> warnings;
  final String? error;

  const PlanImportResult({this.plan, this.loaded = const [], this.warnings = const [], this.error});

  bool get ok => plan != null;
}

/// The latest format version ONO writes. Older or unmarked files still load.
const planFormatVersion = 1;

/// Reads [text] as a plan. [routeOk] says whether an in-app link exists;
/// links that don't are dropped (a tap must never lead nowhere).
PlanImportResult importPlan(String text, {bool Function(String route)? routeOk}) {
  final raw = extractJsonObject(text);
  if (raw == null) {
    return const PlanImportResult(
        error: 'There is no plan in that text. Paste the whole answer, from the first { to the last }.');
  }
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    return PlanImportResult(
        error: 'The plan is cut off or has a typo (${e.message}). Ask the AI to "send the complete JSON again, nothing else".');
  }
  if (decoded is! Map) {
    return const PlanImportResult(error: 'That is a list, not a plan. The plan is one { … } object.');
  }
  final n = _Normaliser(routeOk ?? (_) => true);
  final m = n.root(decoded);
  final name = '${(m['profile'] as Map?)?['name'] ?? ''}'.trim();
  if (name.isEmpty) {
    return const PlanImportResult(
        error: 'The plan has no name. It needs "profile": { "name": "Your Name" }.');
  }
  final plan = PlanContent.fromJson(m);
  return PlanImportResult(plan: plan, loaded: _summary(plan), warnings: n.warnings);
}

/// The JSON object inside [text]: without code fences or chat around it.
String? extractJsonObject(String text) {
  final t = text.replaceAll('﻿', '');
  final start = t.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < t.length; i++) {
    final c = t[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == '\\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return _relaxed(t.substring(start, i + 1));
    }
  }
  // Cut off: hand back what's there so the error says so.
  return t.substring(start);
}

/// Smart quotes and trailing commas, which chat tools sometimes add.
String _relaxed(String s) => s
    .replaceAll(RegExp('[“”]'), '"')
    .replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m.group(1)!);

List<String> _summary(PlanContent p) => [
      'Profile: ${p.profile!.name}${p.profile!.targetRole.isEmpty ? '' : ', becoming ${p.profile!.targetRole}'}',
      if (p.dailyItems.isNotEmpty) '${p.dailyItems.length} daily items',
      if (p.schedule.isNotEmpty) 'A day in ${p.schedule.length} blocks',
      if (p.gym.isNotEmpty) '${p.gym.length} training days',
      if (p.growthAreas.isNotEmpty) '${p.growthAreas.length} growth areas',
      if (p.books.isNotEmpty || p.novels.isNotEmpty) '${p.books.length + p.novels.length} books',
      if (p.films.isNotEmpty) '${p.films.length} films',
      if (p.podcasts.isNotEmpty) '${p.podcasts.length} podcast days',
      if (p.protocols.isNotEmpty) '${p.protocols.length} practices',
      if (p.reminders.isNotEmpty) '${p.reminders.length} reminders',
      if (p.monthThemes.isNotEmpty) '${p.monthThemes.length} month themes',
      if (p.unlocks.isNotEmpty) 'Things to unlock in ${p.unlocks.length} months',
      if (p.careerMilestones.isNotEmpty) '${p.careerMilestones.length} milestones',
      if (p.ritual.isNotEmpty) 'A morning ritual of ${p.ritual.length} steps',
      if (p.coachTips.isNotEmpty) '${p.coachTips.length} coach notes',
      if (p.seedCards.isNotEmpty) '${p.seedCards.length} cards to remember',
      if (p.extras.isNotEmpty)
        '${p.extras.length} more ${p.extras.length == 1 ? 'section' : 'sections'} (${p.extras.keys.map(planSectionTitle).join(', ')}): under "More from your plan"',
    ];

/// "weekly_rituals" or "weeklyRituals" → "Weekly rituals".
String planSectionTitle(String key) {
  final words = key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim()
      .toLowerCase();
  return words.isEmpty ? key : '${words[0].toUpperCase()}${words.substring(1)}';
}

class _Normaliser {
  final bool Function(String) routeOk;
  final warnings = <String>[];
  _Normaliser(this.routeOk);

  void warn(String w) {
    if (!warnings.contains(w)) warnings.add(w);
  }

  // ── Small readers ──────────────────────────────────────────────────

  Object? pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null) return m[k];
    }
    return null;
  }

  String str(Map m, List<String> keys) => '${pick(m, keys) ?? ''}'.trim();

  List<Object?> list(Object? v) => v is List ? v : (v == null ? const [] : [v]);

  static const _days = {
    'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7,
  };

  int? weekday(Object? v) {
    if (v is num) return v >= 1 && v <= 7 ? v.toInt() : null;
    final s = '$v'.trim().toLowerCase();
    final n = int.tryParse(s);
    if (n != null) return n >= 1 && n <= 7 ? n : null;
    return s.length >= 3 ? _days[s.substring(0, 3)] : null;
  }

  /// (hour, minute) from "07:30", "7.30", "7:30 pm", or h/m numbers.
  (int, int)? time(Map m) {
    final h = pick(m, ['h', 'hour']);
    if (h is num) {
      final mm = pick(m, ['m', 'minute', 'min']);
      return (h.toInt().clamp(0, 23), (mm is num ? mm.toInt() : 0).clamp(0, 59));
    }
    final t = '${pick(m, ['time', 'at', 'start']) ?? ''}'.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)?').firstMatch(t);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (match.group(3) == 'pm' && hour < 12) hour += 12;
    if (match.group(3) == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  static const _laneWords = {
    'mind': 'mind', 'mental': 'mind', 'wellbeing': 'mind', 'spirit': 'mind', 'meaning': 'mind',
    'calm': 'mind', 'rest': 'mind', 'sleep': 'body',
    'body': 'body', 'health': 'body', 'fitness': 'body', 'physical': 'body', 'food': 'body',
    'nutrition': 'body', 'training': 'body',
    'skill': 'skill', 'career': 'skill', 'work': 'skill', 'learning': 'skill', 'craft': 'skill',
    'money': 'skill', 'professional': 'skill', 'study': 'skill',
    'social': 'social', 'people': 'social', 'relationships': 'social', 'family': 'social',
    'friends': 'social', 'love': 'social', 'community': 'social',
  };

  String lane(Object? v) {
    final s = '${v ?? ''}'.trim().toLowerCase();
    return _laneWords[s] ?? 'mind';
  }

  String when(Object? v) {
    final s = '${v ?? ''}'.trim().toLowerCase();
    if (s.startsWith('morn') || s == 'am' || s == 'wake') return 'morning';
    if (s.startsWith('even') || s.startsWith('night') || s == 'pm' || s == 'bed') return 'evening';
    return 'day';
  }

  String slug(String s) {
    final t = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return t.isEmpty ? 'item' : (t.length > 24 ? t.substring(0, 24) : t);
  }

  String unique(String base, Set<String> used) {
    var id = base;
    var i = 2;
    while (used.contains(id)) {
      id = '${base}_${i++}';
    }
    used.add(id);
    return id;
  }

  String? route(Object? v, String what) {
    if (v == null) return null;
    final r = '$v'.trim();
    if (r.isEmpty) return null;
    if (r.startsWith('/') && routeOk(r)) return r;
    warn('$what linked to "$r", which ONO doesn\'t have — kept without the link.');
    return null;
  }

  // ── The plan ───────────────────────────────────────────────────────

  Map<String, dynamic> root(Map input) {
    var m = input;
    for (final k in ['ono_plan', 'plan', 'onoPlan']) {
      if (m[k] is Map) m = m[k] as Map;
    }
    final out = <String, dynamic>{...m.map((k, v) => MapEntry('$k', v))};
    out['format'] = planFormatVersion;
    out['profile'] = profile(m);
    final cues = <String, String>{..._strMap(m['cues'])};
    final minimums = <String, String>{..._strMap(m['minimums'])};
    out['daily_items'] = dailyItems(pick(m, ['daily_items', 'dailyItems', 'daily', 'habits']), cues, minimums);
    out['cues'] = cues;
    out['minimums'] = minimums;
    out['schedule'] = schedule(pick(m, ['schedule', 'day', 'daily_schedule']));
    out['gym'] = gym(pick(m, ['gym', 'training', 'workouts']));
    out['growth_areas'] = areas(pick(m, ['growth_areas', 'growthAreas', 'areas']));
    final books = <Map<String, dynamic>>[];
    final novels = <Map<String, dynamic>>[];
    for (final b in [...list(pick(m, ['books', 'reading'])), ...list(m['novels'])]) {
      final x = book(b);
      if (x == null) continue;
      (x['fiction'] == true ? novels : books).add(x);
    }
    out['books'] = books;
    out['novels'] = novels;
    out['films'] = [for (final f in list(pick(m, ['films', 'movies']))) if (film(f) case final x?) x];
    out['podcasts'] = inputs(pick(m, ['podcasts', 'listening']), 'Podcast');
    out['domain_scans'] = inputs(pick(m, ['domain_scans', 'daily_reads', 'scans', 'reading_rotation']), 'Daily read');
    out['protocols'] = practices(pick(m, ['protocols', 'practices', 'tools']));
    out['reminders'] = reminders(m['reminders']);
    out['month_themes'] = monthMap(pick(m, ['month_themes', 'monthThemes', 'months']), ['theme', 'focus', 'text']);
    out['month_artifacts'] = monthMap(pick(m, ['month_artifacts', 'artifacts']), ['artifact', 'title', 'text']);
    out['unlocks'] = unlocks(m['unlocks']);
    out['career_milestones'] = milestones(pick(m, ['career_milestones', 'milestones']));
    out['ritual'] = ritual(pick(m, ['ritual', 'morning_ritual']));
    out['coach_tips'] = tips(pick(m, ['coach_tips', 'coach_notes', 'tips']));
    out['seed_cards'] = cards(pick(m, ['seed_cards', 'cards', 'flashcards']));
    out['weekly_review_questions'] = [
      for (final q in list(pick(m, ['weekly_review_questions', 'weekly_questions'])))
        if ('$q'.trim().isNotEmpty) '$q'.trim()
    ];
    out['evening_focus'] = weekdayMap(m['evening_focus']);
    return out;
  }

  Map<String, String> _strMap(Object? v) =>
      {for (final e in (v is Map ? v.entries : const <MapEntry>[])) '${e.key}': '${e.value}'};

  Map<String, dynamic> profile(Map m) {
    final p = (pick(m, ['profile', 'person', 'me']) as Map?) ?? m;
    final name = str(p, ['name', 'full_name', 'fullName']);
    final people = <Map<String, dynamic>>[];
    for (final k in list(pick(p, ['key_people', 'keyPeople', 'people']))) {
      if (k is Map) {
        final n = str(k, ['name']);
        if (n.isEmpty) continue;
        final every = pick(k, ['every', 'every_days', 'contact_every_days']);
        people.add({
          'name': n,
          'relation': str(k, ['relation', 'role', 'who']),
          'every': every is num ? every.toInt().clamp(1, 365) : 14,
          'primary': k['primary'] == true,
        });
      } else if ('$k'.trim().isNotEmpty) {
        people.add({'name': '$k'.trim(), 'relation': '', 'every': 14, 'primary': false});
      }
    }
    return {
      'name': name,
      'first_name': str(p, ['first_name', 'firstName']).isEmpty ? name.split(' ').first : str(p, ['first_name', 'firstName']),
      'current_role': str(p, ['current_role', 'currentRole', 'role', 'now']),
      'target_role': str(p, ['target_role', 'targetRole', 'becoming', 'goal_role']),
      'organisation': str(p, ['organisation', 'organization', 'company', 'employer']),
      'focus': str(p, ['focus']),
      'domain': str(p, ['domain', 'field']),
      'identity_statement': str(p, ['identity_statement', 'identityStatement', 'identity']),
      'archetype': str(p, ['archetype']),
      'tagline': str(p, ['tagline']),
      'location': str(p, ['location', 'city']),
      'path': [for (final s in list(p['path'])) '$s'],
      'key_people': people,
      'context': str(p, ['context', 'coach_context', 'coachContext', 'about']),
    };
  }

  List<Map<String, dynamic>> dailyItems(Object? v, Map<String, String> cues, Map<String, String> minimums) {
    final used = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final e in list(v)) {
      final m = e is Map ? e : {'title': '$e'};
      final title = str(m, ['title', 'name', 'what', 'habit']);
      if (title.isEmpty) continue;
      final id = unique(str(m, ['id']).isEmpty ? slug(title) : slug(str(m, ['id'])), used);
      final r = route(m['route'], '"$title"');
      out.add({
        'id': id,
        'title': title,
        'lane': lane(pick(m, ['lane', 'area', 'category'])),
        'when': when(pick(m, ['when', 'time_of_day', 'time'])),
        if (r != null) 'route': r,
      });
      final cue = str(m, ['cue', 'if_then', 'trigger']);
      if (cue.isNotEmpty) cues[id] = cue;
      final min = str(m, ['minimum', 'min', 'minimum_version']);
      if (min.isNotEmpty) minimums[id] = min;
    }
    if (out.length > 15) {
      warn('${out.length} daily items is a lot — kept the first 15. Fewer, done daily, beats many done sometimes.');
      return out.take(15).toList();
    }
    if (out.isNotEmpty && out.length < 3) {
      warn('Only ${out.length} daily items — ONO counts a day as held from a list of three or more; add some on Your daily items.');
    }
    return out;
  }

  List<Map<String, dynamic>> schedule(Object? v) {
    final out = <Map<String, dynamic>>[];
    for (final e in list(v)) {
      if (e is! Map) continue;
      final t = time(e);
      final title = str(e, ['title', 'name', 'what']);
      if (t == null || title.isEmpty) {
        if (title.isNotEmpty) warn('Schedule block "$title" has no time — left out.');
        continue;
      }
      out.add({
        'h': t.$1, 'm': t.$2, 'title': title,
        'detail': str(e, ['detail', 'details', 'note', 'description']),
        'lane': lane(pick(e, ['lane', 'area', 'category'])),
        'icon': str(e, ['icon']),
      });
    }
    out.sort((a, b) => (a['h'] as int) * 60 + (a['m'] as int) - (b['h'] as int) * 60 - (b['m'] as int));
    return out;
  }

  Map<String, dynamic> exercise(Object? e) {
    if (e is Map) {
      return {
        'name': str(e, ['name', 'exercise', 'title']),
        'sets': str(e, ['sets', 'scheme', 'reps']),
        if (str(e, ['note', 'notes']).isNotEmpty) 'note': str(e, ['note', 'notes']),
        if (pick(e, ['key', 'key_lift', 'keyLift']) == true) 'key': true,
        if (e['shoulder'] == true) 'shoulder': true,
      };
    }
    // "Goblet squat 3×12" → name and sets.
    final s = '$e'.trim();
    final m = RegExp(r'^(.*?)[\s—–-]*(\d+\s*[x×]\s*[\d\w ]+)$').firstMatch(s);
    return m == null ? {'name': s, 'sets': ''} : {'name': m.group(1)!.trim(), 'sets': m.group(2)!.trim()};
  }

  List<Map<String, dynamic>> gym(Object? v) {
    final out = <Map<String, dynamic>>[];
    final used = <String>{};
    var i = 0;
    for (final e in list(v)) {
      if (e is! Map) continue;
      final letter = str(e, ['letter']).isEmpty ? String.fromCharCode(65 + i) : str(e, ['letter']);
      final day = weekday(pick(e, ['weekday', 'day']));
      final exercises = [
        for (final x in list(pick(e, ['exercises', 'moves', 'lifts']))) exercise(x)
      ].where((x) => '${x['name']}'.isNotEmpty).toList();
      if (exercises.isEmpty) continue;
      out.add({
        'id': unique(str(e, ['id']).isEmpty ? 'day_${letter.toLowerCase()}' : slug(str(e, ['id'])), used),
        'letter': letter,
        'name': str(e, ['name', 'title', 'focus']).isEmpty ? 'Day $letter' : str(e, ['name', 'title', 'focus']),
        'weekday': day ?? const [1, 3, 5, 2, 4, 6, 7][i % 7],
        'finisher': str(e, ['finisher', 'cooldown', 'finish']),
        'exercises': exercises,
      });
      i++;
    }
    return out;
  }

  List<Map<String, dynamic>> areas(Object? v) {
    final out = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final e in list(v)) {
      if (e is! Map) continue;
      final name = str(e, ['name', 'title', 'area']);
      if (name.isEmpty) continue;
      out.add({
        'id': unique(str(e, ['id']).isEmpty ? slug(name) : slug(str(e, ['id'])), used),
        'name': name,
        'bar': str(e, ['bar', 'good_looks_like', 'goal']),
        'ask': str(e, ['ask', 'feedback_question', 'question']),
        'personal': e['personal'] == true,
        'levels': [for (final l in list(e['levels'])) '$l'].take(5).toList(),
        'drills': [
          for (final d in list(pick(e, ['drills', 'practices', 'exercises'])))
            if (d is Map)
              {'title': str(d, ['title', 'name']), 'how': str(d, ['how', 'what']), 'signal': str(d, ['signal', 'sign', 'evidence'])}
            else if ('$d'.trim().isNotEmpty)
              {'title': '$d'.trim(), 'how': '', 'signal': ''}
        ],
      });
    }
    return out;
  }

  Map<String, dynamic>? book(Object? e) {
    final m = e is Map ? e : {'title': '$e'};
    final title = str(m, ['title', 'name']);
    if (title.isEmpty) return null;
    final month = pick(m, ['month']);
    final kind = str(m, ['kind', 'type', 'genre']).toLowerCase();
    return {
      'slot': str(m, ['slot']).isEmpty ? (month is num ? 'Month ${month.toInt()}' : 'Any time') : str(m, ['slot']),
      if (month is num) 'month': month.toInt(),
      'title': title,
      'author': str(m, ['author', 'by']),
      'chapters': str(m, ['chapters', 'read', 'focus']),
      'why': str(m, ['why', 'reason', 'because']),
      if (m['fiction'] == true || kind.contains('fiction') || kind == 'novel') 'fiction': true,
    };
  }

  Map<String, dynamic>? film(Object? e) {
    final m = e is Map ? e : {'title': '$e'};
    final title = str(m, ['title', 'name']);
    if (title.isEmpty) return null;
    final year = pick(m, ['year']);
    return {
      'title': title,
      'year': year is num ? year.toInt() : int.tryParse('$year') ?? 0,
      'when': str(m, ['when', 'month']),
      'why': str(m, ['why', 'reason']),
    };
  }

  List<Map<String, dynamic>> inputs(Object? v, String what) {
    final out = <Map<String, dynamic>>[];
    for (final e in list(v)) {
      if (e is! Map) continue;
      final day = weekday(pick(e, ['weekday', 'day']));
      final title = str(e, ['title', 'name', 'show', 'source']);
      if (day == null || title.isEmpty) continue;
      out.add({
        'weekday': day, 'title': title, 'detail': str(e, ['detail', 'episode', 'why', 'note']),
        if (str(e, ['url', 'link']).isNotEmpty) 'url': str(e, ['url', 'link']),
      });
    }
    return out;
  }

  List<Map<String, dynamic>> practices(Object? v) {
    final out = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final e in list(v)) {
      if (e is! Map) continue;
      final name = str(e, ['name', 'title']);
      if (name.isEmpty) continue;
      out.add({
        'id': unique(str(e, ['id']).isEmpty ? slug(name) : slug(str(e, ['id'])), used),
        'name': name,
        'lane': lane(pick(e, ['lane', 'area'])),
        'icon': str(e, ['icon']),
        'what': str(e, ['what', 'how', 'steps']),
        'when': str(e, ['when', 'use_when']),
        'why': str(e, ['why', 'because']),
        'source': str(e, ['source', 'evidence', 'reference']),
        if (str(e, ['before']).isNotEmpty) 'before': str(e, ['before']),
        if (str(e, ['after']).isNotEmpty) 'after': str(e, ['after']),
      });
    }
    return out;
  }

  List<Map<String, dynamic>> reminders(Object? v) {
    final out = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final e in list(v)) {
      if (e is! Map) continue;
      final label = str(e, ['label', 'title', 'text', 'what']);
      final t = time(e);
      if (label.isEmpty || t == null) {
        if (label.isNotEmpty) warn('Reminder "$label" has no time — left out.');
        continue;
      }
      final days = [for (final d in list(pick(e, ['weekdays', 'days']))) if (weekday(d) case final x?) x];
      out.add({
        'id': unique(str(e, ['id']).isEmpty ? slug(label) : slug(str(e, ['id'])), used),
        'label': label,
        'h': t.$1, 'm': t.$2,
        if (days.isNotEmpty) 'weekdays': days,
        if (pick(e, ['work_days_only', 'workDaysOnly']) == true) 'work_days_only': true,
        'route': route(e['route'], 'Reminder "$label"') ?? '/home',
        if (pick(e, ['default_on', 'on']) == false) 'default_on': false,
      });
    }
    return out;
  }

  Map<String, String> monthMap(Object? v, List<String> textKeys) {
    final out = <String, String>{};
    if (v is Map) {
      for (final e in v.entries) {
        final m = int.tryParse('${e.key}'.replaceAll(RegExp(r'\D'), ''));
        if (m != null && '${e.value}'.trim().isNotEmpty) out['$m'] = '${e.value}'.trim();
      }
    } else {
      for (final e in list(v)) {
        if (e is! Map) continue;
        final m = pick(e, ['month']);
        final text = str(e, textKeys);
        if (m is num && text.isNotEmpty) out['${m.toInt()}'] = text;
      }
    }
    return out;
  }

  Map<String, String> weekdayMap(Object? v) {
    final out = <String, String>{};
    if (v is Map) {
      for (final e in v.entries) {
        final d = weekday(e.key);
        if (d != null) out['$d'] = '${e.value}';
      }
    }
    return out;
  }

  Map<String, List<Map<String, dynamic>>> unlocks(Object? v) {
    final out = <String, List<Map<String, dynamic>>>{};
    void add(int month, Object? u) {
      if (u is! Map) return;
      final title = str(u, ['title', 'name']);
      if (title.isEmpty) return;
      final r = route(u['route'], 'Unlock "$title"');
      (out['$month'] ??= []).add({
        'kind': str(u, ['kind', 'type']).isEmpty ? 'milestone' : str(u, ['kind', 'type']),
        'title': title,
        'detail': str(u, ['detail', 'why', 'description']),
        if (r != null) 'route': r,
        if (str(u, ['done', 'done_key']).isNotEmpty) 'done': str(u, ['done', 'done_key']),
      });
    }
    if (v is Map) {
      for (final e in v.entries) {
        final m = int.tryParse('${e.key}'.replaceAll(RegExp(r'\D'), ''));
        if (m == null) continue;
        for (final u in list(e.value)) {
          add(m, u);
        }
      }
    } else {
      for (final u in list(v)) {
        if (u is Map && pick(u, ['month']) is num) add((u['month'] as num).toInt(), u);
      }
    }
    return out;
  }

  List<Map<String, dynamic>> milestones(Object? v) {
    final out = <Map<String, dynamic>>[];
    for (final e in list(v)) {
      if (e is! Map) continue;
      final m = pick(e, ['month']);
      final targets = [for (final t in list(pick(e, ['targets', 'goals', 'items']))) '$t'.trim()]
          .where((t) => t.isNotEmpty)
          .toList();
      if (m is num && targets.isNotEmpty) out.add({'month': m.toInt(), 'targets': targets});
    }
    return out;
  }

  List<Map<String, dynamic>> ritual(Object? v) {
    final out = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final e in list(v)) {
      final m = e is Map ? e : {'title': '$e'};
      final title = str(m, ['title', 'name', 'step']);
      if (title.isEmpty) continue;
      final secs = pick(m, ['seconds', 'duration_seconds']);
      final mins = pick(m, ['minutes']);
      out.add({
        'id': unique(str(m, ['id']).isEmpty ? slug(title) : str(m, ['id']), used),
        'title': title,
        'subtitle': str(m, ['subtitle', 'why']),
        'lane': lane(pick(m, ['lane', 'area'])),
        'seconds': secs is num ? secs.toInt() : (mins is num ? (mins * 60).toInt() : 60),
        'icon': str(m, ['icon']),
        'instruction': str(m, ['instruction', 'how', 'what']),
        if (m['optional'] == true) 'optional': true,
      });
    }
    return out;
  }

  static const _laneColors = {
    'mind': 0xFF8FA3C8, 'body': 0xFF86B49A, 'skill': 0xFF6FAFB3, 'social': 0xFFC49AC0,
  };

  List<Map<String, dynamic>> tips(Object? v) {
    final out = <Map<String, dynamic>>[];
    var i = 1;
    for (final e in list(v)) {
      final m = e is Map ? e : {'content': '$e'};
      final content = str(m, ['content', 'text', 'note', 'body']);
      if (content.isEmpty) continue;
      final l = lane(pick(m, ['lane', 'area']));
      out.add({
        'id': str(m, ['id']).isEmpty ? 'tip_d$i' : str(m, ['id']),
        'title': str(m, ['title', 'heading']),
        'content': content,
        'lane': l,
        'color': _laneColors[l],
      });
      i++;
    }
    return out;
  }

  List<Map<String, dynamic>> cards(Object? v) {
    final out = <Map<String, dynamic>>[];
    var i = 0;
    for (final e in list(v)) {
      if (e is! Map) continue;
      final front = str(e, ['front', 'question', 'q']);
      final back = str(e, ['back', 'answer', 'a']);
      if (front.isEmpty || back.isEmpty) continue;
      // Ids given are kept: review history is keyed by them.
      final id = str(e, ['id']);
      out.add({'id': id.isEmpty ? 'seed:plan:$i' : id, 'front': front, 'back': back, 'source': 'seed'});
      i++;
    }
    return out;
  }
}

/// What loading [next] over [current] would change, one line per part, in
/// words ("Daily items: 2 added (Walk, Read), 1 removed (Stretch)"). Empty
/// when nothing changes. What you logged is never touched either way.
List<String> planChanges(PlanContent current, PlanContent next) {
  final out = <String>[];
  String names(Iterable<String> xs) {
    final l = xs.toList();
    return l.length <= 3 ? l.join(', ') : '${l.take(3).join(', ')} and ${l.length - 3} more';
  }

  void byId<T>(String part, List<T> a, List<T> b, String Function(T) id, String Function(T) title,
      [Object? Function(T)? shape]) {
    final was = {for (final x in a) id(x): x};
    final now = {for (final x in b) id(x): x};
    final added = [for (final e in now.entries) if (!was.containsKey(e.key)) title(e.value)];
    final removed = [for (final e in was.entries) if (!now.containsKey(e.key)) title(e.value)];
    final changed = [
      for (final e in now.entries)
        if (was.containsKey(e.key) &&
            (title(was[e.key] as T) != title(e.value) ||
                (shape != null && '${shape(was[e.key] as T)}' != '${shape(e.value)}')))
          title(e.value)
    ];
    final bits = [
      if (added.isNotEmpty) '${added.length} added (${names(added)})',
      if (removed.isNotEmpty) '${removed.length} removed (${names(removed)})',
      if (changed.isNotEmpty) '${changed.length} changed (${names(changed)})',
    ];
    if (bits.isNotEmpty) out.add('$part: ${bits.join(', ')}');
  }

  final a = current.profile, b = next.profile;
  if (a?.name != b?.name) out.add('Name: ${a?.name ?? '—'} → ${b?.name ?? '—'}');
  if ((a?.targetRole ?? '') != (b?.targetRole ?? '')) {
    out.add('Becoming: ${a?.targetRole.isEmpty ?? true ? '—' : a!.targetRole} → ${b?.targetRole.isEmpty ?? true ? '—' : b!.targetRole}');
  }
  byId('Daily items', current.dailyItems, next.dailyItems, (x) => x.id, (x) => x.title,
      (x) => '${x.lane}|${x.when}');
  final cueChanged = [
    for (final n in next.dailyItems)
      if (current.dailyItems.any((o) => o.id == n.id) && (current.cues[n.id] ?? '') != (next.cues[n.id] ?? ''))
        n.title
  ];
  if (cueChanged.isNotEmpty) out.add('If-then plans: ${cueChanged.length} changed (${names(cueChanged)})');
  byId('Growth areas', current.growthAreas, next.growthAreas, (x) => x.id, (x) => x.name,
      (x) => x.drills.map((d) => d.title).join('|'));
  byId('Training days', current.gym, next.gym, (x) => x.id, (x) => x.name,
      (x) => x.exercises.map((e) => e.name).join('|'));
  byId('Reminders', current.reminders, next.reminders, (x) => x.id, (x) => x.label,
      (x) => '${x.hour}:${x.minute}');
  byId('Books', [...current.books, ...current.novels], [...next.books, ...next.novels], (x) => x.title, (x) => x.title);
  byId('Films', current.films, next.films, (x) => x.title, (x) => x.title);
  byId('Practices', current.protocols, next.protocols, (x) => x.id, (x) => x.name);
  byId('Cards to remember', current.seedCards, next.seedCards, (x) => x.id, (x) => x.front);
  if (current.schedule.length != next.schedule.length ||
      [for (var i = 0; i < next.schedule.length; i++) next.schedule[i].title].join() !=
          [for (var i = 0; i < current.schedule.length; i++) current.schedule[i].title].join()) {
    out.add('Your day: ${current.schedule.length} → ${next.schedule.length} blocks');
  }
  final themes = {...current.monthThemes.keys, ...next.monthThemes.keys}
      .where((m) => current.monthThemes[m] != next.monthThemes[m])
      .length;
  if (themes > 0) out.add('Month themes: $themes changed');
  final extraBits = [
    for (final k in next.extras.keys)
      if (!current.extras.containsKey(k)) 'added ${planSectionTitle(k)}'
      else if (jsonEncode(current.extras[k]) != jsonEncode(next.extras[k])) 'changed ${planSectionTitle(k)}',
    for (final k in current.extras.keys)
      if (!next.extras.containsKey(k)) 'removed ${planSectionTitle(k)}',
  ];
  if (extraBits.isNotEmpty) out.add('Other sections: ${extraBits.join(', ')}');
  return out;
}

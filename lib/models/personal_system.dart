// State for the personal operating system. Everything the app shows about
// Emin's progress is derived from this — no seeded or sample numbers.

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime weekStartOf(DateTime d) {
  final day = dayOnly(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// One thing that actually happened: a weigh-in, a gym session, a sigh
/// before a meeting, a Feynman note… `type` selects the meaning of `data`.
class LogEntry {
  final String id;
  final String type;
  final DateTime date; // the day it counts for
  final DateTime createdAt;
  final String text;
  final Map<String, dynamic> data;

  const LogEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.createdAt,
    this.text = '',
    this.data = const {},
  });

  num? number(String key) => data[key] as num?;
  String? str(String key) => data[key] as String?;

  LogEntry copyWith({
    String? id,
    String? type,
    DateTime? date,
    DateTime? createdAt,
    String? text,
    Map<String, dynamic>? data,
  }) =>
      LogEntry(
        id: id ?? this.id,
        type: type ?? this.type,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        text: text ?? this.text,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'date': dateKey(date),
        'created_at': createdAt.toIso8601String(),
        'text': text,
        'data': data,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        text: (json['text'] as String?) ?? '',
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      );
}

class EvidenceItem {
  final String id;
  final String section; // built | solved | knowledge
  final String text;
  final DateTime createdAt;

  const EvidenceItem({
    required this.id,
    required this.section,
    required this.text,
    required this.createdAt,
  });

  EvidenceItem copyWith({
    String? id,
    String? section,
    String? text,
    DateTime? createdAt,
  }) =>
      EvidenceItem(
        id: id ?? this.id,
        section: section ?? this.section,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };

  factory EvidenceItem.fromJson(Map<String, dynamic> json) => EvidenceItem(
        id: json['id'] as String,
        section: json['section'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class WeeklyReport {
  final String id;
  final DateTime weekStart;
  final double nonNegotiableAverage;
  final int gymSessions;
  final String bestMoment;
  final String hardestMoment;
  final String workSituation;
  final DateTime createdAt;

  const WeeklyReport({
    required this.id,
    required this.weekStart,
    required this.nonNegotiableAverage,
    required this.gymSessions,
    required this.bestMoment,
    required this.hardestMoment,
    required this.workSituation,
    required this.createdAt,
  });

  WeeklyReport copyWith({
    String? id,
    DateTime? weekStart,
    double? nonNegotiableAverage,
    int? gymSessions,
    String? bestMoment,
    String? hardestMoment,
    String? workSituation,
    DateTime? createdAt,
  }) =>
      WeeklyReport(
        id: id ?? this.id,
        weekStart: weekStart ?? this.weekStart,
        nonNegotiableAverage:
            nonNegotiableAverage ?? this.nonNegotiableAverage,
        gymSessions: gymSessions ?? this.gymSessions,
        bestMoment: bestMoment ?? this.bestMoment,
        hardestMoment: hardestMoment ?? this.hardestMoment,
        workSituation: workSituation ?? this.workSituation,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Plain-text version to paste into any coaching conversation.
  String toCoachingMessage() => '''Weekly report — week of ${dateKey(weekStart)}
1. Non-negotiables: ${nonNegotiableAverage.toStringAsFixed(1)}/10 average per day
2. Gym sessions: $gymSessions/3
3. Best moment: $bestMoment
4. Hardest moment: $hardestMoment
5. Work situation to coach through: $workSituation''';

  Map<String, dynamic> toJson() => {
        'id': id,
        'week_start': weekStart.toIso8601String(),
        'non_negotiable_average': nonNegotiableAverage,
        'gym_sessions': gymSessions,
        'best_moment': bestMoment,
        'hardest_moment': hardestMoment,
        'work_situation': workSituation,
        'created_at': createdAt.toIso8601String(),
      };

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
        id: json['id'] as String,
        weekStart: DateTime.parse(json['week_start'] as String),
        nonNegotiableAverage:
            (json['non_negotiable_average'] as num).toDouble(),
        gymSessions: json['gym_sessions'] as int,
        bestMoment: json['best_moment'] as String,
        hardestMoment: json['hardest_moment'] as String,
        workSituation: json['work_situation'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// The coach's answer to a Sunday report: plan for the coming week.
class WeeklyBrief {
  final String id;
  final DateTime weekStart; // the week this brief is FOR
  final DateTime createdAt;
  final String source; // 'ai' (Claude) | 'device' (rule-based, offline)
  final String headline;
  final List<String> tasks;
  final String domainBrief;
  final String coaching;
  final List<String> adjustments;

  const WeeklyBrief({
    required this.id,
    required this.weekStart,
    required this.createdAt,
    required this.source,
    required this.headline,
    required this.tasks,
    required this.domainBrief,
    required this.coaching,
    required this.adjustments,
  });

  WeeklyBrief copyWith({
    String? id,
    DateTime? weekStart,
    DateTime? createdAt,
    String? source,
    String? headline,
    List<String>? tasks,
    String? domainBrief,
    String? coaching,
    List<String>? adjustments,
  }) =>
      WeeklyBrief(
        id: id ?? this.id,
        weekStart: weekStart ?? this.weekStart,
        createdAt: createdAt ?? this.createdAt,
        source: source ?? this.source,
        headline: headline ?? this.headline,
        tasks: tasks ?? this.tasks,
        domainBrief: domainBrief ?? this.domainBrief,
        coaching: coaching ?? this.coaching,
        adjustments: adjustments ?? this.adjustments,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'week_start': dateKey(weekStart),
        'created_at': createdAt.toIso8601String(),
        'source': source,
        'headline': headline,
        'tasks': tasks,
        'domain_brief': domainBrief,
        'coaching': coaching,
        'adjustments': adjustments,
      };

  factory WeeklyBrief.fromJson(Map<String, dynamic> json) => WeeklyBrief(
        id: json['id'] as String,
        weekStart: DateTime.parse(json['week_start'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        source: json['source'] as String,
        headline: json['headline'] as String,
        tasks: List<String>.from(json['tasks'] as List),
        domainBrief: json['domain_brief'] as String,
        coaching: json['coaching'] as String,
        adjustments: List<String>.from(json['adjustments'] as List),
      );
}

class PersonalSystemState {
  final DateTime programStart;

  /// False until the Commission onboarding is completed.
  final bool commissioned;
  final DateTime? manifestoSignedAt;

  /// Weekdays (DateTime.monday…) for gym days A, B, C.
  final List<int> gymDays;

  /// Reminder id → enabled. Missing ids default to enabled.
  final Map<String, bool> reminders;

  /// dateKey → ids checked that day (Daily 10 ids, 'gym', supplements…).
  final Map<String, List<String>> dailyChecks;

  /// dateKey → the 3 morning priorities.
  final Map<String, List<String>> priorities;

  /// One-off checklist keys (e.g. 'wardrobe:w1', 'ms_1_0', 'brief:<id>:2').
  final Set<String> done;

  final List<EvidenceItem> evidence;
  final List<WeeklyReport> reports;
  final List<WeeklyBrief> briefs;
  final List<LogEntry> logs;

  /// Daily 10 id → the user's own if-then cue (overrides `defaultCues`).
  final Map<String, String> cues;

  const PersonalSystemState({
    required this.programStart,
    this.commissioned = false,
    this.manifestoSignedAt,
    this.gymDays = const [DateTime.monday, DateTime.wednesday, DateTime.thursday],
    this.reminders = const {},
    this.dailyChecks = const {},
    this.priorities = const {},
    this.done = const {},
    this.evidence = const [],
    this.reports = const [],
    this.briefs = const [],
    this.logs = const [],
    this.cues = const {},
  });

  PersonalSystemState copyWith({
    DateTime? programStart,
    bool? commissioned,
    DateTime? manifestoSignedAt,
    List<int>? gymDays,
    Map<String, bool>? reminders,
    Map<String, List<String>>? dailyChecks,
    Map<String, List<String>>? priorities,
    Set<String>? done,
    List<EvidenceItem>? evidence,
    List<WeeklyReport>? reports,
    List<WeeklyBrief>? briefs,
    List<LogEntry>? logs,
    Map<String, String>? cues,
  }) =>
      PersonalSystemState(
        programStart: programStart ?? this.programStart,
        commissioned: commissioned ?? this.commissioned,
        manifestoSignedAt: manifestoSignedAt ?? this.manifestoSignedAt,
        gymDays: gymDays ?? this.gymDays,
        reminders: reminders ?? this.reminders,
        dailyChecks: dailyChecks ?? this.dailyChecks,
        priorities: priorities ?? this.priorities,
        done: done ?? this.done,
        evidence: evidence ?? this.evidence,
        reports: reports ?? this.reports,
        briefs: briefs ?? this.briefs,
        logs: logs ?? this.logs,
        cues: cues ?? this.cues,
      );

  Map<String, dynamic> toJson() => {
        'version': 2,
        'program_start': programStart.toIso8601String(),
        'commissioned': commissioned,
        'manifesto_signed_at': manifestoSignedAt?.toIso8601String(),
        'gym_days': gymDays,
        'reminders': reminders,
        'daily_checks': dailyChecks,
        'priorities': priorities,
        'done': done.toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'reports': reports.map((r) => r.toJson()).toList(),
        'briefs': briefs.map((b) => b.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'cues': cues,
      };

  factory PersonalSystemState.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> stringListMap(Object? raw) =>
        (raw as Map<String, dynamic>? ?? {}).map((k, v) =>
            MapEntry(k, (v as List).map((e) => e as String).toList()));

    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
        ((raw as List?) ?? [])
            .map((e) => f(Map<String, dynamic>.from(e as Map)))
            .toList();

    final signed = json['manifesto_signed_at'] as String?;
    return PersonalSystemState(
      programStart: DateTime.parse(json['program_start'] as String),
      // States saved before onboarding existed were real users of the
      // program, so treat them as commissioned.
      commissioned: (json['commissioned'] as bool?) ?? true,
      manifestoSignedAt: signed == null ? null : DateTime.parse(signed),
      gymDays: ((json['gym_days'] as List?) ??
              const [DateTime.monday, DateTime.wednesday, DateTime.thursday])
          .map((e) => e as int)
          .toList(),
      reminders: (json['reminders'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as bool)),
      dailyChecks: stringListMap(json['daily_checks']),
      priorities: stringListMap(json['priorities']),
      done: ((json['done'] as List?) ?? []).map((e) => e as String).toSet(),
      evidence: list(json['evidence'], EvidenceItem.fromJson),
      reports: list(json['reports'], WeeklyReport.fromJson),
      briefs: list(json['briefs'], WeeklyBrief.fromJson),
      logs: list(json['logs'], LogEntry.fromJson),
      cues: (json['cues'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
    );
  }
}

// State for the personal operating system (Today / Plan / Playbook tabs):
// daily non-negotiable check-offs, morning priorities, evidence archive,
// weekly coaching reports and generic "done" checklists (wardrobe,
// milestones, certificates, bloodwork, LinkedIn).

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime weekStartOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
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

  /// Plain-text version to paste into a coaching conversation.
  String toCoachingMessage() => '''Weekly report — week of ${dateKey(weekStart)}
1. Non-negotiables: ${nonNegotiableAverage.toStringAsFixed(1)}/10 average per day
2. Gym sessions: $gymSessions/3
3. Best moment: $bestMoment
4. Hardest moment: $hardestMoment
5. Work situation to coach through: $workSituation

Please respond with: next week's specific tasks, a domain brief, coaching on the work situation, and any plan adjustments.''';

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

class PersonalSystemState {
  final DateTime programStart;

  /// dateKey → ids checked that day (non-negotiable ids, plus 'gym').
  final Map<String, List<String>> dailyChecks;

  /// dateKey → the 3 morning priorities.
  final Map<String, List<String>> priorities;

  /// Generic one-off checklist keys (e.g. 'wardrobe:w1', 'ms_1_0').
  final Set<String> done;

  final List<EvidenceItem> evidence;
  final List<WeeklyReport> reports;

  const PersonalSystemState({
    required this.programStart,
    this.dailyChecks = const {},
    this.priorities = const {},
    this.done = const {},
    this.evidence = const [],
    this.reports = const [],
  });

  PersonalSystemState copyWith({
    DateTime? programStart,
    Map<String, List<String>>? dailyChecks,
    Map<String, List<String>>? priorities,
    Set<String>? done,
    List<EvidenceItem>? evidence,
    List<WeeklyReport>? reports,
  }) =>
      PersonalSystemState(
        programStart: programStart ?? this.programStart,
        dailyChecks: dailyChecks ?? this.dailyChecks,
        priorities: priorities ?? this.priorities,
        done: done ?? this.done,
        evidence: evidence ?? this.evidence,
        reports: reports ?? this.reports,
      );

  Map<String, dynamic> toJson() => {
        'program_start': programStart.toIso8601String(),
        'daily_checks': dailyChecks,
        'priorities': priorities,
        'done': done.toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'reports': reports.map((r) => r.toJson()).toList(),
      };

  factory PersonalSystemState.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> stringListMap(Object? raw) =>
        (raw as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as List).map((e) => e as String).toList()));

    return PersonalSystemState(
      programStart: DateTime.parse(json['program_start'] as String),
      dailyChecks: stringListMap(json['daily_checks']),
      priorities: stringListMap(json['priorities']),
      done: ((json['done'] as List?) ?? []).map((e) => e as String).toSet(),
      evidence: ((json['evidence'] as List?) ?? [])
          .map((e) => EvidenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      reports: ((json['reports'] as List?) ?? [])
          .map((e) => WeeklyReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

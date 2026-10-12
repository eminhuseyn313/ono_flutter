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

  /// From morning check-ins this week (null when none were logged).
  final double? avgEnergy;
  final double? avgSleep;
  final int shoulderFlagDays;

  /// Target-role dimension furthest below the bar, if rated.
  final String? readinessGap;
  final int openFollowUps;

  /// "Habit → outcome X vs Y without" from his own logs, strongest first.
  final List<String> patterns;

  /// Logged focus blocks and evening shutdowns this week.
  final double deepWorkHours;
  final int shutdowns;

  /// This week's Big 3, each prefixed "[done]" or "[open]".
  final List<String> weekOutcomes;

  /// People past their contact cadence, most overdue first.
  final List<String> peopleOverdue;

  /// This month's growth area, next week's drill, practice and feedback.
  final String? growthFocus;
  final String? growthDrill;
  final int repsThisWeek;
  final int feedbackThisMonth;

  /// The value the week reflected least (rated below 4), if checked.
  final String? valueGap;

  /// Self-coaching commitments past their date and not yet kept.
  final List<String> openCommitments;

  /// Active goals: progress vs time used, pace, obstacle and plan.
  final List<String> goals;

  /// Whether this week's progress note went to someone.
  final bool noteSent;

  /// Setbacks met with the protocol this week.
  final int setbacks;

  /// Counts only: kind acts logged and thoughts checked this week.
  final int kindnessActs;
  final int thoughtsChecked;

  /// Signature strengths, uses of them this week, and roles nobody fills
  /// on their personal board.
  final List<String> strengths;
  final int strengthUses;
  final List<String> boardGaps;

  /// Whether rest is planned (or running) within the next 8 weeks.
  final bool restPlanned;

  /// Personal experiments: change, status, measure before → during.
  final List<String> experiments;

  /// Recently applied learning: the principle and the experiment or result.
  final List<String> learningApplied;

  /// The lowest area on the latest quarterly life wheel, e.g. "Money (4/10)".
  final String? lowestLifeArea;

  /// Daily item id → its title (covers items the person added).
  final Map<String, String> itemTitles;

  /// How many daily items there are (the Daily 10 may have 8 or 12).
  final int itemCount;

  /// When their energy peaks, e.g. "morning (9:00–12:00)", from their own
  /// ratings.
  final String? energyPeak;

  /// The theme from their latest quarterly feedback round.
  final String? feedbackThemes;

  /// Hard days this week by kind: minimum days, sick days, emergency skips.
  final Map<String, int> hardDays;

  /// The accountability pact over the last 4 check-ins, e.g. "with Sam:
  /// you kept it 3 of 4 weeks, they 2".
  final String? partner;

  /// The life they lean towards in their Odyssey plan, and the crafting
  /// move from their latest energy audit.
  final String? direction;
  final String? craftingMove;

  /// Moderate-equivalent minutes moved and strength days this week.
  final int? moveMinutes;
  final int strengthDays;

  /// Whether the built-in plan (its gym plan, monthly artifact, posts and
  /// reading list) applies; false for anyone with a plan of their own.
  final bool builtInPlan;

  /// People they're helping grow: "Sam: delegating (2 helps this month)".
  final List<String> growingOthers;

  /// The latest money check-in: savings rate and buffer, no amounts.
  final String? money;

  /// Who the brief is for: names, roles, key people and coach context.
  final Profile profile;

  BriefInput({
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
    this.avgEnergy,
    this.avgSleep,
    this.shoulderFlagDays = 0,
    this.readinessGap,
    this.openFollowUps = 0,
    this.patterns = const [],
    this.deepWorkHours = 0,
    this.shutdowns = 0,
    this.weekOutcomes = const [],
    this.peopleOverdue = const [],
    this.growthFocus,
    this.growthDrill,
    this.repsThisWeek = 0,
    this.feedbackThisMonth = 0,
    this.valueGap,
    this.openCommitments = const [],
    Profile? profile,
    this.goals = const [],
    this.noteSent = false,
    this.setbacks = 0,
    this.kindnessActs = 0,
    this.thoughtsChecked = 0,
    this.strengths = const [],
    this.strengthUses = 0,
    this.boardGaps = const [],
    this.lowestLifeArea,
    this.learningApplied = const [],
    this.experiments = const [],
    this.restPlanned = true,
    this.itemTitles = const {},
    this.itemCount = 10,
    this.energyPeak,
    this.feedbackThemes,
    this.hardDays = const {},
    this.partner,
    this.direction,
    this.craftingMove,
    this.moveMinutes,
    this.strengthDays = 0,
    this.builtInPlan = true,
    this.growingOthers = const [],
    this.money,
  }) : profile = profile ?? activeProfile;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'goals': goals,
        'progress_note_sent': noteSent,
        'setbacks_handled': setbacks,
        'kindness_acts_this_week': kindnessActs,
        'thoughts_checked_this_week': thoughtsChecked,
        if (strengths.isNotEmpty) 'signature_strengths': strengths,
        if (strengths.isNotEmpty) 'strength_uses_this_week': strengthUses,
        if (boardGaps.isNotEmpty) 'personal_board_gaps': boardGaps,
        'lowest_life_area': lowestLifeArea,
        'learning_applied': learningApplied,
        'experiments': experiments,
        'rest_planned_next_8_weeks': restPlanned,
        'energy_peak': energyPeak,
        'hard_days': hardDays,
        'accountability_partner': partner,
        'five_year_direction': direction,
        'crafting_move': craftingMove,
        'people_they_are_growing': growingOthers,
        'money': money,
        'move_minutes_moderate_equivalent': moveMinutes,
        'strength_days': strengthDays,
        'feedback_round_theme': feedbackThemes,
        'report': report.toJson(),
        'for_week': dateKey(forWeek),
        'program_month': programMonth,
        'program_week': programWeek,
        'phase': phaseFor(programMonth).name,
        if (builtInPlan) ...{
          'month_theme': monthThemes[programMonth],
          'artifact_of_month': artifactFor(programMonth),
          'book_of_month': currentBook(programMonth).title,
        },
        'item_rates': itemRates,
        'item_titles': itemTitles,
        'daily_item_count': itemCount,
        'evidence_added_this_week': evidenceAddedThisWeek,
        'artifacts_this_month': artifactsThisMonth,
        'posts_this_week': postsThisWeek,
        'gym_days': gymDays,
        'open_unlocks': openUnlocks,
        'latest_weight_kg': latestWeight,
        'avg_energy_1_to_5': avgEnergy,
        'avg_sleep_hours': avgSleep,
        'shoulder_flag_mornings': shoulderFlagDays,
        'readiness_gap': readinessGap,
        'open_one_on_one_followups': openFollowUps,
        'personal_patterns': patterns,
        'deep_work_hours': deepWorkHours,
        'evening_shutdowns': shutdowns,
        'week_outcomes': weekOutcomes,
        'people_overdue': peopleOverdue,
        'growth_focus': growthFocus,
        'next_drill': growthDrill,
        'practice_reps_this_week': repsThisWeek,
        'feedback_this_month': feedbackThisMonth,
        'value_least_lived': valueGap,
        'open_commitments': openCommitments,
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
    'sigh': 'Sigh ×3 before you walk into work, and before every high-stakes conversation.',
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
    String title(String id) => _titleFor[id] ?? input.itemTitles[id] ?? id;
    final ratio = input.itemCount == 0 ? 0.0 : avg / input.itemCount;
    final strongest = rates.isEmpty ? null : rates.last.key;

    final headline = ratio >= 0.8
        ? 'Strong week (${avg.toStringAsFixed(1)}/${input.itemCount}). Hold the line and raise one bar.'
        : ratio >= 0.6
            ? 'Solid week (${avg.toStringAsFixed(1)}/${input.itemCount}). Tighten ${title(weakest.first)} and ${title(weakest.last)}.'
            : 'Reset week (${avg.toStringAsFixed(1)}/${input.itemCount}). Fewer, firmer commitments.';

    final tasks = <String>[
      for (final id in weakest)
        _taskFor[id] ??
            'Protect "${title(id)}": tie it to one fixed moment in your day, and make it smaller if it keeps slipping.',
    ];
    if (input.builtInPlan && r.gymSessions < 3 && input.gymDays.length >= 3) {
      final names = [
        for (var i = 0; i < 3; i++)
          '${_dayName(input.gymDays[i])} ${gymPlan[i].name}'
      ].join(' / ');
      tasks.add('Three sessions at 19:00: $names. Face pulls every time.');
    }
    if (input.openUnlocks.isNotEmpty) {
      tasks.add('This month\'s open item: ${input.openUnlocks.first}.');
    }
    if (input.builtInPlan && input.artifactsThisMonth == 0) {
      tasks.add(
          'Block 2 × 45 min for the artifact of the month: ${artifactFor(input.programMonth)}.');
    }
    if (input.builtInPlan && input.programMonth >= 2 && input.postsThisWeek < 2) {
      tasks.add('Publish 2 LinkedIn posts (Tue + Thu). Hook → insight → example → question.');
    }
    if (r.workSituation.trim().isNotEmpty) {
      tasks.add(input.builtInPlan
          ? 'Before the meeting about this situation: six-questions-deep prep.'
          : 'Before the conversation about this situation: prepare it in Hard conversations — what you want, the facts, your first sentence.');
    }

    // Domain brief: next week's rotation + one fact to own.
    final fact = keyData[input.programWeek % keyData.length];
    final rotation = domainScanRotation
        .where((d) => d.weekday <= DateTime.friday)
        .map((d) => '${_dayName(d.weekday).substring(0, 3)} ${d.title}')
        .join(' · ');
    final domainBrief = input.builtInPlan
        ? 'Scan rotation: $rotation.\n\n'
            'Fact to own this week — ${fact[0]}: ${fact[1]}.\n'
            'Write one sentence connecting it to ${input.profile.focus} and use it in a meeting.'
        : input.growthFocus == null
            ? 'Choose one area to grow this month, and practise it twice next week on real situations.'
            : 'This week\'s practice: ${input.growthFocus}${input.growthDrill == null ? '' : ' — ${input.growthDrill}'}. Do it twice, write what you noticed, and ask one person what they saw.';

    final situation = r.workSituation.trim();
    final coaching = !input.builtInPlan
        ? situation.isEmpty
            ? 'No situation reported. Pick the moment next week you most want to go well — at work or at home — and decide your first sentence now.'
            : 'Situation: "${_clip(situation, 160)}"\n\n'
                '1. Decide what you really want — for you, for them, and for the relationship.\n'
                '2. Separate the facts (what a camera would record) from the story you\'re telling yourself; imagine their story.\n'
                '3. Write your first sentence: describe the gap and invite their view. Then one concrete ask.\n'
                '4. Before it, three slow breaths. Afterwards, write what you learned.'
        : situation.isEmpty
        ? 'No work situation reported. Pick the meeting you most want to go well next week and run six-questions-deep on it.'
        : 'Situation: "${_clip(situation, 160)}"\n\n'
            '1. Decide your position and write it as BLUF: the decision first, three reasons, what you need, by when.\n'
            '2. Six questions deep: the six hardest questions ${input.profile.manager.isEmpty ? 'they' : input.profile.manager} could ask about this, your answer to each, and the hardest follow-up.\n'
            '3. In the room: sigh ×3 beforehand, say "I am excited", still body, one breath before every answer, downward inflection.\n'
            '4. Afterwards: log what held and what didn\'t; if it went well, it goes in the Evidence Archive.';

    final behind = input.goals.where((g) => g.contains('(behind)')).toList();
    final adjustments = <String>[
      if (input.growthFocus == null)
        'No growth area this month. Pick one in the Growth plan — the gap you most want closed — and practise it on real work.',
      if (input.growthFocus != null && input.repsThisWeek < 2)
        'Growth — ${input.growthFocus}: ${input.repsThisWeek} rep${input.repsThisWeek == 1 ? '' : 's'} this week. Next week\'s drill: ${input.growthDrill}. Do it twice and write what you noticed.',
      if (input.growthFocus != null && input.feedbackThisMonth == 0)
        'No feedback on ${input.growthFocus} yet this month. Ask one person one specific question — practice without feedback doesn\'t improve.',
      if (ratio < 0.6)
        input.builtInPlan
            ? 'Shrink to the core five next week: manifesto, scan, BLUF, protein, bed. Add the rest back when you hold 5/5.'
            : 'Shrink the list next week: keep the three items that matter most, use their minimum versions on hard days, and add the rest back once those hold.',
      if (input.builtInPlan && r.gymSessions < 2)
        'If a weekday slips, move the session to Saturday morning rather than skipping it.',
      if (input.builtInPlan && input.evidenceAddedThisWeek < 5)
        'Evidence Archive: add ${5 - input.evidenceAddedThisWeek} more items tonight — the impostor feeds on forgetting.',
      if (r.hardestMoment.trim().isNotEmpty)
        'Hardest moment noted. Ask: what would ${input.profile.archetype.isEmpty ? 'the person you\'re becoming' : input.profile.archetype} do differently? Write the answer as one rule.',
      if (input.readinessGap != null)
        '${input.profile.targetRole} gap: ${input.readinessGap}. Pick one thing this week that shows it, and log it as evidence.',
      if (input.openFollowUps >= 3)
        '${input.openFollowUps} open 1:1 follow-ups. Close or hand off the oldest before your next 1:1${input.profile.manager.isEmpty ? '' : ' with ${input.profile.manager}'}.',
      if (input.shoulderFlagDays >= 3)
        'Shoulders flagged on ${input.shoulderFlagDays} mornings. Keep the shoulder-sparing sessions and bring the check-in log to your rheumatologist.',
      if (input.avgSleep != null && input.avgSleep! < 7)
        'Average sleep ${input.avgSleep!.toStringAsFixed(1)} h. Protect ${input.builtInPlan ? '22:30' : 'a fixed bedtime'} before adding anything else — sleep sets tomorrow\'s mind.',
      if ((input.hardDays['sick'] ?? 0) >= 2)
        'You were sick ${input.hardDays['sick']} days. Come back with the minimum version of each item for two days before the full plan — and if it isn\'t getting better, see a doctor.'
      else if ((input.hardDays['pass'] ?? 0) + (input.hardDays['minimum'] ?? 0) >= 3)
        '${(input.hardDays['pass'] ?? 0) + (input.hardDays['minimum'] ?? 0)} hard days this week. Look at what kept happening — if it will happen again, change the plan, not your opinion of yourself.',
      if (input.goals.isEmpty)
        'No goals set. Name the one outcome that would make the next six months a success — and the obstacle most likely to stop you.',
      if (behind.isNotEmpty)
        'Behind on ${behind.first.split(':').first}. Read your if-then plan again and make next week\'s Big 3 move it.',
      if (!input.restPlanned)
        'No rest planned in the next eight weeks. Put one full rest day — or a lighter week — in the plan now, before the calendar decides for you.',
      if (input.goals.isNotEmpty && !input.noteSent)
        'No progress note went out this week. Friday: five lines to ${input.profile.manager.isEmpty ? 'one person you trust' : input.profile.manager} — reported progress moves goals faster than private tracking.',
      if (input.setbacks > 0)
        '${input.setbacks} setback${input.setbacks == 1 ? '' : 's'} met with a next step instead of a spiral. That is the skill.',
      if (input.boardGaps.contains('sponsor'))
        'Nobody on your board speaks for you where you are not. Who could become a sponsor? Ask them for one thing this month.',
      if (input.strengths.isNotEmpty && input.strengthUses == 0)
        'Use ${input.strengths.first.toLowerCase()} in a new way this week — once a day if you can.',
      if (input.thoughtsChecked > 0)
        'You put ${input.thoughtsChecked} hard thought${input.thoughtsChecked == 1 ? '' : 's'} to the test this week instead of believing ${input.thoughtsChecked == 1 ? 'it' : 'them'}.',
      if (input.kindnessActs >= 5)
        '${input.kindnessActs} kind acts this week — they count for you too.',
      if (input.valueGap != null)
        'This week reflected ${input.valueGap} least. Name one moment next week where you\'ll choose it on purpose.',
      if (input.openCommitments.isNotEmpty)
        'You committed to: "${input.openCommitments.first}". Keep it, renegotiate it with yourself, or drop it on purpose — don\'t let it linger.',
      if (input.weekOutcomes.isEmpty)
        'No Big 3 for the week. Sunday night: three outcomes that would make next week a win, ${input.builtInPlan ? 'one tied to the artifact' : 'one tied to your goal'}.',
      if (input.weekOutcomes.any((o) => o.startsWith('[open]')))
        'Week outcomes: ${input.weekOutcomes.where((o) => o.startsWith('[done]')).length} of ${input.weekOutcomes.length} done. Carry the open one only if it still matters — otherwise drop it on purpose.',
      if (input.peopleOverdue.isNotEmpty)
        'Overdue to reach out: ${input.peopleOverdue.join(', ')}. One message each this week — a useful link or a question beats "catching up".',
      if (input.deepWorkHours < 3)
        'Deep work: ${input.deepWorkHours.toStringAsFixed(1)} h this week. Book two 90-minute blocks for ${input.builtInPlan ? 'the artifact' : 'what matters most'}${input.energyPeak == null ? '' : ' in your ${input.energyPeak}'} before Monday fills up.',
      if (input.moveMinutes != null && input.moveMinutes! < 150)
        'Moved ${input.moveMinutes} of 150 minutes this week. Add a 20-minute walk after lunch on three days — that alone closes most of the gap.',
      if (input.growingOthers.any((g) => g.contains('(0 helps')))
        'You\'re helping ${input.growingOthers.firstWhere((g) => g.contains('(0 helps')).split(':').first} grow, but haven\'t this month. One question or one piece of feedback this week is enough.',
      if (input.craftingMove != null)
        'Your crafting move: ${input.craftingMove}. Put it on next week\'s calendar once — small changes to the work are how it starts to fit you.',
      if (input.feedbackThemes != null)
        'What others told you: "${input.feedbackThemes}". Pick one moment next week to act on it where they can see it.',
      if (input.shutdowns < 4)
        'Evening shutdown on ${input.shutdowns} of 7 nights. Three minutes ${input.builtInPlan ? 'at 21:30' : 'before bed'}: tomorrow\'s three on paper, head empty, then bed.',
      if (input.patterns.isNotEmpty)
        'From your own last 60 days: ${input.patterns.first}. A pattern, not proof — but worth protecting this week.',
      if (strongest != null && (input.itemRates[strongest] ?? 0) >= 0.85)
        '${title(strongest)} is becoming automatic — keep it, stop thinking about it.',
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

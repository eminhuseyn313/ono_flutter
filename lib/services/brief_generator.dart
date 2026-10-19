import '../data/emin_system.dart';
import '../models/personal_system.dart';

/// Everything a coach needs to answer a Sunday report.
class BriefInput {
  final WeeklyReport report;
  final DateTime forWeek;
  final int programMonth;

  /// The current phase's name (phases scale with the program's length).
  final String? phaseName;
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

  /// Minutes between the week's earliest and latest wake (Apple Health).
  final int? wakeSpread;
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

  /// Deciders who saw your work in 90 days: (saw, deciders).
  final (int, int) decidersSeen;

  /// This month's reps with a feedback source noted: (none, noted).
  final (int, int) repsWithoutFeedback;
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

  /// Rungs of the courage ladder taken this week (a count).
  final int courageSteps;

  /// Where the load comes from when two months running felt heavy; null
  /// otherwise.
  final List<String>? heavyLoad;

  /// A big life change in the last 90 days ("A new job or role, 12 days
  /// ago"); null otherwise.
  final String? lifeChange;

  /// Signature strengths, uses of them this week, and roles nobody fills
  /// on their personal board.
  final List<String> strengths;
  final int strengthUses;
  final List<String> boardGaps;

  /// Promises kept of those closed in 90 days ("9 of 10"), and open
  /// promises past their date.
  final String? sayDo;
  final int promisesOverdue;

  /// Times they asked for help this week, and their record over six
  /// months ("7 of 9 said yes; you expected 45%").
  final int asksThisWeek;

  /// Outcomes proposed for next week's Big 3 (goal's next step, the drill,
  /// what feedback said) — the brief leads with them.
  final List<String> proposedOutcomes;
  final String? askRecord;

  /// The one word chosen for this year in last year's review.
  final String? wordForTheYear;

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

  /// What last month's review said to carry, and the quarter's focus, in
  /// their words.
  final String? monthCarry;
  final String? quarterFocus;

  /// Wins logged this week (text stays on the device; only the count is
  /// sent to the coach).
  final List<String> wins;

  /// People on their list they were in touch with this week, of how many.
  final int peopleReached;
  final int peopleCount;

  /// Daily item id → their own if-then plan for it, when they wrote one.
  final Map<String, String> itemCues;

  /// Days of the reported week that were inside the program (a first
  /// week that started midweek has fewer than 7).
  final int daysCounted;

  /// When their energy peaks, e.g. "morning (9:00–12:00)", from their own
  /// ratings.
  final String? energyPeak;

  /// The theme from their latest quarterly feedback round.
  final String? feedbackThemes;

  /// Hard days this week by kind: minimum days, sick days, emergency skips.
  final Map<String, int> hardDays;

  /// Days this week that were sick, skipped, rest or paused: left out of
  /// the average, and a reason for a gentler verdict.
  final int excusedDays;

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
    this.phaseName,
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
    this.wakeSpread,
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
    this.repsWithoutFeedback = (0, 0),
    this.decidersSeen = (0, 0),
    this.feedbackThisMonth = 0,
    this.valueGap,
    this.openCommitments = const [],
    Profile? profile,
    this.goals = const [],
    this.noteSent = false,
    this.setbacks = 0,
    this.kindnessActs = 0,
    this.thoughtsChecked = 0,
    this.courageSteps = 0,
    this.heavyLoad,
    this.lifeChange,
    this.strengths = const [],
    this.strengthUses = 0,
    this.boardGaps = const [],
    this.sayDo,
    this.promisesOverdue = 0,
    this.asksThisWeek = 0,
    this.proposedOutcomes = const [],
    this.askRecord,
    this.wordForTheYear,
    this.lowestLifeArea,
    this.learningApplied = const [],
    this.experiments = const [],
    this.restPlanned = true,
    this.itemTitles = const {},
    this.itemCount = 10,
    this.itemCues = const {},
    this.wins = const [],
    this.monthCarry,
    this.quarterFocus,
    this.peopleReached = 0,
    this.peopleCount = 0,
    this.daysCounted = 7,
    this.energyPeak,
    this.feedbackThemes,
    this.hardDays = const {},
    this.excusedDays = 0,
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
        // Which plan this is: the built-in one (training, posts, artifact,
        // readiness) or someone's own.
        'built_in_plan': builtInPlan,
        'progress_note_sent': noteSent,
        'setbacks_handled': setbacks,
        'kindness_acts_this_week': kindnessActs,
        'thoughts_checked_this_week': thoughtsChecked,
        if (courageSteps > 0) 'courage_steps_this_week': courageSteps,
        if (heavyLoad != null) 'heavy_load_two_months': heavyLoad,
        if (lifeChange != null) 'life_change': lifeChange,
        if (strengths.isNotEmpty) 'signature_strengths': strengths,
        if (strengths.isNotEmpty) 'strength_uses_this_week': strengthUses,
        if (boardGaps.isNotEmpty) 'personal_board_gaps': boardGaps,
        if (sayDo != null) 'promises_kept_90_days': sayDo,
        if (promisesOverdue > 0) 'promises_overdue': promisesOverdue,
        'asks_for_help_this_week': asksThisWeek,
        if (proposedOutcomes.isNotEmpty) 'proposed_big_3': proposedOutcomes,
        if (askRecord != null) 'asks_for_help_180_days': askRecord,
        if (wordForTheYear != null) 'word_for_the_year': wordForTheYear,
        'lowest_life_area': lowestLifeArea,
        'learning_applied': learningApplied,
        'experiments': experiments,
        'rest_planned_next_8_weeks': restPlanned,
        'energy_peak': energyPeak,
        'hard_days': hardDays,
        'excused_days_this_week': excusedDays,
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
        'phase': phaseName ?? phaseFor(programMonth).name,
        if (builtInPlan) ...{
          'evidence_added_this_week': evidenceAddedThisWeek,
          'artifacts_this_month': artifactsThisMonth,
          'posts_this_week': postsThisWeek,
          'gym_days': gymDays,
          'open_unlocks': openUnlocks,
          'shoulder_flag_mornings': shoulderFlagDays,
          'readiness_gap': readinessGap,
          'month_theme': monthThemes[programMonth],
          'artifact_of_month': artifactFor(programMonth),
          if (scheduledBook(programMonth) case final b?) 'book_of_month': b.title,
        },
        'item_rates': itemRates,
        'item_titles': itemTitles,
        'daily_item_count': itemCount,
        if (itemCues.isNotEmpty) 'item_if_then_plans': itemCues,
        if (peopleCount > 0) 'people_in_touch_this_week': '$peopleReached of $peopleCount',
        'wins_logged_this_week': wins.length,
        if (monthCarry != null) 'month_carry': monthCarry,
        if (quarterFocus != null) 'quarter_focus': quarterFocus,
        'days_in_program_this_week': daysCounted,
        // Body weight stays on the device.
        'avg_energy_1_to_5': avgEnergy,
        'avg_sleep_hours': avgSleep,
        if (wakeSpread != null) 'wake_time_spread_minutes': wakeSpread,
        'open_one_on_one_followups': openFollowUps,
        'personal_patterns': patterns,
        'deep_work_hours': deepWorkHours,
        'evening_shutdowns': shutdowns,
        'week_outcomes': weekOutcomes,
        'people_overdue': peopleOverdue,
        'growth_focus': growthFocus,
        'next_drill': growthDrill,
        'practice_reps_this_week': repsThisWeek,
        if (decidersSeen.$2 > 0) 'deciders_who_saw_your_work_90_days': '${decidersSeen.$1} of ${decidersSeen.$2}',
        if (repsWithoutFeedback.$2 > 0)
          'reps_this_month_without_feedback': '${repsWithoutFeedback.$1} of ${repsWithoutFeedback.$2}',
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
  /// Changes suggested per brief, most important first.
  static const maxAdjustments = 6;

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

    final partial = input.daysCounted < 5;
    final restWeek = !partial && input.daysCounted - input.excusedDays < 3;
    final headline = restWeek
        ? 'A week given mostly to rest or illness. That is part of the plan — next week starts fresh.'
        : partial
        ? 'Your first ${input.daysCounted == 1 ? 'day' : '${input.daysCounted} days'} (${avg.toStringAsFixed(1)}/${input.itemCount}). Too early for a verdict — next week is the first full one.'
        : ratio >= 0.8
        ? 'Strong week (${avg.toStringAsFixed(1)}/${input.itemCount}). Hold the line and raise one bar.'
        : ratio >= 0.6
            ? 'Solid week (${avg.toStringAsFixed(1)}/${input.itemCount}). Tighten ${title(weakest.first)} and ${title(weakest.last)}.'
            : 'Reset week (${avg.toStringAsFixed(1)}/${input.itemCount}). Fewer, firmer commitments.';

    final word = input.wordForTheYear;

    final tasks = <String>[
      // The week's three first: the same ones /week offers in one tap.
      for (final o in input.proposedOutcomes) 'One of the week\'s three: $o',
      for (final id in weakest)
        _taskFor[id] ??
            ((input.itemCues[id] ?? '').trim().isEmpty
                ? 'Protect "${title(id)}": tie it to one fixed moment in your day, and make it smaller if it keeps slipping.'
                : 'Protect "${title(id)}". Your plan: "${_clip(input.itemCues[id]!.trim(), 120)}". If it slipped anyway, the moment is wrong — move it, or do the minimum version.'),
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
    final pastDue = input.goals.where((g) => g.contains('(past due)')).toList();
    // At most six things to change and one thing done well — a long list
    // is a list nobody acts on. Health first, then what their own data
    // says, then set-up nudges (no goal, no rest planned, …), the week and
    // the rest.
    final health = <String>[
      if (ratio < 0.6 && !partial && input.excusedDays < 2 && input.itemCount > 3)
        input.builtInPlan
            ? 'Shrink to the core five next week: manifesto, scan, BLUF, protein, bed. Add the rest back when you hold 5/5.'
            : 'Shrink the list next week: keep the three items that matter most, use their minimum versions on hard days, and add the rest back once those hold.',
      if (input.shoulderFlagDays >= 3)
        'Shoulders flagged on ${input.shoulderFlagDays} mornings. Keep the shoulder-sparing sessions and bring the check-in log to your rheumatologist.',
      if (input.avgSleep != null && input.avgSleep! < 7)
        'Average sleep ${input.avgSleep!.toStringAsFixed(1)} h. Protect ${input.builtInPlan ? '22:30' : 'a fixed bedtime'} before adding anything else — sleep sets tomorrow\'s mind.',
      if ((input.hardDays['sick'] ?? 0) >= 2)
        'You were sick ${input.hardDays['sick']} days. Come back with the minimum version of each item for two days before the full plan — and if it isn\'t getting better, see a doctor.'
      else if ((input.hardDays['pass'] ?? 0) + (input.hardDays['minimum'] ?? 0) >= 3)
        '${(input.hardDays['pass'] ?? 0) + (input.hardDays['minimum'] ?? 0)} hard days this week. Look at what kept happening — if it will happen again, change the plan, not your opinion of yourself.',
    ];
    if (input.lifeChange case final change?) {
      health.add(
          'Life changed recently ($change). Be gentle with the numbers for a while: keep the few items that matter, tie them to the new place or rhythm, and use minimum days freely.');
    }
    if (input.heavyLoad case final from?) {
      health.add(
          'The load has felt heavy two months running${from.isEmpty ? '' : ' (${from.join(', ')})'}. Before it costs you: plan some rest, stop one thing, or ask someone to share it.');
    }
    final personal = <String>[
      if (input.decidersSeen.$2 > 0 && input.decidersSeen.$1 < input.decidersSeen.$2)
        '${input.decidersSeen.$2 - input.decidersSeen.$1} of the people who decide your next step haven\'t seen your work in 90 days. Show one of them something real this week — and ask for their input.',
      if (input.repsWithoutFeedback.$2 >= 3 && input.repsWithoutFeedback.$1 * 2 >= input.repsWithoutFeedback.$2)
        'Most of this month\'s reps had no feedback. Next rep, add one source: record it, ask someone, or check the result — feedback is what turns practice into progress.',
      if (input.patterns.isNotEmpty)
        'From your own last 60 days: ${input.patterns.first}. A pattern, not proof — but worth protecting this week.',
      if (input.growthFocus != null && input.repsThisWeek < 2)
        'Growth — ${input.growthFocus}: ${input.repsThisWeek} rep${input.repsThisWeek == 1 ? '' : 's'} this week. Next week\'s drill: ${input.growthDrill}. Do it twice and write what you noticed.',
      if (input.growthFocus != null && input.feedbackThisMonth == 0)
        'No feedback on ${input.growthFocus} yet this month. Ask one person one specific question — practice without feedback doesn\'t improve.',
      if (input.readinessGap != null)
        '${input.profile.targetRole} gap: ${input.readinessGap}. Pick one thing this week that shows it, and log it as evidence.',
      if (pastDue.isNotEmpty)
        '${pastDue.first.split(' — ').first} has reached its date. Decide on purpose: achieved, a new date, or drop it — an open goal past its date quietly costs attention.',
      if (behind.isNotEmpty)
        'Behind on ${behind.first.split(' — ').first}. Is the obstacle still the one you named? Re-plan it, then make one of next week\'s three its next step.',
      if (input.promisesOverdue > 0)
        '${input.promisesOverdue} promise${input.promisesOverdue == 1 ? ' is' : 's are'} past the date. Close ${input.promisesOverdue == 1 ? 'it' : 'them'} honestly — kept late or missed — and tell the person; next time, say a new date before the day comes.',
      if (input.openCommitments.isNotEmpty)
        'You committed to: "${input.openCommitments.first}". Keep it, renegotiate it with yourself, or drop it on purpose — don\'t let it linger.',
      if (r.hardestMoment.trim().isNotEmpty)
        'Hardest moment: "${_clip(r.hardestMoment.trim(), 120)}". Ask: what would ${input.profile.archetype.isEmpty ? 'the person you\'re becoming' : input.profile.archetype} do differently? Write the answer as one rule.',
      if (input.askRecord != null && input.asksThisWeek == 0)
        'You asked nobody for help this week. Your own record: ${input.askRecord}. Ask one person for one specific thing.',
      if (input.strengths.isNotEmpty && input.strengthUses == 0)
        'Use ${input.strengths.first.toLowerCase()} in a new way this week — once a day if you can.',
      if (input.learningApplied.where((l) => l.endsWith(')') && l.contains(' (experiment: ')).firstOrNull
          case final l?)
        'You took "${_clip(l.substring(l.indexOf(': ') + 2, l.lastIndexOf(' (experiment: ')), 100)}" from ${l.substring(0, l.indexOf(': '))}. Did the experiment hold? Note what happened in Learning — applied learning is the kind that stays.',
      if (input.monthCarry != null)
        'Last month you decided to carry: "${_clip(input.monthCarry!, 100)}". Where will it show up next week?',
      if (input.valueGap != null)
        'This week reflected ${input.valueGap} least. Name one moment next week where you\'ll choose it on purpose.',
      if (input.feedbackThemes != null)
        'What others told you: "${input.feedbackThemes}". Pick one moment next week to act on it where they can see it.',
    ];
    // The first two weeks: health and the basics only. Nudges about things
    // they haven't met yet (rest, notes, deep work…) wait.
    final early = partial || input.programWeek <= 2;
    final setup = <String>[
      if (input.growthFocus == null)
        'No growth area this month. Pick one in the Growth plan — the gap you most want closed — and practise it on real work.',
      if (input.goals.isEmpty)
        'No goals set. Name the one outcome that would make the next six months a success — and the obstacle most likely to stop you.',
      if (!input.restPlanned && !early)
        'No rest planned in the next eight weeks. Put one full rest day — or a lighter week — in the plan now, before the calendar decides for you.',
      if (input.builtInPlan && input.evidenceAddedThisWeek < 5)
        'Evidence Archive: add ${5 - input.evidenceAddedThisWeek} more items tonight — the impostor feeds on forgetting.',
    ];
    final week = <String>[
      if (input.weekOutcomes.isEmpty)
        'No Big 3 for the week. Sunday night: three outcomes that would make next week a win, ${input.builtInPlan ? 'one tied to the artifact' : 'one tied to your goal'}.',
      if (input.builtInPlan && r.gymSessions < 2)
        'If a weekday slips, move the session to Saturday morning rather than skipping it.',
      if (input.goals.isNotEmpty && !input.noteSent && !early)
        'No progress note went out this week. Friday: five lines to ${input.profile.manager.isEmpty ? 'one person you trust' : input.profile.manager} — reported progress moves goals faster than private tracking.',
      if (input.weekOutcomes.any((o) => o.startsWith('[open]')))
        'Week outcomes: ${input.weekOutcomes.where((o) => o.startsWith('[done]')).length} of ${input.weekOutcomes.length} done. Carry the open one only if it still matters — otherwise drop it on purpose.',
      if (input.peopleOverdue.isNotEmpty)
        'Overdue to reach out: ${input.peopleOverdue.join(', ')}. One message each this week — ask about something they care about, not just "how are you".',
      if (input.deepWorkHours < 3 && !early)
        'Deep work: ${input.deepWorkHours.toStringAsFixed(1)} h this week. Book two 90-minute blocks for ${input.builtInPlan ? 'the artifact' : 'what matters most'}${input.energyPeak == null ? '' : ' in your ${input.energyPeak}'} before Monday fills up.',
      if (input.shutdowns < 4 && !early)
        'Evening shutdown on ${input.shutdowns} of 7 nights. Three minutes ${input.builtInPlan ? 'at 21:30' : 'before bed'}: tomorrow\'s three on paper, head empty, then bed.',
    ];
    final more = <String>[
      if (input.openFollowUps >= 3)
        '${input.openFollowUps} open 1:1 follow-ups. Close or hand off the oldest before your next 1:1${input.profile.manager.isEmpty ? '' : ' with ${input.profile.manager}'}.',
      if (input.boardGaps.contains('sponsor'))
        'Nobody on your board speaks for you where you are not. Who could become a sponsor? Ask them for one thing this month.',
      if (input.moveMinutes != null && input.moveMinutes! < 150)
        'Moved ${input.moveMinutes} of 150 minutes this week. Add a 20-minute walk after lunch on three days — that alone closes most of the gap.',
      if (input.growingOthers.any((g) => g.contains('(0 helps')))
        'You\'re helping ${input.growingOthers.firstWhere((g) => g.contains('(0 helps')).split(':').first} grow, but haven\'t this month. One question or one piece of feedback this week is enough.',
      if (input.craftingMove != null)
        'Your crafting move: ${input.craftingMove}. Put it on next week\'s calendar once — small changes to the work are how it starts to fit you.',
    ];
    final recognition = <String>[
      if (early && input.wins.isNotEmpty)
        'You logged ${input.wins.length} win${input.wins.length == 1 ? '' : 's'} — the first: "${_clip(input.wins.first, 100)}". Keep writing them down; on a hard day they are your evidence.',
      if (r.bestMoment.trim().isNotEmpty)
        'Best moment: "${_clip(r.bestMoment.trim(), 120)}". What made it possible? Set that up again next week.',
      if (input.setbacks > 0)
        '${input.setbacks} setback${input.setbacks == 1 ? '' : 's'} met with a next step instead of a spiral. That is the skill.',
      if (input.courageSteps > 0)
        'You climbed ${input.courageSteps} rung${input.courageSteps == 1 ? '' : 's'} of your courage ladder. Doing the thing you avoid is how self-trust is built.',
      if (input.thoughtsChecked > 0)
        'You put ${input.thoughtsChecked} hard thought${input.thoughtsChecked == 1 ? '' : 's'} to the test this week instead of believing ${input.thoughtsChecked == 1 ? 'it' : 'them'}.',
      if (input.peopleCount >= 3 && input.peopleReached * 2 >= input.peopleCount)
        'In touch with ${input.peopleReached} of your ${input.peopleCount} people this week. That is how closeness is kept.',
      if (input.kindnessActs >= 5)
        '${input.kindnessActs} kind acts this week — they count for you too.',
      if (strongest != null && (input.itemRates[strongest] ?? 0) >= 0.85)
        '${title(strongest)} is becoming automatic — keep it, stop thinking about it.',
    ];
    // Each tier gets its share first, so the week is never crowded out;
    // free places then go to the rest, in the same order.
    final adjustments = [
      ...[
        ...health.take(2),
        ...personal.take(2),
        ...setup.take(1),
        ...week.take(1),
        ...personal.skip(2),
        ...week.skip(1),
        ...setup.skip(1).take(1),
        ...health.skip(2),
        if (!early) ...more,
      ].take(maxAdjustments),
      ...recognition.take(1),
    ];

    return WeeklyBrief(
      id: 'brief_${dateKey(input.forWeek)}',
      weekStart: input.forWeek,
      createdAt: DateTime.now(),
      source: 'device',
      headline: word == null ? headline : '$headline Your word for the year: $word.',
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
        // The same caps as the device's brief: a long list isn't acted on.
        tasks: List<String>.from(r['tasks'] as List).take(6).toList(),
        domainBrief: r['domain_brief'] as String,
        coaching: r['coaching'] as String,
        adjustments:
            List<String>.from(r['adjustments'] as List? ?? const []).take(7).toList(),
      );
    } catch (_) {
      return fallback.generate(input);
    }
  }
}

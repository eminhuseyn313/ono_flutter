import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/auth_provider.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_charts.dart';
import '../widgets/ono_ui.dart';

/// ME — who you are becoming, measured. Every figure comes from your own
/// check-offs and logs. Settings that actually do something.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.isLoaded) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    final today = dayOnly(DateTime.now());
    final weeks = ((today.daysSince(weekStartOf(system.programStart))) ~/ 7 + 1)
        .clamp(1, 26);
    final heatFrom = weekStartOf(today).minusDays((weeks - 1) * 7);
    final keyLifts = [
      'Dumbbell Shoulder Press',
      'Lat Pulldown',
      'Goblet Squat',
      'Romanian Deadlift',
      'Face Pulls',
    ];

    return OnoPage(
      eyebrow: activeProfile.archetype,
      title: activeProfile.name,
      subtitle: [activeProfile.roleLine, activeProfile.organisation]
          .where((s) => s.trim().isNotEmpty)
          .join('\n'),
      children: [
        const SizedBox(height: 20),
        // Me starts with what someone came for: finding the right tool.
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.search_rounded,
            color: AppColors.accent,
            title: 'Find a tool',
            subtitle: 'Search everything ONO can help with',
            onTap: () => context.push('/tools'),
          ),
        ),
        const SizedBox(height: 12),
        OnoCard(
          color: AppColors.navy,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: StatTile(
                          system.programComplete
                              ? '${system.programDays}'
                              : system.hasStarted
                                  ? '${system.programDay}'
                                  : '0',
                          system.programComplete
                              ? 'days · complete'
                              : 'day of ${system.programDays}')),
                  // No row of zeros on day one: streaks show once there is one.
                  if (system.bestStreak > 0) ...[
                    Expanded(child: StatTile('${system.streak}', 'streak')),
                    Expanded(
                        child: StatTile('${system.bestStreak}', 'best streak')),
                  ],
                  Expanded(
                      child: StatTile('${system.daysHeld}',
                          system.cycle > 1 ? 'held this program' : 'days held')),
                ],
              ),
              const SizedBox(height: 16),
              ThinBar(
                  value: system.hasStarted
                      ? (system.programDay / system.programDays).clamp(0.0, 1.0)
                      : 0),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                      '${system.daysHeldThisMonth} held this month · one slip is forgiven',
                      style: AppText.small().copyWith(fontSize: 11.5)),
                ],
              ),
              if (system.latelyLine case final l?) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l,
                      key: const Key('me-lately'),
                      style: AppText.small(color: AppColors.white)),
                ),
              ],
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    Text('Month ${system.programMonth} · ${system.phase.name}',
                        style: AppText.small()),
                    Text(
                        'Ends ${shortDate(system.programEnd)}${system.programEnd.year != DateTime.now().year ? ' ${system.programEnd.year}' : ''}${system.pausedDays > 0 ? ' · paused ${system.pausedDays} d' : ''}',
                        style: AppText.small()),
                  ],
                ),
              ),
            ],
          ),
        ),
        // History, mornings and patterns appear once there is something
        // to show; on day one they are empty grids.
        if (system.programDay >= 7 || system.daysHeld > 0) ...[
          const SectionHeader('Every day so far'),
          OnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeatGrid(
                  from: heatFrom,
                  weeks: weeks < 8 ? 8 : weeks,
                  scoreFor: (d) => d.isBefore(system.programStart)
                      ? null
                      : system.scoreOutOf10(d),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Less', style: AppText.small().copyWith(fontSize: 11)),
                    const SizedBox(width: 6),
                    for (final s in [0, 3, 6, 8, 10])
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                            color: heatColor(s),
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    Text('more · Daily ${system.dailyCount}',
                        style: AppText.small().copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (system.isBuiltInPerson) ...[
          const SectionHeader('Protocol mastery'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (final p in protocols)
                  InkWell(
                    onTap: () =>
                        context.push(protocolTools[p.id] ?? '/protocols'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(p.icon, size: 18, color: AppColors.lane(p.lane)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(p.name, style: AppText.body())),
                          Text('${system.usesOf(p.id)}',
                              style: AppText.small(color: AppColors.white)
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 86,
                            child: Text(system.masteryOf(p.id),
                                textAlign: TextAlign.right,
                                style: AppText.small(
                                    color: system.usesOf(p.id) >= 20
                                        ? AppColors.accent
                                        : AppColors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (system.isBuiltInPerson || system.logsOf('checkin').isNotEmpty) ...[
          SectionHeader('Mornings',
              action: 'Check in', onAction: () => context.push('/checkin')),
          const _Mornings(),
        ],
        const _AppleHealth(),
        const _CalendarLink(),
        // Patterns and experiments need a couple of weeks of days first
        // (an experiment already running always shows).
        if (system.programDay >= 14 ||
            system.logsOf('experiment').isNotEmpty) ...[
          const SectionHeader('What moves your day'),
          const _Patterns(),
          const SizedBox(height: 10),
          OnoCard(
            padding: EdgeInsets.zero,
            child: LinkRow(
              icon: Icons.science_outlined,
              color: AppColors.mind,
              title: 'Experiments',
              subtitle: system.experimentsWith('running').isEmpty
                  ? 'Test a change for 1–3 weeks, keep it or drop it'
                  : 'Running: ${system.experimentsWith('running').map((e) => e.text).join(' · ')}',
              onTap: () => context.push('/experiments'),
            ),
          ),
        ],
        SectionHeader('Body',
            action: '${system.moveMinutesInWeek(DateTime.now())} min moved',
            onAction: () => context.push('/move')),
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.spa_outlined,
            color: AppColors.body,
            title: 'Care',
            subtitle: system.upkeep.isEmpty
                ? 'Check-ups, haircut, nails, the car — what slips when busy'
                : system.upkeepDue.isEmpty
                    ? '${system.upkeep.length} tracked · nothing due'
                    : 'Due: ${system.upkeepDue.map((u) => u.text).join(' · ')}',
            onTap: () => context.push('/upkeep'),
          ),
        ),
        const SizedBox(height: 10),
        if (!system.isBuiltInPerson)
          const _MoveSummary()
        else
          OnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                          system.latestWeight?.toStringAsFixed(1) ?? '—',
                          'kg now',
                          unit: 'kg'),
                    ),
                    Expanded(
                      child: StatTile(
                          system.startWeight == null ||
                                  system.latestWeight == null
                              ? '—'
                              : (system.latestWeight! - system.startWeight!)
                                  .toStringAsFixed(1),
                          'since Day 1'),
                    ),
                    Expanded(
                        child:
                            StatTile('${system.countOf('gym')}', 'sessions')),
                  ],
                ),
                const SizedBox(height: 14),
                for (final l in keyLifts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(l, style: AppText.small())),
                        Text(
                            system.bestLift(l) > 0
                                ? '${system.bestLift(l).toStringAsFixed(1)} kg'
                                : '—',
                            style: AppText.small(color: AppColors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SectionHeader('Direction'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.flag_circle_outlined,
                color: AppColors.accent,
                title: 'Goals',
                subtitle: system.activeGoals.isEmpty
                    ? 'The outcomes everything else serves'
                    : system.activeGoals.map((g) => g.text).join(' · '),
                onTap: () => context.push('/goals'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.trending_up_rounded,
                color: AppColors.accent,
                title: 'Growth plan',
                subtitle: system.focusArea() == null
                    ? 'Choose this month\'s area'
                    : '${system.focusArea()!.name} · ${system.repsIn(system.focusArea()!.id, system.programMonth).length} reps this month',
                onTap: () => context.push('/growth'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.explore_outlined,
                color: AppColors.skill,
                title: 'Three possible lives',
                subtitle: system.odysseyLeaning == null
                    ? 'An Odyssey plan: your options for the next five years'
                    : 'Leaning towards: ${system.odysseyLeaning}',
                onTap: () => context.push('/odyssey'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.wb_sunny_outlined,
                color: AppColors.skill,
                title: 'Your best possible future',
                subtitle: system.bestFuture == null
                    ? 'Write it as if it already happened'
                    : 'Last written ${shortDate(system.bestFuture!.date)}',
                onTap: () => context.push('/best-future'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.bolt_outlined,
                color: AppColors.skill,
                title: 'Signature strengths',
                subtitle: system.signatureStrengths.isEmpty
                    ? 'Pick your top five, use one in a new way'
                    : system.signatureStrengths.join(' · '),
                onTap: () => context.push('/strengths'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.auto_stories_outlined,
                color: AppColors.mind,
                title: 'Life chapters',
                subtitle: system.lifeChapters.isEmpty
                    ? 'Your story so far, and the next chapter'
                    : '${system.lifeChapters.length} chapters${(system.lifeStory?.str('next') ?? '').isEmpty ? '' : ' · next: ${system.lifeStory!.str('next')}'}',
                onTap: () => context.push('/chapters'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.diamond_outlined,
                color: AppColors.mind,
                title: 'Your values',
                subtitle: system.values.isEmpty
                    ? 'Three to five, in your own words'
                    : system.values.map((v) => v.name).join(' · '),
                onTap: () => context.push('/values'),
              ),
              if (system.isBuiltInPerson) const Divider(indent: 66),
              if (system.isBuiltInPerson)
                LinkRow(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.skill,
                  title: '${activeProfile.targetRole} readiness',
                  subtitle: system.readiness.isEmpty
                      ? 'Not rated yet'
                      : system.readinessGap == null
                          ? 'At the bar on every dimension'
                          : 'Gap: ${system.readinessGap!.name}',
                  onTap: () => context.push('/cockpit?tab=2'),
                ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.savings_outlined,
                color: AppColors.body,
                title: 'Money check-in',
                subtitle:
                    system.moneySummary == null || system.moneySummary!.isEmpty
                        ? 'Once a month: in, out, set aside, one decision'
                        : 'Last: ${system.moneySummary}',
                onTap: () {
                  system.setDone('money:on', true);
                  context.push('/money');
                },
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.donut_large_rounded,
                color: AppColors.accent,
                title: 'Quarterly review',
                subtitle: system.lowestLifeArea == null
                    ? 'Life wheel, wins, lessons, next 90 days'
                    : 'Lowest last time: ${system.lowestLifeArea!.name}',
                onTap: () => context.push('/quarter'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.menu_book_outlined,
                color: AppColors.accent,
                title: 'Story bank',
                subtitle: system.stories.isEmpty
                    ? 'Your best stories, ready for an interview or review'
                    : '${system.stories.length} stories${system.storyGaps.isEmpty ? '' : ' · none yet for ${system.storyGaps.first.toLowerCase()}'}',
                onTap: () => context.push('/stories'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.workspace_premium_outlined,
                color: AppColors.accent,
                title: 'Brag document',
                subtitle: 'What you\'ve done, ready for a review or a CV',
                onTap: () => context.push('/brag'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.celebration_outlined,
                color: AppColors.accent,
                title: 'Year in review',
                subtitle: system.wordForTheYear != null
                    ? 'Your word for this year: ${system.wordForTheYear}'
                    : 'What the year added up to, and one word for the next',
                onTap: () => context.push('/year'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.mail_outline_rounded,
                color: AppColors.accent,
                title: 'Letters to future you',
                subtitle: system.letters.isEmpty
                    ? 'Seal one for the next phase or the last day'
                    : '${system.letters.where((l) => !system.letterIsOpen(l)).length} sealed · ${system.letters.where(system.letterIsOpen).length} opened',
                onTap: () => context.push('/letters'),
              ),
            ],
          ),
        ),
        const SectionHeader('Practice'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.school_outlined,
                color: AppColors.skill,
                title: 'Learning',
                subtitle: system.learningWith('active').isEmpty
                    ? 'Learn it, then apply it'
                    : 'Now: ${system.learningWith('active').map((l) => l.text).join(' · ')}',
                onTap: () => context.push('/learning'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.flag_outlined,
                color: AppColors.skill,
                title: 'After-action review',
                subtitle: system.aars.isEmpty
                    ? 'After something that mattered: keep one thing, change one'
                    : 'Last: ${system.aars.first.text}',
                onTap: () => context.push('/aar'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.menu_book_outlined,
                color: AppColors.skill,
                title: 'Your playbook',
                subtitle: system.playbook().isEmpty
                    ? 'Every lesson you write gathers here'
                    : '${system.playbook().length} lessons in your own words',
                onTap: () => context.push('/playbook'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.stairs_outlined,
                color: AppColors.skill,
                title: 'Courage ladder',
                subtitle: system.nextCourageStep == null
                    ? 'What you avoid, one rung at a time'
                    : 'Next rung: ${system.nextCourageStep!.text}',
                onTap: () => context.push('/courage'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.center_focus_strong_rounded,
                color: AppColors.skill,
                title: 'Deep work',
                subtitle: system.isBuiltInPerson
                    ? '${(system.focusMinutesInWeek(DateTime.now()) / 60).toStringAsFixed(1)} h this week · ${(system.artifactMinutesThisMonth / 60).toStringAsFixed(1)} h on the artifact this month'
                    : '${(system.focusMinutesInWeek(DateTime.now()) / 60).toStringAsFixed(1)} h this week · one block, one thing',
                onTap: () => context.push('/focus'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.style_rounded,
                color: AppColors.mind,
                title: 'Review deck',
                subtitle:
                    '${system.deckStats.total} cards · ${system.deckStats.mature} mature',
                onTap: () => context.push('/review'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.autorenew_rounded,
                color: AppColors.body,
                title: 'Is it a habit yet?',
                subtitle:
                    '${system.automaticItems.length} of ${system.dailyCount} automatic',
                onTap: () => context.push('/habits'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.bolt_outlined,
                color: AppColors.mind,
                title: 'Energy map',
                subtitle: system.energyPeak == null
                    ? 'Find the hours you are sharpest'
                    : 'Peak: ${system.energyPeak!.label.toLowerCase()}',
                onTap: () => context.push('/energy'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.battery_charging_full_rounded,
                color: AppColors.skill,
                title: 'What gives and drains you',
                subtitle: system.craftingMove ??
                    'Rate a normal week, then change one thing',
                onTap: () => context.push('/crafting'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.do_not_disturb_on_outlined,
                color: AppColors.warning,
                title: 'Stop doing',
                subtitle: system.stopList.isEmpty
                    ? 'What you give up to make room'
                    : '${system.stopList.length} given up',
                onTap: () => context.push('/stop'),
              ),
            ],
          ),
        ),
        const SectionHeader('People'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.group_outlined,
                color: AppColors.social,
                title: 'People',
                subtitle: system.people.isEmpty
                    ? 'Who you invest in, and how often'
                    : '${system.people.length} people · ${system.peopleDue.length} due${system.peopleGrowing.isEmpty ? '' : ' · helping ${system.peopleGrowing.length} grow'}',
                onTap: () => context.push('/people'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.send_rounded,
                color: AppColors.social,
                title: 'Progress note',
                subtitle: system.noteSentInWeek(DateTime.now())
                    ? 'Sent this week'
                    : 'Tell one person how the week went',
                onTap: () => context.push('/note'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.favorite_outline_rounded,
                color: AppColors.social,
                title: 'A check-in for two',
                subtitle: system.usStreak == 0
                    ? 'Twenty minutes a week with your partner'
                    : '${system.usStreak} week${system.usStreak == 1 ? '' : 's'} in a row',
                onTap: () => context.push('/us'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.menu_book_rounded,
                color: AppColors.social,
                title: 'How to work with me',
                subtitle: system.manual == null
                    ? 'A one-page user manual for your team or partner'
                    : 'Updated ${shortDate(system.manual!.date)}',
                onTap: () => context.push('/manual'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.forum_outlined,
                color: AppColors.social,
                title: 'Hard conversations',
                subtitle: system.plannedConversations.isEmpty
                    ? 'Prepare the one you\'ve been avoiding'
                    : '${system.plannedConversations.length} ahead · with ${system.plannedConversations.map((c) => c.str('with')).join(', ')}',
                onTap: () => context.push('/conversations'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.handshake_outlined,
                color: AppColors.social,
                title: 'Accountability partner',
                subtitle: system.partner == null
                    ? 'One promise each, one check-in a week'
                    : 'With ${system.partner!.text}',
                onTap: () => context.push('/partner'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.groups_2_outlined,
                color: AppColors.social,
                title: 'Feedback round',
                subtitle: system.roundFor(system.programQuarter) == null
                    ? 'One question, three people, once a quarter'
                    : 'Quarter ${system.programQuarter}: ${system.roundAnswers(system.roundFor(system.programQuarter)!).length} answers',
                onTap: () => context.push('/360'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.auto_awesome_outlined,
                color: AppColors.skill,
                title: 'You, at your best',
                subtitle: system.bestSelfPortrait ??
                    'Stories from people who have seen it',
                onTap: () => context.push('/best-self'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.emoji_people_outlined,
                color: AppColors.skill,
                title: 'Role models',
                subtitle: system.roleModels.isEmpty
                    ? 'People one step ahead, and what to ask them'
                    : system.roleModels.map((m) => m.text).join(' · '),
                onTap: () => context.push('/models'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.pan_tool_alt_outlined,
                color: AppColors.social,
                title: 'Ask for help',
                subtitle: system.askRecord() != null
                    ? '${system.askRecord()!.yes} of ${system.askRecord()!.asked} said yes or partly · you expected ${system.askRecord()!.guess}%'
                    : system.openAsks.isEmpty
                        ? 'Guess the chance of a yes, then ask'
                        : '${system.openAsks.length} waiting for an answer',
                onTap: () => context.push('/asks'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.tips_and_updates_outlined,
                color: AppColors.social,
                title: 'Advice',
                subtitle: system.adviceToReport.isNotEmpty
                    ? '${system.adviceToReport.length} to report back on'
                    : 'Write it down, try it, tell them how it went',
                onTap: () => context.push('/advice'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.handshake_outlined,
                color: AppColors.social,
                title: 'Negotiation planner',
                subtitle: 'A raise, a scope, rent: prepare in 15 minutes',
                onTap: () => context.push('/negotiate'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.handshake_outlined,
                color: AppColors.social,
                title: 'Promises',
                subtitle: system.sayDo() != null
                    ? 'Kept ${system.sayDo()!.kept} of ${system.sayDo()!.kept + system.sayDo()!.missed} · ${system.openPromises.length} open'
                    : system.openPromises.isEmpty
                        ? 'What you said you\'d do, kept or renegotiated in time'
                        : '${system.openPromises.length} open',
                onTap: () => context.push('/promises'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.groups_outlined,
                color: AppColors.social,
                title: 'Your personal board',
                subtitle: system.boardGaps.isNotEmpty
                    ? 'Missing: ${system.boardGaps.join(', ')}'
                    : system.board.values.every((v) => v.isEmpty)
                        ? 'Mentor, sponsor, peer, challenger — who is yours?'
                        : 'Every role has someone',
                onTap: () => context.push('/board'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.volunteer_activism_outlined,
                color: AppColors.social,
                title: 'Kindness day',
                subtitle: system.kindnessDay == null
                    ? 'Five small kind acts, one day a week'
                    : '${weekdayName(system.kindnessDay!)}s · ${system.kindnessInWeek(DateTime.now())} this week',
                onTap: () => context.push('/kindness'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.favorite_outline_rounded,
                color: AppColors.social,
                title: 'Gratitude letter',
                subtitle: 'To someone who changed your life',
                onTap: () => context.push('/gratitude'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.assignment_outlined,
                color: AppColors.social,
                title: 'Report for your coach',
                subtitle: 'This month or quarter, ready to copy',
                onTap: () => context.push('/coach-report'),
              ),
            ],
          ),
        ),
        const SectionHeader('Hard days'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.replay_rounded,
                color: AppColors.warning,
                title: 'It slipped — reset',
                subtitle: 'Kindness, facts, the smallest next step',
                onTap: () => context.push('/setback'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.zoom_out_map_rounded,
                color: AppColors.mind,
                title: 'Step back',
                subtitle: 'Talk to yourself by name when it all feels close',
                onTap: () => context.push('/stepback'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.psychology_outlined,
                color: AppColors.mind,
                title: 'Thought check',
                subtitle: system.thoughtRelief == null
                    ? 'Put a painful thought to the test'
                    : 'Takes the feeling down ${system.thoughtRelief!.round()} points on average',
                onTap: () => context.push('/thought'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.local_parking_rounded,
                color: AppColors.mind,
                title: 'Worry time',
                subtitle: system.parkedWorries.isEmpty
                    ? 'Park worries, deal with them once a day'
                    : '${system.parkedWorries.length} parked',
                onTap: () => context.push('/worry'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.alt_route_rounded,
                color: AppColors.mind,
                title: 'Decide with your values',
                subtitle: 'Options, what matters, 10/10/10, a premortem',
                onTap: () => context.push('/decide'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.psychology_alt_outlined,
                color: AppColors.mind,
                title: 'Think it through',
                subtitle: 'Coach yourself on a problem that keeps circling',
                onTap: () => context.push('/coach'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.beach_access_outlined,
                color: AppColors.body,
                title: 'Plan your rest',
                subtitle: system.restPlannedSoon
                    ? 'Rest is in the plan'
                    : 'Nothing planned in the next 8 weeks',
                onTap: () => context.push('/rest'),
              ),
            ],
          ),
        ),
        const SectionHeader('Settings'),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LinkRow(
                icon: Icons.auto_awesome_outlined,
                color: AppColors.accent,
                title: 'Build your plan',
                subtitle: system.planBuilt
                    ? 'Rebuild: profile, life wheel, focus, goal, daily items'
                    : '5 minutes: who you are becoming, one goal, daily actions',
                onTap: () => context.push('/start'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.inventory_2_outlined,
                color: AppColors.accent,
                title: 'Plan packs',
                subtitle: 'Start from a ready plan, or share yours',
                onTap: () => context.push('/packs'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.badge_outlined,
                color: AppColors.accent,
                title: 'Your profile',
                subtitle:
                    '${[activeProfile.currentRole, activeProfile.targetRole].where((s) => s.trim().isNotEmpty).join(' → ')}${system.profileEdited ? ' · edited' : ''}',
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.event_rounded,
                color: AppColors.accent,
                title: 'Program start',
                subtitle:
                    '${weekdayName(system.programStart.weekday)} ${shortDate(system.programStart)} ${system.programStart.year}',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: system.programStart,
                    // A start further back than the picker's range (a long
                    // program, paused days) must still be the initial date.
                    firstDate:
                        system.programStart.isBefore(today.minusDays(540))
                            ? system.programStart
                            : today.minusDays(540),
                    lastDate: today.plusDays(60),
                  );
                  if (picked != null) system.setProgramStart(picked);
                },
              ),
              if (system.isBuiltInPerson) ...[
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.body,
                  title: 'Gym days',
                  subtitle: [
                    for (var i = 0; i < 3; i++)
                      '${gymPlan[i].letter} ${weekdayName(system.gymDays[i]).substring(0, 3)}'
                  ].join(' · '),
                  onTap: () => _gymDaysSheet(context, system),
                ),
              ],
              const Divider(indent: 66),
              if (!system.isBuiltInPerson) ...[
                LinkRow(
                  icon: Icons.schedule_rounded,
                  color: AppColors.mind,
                  title: 'Your day',
                  subtitle: system.dayShape == null
                      ? 'Wake, work and bed times'
                      : 'Wake ${(system.dayShape!.wake ~/ 60).toString().padLeft(2, '0')}:${(system.dayShape!.wake % 60).toString().padLeft(2, '0')} · lights out ${(system.dayShape!.bed ~/ 60).toString().padLeft(2, '0')}:${(system.dayShape!.bed % 60).toString().padLeft(2, '0')}',
                  onTap: () => context.push('/day'),
                ),
                const Divider(indent: 66),
              ],
              if (system.remindersSupported) ...[
                LinkRow(
                  icon: Icons.notifications_none_rounded,
                  color: AppColors.mind,
                  title: 'Reminders',
                  subtitle:
                      '${system.activeReminderDefs.where((r) => system.reminderOn(r.id)).length} of ${system.activeReminderDefs.length} on',
                  onTap: () => _remindersSheet(context),
                ),
                const Divider(indent: 66),
              ],
              LinkRow(
                icon: Icons.timelapse_rounded,
                color: AppColors.accent,
                title: 'Program length',
                subtitle:
                    '${system.programLengthLabel}${system.cycle > 1 ? ' · program ${system.cycle}' : ''}',
                onTap: () => _lengthSheet(context, system),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.flash_on_outlined,
                color: AppColors.mind,
                title: 'Emergency skips',
                subtitle:
                    '${system.passesPerMonth} a month · for days you couldn\'t plan for',
                onTap: () => _skipsSheet(context, system),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.ios_share_rounded,
                color: AppColors.steel,
                title: 'Export backup',
                subtitle: 'Everything as a JSON file you keep',
                onTap: () async {
                  final json = system.exportJson();
                  try {
                    await Share.share(json,
                        subject: 'ONO backup ${dateKey(today)}');
                  } catch (_) {
                    if (context.mounted) {
                      await copyText(context, json,
                          message: 'Backup copied to clipboard');
                    }
                  }
                },
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.restore_rounded,
                color: AppColors.steel,
                title: 'Restore from clipboard',
                subtitle: 'Paste an exported backup',
                onTap: () => _restore(context, system),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.shield_outlined,
                color: AppColors.steel,
                title: 'Your data & privacy',
                subtitle: system.syncsToCloud
                    ? 'On this phone and your private cloud · delete anytime'
                    : 'Only on this phone · export or delete anytime',
                onTap: () => context.push('/privacy'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.logout_rounded,
                color: AppColors.danger,
                title: 'Sign out',
                subtitle: 'Your data stays on this device',
                onTap: () async {
                  final auth = context.read<AuthProvider>();
                  await auth.signOut();
                  if (!context.mounted) return;
                  if (auth.isAuthenticated) {
                    toast(context, 'Couldn\'t sign out. Check your connection and try again.');
                    return;
                  }
                  context.go('/welcome');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
            system.syncsToCloud
                ? 'Data is on this device with a copy in your private cloud. Export a backup to keep your own copy.'
                : 'Data is stored on this device. Export a backup before deleting the app or changing phones.',
            style: AppText.small()),
      ],
    );
  }

  void _lengthSheet(BuildContext context, PersonalSystemProvider system) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Program length', style: AppText.title()),
              const SizedBox(height: 4),
              Text(
                  'The four phases spread over it, and at the end you look back and start the next. You are on day ${system.programDay}; a length shorter than that ends this program today.',
                  style: AppText.small()),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in PersonalSystemProvider.programLengths.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: system.programDays == e.key,
                      onSelected: (_) async {
                        // Shorter than the day you're on ends the program
                        // today: ask, so a stray tap doesn't.
                        if (e.key < system.programDay) {
                          final yes = await showDialog<bool>(
                            context: ctx,
                            builder: (d) => AlertDialog(
                              title: const Text('End this program today?'),
                              content: Text(
                                  'You are on day ${system.programDay}. ${e.value} ends it now and opens the look back.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Keep going')),
                                TextButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text('End it')),
                              ],
                            ),
                          );
                          if (yes != true) return;
                        }
                        system.setProgramLength(e.key);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/next-program');
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(system.programComplete
                    ? 'Close this program and start the next'
                    : 'Close this program early'),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Future<void> _skipsSheet(
          BuildContext context, PersonalSystemProvider system) =>
      showModalBottomSheet<void>(
      isScrollControlled: true,
      useRootNavigator: true,
        context: context,
        backgroundColor: AppColors.card,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency skips', style: AppText.title()),
                const SizedBox(height: 4),
                Text(
                    'A skip sets a day aside without breaking your streak. A small reserve keeps people going; a big one stops meaning anything. Most people do well with 2.',
                    style: AppText.small()),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var n = 0;
                        n <= PersonalSystemProvider.maxPassesPerMonth;
                        n++)
                      ChoiceChip(
                        label: Text('$n a month'),
                        selected: system.passesPerMonth == n,
                        onSelected: (_) {
                          system.setPassesPerMonth(n);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          )),
      ),
      );

  Future<void> _restore(
      BuildContext context, PersonalSystemProvider system) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (!context.mounted) return;
    final preview = system.importPreview(text);
    if (preview == null) {
      toast(context, 'That isn\'t an ONO backup. Copy the whole backup, then try again.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Replace all data?', style: AppText.title()),
        content: Text(
            'The backup holds ${preview.entries} entries${preview.latest == null ? '' : ', the latest from ${shortDate(preview.latest!)} ${preview.latest!.year}'}.'
            '${preview.missingHere == 0 ? '' : ' ${preview.missingHere} entries here aren\'t in it and will be removed — on every device that syncs.'}',
            style: AppText.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (!system.importJson(text)) {
      toast(context, 'That isn\'t an ONO backup.');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 10),
        content: const Text('Backup restored.'),
        action: SnackBarAction(label: 'Undo', onPressed: system.undoImport),
      ));
  }

  void _gymDaysSheet(BuildContext context, PersonalSystemProvider system) {
    var days = List<int>.from(system.gymDays);
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gym days', style: AppText.title()),
              const SizedBox(height: 14),
              for (var i = 0; i < 3; i++) ...[
                Text(
                    'DAY ${gymPlan[i].letter} · ${gymPlan[i].name.toUpperCase()}',
                    style: AppText.eyebrow()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      ChoiceChip(
                        label: Text(weekdayName(d).substring(0, 3)),
                        selected: days[i] == d,
                        onSelected: days.contains(d) && days[i] != d
                            ? null
                            : (_) => set(() => days[i] = d),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton('Save', onPressed: () {
                system.setGymDays(days);
                Navigator.pop(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _remindersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer<PersonalSystemProvider>(
        builder: (ctx, system, _) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text('Reminders', style: AppText.title()),
              const SizedBox(height: 6),
              Text('Each opens the tool for that moment.',
                  style: AppText.small()),
              const SizedBox(height: 10),
              for (final r in system.activeReminderDefs)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: system.reminderOn(r.id),
                  onChanged: (v) => system.setReminder(r.id, v),
                  title: Text(r.label,
                      style: AppText.body(color: AppColors.white)
                          .copyWith(fontSize: 14.5)),
                  subtitle: Text(
                      r.id == 'gym'
                          ? '18:45 on gym days'
                          : '${r.timeLabel}${r.weekdays == null ? ' daily' : ' · ${r.weekdays!.map((d) => weekdayName(d).substring(0, 3)).join(', ')}'}',
                      style: AppText.small()),
                ),
              const SizedBox(height: 8),
              GhostButton('Allow notifications',
                  icon: Icons.notifications_active_outlined,
                  onPressed: () async {
                final ok = await system.requestReminderPermission();
                if (ctx.mounted) {
                  toast(ctx,
                      ok ? 'Notifications on.' : 'Enable in Settings › ONO.');
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last 7 days of check-ins: energy, sleep and shoulders, plus the pain
/// trend for 30 days — the log to bring to the rheumatologist.
/// Personal patterns from his own logs: days with a habit vs without.
class _Patterns extends StatelessWidget {
  const _Patterns();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final found = system.patterns();
    if (found.isEmpty) {
      return const EmptyNote(
          'Patterns show here once there are 5+ days with and without a habit: '
          'sleep vs your daily list, bedtime vs morning energy, caffeine vs sleep. '
          'Morning check-ins make them appear sooner.',
          icon: Icons.insights_rounded);
    }
    return OnoCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in found.take(4))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: Icon(
                        p.delta >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 18,
                        color:
                            p.delta >= 0 ? AppColors.body : AppColors.warning),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.habit} → ${p.outcome} ${p.fmt(p.withHabit)}',
                            style: AppText.body(color: AppColors.white)),
                        Text(
                            'vs ${p.fmt(p.without)} without · ${p.daysWith} vs ${p.daysWithout} days',
                            style: AppText.small().copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text('Last 60 days of your own logs. Patterns, not proof.',
              style:
                  AppText.small(color: AppColors.faint).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Mornings extends StatelessWidget {
  const _Mornings();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = DateTime.now();
    final week = system.checkinsEnding(today, 7);
    if (week.isEmpty) {
      return const EmptyNote(
          'No check-ins yet. Thirty seconds each morning shows how sleep, energy and mood move together.',
          icon: Icons.wb_twilight_rounded);
    }
    String avg(String key, int digits) {
      final v = system.averageOf(week, key);
      return v == null ? '—' : v.toStringAsFixed(digits);
    }

    final month = system.checkinsEnding(today, 30);
    final flags = system.flagDaysInWeekEnding(today);
    return OnoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: StatTile(avg('energy', 1), 'energy', unit: '/5')),
              Expanded(child: StatTile(avg('sleep', 1), 'sleep', unit: 'h')),
              Expanded(
                  child: system.isBuiltInPerson
                      ? StatTile(avg('pain', 1), 'shoulder pain', unit: '/10')
                      : StatTile(avg('mood', 1), 'mood', unit: '−2…2')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Averages of the last ${week.length} check-ins',
              style: AppText.small().copyWith(fontSize: 11.5)),
          if (system.feelingsNamed().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
                'Named this month: ${system.feelingsNamed().take(4).map((f) => f.$2 > 1 ? '${f.$1} ×${f.$2}' : f.$1).join(' · ')}',
                key: const Key('feelings-named'),
                style: AppText.small(color: AppColors.white)),
          ],
          if (month.length >= 2 && system.isBuiltInPerson) ...[
            const SizedBox(height: 14),
            Text('SHOULDER PAIN · 30 DAYS', style: AppText.eyebrow()),
            const SizedBox(height: 8),
            TrendLine(
              points: [
                for (final c in month)
                  (x: c.date, y: (c.number('pain') ?? 0).toDouble())
              ],
              color: AppColors.warning,
              height: 110,
              unit: '/10',
            ),
          ],
          if (flags >= 3 && system.isBuiltInPerson) ...[
            const SizedBox(height: 12),
            OnoCard(
              accent: AppColors.warning,
              padding: const EdgeInsets.all(12),
              child: Text(
                  'Shoulders flagged on $flags of the last 7 mornings. Worth mentioning to your rheumatologist — this log shows the pattern.',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Apple Health link: last night's sleep, HRV and resting heart rate.
/// Sleep before 22:45 ticks "In bed by 10:30pm" automatically.
/// Calendar link for meeting prep; meetings stay on the phone.
class _CalendarLink extends StatelessWidget {
  const _CalendarLink();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.calendarSupported) return const SizedBox.shrink();
    final on = system.calendarConnected;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        padding: EdgeInsets.zero,
        child: LinkRow(
          icon: Icons.event_rounded,
          color: AppColors.skill,
          title: on ? 'Calendar connected' : 'Connect your calendar',
          subtitle: on
              ? 'Today shows your meetings; a nudge 10 min before each. Tap to disconnect.'
              : activeProfile.keyPeopleNames.isEmpty
                  ? 'Today shows your meetings and a breathing nudge 10 min before each. Read-only, stays on the phone.'
                  : 'Today shows your meetings; 10 min before each: sigh, or six questions for ${activeProfile.keyPeopleNames}. Read-only, stays on the phone.',
          onTap: () async {
            if (on) {
              await system.disconnectCalendar();
              if (context.mounted) toast(context, 'Calendar disconnected.');
              return;
            }
            final err = await system.connectCalendar();
            if (context.mounted) {
              toast(context,
                  err ?? 'Connected — today\'s meetings are on Today.');
            }
          },
        ),
      ),
    );
  }
}

class _AppleHealth extends StatelessWidget {
  const _AppleHealth();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.healthSupported) return const SizedBox.shrink();
    if (!system.healthConnected) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            icon: Icons.favorite_outline_rounded,
            color: AppColors.danger,
            title: 'Connect Apple Health',
            subtitle: system.isBuiltInPerson
                ? 'Sleep fills the check-in and ticks "bed by 22:30"; HRV and resting heart rate; weigh-ins go to Health'
                : 'Sleep fills the check-in; HRV and resting heart rate; weigh-ins go to Health',
            onTap: () async {
              final err = await system.connectHealth();
              if (context.mounted) {
                toast(context, err ?? 'Connected — last 3 nights synced.');
              }
            },
          ),
        ),
      );
    }
    final today = dayOnly(DateTime.now());
    final sleep = system.logsOn(today, 'sleep');
    final vitals = system.logsOf('vitals');
    final v = vitals.isEmpty ? null : vitals.first;
    final bed = sleep.isEmpty
        ? null
        : DateTime.tryParse(sleep.last.str('bed_start') ?? '');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OnoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text('APPLE HEALTH', style: AppText.eyebrow())),
                GestureDetector(
                  onTap: () async {
                    await system.syncHealth();
                    if (context.mounted) toast(context, 'Synced.');
                  },
                  child: Text('Sync',
                      style: AppText.small(color: AppColors.accent)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        sleep.isEmpty
                            ? '—'
                            : '${sleep.last.number('asleep_h')}',
                        'asleep last night',
                        unit: 'h')),
                Expanded(
                    child: StatTile(
                        v?.number('hrv') == null ? '—' : '${v!.number('hrv')}',
                        'HRV',
                        unit: 'ms')),
                Expanded(
                    child: StatTile(
                        v?.number('rhr') == null ? '—' : '${v!.number('rhr')}',
                        'resting HR')),
              ],
            ),
            if (bed != null) ...[
              const SizedBox(height: 6),
              Text(
                  'In bed ${bed.hour.toString().padLeft(2, '0')}:${bed.minute.toString().padLeft(2, '0')}${bed.hour >= 12 && system.isChecked(dayOnly(bed), 'bed') ? ' — "bed by 22:30" ticked' : ''}',
                  style: AppText.small().copyWith(fontSize: 12)),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: system.disconnectHealth,
              child: Text('Disconnect',
                  style: AppText.small().copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Movement this week for someone without the built-in training plan.
class _MoveSummary extends StatelessWidget {
  const _MoveSummary();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    return OnoCard(
      onTap: () => context.push('/move'),
      child: Row(
        children: [
          Expanded(
              child: StatTile(
                  '${system.moveMinutesInWeek(now)}', 'of 150 min this week')),
          Expanded(
              child: StatTile(
                  '${system.strengthDaysInWeek(now)}', 'of 2 strength days')),
          if (system.latestWeight != null)
            Expanded(
                child: StatTile(
                    system.latestWeight!.toStringAsFixed(1), 'weight',
                    unit: 'kg')),
        ],
      ),
    );
  }
}

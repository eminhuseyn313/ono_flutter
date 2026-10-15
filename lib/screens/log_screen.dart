import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// LOG — the record of what actually happened, newest first, plus quick
/// entry for weight, protein, bloodwork, wins and notes.
class LogScreen extends StatefulWidget {
  final String? add;
  const LogScreen({super.key, this.add});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

const _filters = <String, Set<String>?>{
  'All': null,
  'Growth': {
    'rep',
    'feedback',
    'growth_focus',
    'coaching',
    'affirmation',
    'values_check',
    'goal_value',
    'progress_note',
    'setback',
    'quarterly_review',
    'learning',
    'experiment',
    'gratitude',
    'feedback_round',
    'wheel',
    'aar',
    'strength_use',
    'program_cycle',
    'story',
    'automaticity'
  },
  'Notes': {
    'feynman',
    'scan',
    'pennebaker',
    'note',
    'win',
    'month_review',
    'shutdown',
    'stepback',
    'thought'
  },
  'Protocols': {
    'sigh',
    'excited',
    'bluf',
    'sixq',
    'pause',
    'still',
    'ritual',
    'read',
    'anki'
  },
  'Body': {
    'weight',
    'protein',
    'gym',
    'blood',
    'checkin',
    'sleep',
    'vitals',
    'energy',
    'move',
    'rest',
    'detach',
    'hard_day'
  },
  'People': {
    'touch',
    'help',
    'partner_checkin',
    'gratitude',
    'feedback_round',
    'kindness',
    'promise',
    'ask'
  },
  'Career': {
    'linkedin',
    'artifact',
    'one_on_one',
    'decision',
    'readiness',
    'focus',
    'week_plan'
  },
};

/// Where tapping an entry goes: the screen that owns it.
const _ownerRoute = {
  'week_plan': '/week',
  'promise': '/promises',
  'checkin': '/checkin',
  'rep': '/growth',
  'feedback': '/growth',
  'growth_focus': '/growth',
  'move': '/move',
  'goal_value': '/goals',
  'learning': '/learning',
  'experiment': '/experiments',
  'rest': '/rest',
  'detach': '/rest',
  'ask': '/asks',
  'story': '/stories',
  'kindness': '/kindness',
  'touch': '/people',
  'help': '/people',
  'one_on_one': '/cockpit',
  'decision': '/cockpit?tab=1',
  'readiness': '/cockpit?tab=2',
  'shutdown': '/shutdown',
  'quarterly_review': '/quarter',
  'gratitude': '/gratitude',
  'feedback_round': '/360',
  'values_check': '/values',
  'affirmation': '/values',
  'coaching': '/coach',
  'progress_note': '/note',
  'strength_use': '/strengths',
  'partner_checkin': '/partner',
  'focus': '/focus',
  'energy': '/energy',
  'automaticity': '/habits',
  'aar': '/aar',
  'thought': '/thought',
  'stepback': '/stepback',
};

/// Records other features rely on (the week's three, the month's area, a
/// planned rest, a hard day, reviews): deleting one asks first.
const _askBeforeDelete = {
  'week_plan',
  'growth_focus',
  'rest',
  'hard_day',
  'quarterly_review',
  'month_review',
  'program_cycle',
  'wheel',
  'goal_value',
};

class _LogScreenState extends State<LogScreen> {
  String _filter = 'All';
  bool _opened = false;
  String _query = '';
  bool _all = false;

  static const _recentDays = 30;

  bool _matches(LogEntry e) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [e.text, ...e.data.values.whereType<String>()]
        .join(' ')
        .toLowerCase()
        .contains(q);
  }

  Future<void> _tap(PersonalSystemProvider system, LogEntry e) async {
    if (e.type == 'win' || e.type == 'note') {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (ctx) => _EditTextSheet(
          title: e.type == 'win' ? 'Edit the win' : 'Edit the note',
          initial: e.text,
          onSave: (t) => system.editLogText(e.id, t),
        ),
      );
      return;
    }
    final route = _ownerRoute[e.type];
    if (route != null && mounted) context.push(route);
  }

  Future<bool> _confirmDelete(LogEntry e, String label) async {
    if (!_askBeforeDelete.contains(e.type)) return true;
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Delete this $label?'),
        content: const Text(
            'Other parts of ONO use it — the week, the month or your streak.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ),
    );
    return sure == true;
  }

  void _deleted(PersonalSystemProvider system, LogEntry e) {
    system.removeLog(e.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Deleted.'),
        action: SnackBarAction(
            label: 'Undo', onPressed: () => system.restoreLog(e)),
      ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened && widget.add != null) {
      _opened = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openAdd(context, widget.add!));
    }
  }

  @override
  void didUpdateWidget(LogScreen old) {
    super.didUpdateWidget(old);
    if (widget.add != null && widget.add != old.add) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openAdd(context, widget.add!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    if (!system.isLoaded) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    // Apple Health syncs a sleep and a vitals entry every day; they live
    // under Body so the main timeline stays about what you did.
    final entries = _filters[_filter] == null
        ? system
            .allLogs()
            .where((e) => e.type != 'sleep' && e.type != 'vitals')
            // Letters stay sealed: they only show on /letters.
            .where((e) => e.type != 'letter')
            // People are a list, not events; contact with them is a touch.
            .where((e) => !const {
                  'person',
                  'values',
                  'growth_area',
                  'area_drills',
                  'goal',
                  'profile',
                  'daily_item',
                  'stop',
                  'role_model',
                  'partner',
                  'odyssey',
                  'energy_audit',
                  'best_self',
                  'conversation',
                  'money_check',
                  'upkeep',
                  'manual',
                  'us_checkin',
                  'day_shape',
                  'strengths',
                  'best_future',
                  'life_story',
                  'kindness_plan',
                  'worry',
                  'worry_plan',
                  'year_review',
                  'daily_list'
                }.contains(e.type))
            .toList()
        : system.allLogs(_filters[_filter]);
    final matching = entries.where(_matches).toList();
    // The last month by default; searching looks through everything.
    final cutoff = dayOnly(DateTime.now()).minusDays(_recentDays);
    final shown = _all || _query.trim().isNotEmpty
        ? matching
        : [for (final e in matching) if (!e.date.isBefore(cutoff)) e];
    final hidden = matching.length - shown.length;
    final byDay = <String, List<LogEntry>>{};
    for (final e in shown) {
      byDay.putIfAbsent(dateKey(e.date), () => []).add(e);
    }
    return OnoPage(
      // What the list shows, not the settings and plans behind it.
      eyebrow: entries.length == 1 ? '1 entry' : '${entries.length} entries',
      title: 'Log',
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final a in [
                ('win', Icons.emoji_events_outlined, 'Win'),
                ('note', Icons.edit_note_rounded, 'Note'),
                if (!system.isBuiltInPerson)
                  ('move', Icons.directions_walk_rounded, 'Movement'),
                ('weight', Icons.monitor_weight_outlined, 'Weight'),
                if (system.isBuiltInPerson)
                  ('protein', Icons.egg_alt_outlined, 'Protein'),
                if (system.isBuiltInPerson)
                  ('blood', Icons.bloodtype_outlined, 'Bloodwork'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(a.$2, size: 16, color: AppColors.accent),
                    label: Text(a.$3),
                    onPressed: () => a.$1 == 'move'
                        ? context.push('/move')
                        : _openAdd(context, a.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Career tools show for anyone once they've used them.
              if (system.isBuiltInPerson ||
                  system.logsOf('one_on_one').isNotEmpty ||
                  system.logsOf('decision').isNotEmpty) ...[
                LinkRow(
                  icon: Icons.work_outline_rounded,
                  color: AppColors.accent,
                  title: 'Career cockpit',
                  subtitle: '1:1s · decisions · readiness',
                  trailing:
                      '${system.openFollowUps.length + system.dueDecisionReviews(DateTime.now()).length}',
                  onTap: () => context.push('/cockpit'),
                ),
                const Divider(indent: 66),
              ],
              LinkRow(
                icon: Icons.style_rounded,
                color: AppColors.mind,
                title: 'Review deck',
                subtitle: 'Spaced repetition',
                trailing: '${system.dueCards(DateTime.now()).length}',
                onTap: () => context.push('/review'),
              ),
              if (system.isBuiltInPerson || system.evidenceCount > 0) ...[
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.steel,
                  title: 'Evidence Archive',
                  trailing: '${system.evidenceCount}',
                  onTap: () => context.push('/evidence'),
                ),
              ],
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.assignment_outlined,
                color: AppColors.accent,
                title: 'Sunday reports & briefs',
                trailing: '${system.briefs.length}',
                onTap: () => context.push('/weekly-coaching'),
              ),
              if (system.isBuiltInPerson) ...[
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.campaign_outlined,
                  color: AppColors.skill,
                  title: 'LinkedIn posts',
                  trailing: '${system.countOf('linkedin')}',
                  onTap: () => context.push('/tool/linkedin'),
                ),
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.description_outlined,
                  color: AppColors.skill,
                  title: 'Artifacts',
                  trailing: '${system.countOf('artifact')}',
                  onTap: () => context.push('/tool/artifact'),
                ),
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.school_outlined,
                  color: AppColors.mind,
                  title: 'Anki',
                  onTap: () => context.push('/tool/anki'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in _filters.keys)
                // Breathing and pause tools are anyone's; the filter shows
                // once there is something in it.
                if (f != 'Protocols' ||
                    system.isBuiltInPerson ||
                    system.allLogs(_filters[f]).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == 'Protocols' && !system.isBuiltInPerson ? 'Tools' : f),
                      selected: _filter == f,
                      showCheckmark: false,
                      selectedColor: AppColors.cardLight,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('log-search'),
          onChanged: (v) => setState(() => _query = v),
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              hintText: 'Search what you logged'),
        ),
        if (entries.isEmpty)
          const EmptyNote(
              'Nothing here yet. Wins, notes and every tool you use land in this log.')
        else if (shown.isEmpty)
          const EmptyNote('Nothing matches.'),
        for (final day in byDay.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
            child:
                Text(_dayLabel(DateTime.parse(day)), style: AppText.eyebrow()),
          ),
          OnoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(
              children: [
                for (final e in byDay[day]!)
                  Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger),
                    ),
                    confirmDismiss: (_) => _confirmDelete(
                        e, (_EntryRow._meta[e.type]?.$3 ?? 'entry').toLowerCase()),
                    onDismissed: (_) => _deleted(system, e),
                    // Swiping isn't possible for everyone: a screen reader
                    // gets Delete as an action.
                    child: Semantics(
                      customSemanticsActions: {
                        const CustomSemanticsAction(label: 'Delete'): () async {
                          if (await _confirmDelete(e,
                              (_EntryRow._meta[e.type]?.$3 ?? 'entry').toLowerCase())) {
                            _deleted(system, e);
                          }
                        },
                      },
                      child: InkWell(
                        onTap: () => _tap(system, e),
                        child: _EntryRow(
                            entry: e, builtIn: system.isBuiltInPerson),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (hidden > 0)
          Center(
            child: TextButton(
              key: const Key('log-earlier'),
              onPressed: () => setState(() => _all = true),
              child: Text('Show $hidden earlier'),
            ),
          ),
      ],
    );
  }

  String _dayLabel(DateTime d) {
    final today = dayOnly(DateTime.now());
    if (dateKey(d) == dateKey(today)) return 'TODAY';
    if (dateKey(d) == dateKey(today.minusDays(1))) {
      return 'YESTERDAY';
    }
    return '${weekdayName(d.weekday).toUpperCase()} · ${shortDate(d).toUpperCase()}';
  }
}

class _EntryRow extends StatelessWidget {
  final LogEntry entry;
  final bool builtIn;
  const _EntryRow({required this.entry, this.builtIn = true});

  static const _meta = {
    'weight': (Icons.monitor_weight_outlined, 'body', 'Weight'),
    'protein': (Icons.egg_alt_outlined, 'body', 'Protein'),
    'gym': (Icons.fitness_center_rounded, 'body', 'Gym'),
    'blood': (Icons.bloodtype_outlined, 'body', 'Bloodwork'),
    'sigh': (Icons.air_rounded, 'mind', 'Sigh'),
    'excited': (Icons.bolt_rounded, 'mind', '"I am excited"'),
    'pause': (Icons.pause_circle_outline_rounded, 'social', 'Pause'),
    'still': (Icons.accessibility_new_rounded, 'social', 'Still body'),
    'bluf': (Icons.vertical_align_top_rounded, 'skill', 'BLUF'),
    'sixq': (Icons.layers_rounded, 'skill', '6Q prep'),
    'feynman': (Icons.edit_rounded, 'skill', 'Feynman'),
    'read': (Icons.menu_book_rounded, 'skill', 'Lunch read'),
    'scan': (Icons.travel_explore_rounded, 'skill', 'Domain scan'),
    'anki': (Icons.school_outlined, 'skill', 'Anki'),
    'pennebaker': (Icons.history_edu_rounded, 'mind', 'Pennebaker'),
    'ritual': (Icons.wb_sunny_outlined, 'mind', 'Morning ritual'),
    'linkedin': (Icons.campaign_outlined, 'social', 'LinkedIn post'),
    'artifact': (Icons.description_outlined, 'skill', 'Artifact'),
    'win': (Icons.emoji_events_outlined, 'mind', 'Win'),
    'note': (Icons.edit_note_rounded, 'mind', 'Note'),
    'month_review': (Icons.fact_check_outlined, 'mind', 'Month review'),
    'checkin': (Icons.wb_twilight_rounded, 'body', 'Morning check-in'),
    'one_on_one': (Icons.forum_outlined, 'social', '1:1'),
    'sleep': (Icons.bedtime_outlined, 'body', 'Sleep · Apple Health'),
    'vitals': (Icons.monitor_heart_outlined, 'body', 'Heart · Apple Health'),
    'decision': (Icons.balance_rounded, 'skill', 'Decision'),
    'readiness': (Icons.trending_up_rounded, 'skill', 'Readiness check'),
    'automaticity': (Icons.autorenew_rounded, 'mind', 'Habit check'),
    'focus': (Icons.center_focus_strong_rounded, 'skill', 'Deep work'),
    'shutdown': (Icons.nights_stay_outlined, 'mind', 'Shutdown'),
    'week_plan': (Icons.flag_rounded, 'skill', 'The week\'s three'),
    'rep': (Icons.trending_up_rounded, 'skill', 'Practice rep'),
    'coaching': (Icons.psychology_alt_outlined, 'mind', 'Coached myself'),
    'goal_value': (Icons.straighten_rounded, 'skill', 'Goal measured'),
    'progress_note': (Icons.send_rounded, 'social', 'Progress note'),
    'quarterly_review': (Icons.donut_large_rounded, 'mind', 'Quarterly review'),
    'learning': (Icons.school_outlined, 'skill', 'Learning'),
    'experiment': (Icons.science_outlined, 'mind', 'Experiment'),
    'rest': (Icons.beach_access_outlined, 'body', 'Rest planned'),
    'gratitude': (Icons.favorite_outline_rounded, 'social', 'Gratitude letter'),
    'feedback_round': (Icons.groups_2_outlined, 'social', 'Feedback round'),
    'energy': (Icons.bolt_outlined, 'mind', 'Energy'),
    'wheel': (Icons.donut_large_rounded, 'mind', 'Life wheel'),
    'hard_day': (Icons.healing_outlined, 'body', 'Hard day'),
    'move': (Icons.directions_walk_rounded, 'body', 'Movement'),
    'help': (
      Icons.volunteer_activism_outlined,
      'social',
      'Helped someone grow'
    ),
    'stepback': (Icons.zoom_out_map_rounded, 'mind', 'Stepped back'),
    'thought': (Icons.psychology_outlined, 'mind', 'Thought check'),
    'aar': (Icons.flag_outlined, 'skill', 'After-action review'),
    'promise': (Icons.handshake_outlined, 'social', 'Promise'),
    'ask': (Icons.pan_tool_alt_outlined, 'social', 'Asked for help'),
    'story': (Icons.menu_book_outlined, 'skill', 'Story'),
    'program_cycle': (Icons.flag_circle_rounded, 'mind', 'Program closed'),
    'strength_use': (Icons.bolt_outlined, 'mind', 'Strength used'),
    'kindness': (Icons.volunteer_activism_outlined, 'social', 'Kindness'),
    'partner_checkin': (Icons.handshake_outlined, 'social', 'Partner check-in'),
    'detach': (Icons.power_settings_new_rounded, 'mind', 'Switched off'),
    'setback': (Icons.replay_rounded, 'mind', 'Setback, reset'),
    'affirmation': (Icons.diamond_outlined, 'mind', 'Values affirmation'),
    'values_check': (Icons.diamond_outlined, 'mind', 'Values check'),
    'feedback': (Icons.record_voice_over_outlined, 'social', 'Feedback'),
    'growth_focus': (Icons.track_changes_rounded, 'mind', 'Growth area'),
    'touch': (Icons.group_outlined, 'social', 'In touch'),
  };

  String get _summary {
    final e = entry;
    switch (e.type) {
      case 'weight':
        return '${e.number('kg')} kg';
      case 'protein':
        return '+${e.number('g')} g';
      case 'gym':
        final d = gymPlan.firstWhere((g) => g.id == e.str('day'),
            orElse: () => gymPlan.first);
        return 'Day ${d.letter} ${d.name} · ${((e.number('volume') ?? 0) / 1000).toStringAsFixed(1)} t${e.data['zone2'] == true ? ' · Zone 2' : ''}';
      case 'blood':
        return '${e.str('test')}: ${e.number('value')} ${e.str('unit') ?? ''}';
      case 'sixq':
        return '${e.str('meeting')} with ${e.str('with')}${e.str('outcome') == null ? '' : ' · ${e.str('outcome')}'}';
      case 'artifact':
        return '${e.str('title')} · ${e.str('status')}';
      case 'read':
        return '${e.str('book')} · 20 min';
      case 'anki':
        return e.str('kind') == 'new'
            ? '+${e.number('count')} new cards'
            : 'Daily review';
      case 'pennebaker':
        return 'Session ${e.number('session') ?? ''} · 15 min';
      case 'ritual':
        return '5 steps · ${((e.number('seconds') ?? 0) / 60).toStringAsFixed(0)} min';
      case 'month_review':
        return 'Month ${e.number('month')}: ${e.text}';
      case 'sleep':
        final bed = DateTime.tryParse(e.str('bed_start') ?? '');
        return '${e.number('asleep_h')} h asleep${bed == null ? '' : ' · in bed ${bed.hour.toString().padLeft(2, '0')}:${bed.minute.toString().padLeft(2, '0')}'}';
      case 'vitals':
        return [
          if (e.number('hrv') != null) 'HRV ${e.number('hrv')} ms',
          if (e.number('rhr') != null) 'resting HR ${e.number('rhr')}',
        ].join(' · ');
      case 'one_on_one':
        final n = ((e.data['followups'] as List?) ?? const []).length;
        return '${e.str('with') ?? activeProfile.manager} · ${e.text.isEmpty ? 'logged' : e.text}${n == 0 ? '' : ' · $n follow-ups'}';
      case 'decision':
        final v = e.str('verdict');
        return v == null ? e.text : '${e.text} · $v';
      case 'focus':
        final t = e.str('target');
        return '${e.number('minutes')} min${t == 'artifact' ? ' · artifact' : t == 'skill' ? ' · skill' : t == 'goal' ? ' · goal' : ''}';
      case 'partner_checkin':
        return 'With ${e.str('partner')}: you ${e.str('mine')}, they ${e.str('theirs')}';
      case 'promise':
        final st = e.str('status') ?? 'open';
        return '${e.text}${(e.str('to') ?? '').isEmpty ? '' : ' · to ${e.str('to')}'} · ${st == 'open' ? 'by ${e.str('by')}' : st}';
      case 'ask':
        final st = e.str('status') ?? 'asked';
        return '${e.text}${(e.str('of') ?? '').isEmpty ? '' : ' · ${e.str('of')}'} · ${st == 'asked' ? 'waiting' : st}';
      case 'program_cycle':
        return 'Program ${e.number('number')} · ${e.number('held')} of ${e.number('counted')} days held';
      case 'aar':
        final next = e.str('improve') ?? '';
        return '${e.text}${next.isEmpty ? '' : ' · next time: $next'}';
      case 'strength_use':
        return '${e.str('strength')}: ${e.text}';
      case 'thought':
        final b = e.number('before'), a = e.number('after');
        return '${e.text}${b == null || a == null ? '' : ' · $b → $a'}';
      case 'help':
        return '${e.str('name')}: ${e.text}';
      case 'move':
        return '${PersonalSystemProvider.moveKinds[e.str('kind')] ?? e.str('kind')} · ${e.number('minutes')} min${e.data['vigorous'] == true ? ' · vigorous' : ''}';
      case 'hard_day':
        return PersonalSystemProvider.hardDayKinds[e.str('kind')] ?? 'Hard day';
      case 'wheel':
        final w = (e.data['wheel'] as Map? ?? const {});
        return '${w.length} areas rated';
      case 'energy':
        return '${e.number('level')}/5 at ${e.number('hour')}:00';
      case 'feedback_round':
        final themes = e.str('themes') ?? '';
        return 'Quarter ${e.number('quarter')}${themes.isEmpty ? '' : ' · $themes'}';
      case 'gratitude':
        return 'To ${e.str('to')} · ${e.str('status') == 'delivered' ? 'delivered' : 'written'}';
      case 'rest':
        return '${e.str('kind') == 'light' ? 'Lighter week' : e.str('kind') == 'holiday' ? 'Holiday' : 'Rest day'} · ${e.str('from')}${e.str('to') == e.str('from') ? '' : ' → ${e.str('to')}'}';
      case 'detach':
        return const [
          '',
          'Not really',
          'Partly',
          'Fully'
        ][(e.number('level') ?? 0).toInt().clamp(0, 3)];
      case 'experiment':
        return '${e.text} · ${e.str('status') ?? 'running'}';
      case 'learning':
        final st = e.str('status') ?? 'queue';
        return '${e.text} · ${st == 'done' ? 'applied' : st == 'active' ? 'reading' : 'next'}';
      case 'quarterly_review':
        return 'Quarter ${e.number('quarter')}${e.text.isEmpty ? '' : ' · next: ${e.text}'}';
      case 'progress_note':
        return 'To ${e.str('to')?.isEmpty ?? true ? 'someone' : e.str('to')}';
      case 'setback':
        return '${e.text.isEmpty ? 'Reset' : e.text} → ${e.str('next')}';
      case 'goal_value':
        final v = (e.number('value') ?? 0).toDouble();
        return '${e.str('title') ?? 'Goal'} · ${v == v.roundToDouble() ? v.toInt() : v}';
      case 'coaching':
        return '${e.text} → ${e.str('will')}';
      case 'affirmation':
        final before = e.str('before') ?? '';
        return '${e.str('value')}${before.isEmpty ? '' : ' · before $before'}';
      case 'values_check':
        final r = (e.data['ratings'] as Map? ?? const {});
        return r.entries.map((x) => '${x.key} ${x.value}').join(' · ');
      case 'rep':
        final lesson = e.str('lesson') ?? '';
        return '${e.str('drill')} · ${lesson.isEmpty ? e.text : lesson}';
      case 'feedback':
        return '${e.str('from')}: "${e.text}"';
      case 'growth_focus':
        return 'Month ${e.number('month')} · ${e.str('name') ?? growthArea(e.str('area') ?? '').name}';
      case 'week_plan':
        final o = ((e.data['outcomes'] as List?) ?? const [])
            .where((x) => '$x'.trim().isNotEmpty)
            .length;
        return 'Week of ${e.date.day}/${e.date.month} · ${((e.data['done'] as List?) ?? const []).length}/$o done';
      case 'touch':
        return '${e.str('name') ?? ''}${e.text.isEmpty ? '' : ' · ${e.text}'}';
      case 'shutdown':
        final open = e.str('open') ?? '';
        return '${e.number('done')}/${e.number('set')} done${open.isEmpty ? '' : ' · $open'}';
      case 'readiness':
      case 'automaticity':
        return 'Month ${e.number('month')}';
      case 'checkin':
        final stiff = (e.number('stiffness') ?? 0).toInt();
        if (!builtIn) {
          final mood = (e.number('mood') ?? 0).toInt();
          return 'Energy ${e.number('energy')}/5 · sleep ${e.number('sleep')} h · mood ${mood > 0 ? '+$mood' : '$mood'}';
        }
        return 'Energy ${e.number('energy')}/5 · sleep ${e.number('sleep')} h · '
            'shoulders ${e.number('pain')}/10'
            '${stiff > 0 ? ' · stiff ${const [
                '',
                '<15',
                '15–30',
                '30–60',
                '60+'
              ][stiff.clamp(0, 4)]} min' : ''}';
      default:
        final extra = e.str('outcome');
        final t = e.text.isEmpty ? 'Logged' : e.text;
        return extra == null ? t : '$t · $extra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta[entry.type] ?? (Icons.circle_outlined, 'mind', entry.type);
    final time =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(m.$1, size: 18, color: AppColors.lane(m.$2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.$3,
                    style: AppText.small(color: AppColors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small(color: AppColors.greyLight)),
              ],
            ),
          ),
          Text(time, style: AppText.small().copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Bottom-sheet entry forms, also used from Today and Program.
Future<void> _openAdd(BuildContext context, String kind) async {
  final system = context.read<PersonalSystemProvider>();
  final a = TextEditingController();
  var test = bloodwork.first;
  var toEvidence = true;
  var section = 'built';

  const units = {
    'Ferritin': 'ng/mL',
    'Hemoglobin': 'g/dL',
    'Vitamin D': 'ng/mL',
    'Testosterone': 'ng/dL',
    'TSH': 'mIU/L',
  };

  final title = switch (kind) {
    'weight' => 'Weigh-in',
    'protein' => 'Protein',
    'blood' => 'Bloodwork result',
    'win' => 'A win from today',
    _ => 'Note',
  };

  await showModalBottomSheet<void>(
      useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title()),
            const SizedBox(height: 16),
            if (kind == 'weight')
              TextField(
                controller: a,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppText.number(size: 22),
                decoration: InputDecoration(
                    suffixText: 'kg',
                    hintText: system.latestWeight?.toStringAsFixed(1)),
              ),
            if (kind == 'protein') ...[
              TextField(
                controller: a,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppText.number(size: 22),
                decoration: const InputDecoration(suffixText: 'g'),
              ),
              const SizedBox(height: 8),
              Text('${system.proteinFor(DateTime.now())} g so far today',
                  style: AppText.small()),
            ],
            if (kind == 'blood') ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in bloodwork)
                    ChoiceChip(
                      label: Text(t),
                      selected: test == t,
                      onSelected: (_) => set(() => test = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: a,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppText.number(size: 22),
                decoration: InputDecoration(suffixText: units[test]),
              ),
            ],
            if (kind == 'win' || kind == 'note') ...[
              TextField(
                controller: a,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                style: AppText.body(color: AppColors.white),
                decoration: InputDecoration(
                    hintText: kind == 'win'
                        ? 'What you did, where, and what it changed.'
                        : 'Anything worth keeping.'),
              ),
              if (kind == 'win') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: toEvidence,
                  onChanged: (v) => set(() => toEvidence = v),
                  title: Text('Also add to the Evidence Archive',
                      style: AppText.body()),
                ),
                if (toEvidence)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final s in context
                          .read<PersonalSystemProvider>()
                          .activeEvidenceSections)
                        ChoiceChip(
                          label: Text(s.title),
                          selected: section == s.section,
                          onSelected: (_) => set(() => section = s.section),
                        ),
                    ],
                  ),
              ],
            ],
            const SizedBox(height: 18),
            PrimaryButton('Save', onPressed: () {
              final now = DateTime.now();
              final num = double.tryParse(a.text.replaceAll(',', '.'));
              switch (kind) {
                case 'weight':
                  if (num == null || !system.logWeight(num)) {
                    toast(ctx, 'That weight looks off — check the number.');
                    return;
                  }
                case 'protein':
                  if (num == null || !system.addProtein(now, num.round())) {
                    toast(ctx, 'Enter grams between 1 and 500.');
                    return;
                  }
                case 'blood':
                  if (num == null) return;
                  system.addLog('blood',
                      data: {'test': test, 'value': num, 'unit': units[test]});
                case 'win':
                  if (a.text.trim().isEmpty) return;
                  system.addLog('win', text: a.text.trim());
                  if (toEvidence) system.addEvidence(section, a.text.trim());
                default:
                  if (a.text.trim().isEmpty) return;
                  system.addLog('note', text: a.text.trim());
              }
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    ),
  );
  // Not disposed here: the sheet's closing animation still reads them, and
  // nothing else listens to them, so they are simply collected.
}

/// Edits an entry's text; owns its controller, so closing the sheet
/// never touches a disposed one.
class _EditTextSheet extends StatefulWidget {
  final String title;
  final String initial;
  final void Function(String) onSave;
  const _EditTextSheet(
      {required this.title, required this.initial, required this.onSave});

  @override
  State<_EditTextSheet> createState() => _EditTextSheetState();
}

class _EditTextSheetState extends State<_EditTextSheet> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppText.title()),
            const SizedBox(height: 12),
            TextField(
              key: const Key('log-edit'),
              controller: _c,
              minLines: 2,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
            ),
            const SizedBox(height: 14),
            PrimaryButton('Save', onPressed: () {
              widget.onSave(_c.text);
              Navigator.pop(context);
            }),
          ],
        ),
      );
}

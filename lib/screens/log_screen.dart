import 'package:flutter/material.dart';
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
  'Growth': {'rep', 'feedback', 'growth_focus', 'coaching', 'affirmation', 'values_check', 'goal_value', 'progress_note', 'setback', 'quarterly_review', 'learning', 'experiment', 'rest', 'detach', 'gratitude', 'feedback_round', 'wheel'},
  'Notes': {'feynman', 'scan', 'pennebaker', 'note', 'win', 'month_review', 'shutdown'},
  'Protocols': {'sigh', 'excited', 'bluf', 'sixq', 'pause', 'still', 'ritual', 'read', 'anki'},
  'Body': {'weight', 'protein', 'gym', 'blood', 'checkin', 'sleep', 'vitals', 'energy'},
  'Career': {'linkedin', 'artifact', 'one_on_one', 'decision', 'readiness', 'focus', 'week_plan', 'touch'},
};

class _LogScreenState extends State<LogScreen> {
  String _filter = 'All';
  bool _opened = false;

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
            .where((e) => !const {'person', 'values', 'growth_area', 'area_drills', 'goal', 'profile', 'daily_item', 'stop', 'role_model'}
                .contains(e.type))
            .toList()
        : system.allLogs(_filters[_filter]);
    final byDay = <String, List<LogEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(dateKey(e.date), () => []).add(e);
    }
    return OnoPage(
      eyebrow: system.allLogs().length == 1
          ? '1 entry'
          : '${system.allLogs().length} entries',
      title: 'Log',
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final a in const [
                ('weight', Icons.monitor_weight_outlined, 'Weight'),
                ('protein', Icons.egg_alt_outlined, 'Protein'),
                ('win', Icons.emoji_events_outlined, 'Win'),
                ('note', Icons.edit_note_rounded, 'Note'),
                ('blood', Icons.bloodtype_outlined, 'Bloodwork'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(a.$2, size: 16, color: AppColors.accent),
                    label: Text(a.$3),
                    onPressed: () => _openAdd(context, a.$1),
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
              LinkRow(
                icon: Icons.work_outline_rounded,
                color: AppColors.accent,
                title: 'Career cockpit',
                subtitle: '1:1s · decisions · readiness',
                trailing: '${system.openFollowUps.length + system.dueDecisionReviews(DateTime.now()).length}',
                onTap: () => context.push('/cockpit'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.style_rounded,
                color: AppColors.mind,
                title: 'Review deck',
                subtitle: 'Spaced repetition',
                trailing: '${system.dueCards(DateTime.now()).length}',
                onTap: () => context.push('/review'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.inventory_2_outlined,
                color: AppColors.steel,
                title: 'Evidence Archive',
                trailing: '${system.evidenceCount}',
                onTap: () => context.push('/evidence'),
              ),
              const Divider(indent: 66),
              LinkRow(
                icon: Icons.assignment_outlined,
                color: AppColors.accent,
                title: 'Sunday reports & briefs',
                trailing: '${system.briefs.length}',
                onTap: () => context.push('/weekly-coaching'),
              ),
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
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in _filters.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
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
        if (entries.isEmpty)
          const EmptyNote(
              'Nothing here yet. Every tool you use — sigh, BLUF, Feynman, gym — lands in this log.'),
        for (final day in byDay.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
            child: Text(_dayLabel(DateTime.parse(day)),
                style: AppText.eyebrow()),
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
                    onDismissed: (_) => system.removeLog(e.id),
                    child: _EntryRow(entry: e),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _dayLabel(DateTime d) {
    final today = dayOnly(DateTime.now());
    if (dateKey(d) == dateKey(today)) return 'TODAY';
    if (dateKey(d) == dateKey(today.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return '${weekdayName(d.weekday).toUpperCase()} · ${shortDate(d).toUpperCase()}';
  }
}

class _EntryRow extends StatelessWidget {
  final LogEntry entry;
  const _EntryRow({required this.entry});

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
    'week_plan': (Icons.flag_rounded, 'skill', 'Big 3'),
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
        return '${e.number('minutes')} min${t == 'artifact' ? ' · artifact' : t == 'skill' ? ' · skill' : ''}';
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
        return const ['', 'Not really', 'Partly', 'Fully'][(e.number('level') ?? 0).toInt().clamp(0, 3)];
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
        return 'Energy ${e.number('energy')}/5 · sleep ${e.number('sleep')} h · '
            'shoulders ${e.number('pain')}/10'
            '${stiff > 0 ? ' · stiff ${const ['', '<15', '15–30', '30–60', '60+'][stiff.clamp(0, 4)]} min' : ''}';
      default:
        final extra = e.str('outcome');
        final t = e.text.isEmpty ? 'Logged' : e.text;
        return extra == null ? t : '$t · $extra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta[entry.type] ??
        (Icons.circle_outlined, 'mind', entry.type);
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
  final b = TextEditingController();
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
                    hintText: system.latestWeight?.toStringAsFixed(1) ?? '83'),
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
                      for (final s in evidenceSections)
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
                  if (num == null) return;
                  system.logWeight(num);
                case 'protein':
                  if (num == null) return;
                  system.addProtein(now, num.round());
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
  a.dispose();
  b.dispose();
}

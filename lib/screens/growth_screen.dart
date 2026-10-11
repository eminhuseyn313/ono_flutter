import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../data/growth_templates.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The growth plan: one area a month, practised on real work, each rep
/// reflected on, with feedback from someone who sees it.
class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final area = system.focusArea();
    return OnoPage(
      showBack: true,
      eyebrow: 'Month ${system.programMonth} · growth plan',
      title: area?.name ?? 'Choose what to grow',
      subtitle: area?.bar ??
          'One area a month. Practise it on your real work, reflect on every rep, and ask someone who sees you do it.',
      children: area == null
          ? [_Chooser(suggested: system.suggestedArea.id)]
          : [_Plan(area: area)],
    );
  }
}

class _Chooser extends StatefulWidget {
  final String suggested;
  final String? current;
  const _Chooser({required this.suggested, this.current});

  @override
  State<_Chooser> createState() => _ChooserState();
}

class _ChooserState extends State<_Chooser> {
  late String _area = widget.current ?? widget.suggested;
  int _rating = 2;

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    Widget group(String title, List<GrowthArea> areas) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title),
            OnoCard(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Column(
                children: [
                  for (final a in areas)
                    InkWell(
                      key: Key('area-${a.id}'),
                      onTap: () => setState(() => _area = a.id),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                _area == a.id
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: _area == a.id
                                    ? AppColors.accent
                                    : AppColors.faint),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      a.id == widget.suggested
                                          ? '${a.name} · suggested'
                                          : a.name,
                                      style: AppText.heading()),
                                  Text(a.bar, style: AppText.small()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (system.isBuiltInPerson) ...[
          group('Career · ${activeProfile.targetRole}',
              growthAreas.where((a) => !a.personal).toList()),
          group('Personal', growthAreas.where((a) => a.personal).toList()),
        ],
        if (system.customAreas.isNotEmpty)
          group('Your own areas', system.customAreas),
        if (!system.isBuiltInPerson)
          group('Start from a template', [
            for (final t in areaTemplates)
              if (!system.customAreas.any((a) => a.name == t.name)) t
          ]),
        const SizedBox(height: 8),
        GhostButton('Create your own area',
            icon: Icons.add_rounded,
            onPressed: () => context.push('/growth/area')),
        const SectionHeader('Where are you now?'),
        Text('Pick the description that sounds like you today.',
            style: AppText.small()),
        const SizedBox(height: 8),
        _RatingRow(
            value: _rating,
            levels: levelsOf(system.areaById(_area)),
            onChanged: (v) => setState(() => _rating = v)),
        const SizedBox(height: 16),
        PrimaryButton('Grow this for month ${system.programMonth}',
            icon: Icons.trending_up_rounded, onPressed: () {
          system.focusOn(_area, startRating: _rating);
          HapticFeedback.mediumImpact();
          if (Navigator.of(context).canPop() && widget.current != null) {
            Navigator.of(context).pop();
          }
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  /// Level descriptions; the selected one shows under the chips.
  final List<String> levels;
  const _RatingRow(
      {required this.value, required this.onChanged, this.levels = const []});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$i'),
                    selected: value == i,
                    showCheckmark: false,
                    onSelected: (_) => onChanged(i),
                  ),
                ),
            ],
          ),
          if (levels.length == 5 && value >= 1 && value <= 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('$value · ${levels[value - 1]}',
                  key: const Key('level-description'),
                  style: AppText.small(color: AppColors.greyLight)),
            ),
        ],
      );
}

class _Plan extends StatelessWidget {
  final GrowthArea area;
  const _Plan({required this.area});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final drill = system.drillFor(area, now);
    final reps = system.repsIn(area.id, system.programMonth);
    final feedback = system.feedbackIn(area.id, system.programMonth);
    final (start, end) = system.focusRatings();
    final practised = reps.map((r) => r.str('drill')).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: StatTile('${reps.length}', 'reps this month')),
            Expanded(child: StatTile('${feedback.length}', 'feedback asked')),
            Expanded(
                child: StatTile(
                    end == null ? '${start ?? '–'}' : '$start→$end',
                    end == null ? 'start rating' : 'start → now')),
          ],
        ),
        const SectionHeader('This week\'s drill'),
        OnoCard(
          accent: AppColors.accent,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(drill.title, style: AppText.heading()),
              const SizedBox(height: 6),
              Text(drill.how, style: AppText.body(color: AppColors.white)),
              const SizedBox(height: 8),
              Text('You\'ll know it worked: ${drill.signal}',
                  style: AppText.small(color: AppColors.body)),
              const SizedBox(height: 12),
              PrimaryButton('I did it — reflect',
                  icon: Icons.edit_note_rounded,
                  onPressed: () => _repSheet(context, system, drill)),
            ],
          ),
        ),
        if (reps.isNotEmpty) ...[
          const SectionHeader('What you\'re learning'),
          for (final r in reps.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.str('drill')} · ${shortDate(r.date)}',
                        style: AppText.eyebrow()),
                    const SizedBox(height: 4),
                    Text(
                        (r.str('lesson') ?? '').isNotEmpty
                            ? r.str('lesson')!
                            : r.text,
                        style: AppText.body(color: AppColors.white)),
                    if ((r.str('next') ?? '').isNotEmpty)
                      Text('Next time: ${r.str('next')}',
                          style: AppText.small()),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('Ask for feedback'),
        OnoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ask one person who sees you do it:',
                  style: AppText.small()),
              const SizedBox(height: 6),
              Text('"${area.ask}"',
                  style: AppText.serif(size: 20, color: AppColors.white)),
              const SizedBox(height: 6),
              Text('Then just listen. Say thank you, not "but".',
                  style: AppText.small()),
              const SizedBox(height: 10),
              GhostButton('Log what they said',
                  icon: Icons.record_voice_over_outlined,
                  onPressed: () => _feedbackSheet(context, system)),
              for (final f in feedback.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      '${f.str('from')}: "${f.text}"${(f.str('action') ?? '').isEmpty ? '' : ' → ${f.str('action')}'}',
                      style: AppText.small(color: AppColors.greyLight)),
                ),
            ],
          ),
        ),
        const SectionHeader('All drills'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Column(
            children: [
              for (final d in system.drillsOf(area))
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  leading: Icon(
                      practised.contains(d.title)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: practised.contains(d.title)
                          ? AppColors.accent
                          : AppColors.faint),
                  title: Text(d.title, style: AppText.body(color: AppColors.white)),
                  childrenPadding: const EdgeInsets.fromLTRB(0, 0, 8, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.how, style: AppText.small(color: AppColors.greyLight)),
                    const SizedBox(height: 4),
                    Text('Signal: ${d.signal}', style: AppText.small()),
                    TextButton(
                      onPressed: () => _repSheet(context, system, d),
                      child: const Text('Log a rep'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _addDrillSheet(context, system),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add your own drill'),
            ),
            const Spacer(),
            if (area.custom)
              TextButton(
                onPressed: () => context.push('/growth/area?id=${area.id}'),
                child: const Text('Edit area'),
              ),
          ],
        ),
        const SectionHeader('End of the month'),
        OnoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate yourself again against the bar. The gap is what you grew.',
                  style: AppText.small()),
              const SizedBox(height: 8),
              _RatingRow(
                  value: end ?? 0,
                  levels: levelsOf(area),
                  onChanged: (v) {
                    system.rateFocusEnd(v);
                    toast(context, start == null || v <= start
                        ? 'Rated $v. Keep this area next month if it isn\'t moving yet.'
                        : 'Up ${v - start} since the start of the month.');
                  }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => _changeArea(context, system),
            child: const Text('Change this month\'s area'),
          ),
        ),
        if (system.growthHistory.length > 1) ...[
          const SectionHeader('Earlier months'),
          for (final h in system.growthHistory
              .where((h) => h.number('month') != system.programMonth))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  'Month ${h.number('month')} · ${system.areaById(h.str('area') ?? '').name} · '
                  '${h.number('start') ?? '–'} → ${h.number('end') ?? '–'} · '
                  '${system.repsIn(h.str('area') ?? '', (h.number('month') ?? 0).toInt()).length} reps',
                  style: AppText.small(color: AppColors.greyLight)),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _addDrillSheet(BuildContext context, PersonalSystemProvider system) {
    final c = List.generate(3, (_) => TextEditingController());
    const hints = ['Drill name', 'What exactly to do', 'How you\'ll know it worked'];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your own drill', style: AppText.title()),
            for (var i = 0; i < 3; i++) ...[
              const SizedBox(height: 8),
              TextField(
                controller: c[i],
                minLines: i == 1 ? 2 : 1,
                maxLines: i == 1 ? 4 : 2,
                style: AppText.body(color: AppColors.white),
                decoration: InputDecoration(hintText: hints[i]),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton('Add drill', icon: Icons.check_rounded, onPressed: () {
              if (c[0].text.trim().isEmpty) {
                toast(ctx, 'Name the drill first.');
                return;
              }
              system.addDrill(area,
                  Drill(c[0].text.trim(), c[1].text.trim(), c[2].text.trim()));
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    ).whenComplete(() {
      for (final x in c) {
        x.dispose();
      }
    });
  }

  void _changeArea(BuildContext context, PersonalSystemProvider system) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: system,
        child: OnoPage(
          showBack: true,
          eyebrow: 'Month ${system.programMonth}',
          title: 'Change area',
          children: [
            _Chooser(suggested: system.suggestedArea.id, current: area.id),
          ],
        ),
      ),
    ));
  }

  void _repSheet(
      BuildContext context, PersonalSystemProvider system, Drill drill) {
    final c = List.generate(4, (_) => TextEditingController());
    const prompts = [
      ('What did you do?', 'The situation, briefly'),
      ('What did you notice?', 'In them, in you — what actually happened'),
      ('The lesson', 'One sentence you\'d tell a younger PO'),
      ('Next time I will…', 'One specific change'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(drill.title, style: AppText.title()),
              for (var i = 0; i < 4; i++) ...[
                const SizedBox(height: 10),
                Text(prompts[i].$1, style: AppText.small(color: AppColors.white)),
                const SizedBox(height: 4),
                TextField(
                  controller: c[i],
                  minLines: 1,
                  maxLines: 3,
                  style: AppText.body(color: AppColors.white),
                  decoration: InputDecoration(hintText: prompts[i].$2),
                ),
              ],
              const SizedBox(height: 14),
              PrimaryButton('Save the rep', icon: Icons.check_rounded,
                  onPressed: () {
                if (c[0].text.trim().isEmpty) {
                  toast(ctx, 'Write what you did first.');
                  return;
                }
                system.logRep(area, drill,
                    did: c[0].text,
                    noticed: c[1].text,
                    lesson: c[2].text,
                    next: c[3].text);
                Navigator.of(ctx).pop();
                HapticFeedback.mediumImpact();
                toast(context, 'Rep saved. That\'s how the bar moves.');
              }),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      for (final x in c) {
        x.dispose();
      }
    });
  }

  void _feedbackSheet(BuildContext context, PersonalSystemProvider system) {
    final from = TextEditingController();
    final said = TextEditingController();
    final action = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Feedback', style: AppText.title()),
              const SizedBox(height: 10),
              TextField(
                  controller: from,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(hintText: 'From whom')),
              const SizedBox(height: 8),
              TextField(
                  controller: said,
                  minLines: 2,
                  maxLines: 4,
                  style: AppText.body(color: AppColors.white),
                  decoration:
                      const InputDecoration(hintText: 'What they said, in their words')),
              const SizedBox(height: 8),
              TextField(
                  controller: action,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'What you\'ll do with it')),
              const SizedBox(height: 14),
              PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
                if (said.text.trim().isEmpty) {
                  toast(ctx, 'Write what they said first.');
                  return;
                }
                system.logFeedback(area,
                    from: from.text.trim().isEmpty ? 'Someone' : from.text,
                    said: said.text,
                    action: action.text);
                Navigator.of(ctx).pop();
                toast(context, 'Saved. Thank them — then act on one thing.');
              }),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      from.dispose();
      said.dispose();
      action.dispose();
    });
  }
}

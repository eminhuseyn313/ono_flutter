import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Odyssey plan: three five-year lives, rated the same way, then one small
/// prototype to test the one you lean towards.
class OdysseyScreen extends StatefulWidget {
  const OdysseyScreen({super.key});

  @override
  State<OdysseyScreen> createState() => _OdysseyScreenState();
}

class _OdysseyScreenState extends State<OdysseyScreen> {
  final _titles = List.generate(3, (_) => TextEditingController());
  final _stories = List.generate(3, (_) => TextEditingController());
  final _ratings = List.generate(3, (_) => <String, int>{});
  final _prototype = TextEditingController();
  int? _leaning;
  bool _loaded = false;
  int _saves = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final lives = system.odysseyLives;
    for (var i = 0; i < 3; i++) {
      _titles[i].text = '${lives[i]['title'] ?? ''}';
      _stories[i].text = '${lives[i]['story'] ?? ''}';
      for (final k in PersonalSystemProvider.odysseyGauges.keys) {
        final v = lives[i][k];
        if (v is num) _ratings[i][k] = v.toInt();
      }
    }
    _leaning = system.odyssey?.number('leaning')?.toInt();
    _prototype.text = system.odyssey?.str('prototype') ?? '';
  }

  @override
  void dispose() {
    for (final c in [..._titles, ..._stories, _prototype]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(PersonalSystemProvider system) {
    system.saveOdyssey([
      for (var i = 0; i < 3; i++)
        {'title': _titles[i].text.trim(), 'story': _stories[i].text.trim(), ..._ratings[i]}
    ], leaning: _leaning, prototype: _prototype.text);
    setState(() => _saves++);
    FocusManager.instance.primaryFocus?.unfocus();
    toast(context, 'Saved. Come back to it each quarter.');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return UnsavedGuard(
        changesOnly: true,
        saves: _saves,
        fields: [..._titles, ..._stories, _prototype],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Odyssey plan · 20 minutes',
      title: 'Three possible lives',
      subtitle:
          'Sketch three different next five years. Not a decision — a way to see your options before the default picks for you.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () => _save(system)),
      children: [
        for (var i = 0; i < 3; i++) ...[
          SectionHeader('${i + 1} · ${PersonalSystemProvider.odysseyPrompts[i]}'),
          OnoCard(
            highlight: _leaning == i,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titles[i],
                  style: AppText.heading(),
                  decoration: const InputDecoration(hintText: 'A six-word title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _stories[i],
                  minLines: 2,
                  maxLines: 5,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'What you do, where, with whom — and what a good Tuesday looks like'),
                ),
                const SizedBox(height: 8),
                for (final g in PersonalSystemProvider.odysseyGauges.entries) ...[
                  Text(g.value, style: AppText.small()),
                  const SizedBox(height: 4),
                  Segmented(
                    labels: const ['1', '2', '3', '4', '5'],
                    index: (_ratings[i][g.key] ?? 0) - 1,
                    onChanged: (v) => setState(() => _ratings[i][g.key] = v + 1),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton.icon(
                  onPressed: () => setState(() => _leaning = _leaning == i ? null : i),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: Icon(_leaning == i ? Icons.star_rounded : Icons.star_outline_rounded, size: 18),
                  label: Text(_leaning == i ? 'Leaning towards this one' : 'I lean towards this one'),
                ),
              ],
            ),
          ),
        ],
        const SectionHeader('Next: one small prototype'),
        TextField(
          controller: _prototype,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'A conversation with someone living it, or a weekend trying it'),
        ),
        if (_leaning != null && _titles[_leaning!].text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          GhostButton('Make it a goal', icon: Icons.flag_outlined, onPressed: () {
            _save(system);
            context.push('/goals/edit?title=${Uri.encodeComponent(_titles[_leaning!].text.trim())}');
          }),
        ],
        const SizedBox(height: 16),
      ],
    ));
  }
}

/// What gives and drains energy in a normal week, and one crafting move.
class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key});

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen> {
  final List<({TextEditingController name, int energy})> _rows = [];
  String? _craft;
  String _move = 'reshape';
  final _how = TextEditingController();
  bool _loaded = false;
  int _saves = 0;

  static const _energyLabels = ['Drains', 'Tires', 'Neutral', 'Lifts', 'Energises'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final a = system.energyAudit ?? system.latestEnergyAudit;
    if (a != null) {
      for (final x in system.auditActivities(a)) {
        _rows.add((name: TextEditingController(text: x.name), energy: x.energy));
      }
      _craft = (a.str('craft') ?? '').isEmpty ? null : a.str('craft');
      _move = a.str('move') ?? 'reshape';
      _how.text = a.str('how') ?? '';
    }
    while (_rows.length < 3) {
      _rows.add((name: TextEditingController(), energy: 0));
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.name.dispose();
    }
    _how.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final names = [
      for (final r in _rows)
        if (r.name.text.trim().isNotEmpty) r.name.text.trim()
    ];
    return UnsavedGuard(
        changesOnly: true,
        saves: _saves,
        fields: [_how, for (final r in _rows) r.name],
        child: OnoPage(
      showBack: true,
      eyebrow: 'Quarter ${system.programQuarter} · energy audit',
      title: 'What gives and drains you',
      subtitle:
          'List what fills a normal week — at work and at home. Rate each one. Then change one thing: you shape the work, not only the other way round.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        system.saveEnergyAudit(
            [for (final r in _rows) (name: r.name.text, energy: r.energy)],
            craftActivity: _craft ?? '',
            craftMove: _move,
            craftHow: _how.text);
        setState(() => _saves++);
        FocusManager.instance.primaryFocus?.unfocus();
        toast(context, 'Saved. Your move goes into the Sunday brief.');
      }),
      children: [
        const SectionHeader('A normal week'),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _rows[i].name,
                    onChanged: (_) => setState(() {}),
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(
                        hintText: 'e.g. Weekly status meeting, school run, emails'),
                  ),
                  const SizedBox(height: 8),
                  Segmented(
                    labels: const ['−2', '−1', '0', '+1', '+2'],
                    index: _rows[i].energy + 2,
                    onChanged: (v) => setState(() => _rows[i] = (name: _rows[i].name, energy: v - 2)),
                  ),
                  const SizedBox(height: 4),
                  Text(_energyLabels[_rows[i].energy + 2], style: AppText.small()),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: _rows.length >= 12
              ? null
              : () => setState(() => _rows.add((name: TextEditingController(), energy: 0))),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add an activity'),
        ),
        if (names.isNotEmpty) ...[
          const SectionHeader('One crafting move'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in names)
                ChoiceChip(
                  label: Text(n),
                  selected: _craft == n,
                  onSelected: (_) => setState(() => _craft = n),
                ),
            ],
          ),
          if (_craft != null) ...[
            const SizedBox(height: 10),
            for (final m in PersonalSystemProvider.craftMoves.entries)
              CheckRow(
                checked: _move == m.key,
                title: m.value,
                onChanged: (_) => setState(() => _move = m.key),
              ),
            TextField(
              controller: _how,
              minLines: 2,
              maxLines: 4,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'How, exactly — starting this week'),
            ),
          ],
        ],
        const SizedBox(height: 16),
      ],
    ));
  }
}

/// Reflected best self: stories from people who saw you at your best,
/// the themes across them, and a portrait in your own words.
class BestSelfScreen extends StatefulWidget {
  const BestSelfScreen({super.key});

  @override
  State<BestSelfScreen> createState() => _BestSelfScreenState();
}

class _BestSelfScreenState extends State<BestSelfScreen> {
  final _themes = TextEditingController();
  final _portrait = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final b = context.read<PersonalSystemProvider>().bestSelf;
    _themes.text = b?.str('themes') ?? '';
    _portrait.text = b?.str('portrait') ?? '';
  }

  @override
  void dispose() {
    _themes.dispose();
    _portrait.dispose();
    super.dispose();
  }

  void _addStory(PersonalSystemProvider system) {
    final from = TextEditingController();
    final story = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Their story', style: AppText.title()),
            const SizedBox(height: 10),
            TextField(
              controller: from,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Who told it'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: story,
              minLines: 3,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'In their words'),
            ),
            const SizedBox(height: 12),
            PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              system.addBestSelfStory(from.text, story.text);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final stories = system.bestSelfStories();
    return OnoPage(
      showBack: true,
      eyebrow: 'Reflected best self',
      title: 'You, at your best',
      subtitle:
          'Ask a few people who know you in different parts of life for one story of you at your best. Strengths you can\'t see yourself become something to stand on.',
      children: [
        const SizedBox(height: 14),
        GhostButton('Copy the ask', icon: Icons.copy_rounded, onPressed: () {
          Clipboard.setData(const ClipboardData(text: PersonalSystemProvider.bestSelfAsk));
          toast(context, 'Copied. Send it to three to five people.');
        }),
        SectionHeader('Stories · ${stories.length}', action: 'Add', onAction: () => _addStory(system)),
        if (stories.isEmpty)
          Text('When someone answers, save their story here in their words.',
              style: AppText.small()),
        for (var i = 0; i < stories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 4, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stories[i].from.isEmpty ? 'Someone' : stories[i].from,
                            style: AppText.heading()),
                        Text('"${stories[i].story}"', style: AppText.body(color: AppColors.white)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.faint,
                    onPressed: () => system.removeBestSelfStory(i),
                  ),
                ],
              ),
            ),
          ),
        if (stories.length >= 2) ...[
          const SectionHeader('What repeats'),
          TextField(
            controller: _themes,
            minLines: 2,
            maxLines: 4,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'The strengths that show up in more than one story'),
          ),
          const SectionHeader('Your portrait'),
          TextField(
            controller: _portrait,
            minLines: 3,
            maxLines: 6,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'When I\'m at my best, I…'),
          ),
          const SizedBox(height: 10),
          PrimaryButton('Save the portrait', icon: Icons.check_rounded, onPressed: () {
            system.saveBestSelfPortrait(themes: _themes.text, portrait: _portrait.text);
            FocusManager.instance.primaryFocus?.unfocus();
            toast(context, 'Saved. It will be there on hard days.');
          }),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

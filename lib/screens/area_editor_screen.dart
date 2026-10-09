import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../data/growth_templates.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Create or edit a growth area: what you're growing, what good looks
/// like, who to ask, and the drills that get you there. Templates are a
/// starting point; everything stays editable.
class AreaEditorScreen extends StatefulWidget {
  final String? areaId;
  final String? templateId;
  const AreaEditorScreen({super.key, this.areaId, this.templateId});

  @override
  State<AreaEditorScreen> createState() => _AreaEditorScreenState();
}

class _DrillFields {
  final TextEditingController title;
  final TextEditingController how;
  final TextEditingController signal;
  _DrillFields(Drill d)
      : title = TextEditingController(text: d.title),
        how = TextEditingController(text: d.how),
        signal = TextEditingController(text: d.signal);
  void dispose() {
    title.dispose();
    how.dispose();
    signal.dispose();
  }

  Drill get drill => Drill(title.text.trim(), how.text.trim(), signal.text.trim());
}

class _AreaEditorScreenState extends State<AreaEditorScreen> {
  final _name = TextEditingController();
  final _bar = TextEditingController();
  final _ask = TextEditingController();
  final List<_DrillFields> _drills = [];
  final _levels = List.generate(5, (_) => TextEditingController());
  bool _personal = true;
  String _id = '';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    GrowthArea? start;
    if (widget.areaId != null) {
      final a = system.areaById(widget.areaId!);
      if (a.custom) start = a;
    } else if (widget.templateId != null) {
      start = areaTemplates.where((t) => t.id == widget.templateId).firstOrNull;
    }
    if (start != null) _fill(start, keepId: widget.areaId != null);
    if (_drills.isEmpty) _drills.add(_DrillFields(const Drill('', '', '')));
  }

  void _fill(GrowthArea a, {bool keepId = false}) {
    _id = keepId ? a.id : '';
    _name.text = a.name;
    _bar.text = a.bar;
    _ask.text = a.ask;
    _personal = a.personal;
    for (var i = 0; i < 5; i++) {
      _levels[i].text = a.levels.length == 5 ? a.levels[i] : '';
    }
    for (final d in _drills) {
      d.dispose();
    }
    _drills
      ..clear()
      ..addAll(a.drills.map(_DrillFields.new));
  }

  @override
  void dispose() {
    _name.dispose();
    _bar.dispose();
    _ask.dispose();
    for (final d in _drills) {
      d.dispose();
    }
    for (final l in _levels) {
      l.dispose();
    }
    super.dispose();
  }

  void _save() {
    final drills = [
      for (final d in _drills)
        if (d.title.text.trim().isNotEmpty) d.drill
    ];
    if (_name.text.trim().isEmpty || drills.isEmpty) {
      toast(context, 'Give it a name and at least one drill.');
      return;
    }
    final system = context.read<PersonalSystemProvider>();
    system.saveCustomArea(GrowthArea(_id, _name.text.trim(),
        bar: _bar.text.trim(),
        ask: _ask.text.trim().isEmpty
            ? 'What\'s one thing I could do better here?'
            : _ask.text.trim(),
        drills: drills,
        personal: _personal,
        custom: true,
        levels: _levels.every((l) => l.text.trim().isNotEmpty)
            ? [for (final l in _levels) l.text.trim()]
            : const []));
    toast(context, 'Saved. Choose it on the growth plan when it\'s the month.');
    context.canPop() ? context.pop() : context.go('/growth');
  }

  TextField _field(TextEditingController c, String hint, {int lines = 1}) =>
      TextField(
        controller: c,
        minLines: lines,
        maxLines: lines + 2,
        style: AppText.body(color: AppColors.white),
        decoration: InputDecoration(hintText: hint),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    final editing = _id.isNotEmpty;
    return OnoPage(
      showBack: true,
      eyebrow: editing ? 'Your area' : 'New growth area',
      title: editing ? 'Edit area' : 'What do you want to grow?',
      subtitle:
          'Anything: a skill at work, a sport, a relationship, your health, your inner life. Be specific about what good looks like.',
      bottomBar: PrimaryButton('Save area', icon: Icons.check_rounded, onPressed: _save),
      children: [
        if (!editing) ...[
          const SectionHeader('Start from a template'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in areaTemplates)
                ActionChip(
                  label: Text(t.name),
                  onPressed: () => setState(() => _fill(t)),
                ),
            ],
          ),
        ],
        const SectionHeader('The area'),
        _field(_name, 'e.g. Marathon under 4 hours, Patience with my kids'),
        const SizedBox(height: 10),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Life'),
              selected: _personal,
              showCheckmark: false,
              onSelected: (_) => setState(() => _personal = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Work'),
              selected: !_personal,
              showCheckmark: false,
              onSelected: (_) => setState(() => _personal = false),
            ),
          ],
        ),
        const SectionHeader('What good looks like'),
        _field(_bar, 'Describe the person who\'s great at this — what they do, consistently', lines: 2),
        const SectionHeader('The feedback question'),
        _field(_ask, 'What will you ask someone who sees you do it?'),
        const SectionHeader('What each level looks like'),
        Text('Optional. Leave blank to use the general ladder, with your "good" as level 4.',
            style: AppText.small()),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _field(_levels[i], 'Level ${i + 1}${const [' — just starting', '', '', ' — the bar', ' — others learn from you'][i]}'),
          ),
        SectionHeader('Drills · ${_drills.length}'),
        Text('Concrete things to practise, each with a sign that it worked.',
            style: AppText.small()),
        for (var i = 0; i < _drills.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _field(_drills[i].title, 'Drill name'),
                        const SizedBox(height: 6),
                        _field(_drills[i].how, 'What exactly to do', lines: 2),
                        const SizedBox(height: 6),
                        _field(_drills[i].signal, 'How you\'ll know it worked'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove drill',
                    onPressed: _drills.length == 1
                        ? null
                        : () => setState(() => _drills.removeAt(i).dispose()),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _drills.add(_DrillFields(const Drill('', '', '')))),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add a drill'),
        ),
        if (editing)
          TextButton(
            onPressed: () {
              if (system.removeCustomArea(_id)) {
                toast(context, 'Area removed. Its reps stay in your log.');
                context.canPop() ? context.pop() : context.go('/growth');
              } else {
                toast(context, 'It\'s this month\'s area — choose another first.');
              }
            },
            child: Text('Remove this area',
                style: AppText.small(color: AppColors.danger)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

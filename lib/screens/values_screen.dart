import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// His values in his own words, a five-minute affirmation before pressure
/// moments, and a weekly check on whether the week reflected them.
class ValuesScreen extends StatelessWidget {
  const ValuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final values = system.values;
    return OnoPage(
      showBack: true,
      eyebrow: 'Mind · who you are',
      title: 'Your values',
      subtitle: values.isEmpty
          ? 'Three to five values, in your own words. They steady you before hard moments and tell you whether a week was well spent.'
          : 'Before a hard meeting, five minutes on why one of these matters. It lowers the threat response — and the impostor voice with it.',
      children: values.isEmpty
          ? const [_Picker()]
          : [
              const SizedBox(height: 14),
              for (final v in values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OnoCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: AppText.serif(size: 22)),
                        if (v.meaning.isNotEmpty)
                          Text(v.meaning,
                              style: AppText.body(color: AppColors.greyLight)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              PrimaryButton('Affirm before a hard moment',
                  icon: Icons.self_improvement_rounded,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ChangeNotifierProvider.value(
                          value: system, child: const _Affirm())))),
              const _WeekCheck(),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider.value(
                              value: system,
                              child: const OnoPage(
                                  showBack: true,
                                  eyebrow: 'Mind',
                                  title: 'Edit values',
                                  children: [_Picker()])))),
                  child: const Text('Edit values'),
                ),
              ),
              const SizedBox(height: 16),
            ],
    );
  }
}

class _Picker extends StatefulWidget {
  const _Picker();

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final Map<String, TextEditingController> _chosen = {};
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    for (final v in context.read<PersonalSystemProvider>().values) {
      _chosen[v.name] = TextEditingController(text: v.meaning);
    }
  }

  @override
  void dispose() {
    for (final c in _chosen.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Choose 3–5 · ${_chosen.length} chosen'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final v in valueOptions)
              FilterChip(
                label: Text(v),
                selected: _chosen.containsKey(v),
                showCheckmark: false,
                onSelected: (on) => setState(() {
                  if (on && _chosen.length < 5) {
                    _chosen[v] = TextEditingController();
                  } else if (!on) {
                    _chosen.remove(v)?.dispose();
                  }
                }),
              ),
          ],
        ),
        if (_chosen.isNotEmpty) ...[
          const SectionHeader('What each means to you'),
          for (final e in _chosen.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: e.value,
                style: AppText.body(color: AppColors.white),
                decoration: InputDecoration(
                    labelText: e.key,
                    hintText: 'One sentence, in your words'),
              ),
            ),
        ],
        const SizedBox(height: 8),
        PrimaryButton('Save my values', icon: Icons.check_rounded,
            onPressed: () {
          if (_chosen.length < 3) {
            toast(context, 'Choose at least three.');
            return;
          }
          context.read<PersonalSystemProvider>().setValues([
            for (final e in _chosen.entries) (name: e.key, meaning: e.value.text)
          ]);
          FocusManager.instance.primaryFocus?.unfocus();
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Five minutes: the value that matters most right now, why, and a time
/// you lived it.
class _Affirm extends StatefulWidget {
  const _Affirm();

  @override
  State<_Affirm> createState() => _AffirmState();
}

class _AffirmState extends State<_Affirm> {
  String? _value;
  final _before = TextEditingController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _before.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final values = system.values;
    return OnoPage(
      showBack: true,
      eyebrow: 'Values affirmation · 5 min',
      title: 'Why it matters',
      subtitle:
          'Pick the value that matters most to you right now. Write why — and one time you lived it. Not about the meeting: about you.',
      bottomBar: PrimaryButton('Done — walk in', icon: Icons.check_rounded,
          onPressed: () {
        if (_value == null || _text.text.trim().isEmpty) {
          toast(context, 'Pick a value and write a few lines.');
          return;
        }
        system.logAffirmation(_value!, _text.text, before: _before.text);
        HapticFeedback.mediumImpact();
        toast(context, 'You know who you are. Go.');
        Navigator.of(context).pop();
      }),
      children: [
        const SizedBox(height: 14),
        TextField(
          controller: _before,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'Before what? (e.g. a hard conversation, a big game)'),
        ),
        const SectionHeader('The value'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(v.name),
                selected: _value == v.name,
                showCheckmark: false,
                onSelected: (_) => setState(() => _value = v.name),
              ),
          ],
        ),
        const SectionHeader('Why it matters to you'),
        TextField(
          controller: _text,
          minLines: 6,
          maxLines: 12,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText:
                  'Why this matters, and a moment you lived it — even a small one.'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Did the week reflect them? Rated once a week.
class _WeekCheck extends StatelessWidget {
  const _WeekCheck();

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final ratings = system.valuesCheck(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('This week · ${shortDate(weekStartOf(now))}'),
        Text('How much did this week reflect each one? 1 = not at all · 5 = fully',
            style: AppText.small()),
        const SizedBox(height: 8),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            children: [
              for (final v in system.values)
                Row(
                  children: [
                    Expanded(child: Text(v.name, style: AppText.body(color: AppColors.white))),
                    for (var i = 1; i <= 5; i++)
                      SizedBox(
                        width: 30,
                        child: IconButton(
                          tooltip: '${v.name}: $i of 5',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => system.saveValuesCheck(
                              now, {...ratings, v.name: i}),
                          icon: Icon(
                              (ratings[v.name] ?? 0) >= i
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              size: 16,
                              color: (ratings[v.name] ?? 0) >= i
                                  ? AppColors.accent
                                  : AppColors.faint),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Fifteen-second morning check-in: energy, mood, sleep, shoulder pain and
/// morning stiffness. A painful or stiff morning turns the day's gym session
/// shoulder-sparing. The log is for you and your rheumatologist — ONO never
/// changes medication or supplements.
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

const energyLabels = ['Drained', 'Low', 'OK', 'Good', 'Sharp'];
const moodLabels = [
  'Very unpleasant',
  'Unpleasant',
  'Neutral',
  'Pleasant',
  'Very pleasant'
];
const stiffnessLabels = ['None', '< 15 min', '15–30 min', '30–60 min', '60+ min'];

class _CheckinScreenState extends State<CheckinScreen> {
  int _energy = 3; // 1–5
  int _mood = 0; // −2 … +2
  double _sleep = 7.5;
  int _pain = 0; // 0–10
  int _stiffness = 0; // bucket 0–4
  bool _loaded = false;
  bool _sleepFromHealth = false;
  final _feelings = <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final c = system.checkinFor(dayOnly(DateTime.now()));
    final fromHealth = system.sleepHoursFor(dayOnly(DateTime.now()));
    if (fromHealth != null) {
      _sleep = ((fromHealth * 2).round() / 2).clamp(0, 14).toDouble();
      _sleepFromHealth = true;
    }
    if (c != null) {
      _energy = c.number('energy')?.toInt() ?? _energy;
      _mood = c.number('mood')?.toInt() ?? _mood;
      _sleep = (c.number('sleep')?.toDouble() ?? _sleep).clamp(0, 14);
      _pain = c.number('pain')?.toInt() ?? _pain;
      _stiffness = c.number('stiffness')?.toInt() ?? _stiffness;
      _feelings.addAll([for (final f in (c.data['feelings'] as List? ?? const [])) '$f']);
    }
  }

  void _save() {
    final system = context.read<PersonalSystemProvider>();
    final today = dayOnly(DateTime.now());
    system.saveCheckin(today,
        energy: _energy,
        mood: _mood,
        sleep: _sleep,
        pain: _pain,
        stiffness: _stiffness,
        feelings: _feelings);
    HapticFeedback.mediumImpact();
    final gym = system.gymDayOn(today);
    toast(
        context,
        system.shoulderFlag(today)
            ? gym == null
                ? 'Logged. Shoulders flagged — go easy on them today.'
                : 'Logged. Today\'s Day ${gym.letter} is shoulder-sparing.'
            : 'Morning logged.');
    context.canPop() ? context.pop() : context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final flagged = _pain >= 5 || _stiffness >= 3;
    // Shoulder pain and stiffness are the built-in person's condition.
    final builtIn = context.watch<PersonalSystemProvider>().isBuiltInPerson;
    return OnoPage(
      showBack: true,
      eyebrow: 'Morning check-in · 15 seconds',
      title: 'How are you, really?',
      subtitle:
          'What you did is in your daily list. This is how you were — it decides how hard today should push.',
      bottomBar: PrimaryButton('Save check-in',
          icon: Icons.check_rounded, onPressed: _save),
      children: [
        _Section(
          label: 'Energy',
          child: _Choices(
            labels: energyLabels,
            selected: _energy - 1,
            onSelected: (i) => setState(() => _energy = i + 1),
          ),
        ),
        _Section(
          label: 'Mood',
          child: _Choices(
            labels: moodLabels,
            selected: _mood + 2,
            onSelected: (i) => setState(() => _mood = i - 2),
          ),
        ),
        _Section(
          label: 'Name it (optional, up to two)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in PersonalSystemProvider.feelingWords.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final w in group.value)
                        FilterChip(
                          key: Key('feeling-$w'),
                          label: Text(w),
                          tooltip: group.key,
                          selected: _feelings.contains(w),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: (on) => setState(() {
                            if (!on) {
                              _feelings.remove(w);
                            } else if (_feelings.length < PersonalSystemProvider.maxFeelings) {
                              _feelings.add(w);
                            } else {
                              _feelings
                                ..removeAt(0)
                                ..add(w);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Section(
          label: _sleepFromHealth
              ? 'Sleep last night · Apple Health'
              : 'Sleep last night',
          trailing: '${_fmtHours(_sleep)} h',
          child: Slider(
            value: _sleep,
            min: 0,
            max: 14,
            divisions: 28,
            label: '${_fmtHours(_sleep)} h',
            onChanged: (v) => setState(() => _sleep = v),
          ),
        ),
        if (builtIn) ...[
        _Section(
          label: 'Shoulder pain',
          trailing: '$_pain / 10',
          child: Slider(
            value: _pain.toDouble(),
            max: 10,
            divisions: 10,
            label: '$_pain',
            onChanged: (v) => setState(() => _pain = v.round()),
          ),
        ),
        _Section(
          label: 'Morning stiffness',
          child: _Choices(
            labels: stiffnessLabels,
            selected: _stiffness,
            onSelected: (i) => setState(() => _stiffness = i),
          ),
        ),
        const SizedBox(height: 16),
        OnoCard(
          accent: flagged ? AppColors.warning : AppColors.body,
          padding: const EdgeInsets.all(14),
          child: Text(
            flagged
                ? 'Shoulder-sparing day: presses, flyes and pulldowns are swapped for legs and trunk work. Stiffness past 30 minutes most mornings is worth mentioning to your rheumatologist.'
                : 'Normal training day.',
            style: AppText.small(color: AppColors.greyLight),
          ),
        ),
        ],
      ],
    );
  }

  static String _fmtHours(double h) =>
      h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);
}

class _Section extends StatelessWidget {
  final String label;
  final String? trailing;
  final Widget child;
  const _Section({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label.toUpperCase(), style: AppText.eyebrow())),
              if (trailing != null)
                Text(trailing!,
                    style: AppText.small(color: AppColors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  const _Choices(
      {required this.labels, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: i == selected,
            showCheckmark: false,
            selectedColor: AppColors.accent,
            side: BorderSide(
                color: i == selected ? AppColors.accent : AppColors.divider),
            labelStyle: AppText.small(
                    color: i == selected ? AppColors.ink : AppColors.greyLight)
                .copyWith(fontWeight: FontWeight.w700),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelected(i);
            },
          ),
      ],
    );
  }
}

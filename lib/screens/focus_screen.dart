import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import 'tool_screens.dart' show CountdownTimer;

/// Deep work: one block on one thing, phone away. Logged blocks feed the
/// week's deep-work hours and the artifact's hours this month.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  String? _target;
  int _minutes = 90;
  String? _toRate;

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _hours(int minutes) {
    final h = minutes / 60;
    return h == h.roundToDouble() ? '${h.toInt()}' : h.toStringAsFixed(1);
  }

  /// After a block: break the sitting before the next one.
  bool _breakDue = false;

  void _log(PersonalSystemProvider system, {required bool timed}) {
    setState(() {
      _toRate = system.logFocus(_minutes, _target!)?.id;
      _breakDue = _minutes >= 25;
    });
    toast(context,
        timed ? 'Block done — $_minutes min logged.' : '$_minutes min logged.');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final builtIn = system.isBuiltInPerson;
    final artifact = artifactFor(system.programMonth);
    final week = system.focusMinutesInWeek(now);
    final from = system.monthStart(system.programMonth);
    final month = builtIn
        ? system.artifactMinutesThisMonth
        : [
            for (final f in system.logsOf('focus'))
              if (!f.date.isBefore(from)) (f.number('minutes') ?? 0).toInt()
          ].fold<int>(0, (a, b) => a + b);
    _target ??= builtIn ? 'artifact' : 'skill';
    final free = system.freeBlocks(now);
    final targets = builtIn
        ? const {'artifact': 'Artifact', 'skill': 'Skill', 'other': 'Other'}
        : const {'skill': 'My growth area', 'goal': 'A goal', 'other': 'Other'};
    return OnoPage(
      showBack: true,
      eyebrow: 'Deep work',
      title: 'One block, one thing',
      subtitle:
          'Phone in another room, notifications off, one document open. Switching costs you the first 20 minutes of the next task.',
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: StatTile(_hours(week), 'this week', unit: 'h')),
            Expanded(
                child: StatTile(_hours(month),
                    builtIn ? 'on the artifact this month' : 'this month',
                    unit: 'h')),
          ],
        ),
        if (free.isNotEmpty) ...[
          const SectionHeader('Free today'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in free.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                        '${_hm(b.start)}–${_hm(b.end)} · ${_hours(b.end.difference(b.start).inMinutes)} h',
                        style: AppText.body(color: AppColors.white)),
                  ),
                Text(
                    system.energyPeak == null
                        ? 'From your calendar. Block one before someone else does.'
                        : 'From your calendar. Your energy peaks ${system.energyPeak!.from}:00–${system.energyPeak!.to}:00 — block that one first.',
                    style: AppText.small()),
              ],
            ),
          ),
        ],
        if (_toRate != null) ...[
          const SectionHeader('How sharp were you?'),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      onPressed: () {
                        system.rateFocus(_toRate!, i);
                        setState(() => _toRate = null);
                        toast(context, 'Saved to your energy map.');
                      },
                      child: Text('$i'),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (_breakDue) ...[
          const SizedBox(height: 12),
          OnoCard(
            key: const Key('focus-break'),
            accent: AppColors.body,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stand up and walk for three minutes',
                    style: AppText.heading()),
                Text('Breaking long sitting with a short walk does more than standing (Buffey et al. 2022).',
                    style: AppText.small()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _breakDue = false),
                      child: const Text('Not now'),
                    ),
                    TextButton(
                      onPressed: () {
                        system.logMove('walk', 3);
                        setState(() => _breakDue = false);
                        toast(context, 'Walked. Back when you\'re ready.');
                      },
                      child: const Text('I walked'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SectionHeader('On'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in targets.entries)
              ChoiceChip(
                label: Text(t.value),
                selected: _target == t.key,
                onSelected: (_) => setState(() => _target = t.key),
              ),
          ],
        ),
        if (_target == 'artifact' && builtIn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('This month: $artifact', style: AppText.small()),
          ),
        const SectionHeader('Length'),
        Wrap(
          spacing: 6,
          children: [
            for (final m in PersonalSystemProvider.focusLengths)
              ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Center(
          child: CountdownTimer(
            key: ValueKey('$_minutes-$_target'),
            minutes: _minutes,
            label: targets[_target]!.toLowerCase(),
            onDone: () => _log(system, timed: true),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => _log(system, timed: false),
            child: Text('Already did a $_minutes-min block — log it'),
          ),
        ),
      ],
    );
  }
}

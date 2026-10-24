import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The shape of an ordinary day: wake, work, bed. It draws the dial and
/// times the reminders.
/// "Mon–Fri", "Sun–Thu", or a list ("Mon, Wed, Sat").
String workDaysLabel(List<int> days) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final d = [...days]..sort();
  if (d.isEmpty) return 'No fixed days';
  if (d.length == 7) return 'Every day';
  // A run, also across Sunday into Monday (Sun–Thu).
  for (var start = 1; start <= 7; start++) {
    final run = [for (var i = 0; i < d.length; i++) (start - 1 + i) % 7 + 1];
    if (d.length > 2 && run.toSet().containsAll(d)) {
      return '${names[start - 1]}–${names[run.last - 1]}';
    }
  }
  return d.map((x) => names[x - 1]).join(', ');
}

class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  int _wake = 7 * 60, _start = 9 * 60, _end = 17 * 60 + 30, _bed = 23 * 60;
  bool _work = true;
  Set<int> _days = {1, 2, 3, 4, 5};
  bool _loaded = false;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    _days = system.workDays.toSet();
    final d = system.dayShape;
    if (d != null) {
      _wake = d.wake;
      _start = d.workStart;
      _end = d.workEnd;
      _bed = d.bed;
      _work = d.workStart < d.workEnd;
    }
  }

  static String _hm(int m) =>
      '${((m ~/ 60) % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Widget _row(String label, int value, ValueChanged<int> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(label, style: AppText.body(color: AppColors.white))),
            IconButton(
              tooltip: '15 minutes earlier',
              icon: const Icon(Icons.remove_rounded),
              onPressed: () => onChanged((value - 15).clamp(0, 24 * 60 - 15)),
            ),
            SizedBox(
              width: 64,
              child: Text(_hm(value),
                  textAlign: TextAlign.center, style: AppText.number(size: 20)),
            ),
            IconButton(
              tooltip: '15 minutes later',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => onChanged((value + 15).clamp(0, 24 * 60 - 15)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final sleep = (_wake + 24 * 60 - _bed) % (24 * 60);
    // The built-in schedule sets his times; only the days are his to choose.
    final daysOnly = system.isBuiltInPerson;
    return OnoPage(
      showBack: true,
      eyebrow: 'Your day',
      title: daysOnly ? 'Work days' : 'An ordinary day',
      subtitle: daysOnly
          ? 'Your schedule is a working day. On the other days your dial shows a plain day: morning, the day, winding down, sleep.'
          : 'When you wake, work and sleep, and which days you work. Your dial shows it, and your reminders follow it.',
      bottomBar:
          PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if ((_work || daysOnly) && _days.isEmpty) {
          toast(
              context, 'Choose the days you work, or switch fixed hours off.');
          return;
        }
        if (_work && _start >= _end) {
          toast(context,
              'Work has to end after it starts. Night shifts: switch fixed hours off.');
          return;
        }
        system.saveDayShape(
            wake: _wake,
            workStart: _work ? _start : _wake,
            workEnd: _work ? _end : _wake,
            bed: _bed,
            workDays: _work || daysOnly ? (_days.toList()..sort()) : null);
        toast(context,
            daysOnly ? 'Saved.' : 'Saved. Your reminders follow your day now.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SizedBox(height: 10),
        if (!daysOnly) ...[
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Column(
              children: [
                _row('Wake up', _wake, (v) => setState(() => _wake = v)),
                if (_work) ...[
                  _row('Start work', _start, (v) => setState(() => _start = v)),
                  _row('Finish work', _end, (v) => setState(() => _end = v)),
                ],
                _row('Lights out', _bed, (v) => setState(() => _bed = v)),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _work,
            onChanged: (v) => setState(() => _work = v),
            title: Text('Fixed work or study hours',
                style: AppText.body(color: AppColors.white)),
          ),
        ],
        if (_work || daysOnly) ...[
          Text('On these days — the others are days off',
              style: AppText.small()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  key: Key('workday-$d'),
                  label: Text(_dayNames[d - 1]),
                  selected: _days.contains(d),
                  showCheckmark: false,
                  onSelected: (on) =>
                      setState(() => on ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!daysOnly)
          Text(
              '${(sleep / 60).toStringAsFixed(1)} hours from lights out to waking.${sleep < 7 * 60 ? ' Most adults need seven or more.' : ''}',
              style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

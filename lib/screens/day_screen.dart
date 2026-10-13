import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The shape of an ordinary day: wake, work, bed. It draws the dial and
/// times the reminders.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  int _wake = 7 * 60, _start = 9 * 60, _end = 17 * 60 + 30, _bed = 23 * 60;
  bool _work = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final d = context.read<PersonalSystemProvider>().dayShape;
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
            Expanded(child: Text(label, style: AppText.body(color: AppColors.white))),
            IconButton(
              tooltip: '15 minutes earlier',
              icon: const Icon(Icons.remove_rounded),
              onPressed: () => onChanged((value - 15).clamp(0, 24 * 60 - 15)),
            ),
            SizedBox(
              width: 64,
              child: Text(_hm(value), textAlign: TextAlign.center, style: AppText.number(size: 20)),
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
    return OnoPage(
      showBack: true,
      eyebrow: 'Your day',
      title: 'An ordinary day',
      subtitle:
          'When you wake, work and sleep. Your dial shows it, and your reminders follow it.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_work && _start >= _end) {
          toast(context, 'Work has to end after it starts. Night shifts: switch fixed hours off.');
          return;
        }
        system.saveDayShape(
            wake: _wake,
            workStart: _work ? _start : _wake,
            workEnd: _work ? _end : _wake,
            bed: _bed);
        toast(context, 'Saved. Your reminders follow your day now.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SizedBox(height: 10),
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
          title: Text('Fixed work or study hours', style: AppText.body(color: AppColors.white)),
        ),
        Text(
            '${(sleep / 60).toStringAsFixed(1)} hours from lights out to waking.${sleep < 7 * 60 ? ' Most adults need seven or more.' : ''}',
            style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

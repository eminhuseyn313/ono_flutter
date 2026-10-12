import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Evening shutdown: tick today's three, write tomorrow's, empty the head.
/// A plan for unfinished work quiets it, and a written to-do list before
/// bed shortens the time it takes to fall asleep.
class ShutdownScreen extends StatefulWidget {
  const ShutdownScreen({super.key});

  @override
  State<ShutdownScreen> createState() => _ShutdownScreenState();
}

class _ShutdownScreenState extends State<ShutdownScreen> {
  late final List<TextEditingController> _next;
  final _open = TextEditingController();
  final _win = TextEditingController();
  final _why = TextEditingController();
  late final DateTime _today;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final system = context.read<PersonalSystemProvider>();
    _today = dayOnly(DateTime.now());
    final tomorrow = system.prioritiesFor(_today.plusDays(1));
    // Tomorrow's own priorities first, then what's unfinished today.
    final seed = [
      ...tomorrow.where((p) => p.trim().isNotEmpty),
      ...system.carryOverFrom(_today).where((p) => !tomorrow.contains(p)),
    ];
    _next = List.generate(
        3, (i) => TextEditingController(text: i < seed.length ? seed[i] : ''));
    _open.text = system.shutdownFor(_today)?.str('open') ?? '';
  }

  @override
  void dispose() {
    for (final c in _next) {
      c.dispose();
    }
    _open.dispose();
    _win.dispose();
    _why.dispose();
    super.dispose();
  }

  /// A priority ticked now no longer carries over to tomorrow; unticked,
  /// it goes back into the first free place.
  void _carry(String text, {required bool done}) {
    final t = text.trim();
    setState(() {
      if (done) {
        for (final c in _next) {
          if (c.text.trim() == t) c.clear();
        }
      } else if (!_next.any((c) => c.text.trim() == t)) {
        _next.where((c) => c.text.trim().isEmpty).firstOrNull?.text = t;
      }
    });
  }

  void _finish() {
    final system = context.read<PersonalSystemProvider>();
    system.completeShutdown(_today,
        tomorrow: [for (final c in _next) c.text],
        open: _open.text,
        win: _win.text,
        why: _why.text);
    HapticFeedback.heavyImpact();
    toast(context,
        'Shutdown complete. Tomorrow is on paper — the day is closed.');
    context.canPop() ? context.pop() : context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = system.prioritiesFor(_today);
    final done = system.shutdownFor(_today);
    return OnoPage(
      showBack: true,
      eyebrow: done != null
          ? 'Closed tonight'
          : system.isBuiltInPerson
              ? '21:30 · three minutes'
              : 'Three minutes',
      title: 'Shutdown',
      subtitle:
          'Close the loops on paper, then stop thinking about work. Tomorrow starts already decided.',
      bottomBar: PrimaryButton(
          done == null ? 'Shutdown complete' : 'Save again',
          icon: Icons.nights_stay_rounded,
          onPressed: _finish),
      children: [
        const SectionHeader('1 · Today\'s three'),
        if (today.every((p) => p.trim().isEmpty))
          const EmptyNote(
              'No priorities were set today. Tomorrow\'s three matter more now.',
              icon: Icons.flag_outlined)
        else
          OnoCard(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  if (today[i].trim().isNotEmpty)
                    CheckRow(
                      checked: system.priorityDone(_today, i),
                      title: today[i],
                      onChanged: (_) {
                        system.togglePriority(_today, i);
                        _carry(today[i], done: system.priorityDone(_today, i));
                      },
                    ),
              ],
            ),
          ),
        const SectionHeader('2 · Tomorrow\'s three'),
        OnoCard(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unfinished items carry over. Outcomes, not tasks.',
                  style: AppText.small()),
              for (var i = 0; i < 3; i++)
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${i + 1}',
                          style:
                              AppText.serif(size: 20, color: AppColors.accent)),
                    ),
                    Expanded(
                      child: TextField(
                        key: Key('tomorrow-$i'),
                        controller: _next[i],
                        style: AppText.body(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            hintText: 'What must be true by 18:00?',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SectionHeader('3 · Good things today'),
        TextField(
          controller: _win,
          minLines: 1,
          maxLines: 3,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'One to three things that went well, one per line'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _why,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'Why did the first one happen? (makes it repeatable)'),
        ),
        const SectionHeader('4 · Still open in your head?'),
        TextField(
          controller: _open,
          minLines: 3,
          maxLines: 6,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText:
                  'Anything nagging — write it here so it stops circling. It goes in tonight\'s log.'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

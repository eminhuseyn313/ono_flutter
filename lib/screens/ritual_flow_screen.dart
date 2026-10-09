import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_personal_content.dart';
import '../data/emin_system.dart';
import '../models/ritual.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The 06:05 morning ritual: water, manifesto, three priorities, sigh,
/// statement. Finishing ticks the manifesto and sigh in the Daily 10 and
/// saves the priorities to Today.
class RitualFlowScreen extends StatefulWidget {
  final String ritualId;
  const RitualFlowScreen({super.key, required this.ritualId});

  @override
  State<RitualFlowScreen> createState() => _RitualFlowScreenState();
}

class _RitualFlowScreenState extends State<RitualFlowScreen> {
  final List<RitualStep> _steps = eminMorningRitual;
  int _i = 0;
  late int _left = _steps.first.durationSeconds;
  Timer? _t;
  final _started = DateTime.now();
  bool _finished = false;
  final _priorities = List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalSystemProvider>().prioritiesFor(DateTime.now());
    for (var i = 0; i < 3; i++) {
      _priorities[i].text = p[i];
    }
    _run();
  }

  void _run() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _left <= 0) return;
      setState(() => _left--);
      if (_left == 0) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    for (final c in _priorities) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_steps[_i].id == 'three_priorities') _savePriorities();
    if (_i == _steps.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _i++;
      _left = _steps[_i].durationSeconds;
    });
    _run();
  }

  void _savePriorities() {
    final system = context.read<PersonalSystemProvider>();
    for (var i = 0; i < 3; i++) {
      system.setPriority(DateTime.now(), i, _priorities[i].text);
    }
  }

  void _finish() {
    _t?.cancel();
    final system = context.read<PersonalSystemProvider>();
    final now = DateTime.now();
    system.setCheck(now, 'manifesto', true);
    system.logProtocolUse('sigh', text: 'Morning ritual');
    system.addLog('ritual',
        data: {'seconds': now.difference(_started).inSeconds});
    HapticFeedback.heavyImpact();
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _finished ? _summary(bottom) : _step(bottom),
      ),
    );
  }

  Widget _step(double bottom) {
    final s = _steps[_i];
    final lane = s.lane.name;
    final color = AppColors.lane(lane);
    final next = _i + 1 < _steps.length ? _steps[_i + 1].title : null;
    final total = s.durationSeconds;
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                icon: const Icon(Icons.close_rounded, color: AppColors.grey),
              ),
              const SizedBox(width: 4),
              Expanded(
                  child: TickSegments(
                      total: _steps.length, filled: _i + 1, height: 4)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Text('STEP ${_i + 1} OF ${_steps.length} · ${lane.toUpperCase()}',
                  style: AppText.eyebrow(color: color)),
              const SizedBox(height: 8),
              Text(s.title, style: AppText.display()),
              const SizedBox(height: 6),
              Text(s.subtitle, style: AppText.body(color: AppColors.grey)),
              const SizedBox(height: 24),
              Center(
                child: ScoreRing(
                  progress: 1 - _left / total,
                  size: 170,
                  stroke: 12,
                  color: color,
                  center: Text(_left == 0 ? '✓' : '$mm:$ss',
                      style: AppText.number(size: 44)),
                ),
              ),
              const SizedBox(height: 24),
              if (s.id == 'manifesto')
                for (final stanza in manifestoStanzas) ...[
                  for (final line in stanza)
                    Text(line,
                        style: AppText.serif(
                            size: 20,
                            color: stanza == manifestoStanzas.last
                                ? AppColors.accent
                                : AppColors.white)),
                  const SizedBox(height: 14),
                ]
              else if (s.id == 'three_priorities')
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _priorities[i],
                      style: AppText.body(color: AppColors.white),
                      decoration: InputDecoration(
                        prefixText: '${i + 1}   ',
                        hintText: const [
                          'The outcome that matters most',
                          'Second outcome',
                          'Third outcome'
                        ][i],
                      ),
                    ),
                  )
              else if (s.id == 'identity')
                Text(activeProfile.identityStatement,
                    textAlign: TextAlign.center,
                    style: AppText.serif(size: 30, color: AppColors.accent))
              else
                OnoCard(
                  child: Text(s.instruction,
                      style: AppText.body(color: AppColors.white)),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
          child: PrimaryButton(
            next == null ? 'Finish ritual' : 'Next: $next',
            icon: Icons.arrow_forward_rounded,
            onPressed: _next,
          ),
        ),
      ],
    );
  }

  Widget _summary(double bottom) {
    final secs = DateTime.now().difference(_started).inSeconds;
    final system = context.watch<PersonalSystemProvider>();
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RITUAL COMPLETE', style: AppText.eyebrow(color: AppColors.accent)),
          const SizedBox(height: 10),
          Text('Today I build something permanent.', style: AppText.display()),
          const SizedBox(height: 28),
          OnoCard(
            child: Row(
              children: [
                Expanded(
                    child: StatTile('${_steps.length}/${_steps.length}', 'steps')),
                Expanded(
                    child: StatTile(
                        '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                        'minutes')),
                Expanded(
                    child: StatTile('${system.scoreFor(DateTime.now())}',
                        'Daily 10 now',
                        unit: '/10')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Manifesto and sigh are ticked. Your priorities are on Today.',
              style: AppText.small()),
          const Spacer(),
          if (system.checkinFor(DateTime.now()) == null) ...[
            PrimaryButton('Morning check-in · 15 s',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.pushReplacement('/checkin')),
            const SizedBox(height: 10),
            GhostButton('Back to Today', onPressed: () => context.go('/home')),
          ] else
            PrimaryButton('Back to Today',
                onPressed: () => context.go('/home')),
        ],
      ),
    );
  }
}

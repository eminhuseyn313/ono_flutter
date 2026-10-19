import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// A routine stepped through calmly: one step on screen, then the next.
/// Finishing ticks the daily item it belongs to.
class RoutineScreen extends StatefulWidget {
  final String? itemId;
  const RoutineScreen({super.key, this.itemId});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  int _step = 0;

  void _finish(PersonalSystemProvider system, String id) {
    system.setCheck(system.logicalToday, id, true);
    HapticFeedback.mediumImpact();
    toast(context, 'Done. Ticked for today.');
    context.canPop() ? context.pop() : context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final id = widget.itemId;
    final item = id == null ? null : system.dailyItem(id);
    final steps = id == null ? const <String>[] : system.stepsOf(id);
    if (item == null || steps.isEmpty) {
      return OnoPage(
        showBack: true,
        eyebrow: 'Routine',
        title: 'Routines',
        subtitle: 'Give one of your daily items steps under Your daily items, and it opens here.',
        children: [
          const SizedBox(height: 14),
          GhostButton('Your daily items',
              icon: Icons.checklist_rounded, onPressed: () => context.push('/daily')),
        ],
      );
    }
    final i = _step.clamp(0, steps.length - 1);
    final last = i == steps.length - 1;
    final done = system.isChecked(system.logicalToday, item.id);
    return OnoPage(
      showBack: true,
      eyebrow: '${item.title} · step ${i + 1} of ${steps.length}',
      title: steps[i],
      subtitle: done ? 'Already ticked for today.' : null,
      bottomBar: Row(
        children: [
          if (i > 0) ...[
            Expanded(
              child: GhostButton('Back',
                  icon: Icons.arrow_back_rounded, onPressed: () => setState(() => _step = i - 1)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: PrimaryButton(last ? 'Done' : 'Next',
                key: const Key('routine-next'),
                icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: () => last ? _finish(system, item.id) : setState(() => _step = i + 1)),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 18),
        TickSegments(
          total: steps.length,
          filled: i + 1,
          height: 6,
          colors: [
            for (var s = 0; s < steps.length; s++)
              s <= i ? AppColors.lane(item.lane) : AppColors.cardLight
          ],
        ),
        const SizedBox(height: 22),
        for (var s = 0; s < steps.length; s++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${s < i ? '✓ ' : s == i ? '→ ' : '   '}${steps[s]}',
              style: s == i
                  ? AppText.heading()
                  : AppText.body(color: s < i ? AppColors.grey : AppColors.faint),
            ),
          ),
        if (system.minimumFor(item.id).isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('On a hard day: ${system.minimumFor(item.id)}', style: AppText.small()),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Edit a routine's steps: one per line.
Future<void> editSteps(BuildContext context, PersonalSystemProvider system, NonNegotiable item) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => _StepsSheet(system: system, item: item),
    );

class _StepsSheet extends StatefulWidget {
  final PersonalSystemProvider system;
  final NonNegotiable item;
  const _StepsSheet({required this.system, required this.item});

  @override
  State<_StepsSheet> createState() => _StepsSheetState();
}

class _StepsSheetState extends State<_StepsSheet> {
  late final _steps = TextEditingController(text: widget.system.stepsOf(widget.item.id).join('\n'));

  @override
  void dispose() {
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.item.title, style: AppText.title()),
              Text('Steps, one per line. Leave it empty for a simple tick.', style: AppText.small()),
              const SizedBox(height: 10),
              TextField(
                key: const Key('steps-text'),
                controller: _steps,
                minLines: 4,
                maxLines: 10,
                style: AppText.body(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Brush your teeth\nClean between your teeth\n…'),
              ),
              const SizedBox(height: 12),
              PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
                widget.system.setSteps(widget.item.id, _steps.text.split('\n'));
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Something big changed: a move, a new job, a baby, a breakup. Old cues
/// stop working, and for about three months new habits start more easily.
/// Four steps, one at a time, then it settles.
class ChangeScreen extends StatefulWidget {
  const ChangeScreen({super.key});

  @override
  State<ChangeScreen> createState() => _ChangeScreenState();
}

class _ChangeScreenState extends State<ChangeScreen> {
  final _note = TextEditingController();
  final _keep = TextEditingController();
  String? _kind;
  String? _keepFor;

  @override
  void dispose() {
    _note.dispose();
    _keep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final t = system.activeTransition;
    if (t == null) return _start(system);
    if (_keepFor != t.id) {
      _keepFor = t.id;
      _keep.text = t.str('keep') ?? '';
    }
    final days = system.logicalToday.daysSince(t.date);
    return OnoPage(
      showBack: true,
      eyebrow: 'Something changed · day ${days + 1} of ${PersonalSystemProvider.transitionDays}',
      title: PersonalSystemProvider.transitionKinds[t.str('kind')] ?? 'Something changed',
      subtitle:
          'Old cues stop working after a big change, and new habits start more easily for a few months. Four steps, in your own time.',
      children: [
        if (t.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(t.text, style: AppText.body(color: AppColors.white)),
        ],
        const SectionHeader('Steps'),
        OnoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final s in PersonalSystemProvider.transitionSteps)
                if (s.$1 != 'keep')
                  CheckRow(
                    key: Key('change-${s.$1}'),
                    checked: system.transitionStepDone(t, s.$1),
                    title: s.$2,
                    onChanged: (v) => system.setTransitionStep(t, s.$1, v),
                    onOpen: () => context.push(s.$3),
                  ),
            ],
          ),
        ),
        const SectionHeader('What stays the same'),
        Text('Your values, the people who stay, the rules you live by — what this change doesn\'t touch.',
            style: AppText.small()),
        const SizedBox(height: 8),
        TextField(
          key: const Key('change-keep'),
          controller: _keep,
          minLines: 2,
          maxLines: 5,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'e.g. Sunday calls with my mother, how I treat people'),
        ),
        const SizedBox(height: 8),
        GhostButton('Keep it', icon: Icons.check_rounded, onPressed: () {
          system.setTransitionKeep(t, _keep.text);
          FocusScope.of(context).unfocus();
          toast(context, 'Kept.');
        }),
        if (system.values.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Your values: ${system.values.map((v) => v.name).join(' · ')}', style: AppText.small()),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            system.settleTransition(t);
            toast(context, 'Settled. It stays in your journal.');
          },
          child: const Text('It has settled — close this'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _start(PersonalSystemProvider system) => OnoPage(
        showBack: true,
        eyebrow: 'Something changed',
        title: 'When life changes',
        subtitle:
            'A move, a new job, a baby, an ending. For about three months ONO helps you rebuild the few habits that matter around the new shape of your days.',
        bottomBar: PrimaryButton('Start', key: const Key('change-start'), icon: Icons.arrow_forward_rounded,
            onPressed: () {
          final k = _kind;
          if (k == null) {
            toast(context, 'Choose what changed.');
            return;
          }
          system.startTransition(k, note: _note.text);
          _note.clear();
        }),
        children: [
          const SectionHeader('What changed?'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in PersonalSystemProvider.transitionKinds.entries)
                ChoiceChip(
                  key: Key('change-kind-${k.key}'),
                  label: Text(k.value),
                  selected: _kind == k.key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _kind = k.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(hintText: 'A line about it (optional)'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/remember'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('If someone died, remembering them is here'),
          ),
          if (system.logsOf('transition').isNotEmpty) ...[
            const SectionHeader('Before'),
            for (final l in system.logsOf('transition').take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                    '${shortDate(l.date)} · ${PersonalSystemProvider.transitionKinds[l.str('kind')] ?? ''}${l.text.isEmpty ? '' : ' — ${l.text}'}',
                    style: AppText.small(color: AppColors.white)),
              ),
          ],
          const SizedBox(height: 16),
        ],
      );
}

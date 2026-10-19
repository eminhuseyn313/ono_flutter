import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Negotiations you're preparing and the ones behind you: a raise, a
/// scope, rent, a car. Private: never sent anywhere.
class NegotiationsScreen extends StatelessWidget {
  const NegotiationsScreen({super.key});

  void _open(BuildContext context, [LogEntry? l]) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NegotiationEditScreen(entry: l)));

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final planned = [for (final l in system.negotiations) if (l.str('status') != 'done') l];
    final done = [for (final l in system.negotiations) if (l.str('status') == 'done') l];
    return OnoPage(
      showBack: true,
      eyebrow: 'Negotiation · 15 minutes',
      title: 'Prepare to negotiate',
      subtitle:
          'Know your alternative and your bottom line, learn what they care about, and open with an ambitious, justifiable first offer.',
      bottomBar: PrimaryButton('Prepare a negotiation',
          key: const Key('negotiation-new'), icon: Icons.add_rounded, onPressed: () => _open(context)),
      children: [
        if (planned.isEmpty && done.isEmpty) ...[
          const SizedBox(height: 14),
          const EmptyNote('A raise, a project\'s scope, rent, a car — anything with two sides.',
              icon: Icons.handshake_outlined),
        ],
        if (planned.isNotEmpty) ...[
          const SectionHeader('Coming up'),
          for (final l in planned)
            OnoCard(
              onTap: () => _open(context, l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.text, style: AppText.heading()),
                  if ((l.str('first_offer') ?? '').isNotEmpty)
                    Text('Opening: ${l.str('first_offer')}', style: AppText.small()),
                ],
              ),
            ),
        ],
        if (done.isNotEmpty) ...[
          const SectionHeader('Behind you'),
          for (final l in done.take(12))
            InkWell(
              onTap: () => _open(context, l),
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                  '${l.text} · ${PersonalSystemProvider.negotiationOutcomes[l.str('outcome')] ?? ''}${(l.str('lesson') ?? '').isEmpty ? '' : ' — ${l.str('lesson')}'}',
                  style: AppText.small(color: AppColors.white)),
            ),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class NegotiationEditScreen extends StatefulWidget {
  final LogEntry? entry;
  const NegotiationEditScreen({super.key, this.entry});

  @override
  State<NegotiationEditScreen> createState() => _NegotiationEditScreenState();
}

class _NegotiationEditScreenState extends State<NegotiationEditScreen> {
  late final _about = TextEditingController(text: widget.entry?.text ?? '');
  late final _fields = {
    for (final f in PersonalSystemProvider.negotiationFields)
      f.$1: TextEditingController(text: widget.entry?.str(f.$1) ?? ''),
  };
  late final _lesson = TextEditingController(text: widget.entry?.str('lesson') ?? '');
  late String? _outcome = widget.entry?.str('outcome');
  int _saves = 0;

  @override
  void dispose() {
    for (final c in [_about, _lesson, ..._fields.values]) {
      c.dispose();
    }
    super.dispose();
  }

  LogEntry? _save(PersonalSystemProvider system) => system.saveNegotiation(
        id: widget.entry?.id,
        about: _about.text,
        fields: {for (final e in _fields.entries) e.key: e.value.text},
      );

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    final existing = widget.entry != null;
    final done = widget.entry?.str('status') == 'done';
    return UnsavedGuard(
      changesOnly: true,
      saves: _saves,
      fields: [_about, ..._fields.values],
      child: OnoPage(
        showBack: true,
        eyebrow: 'Negotiation',
        title: widget.entry == null ? 'Prepare' : widget.entry!.text,
        bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
          if (_save(system) == null) {
            toast(context, 'Say what it\'s about first.');
            return;
          }
          setState(() => _saves++);
          toast(context, 'Saved.');
          Navigator.of(context).pop();
        }),
        children: [
          const SizedBox(height: 8),
          TextField(
            key: const Key('negotiation-about'),
            controller: _about,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'What it\'s about', hintText: 'e.g. My salary in the promotion'),
          ),
          for (final f in PersonalSystemProvider.negotiationFields)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _fields[f.$1],
                minLines: 1,
                maxLines: 4,
                style: AppText.body(color: AppColors.white),
                decoration: InputDecoration(labelText: f.$2, hintText: f.$3),
              ),
            ),
          if (existing) ...[
            const SectionHeader('Afterwards: how did it go?'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in PersonalSystemProvider.negotiationOutcomes.entries)
                  ChoiceChip(
                    label: Text(o.value),
                    selected: _outcome == o.key,
                    onSelected: (_) => setState(() => _outcome = o.key),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lesson,
              minLines: 1,
              maxLines: 3,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'One lesson for next time'),
            ),
            const SizedBox(height: 8),
            GhostButton(done ? 'Save how it went' : 'It happened — close it', icon: Icons.flag_outlined, onPressed: () {
              if (_outcome == null) {
                toast(context, 'Choose how it went.');
                return;
              }
              if (_save(system) == null) {
                toast(context, 'Say what it\'s about first.');
                return;
              }
              system.closeNegotiation(widget.entry!.id, outcome: _outcome!, lesson: _lesson.text);
              setState(() => _saves++);
              toast(context, 'Closed. The lesson is in your playbook.');
              Navigator.of(context).pop();
            }),
            TextButton(
              onPressed: () {
                final entry = widget.entry!;
                system.removeLog(entry.id);
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: const Text('Deleted.'),
                    action: SnackBarAction(label: 'Undo', onPressed: () => system.restoreLog(entry)),
                  ));
              },
              child: const Text('Delete this negotiation'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

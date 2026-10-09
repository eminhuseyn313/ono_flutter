import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The weekly progress note: written from real data, edited by you, sent
/// by you to one person. ONO never sends anything itself.
class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _text = TextEditingController();
  final _ask = TextEditingController();
  late String _to;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final system = context.read<PersonalSystemProvider>();
    _to = system.defaultNoteRecipient;
    _regenerate(system);
  }

  void _regenerate(PersonalSystemProvider system) {
    _text.text =
        system.progressNoteText(DateTime.now(), to: _to, ask: _ask.text);
  }

  @override
  void dispose() {
    _text.dispose();
    _ask.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final names = <String>{
      for (final p in activeProfile.keyPeople) p.name,
      for (final p in system.people) p.text,
    }.where((n) => n.isNotEmpty).toList();
    final sent = system.noteSentInWeek(DateTime.now());
    return OnoPage(
      showBack: true,
      eyebrow: sent ? 'Sent this week' : 'Friday · 5 minutes',
      title: 'Progress note',
      subtitle:
          'Tell one person how the week went. Progress you report moves faster than progress you only track.',
      bottomBar: PrimaryButton('Copy and mark sent', icon: Icons.send_rounded,
          onPressed: () {
        Clipboard.setData(ClipboardData(text: _text.text));
        system.logProgressNote(_to, _text.text);
        HapticFeedback.mediumImpact();
        toast(context, 'Copied. Paste it to ${_to.isEmpty ? 'them' : _to} — and ask for one reply.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SectionHeader('To'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in names)
              ChoiceChip(
                label: Text(n),
                selected: _to == n,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _to = n;
                  _regenerate(system);
                }),
              ),
            ActionChip(
              label: const Text('Someone else'),
              onPressed: () => setState(() {
                _to = '';
                _regenerate(system);
              }),
            ),
          ],
        ),
        const SectionHeader('Where could they help?'),
        TextField(
          controller: _ask,
          style: AppText.body(color: AppColors.white),
          onChanged: (_) => setState(() => _regenerate(system)),
          decoration: const InputDecoration(
              hintText: 'Optional: one specific ask — feedback, an intro, a decision'),
        ),
        const SectionHeader('The note'),
        TextField(
          key: const Key('note-text'),
          controller: _text,
          minLines: 8,
          maxLines: 20,
          style: AppText.body(color: AppColors.white),
        ),
        const SizedBox(height: 6),
        Text('Built from your goals, Big 3, growth reps and wins. Edit freely.',
            style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

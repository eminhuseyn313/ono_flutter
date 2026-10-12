import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The people he invests in and how often. Closeness fades without
/// contact; a rhythm he chose keeps it from fading by accident.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _name = TextEditingController();
  final _role = TextEditingController();
  int _every = 30;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _sheet(PersonalSystemProvider system, LogEntry p) {
    final note = TextEditingController();
    final ritual = TextEditingController(text: system.ritualOf(p));
    final growing = TextEditingController(text: p.str('growing') ?? '');
    final nextHelp = TextEditingController(text: p.str('next_help') ?? '');
    int? quality;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.text, style: AppText.title()),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'What about? (optional)'),
                ),
                const SizedBox(height: 10),
                Text('How present were you?', style: AppText.small()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final (i, label) in const ['Distracted', 'Okay', 'Fully present'].indexed)
                      ChoiceChip(
                        label: Text(label),
                        selected: quality == i + 1,
                        showCheckmark: false,
                        onSelected: (_) => setSheet(() => quality = i + 1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton('In touch today', icon: Icons.check_rounded,
                    onPressed: () {
                  system.logTouch(p, note: note.text, quality: quality);
                  if (ritual.text.trim() != system.ritualOf(p)) {
                    system.setRitual(p, ritual.text);
                  }
                  Navigator.of(ctx).pop();
                  toast(context, 'Logged. Next in ${system.cadenceOf(p)} days.');
                }),
                const SizedBox(height: 14),
                Text('Your ritual together', style: AppText.small()),
                const SizedBox(height: 6),
                TextField(
                  controller: ritual,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'e.g. Friday dinner, phones away · Sunday call'),
                ),
                TextButton(
                  onPressed: () {
                    system.setRitual(p, ritual.text);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save ritual only'),
                ),
                const SizedBox(height: 14),
                Text('Helping them grow', style: AppText.small()),
                const SizedBox(height: 6),
                TextField(
                  controller: growing,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'What they\'re working on, e.g. presenting, reading, delegating'),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nextHelp,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(
                      hintText: 'Your next way to help: a question, feedback, an intro'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        system.setGrowing(p, workingOn: growing.text, nextHelp: nextHelp.text);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Save'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        if (nextHelp.text.trim().isEmpty) {
                          toast(context, 'Write how you helped first.');
                          return;
                        }
                        system.setGrowing(p, workingOn: growing.text, nextHelp: nextHelp.text);
                        system.logHelp(p, nextHelp.text);
                        Navigator.of(ctx).pop();
                        toast(context, 'Logged. Teaching it teaches you too.');
                      },
                      child: const Text('I helped today'),
                    ),
                  ],
                ),
                GhostButton('Remove ${p.text.split(' ').first}',
                    icon: Icons.delete_outline_rounded, onPressed: () async {
                  final sure = await showDialog<bool>(
                    context: ctx,
                    builder: (d) => AlertDialog(
                      title: Text('Remove ${p.text}?'),
                      content: const Text(
                          'Their contact history and the help you logged go too.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: const Text('Keep')),
                        TextButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (sure != true || !ctx.mounted) return;
                  system.removePerson(p.id);
                  Navigator.of(ctx).pop();
                }),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      note.dispose();
      ritual.dispose();
      growing.dispose();
      nextHelp.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final people = system.people;
    final missing = activeProfile.keyPeople
        .where((k) => !people.any((p) => p.text.split(' ').first == k.name))
        .toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Social lane',
      title: 'People',
      subtitle:
          'Who you invest in, and how often. 1:1s count automatically; tap someone to log any other contact.',
      children: [
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 14),
          GhostButton(
              'Add ${missing.map((k) => k.name).join(' and ')} from your profile',
              icon: Icons.person_add_alt_rounded, onPressed: () {
            for (final k in missing) {
              system.addPerson(k.name, role: k.relation, every: k.every);
            }
          }),
        ],
        if (people.isNotEmpty) ...[
          const SectionHeader('Your people'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                for (final p in people) _row(system, p),
              ],
            ),
          ),
        ] else
          const EmptyNote(
              'Add the people who shape who you\'re becoming: a manager or coach, a mentor, peers one step ahead, family and friends you don\'t want to drift from.',
              icon: Icons.group_outlined),
        const SectionHeader('Add someone'),
        TextField(
          controller: _name,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _role,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'Who they are to you (e.g. mentor, coach, brother)'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: [
            for (final d in PersonalSystemProvider.contactCadences)
              ChoiceChip(
                label: Text(switch (d) {
                  7 => 'Weekly',
                  14 => 'Every 2 weeks',
                  30 => 'Monthly',
                  _ => 'Quarterly',
                }),
                selected: _every == d,
                onSelected: (_) => setState(() => _every = d),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton('Add', icon: Icons.person_add_alt_rounded, onPressed: () {
          if (_name.text.trim().isEmpty) {
            toast(context, 'Name first.');
            return;
          }
          system.addPerson(_name.text, role: _role.text, every: _every);
          _name.clear();
          _role.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _row(PersonalSystemProvider system, LogEntry p) {
    final days = system.daysSinceContact(p);
    final every = system.cadenceOf(p);
    final due = days >= every;
    final last = system.lastContact(p);
    return InkWell(
      onTap: () => _sheet(system, p),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.text, style: AppText.heading()),
                  Text(
                      [
                        if ((p.str('role') ?? '').isNotEmpty) p.str('role')!,
                        last == null ? 'no contact yet' : '$days d ago',
                        'every $every d',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small()),
                  if ((p.str('growing') ?? '').isNotEmpty)
                    Text(
                        'Growing: ${p.str('growing')}${(p.str('next_help') ?? '').isEmpty ? '' : ' · next: ${p.str('next_help')}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small(color: AppColors.skill)),
                  if (system.ritualOf(p).isNotEmpty ||
                      system.presenceOf(p) != null)
                    Text(
                        [
                          if (system.ritualOf(p).isNotEmpty) system.ritualOf(p),
                          if (system.presenceOf(p) != null)
                            'presence ${system.presenceOf(p)!.toStringAsFixed(1)}/3',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small(color: AppColors.social)),
                ],
              ),
            ),
            if (due)
              Text('Due',
                  style: AppText.small(color: AppColors.warning)
                      .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

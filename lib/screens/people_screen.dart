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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
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
            const SizedBox(height: 12),
            PrimaryButton('In touch today', icon: Icons.check_rounded,
                onPressed: () {
              system.logTouch(p, note: note.text);
              Navigator.of(ctx).pop();
              toast(context, 'Logged. Next in ${system.cadenceOf(p)} days.');
            }),
            const SizedBox(height: 8),
            GhostButton('Remove ${p.text.split(' ').first}',
                icon: Icons.delete_outline_rounded, onPressed: () {
              system.removePerson(p.id);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    ).whenComplete(note.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final people = system.people;
    final missing = keyPeople
        .where((k) => !people.any((p) => p.text.split(' ').first == k))
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
              'Add ${missing.join(' and ')} (weekly / monthly)',
              icon: Icons.person_add_alt_rounded, onPressed: () {
            for (final k in missing) {
              system.addPerson(k,
                  role: k == 'Ali' ? 'Manager' : 'Senior stakeholder',
                  every: k == 'Ali' ? 7 : 30);
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
              'Add the people who shape your next role: your manager, a skip-level, peers one role ahead, a mentor outside PASHA.',
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
              hintText: 'Role or why (e.g. Head of Product, Kapital)'),
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

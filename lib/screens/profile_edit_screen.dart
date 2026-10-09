import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

class _PersonFields {
  final TextEditingController name;
  final TextEditingController relation;
  int every;
  bool primary;
  _PersonFields(KeyPerson p)
      : name = TextEditingController(text: p.name),
        relation = TextEditingController(text: p.relation),
        every = p.every,
        primary = p.primary;
  void dispose() {
    name.dispose();
    relation.dispose();
  }

  KeyPerson get person => KeyPerson(name.text.trim(), relation.text.trim(),
      every: every, primary: primary);
}

/// Who the plan is for. Every screen, the weekly coach and the progress
/// note read from here — the same screen will start onboarding for others.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _c = <String, TextEditingController>{};
  final List<_PersonFields> _people = [];
  bool _loaded = false;

  static const _fields = [
    ('name', 'Full name', 'e.g. Leyla Mammadova', 1),
    ('firstName', 'First name', 'What ONO calls you', 1),
    ('currentRole', 'Where you are now', 'e.g. Team lead, amateur runner, founder', 1),
    ('targetRole', 'Who you\'re growing into', 'e.g. Director, sub-3 marathoner, CEO', 1),
    ('organisation', 'Organisation, team or club', 'Optional', 1),
    ('focus', 'What you own there', 'Optional: a product, a team, an event', 1),
    ('domain', 'The field to stay sharp in', 'e.g. payments and identity, endurance training', 1),
    ('location', 'Where you live', 'Optional', 1),
    ('archetype', 'Your archetype', 'e.g. The Product Architect, The Comeback Athlete', 1),
    ('tagline', 'A line under it', 'Optional', 1),
    ('identityStatement', 'Identity statement', 'The one line you start each day with', 1),
    ('path', 'Your path, one step per line', 'Now → next → after that', 4),
    ('coachContext', 'What your coach should know', 'Your routines, health conditions to respect, protocols, the thesis you work from', 6),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _fill(activeProfile);
  }

  void _fill(Profile p) {
    final values = {
      'name': p.name,
      'firstName': p.firstName,
      'currentRole': p.currentRole,
      'targetRole': p.targetRole,
      'organisation': p.organisation,
      'focus': p.focus,
      'domain': p.domain,
      'location': p.location,
      'archetype': p.archetype,
      'tagline': p.tagline,
      'identityStatement': p.identityStatement,
      'path': p.path.join('\n'),
      'coachContext': p.coachContext,
    };
    for (final f in _fields) {
      (_c[f.$1] ??= TextEditingController()).text = values[f.$1] ?? '';
    }
    for (final x in _people) {
      x.dispose();
    }
    _people
      ..clear()
      ..addAll(p.keyPeople.map(_PersonFields.new));
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    for (final p in _people) {
      p.dispose();
    }
    super.dispose();
  }

  String _v(String k) => _c[k]!.text.trim();

  void _save() {
    if (_v('name').isEmpty || _v('targetRole').isEmpty) {
      toast(context, 'Your name and who you\'re growing into are needed.');
      return;
    }
    final people = [
      for (final p in _people)
        if (p.name.text.trim().isNotEmpty) p.person
    ];
    final profile = Profile(
      name: _v('name'),
      firstName: _v('firstName').isEmpty ? _v('name').split(' ').first : _v('firstName'),
      currentRole: _v('currentRole'),
      targetRole: _v('targetRole'),
      organisation: _v('organisation'),
      focus: _v('focus'),
      domain: _v('domain'),
      location: _v('location'),
      archetype: _v('archetype'),
      tagline: _v('tagline'),
      identityStatement: _v('identityStatement'),
      path: [
        for (final l in _c['path']!.text.split('\n'))
          if (l.trim().isNotEmpty) l.trim()
      ],
      keyPeople: people,
      coachContext: _v('coachContext'),
    );
    context.read<PersonalSystemProvider>().saveProfile(profile);
    HapticFeedback.mediumImpact();
    toast(context, 'Profile saved. Everything now reads from it.');
    context.canPop() ? context.pop() : context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: system.profileEdited ? 'Your profile · edited' : 'Your profile',
      title: 'Who is this plan for?',
      subtitle:
          'Every screen, the weekly coach and your progress notes read from here. Change it whenever your life does.',
      bottomBar: PrimaryButton('Save profile', icon: Icons.check_rounded, onPressed: _save),
      children: [
        for (final f in _fields) ...[
          const SizedBox(height: 14),
          Text(f.$2, style: AppText.small(color: AppColors.white)
              .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            key: Key('profile-${f.$1}'),
            controller: _c[f.$1],
            minLines: f.$4,
            maxLines: f.$4 + 4,
            style: AppText.body(color: AppColors.white),
            decoration: InputDecoration(hintText: f.$3),
          ),
        ],
        SectionHeader('Key people · ${_people.length}'),
        Text('The people who shape your growth: a manager or coach, a mentor, family. The primary one gets your progress notes by default.',
            style: AppText.small()),
        for (var i = 0; i < _people.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _people[i].name,
                          style: AppText.body(color: AppColors.white),
                          decoration: const InputDecoration(hintText: 'Name'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () => setState(() => _people.removeAt(i).dispose()),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextField(
                      controller: _people[i].relation,
                      style: AppText.body(color: AppColors.white),
                      decoration: const InputDecoration(
                          hintText: 'Who they are to you (manager, coach, partner…)'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in PersonalSystemProvider.contactCadences)
                        ChoiceChip(
                          label: Text(switch (d) {
                            7 => 'Weekly',
                            14 => '2 weeks',
                            30 => 'Monthly',
                            _ => 'Quarterly',
                          }),
                          selected: _people[i].every == d,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _people[i].every = d),
                        ),
                      FilterChip(
                        label: const Text('Primary'),
                        selected: _people[i].primary,
                        showCheckmark: false,
                        onSelected: (on) => setState(() {
                          for (final p in _people) {
                            p.primary = false;
                          }
                          _people[i].primary = on;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _people.add(_PersonFields(
              const KeyPerson('', '', every: 30)))),
          icon: const Icon(Icons.person_add_alt_rounded, size: 18),
          label: const Text('Add a person'),
        ),
        if (system.profileEdited)
          TextButton(
            onPressed: () {
              system.resetProfile();
              setState(() => _fill(activeProfile));
              toast(context, 'Back to the original profile.');
            },
            child: Text('Reset to the original profile',
                style: AppText.small(color: AppColors.warning)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

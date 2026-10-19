import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// The people he invests in and how often. Closeness fades without
/// contact; a rhythm he chose keeps it from fading by accident.
class PeopleScreen extends StatefulWidget {
  /// A person to open straight away (from Today's "Reach out").
  final String? openId;
  const PeopleScreen({super.key, this.openId});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

const _cadenceLabels = {7: 'Weekly', 14: 'Every 2 weeks', 30: 'Monthly', 90: 'Quarterly', 365: 'Now and then'};

class _PeopleScreenState extends State<PeopleScreen> {
  final _name = TextEditingController();
  final _role = TextEditingController();
  int _every = 30;

  @override
  void initState() {
    super.initState();
    final id = widget.openId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final system = context.read<PersonalSystemProvider>();
        final p = system.personById(id);
        if (p != null) _sheet(system, p);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _sheet(PersonalSystemProvider system, LogEntry p) {
    if (system.isRemembered(p)) {
      _rememberedSheet(system, p);
      return;
    }
    final note = TextEditingController();
    final name = TextEditingController(text: p.text);
    final role = TextEditingController(text: p.str('role') ?? '');
    final askAbout = TextEditingController(text: system.askAboutOf(p));
    final b = system.birthdayOf(p);
    final birthday = TextEditingController(
        text: b == null ? '' : '${b.$2}.${b.$1.toString().padLeft(2, '0')}');
    final ritual = TextEditingController(text: system.ritualOf(p));
    final growing = TextEditingController(text: p.str('growing') ?? '');
    final nextHelp = TextEditingController(text: p.str('next_help') ?? '');
    var every = system.cadenceOf(p);
    int? quality;
    int? minutes;
    var yesterday = false;
    var details = false;
    final between = system.betweenYou(p);
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
                Text(
                    [
                      if ((p.str('role') ?? '').isNotEmpty) p.str('role')!,
                      _cadenceLabels[every] ?? 'every $every days',
                    ].join(' · '),
                    style: AppText.small()),
                if (system.askAboutOf(p).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Ask about: ${system.askAboutOf(p)}',
                      style: AppText.body(color: AppColors.accent)),
                ],
                if (between.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('BETWEEN YOU', style: AppText.eyebrow()),
                  for (final (kind, text, date) in between)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '$kind: $text${date == null ? '' : ' · ${shortDate(date)}'}',
                          style: AppText.small(color: AppColors.white)),
                    ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('person-know'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/know?id=${p.id}');
                  },
                  icon: const Icon(Icons.favorite_border_rounded, size: 18),
                  label: Text(
                      'What you know about ${p.text.split(' ').first} · ${system.knownCount(p)} of ${system.knowQuestionsFor(p).length}'),
                ),
                SwitchListTile(
                  key: const Key('person-in-care'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: system.inMyCare(system.personById(p.id) ?? p),
                  onChanged: (v) {
                    system.setInMyCare(p, v);
                    setSheet(() {});
                  },
                  title: Text('In my care', style: AppText.body(color: AppColors.white)),
                  subtitle: Text(
                      system.inMyCare(system.personById(p.id) ?? p)
                          ? 'Their check-ups are under Care; their story under What you know.'
                          : 'A parent, a child, someone who is ill',
                      style: AppText.small()),
                ),
                SwitchListTile(
                  key: const Key('person-child'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: system.isChild(system.personById(p.id) ?? p),
                  onChanged: (v) {
                    system.setIsChild(p, v);
                    setSheet(() {});
                  },
                  title: Text('My child', style: AppText.body(color: AppColors.white)),
                  subtitle: Text('Questions that fit a child, asked again every month', style: AppText.small()),
                ),
                SwitchListTile(
                  key: const Key('person-remembered'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: false,
                  onChanged: (_) {
                    system.setRemembered(p, true);
                    Navigator.of(ctx).pop();
                    context.push('/remember?id=${p.id}');
                  },
                  title: Text('Remember them', style: AppText.body(color: AppColors.white)),
                  subtitle: Text('If they have died: no more reminders to reach out. Everything stays.',
                      style: AppText.small()),
                ),
                if (system.askAboutOf(p).isEmpty)
                  if (system.nextQuestionFor(p) case final q?)
                    Text(
                        q.$3 ? 'Ask again: ${q.$2}' : 'Something to ask: ${q.$2}',
                        style: AppText.small(color: AppColors.accent)),
                const SizedBox(height: 10),
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
                  runSpacing: 6,
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
                const SizedBox(height: 10),
                Text('How long? (optional)', style: AppText.small()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final l in PersonalSystemProvider.touchLengths.entries)
                      ChoiceChip(
                        key: Key('touch-${l.key}'),
                        label: Text(l.value),
                        selected: minutes == l.key,
                        showCheckmark: false,
                        onSelected: (on) => setSheet(() => minutes = on ? l.key : null),
                      ),
                  ],
                ),
                if (system.hoursTogether(p) >= 1) ...[
                  const SizedBox(height: 6),
                  Text(
                      'About ${system.hoursTogether(p).round()} hours together in the last three months',
                      style: AppText.small()),
                ],
                const SizedBox(height: 10),
                Segmented(
                  labels: const ['Today', 'Yesterday'],
                  index: yesterday ? 1 : 0,
                  onChanged: (i) => setSheet(() => yesterday = i == 1),
                ),
                const SizedBox(height: 12),
                PrimaryButton(yesterday ? 'In touch yesterday' : 'In touch today',
                    icon: Icons.check_rounded, onPressed: () {
                  system.logTouch(p,
                      note: note.text,
                      quality: quality,
                      minutes: minutes,
                      date: yesterday
                          ? dayOnly(DateTime.now()).minusDays(1)
                          : null);
                  Navigator.of(ctx).pop();
                  toast(context, 'Logged. Next in ${system.cadenceOf(p)} days.');
                }),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const Key('person-details'),
                  onPressed: () => setSheet(() => details = !details),
                  icon: Icon(details
                      ? Icons.expand_less_rounded
                      : Icons.edit_outlined, size: 18),
                  label: const Text('Details, rhythm and what to ask'),
                ),
                if (details) ...[
                  TextField(
                    controller: name,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: role,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Who they are to you'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in PersonalSystemProvider.contactCadences)
                        ChoiceChip(
                          label: Text(_cadenceLabels[d]!),
                          selected: every == d,
                          onSelected: (_) => setSheet(() => every = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: askAbout,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(
                        labelText: 'Next time, ask about',
                        hintText: 'e.g. how the exam went, her new job'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: birthday,
                    keyboardType: TextInputType.datetime,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(
                        labelText: 'Birthday (day.month, optional)',
                        hintText: 'e.g. 14.03'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ritual,
                    style: AppText.body(color: AppColors.white),
                    decoration: const InputDecoration(
                        labelText: 'Your ritual together',
                        hintText: 'e.g. Friday dinner, phones away · Sunday call'),
                  ),
                  const SizedBox(height: 10),
                  GhostButton('Save details', icon: Icons.check_rounded,
                      onPressed: () {
                    final bd = _parseBirthday(birthday.text);
                    if (birthday.text.trim().isNotEmpty && bd == null) {
                      toast(context, 'Birthday as day.month, e.g. 14.03');
                      return;
                    }
                    system.updatePerson(p,
                        name: name.text,
                        role: role.text,
                        every: every,
                        askAbout: askAbout.text,
                        birthday: bd ?? '');
                    system.setRitual(p, ritual.text);
                    Navigator.of(ctx).pop();
                    toast(context, 'Saved.');
                  }),
                ],
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
                          'Their contact history and the help you logged go too. To see them less often, change the rhythm under Details instead.'),
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
    );
  }

  /// "14.03" or "14/3" → "03-14"; null when it isn't a date.
  static String? _parseBirthday(String text) {
    final parts = text.trim().split(RegExp(r'[./\- ]+'));
    if (parts.length != 2) return null;
    final d = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (d == null || m == null || m < 1 || m > 12 || d < 1 || d > 31) return null;
    return '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final people = system.peopleByDue;
    final missing = activeProfile.keyPeople
        .where((k) => !system.people.any((p) => p.text.split(' ').first == k.name))
        .toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'People',
      title: 'People',
      subtitle:
          'Who you want to stay close to, and how often. Tap someone when you\'ve been in touch.',
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
              'Add the people you don\'t want to drift from: family and friends, a mentor, people one step ahead, the people you work with.',
              icon: Icons.group_outlined),
        if (system.rememberedPeople.isNotEmpty) ...[
          const SectionHeader('Remembered'),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                for (final p in system.rememberedPeople)
                  InkWell(
                    onTap: () => _sheet(system, p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(p.text, style: AppText.heading())),
                          const Icon(Icons.local_florist_outlined, size: 18, color: AppColors.faint),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                label: Text(_cadenceLabels[d]!),
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

  void _rememberedSheet(PersonalSystemProvider system, LogEntry p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.text, style: AppText.title()),
              Text('Remembered', style: AppText.small()),
              const SizedBox(height: 14),
              PrimaryButton('Write to remember them', icon: Icons.edit_outlined, onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/remember?id=${p.id}');
              }),
              const SizedBox(height: 8),
              GhostButton('Their story', icon: Icons.auto_stories_outlined, onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/know?id=${p.id}');
              }),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  system.setRemembered(p, false);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Back among your people'),
              ),
            ],
          ),
        ),
      ),
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
                        if (system.askAboutOf(p).isNotEmpty)
                          'ask about ${system.askAboutOf(p)}',
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

/// Names from People under a "to / who / with" field, so a promise, an ask
/// or a conversation is tied to the person in one tap.
class PeoplePicker extends StatelessWidget {
  final TextEditingController controller;
  const PeoplePicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final people = context.watch<PersonalSystemProvider>().peopleByDue.take(8);
    if (people.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in people)
              ChoiceChip(
                label: Text(p.text),
                selected: controller.text.trim() == p.text,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => controller.text = p.text,
              ),
          ],
        ),
      ),
    );
  }
}

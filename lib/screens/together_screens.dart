import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../widgets/support_sheet.dart';

/// How to work with me: a personal user manual, drafted from your data.
class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  final Map<String, TextEditingController> _c = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isNotEmpty) return;
    final system = context.read<PersonalSystemProvider>();
    for (final s in PersonalSystemProvider.manualSections) {
      _c[s.$1] = TextEditingController(text: system.manualSection(s.$1));
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  static const _hints = {
    'best': 'When I\'m at my best, I…',
    'values': 'What matters most to me, and why',
    'energy': 'When I think best, and when to leave me alone',
    'communication': 'e.g. Short messages; call me if it\'s urgent; I like the decision first',
    'feedback': 'e.g. Directly and soon, in private, with an example',
    'watch': 'e.g. I go quiet when overloaded — ask me what I\'d drop',
  };

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'How to work with me',
      title: 'Your user manual',
      subtitle:
          'One page that tells your team, your partner or a new colleague how you work best. Drafted from what you\'ve written here — make it yours.',
      bottomBar: PrimaryButton('Save and copy', icon: Icons.copy_rounded, onPressed: () {
        system.saveManual({for (final e in _c.entries) e.key: e.value.text});
        Clipboard.setData(ClipboardData(text: system.manualText()));
        toast(context, 'Saved and copied. Share it with the people you work with.');
      }),
      children: [
        for (final s in PersonalSystemProvider.manualSections)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: TextField(
              controller: _c[s.$1],
              minLines: 2,
              maxLines: 6,
              style: AppText.body(color: AppColors.white),
              decoration: InputDecoration(labelText: s.$2, hintText: _hints[s.$1]),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A weekly check-in with a partner: appreciation first.
class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> {
  final _with = TextEditingController();
  final Map<String, TextEditingController> _c = {
    for (final q in PersonalSystemProvider.usQuestions) q.$1: TextEditingController(),
  };
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final last = system.logsOf('us_checkin').firstOrNull;
    final partner = activeProfile.keyPeople
        .where((k) => RegExp('wife|husband|partner', caseSensitive: false).hasMatch(k.relation))
        .firstOrNull;
    _with.text = last?.str('with') ?? partner?.name ?? '';
    final now = system.usCheckinFor(DateTime.now());
    if (now != null) {
      for (final q in PersonalSystemProvider.usQuestions) {
        _c[q.$1]!.text = now.str(q.$1) ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_with, ..._c.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final streak = system.usStreak;
    return OnoPage(
      showBack: true,
      eyebrow: 'Us · 20 minutes a week',
      title: 'A check-in for two',
      subtitle:
          'Sit together, phones away. Each of you answers in turn — start with appreciation. Small regular rituals keep a relationship close.',
      bottomBar: PrimaryButton('Save this week', icon: Icons.favorite_outline_rounded, onPressed: () {
        if (_c.values.every((c) => c.text.trim().isEmpty)) {
          toast(context, 'Answer at least one question together first.');
          return;
        }
        system.logUsCheckin(_with.text, {for (final e in _c.entries) e.key: e.value.text});
        FocusManager.instance.primaryFocus?.unfocus();
        toast(context, 'Saved. Same time next week?');
      }),
      children: [
        if (streak > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('$streak week${streak == 1 ? '' : 's'} in a row',
                style: AppText.small(color: AppColors.social)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextField(
            controller: _with,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'With'),
          ),
        ),
        for (final q in PersonalSystemProvider.usQuestions)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _c[q.$1],
              minLines: 2,
              maxLines: 5,
              style: AppText.body(color: AppColors.white),
              decoration: InputDecoration(labelText: q.$2),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// What you know about one person's world: what they're working towards,
/// what weighs on them, how they like to be appreciated. Knowing it is
/// what closeness is built on (Gottman's "love maps"); at work it is
/// understanding the people you work with. Private: never sent anywhere.
class KnowScreen extends StatefulWidget {
  final String? personId;
  const KnowScreen({super.key, this.personId});

  @override
  State<KnowScreen> createState() => _KnowScreenState();
}

class _KnowScreenState extends State<KnowScreen> {
  final _answers = {
    for (final q in [
      ...PersonalSystemProvider.knowQuestions,
      ...PersonalSystemProvider.childKnowQuestions,
    ])
      q.$1: TextEditingController(),
  };
  final _story = {
    for (final q in PersonalSystemProvider.storyQuestions)
      q.$1: TextEditingController(),
  };
  bool _loaded = false;
  int _saves = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final system = context.read<PersonalSystemProvider>();
    final p = widget.personId == null ? null : system.personById(widget.personId!);
    if (p == null) return;
    for (final q in system.knowQuestionsFor(p)) {
      _answers[q.$1]!.text = system.knowAnswer(p, q.$1);
    }
    for (final q in PersonalSystemProvider.storyQuestions) {
      _story[q.$1]!.text = system.storyAnswer(p, q.$1);
    }
  }

  @override
  void dispose() {
    for (final c in [..._answers.values, ..._story.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = widget.personId == null ? null : system.personById(widget.personId!);
    if (p == null) {
      return OnoPage(
        showBack: true,
        eyebrow: 'People',
        title: 'What you know about them',
        subtitle: 'Open someone on People, then "What you know about them".',
        children: [
          const SizedBox(height: 14),
          if (system.activePeople.isEmpty)
            const EmptyNote('Add the people who matter on People first.',
                icon: Icons.group_outlined)
          else
            OnoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final x in system.activePeople)
                    LinkRow(
                      icon: Icons.person_outline_rounded,
                      color: AppColors.social,
                      title: x.text,
                      trailing:
                          '${system.knownCount(x)}/${system.knowQuestionsFor(x).length}',
                      onTap: () => context.push('/know?id=${x.id}'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      );
    }
    final first = p.text.split(' ').first;
    // For someone remembered, only their story — no questions about now.
    final remembered = system.isRemembered(p);
    final next = remembered ? null : system.nextQuestionFor(p);
    final questions = remembered ? const <(String, String, String)>[] : system.knowQuestionsFor(p);
    return UnsavedGuard(
      changesOnly: true,
      saves: _saves,
      fields: [..._answers.values, ..._story.values],
      child: OnoPage(
        showBack: true,
        eyebrow: remembered ? 'Remembering' : 'People · ${system.knownCount(p)} of ${questions.length} known',
        title: 'What you know about $first',
        subtitle:
            'Knowing someone\'s world is what closeness is built on. Write what $first told you, in a line. It stays on your devices.',
        bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
          for (final q in questions) {
            system.setKnow(system.personById(p.id)!, q.$1, _answers[q.$1]!.text);
          }
          for (final q in PersonalSystemProvider.storyQuestions) {
            system.setStoryAnswer(system.personById(p.id)!, q.$1, _story[q.$1]!.text);
          }
          setState(() => _saves++);
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Saved.');
        }),
        children: [
          if (next != null) ...[
            const SizedBox(height: 14),
            OnoCard(
              key: const Key('know-next'),
              accent: AppColors.social,
              child: Text(
                  next.$3
                      ? 'Next time, ask again: ${next.$2}. It may have changed.'
                      : 'Next time, ask $first ${next.$2}.',
                  style: AppText.body(color: AppColors.white)),
            ),
          ],
          for (final q in questions) ...[
            SectionHeader(q.$2),
            TextField(
              key: Key('know-${q.$1}'),
              controller: _answers[q.$1],
              minLines: 1,
              maxLines: 4,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Not yet — ask next time'),
            ),
            if (system.knowOn(p, q.$1) case final on?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    system.knowStale(p, q.$1)
                        ? 'From ${shortDate(on)} — may have changed'
                        : 'As of ${shortDate(on)}',
                    style: AppText.small(
                        color: system.knowStale(p, q.$1) ? AppColors.warning : AppColors.grey)),
              ),
          ],
          // For someone in your care: their story, asked while you can.
          if (system.inMyCare(p)) ...[
            const SectionHeader('Their story'),
            Text('Questions to ask while you can — in their words, kept only for you.',
                style: AppText.small()),
            for (final q in PersonalSystemProvider.storyQuestions) ...[
              const SizedBox(height: 12),
              Text(q.$2, style: AppText.body(color: AppColors.white)),
              const SizedBox(height: 4),
              TextField(
                key: Key('story-${q.$1}'),
                controller: _story[q.$1],
                minLines: 1,
                maxLines: 6,
                style: AppText.body(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Ask them next time'),
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Once a month, for anyone caring for someone: how heavy it has felt
/// and who could share it. Caregiver strain grows unseen.
class CarerScreen extends StatefulWidget {
  const CarerScreen({super.key});

  @override
  State<CarerScreen> createState() => _CarerScreenState();
}

class _CarerScreenState extends State<CarerScreen> {
  final _share = TextEditingController();
  int? _heavy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final system = context.read<PersonalSystemProvider>();
    final c = system.caregiverCheckFor(system.programMonth);
    if (c != null && _heavy == null) {
      _heavy = c.number('heavy')?.toInt();
      _share.text = c.str('share') ?? '';
    }
  }

  @override
  void dispose() {
    _share.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final names = system.peopleInCare.map((p) => p.text.split(' ').first).join(' and ');
    return OnoPage(
      showBack: true,
      eyebrow: 'Care · once a month',
      title: 'And how are you?',
      subtitle: names.isEmpty
          ? 'For anyone looking after someone.'
          : 'Looking after $names matters. So do you.',
      bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
        if (_heavy == null) {
          toast(context, 'Choose how heavy it has felt.');
          return;
        }
        system.saveCaregiverCheck(heavy: _heavy!, share: _share.text);
        toast(context, 'Saved.');
        context.canPop() ? context.pop() : context.go('/home');
      }),
      children: [
        const SectionHeader('How heavy has caring felt this month?'),
        Segmented(
          labels: const ['Light', '2', '3', '4', 'Heavy'],
          index: _heavy == null ? -1 : _heavy! - 1,
          onChanged: (i) => setState(() => _heavy = i + 1),
        ),
        const SectionHeader('Who could share some of it?'),
        TextField(
          controller: _share,
          minLines: 1,
          maxLines: 3,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'A sibling, a friend, a neighbour, a service'),
        ),
        if ((_heavy ?? 0) >= 4) ...[
          const SizedBox(height: 14),
          OnoCard(
            accent: AppColors.social,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                LinkRow(
                  icon: Icons.pan_tool_alt_outlined,
                  color: AppColors.social,
                  title: 'Ask for help',
                  subtitle: 'Most people say yes more often than you\'d guess',
                  onTap: () => context.push('/asks'),
                ),
                const Divider(indent: 66),
                LinkRow(
                  icon: Icons.beach_access_outlined,
                  color: AppColors.body,
                  title: 'Plan some rest',
                  subtitle: 'A day, or a lighter week',
                  onTap: () => context.push('/rest'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Someone you lost ──────────────────────────────────────────────────

/// A quiet place to remember someone who has died: what you miss, what
/// they taught you, what you carry forward. No stages, no timelines.
class RememberScreen extends StatefulWidget {
  final String? personId;
  const RememberScreen({super.key, this.personId});

  @override
  State<RememberScreen> createState() => _RememberScreenState();
}

class _RememberScreenState extends State<RememberScreen> {
  late final _answers = {
    for (final q in PersonalSystemProvider.remembranceQuestions) q.$1: TextEditingController()
  };
  final _died = TextEditingController();
  int _saves = 0;
  bool _dateSet = false;

  @override
  void initState() {
    super.initState();
    // Opening it is enough: today's quiet line on Today goes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.personId == null) return;
      final system = context.read<PersonalSystemProvider>();
      final p = system.personById(widget.personId!);
      if (p != null && system.isRemembered(p)) {
        system.setDone(system.remembranceSeenKey(p, system.logicalToday), true);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [..._answers.values, _died]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "d.MM.yyyy" → a date, or null.
  static DateTime? _parse(String s) {
    final p = s.trim().split(RegExp(r'[./-]'));
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null || m < 1 || m > 12 || d < 1 || d > 31 || y < 1900) {
      return null;
    }
    final date = DateTime(y, m, d);
    return date.month == m ? date : null;
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = widget.personId == null ? null : system.personById(widget.personId!);
    if (p == null) {
      final remembered = system.rememberedPeople;
      return OnoPage(
        showBack: true,
        eyebrow: 'People',
        title: 'Remembering',
        subtitle:
            'When someone on your list has died, open them under People and choose Remember them. Their history stays; ONO stops asking you to reach out.',
        children: [
          const SizedBox(height: 14),
          if (remembered.isEmpty)
            const EmptyNote('No one here.', icon: Icons.local_florist_outlined)
          else
            OnoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, r) in remembered.indexed) ...[
                    if (i > 0) const Divider(indent: 16),
                    ListTile(
                      title: Text(r.text, style: AppText.heading()),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                      onTap: () => context.push('/remember?id=${r.id}'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }
    final died = system.diedOn(p);
    if (!_dateSet) {
      _dateSet = true;
      if (died != null) _died.text = '${died.day}.${died.month.toString().padLeft(2, '0')}.${died.year}';
    }
    final first = p.text.split(' ').first;
    final past = system.remembrancesOf(p);
    final story = [
      for (final q in PersonalSystemProvider.storyQuestions)
        if (system.storyAnswer(p, q.$1).isNotEmpty) (q.$2, system.storyAnswer(p, q.$1))
    ];
    return UnsavedGuard(
      fields: _answers.values.toList(),
      saves: _saves,
      child: OnoPage(
        showBack: true,
        eyebrow: 'Remembering',
        title: p.text,
        subtitle: 'Write when you want to, as much or as little as you like. It stays on this phone and in your journal.',
        bottomBar: PrimaryButton('Keep this', key: const Key('remember-save'), icon: Icons.check_rounded,
            onPressed: () {
          final saved = system.saveRemembrance(p, {
            for (final e in _answers.entries) e.key: e.value.text,
          });
          if (saved == null) {
            toast(context, 'Write a line first.');
            return;
          }
          for (final c in _answers.values) {
            c.clear();
          }
          setState(() => _saves++);
          FocusScope.of(context).unfocus();
          toast(context, 'Kept.');
        }),
        children: [
          for (final q in PersonalSystemProvider.remembranceQuestions)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                key: Key('remember-${q.$1}'),
                controller: _answers[q.$1],
                minLines: 2,
                maxLines: 6,
                style: AppText.body(color: AppColors.white),
                decoration: InputDecoration(labelText: q.$2),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _died,
            keyboardType: TextInputType.datetime,
            style: AppText.body(color: AppColors.white),
            decoration: const InputDecoration(
                labelText: 'The day they died (optional)', hintText: 'd.mm.yyyy'),
            onChanged: (v) {
              if (v.trim().isEmpty) {
                system.setDiedOn(p, null);
              } else if (_parse(v) case final d?) {
                system.setDiedOn(p, d);
              }
            },
          ),
          Text('ONO will quietly mark the day each year, and their birthday.', style: AppText.small()),
          if (story.isNotEmpty) ...[
            SectionHeader('$first\'s story'),
            for (final (q, a) in story)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('$q\n$a', style: AppText.small(color: AppColors.white)),
              ),
          ],
          if (past.isNotEmpty) ...[
            const SectionHeader('What you wrote'),
            for (final l in past)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OnoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shortDate(l.date), style: AppText.eyebrow()),
                      for (final q in PersonalSystemProvider.remembranceQuestions)
                        if ((l.str(q.$1) ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(q.$2, style: AppText.small()),
                          Text(l.str(q.$1)!, style: AppText.body(color: AppColors.white)),
                        ],
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          const SupportLink(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

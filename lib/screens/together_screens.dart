import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

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
    for (final q in PersonalSystemProvider.knowQuestions)
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
    for (final q in PersonalSystemProvider.knowQuestions) {
      _answers[q.$1]!.text = system.knowAnswer(p, q.$1);
    }
  }

  @override
  void dispose() {
    for (final c in _answers.values) {
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
          if (system.people.isEmpty)
            const EmptyNote('Add the people who matter on People first.',
                icon: Icons.group_outlined)
          else
            OnoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final x in system.people)
                    LinkRow(
                      icon: Icons.person_outline_rounded,
                      color: AppColors.social,
                      title: x.text,
                      trailing:
                          '${system.knownCount(x)}/${PersonalSystemProvider.knowQuestions.length}',
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
    final next = system.nextQuestionFor(p);
    return UnsavedGuard(
      changesOnly: true,
      saves: _saves,
      fields: _answers.values.toList(),
      child: OnoPage(
        showBack: true,
        eyebrow: 'People · ${system.knownCount(p)} of ${PersonalSystemProvider.knowQuestions.length} known',
        title: 'What you know about $first',
        subtitle:
            'Knowing someone\'s world is what closeness is built on. Write what $first told you, in a line. It stays on your devices.',
        bottomBar: PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
          for (final q in PersonalSystemProvider.knowQuestions) {
            system.setKnow(p, q.$1, _answers[q.$1]!.text);
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
          for (final q in PersonalSystemProvider.knowQuestions) ...[
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

Widget _input(TextEditingController c, String hint, {int lines = 1, Key? key}) =>
    TextField(
      key: key,
      controller: c,
      minLines: lines,
      maxLines: lines + 3,
      style: AppText.body(color: AppColors.white),
      decoration: InputDecoration(hintText: hint),
    );

// ── Stop-doing list ────────────────────────────────────────────────────

/// What you've given up on purpose — and what that makes room for.
class StopScreen extends StatefulWidget {
  const StopScreen({super.key});

  @override
  State<StopScreen> createState() => _StopScreenState();
}

class _StopScreenState extends State<StopScreen> {
  final _what = TextEditingController();
  final _room = TextEditingController();

  @override
  void dispose() {
    _what.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    return OnoPage(
      showBack: true,
      eyebrow: 'Direction · saying no',
      title: 'Stop doing',
      subtitle:
          'Every yes needs time from somewhere. Name what you\'re giving up — and check each week that it stayed given up.',
      children: [
        if (system.stopList.isEmpty)
          const EmptyNote('Nothing yet. What drains time without moving anything you care about?',
              icon: Icons.do_not_disturb_on_outlined)
        else ...[
          const SectionHeader('This week'),
          for (final s in system.stopList)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(s.text, style: AppText.heading())),
                        IconButton(
                          tooltip: 'No longer needed',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => system.retireStop(s.id),
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.faint),
                        ),
                      ],
                    ),
                    if ((s.str('room') ?? '').isNotEmpty)
                      Text('Makes room for: ${s.str('room')}', style: AppText.small()),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('Held'),
                          selected: system.stopHeldInWeek(s.id, now) == true,
                          showCheckmark: false,
                          onSelected: (_) => system.setStopHeld(s.id, now, true),
                        ),
                        ChoiceChip(
                          label: const Text('Slipped'),
                          selected: system.stopHeldInWeek(s.id, now) == false,
                          showCheckmark: false,
                          onSelected: (_) => system.setStopHeld(s.id, now, false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('Add'),
        _input(_what, 'I stop… (e.g. checking email before 9, saying yes to every meeting)',
            key: const Key('stop-what')),
        const SizedBox(height: 8),
        _input(_room, 'So I have room for… (optional)'),
        const SizedBox(height: 12),
        PrimaryButton('Add', icon: Icons.add_rounded, onPressed: () {
          if (system.addStop(_what.text, makesRoomFor: _room.text) == null) {
            toast(context, 'Write what you\'re stopping.');
            return;
          }
          _what.clear();
          _room.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Gratitude letter ───────────────────────────────────────────────────

/// A letter to someone who changed your life — then deliver it.
class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final _to = TextEditingController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _to.dispose();
    _text.dispose();
    super.dispose();
  }

  void _deliver(PersonalSystemProvider system, LogEntry l) {
    final c = TextEditingController();
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
            Text('Delivered', style: AppText.title()),
            const SizedBox(height: 10),
            _input(c, 'How did ${l.str('to')} react? How did you feel?', lines: 2),
            const SizedBox(height: 12),
            PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              system.deliverGratitude(l.id, reaction: c.text);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    ).whenComplete(c.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final names = <String>{
      for (final p in activeProfile.keyPeople) p.name,
      for (final p in system.people) p.text,
    }.where((n) => n.isNotEmpty).toList();
    return OnoPage(
      showBack: true,
      eyebrow: 'Social · 20 minutes',
      title: 'Gratitude letter',
      subtitle:
          'Write to someone who changed your life and never heard it properly. Then deliver it — read it to them if you can.',
      children: [
        const SectionHeader('To'),
        if (names.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in names)
                ActionChip(label: Text(n), onPressed: () => setState(() => _to.text = n)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _input(_to, 'Name — a teacher, a parent, a mentor, a friend'),
        const SectionHeader('The letter'),
        _input(_text,
            'What they did, specifically. How it changed you. Where you are now because of it.',
            lines: 8, key: const Key('gratitude-text')),
        const SizedBox(height: 12),
        PrimaryButton('Save the letter', icon: Icons.favorite_outline_rounded,
            onPressed: () {
          if (system.writeGratitude(_to.text, _text.text) == null) {
            toast(context, 'Who is it for, and what do you want to say?');
            return;
          }
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: _text.text));
          _to.clear();
          _text.clear();
          FocusManager.instance.primaryFocus?.unfocus();
          toast(context, 'Saved and copied. Now deliver it.');
        }),
        if (system.gratitudeLetters.isNotEmpty) ...[
          const SectionHeader('Your letters'),
          for (final l in system.gratitudeLetters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To ${l.str('to')}', style: AppText.heading()),
                    Text(l.text, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: AppText.small()),
                    if (l.str('status') == 'delivered')
                      Text('Delivered${(l.str('reaction') ?? '').isEmpty ? '' : ' — ${l.str('reaction')}'}',
                          style: AppText.small(color: AppColors.body))
                    else
                      TextButton(
                        onPressed: () => _deliver(system, l),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('I delivered it'),
                      ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Role models ────────────────────────────────────────────────────────

/// People one step ahead: what to learn from each, and the one question
/// you'd ask them.
class RoleModelsScreen extends StatefulWidget {
  const RoleModelsScreen({super.key});

  @override
  State<RoleModelsScreen> createState() => _RoleModelsScreenState();
}

class _RoleModelsScreenState extends State<RoleModelsScreen> {
  final _name = TextEditingController();
  final _learn = TextEditingController();
  final _question = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _learn.dispose();
    _question.dispose();
    super.dispose();
  }

  void _answer(PersonalSystemProvider system, LogEntry m) {
    final c = TextEditingController(text: m.str('answer') ?? '');
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
            Text('What ${m.text} said', style: AppText.title()),
            Text(m.str('question') ?? '', style: AppText.small()),
            const SizedBox(height: 10),
            _input(c, 'Their answer, in their words', lines: 3),
            const SizedBox(height: 12),
            PrimaryButton('Save', icon: Icons.check_rounded, onPressed: () {
              system.answerRoleModel(m.id, c.text);
              Navigator.of(ctx).pop();
            }),
          ],
        ),
      ),
    ).whenComplete(c.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Skill · learning by watching',
      title: 'Role models',
      subtitle:
          'People one step ahead of you — at work, in sport, in life. What exactly do they do that you want to learn? Then ask them one good question.',
      children: [
        for (final m in system.roleModels)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OnoCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(m.text, style: AppText.heading())),
                      IconButton(
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => system.removeRoleModel(m.id),
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.faint),
                      ),
                    ],
                  ),
                  if ((m.str('learn') ?? '').isNotEmpty)
                    Text('To learn: ${m.str('learn')}', style: AppText.small()),
                  if ((m.str('question') ?? '').isNotEmpty)
                    Text('Ask: ${m.str('question')}',
                        style: AppText.small(color: AppColors.greyLight)),
                  if ((m.str('answer') ?? '').isNotEmpty)
                    Text('They said: ${m.str('answer')}',
                        style: AppText.small(color: AppColors.body)),
                  TextButton(
                    onPressed: () => _answer(system, m),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text((m.str('answer') ?? '').isEmpty
                        ? 'I asked — save the answer'
                        : 'Edit answer'),
                  ),
                ],
              ),
            ),
          ),
        if (system.roleModels.isEmpty)
          const EmptyNote('Who is one step ahead of where you want to be?',
              icon: Icons.emoji_people_outlined),
        const SectionHeader('Add'),
        _input(_name, 'Name', key: const Key('model-name')),
        const SizedBox(height: 8),
        _input(_learn, 'What exactly do they do that you want to learn?'),
        const SizedBox(height: 8),
        _input(_question, 'The one question you\'d ask them'),
        const SizedBox(height: 12),
        PrimaryButton('Add', icon: Icons.add_rounded, onPressed: () {
          if (system.addRoleModel(_name.text,
                  learn: _learn.text, question: _question.text) ==
              null) {
            toast(context, 'Name them first.');
            return;
          }
          _name.clear();
          _learn.clear();
          _question.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

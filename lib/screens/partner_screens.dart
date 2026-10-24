import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

/// One accountability partner: a two-way pact and a weekly check-in.
class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _name = TextEditingController();
  final _mine = TextEditingController();
  final _theirs = TextEditingController();
  final _note = TextEditingController();
  final _stake = TextEditingController();
  int _weekday = DateTime.friday;
  bool _editing = false;
  // No answer until they choose one: a tap shouldn't record "kept".
  String? _myAnswer;
  String? _theirAnswer;
  bool _changing = false;

  @override
  void dispose() {
    for (final c in [_name, _mine, _theirs, _note, _stake]) {
      c.dispose();
    }
    super.dispose();
  }

  void _edit(LogEntry? p) {
    _name.text = p?.text ?? '';
    _mine.text = p?.str('mine') ?? '';
    _theirs.text = p?.str('theirs') ?? '';
    _stake.text = p?.str('stake') ?? '';
    _weekday = (p?.number('weekday') ?? DateTime.friday).toInt();
    setState(() => _editing = true);
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          style: AppText.body(color: AppColors.white),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _answers(String who, String? value, ValueChanged<String> onChanged) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(who, style: AppText.small(color: AppColors.white)),
          const SizedBox(height: 6),
          Segmented(
            labels: const ['Kept', 'Partly', 'Missed'],
            index: value == null ? -1 : PersonalSystemProvider.checkinAnswers.indexOf(value),
            onChanged: (i) => onChanged(PersonalSystemProvider.checkinAnswers[i]),
          ),
          const SizedBox(height: 12),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final p = system.partner;
    final today = timeNow();
    final checkin = system.partnerCheckinFor(today);
    final record = system.partnerRecord();
    final editing = _editing || p == null;
    return OnoPage(
      showBack: true,
      eyebrow: 'Accountability partner',
      title: 'Keep each other honest',
      subtitle:
          'One person, one promise each, one check-in a week. Telling someone how it went makes you far more likely to follow through.',
      children: [
        const SizedBox(height: 14),
        if (editing) ...[
          _field(_name, 'Partner', 'A friend, colleague or sibling'),
          _field(_mine, 'Your commitment', 'e.g. Train three times a week'),
          _field(_theirs, 'Their commitment', 'e.g. Write 500 words a day'),
          _field(_stake, 'The stake if one of you misses (optional)',
              'e.g. Buys the other coffee · gives 20 to a cause'),
          const SectionHeader('Check-in day'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                ChoiceChip(
                  label: Text(_days[d - 1]),
                  selected: _weekday == d,
                  onSelected: (_) => setState(() => _weekday = d),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton('Save the pact', icon: Icons.handshake_outlined, onPressed: () {
            if (_name.text.trim().isEmpty || _mine.text.trim().isEmpty) {
              toast(context, 'Name your partner and your commitment.');
              return;
            }
            system.setPartner(_name.text,
                mine: _mine.text, theirs: _theirs.text, weekday: _weekday, stake: _stake.text);
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _editing = false);
          }),
        ] else ...[
          OnoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('With ${p.text} · ${_days[(p.number('weekday') ?? 5).toInt() - 1]}s',
                    style: AppText.heading()),
                const SizedBox(height: 6),
                Text('You: ${p.str('mine')}', style: AppText.body(color: AppColors.white)),
                if ((p.str('theirs') ?? '').isNotEmpty)
                  Text('${p.text.split(' ').first}: ${p.str('theirs')}',
                      style: AppText.body(color: AppColors.white)),
                if ((p.str('stake') ?? '').isNotEmpty)
                  Text('Stake: ${p.str('stake')}', style: AppText.small(color: AppColors.social)),
                if (record.weeks > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Last ${record.weeks} weeks: you kept it ${record.mine}, ${p.text.split(' ').first} ${record.theirs}',
                      style: AppText.small()),
                ],
              ],
            ),
          ),
          const SectionHeader('This week'),
          GhostButton('Copy my update', icon: Icons.copy_rounded, onPressed: () {
            Clipboard.setData(ClipboardData(text: system.partnerUpdateText(today)));
            toast(context, 'Copied. Send it to ${p.text.split(' ').first}.');
          }),
          const SizedBox(height: 14),
          if (checkin != null && !_changing)
            Row(
              children: [
                Expanded(
                  child: Text(
                      'Checked in: you ${checkin.str('mine')}, ${p.text.split(' ').first} ${checkin.str('theirs')}.',
                      style: AppText.small(color: AppColors.white)),
                ),
                TextButton(
                  key: const Key('partner-change'),
                  onPressed: () => setState(() {
                    _changing = true;
                    _myAnswer = checkin.str('mine');
                    _theirAnswer = checkin.str('theirs');
                    _note.text = checkin.str('note') ?? '';
                  }),
                  child: const Text('Change'),
                ),
              ],
            )
          else ...[
            _answers('Did you keep yours?', _myAnswer, (v) => setState(() => _myAnswer = v)),
            _answers('Did ${p.text.split(' ').first} keep theirs?', _theirAnswer,
                (v) => setState(() => _theirAnswer = v)),
            TextField(
              controller: _note,
              style: AppText.body(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'What got in the way, or what helped (optional)'),
            ),
            const SizedBox(height: 10),
            PrimaryButton('Record the check-in', icon: Icons.check_rounded, onPressed: () {
              if (_myAnswer == null || _theirAnswer == null) {
                toast(context, 'Choose an answer for both of you.');
                return;
              }
              system.recordPartnerCheckin(today,
                  mine: _myAnswer!, theirs: _theirAnswer!, note: _note.text);
              setState(() => _changing = false);
              toast(context, 'Recorded.');
            }),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(onPressed: () => _edit(p), child: const Text('Change the pact')),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('End the pact?'),
                      content: const Text('Your check-ins stay. You can start a new pact any time.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep it')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('End it')),
                      ],
                    ),
                  );
                  if (yes != true || !context.mounted) return;
                  system.endPartnership();
                  toast(context, 'Partnership ended. Your check-ins stay in the log.');
                },
                child: const Text('End it'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

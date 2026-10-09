import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Rest, planned before the calendar decides. Planned rest days and
/// holidays never break the streak; a lighter week still counts.
class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  String _kind = 'day';
  DateTime? _from;
  DateTime? _to;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final today = dayOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? _from ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to == null || _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
      }
    });
  }

  String _range(LogEntry r) {
    final from = DateTime.tryParse(r.str('from') ?? '');
    final to = DateTime.tryParse(r.str('to') ?? '');
    if (from == null || to == null) return '';
    return from == to ? shortDate(from) : '${shortDate(from)} – ${shortDate(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = dayOnly(DateTime.now());
    final upcoming = [
      for (final r in system.restPlans)
        if (!(DateTime.tryParse(r.str('to') ?? '') ?? today).isBefore(today)) r
    ];
    final nextSat = today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
    return OnoPage(
      showBack: true,
      eyebrow: 'Body & mind · recovery',
      title: 'Plan your rest',
      subtitle:
          'Recovery is where strength and good judgement are built. Plan it like a meeting — planned rest days never break your streak.',
      children: [
        if (upcoming.isNotEmpty) ...[
          const SectionHeader('Planned'),
          for (final r in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OnoCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(PersonalSystemProvider.restKinds[r.str('kind')] ?? 'Rest',
                              style: AppText.heading()),
                          Text('${_range(r)}${r.text.isEmpty ? '' : ' · ${r.text}'}',
                              style: AppText.small()),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => system.removeRest(r.id),
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.faint),
                    ),
                  ],
                ),
              ),
            ),
        ] else
          const EmptyNote('Nothing planned. Put one rest day in the next two weeks.',
              icon: Icons.beach_access_outlined),
        const SectionHeader('Plan rest'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in PersonalSystemProvider.restKinds.entries)
              ChoiceChip(
                label: Text(k.value),
                selected: _kind == k.key,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _kind = k.key;
                  if (k.key == 'light' && _from != null) {
                    _to = _from!.add(const Duration(days: 6));
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ActionChip(
              label: Text('This Saturday · ${shortDate(nextSat)}'),
              onPressed: () => setState(() {
                _from = nextSat;
                _to = _kind == 'light' ? nextSat.add(const Duration(days: 6)) : nextSat;
              }),
            ),
            ActionChip(
              label: Text(_from == null ? 'From…' : 'From ${shortDate(_from!)}'),
              onPressed: () => _pick(true),
            ),
            ActionChip(
              label: Text(_to == null ? 'To…' : 'To ${shortDate(_to!)}'),
              onPressed: () => _pick(false),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
              hintText: 'Optional: what restores you (a walk, family, no laptop)'),
        ),
        const SizedBox(height: 12),
        PrimaryButton('Plan it', icon: Icons.event_available_rounded, onPressed: () {
          if (_from == null) {
            toast(context, 'Pick a day first.');
            return;
          }
          system.planRest(_kind, _from!, _to ?? _from!, note: _note.text);
          setState(() {
            _from = null;
            _to = null;
            _note.clear();
          });
          toast(context, 'Planned. Protect it like a meeting.');
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

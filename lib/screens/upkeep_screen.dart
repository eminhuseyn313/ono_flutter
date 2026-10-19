import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Care: the recurring things that slip when life is busy — check-ups,
/// the barber, nails, the car — with when each is next due or booked.
class UpkeepScreen extends StatefulWidget {
  const UpkeepScreen({super.key});

  @override
  State<UpkeepScreen> createState() => _UpkeepScreenState();
}

class _UpkeepScreenState extends State<UpkeepScreen> {
  final _name = TextEditingController();
  int _every = 28;
  String _kind = 'grooming';

  static const _intervals = [
    (14, '2 weeks'),
    (28, '4 weeks'),
    (42, '6 weeks'),
    (90, '3 months'),
    (180, '6 months'),
    (365, 'Yearly'),
    (730, 'Every 2 years'),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _every2(int days) =>
      _intervals.where((i) => i.$1 == days).firstOrNull?.$2.toLowerCase() ?? 'every $days days';

  String _due(PersonalSystemProvider system, LogEntry u) {
    if (system.careKindOf(u) == 'documents') {
      final exp = system.upkeepExpires(u);
      if (exp == null) return 'Add the expiry date';
      final left = exp.daysSince(dayOnly(DateTime.now()));
      if (left < 0) return 'Expired ${shortDate(exp)}';
      if (left <= PersonalSystemProvider.renewLeadDays) {
        return 'Expires ${shortDate(exp)} — time to renew';
      }
      return 'Expires ${shortDate(exp)} ${exp.year}';
    }
    if (system.upkeepBooked(u) case final b?) {
      final days = b.daysSince(dayOnly(DateTime.now()));
      return days == 0
          ? 'Booked for today'
          : days == 1
              ? 'Booked for tomorrow'
              : days < 0
                  ? 'Booked for ${shortDate(b)} — done?'
                  : 'Booked for ${weekdayName(b.weekday).substring(0, 3)} ${shortDate(b)}';
    }
    final next = system.upkeepNextDue(u);
    if (next == null) return 'No date yet — tap Done… to set the last time';
    final days = next.daysSince(dayOnly(DateTime.now()));
    if (days < 0) return 'Overdue by ${-days} d';
    if (days == 0) return 'Due today';
    return days < 60 ? 'Due in $days d' : 'Next ${shortDate(next)}';
  }

  /// The expiry date of a document: after adding it, or once renewed.
  Future<DateTime?> _pickExpiry(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 20),
      helpText: 'When does it expire?',
    );
  }

  Future<void> _done(PersonalSystemProvider system, LogEntry u) async {
    if (system.careKindOf(u) == 'documents') {
      final exp = await _pickExpiry(system.upkeepExpires(u));
      if (exp == null || !mounted) return;
      system.setUpkeepExpires(u.id, exp);
      toast(context, 'Noted. ONO asks again ${PersonalSystemProvider.renewLeadDays} days before it expires.');
      return;
    }
    final now = DateTime.now();
    // A date, not just today: the last visit may have been months ago.
    final on = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'When was it done?',
    );
    if (on == null || !mounted) return;
    system.markUpkeepDone(u.id, on: on);
    toast(context, 'Noted. The next one is remembered.');
  }

  void _edit(PersonalSystemProvider system, LogEntry u) {
    var every = (u.number('every') ?? 365).toInt();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final usual = system.upkeepUsualEvery(u);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.text, style: AppText.title()),
                  Text(_due(system, u), style: AppText.small()),
                  const SizedBox(height: 14),
                  if (system.careKindOf(u) != 'documents') ...[
                  Text('How often', style: AppText.small()),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final i in _intervals)
                        ChoiceChip(
                          label: Text(i.$2),
                          selected: every == i.$1,
                          onSelected: (_) {
                            setSheet(() => every = i.$1);
                            system.editUpkeep(u.id, every: i.$1);
                          },
                        ),
                    ],
                  ),
                  if (usual != null && usual != every) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('care-usual'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        setSheet(() => every = usual);
                        system.editUpkeep(u.id, every: usual);
                      },
                      child: Text('You actually go about every $usual days — use that'),
                    ),
                  ],
                  ],
                  const SizedBox(height: 14),
                  GhostButton(
                      system.upkeepBooked(u) == null ? 'Booked it — pick the day' : 'Change the booked day',
                      icon: Icons.event_outlined, onPressed: () async {
                    final now = DateTime.now();
                    final day = await showDatePicker(
                      context: ctx,
                      initialDate: system.upkeepBooked(u) ?? now,
                      firstDate: dayOnly(now),
                      lastDate: DateTime(now.year + 2),
                      helpText: 'When is it booked?',
                    );
                    if (day == null) return;
                    system.bookUpkeep(u.id, day);
                    setSheet(() {});
                  }),
                  if (system.upkeepBooked(u) != null)
                    TextButton(
                      onPressed: () {
                        system.bookUpkeep(u.id, null);
                        setSheet(() {});
                      },
                      child: const Text('Cancel the booking'),
                    ),
                  const SizedBox(height: 6),
                  GhostButton('Remove', icon: Icons.delete_outline_rounded, onPressed: () {
                    Navigator.of(ctx).pop();
                    system.removeUpkeep(u.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('${u.text} removed.'),
                        action: SnackBarAction(label: 'Undo', onPressed: () => system.restoreLog(u)),
                      ));
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(PersonalSystemProvider system, LogEntry u) {
    final due = system.upkeepDue.contains(u);
    return InkWell(
      key: Key('care-${u.id}'),
      onTap: () => _edit(system, u),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.text, style: AppText.heading()),
                  Text(
                      system.careKindOf(u) == 'documents'
                          ? _due(system, u)
                          : '${_due(system, u)} · ${_every2((u.number('every') ?? 365).toInt())}',
                      style: AppText.small(color: due ? AppColors.warning : AppColors.grey)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _done(system, u),
              child: Text(system.careKindOf(u) == 'documents'
                  ? (system.upkeepExpires(u) == null ? 'Date…' : 'Renewed…')
                  : 'Done…'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final items = system.upkeep;
    return OnoPage(
      showBack: true,
      eyebrow: 'Care',
      title: 'Look after yourself',
      subtitle:
          'The things that slip when life is busy — check-ups, the barber, nails, the car. You choose how often (health ones with your doctor); ONO only remembers the dates.',
      children: [
        for (final kind in PersonalSystemProvider.careKinds.entries) ...[
          if (items.any((u) => system.careKindOf(u) == kind.key)) ...[
            SectionHeader(kind.value),
            OnoCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Column(
                children: [
                  for (final u in items)
                    if (system.careKindOf(u) == kind.key) _row(system, u),
                ],
              ),
            ),
          ],
        ],
        if (items.isEmpty) ...[
          const SizedBox(height: 14),
          const EmptyNote('Add what you want to keep up with — a few taps below.',
              icon: Icons.spa_outlined),
        ],
        const SectionHeader('Common ones'),
        for (final kind in PersonalSystemProvider.careKinds.entries)
          if (PersonalSystemProvider.upkeepSuggestions
              .any((s) => s.$3 == kind.key && !items.any((u) => u.text == s.$1))) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(kind.value, style: AppText.small()),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in PersonalSystemProvider.upkeepSuggestions)
                  if (s.$3 == kind.key && !items.any((u) => u.text == s.$1))
                    ActionChip(
                      label: Text(s.$1),
                      onPressed: () async {
                        if (s.$3 != 'documents') {
                          system.addUpkeep(s.$1, s.$2, kind: s.$3);
                          return;
                        }
                        // Only the date it expires — never its number.
                        final exp = await _pickExpiry(null);
                        if (exp == null) return;
                        system.addUpkeep(s.$1, 0, kind: s.$3, expires: exp);
                      },
                    ),
              ],
            ),
          ],
        const SectionHeader('Your own'),
        TextField(
          controller: _name,
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(hintText: 'e.g. Massage, physio review, tyre change'),
        ),
        const SizedBox(height: 8),
        Segmented(
          labels: [for (final k in PersonalSystemProvider.careKinds.values) k],
          index: PersonalSystemProvider.careKinds.keys.toList().indexOf(_kind),
          onChanged: (i) => setState(() => _kind = PersonalSystemProvider.careKinds.keys.elementAt(i)),
        ),
        const SizedBox(height: 8),
        if (_kind == 'documents')
          Text('Only its expiry date is kept — never its number.', style: AppText.small())
        else
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in _intervals)
              ChoiceChip(
                label: Text(i.$2),
                selected: _every == i.$1,
                onSelected: (_) => setState(() => _every = i.$1),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GhostButton('Add', icon: Icons.add_rounded, onPressed: () async {
          if (_name.text.trim().isEmpty) {
            toast(context, 'Give it a name first.');
            return;
          }
          DateTime? exp;
          if (_kind == 'documents') {
            exp = await _pickExpiry(null);
            if (exp == null) return;
          }
          if (system.addUpkeep(_name.text, _every, kind: _kind, expires: exp) != null) {
            _name.clear();
            FocusManager.instance.primaryFocus?.unfocus();
          }
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

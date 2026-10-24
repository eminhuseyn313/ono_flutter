import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/checkups.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../time.dart';

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

  static const _ownKinds = ['health', 'grooming', 'home', 'documents'];

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
      final left = exp.daysSince(dayOnly(timeNow()));
      if (left < 0) return 'Expired ${shortDate(exp)}';
      if (left <= PersonalSystemProvider.renewLeadDays) {
        return 'Expires ${shortDate(exp)} — time to renew';
      }
      return 'Expires ${shortDate(exp)} ${exp.year}';
    }
    if (system.upkeepBooked(u) case final b?) {
      final days = b.daysSince(dayOnly(timeNow()));
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
    final days = next.daysSince(dayOnly(timeNow()));
    if (days < 0) return 'Overdue by ${-days} d';
    if (days == 0) return 'Due today';
    return days < 60 ? 'Due in $days d' : 'Next ${shortDate(next)}';
  }

  /// The expiry date of a document: after adding it, or once renewed.
  Future<DateTime?> _pickExpiry(DateTime? current) {
    final now = timeNow();
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
    final now = timeNow();
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

  void _edit(PersonalSystemProvider system, LogEntry item) {
    var every = (item.number('every') ?? 365).toInt();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          // Always the item as it is now, not as the sheet opened.
          final u = system.upkeep.where((x) => x.id == item.id).firstOrNull ?? item;
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
                    final now = timeNow();
                    final booked = system.upkeepBooked(u);
                    final day = await showDatePicker(
                      context: ctx,
                      // A booking that has passed can't be the starting day.
                      initialDate: booked == null || booked.isBefore(dayOnly(now)) ? now : booked,
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
          if (kind.key != 'for' && items.any((u) => system.careKindOf(u) == kind.key)) ...[
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
        // Someone in your care: their check-ups, under their name — and
        // anything kept for someone no longer in your care, so it can go.
        for (final p in system.people)
          if (system.inMyCare(p) || system.careFor(p).isNotEmpty) ...[
          SectionHeader(system.inMyCare(p) ? 'For ${p.text}' : 'For ${p.text} · no longer in your care'),
          if (system.careFor(p).isNotEmpty)
            OnoCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Column(children: [for (final u in system.careFor(p)) _row(system, u)]),
            ),
          const SizedBox(height: 6),
          if (system.inMyCare(p))
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in const [('Check-up', 365), ('Dentist', 180), ('Eye test', 365), ('Hearing test', 730)])
                if (!system.careFor(p).any((u) => u.text.endsWith(s.$1)))
                  ActionChip(
                    key: Key('care-for-${p.id}-${s.$1}'),
                    label: Text(s.$1),
                    onPressed: () => system.addUpkeep('${p.text.split(' ').first}: ${s.$1}', s.$2,
                        forPerson: p.id),
                  ),
            ],
          ),
        ],
        if (items.isEmpty) ...[
          const SizedBox(height: 14),
          const EmptyNote('Add what you want to keep up with — a few taps below.',
              icon: Icons.spa_outlined),
        ],
        _AskYourDoctor(system: system),
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
          labels: [for (final k in _ownKinds) PersonalSystemProvider.careKinds[k]!],
          index: _ownKinds.indexOf(_kind),
          onChanged: (i) => setState(() => _kind = _ownKinds[i]),
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

/// Check-ups and vaccines worth asking about at this age — questions for
/// a doctor, never "you are due". Needs only a birth year (and sex for
/// some), kept private on this device and your synced copy.
class _AskYourDoctor extends StatefulWidget {
  final PersonalSystemProvider system;
  const _AskYourDoctor({required this.system});

  @override
  State<_AskYourDoctor> createState() => _AskYourDoctorState();
}

class _AskYourDoctorState extends State<_AskYourDoctor> {
  late final _year = TextEditingController(text: widget.system.careBirthYear?.toString() ?? '');
  bool _editing = false;

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = widget.system;
    final set = system.careBirthYear != null && !_editing;
    final list = system.checkupsToAsk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('To ask your doctor about'),
        if (!set) ...[
          Text(
              'Your birth year (and sex, for a few) is enough to list check-ups and vaccines worth asking about. Kept with your private data, never sent to the coach.',
              style: AppText.small()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final s in sexOptions.entries)
                ChoiceChip(
                  label: Text(s.value),
                  selected: system.careSex == s.key,
                  showCheckmark: false,
                  onSelected: (on) => system.setCareDetails(sex: on ? s.key : ''),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('care-birth-year'),
                  controller: _year,
                  keyboardType: TextInputType.number,
                  style: AppText.body(color: AppColors.white),
                  decoration: const InputDecoration(hintText: 'Birth year, e.g. 1990'),
                ),
              ),
              TextButton(
                key: const Key('care-details-save'),
                onPressed: () {
                  final y = int.tryParse(_year.text.trim());
                  if (y == null || y < 1900 || y > timeNow().year) {
                    toast(context, 'Enter a four-digit year.');
                    return;
                  }
                  system.setCareDetails(birthYear: y);
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _editing = false);
                },
                child: const Text('Show'),
              ),
            ],
          ),
          if (_editing)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('care-details-forget'),
                  onPressed: () {
                    system.forgetCareDetails();
                    _year.clear();
                    setState(() => _editing = false);
                    toast(context, 'Forgotten.');
                  },
                  child: const Text('Forget these'),
                ),
              ],
            ),
        ] else ...[
          Text('Guidelines differ by country and by your history — take this list to your doctor, not as a schedule.',
              style: AppText.small()),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Text('Nothing more for now — what fits is already on your list.', style: AppText.small(color: AppColors.body))
          else
            OnoCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Column(
                children: [
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: AppText.body(color: AppColors.white)),
                                Text(c.only.isEmpty ? c.why : '${c.why} (${c.only})', style: AppText.small()),
                              ],
                            ),
                          ),
                          TextButton(
                            key: Key('checkup-${c.id}'),
                            onPressed: () async {
                              if (c.every == 0) {
                                system.takeCheckup(c);
                                return;
                              }
                              // A recent one shouldn't show as due at once.
                              final now = timeNow();
                              final last = await showDatePicker(
                                context: context,
                                helpText: 'When did you last have it? (Cancel if never or not sure)',
                                initialDate: now,
                                firstDate: DateTime(now.year - 15),
                                lastDate: now,
                              );
                              system.takeCheckup(c, lastDone: last);
                            },
                            child: Text(c.every > 0 ? 'Add' : 'Asked'),
                          ),
                          IconButton(
                            tooltip: 'Not for me',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.faint,
                            onPressed: () => system.setDone('checkup:off:${c.id}', true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          TextButton(
            onPressed: () => setState(() {
              _editing = true;
              _year.text = system.careBirthYear?.toString() ?? '';
            }),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
                'Born ${system.careBirthYear}${(system.careSex ?? '').isEmpty ? '' : ' · ${sexOptions[system.careSex]}'} — change'),
          ),
        ],
      ],
    );
  }
}

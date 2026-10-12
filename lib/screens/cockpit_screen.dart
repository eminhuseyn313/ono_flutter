import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Career cockpit: the record that turns daily work into a target-role
/// case. 1:1s with follow-ups you own, a decision journal that comes back
/// in 90 days, and a monthly readiness check against the bar.
class CockpitScreen extends StatefulWidget {
  final int initialTab;
  const CockpitScreen({super.key, this.initialTab = 0});

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final dueReviews = system.dueDecisionReviews(DateTime.now()).length;
    return OnoPage(
      showBack: true,
      eyebrow: '${activeProfile.currentRole} → ${activeProfile.targetRole}',
      title: 'Career cockpit',
      subtitle:
          'Do the next job before you have it — and keep the record, so the case writes itself.',
      children: [
        const SizedBox(height: 14),
        Segmented(
          labels: [
            '1:1s',
            dueReviews > 0 ? 'Decisions · $dueReviews' : 'Decisions',
            'Readiness',
          ],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 6),
        ...switch (_tab) {
          0 => _oneOnOnes(context, system),
          1 => _decisions(context, system),
          _ => _readiness(context, system),
        },
      ],
    );
  }

  // ── 1:1s ───────────────────────────────────────────────────────────────

  List<Widget> _oneOnOnes(BuildContext context, PersonalSystemProvider system) {
    final open = system.openFollowUps;
    final logs = system.logsOf('one_on_one');
    return [
      const SizedBox(height: 12),
      PrimaryButton('Log a 1:1',
          icon: Icons.add_rounded, onPressed: () => _logOneOnOne(context)),
      const SizedBox(height: 8),
      Text('Before it: run six-questions-deep prep from Today → Work.',
          style: AppText.small().copyWith(fontSize: 12)),
      SectionHeader('Follow-ups you own · ${open.length}'),
      if (open.isEmpty)
        const EmptyNote('Nothing open. Follow-ups from each 1:1 land here.',
            icon: Icons.task_alt_rounded)
      else
        OnoCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              for (final f in open)
                CheckRow(
                  checked: false,
                  title: f.text,
                  subtitle: '${f.withWhom} · ${shortDate(f.date)}',
                  onChanged: (_) => system.setDone(f.key, true),
                ),
            ],
          ),
        ),
      if (logs.isNotEmpty) ...[
        const SectionHeader('History'),
        for (final l in logs.take(12))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OnoCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${l.str('with') ?? activeProfile.manager} · ${weekdayName(l.date.weekday).substring(0, 3)} ${shortDate(l.date)}',
                      style: AppText.eyebrow()),
                  const SizedBox(height: 6),
                  Text(l.text.isEmpty ? '—' : l.text, style: AppText.body()),
                ],
              ),
            ),
          ),
      ],
    ];
  }

  Future<void> _logOneOnOne(BuildContext context) async {
    final withC = TextEditingController(text: activeProfile.manager);
    final decided = TextEditingController();
    final followUps = TextEditingController();
    final ok = await _sheet(context, 'Log a 1:1', [
      _field(withC, 'With'),
      _field(decided, 'What was decided or learned', lines: 3),
      _field(followUps, 'Your follow-ups — one per line', lines: 4),
    ]);
    if (ok != true || !context.mounted) return;
    if (decided.text.trim().isEmpty && followUps.text.trim().isEmpty) {
      toast(context, 'Nothing logged — write what was decided or a follow-up.');
      return;
    }
    {
      context.read<PersonalSystemProvider>().addOneOnOne(
          withWhom: withC.text,
          decided: decided.text,
          followUps: followUps.text.split('\n'));
      toast(context, '1:1 logged. Follow-ups are on Today.');
    }
  }

  // ── Decisions ──────────────────────────────────────────────────────────

  List<Widget> _decisions(BuildContext context, PersonalSystemProvider system) {
    final due = system.dueDecisionReviews(DateTime.now());
    final all = system.logsOf('decision');
    final reviewed = all.where((l) => l.str('verdict') != null).toList();
    final right = reviewed.where((l) => l.str('verdict') == 'right').length;
    return [
      const SizedBox(height: 12),
      PrimaryButton('Record a decision',
          icon: Icons.add_rounded, onPressed: () => _logDecision(context)),
      const SizedBox(height: 8),
      Text(
          'Write what you expect before you know the outcome. In 90 days ONO asks whether the call was right — that gap is product judgment.',
          style: AppText.small().copyWith(fontSize: 12)),
      const SizedBox(height: 14),
      OnoCard(
        child: Row(
          children: [
            Expanded(child: StatTile('${all.length}', 'decisions')),
            Expanded(child: StatTile('${reviewed.length}', 'reviewed')),
            Expanded(
                child: StatTile(
                    reviewed.isEmpty
                        ? '—'
                        : '${(right * 100 / reviewed.length).round()}',
                    'right',
                    unit: reviewed.isEmpty ? null : '%')),
          ],
        ),
      ),
      if (due.isNotEmpty) ...[
        const SectionHeader('Due for review'),
        for (final d in due)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DecisionCard(
                entry: d, onReview: () => _reviewDecision(context, d)),
          ),
      ],
      if (all.isNotEmpty) ...[
        const SectionHeader('Journal'),
        for (final d in all.where((d) => !due.contains(d)).take(15))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DecisionCard(entry: d),
          ),
      ],
    ];
  }

  Future<void> _logDecision(BuildContext context) async {
    final decision = TextEditingController();
    final options = TextEditingController();
    final why = TextEditingController();
    final expected = TextEditingController();
    final ok = await _sheet(context, 'Record a decision', [
      _field(decision, 'The decision', lines: 2),
      _field(options, 'Options you considered', lines: 2),
      _field(why, 'Why this one', lines: 2),
      _field(expected, 'What you expect to happen — be specific', lines: 2),
    ]);
    if (ok == true && context.mounted && decision.text.trim().isEmpty) {
      toast(context, 'Nothing recorded — write the decision first.');
      return;
    }
    if (ok == true && context.mounted) {
      context.read<PersonalSystemProvider>().addDecision(
          decision: decision.text,
          options: options.text,
          why: why.text,
          expected: expected.text);
      toast(context, 'Recorded. ONO brings it back in 90 days.');
    }
  }

  Future<void> _reviewDecision(BuildContext context, LogEntry d) async {
    final outcome = TextEditingController();
    var verdict = 'right';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Was the call right?', style: AppText.title()),
                const SizedBox(height: 8),
                Text(d.text, style: AppText.heading()),
                if ((d.str('expected') ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('You expected: ${d.str('expected')}',
                      style: AppText.small()),
                ],
                const SizedBox(height: 12),
                _field(outcome, 'What actually happened', lines: 3),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in ['right', 'mixed', 'wrong'])
                      ChoiceChip(
                        label: Text(v[0].toUpperCase() + v.substring(1)),
                        selected: verdict == v,
                        showCheckmark: false,
                        selectedColor: AppColors.accent,
                        labelStyle: AppText.small(
                                color: verdict == v
                                    ? AppColors.ink
                                    : AppColors.greyLight)
                            .copyWith(fontWeight: FontWeight.w700),
                        onSelected: (_) => set(() => verdict = v),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton('Save review',
                    onPressed: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context
          .read<PersonalSystemProvider>()
          .reviewDecision(d.id, outcome: outcome.text, verdict: verdict);
      HapticFeedback.mediumImpact();
      toast(context, 'Reviewed. Write the lesson as one rule in a note.');
    }
  }

  // ── Readiness ──────────────────────────────────────────────────────────

  List<Widget> _readiness(BuildContext context, PersonalSystemProvider system) {
    final r = system.readiness;
    final gap = system.readinessGap;
    return [
      const SizedBox(height: 12),
      Text(
          'Rate yourself monthly against the ${activeProfile.targetRole} bar ($readinessBar = ready). Rate the evidence, not the hope.',
          style: AppText.small()),
      if (gap != null) ...[
        const SizedBox(height: 12),
        OnoCard(
          accent: AppColors.accent,
          padding: const EdgeInsets.all(14),
          child: Text(
              'Biggest gap: ${gap.name} (${r[gap.id]}/5). It goes into your Sunday brief until it meets the bar.',
              style: AppText.small(color: AppColors.greyLight)),
        ),
      ],
      const SizedBox(height: 6),
      for (final d in readinessDimensions)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: OnoCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(d.name, style: AppText.heading())),
                    Text(r[d.id] == null ? '—' : '${r[d.id]}/5',
                        style: AppText.small(
                                color: (r[d.id] ?? 0) >= readinessBar
                                    ? AppColors.body
                                    : AppColors.white)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(d.bar, style: AppText.small().copyWith(fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var v = 1; v <= 5; v++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              system.saveReadiness({...r, d.id: v});
                            },
                            child: Container(
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (r[d.id] ?? 0) >= v
                                    ? (v >= readinessBar
                                        ? AppColors.body
                                        : AppColors.accent)
                                    : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$v',
                                  style: AppText.small(
                                          color: (r[d.id] ?? 0) >= v
                                              ? AppColors.ink
                                              : AppColors.grey)
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (r[d.id] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        '${r[d.id]} · ${levelsOf(system.areaById(d.id))[r[d.id]! - 1]}',
                        style: AppText.small(color: AppColors.greyLight)
                            .copyWith(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      Text(
          'Evidence so far: ${system.evidenceCount} archive items · ${system.countOf('decision')} decisions · ${system.countOf('one_on_one')} 1:1s · ${system.countOf('artifact')} artifacts.',
          style: AppText.small()),
    ];
  }

  // ── Shared ─────────────────────────────────────────────────────────────

  static Widget _field(TextEditingController c, String hint,
          {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines + 3,
          decoration: InputDecoration(hintText: hint),
        ),
      );

  Future<bool?> _sheet(
          BuildContext context, String title, List<Widget> fields) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title()),
                const SizedBox(height: 12),
                ...fields,
                const SizedBox(height: 6),
                PrimaryButton('Save',
                    onPressed: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          ),
        ),
      );
}

class _DecisionCard extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback? onReview;
  const _DecisionCard({required this.entry, this.onReview});

  @override
  Widget build(BuildContext context) {
    final verdict = entry.str('verdict');
    final reviewOn = entry.str('review_on');
    return OnoCard(
      accent: onReview != null
          ? AppColors.accent
          : switch (verdict) {
              'right' => AppColors.body,
              'mixed' => AppColors.warning,
              'wrong' => AppColors.danger,
              _ => null,
            },
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              verdict != null
                  ? '${verdict.toUpperCase()} · ${shortDate(entry.date)}'
                  : reviewOn == null
                      ? shortDate(entry.date)
                      : 'REVIEW ${shortDate(DateTime.parse(reviewOn))}',
              style: AppText.eyebrow()),
          const SizedBox(height: 6),
          Text(entry.text, style: AppText.heading()),
          if ((entry.str('expected') ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Expected: ${entry.str('expected')}', style: AppText.small()),
          ],
          if ((entry.str('outcome') ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Happened: ${entry.str('outcome')}',
                style: AppText.small(color: AppColors.greyLight)),
          ],
          if (onReview != null) ...[
            const SizedBox(height: 10),
            GhostButton('Review now', onPressed: onReview),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Your record: what you've done, gathered from what you logged and ready
/// to copy — for a review or a CV, or for a coach or mentor. One place
/// instead of three, chosen by who it's for.
class RecordScreen extends StatefulWidget {
  /// 0 = for a review or CV, 1 = for a coach.
  final int initialFor;
  const RecordScreen({super.key, this.initialFor = 0});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late int _for = widget.initialFor.clamp(0, 1);
  int _range = 1;
  int _period = 0;
  bool _mornings = true;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final String text;
    if (_for == 0) {
      final since = switch (_range) {
        0 => DateTime(now.year, now.month - 3, now.day),
        1 => DateTime(now.year, now.month - 6, now.day),
        _ => system.programStart,
      };
      text = system.bragText(since: since);
    } else {
      final from = _period == 0
          ? system.monthStart(system.programMonth)
          : system.quarterStart(system.programQuarter);
      text = system.coachReportText(from, dayOnly(now).plusDays(1), mornings: _mornings);
    }
    return OnoPage(
      showBack: true,
      eyebrow: 'Your record',
      title: 'What you\'ve done',
      subtitle:
          'Gathered from what you logged, so nothing gets forgotten. Notes, letters and journal entries are never included.',
      children: [
        const SizedBox(height: 14),
        Segmented(
          labels: const ['For a review or CV', 'For a coach'],
          index: _for,
          onChanged: (i) => setState(() => _for = i),
        ),
        const SizedBox(height: 10),
        if (_for == 0)
          Segmented(
            labels: const ['3 months', '6 months', 'All'],
            index: _range,
            onChanged: (i) => setState(() => _range = i),
          )
        else ...[
          Segmented(
            labels: const ['This month', 'This quarter'],
            index: _period,
            onChanged: (i) => setState(() => _period = i),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _mornings,
            onChanged: (v) => setState(() => _mornings = v),
            title: Text('Include energy and sleep', style: AppText.body(color: AppColors.white)),
          ),
        ],
        const SizedBox(height: 12),
        OnoCard(
          padding: const EdgeInsets.all(14),
          child: SelectableText(text, style: AppText.small(color: AppColors.white)),
        ),
        const SizedBox(height: 12),
        PrimaryButton('Copy', icon: Icons.copy_rounded, onPressed: () {
          Clipboard.setData(ClipboardData(text: text));
          toast(context, _for == 0 ? 'Copied. Add the numbers only you know.' : 'Copied. Add your question at the end.');
        }),
        // The case for the next role is the built-in plan's (readiness).
        if (system.isBuiltInPerson && activeProfile.targetRole.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          GhostButton('The case for ${activeProfile.targetRole}',
              icon: Icons.work_outline_rounded, onPressed: () => context.push('/case')),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

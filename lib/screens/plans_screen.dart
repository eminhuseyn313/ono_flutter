import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// If-then plans for the Daily 10. "When X happens → I do Y" makes the cue
/// do the remembering; each plan shows on Today and inside its reminder.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final Map<String, TextEditingController> _c = {};
  final Map<String, TextEditingController> _m = {};
  late PersonalSystemProvider _system;

  // An item can arrive by sync while this screen is open.
  TextEditingController _cue(String id) => _c.putIfAbsent(
      id, () => TextEditingController(text: _system.cueFor(id)));
  TextEditingController _min(String id) => _m.putIfAbsent(
      id, () => TextEditingController(text: _system.minimumFor(id)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _system = context.read<PersonalSystemProvider>();
    if (_c.isNotEmpty) return;
    final system = _system;
    for (final n in system.dailyItems) {
      _c[n.id] = TextEditingController(text: system.cueFor(n.id));
      _m[n.id] = TextEditingController(text: system.minimumFor(n.id));
    }
  }

  @override
  void dispose() {
    // Reminders carry the cues; reschedule once, not on every keystroke.
    _system.resyncReminders();
    for (final c in [..._c.values, ..._m.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Daily ${system.dailyCount}',
      title: 'If-then plans',
      subtitle:
          'Name the moment, not the intention. "When I park at the office → sigh ×3" beats "be calmer".',
      children: [
        for (final g in nonNegotiableGroups) ...[
          SectionHeader(g[1]),
          OnoCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (final n in system.dailyItems.where((n) => n.when == g[0]))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            LaneDot(n.lane),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(n.title,
                                  style: AppText.small(color: AppColors.white)
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                            if (system.hasCustomCue(n.id))
                              TextButton(
                                onPressed: () {
                                  system.setCue(n.id, '');
                                  _cue(n.id).text = system.cueFor(n.id);
                                },
                                child: const Text('Reset'),
                              ),
                          ],
                        ),
                        TextField(
                          controller: _cue(n.id),
                          maxLines: null,
                          style: AppText.body(color: AppColors.greyLight),
                          textInputAction: TextInputAction.done,
                          onChanged: (v) =>
                              system.setCue(n.id, v, reschedule: false),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'When … → I …',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _min(n.id),
                          maxLines: null,
                          style: AppText.small(color: AppColors.greyLight),
                          textInputAction: TextInputAction.done,
                          onChanged: (v) => system.setMinimum(n.id, v),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Minimum version, for hard days',
                            hintText: 'The 2-minute version',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

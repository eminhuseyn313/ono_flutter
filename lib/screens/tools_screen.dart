import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/tool_index.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Every tool in one searchable list: "Find a tool".
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static const _groupColors = {
    'Plan': AppColors.accent,
    'Direction': AppColors.skill,
    'Practice': AppColors.skill,
    'People': AppColors.social,
    'Hard moments': AppColors.mind,
    'Body': AppColors.body,
    'Look back': AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final builtIn = system.isBuiltInPerson;
    final q = _query.text;
    final found = [
      for (final t in toolIndex)
        if ((builtIn || !t.builtInOnly) && t.matches(q)) t
    ];
    // Before a search, the tools used in the last 30 days come first.
    final recent = system.recentToolRoutes();
    final seen = <String>{};
    final lately = q.trim().isNotEmpty
        ? const <ToolEntry>[]
        : [
            for (final t in found)
              if (recent.contains(t.route.split('?').first) && seen.add(t.route.split('?').first)) t
          ];
    return OnoPage(
      showBack: true,
      eyebrow: '${found.length} tools',
      title: 'Find a tool',
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _query,
          onChanged: (_) => setState(() {}),
          style: AppText.body(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: 'stress, interview, sleep…',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        if (found.isEmpty) ...[
          const SizedBox(height: 16),
          Text('Nothing for "$q". Try another word, or',
              style: AppText.small()),
          TextButton(
            onPressed: () => context.push('/need'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('say what you need right now'),
          ),
        ],
        if (lately.isNotEmpty) ...[
          const SectionHeader('Used lately'),
          _card(context, lately),
        ],
        for (final g in toolGroups)
          if (found.any((t) => t.group == g)) ...[
            SectionHeader(g),
            _card(context, found.where((t) => t.group == g).toList()),
          ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _card(BuildContext context, List<ToolEntry> tools) => OnoCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, t) in tools.indexed) ...[
              if (i > 0) const Divider(indent: 16),
              ListTile(
                title: Text(t.title, style: AppText.heading()),
                subtitle: Text(t.what, style: AppText.small()),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: _groupColors[t.group] ?? AppColors.grey),
                onTap: () => context.push(t.route),
              ),
            ],
          ],
        ),
      );
}

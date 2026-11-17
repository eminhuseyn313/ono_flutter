import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/plan_content.dart';
import '../data/plan_import.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// More from your plan: the sections a plan holds that ONO has no screen
/// for yet, shown as written, so nothing an AI wrote for you is lost.
class PlanMoreScreen extends StatelessWidget {
  const PlanMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<PersonalSystemProvider>();
    final extras = plan.extras;
    return OnoPage(
      showBack: true,
      eyebrow: 'Your plan',
      title: 'More from your plan',
      subtitle: extras.isEmpty
          ? 'Everything in your plan already has its place in ONO.'
          : 'Parts of your plan ONO has no screen for yet, exactly as they were written.',
      children: [
        if (extras.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: GhostButton('Your plan file', icon: Icons.description_outlined,
                onPressed: () => context.push('/plan-file')),
          ),
        for (final e in extras.entries) ...[
          SectionHeader(planSectionTitle(e.key)),
          OnoCard(
            key: Key('plan-more-${e.key}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _rows(e.value, 0),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  /// Indent, capped so deep nesting never pushes text off a small screen.
  static double _pad(int depth) => depth.clamp(0, 4) * 14.0;

  /// The title of an entry written as an object: its name, title or text.
  static String? _titleOf(Map m) {
    for (final k in const ['title', 'name', 'text', 'what', 'label']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static List<Widget> _rows(Object? v, int depth) {
    final indent = EdgeInsets.only(left: _pad(depth), top: 4, bottom: 4);
    if (v is List) {
      return [
        for (final item in v)
          if (item is Map) ..._entry(item, depth) else if (item is List) ..._rows(item, depth + 1) else
            Padding(
              padding: indent,
              child: Text('• ${'$item'.trim()}', style: AppText.body(color: AppColors.white)),
            ),
      ];
    }
    if (v is Map) return _fields(v, depth, skip: null);
    return [Padding(padding: indent, child: Text('$v'.trim(), style: AppText.body(color: AppColors.white)))];
  }

  static List<Widget> _entry(Map m, int depth) {
    final title = _titleOf(m);
    return [
      if (title != null)
        Padding(
          padding: EdgeInsets.only(left: _pad(depth), top: 8, bottom: 2),
          child: Text(title, style: AppText.heading()),
        ),
      ..._fields(m, depth + (title == null ? 0 : 1), skip: title),
    ];
  }

  static List<Widget> _fields(Map m, int depth, {required String? skip}) => [
        for (final f in m.entries)
          if (!(f.value is String && (f.value as String).trim() == skip) && f.value != null && '${f.value}'.trim().isNotEmpty)
            if (f.value is List || f.value is Map) ...[
              Padding(
                padding: EdgeInsets.only(left: _pad(depth), top: 6),
                child: Text(planSectionTitle('${f.key}'), style: AppText.small()),
              ),
              ..._rows(f.value, depth + 1),
            ] else
              Padding(
                padding: EdgeInsets.only(left: _pad(depth), top: 2, bottom: 2),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${planSectionTitle('${f.key}')}: ', style: AppText.small()),
                  TextSpan(text: '${f.value}'.trim(), style: AppText.body(color: AppColors.white)),
                ])),
              ),
      ];
}

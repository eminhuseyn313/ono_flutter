import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// Brag document: what you've done, ready for a review or a CV.
class BragScreen extends StatefulWidget {
  const BragScreen({super.key});

  @override
  State<BragScreen> createState() => _BragScreenState();
}

class _BragScreenState extends State<BragScreen> {
  int _range = 1;

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final now = DateTime.now();
    final since = switch (_range) {
      0 => DateTime(now.year, now.month - 3, now.day),
      1 => DateTime(now.year, now.month - 6, now.day),
      _ => system.programStart,
    };
    final text = system.bragText(since: since);
    return OnoPage(
      showBack: true,
      eyebrow: 'Brag document',
      title: 'What you\'ve done',
      subtitle:
          'For a review, a promotion case or a CV — gathered from what you logged, so nothing gets forgotten.',
      children: [
        const SizedBox(height: 14),
        Segmented(
          labels: const ['3 months', '6 months', 'All'],
          index: _range,
          onChanged: (i) => setState(() => _range = i),
        ),
        const SizedBox(height: 12),
        OnoCard(
          padding: const EdgeInsets.all(14),
          child: SelectableText(text, style: AppText.small(color: AppColors.white)),
        ),
        const SizedBox(height: 12),
        PrimaryButton('Copy', icon: Icons.copy_rounded, onPressed: () {
          Clipboard.setData(ClipboardData(text: text));
          toast(context, 'Copied. Add the numbers only you know.');
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

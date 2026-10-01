import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/emin_system.dart';
import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';

/// Full-screen reading mode for the manifesto. "I've read it" ticks the
/// first non-negotiable for today.
class ManifestoScreen extends StatelessWidget {
  const ManifestoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<PersonalSystemProvider>();
    final today = DateTime.now();
    final read = system.isChecked(today, 'manifesto');
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.grey),
                  ),
                  const Spacer(),
                  Text('MANIFESTO', style: AppText.eyebrow()),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                children: [
                  for (var s = 0; s < manifestoStanzas.length; s++) ...[
                    for (final line in manifestoStanzas[s])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: (s == manifestoStanzas.length - 1)
                              ? AppText.title(color: AppColors.accent)
                                  .copyWith(fontSize: 24, height: 1.35)
                              : AppText.title()
                                  .copyWith(fontSize: 21, height: 1.45,
                                      fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: read
                    ? OutlinedButton.icon(
                        onPressed: () =>
                            system.toggleCheck(today, 'manifesto'),
                        icon: const Icon(Icons.check_rounded,
                            color: AppColors.accent, size: 18),
                        label: const Text('Read today'),
                      )
                    : FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          system.toggleCheck(today, 'manifesto');
                          if (context.canPop()) context.pop();
                        },
                        child: const Text('I\'ve read it — start the day'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

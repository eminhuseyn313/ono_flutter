import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/emin_system.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';

/// First screen: what ONO is, in one breath.
class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ONO',
                  style: AppText.serif(size: 26, color: AppColors.accent)
                      .copyWith(letterSpacing: 6)),
              const Spacer(),
              Text(EminIdentity.archetype.toUpperCase(),
                  style: AppText.eyebrow(color: AppColors.accent)),
              const SizedBox(height: 12),
              Text('Eighteen months.\nOne system.\nBuilt to be yours.',
                  style: AppText.display().copyWith(fontSize: 44)),
              const SizedBox(height: 16),
              Text(
                  'Your Daily 10, the RA-safe training plan, the protocols for pressure, the reading, the style — and the path from Senior PO to the room you want to be in.',
                  style: AppText.body(color: AppColors.grey)),
              const SizedBox(height: 28),
              for (final l in laneFocus)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      LaneDot(l.lane, size: 9),
                      const SizedBox(width: 12),
                      Text(l.name,
                          style: AppText.heading().copyWith(fontSize: 15)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.actions.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.small()),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              PrimaryButton('Begin',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push('/sign-up')),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/sign-in'),
                  child: Text('I already have an account',
                      style: AppText.small(color: AppColors.greyLight)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

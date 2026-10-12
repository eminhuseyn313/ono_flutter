import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/general_program.dart';
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
        // Scrolls when the text is large; otherwise fills the screen.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ONO',
                          style:
                              AppText.serif(size: 26, color: AppColors.accent)
                                  .copyWith(letterSpacing: 6)),
                      const Spacer(),
                      Text('PERSONAL & PROFESSIONAL GROWTH',
                          style: AppText.eyebrow(color: AppColors.accent)),
                      const SizedBox(height: 12),
                      Text('One plan.\nYour pace.\nBuilt to be yours.',
                          style: AppText.display().copyWith(fontSize: 44)),
                      const SizedBox(height: 16),
                      Text(
                          'A daily plan of your own, practice that builds the person you\'re becoming, and an honest look back every week — for a leader, an athlete, a parent, anyone.',
                          style: AppText.body(color: AppColors.grey)),
                      const SizedBox(height: 28),
                      for (final l in generalLanes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              LaneDot(l.$1, size: 9),
                              const SizedBox(width: 12),
                              Text(l.$2,
                                  style:
                                      AppText.heading().copyWith(fontSize: 15)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(l.$3,
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
            ),
          ),
        ),
      ),
    );
  }
}

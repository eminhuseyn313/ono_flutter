import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ono_ui.dart';

/// Free, confidential helplines in most countries, in one place.
const helplineDirectory = 'https://findahelpline.com';

/// For when it's too much to carry alone: real help, plainly. No
/// diagnosis, no questions — ONO is not a crisis service and says so.
Future<void> showSupportSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You don\'t have to carry this alone',
                  style: AppText.title()),
              const SizedBox(height: 12),
              _line(Icons.emergency_outlined,
                  'If you might hurt yourself or you are in danger, call your local emergency number now.'),
              _line(Icons.call_outlined,
                  'Talk to someone tonight. Free, confidential helplines for your country are listed at findahelpline.com.'),
              _line(Icons.forum_outlined,
                  'Message someone you trust. You don\'t need to explain — "Can you call me?" is enough.'),
              const SizedBox(height: 8),
              PrimaryButton('Find a helpline',
                  key: const Key('support-helpline'),
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => openLink(helplineDirectory)),
              const SizedBox(height: 8),
              Text(
                  'ONO is a tool for growth, not a crisis service. A person can help in a way an app can\'t.',
                  style: AppText.small()),
            ],
          ),
        ),
      ),
    );

Widget _line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: AppText.body(color: AppColors.white))),
        ],
      ),
    );

/// A quiet link to [showSupportSheet], for tools people use when low.
class SupportLink extends StatelessWidget {
  const SupportLink({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: const Key('support-link'),
          onPressed: () => showSupportSheet(context),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text('If it feels like too much to carry alone →'),
        ),
      );
}

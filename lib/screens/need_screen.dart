import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/personal_system_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_ui.dart';
import '../widgets/support_sheet.dart';
import 'home_screen.dart' show showHardDaySheet;
import '../time.dart';

/// "What do you need right now?" — the moment, then the one tool for it.
class NeedScreen extends StatelessWidget {
  const NeedScreen({super.key});

  static const _needs = [
    (Icons.air_rounded, 'I\'m stressed or anxious', 'Two minutes of slow breathing, then step back', '/tool/sigh'),
    (Icons.zoom_out_map_rounded, 'It all feels too close', 'Talk to yourself by name, like a friend would', '/stepback'),
    (Icons.alt_route_rounded, 'I have to decide something', 'Options against your values, 10/10/10, a premortem', '/decide'),
    (Icons.forum_outlined, 'A hard conversation is coming', 'What you want, the facts, your first sentence', '/conversations'),
    (Icons.psychology_outlined, 'A thought keeps getting to me', 'Weigh it like a fair judge, find a balanced one', '/thought'),
    (Icons.local_parking_rounded, 'I can\'t stop worrying', 'Park it now, deal with it at your worry time', '/worry'),
    (Icons.swap_horiz_rounded, 'My life just changed', 'A move, a new job, a baby, an ending', '/change'),
    (Icons.local_florist_outlined, 'I\'m missing someone who died', 'Write what you miss and what you carry', '/remember'),
    (Icons.favorite_border_rounded, 'I\'m being hard on myself', 'Two minutes: be on your own side', '/compassion'),
    (Icons.replay_rounded, 'I slipped', 'Kindness, the facts, the smallest next step', '/setback'),
    (Icons.healing_outlined, 'Today is a hard day', 'Minimum day, sick day or an emergency skip', '/home'),
    (Icons.psychology_alt_outlined, 'A problem keeps circling', 'Coach yourself: goal, reality, options, will', '/coach'),
    (Icons.center_focus_strong_rounded, 'I can\'t focus', 'One block, one thing, phone away', '/focus'),
    (Icons.favorite_outline_rounded, 'I want to feel closer to someone', 'A check-in for two, or reach out today', '/us'),
    (Icons.flag_outlined, 'Something big just happened', 'Look back while it\'s fresh: keep one thing, change one', '/aar'),
    (Icons.handshake_outlined, 'I have to negotiate', 'Your alternative, your bottom line, a first offer with a reason', '/negotiate'),
    (Icons.work_outline_rounded, 'I have an interview or review coming', 'Your best stories, in four parts, ready', '/stories'),
    (Icons.stairs_outlined, 'I keep avoiding something', 'One small rung, then see how hard it really was', '/courage'),
    (Icons.auto_awesome_outlined, 'I\'m doubting myself', 'Read what others saw in you at your best', '/best-self'),
    (Icons.explore_outlined, 'I don\'t know where I\'m going', 'Sketch three possible lives', '/odyssey'),
    (Icons.pan_tool_alt_outlined, 'I need help but don\'t want to ask', 'Most people say yes more often than you\'d guess', '/asks'),
    (Icons.wb_sunny_outlined, 'I need some hope', 'Write your best possible future', '/best-future'),
  ];

  /// Every route a need points to (the smoke test resolves each).
  static List<String> get routes => [for (final n in _needs) n.$4];

  @override
  Widget build(BuildContext context) {
    final system = context.read<PersonalSystemProvider>();
    return OnoPage(
      showBack: true,
      eyebrow: 'Right now',
      title: 'What do you need?',
      subtitle: 'Pick the moment you\'re in. One tool, a few minutes.',
      children: [
        const SizedBox(height: 14),
        // First, and always: real help when it's too much.
        OnoCard(
          padding: EdgeInsets.zero,
          child: LinkRow(
            key: const Key('need-support'),
            icon: Icons.favorite_rounded,
            color: AppColors.accent,
            title: 'I don\'t feel safe, or it\'s too much to carry alone',
            subtitle: 'People who can help, tonight',
            onTap: () => showSupportSheet(context),
          ),
        ),
        const SizedBox(height: 10),
        OnoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, n) in _needs.indexed) ...[
                if (i > 0) const Divider(indent: 66),
                LinkRow(
                  icon: n.$1,
                  color: AppColors.mind,
                  title: n.$2,
                  subtitle: n.$3,
                  onTap: () {
                    if (n.$4 == '/home') {
                      showHardDaySheet(context, timeNow());
                      return;
                    }
                    context.push(n.$4);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
            system.isBuiltInPerson
                ? 'Your protocols are under Program → Reference.'
                : 'Everything else lives under Me.',
            style: AppText.small()),
        const SizedBox(height: 16),
      ],
    );
  }
}

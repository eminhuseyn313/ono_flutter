import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// One tappable entry in the [FeatureDiscoveryGrid].
class FeatureEntry {
  final String emoji;
  final String label;
  final String route;

  const FeatureEntry(this.emoji, this.label, this.route);
}

/// A named group of features.
class FeatureGroup {
  final String title;
  final List<FeatureEntry> entries;

  const FeatureGroup(this.title, this.entries);
}

/// Every screen reachable from the home tab, grouped by area. Parameterised
/// routes point at the executive archetype / personal content so they open
/// with real data.
const featureGroups = <FeatureGroup>[
  FeatureGroup('Personal system', [
    FeatureEntry('📜', 'Manifesto', '/manifesto'),
    FeatureEntry('🗓', 'Plan', '/plan'),
    FeatureEntry('⚡', 'Protocols', '/protocols'),
    FeatureEntry('🗂', 'Evidence Archive', '/evidence'),
    FeatureEntry('📚', 'Library', '/library'),
    FeatureEntry('👔', 'Style System', '/style'),
    FeatureEntry('📈', 'Career & Signal', '/career'),
    FeatureEntry('📝', 'Sunday Report', '/weekly-coaching'),
    FeatureEntry('📖', 'Playbook', '/playbook'),
  ]),
  FeatureGroup('Daily', [
    FeatureEntry('☀️', 'Morning Ritual', '/morning-ritual'),
    FeatureEntry('▶️', 'Ritual Flow', '/ritual-flow/ritual_morning_default'),
    FeatureEntry('⚙️', 'Ritual Setup', '/ritual-setup'),
    FeatureEntry('✅', 'Daily Check-in', '/daily-checkin'),
    FeatureEntry('🗓', 'Planner', '/planner'),
    FeatureEntry('🔥', 'Habit Streaks', '/habit-streaks'),
    FeatureEntry('🧘', 'Monk Mode', '/monk-mode'),
    FeatureEntry('⏱', 'Time Mode', '/time-mode'),
  ]),
  FeatureGroup('Growth', [
    FeatureEntry('🧭', 'My Blueprint', '/blueprint/executive'),
    FeatureEntry('🏗️', 'My Role Model', '/role-model/product_architect'),
    FeatureEntry('🌟', 'Role Models', '/role-models'),
    FeatureEntry('🦋', 'Becoming Arc', '/becoming-arc'),
    FeatureEntry('🧱', 'Arc Layers', '/arc-layer'),
    FeatureEntry('🚪', 'Phase Transition', '/phase-transition'),
    FeatureEntry('🔨', 'Forge', '/forge'),
    FeatureEntry('📚', 'Content Library', '/content-library'),
    FeatureEntry('🖼', 'Vision Board', '/vision-board'),
    FeatureEntry('🔐', 'Vault', '/vault'),
  ]),
  FeatureGroup('Coach & Reflection', [
    FeatureEntry('🤖', 'AI Coach', '/ai-coach'),
    FeatureEntry('🏛', 'Council', '/council'),
    FeatureEntry('👻', 'Ghost Mode', '/ghost-mode'),
    FeatureEntry('📝', 'Weekly Review', '/weekly-review'),
    FeatureEntry('🔁', 'Review Flow', '/weekly-review-flow'),
    FeatureEntry('🎚', 'Adaptive Settings', '/adaptive-settings'),
  ]),
  FeatureGroup('Progress', [
    FeatureEntry('📊', 'Dashboard', '/dashboard'),
    FeatureEntry('📈', 'Analytics', '/analytics'),
    FeatureEntry('🛣', 'Lane Analytics', '/lane-analytics'),
    FeatureEntry('🟩', 'Heat Map', '/heat-map'),
    FeatureEntry('🏅', 'Achievements', '/achievements'),
    FeatureEntry('🏆', 'Achievement Hub', '/achievement-hub'),
    FeatureEntry('🎮', 'Gamification', '/gamification'),
    FeatureEntry('🏛️', 'Legacy Score', '/legacy-score'),
    FeatureEntry('🎓', 'Forge Analytics', '/forge-analytics'),
  ]),
  FeatureGroup('Community', [
    FeatureEntry('🤝', 'Brotherhood', '/brotherhood'),
    FeatureEntry('🫂', 'Accountability', '/accountability'),
    FeatureEntry('🪞', 'Mirror Match', '/mirror-match'),
    FeatureEntry('📣', 'Social Feed', '/social-feed'),
    FeatureEntry('⚔️', 'Community Challenges', '/community-challenges'),
    FeatureEntry('⚡', 'Wakz Challenges', '/wakz-challenges'),
    FeatureEntry('🥇', 'Power Rankings', '/power-rankings'),
    FeatureEntry('📈', 'Trending', '/trending'),
    FeatureEntry('📻', 'Radio', '/radio'),
  ]),
  FeatureGroup('Settings', [
    FeatureEntry('🔔', 'Notifications', '/notification-feed'),
    FeatureEntry('🔕', 'Notification Settings', '/notification-settings'),
    FeatureEntry('🛠', 'Settings', '/settings'),
    FeatureEntry('🧩', 'Onboarding Flow', '/onboarding-flow'),
  ]),
];

/// Grid of every feature as a tappable card, so each screen can be found
/// and tested from the home tab. Collapsed to the first group by default.
class FeatureDiscoveryGrid extends StatefulWidget {
  final bool initiallyExpanded;

  const FeatureDiscoveryGrid({super.key, this.initiallyExpanded = false});

  @override
  State<FeatureDiscoveryGrid> createState() => _FeatureDiscoveryGridState();
}

class _FeatureDiscoveryGridState extends State<FeatureDiscoveryGrid> {
  late bool _expanded = widget.initiallyExpanded;

  int get _totalCount =>
      featureGroups.fold(0, (sum, g) => sum + g.entries.length);

  @override
  Widget build(BuildContext context) {
    final groups = _expanded ? featureGroups : featureGroups.take(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧭', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'EXPLORE ALL FEATURES',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '$_totalCount',
                style: const TextStyle(
                  color: AppColors.purpleSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          for (final group in groups) ...[
            const SizedBox(height: 14),
            Text(
              group.title,
              style: const TextStyle(
                color: AppColors.greyLight,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children:
                  group.entries.map((e) => _FeatureCard(entry: e)).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Show all $_totalCount features',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureEntry entry;

  const _FeatureCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLight.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(entry.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(entry.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

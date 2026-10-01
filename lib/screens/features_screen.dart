import 'package:flutter/material.dart';

import '../widgets/feature_discovery_grid.dart';
import '../widgets/ono_ui.dart';

/// Every screen in the app, for discovery and testing.
class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnoPage(
      showBack: true,
      eyebrow: 'Explore',
      title: 'All features',
      subtitle: 'Every screen in ONO, grouped by area.',
      children: [
        SizedBox(height: 12),
        FeatureDiscoveryGrid(initiallyExpanded: true),
      ],
    );
  }
}

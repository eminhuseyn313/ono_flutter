import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/ono_button.dart';
import '../models/models.dart';
import '../gateways/blueprint_gateway.dart';
import '../providers/auth_provider.dart';
import '../providers/blueprint_provider.dart';

class BlueprintScreen extends StatefulWidget {
  final String archetypeId;

  const BlueprintScreen({super.key, required this.archetypeId});

  @override
  State<BlueprintScreen> createState() => _BlueprintScreenState();
}

class _BlueprintScreenState extends State<BlueprintScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        // Only load if the provider doesn't already have a blueprint
        // (e.g. just generated on the loading screen)
        final bp = context.read<BlueprintProvider>();
        if (bp.blueprint == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) bp.loadBlueprint(userId);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpProvider = context.watch<BlueprintProvider>();
    final blueprint = bpProvider.blueprint;

    final archetype = AppData.archetypes.firstWhere(
      (a) => a.id == widget.archetypeId,
      orElse: () => AppData.archetypes.first,
    );

    if (bpProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
      );
    }

    // Use generated blueprint lanes, or fall back to static data
    final lanes = blueprint?.lanes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'YOUR BLUEPRINT',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              archetype.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    blueprint?.title ?? archetype.title,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    blueprint?.summary ?? archetype.description,
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  const Text(
                    'Your Milestones',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMilestone('30', 'Days', 'Foundation'),
                      const SizedBox(width: 8),
                      _buildMilestone('60', 'Days', 'Momentum'),
                      const SizedBox(width: 8),
                      _buildMilestone('90', 'Days', 'Identity'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Lanes from generated blueprint
                  const Text(
                    'Your Lanes',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lanes != null)
                    ...lanes.map((lane) => _buildLaneCard(lane))
                  else
                    ...AppData.getDomains()
                        .map((d) => _buildLegacyDomainCard(d)),
                  const SizedBox(height: 32),
                  OnoButton(
                    label: 'Start my journey',
                    onPressed: () => context.go('/home'),
                    icon: Icons.rocket_launch_rounded,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestone(String days, String label, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(
              days,
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a lane from the AI-generated blueprint.
  Widget _buildLaneCard(BlueprintLane lane) {
    final emoji = _laneEmoji(lane.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            leading: Text(emoji, style: const TextStyle(fontSize: 24)),
            title: Text(
              lane.name,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              lane.description,
              style: const TextStyle(color: AppColors.purple, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.expand_more, color: AppColors.grey),
            children: lane.actions
                .map((action) => ListTile(
                      leading: const Icon(Icons.arrow_forward_ios,
                          color: AppColors.purple, size: 14),
                      title: Text(
                        action.title,
                        style: const TextStyle(
                          color: AppColors.greyLight,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: action.subtitle != null
                          ? Text(
                              action.subtitle!,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Fallback: renders old static BlueprintDomain if no generated blueprint.
  Widget _buildLegacyDomainCard(BlueprintDomain domain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            leading: Text(domain.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(
              domain.name,
              style: TextStyle(
                color: domain.active ? AppColors.white : AppColors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              domain.active ? 'Active lane' : 'Coming soon',
              style: TextStyle(
                color: domain.active ? AppColors.purple : AppColors.grey,
                fontSize: 12,
              ),
            ),
            trailing: domain.active
                ? const Icon(Icons.expand_more, color: AppColors.grey)
                : const Icon(Icons.lock_outline,
                    color: AppColors.grey, size: 18),
            children: domain.active
                ? domain.actions
                    .map((action) => ListTile(
                          leading: const Icon(Icons.arrow_forward_ios,
                              color: AppColors.purple, size: 14),
                          title: Text(
                            action,
                            style: const TextStyle(
                              color: AppColors.greyLight,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList()
                : [],
          ),
        ),
      ),
    );
  }

  String _laneEmoji(String lane) {
    switch (lane) {
      case 'mind':
        return '🧠';
      case 'body':
        return '💪';
      case 'social':
        return '🗣';
      case 'skill':
        return '📚';
      default:
        return '⚡';
    }
  }
}

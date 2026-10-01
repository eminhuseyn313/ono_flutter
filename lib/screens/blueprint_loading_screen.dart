import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/blueprint_provider.dart';

class BlueprintLoadingScreen extends StatefulWidget {
  final String archetypeId;
  final Map<int, int> answers;

  const BlueprintLoadingScreen({
    super.key,
    required this.archetypeId,
    required this.answers,
  });

  @override
  State<BlueprintLoadingScreen> createState() => _BlueprintLoadingScreenState();
}

class _BlueprintLoadingScreenState extends State<BlueprintLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generateBlueprint();
    });
  }

  Future<void> _generateBlueprint() async {
    try {
      final blueprintProvider = context.read<BlueprintProvider>();
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<UserProfileProvider>();

      final userId = authProvider.userId;
      if (userId != null) {
        // Generate + save via the provider
        await blueprintProvider.generateBlueprint(
          userId: userId,
          archetypeId: widget.archetypeId,
          assessmentAnswers: widget.answers,
        );

        // Seed daily_actions from the generated blueprint
        final blueprint = blueprintProvider.blueprint;
        if (blueprint != null) {
          await _seedDailyActions(userId, blueprint);
        }

        // Complete onboarding in profile provider
        profileProvider.selectArchetype(widget.archetypeId);
        profileProvider.setAssessmentAnswers(widget.answers);
        await profileProvider.completeOnboarding(userId);
      }

      if (mounted) {
        context.go('/blueprint/${widget.archetypeId}');
      }
    } catch (e) {
      // On error, still navigate — blueprint screen handles missing data
      if (mounted) {
        context.go('/blueprint/${widget.archetypeId}');
      }
    }
  }

  /// Call the seed-actions Edge Function to create daily_actions rows
  /// from the generated blueprint. Best-effort — failure here doesn't
  /// block onboarding.
  Future<void> _seedDailyActions(String userId, dynamic blueprint) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'seed-actions',
        body: {
          'userId': userId,
          'lanes': blueprint.lanes
              .map((lane) => {
                    'id': lane.id,
                    'actions': lane.actions
                        .map((a) => {
                              'id': a.id,
                              'title': a.title,
                              'subtitle': a.subtitle,
                              'laneId': a.laneId,
                              'orderIndex': a.orderIndex,
                            })
                        .toList(),
                  })
              .toList(),
        },
      );
    } catch (_) {
      // Seeding is best-effort — user can still view their blueprint
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _rotateController,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.purple,
                            AppColors.purple.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'ONO',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Building your blueprint...',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 15,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText('Analysing your profile...'),
                  FadeAnimatedText('Mapping your dimensions...'),
                  FadeAnimatedText('Calibrating your path...'),
                  FadeAnimatedText('Preparing your first steps...'),
                ],
                repeatForever: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/time_mode.dart';
import '../providers/time_mode_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/time_mode_gradient.dart';

/// Settings screen that shows all four time-of-day modes and lets the user
/// toggle between automatic (clock) and manual mode selection.
class TimeModeScreen extends StatelessWidget {
  const TimeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeModeProvider>(
      builder: (context, provider, _) {
        final config = provider.currentConfig;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // -- Gradient header -------------------------------------------
              SliverToBoxAdapter(
                child: _GradientHeader(config: config, provider: provider),
              ),

              // -- Auto-mode toggle ------------------------------------------
              SliverToBoxAdapter(child: _AutoModeToggle(provider: provider)),

              // -- Mode cards ------------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: TimeModeConfig.allModes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mode = TimeModeConfig.allModes[index];
                    final isActive = mode.mode == provider.currentMode;
                    return _ModeCard(
                      config: mode,
                      isActive: isActive,
                      onTap: provider.autoMode
                          ? null
                          : () => provider.setManualMode(mode.mode),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Gradient Header
// =============================================================================

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.config, required this.provider});

  final TimeModeConfig config;
  final TimeModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return TimeModeGradient(
      config: config,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),

              // Current mode badge
              Text(
                'Current Mode: ${config.displayName} ${config.emoji}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.hourRangeLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),

              // Quote card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote of the Day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${provider.currentQuote}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Auto-Mode Toggle
// =============================================================================

class _AutoModeToggle extends StatelessWidget {
  const _AutoModeToggle({required this.provider});

  final TimeModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_mode, color: AppColors.purple, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Switch modes based on time of day',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: provider.autoMode,
              activeColor: AppColors.purple,
              onChanged: (v) => provider.setAutoMode(v),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Mode Card
// =============================================================================

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.config,
    required this.isActive,
    this.onTap,
  });

  final TimeModeConfig config;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? config.accentColor : AppColors.divider,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: config.accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Emoji
            Text(config.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),

            // Name + range
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive ? config.accentColor : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.hourRangeLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),

            // Gradient preview strip
            Container(
              width: 64,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: config.gradient),
              ),
            ),

            if (isActive) ...[
              const SizedBox(width: 10),
              Icon(Icons.check_circle, color: config.accentColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

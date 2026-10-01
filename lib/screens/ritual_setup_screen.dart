import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ritual.dart';
import '../providers/auth_provider.dart';
import '../providers/ritual_provider.dart';
import '../theme/app_theme.dart';
import 'ritual_flow_screen.dart';

/// Configuration screen for morning and evening rituals.
///
/// Allows the user to toggle rituals on/off, set preferred times, reorder
/// steps, add/remove optional steps, and preview the flow.
class RitualSetupScreen extends StatefulWidget {
  const RitualSetupScreen({super.key});

  @override
  State<RitualSetupScreen> createState() => _RitualSetupScreenState();
}

class _RitualSetupScreenState extends State<RitualSetupScreen> {
  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<RitualProvider>().loadRituals(userId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Rituals',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<RitualProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              if (provider.morningRitual != null)
                _RitualCard(ritual: provider.morningRitual!),
              const SizedBox(height: 20),
              if (provider.eveningRitual != null)
                _RitualCard(ritual: provider.eveningRitual!),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ritual card — one per ritual type
// ---------------------------------------------------------------------------

class _RitualCard extends StatelessWidget {
  final Ritual ritual;

  const _RitualCard({required this.ritual});

  bool get _isMorning => ritual.type == RitualType.morning;

  Color get _accentColor => _isMorning ? AppColors.purple : AppColors.cyan;

  IconData get _icon =>
      _isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round;

  String get _label => _isMorning ? 'Morning Ritual' : 'Evening Ritual';

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${t.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<RitualProvider>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(_icon, color: _accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ritual.steps.length} steps · ${_formatDuration(ritual.totalDurationSeconds)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ritual.isActive,
                      activeColor: _accentColor,
                      onChanged: (v) =>
                          provider.toggleRitualActive(ritual.id, v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Preferred time
              _SettingRow(
                icon: Icons.access_time,
                label: 'Preferred time',
                value: _formatTime(ritual.preferredTime),
                onTap: () => _pickTime(context, provider),
              ),
              const Divider(color: AppColors.divider, height: 1, indent: 20),
              // Steps list with reorder
              _StepsSection(ritual: ritual),
              const Divider(color: AppColors.divider, height: 1, indent: 20),
              // Preview button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ritual.isActive
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RitualFlowScreen(ritualId: ritual.id),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Preview Flow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor.withValues(alpha: 0.15),
                      foregroundColor: _accentColor,
                      disabledBackgroundColor:
                          AppColors.grey.withValues(alpha: 0.1),
                      disabledForegroundColor:
                          AppColors.grey.withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    RitualProvider provider,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: ritual.preferredTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.updatePreferredTime(ritual.id, picked);
    }
  }
}

// ---------------------------------------------------------------------------
// Setting row
// ---------------------------------------------------------------------------

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.grey, size: 20),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyLarge),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.purpleSoft,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Steps section with reorder
// ---------------------------------------------------------------------------

class _StepsSection extends StatefulWidget {
  final Ritual ritual;

  const _StepsSection({required this.ritual});

  @override
  State<_StepsSection> createState() => _StepsSectionState();
}

class _StepsSectionState extends State<_StepsSection> {
  late List<RitualStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = List.of(widget.ritual.steps);
  }

  @override
  void didUpdateWidget(_StepsSection old) {
    super.didUpdateWidget(old);
    if (old.ritual.steps != widget.ritual.steps) {
      _steps = List.of(widget.ritual.steps);
    }
  }

  Color _laneColor(RitualLane lane) {
    switch (lane) {
      case RitualLane.mind:
        return AppColors.purple;
      case RitualLane.body:
        return AppColors.cyan;
      case RitualLane.social:
        return AppColors.green;
      case RitualLane.skill:
        return AppColors.warning;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
    context
        .read<RitualProvider>()
        .updateRitualSteps(widget.ritual.id, List.of(_steps));
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
    context
        .read<RitualProvider>()
        .updateRitualSteps(widget.ritual.id, List.of(_steps));
  }

  void _toggleOptional(int index) {
    setState(() {
      _steps[index] = _steps[index].copyWith(
        isOptional: !_steps[index].isOptional,
      );
    });
    context
        .read<RitualProvider>()
        .updateRitualSteps(widget.ritual.id, List.of(_steps));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                'Steps',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.grey,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'Drag to reorder',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _steps.length,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Material(
                  color: Colors.transparent,
                  elevation: 4,
                  shadowColor: AppColors.purple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              child: child,
            );
          },
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final step = _steps[index];
            final color = _laneColor(step.lane);

            return Dismissible(
              key: ValueKey(step.id),
              direction: step.isOptional
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Colors.red.withValues(alpha: 0.15),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              onDismissed: (_) => _removeStep(index),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardLight,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 12, right: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(step.iconData, color: color, size: 18),
                  ),
                  title: Text(
                    step.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${step.durationSeconds ~/ 60}m ${step.durationSeconds % 60}s · ${step.lane.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (step.isOptional)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.warning.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.grey,
                          size: 20,
                        ),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'toggle') _toggleOptional(index);
                          if (value == 'remove') _removeStep(index);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              step.isOptional
                                  ? 'Make required'
                                  : 'Make optional',
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              'Remove step',
                              style: TextStyle(
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Icon(
                            Icons.drag_handle,
                            color: AppColors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


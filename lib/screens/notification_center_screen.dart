import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/notification_templates.dart';
import '../theme/app_theme.dart';

/// Notifications settings screen for v1 — toggle switches per category,
/// a quiet-hours picker, a smart-timing toggle, and a live preview of
/// what each notification type actually looks like.
///
/// (The full scrollable notification feed is out of scope for Sprint 2;
/// this screen focuses on configuration.)
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  // TODO: replace with real auth user id
  static const userId = 'user_1';

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load(NotificationCenterScreen.userId);
      _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index, int total) {
    final start = (index / total) * 0.5;
    final end = start + 0.5;
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _updatePrefs(
    NotificationProvider provider,
    NotificationPreferences Function(NotificationPreferences) mutate,
  ) async {
    HapticFeedback.selectionClick();
    final updated = mutate(provider.preferences);
    await provider.updatePreferences(NotificationCenterScreen.userId, updated);
  }

  Future<void> _pickQuietHour({
    required BuildContext context,
    required int initialHour,
    required ValueChanged<int> onPicked,
  }) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.purple,
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) onPicked(time.hour);
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.3,
                  colors: [
                    AppColors.purple.withValues(alpha: 0.10),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(color: AppColors.cyan.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.notifications.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                final prefs = provider.preferences;
                final sections = <Widget>[
                  _buildHeader(provider),
                  _buildMasterToggle(provider, prefs),
                  _buildSectionLabel('Notification types'),
                  _buildCategoryToggle(
                    provider: provider,
                    index: 0,
                    type: NotificationType.streakRisk,
                    subtitle: 'Keep your streak alive with timely nudges',
                    value: prefs.streakAlerts,
                    onChanged: (v) => _updatePrefs(
                        provider, (p) => p.copyWith(streakAlerts: v)),
                  ),
                  _buildCategoryToggle(
                    provider: provider,
                    index: 1,
                    type: NotificationType.roleModel,
                    subtitle: 'Contextual pushes tied to your active journey',
                    value: prefs.roleModelAlerts,
                    onChanged: (v) => _updatePrefs(
                        provider, (p) => p.copyWith(roleModelAlerts: v)),
                  ),
                  _buildCategoryToggle(
                    provider: provider,
                    index: 2,
                    type: NotificationType.socialProof,
                    subtitle: 'See how you stack up against other ONO users',
                    value: prefs.socialProof,
                    onChanged: (v) =>
                        _updatePrefs(provider, (p) => p.copyWith(socialProof: v)),
                  ),
                  _buildCategoryToggle(
                    provider: provider,
                    index: 3,
                    type: NotificationType.milestone,
                    subtitle: 'Celebrate achievements and score jumps',
                    value: prefs.milestoneAlerts,
                    onChanged: (v) => _updatePrefs(
                        provider, (p) => p.copyWith(milestoneAlerts: v)),
                  ),
                  _buildSectionLabel('Delivery'),
                  _buildSmartTimingCard(provider, prefs),
                  _buildQuietHoursCard(provider, prefs),
                  _buildSectionLabel('Preview'),
                  _buildPreviewCards(),
                  const SizedBox(height: 40),
                ];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: sections,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(NotificationProvider provider) {
    return FadeTransition(
      opacity: _stagger(0, 6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 4),
            Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle(
      NotificationProvider provider, NotificationPreferences prefs) {
    return FadeTransition(
      opacity: _stagger(1, 6),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_stagger(1, 6)),
        child: _GlassCard(
          accent: AppColors.purple,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.notifications_active_rounded,
                    color: AppColors.purpleSoft, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prefs.enabled ? 'On — motivating you daily' : 'Muted',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: prefs.enabled,
                activeTrackColor: AppColors.purple,
                onChanged: (v) =>
                    _updatePrefs(provider, (p) => p.copyWith(enabled: v)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.streakRisk:
        return const Color(0xFFF97316);
      case NotificationType.roleModel:
        return AppColors.purple;
      case NotificationType.socialProof:
        return AppColors.cyan;
      case NotificationType.milestone:
        return AppColors.warning;
      case NotificationType.reminder:
        return AppColors.grey;
    }
  }

  Widget _buildCategoryToggle({
    required NotificationProvider provider,
    required int index,
    required NotificationType type,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final color = _typeColor(type);
    final enabled = provider.preferences.enabled;

    return FadeTransition(
      opacity: _stagger(index + 2, 6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: _GlassCard(
            accent: color,
            dense: true,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(type.emoji, style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  activeTrackColor: color,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartTimingCard(
      NotificationProvider provider, NotificationPreferences prefs) {
    final usualHour = provider.usualOpenHour;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassCard(
        accent: AppColors.cyan,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.access_time_filled_rounded,
                  color: AppColors.cyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart timing',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usualHour != null
                        ? 'Delivers near your usual time — ${_formatHour(usualHour)}'
                        : 'Learns your usual app-open time',
                    style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: prefs.smartTiming,
              activeTrackColor: AppColors.cyan,
              onChanged: (v) =>
                  _updatePrefs(provider, (p) => p.copyWith(smartTiming: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard(
      NotificationProvider provider, NotificationPreferences prefs) {
    return _GlassCard(
      accent: AppColors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.bedtime_rounded, color: AppColors.grey, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Quiet hours',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HourPickerTile(
                  label: 'From',
                  hour: prefs.quietHoursStart,
                  onTap: () => _pickQuietHour(
                    context: context,
                    initialHour: prefs.quietHoursStart,
                    onPicked: (h) => _updatePrefs(
                        provider, (p) => p.copyWith(quietHoursStart: h)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HourPickerTile(
                  label: 'To',
                  hour: prefs.quietHoursEnd,
                  onTap: () => _pickQuietHour(
                    context: context,
                    initialHour: prefs.quietHoursEnd,
                    onPicked: (h) =>
                        _updatePrefs(provider, (p) => p.copyWith(quietHoursEnd: h)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCards() {
    final samples = NotificationTemplates.previewSamples();
    return Column(
      children: samples.entries.map((entry) {
        final color = _typeColor(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              children: [
                Text(entry.key.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.title,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value.body,
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HourPickerTile extends StatelessWidget {
  final String label;
  final int hour;
  final VoidCallback onTap;

  const _HourPickerTile({
    required this.label,
    required this.hour,
    required this.onTap,
  });

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.grey, fontSize: 11)),
            const SizedBox(height: 3),
            Text(
              _formatHour(hour),
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final bool dense;

  const _GlassCard({
    required this.child,
    required this.accent,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(dense ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

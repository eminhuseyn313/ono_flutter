import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/account_header_card.dart';
import '../widgets/settings_tile.dart';

// TODO: Import the real ThemeProvider from the app.
// import '../providers/theme_provider.dart';

/// The app settings screen for ONO.
///
/// Separate from [ProfileScreen] — this handles app preferences,
/// notifications, privacy, and account management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // Load settings on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings().then((_) {
        if (mounted) _animController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.userStats == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          // Account overview
                          if (provider.userStats != null)
                            AccountHeaderCard(
                              displayName: 'Alex Johnson',
                              email: 'alex@onothrive.com',
                              stats: provider.userStats!,
                            ),
                          const SizedBox(height: 24),

                          // Appearance
                          _buildSectionCard(
                            context: context,
                            title: 'Appearance',
                            icon: Icons.palette_rounded,
                            iconColor: AppColors.purple,
                            children: _buildAppearanceSection(
                                context, provider),
                          ),
                          const SizedBox(height: 16),

                          // Notifications
                          _buildSectionCard(
                            context: context,
                            title: 'Notifications',
                            icon: Icons.notifications_rounded,
                            iconColor: AppColors.cyan,
                            children: _buildNotificationsSection(
                                context, provider),
                          ),
                          const SizedBox(height: 16),

                          // Sound & Haptics
                          _buildSectionCard(
                            context: context,
                            title: 'Sound & Haptics',
                            icon: Icons.volume_up_rounded,
                            iconColor: AppColors.green,
                            children: _buildSoundSection(context, provider),
                          ),
                          const SizedBox(height: 16),

                          // Privacy
                          _buildSectionCard(
                            context: context,
                            title: 'Privacy',
                            icon: Icons.shield_rounded,
                            iconColor: AppColors.warning,
                            children: _buildPrivacySection(context, provider),
                          ),
                          const SizedBox(height: 16),

                          // About
                          _buildSectionCard(
                            context: context,
                            title: 'About',
                            icon: Icons.info_rounded,
                            iconColor: AppColors.grey,
                            children: _buildAboutSection(context, provider),
                          ),
                          const SizedBox(height: 24),

                          // App version footer
                          _buildFooter(provider),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Settings',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Glassmorphic section card
  // ---------------------------------------------------------------------------

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card.withValues(alpha: 0.65),
                AppColors.cardLight.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ...children,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Appearance section
  // ---------------------------------------------------------------------------

  List<Widget> _buildAppearanceSection(
      BuildContext context, SettingsProvider provider) {
    // Read theme state from ThemeProvider if available in the widget tree.
    // Falls back to checking the settings model directly.
    final isDark = provider.settings.themeMode == 'dark';

    return [
      SettingsTile(
        icon: Icons.dark_mode_rounded,
        title: 'Dark Mode',
        subtitle: isDark ? 'Currently using dark theme' : 'Currently using light theme',
        type: SettingsTileType.toggle,
        value: isDark,
        onToggle: (value) {
          // Use ThemeProvider.toggle() when available in the widget tree.
          // context.read<ThemeProvider>().toggle();
          provider.updateSetting(
            'themeMode',
            value ? 'dark' : 'light',
          );
        },
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.text_fields_rounded,
        title: 'Font Size',
        subtitle: 'Coming soon',
        trailing: Text(
          'Default',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.language_rounded,
        title: 'Language',
        trailing: Text(
          _languageLabel(provider.settings.language),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
        onTap: () => _showLanguagePicker(context, provider),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Notifications section
  // ---------------------------------------------------------------------------

  List<Widget> _buildNotificationsSection(
      BuildContext context, SettingsProvider provider) {
    final settings = provider.settings;

    return [
      SettingsTile(
        icon: Icons.notifications_active_rounded,
        title: 'Push Notifications',
        subtitle: 'Receive reminders and updates',
        type: SettingsTileType.toggle,
        value: settings.notificationsEnabled,
        onToggle: (_) => provider.toggleNotifications(),
      ),
      if (settings.notificationsEnabled) ...[
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.access_time_rounded,
          title: 'Daily Reminder',
          subtitle: 'Time for your daily check-in',
          trailing: Text(
            _formatTime(settings.dailyReminderTime),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
          onTap: () => _showTimePicker(context, provider),
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.summarize_rounded,
          title: 'Weekly Digest',
          subtitle: 'Get a summary every Monday',
          type: SettingsTileType.toggle,
          value: settings.weeklyDigestEnabled,
          onToggle: (value) =>
              provider.updateSetting('weeklyDigestEnabled', value),
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Sound & Haptics section
  // ---------------------------------------------------------------------------

  List<Widget> _buildSoundSection(
      BuildContext context, SettingsProvider provider) {
    final settings = provider.settings;

    return [
      SettingsTile(
        icon: Icons.music_note_rounded,
        title: 'Sound Effects',
        subtitle: 'Play sounds on actions and achievements',
        type: SettingsTileType.toggle,
        value: settings.soundEnabled,
        onToggle: (value) => provider.updateSetting('soundEnabled', value),
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.vibration_rounded,
        title: 'Haptic Feedback',
        subtitle: 'Vibrations on taps and interactions',
        type: SettingsTileType.toggle,
        value: settings.hapticEnabled,
        onToggle: (value) {
          provider.updateSetting('hapticEnabled', value);
          if (value) {
            HapticFeedback.lightImpact();
          }
        },
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Privacy section
  // ---------------------------------------------------------------------------

  List<Widget> _buildPrivacySection(
      BuildContext context, SettingsProvider provider) {
    final settings = provider.settings;

    return [
      SettingsTile(
        icon: Icons.visibility_off_rounded,
        title: 'Privacy Mode',
        subtitle: 'Hide sensitive data on screen',
        type: SettingsTileType.toggle,
        value: settings.privacyMode,
        onToggle: (value) => provider.updateSetting('privacyMode', value),
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.analytics_rounded,
        title: 'Analytics',
        subtitle: 'Help improve ONO with anonymous usage data',
        type: SettingsTileType.toggle,
        value: settings.analyticsOptIn,
        onToggle: (value) => provider.updateSetting('analyticsOptIn', value),
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.download_rounded,
        title: 'Export My Data',
        subtitle: settings.dataExportRequested
            ? 'Export requested — check your email'
            : 'Download a copy of all your data',
        iconColor: AppColors.cyan,
        onTap: provider.isExporting
            ? null
            : () => _handleExportData(context, provider),
        trailing: provider.isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cyan,
                ),
              )
            : null,
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.delete_forever_rounded,
        title: 'Delete Account',
        subtitle: 'Permanently remove your account and data',
        type: SettingsTileType.danger,
        onTap: () => _showDeleteConfirmation(context, provider),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // About section
  // ---------------------------------------------------------------------------

  List<Widget> _buildAboutSection(
      BuildContext context, SettingsProvider provider) {
    final info = provider.appInfo;

    return [
      SettingsTile(
        icon: Icons.info_outline_rounded,
        title: 'App Version',
        subtitle: 'v${info.version} (${info.buildNumber})',
        trailing: const SizedBox.shrink(),
      ),
      if (info.lastSyncAt != null) ...[
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.sync_rounded,
          title: 'Last Synced',
          subtitle: _formatLastSync(info.lastSyncAt!),
          trailing: const SizedBox.shrink(),
        ),
      ],
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.description_rounded,
        title: 'Terms of Service',
        onTap: () {
          // TODO: Navigate to terms of service webview or external link.
        },
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.privacy_tip_rounded,
        title: 'Privacy Policy',
        onTap: () {
          // TODO: Navigate to privacy policy webview or external link.
        },
      ),
      const SettingsTileDivider(),
      SettingsTile(
        icon: Icons.support_agent_rounded,
        title: 'Support',
        subtitle: 'Get help or report an issue',
        onTap: () {
          // TODO: Open support email or in-app help center.
        },
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter(SettingsProvider provider) {
    return Column(
      children: [
        Text(
          'ONO',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.purple.withValues(alpha: 0.4),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your personal transformation journey',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v${provider.appInfo.version}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs & pickers
  // ---------------------------------------------------------------------------

  Future<void> _showTimePicker(
      BuildContext context, SettingsProvider provider) async {
    final parts = provider.settings.dailyReminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              onPrimary: AppColors.white,
              surface: AppColors.card,
              onSurface: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final time =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      provider.updateReminderTime(time);
    }
  }

  void _showLanguagePicker(
      BuildContext context, SettingsProvider provider) {
    const languages = [
      ('en', 'English'),
      ('es', 'Spanish'),
      ('fr', 'French'),
      ('de', 'German'),
      ('pt', 'Portuguese'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Language',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...languages.map((lang) {
                final isSelected =
                    provider.settings.language == lang.$1;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.purple : AppColors.grey,
                    size: 22,
                  ),
                  title: Text(
                    lang.$2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? AppColors.white : AppColors.grey,
                    ),
                  ),
                  onTap: () {
                    provider.updateSetting('language', lang.$1);
                    Navigator.pop(ctx);
                  },
                );
              }),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExportData(
      BuildContext context, SettingsProvider provider) async {
    final success = await provider.exportData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Data export initiated — you will receive an email with your data.'
              : 'Failed to export data. Please try again.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: success ? AppColors.green : const Color(0xFFE0605A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE0605A),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'This action is permanent and cannot be undone. '
            'All your data, progress, and achievements will be permanently deleted.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await provider.confirmDeleteAccount();
                if (!mounted) return;
                if (success) {
                  // TODO: Navigate to login/onboarding screen.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Account deleted successfully.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: const Color(0xFFE0605A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE0605A),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _languageLabel(String code) {
    const map = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'pt': 'Portuguese',
    };
    return map[code] ?? code.toUpperCase();
  }

  String _formatLastSync(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

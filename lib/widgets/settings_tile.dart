import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// The visual variant of a [SettingsTile].
enum SettingsTileType {
  /// Standard row with optional trailing widget and chevron.
  navigation,

  /// Row with a trailing [Switch].
  toggle,

  /// Destructive action — renders title and icon in danger red.
  danger,
}

/// A reusable settings row widget.
///
/// Supports three visual types via [SettingsTileType]:
/// - **navigation**: icon + title + optional subtitle + trailing widget/chevron.
/// - **toggle**: icon + title + optional subtitle + [Switch].
/// - **danger**: same as navigation but tinted red for destructive actions.
///
/// Example:
/// ```dart
/// SettingsTile(
///   icon: Icons.dark_mode_rounded,
///   title: 'Dark Mode',
///   subtitle: 'Use a darker colour scheme',
///   type: SettingsTileType.toggle,
///   value: isDark,
///   onToggle: (v) => themeProvider.toggle(),
/// )
/// ```
class SettingsTile extends StatelessWidget {
  /// Leading icon for the tile.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Optional secondary label below the title.
  final String? subtitle;

  /// Visual type of the tile.
  final SettingsTileType type;

  /// Current value for [SettingsTileType.toggle] tiles.
  final bool? value;

  /// Called when the toggle switch changes (toggle type only).
  final ValueChanged<bool>? onToggle;

  /// Called when the entire row is tapped (navigation / danger types).
  final VoidCallback? onTap;

  /// Optional trailing widget (shown for navigation type when no default
  /// chevron is desired, or to show a value label).
  final Widget? trailing;

  /// Optional colour override for the leading icon.
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.type = SettingsTileType.navigation,
    this.value,
    this.onToggle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = type == SettingsTileType.danger;
    final dangerColor = const Color(0xFFE0605A);

    final Color resolvedIconColor =
        isDanger ? dangerColor : (iconColor ?? AppColors.purple);

    final Color titleColor =
        isDanger ? dangerColor : AppColors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.purple.withValues(alpha: 0.08),
        highlightColor: AppColors.purple.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: resolvedIconColor,
                ),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    switch (type) {
      case SettingsTileType.toggle:
        return Switch.adaptive(
          value: value ?? false,
          onChanged: onToggle,
          activeColor: AppColors.purple,
          activeTrackColor: AppColors.purple.withValues(alpha: 0.35),
          inactiveThumbColor: AppColors.grey,
          inactiveTrackColor: AppColors.grey.withValues(alpha: 0.2),
        );

      case SettingsTileType.navigation:
        if (trailing != null) return trailing!;
        return Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.grey.withValues(alpha: 0.6),
        );

      case SettingsTileType.danger:
        if (trailing != null) return trailing!;
        return Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: const Color(0xFFE0605A).withValues(alpha: 0.6),
        );
    }
  }

  void _handleTap() {
    if (type == SettingsTileType.toggle) {
      onToggle?.call(!(value ?? false));
    } else {
      onTap?.call();
    }
  }
}

/// A thin divider used between [SettingsTile]s inside a card.
class SettingsTileDivider extends StatelessWidget {
  const SettingsTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.divider.withValues(alpha: 0.6),
      ),
    );
  }
}

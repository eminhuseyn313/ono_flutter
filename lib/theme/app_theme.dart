import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ONO's palette: calm light (warm white, ink text, one deep green accent)
/// and its dark counterpart, following the iPhone's appearance (Emin's
/// choice, 14 Nov 2026). [dark] is set by the app from the platform
/// brightness; every color below reads it, so screens keep using
/// `AppColors.x` and get the right one.
///
/// `white` is "the main text color" and `ink` "text on the accent" — names
/// kept from the first palette so every screen follows.
class AppColors {
  /// Set by the app (OnoApp) from the iPhone's appearance.
  static bool dark = false;

  static Color _p(int light, int darkValue) => Color(dark ? darkValue : light);

  static Color get background => _p(0xFFF7F5F1, 0xFF111413);
  static Color get card => _p(0xFFFFFFFF, 0xFF191D1B);
  static Color get cardLight => _p(0xFFEFECE6, 0xFF222724);
  static Color get purple => accent;
  static Color get purpleSoft => accentSoft;
  static Color get purpleDark => accentDeep;
  static Color get cyan => steel;
  static Color get green => _p(0xFF3F7D5C, 0xFF86B49A);
  static Color get white => _p(0xFF1C1B19, 0xFFEDF0EE);
  static Color get grey => _p(0xFF6B665E, 0xFF9EA6A1);
  static Color get greyLight => _p(0xFF3D3A35, 0xFFCDD3CF);
  static Color get success => green;
  static Color get warning => _p(0xFF9A6410, 0xFFE2B354);
  static Color get divider => _p(0xFFE6E1D8, 0xFF2A302D);

  // ── Semantic aliases ──
  /// Deep green — reserved for "now", "you" and the one primary action.
  static Color get accent => _p(0xFF2F6B4F, 0xFF7CC4A0);
  /// A lighter accent for links and highlights on the background.
  static Color get accentSoft => _p(0xFF3C7F5E, 0xFFB9E2CC);
  /// A tint of the accent behind chips, glows and selected rows.
  static Color get accentDeep => _p(0xFFE3EFE7, 0xFF1F3A2D);
  static Color get accentPressed => _p(0xFF24543E, 0xFF63A985);
  static Color get steel => _p(0xFF4C6E91, 0xFF8AA8D6);

  /// Hero bands (Day Dial, Spine).
  static Color get navy => _p(0xFFEAF1EC, 0xFF18201D);
  static Color get navyLight => _p(0xFFDCE8E0, 0xFF213029);
  /// Text and icons on the accent.
  static Color get ink => _p(0xFFFFFFFF, 0xFF0E1210);
  /// Quiet text that still reads (≥ 4.5:1 on cards).
  static Color get faint => _p(0xFF716C63, 0xFF8E9792);
  static Color get danger => _p(0xFFB83A34, 0xFFE0605A);

  // ── Lane colors (one map, used everywhere) ──
  static Color get mind => _p(0xFF5B78B0, 0xFF8FA3C8);
  static Color get body => _p(0xFF4F8F6B, 0xFF86B49A);
  static Color get skill => _p(0xFF3E8A8F, 0xFF6FAFB3);
  static Color get social => _p(0xFF9A6797, 0xFFC49AC0);

  static Color lane(String lane) {
    switch (lane.toLowerCase()) {
      case 'mind':
        return mind;
      case 'body':
        return body;
      case 'skill':
        return skill;
      case 'social':
        return social;
      default:
        return accent;
    }
  }
}

/// Shared spacing / radius tokens.
class AppSpace {
  static const double gutter = 20;
  static const double radius = 16;
  static const double radiusSm = 12;
}

/// Type scale: Inter throughout — bold, tight titles and plain, readable
/// text (Emin's choice, 14 Nov 2026).
class AppText {
  static TextStyle display({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.white,
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      );

  static TextStyle title({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.white,
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  /// For quotes and hero numbers (the name is kept from the first type
  /// scale): Inter at any size, semibold.
  static TextStyle serif(
          {Color? color, double size = 22, FontStyle style = FontStyle.normal}) =>
      GoogleFonts.inter(
        color: color ?? AppColors.white,
        fontSize: size * 0.9,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontStyle: style,
      );

  static TextStyle heading({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.white,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      );

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.greyLight,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle small({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.grey,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
      );

  /// Uppercase eyebrow label above sections. Use sparingly.
  static TextStyle eyebrow({Color? color}) => GoogleFonts.inter(
        color: color ?? AppColors.grey,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      );

  static TextStyle number({Color? color, double size = 28}) => GoogleFonts.inter(
        color: color ?? AppColors.white,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  static ThemeData get light => _for(false);
  static ThemeData get dark => _for(true);

  static ThemeData _for(bool dark) {
    final was = AppColors.dark;
    AppColors.dark = dark;
    final t = _build(
      brightness: dark ? Brightness.dark : Brightness.light,
      background: AppColors.background,
      surface: AppColors.card,
      surfaceHigh: AppColors.cardLight,
      accent: AppColors.accent,
      text: AppColors.white,
      textMuted: AppColors.grey,
      textSecondary: AppColors.greyLight,
      divider: AppColors.divider,
    );
    AppColors.dark = was;
    return t;
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color accent,
    required Color text,
    required Color textMuted,
    required Color textSecondary,
    required Color divider,
  }) {
    final onAccent = AppColors.ink;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: AppColors.steel,
      onSecondary: AppColors.ink,
      tertiary: AppColors.green,
      onTertiary: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceHigh,
      outline: divider,
      outlineVariant: divider,
    );

    final base = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            color: text,
            fontSize: 44,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5),
        displayMedium: TextStyle(
            color: text,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0),
        displaySmall: TextStyle(
            color: text,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8),
        headlineLarge: TextStyle(
            color: text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5),
        headlineMedium: TextStyle(
            color: text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3),
        titleLarge: TextStyle(
            color: text, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: text, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(
            color: textSecondary,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(
            color: textMuted,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400),
        labelLarge: TextStyle(
            color: text, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: scheme,
      textTheme: base,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
        titleTextStyle: GoogleFonts.inter(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          side: BorderSide(color: divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: shape,
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: shape,
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: divider),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.18),
        side: BorderSide(color: divider),
        labelStyle: GoogleFonts.inter(
            color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? onAccent : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : surfaceHigh),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(onAccent),
        side: BorderSide(color: textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: surfaceHigh,
        circularTrackColor: surfaceHigh,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceHigh,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: GoogleFonts.inter(
            color: text, fontSize: 14, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: divider,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: textMuted,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textSecondary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

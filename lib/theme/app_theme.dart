import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ONO "Architect" palette.
///
/// Built from Emin's own style system: charcoal and ink surfaces, ivory
/// text, one warm cognac accent (the brown loafers), steel navy as the
/// secondary (the navy blazer). Quiet, high-contrast, no neon.
///
/// Field names are kept from the original palette so every screen picks up
/// the new look; `purple*` is now the cognac accent family and `cyan` is the
/// steel-blue secondary. Prefer the semantic aliases ([accent], [ink], …) in
/// new code.
class AppColors {
  static const Color background = Color(0xFF0B0C0E);
  static const Color card = Color(0xFF14161A);
  static const Color cardLight = Color(0xFF1B1E23);
  static const Color purple = Color(0xFFC8894A);
  static const Color purpleSoft = Color(0xFFE8C9A3);
  static const Color purpleDark = Color(0xFF4A2F18);
  static const Color cyan = Color(0xFF7C9CC4);
  static const Color green = Color(0xFF86B49A);
  static const Color white = Color(0xFFF3EFE7);
  static const Color grey = Color(0xFFA39E95);
  static const Color greyLight = Color(0xFFD3CEC5);
  static const Color success = Color(0xFF86B49A);
  static const Color warning = Color(0xFFE2B354);
  static const Color divider = Color(0xFF24272D);

  // ── Semantic aliases ──
  /// Cognac — reserved for "now", "you" and the one primary action.
  static const Color accent = purple;
  static const Color accentSoft = purpleSoft;
  static const Color accentDeep = purpleDark;
  static const Color accentPressed = Color(0xFFA86D35);
  static const Color steel = cyan;

  /// Navy from the wardrobe — hero bands (Day Dial, Spine).
  static const Color navy = Color(0xFF18222F);
  static const Color navyLight = Color(0xFF223042);
  static const Color ink = Color(0xFF0B0C0E);
  static const Color faint = Color(0xFF6E6A63);
  static const Color danger = Color(0xFFE0605A);

  // ── Lane colors (one map, used everywhere) ──
  static const Color mind = Color(0xFF8FA3C8);
  static const Color body = Color(0xFF86B49A);
  static const Color skill = Color(0xFF6FAFB3);
  static const Color social = Color(0xFFC49AC0);

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

/// Light-mode equivalents — screens that use AppColors directly
/// should check `Theme.of(context).brightness` where it matters,
/// but the bulk of the palette adapts through the ThemeData below.
class AppColorsLight {
  static const Color background = Color(0xFFF6F3EE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFEFEAE2);
  static const Color purple = Color(0xFFA86D35);
  static const Color purpleSoft = AppColors.purpleSoft;
  static const Color purpleDark = AppColors.purpleDark;
  static const Color white = Color(0xFF1B1D22); // text becomes dark
  static const Color grey = Color(0xFF6E6A63);
  static const Color greyLight = Color(0xFF3F3C37);
  static const Color success = Color(0xFF4F8A6A);
  static const Color warning = Color(0xFFB8862A);
  static const Color divider = Color(0xFFE2DCD2);
}

/// Shared spacing / radius tokens.
class AppSpace {
  static const double gutter = 20;
  static const double radius = 16;
  static const double radiusSm = 12;
}

/// Type scale. Instrument Serif carries the voice (titles, manifesto, hero
/// numbers); Plus Jakarta Sans carries the interface.
class AppText {
  static TextStyle display({Color color = AppColors.white}) =>
      GoogleFonts.instrumentSerif(
        color: color,
        fontSize: 40,
        height: 1.05,
        letterSpacing: -0.4,
      );

  static TextStyle title({Color color = AppColors.white}) =>
      GoogleFonts.instrumentSerif(
        color: color,
        fontSize: 28,
        height: 1.15,
      );

  /// Serif at any size, for quotes and hero numbers.
  static TextStyle serif(
          {Color color = AppColors.white,
          double size = 22,
          FontStyle style = FontStyle.normal}) =>
      GoogleFonts.instrumentSerif(
        color: color,
        fontSize: size,
        height: 1.25,
        fontStyle: style,
      );

  static TextStyle heading({Color color = AppColors.white}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: 16.5,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle body({Color color = AppColors.greyLight}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: 15.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
      );

  static TextStyle small({Color color = AppColors.grey}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
      );

  /// Uppercase eyebrow label above sections. Use sparingly.
  static TextStyle eyebrow({Color color = AppColors.grey}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.3,
      );

  static TextStyle number({Color color = AppColors.white, double size = 28}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColorsLight.background,
        surface: AppColorsLight.card,
        surfaceHigh: AppColorsLight.cardLight,
        accent: AppColorsLight.purple,
        text: AppColorsLight.white,
        textMuted: AppColorsLight.grey,
        textSecondary: AppColorsLight.greyLight,
        divider: AppColorsLight.divider,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.background,
        surface: AppColors.card,
        surfaceHigh: AppColors.cardLight,
        accent: AppColors.purple,
        text: AppColors.white,
        textMuted: AppColors.grey,
        textSecondary: AppColors.greyLight,
        divider: AppColors.divider,
      );

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
    final isDark = brightness == Brightness.dark;
    final onAccent = isDark ? AppColors.ink : Colors.white;
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

    final base = GoogleFonts.plusJakartaSansTextTheme(
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
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
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: shape,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: divider),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.plusJakartaSans(
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
        labelStyle: GoogleFonts.plusJakartaSans(
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
        contentTextStyle: GoogleFonts.plusJakartaSans(
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
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
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

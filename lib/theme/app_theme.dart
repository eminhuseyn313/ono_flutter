import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0A0C14);
  static const Color card = Color(0xFF121826);
  static const Color cardLight = Color(0xFF1B2336);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFC4B5FD);
  static const Color purpleDark = Color(0xFF4C1D95);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color green = Color(0xFF34D399);
  static const Color white = Color(0xFFF8FAFC);
  static const Color grey = Color(0xFF9AA6B2);
  static const Color greyLight = Color(0xFFD5DEE8);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFF202B3F);
}

/// Light-mode equivalents — screens that use AppColors directly
/// should check `Theme.of(context).brightness` where it matters,
/// but the bulk of the palette adapts through the ThemeData below.
class AppColorsLight {
  static const Color background = Color(0xFFF5F5FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF0F0F8);
  static const Color purple = AppColors.purple;
  static const Color purpleSoft = AppColors.purpleSoft;
  static const Color purpleDark = AppColors.purpleDark;
  static const Color white = Color(0xFF1A1A2E); // text becomes dark
  static const Color grey = Color(0xFF666680);
  static const Color greyLight = Color(0xFF444460);
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color divider = Color(0xFFDDDDE8);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColorsLight.background,
        primaryColor: AppColorsLight.purple,
        colorScheme: const ColorScheme.light(
          primary: AppColorsLight.purple,
          secondary: AppColorsLight.purpleSoft,
          surface: AppColorsLight.card,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
                color: AppColorsLight.white,
                fontSize: 48,
                fontWeight: FontWeight.w800),
            displayMedium: TextStyle(
                color: AppColorsLight.white,
                fontSize: 36,
                fontWeight: FontWeight.w800),
            displaySmall: TextStyle(
                color: AppColorsLight.white,
                fontSize: 28,
                fontWeight: FontWeight.w700),
            headlineLarge: TextStyle(
                color: AppColorsLight.white,
                fontSize: 24,
                fontWeight: FontWeight.w700),
            headlineMedium: TextStyle(
                color: AppColorsLight.white,
                fontSize: 20,
                fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(
                color: AppColorsLight.greyLight,
                fontSize: 16,
                fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(
                color: AppColorsLight.grey,
                fontSize: 14,
                fontWeight: FontWeight.w400),
            labelLarge: TextStyle(
                color: AppColorsLight.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColorsLight.card,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsLight.purple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        dividerColor: AppColorsLight.divider,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColorsLight.card,
          selectedItemColor: AppColorsLight.purple,
          unselectedItemColor: AppColorsLight.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.purple,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple,
          secondary: AppColors.purpleSoft,
          surface: AppColors.card,
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          const TextTheme(
            displayLarge: TextStyle(
                color: AppColors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800),
            displayMedium: TextStyle(
                color: AppColors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800),
            displaySmall: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700),
            headlineLarge: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700),
            headlineMedium: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(
                color: AppColors.greyLight,
                fontSize: 16,
                fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w400),
            labelLarge: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        dividerColor: AppColors.divider,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.purple,
          unselectedItemColor: AppColors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/providers/theme_provider.dart';

void main() {
  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('defaults to dark mode', () {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, true);
    });
  });

  // -- Toggle --------------------------------------------------------------

  group('toggle', () {
    test('toggles from dark to light', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      await provider.toggle();

      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, false);
    });

    test('toggles from light back to dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final provider = ThemeProvider();

      // Wait for _loadFromPrefs to complete
      await Future.delayed(Duration.zero);
      expect(provider.isDark, false);

      await provider.toggle();

      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, true);
    });

    test('persists preference', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      await provider.toggle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('notifies listeners on toggle', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggle();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });

  // -- setMode -------------------------------------------------------------

  group('setMode', () {
    test('sets to light explicitly', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      await provider.setMode(ThemeMode.light);

      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, false);
    });

    test('persists explicit mode', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      await provider.setMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });

  // -- Load from prefs -----------------------------------------------------

  group('loads from SharedPreferences', () {
    test('restores light mode from prefs', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final provider = ThemeProvider();

      // _loadFromPrefs is async in constructor — wait a tick
      await Future.delayed(Duration.zero);

      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, false);
    });

    test('restores dark mode from prefs', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final provider = ThemeProvider();

      await Future.delayed(Duration.zero);

      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, true);
    });
  });
}

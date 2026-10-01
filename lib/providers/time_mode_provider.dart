import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/time_mode.dart';

/// Provides the current [TimeModeConfig] based on the local clock.
///
/// Automatically re-evaluates every minute so the UI transitions between
/// modes without a restart. A daily-seeded random picks the quote of the
/// day so it stays stable across rebuilds but changes each calendar day.
class TimeModeProvider extends ChangeNotifier {
  TimeModeProvider() {
    _update();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _update());
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  Timer? _timer;

  bool _initialized = false;
  late TimeOfDayMode _currentMode;
  late TimeModeConfig _currentConfig;
  late String _currentQuote;
  late String _greetingText;
  late bool _isEarlyBird;

  /// When true the provider follows [DateTime.now]; when false the user has
  /// picked a mode manually.
  bool _autoMode = true;

  /// Only used when [_autoMode] is false.
  TimeOfDayMode? _manualOverride;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  TimeOfDayMode get currentMode => _currentMode;
  TimeModeConfig get currentConfig => _currentConfig;
  String get currentQuote => _currentQuote;
  String get greetingText => _greetingText;

  /// True when the user opened (or is using) the app during dawn hours.
  bool get isEarlyBird => _isEarlyBird;
  bool get autoMode => _autoMode;

  // ---------------------------------------------------------------------------
  // Public setters
  // ---------------------------------------------------------------------------

  /// Toggle between automatic (clock-driven) and manual mode selection.
  void setAutoMode(bool value) {
    if (_autoMode == value) return;
    _autoMode = value;
    if (_autoMode) {
      _manualOverride = null;
    }
    _update();
  }

  /// Manually select a mode. Implicitly disables auto mode.
  void setManualMode(TimeOfDayMode mode) {
    _autoMode = false;
    _manualOverride = mode;
    _update();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _update() {
    final now = DateTime.now();
    final hour = now.hour;

    // Determine mode.
    final TimeOfDayMode resolved;
    if (_autoMode) {
      resolved = TimeModeConfig.configForHour(hour).mode;
    } else {
      resolved = _manualOverride ?? TimeModeConfig.configForHour(hour).mode;
    }

    final config = TimeModeConfig.allModes.firstWhere((c) => c.mode == resolved);

    // Daily-seeded quote index.
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final rng = Random(dayOfYear * 7 + resolved.index);
    final quote = config.quotePool[rng.nextInt(config.quotePool.length)];

    // Greeting text.
    final greeting = _greetingForMode(resolved);

    // Early-bird check — only meaningful for the clock-based hour, not manual.
    final earlyBird = hour >= 4 && hour < 7;

    // Only notify if something actually changed.
    final changed = !_initialized ||
        _currentMode != resolved ||
        _currentQuote != quote ||
        _greetingText != greeting ||
        _isEarlyBird != earlyBird;

    _currentMode = resolved;
    _currentConfig = config;
    _currentQuote = quote;
    _greetingText = greeting;
    _isEarlyBird = earlyBird;
    _initialized = true;

    if (changed) {
      notifyListeners();
    }
  }

  static String _greetingForMode(TimeOfDayMode mode) {
    switch (mode) {
      case TimeOfDayMode.dawn:
        return 'Good morning';
      case TimeOfDayMode.day:
        return 'Good afternoon';
      case TimeOfDayMode.evening:
        return 'Good evening';
      case TimeOfDayMode.night:
        return 'Time to rest';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

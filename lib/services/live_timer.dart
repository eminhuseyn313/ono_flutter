import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A running countdown (a deep-work block, a tool timer, rest between
/// sets) on the iPhone's Lock Screen and Dynamic Island, as a Live
/// Activity drawn by the ONOWidget extension (`OnoTimerAttributes` in
/// ios/Runner/AppDelegate.swift and ios/ONOWidget/ONOWidget.swift).
///
/// iPhone only; everywhere else, and when Live Activities are off or the
/// widget extension isn't installed, every call quietly does nothing.
class LiveTimer {
  static const _channel = MethodChannel('ono/live_activity');

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Shows [title] counting down to [endsAt]. [kind] is focus, timer or
  /// rest (the icon). Replaces any countdown already showing.
  Future<bool> start(
      {required String title,
      required DateTime endsAt,
      String kind = 'timer',
      String? next}) async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('start', {
            'title': title,
            'endsAtMs': endsAt.millisecondsSinceEpoch.toDouble(),
            'kind': kind,
            'next': next ?? '',
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Removes it (the timer finished, was reset or the screen closed).
  Future<void> end() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('end');
    } catch (_) {
      // Nothing showing, or no extension: fine.
    }
  }
}

/// Replaced in tests to see what would be shown.
LiveTimer liveTimer = LiveTimer();

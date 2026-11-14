import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The part of the day an iPhone Focus says it is, through ONO's Focus
/// filter (`OnoFocusFilter` in ios/Runner/AppDelegate.swift): Settings →
/// Focus → Work (or Personal, Sleep) → Focus Filters → ONO.
enum DeviceFocus { work, personal, winddown }

class FocusBridge {
  static const _channel = MethodChannel('ono/focus');

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static DeviceFocus? parse(Object? raw) => switch (raw) {
        'work' => DeviceFocus.work,
        'personal' => DeviceFocus.personal,
        'winddown' => DeviceFocus.winddown,
        _ => null,
      };

  /// The Focus filter now on, or null (no Focus, or none set up for ONO).
  Future<DeviceFocus?> current() async {
    if (!_supported) return null;
    try {
      return parse(await _channel.invokeMethod<String>('current'));
    } catch (_) {
      return null;
    }
  }

  /// [onChange] runs when a Focus with ONO's filter turns on or off while
  /// ONO is open.
  void listen(void Function(DeviceFocus?) onChange) {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') onChange(parse(call.arguments));
      return null;
    });
  }
}

/// Replaced in tests.
FocusBridge focusBridge = FocusBridge();

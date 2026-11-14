import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'widget_sync.dart';

WidgetSync createWidgetSync() =>
    Platform.isIOS ? HomeWidgetSync() : NoopWidgetSync();

/// Writes the snapshot to the app group and reloads the ONOWidget timeline,
/// and hands the same values to the Apple Watch (`OnoWatch` in
/// ios/Runner/AppDelegate.swift). Harmless when the widget extension or
/// the watch app isn't installed: the values just sit in UserDefaults.
class HomeWidgetSync implements WidgetSync {
  static const _watch = MethodChannel('ono/watch');
  bool _groupSet = false;
  String? _lastPushed;

  Future<void> _group() async {
    if (_groupSet) return;
    await HomeWidget.setAppGroupId(widgetAppGroup);
    _groupSet = true;
  }

  @override
  Future<void> push(WidgetSnapshot snapshot) async {
    final values = snapshot.toValues();
    final fingerprint = values.toString();
    if (fingerprint == _lastPushed) return;
    _lastPushed = fingerprint;
    try {
      await _group();
      for (final e in values.entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      await HomeWidget.updateWidget(iOSName: 'ONOWidget');
      await HomeWidget.updateWidget(iOSName: 'ONOItems');
    } catch (_) {
      // No widget or no app group yet — nothing to update.
    }
    try {
      await _watch.invokeMethod<void>('context', values);
    } catch (_) {
      // No watch paired, or an older build without the bridge.
    }
  }

  @override
  Future<void> clear() async {
    _lastPushed = null;
    try {
      await _group();
      for (final k in widgetKeys) {
        await HomeWidget.saveWidgetData<Object>(k, null);
      }
      await HomeWidget.updateWidget(iOSName: 'ONOWidget');
      await HomeWidget.updateWidget(iOSName: 'ONOItems');
    } catch (_) {
      // No widget or no app group — nothing to clear.
    }
    try {
      await _watch.invokeMethod<void>('context', <String, Object>{});
    } catch (_) {
      // No watch.
    }
  }

  @override
  Future<List<WidgetTick>> takeTicks() async {
    try {
      await _group();
      final raw = await HomeWidget.getWidgetData<String>('pending_ticks');
      final ticks = WidgetTick.parse(raw);
      if (raw != null) await HomeWidget.saveWidgetData<String>('pending_ticks', null);
      return ticks;
    } catch (_) {
      return const [];
    }
  }

  @override
  void listenForTicks(void Function() onWaiting) {
    _watch.setMethodCallHandler((call) async {
      if (call.method == 'ticksWaiting') onWaiting();
      return null;
    });
  }
}

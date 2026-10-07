import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import 'widget_sync.dart';

WidgetSync createWidgetSync() =>
    Platform.isIOS ? HomeWidgetSync() : NoopWidgetSync();

/// Writes the snapshot to the app group and reloads the ONOWidget timeline.
/// Harmless when the widget extension isn't installed: the values just sit
/// in UserDefaults.
class HomeWidgetSync implements WidgetSync {
  bool _groupSet = false;
  String? _lastPushed;

  @override
  Future<void> push(WidgetSnapshot snapshot) async {
    final values = snapshot.toValues();
    final fingerprint = values.toString();
    if (fingerprint == _lastPushed) return;
    _lastPushed = fingerprint;
    try {
      if (!_groupSet) {
        await HomeWidget.setAppGroupId(widgetAppGroup);
        _groupSet = true;
      }
      for (final e in values.entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      await HomeWidget.updateWidget(iOSName: 'ONOWidget');
    } catch (_) {
      // No widget or no app group yet — nothing to update.
    }
  }
}

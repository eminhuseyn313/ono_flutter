import 'dart:convert';

import 'widget_sync_stub.dart'
    if (dart.library.io) 'widget_sync_ios.dart' as impl;

/// App group shared by the app and the ONOWidget extension.
const widgetAppGroup = 'group.com.eminhuseynzade.ono';

/// What the Home Screen / Lock Screen widget shows. Plain values only:
/// they go to UserDefaults in the app group.
class WidgetSnapshot {
  final String dateKey;
  final int score;
  final int streak;
  final int programDay;
  final int protein;
  final int cardsDue;
  final String phase;

  /// Today's schedule as (minute of day, title), for "now" on the widget.
  final List<(int, String)> blocks;

  const WidgetSnapshot({
    required this.dateKey,
    required this.score,
    required this.streak,
    required this.programDay,
    required this.protein,
    required this.cardsDue,
    required this.phase,
    required this.blocks,
  });

  Map<String, Object> toValues() => {
        'date': dateKey,
        'score': score,
        'streak': streak,
        'day': programDay,
        'protein': protein,
        'cards_due': cardsDue,
        'phase': phase,
        'blocks': jsonEncode([
          for (final b in blocks) {'m': b.$1, 't': b.$2}
        ]),
      };
}

abstract class WidgetSync {
  /// Save [snapshot] for the widget and ask iOS to redraw it.
  Future<void> push(WidgetSnapshot snapshot);
}

class NoopWidgetSync implements WidgetSync {
  WidgetSnapshot? last;
  @override
  Future<void> push(WidgetSnapshot snapshot) async => last = snapshot;
}

/// The ONOWidget bridge on iOS, [NoopWidgetSync] elsewhere.
WidgetSync createWidgetSync() => impl.createWidgetSync();

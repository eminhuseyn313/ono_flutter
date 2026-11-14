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

  /// Daily items and how many hold the day (10 and 7 by default).
  final int total;
  final int target;
  final int streak;
  final int programDay;
  final int protein;
  final int cardsDue;
  final String phase;

  /// Today's schedule as (minute of day, title), for "now" on the widget.
  final List<(int, String)> blocks;

  /// Today's daily items as (id, title, done), so the widget and the
  /// watch can show and tick them.
  final List<(String, String, bool)> items;

  /// The first of today's three still open ('' when none).
  final String first;

  const WidgetSnapshot({
    required this.dateKey,
    required this.score,
    this.total = 10,
    this.target = 7,
    required this.streak,
    required this.programDay,
    required this.protein,
    required this.cardsDue,
    required this.phase,
    required this.blocks,
    this.items = const [],
    this.first = '',
  });

  Map<String, Object> toValues() => {
        'date': dateKey,
        'score': score,
        'total': total,
        'target': target,
        'streak': streak,
        'day': programDay,
        'protein': protein,
        'cards_due': cardsDue,
        'phase': phase,
        'blocks': jsonEncode([
          for (final b in blocks) {'m': b.$1, 't': b.$2}
        ]),
        'items': jsonEncode([
          for (final i in items) {'id': i.$1, 't': i.$2, 'd': i.$3}
        ]),
        'first': first,
      };
}

/// An item ticked (or unticked) on the widget or the watch, waiting in the
/// app group for the app to record it.
class WidgetTick {
  final String id;
  final String date;
  final bool on;
  const WidgetTick(this.id, this.date, this.on);

  /// [raw] is the JSON list the widget and the watch append to
  /// (`pending_ticks`); anything malformed is skipped.
  static List<WidgetTick> parse(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final e in list)
          if (e is Map && e['id'] is String && e['date'] is String)
            WidgetTick(e['id'] as String, e['date'] as String, e['on'] != false)
      ];
    } catch (_) {
      return const [];
    }
  }
}

abstract class WidgetSync {
  /// Save [snapshot] for the widget and ask iOS to redraw it.
  Future<void> push(WidgetSnapshot snapshot);

  /// Remove what the widget shows (signed out, everything deleted), so the
  /// next person on this phone doesn't see the last one's numbers.
  Future<void> clear();

  /// Ticks made on the widget or the watch since the last call, removed
  /// from the queue as they are handed over.
  Future<List<WidgetTick>> takeTicks();

  /// [onWaiting] runs when the watch sends a tick while ONO is open.
  void listenForTicks(void Function() onWaiting);
}

/// Every key [WidgetSnapshot.toValues] writes.
const widgetKeys = [
  'date', 'score', 'total', 'target', 'streak', 'day', 'protein', 'cards_due', 'phase', 'blocks',
  'items', 'first', 'pending_ticks'
];

class NoopWidgetSync implements WidgetSync {
  WidgetSnapshot? last;
  @override
  Future<void> push(WidgetSnapshot snapshot) async => last = snapshot;
  @override
  Future<void> clear() async {
    last = null;
    pending.clear();
  }

  /// Ticks a test pretends were made on the widget.
  final List<WidgetTick> pending = [];
  void Function()? onWaiting;

  @override
  Future<List<WidgetTick>> takeTicks() async {
    final t = List<WidgetTick>.of(pending);
    pending.clear();
    return t;
  }

  @override
  void listenForTicks(void Function() onWaiting) => this.onWaiting = onWaiting;
}

/// The ONOWidget bridge on iOS, [NoopWidgetSync] elsewhere.
WidgetSync createWidgetSync() => impl.createWidgetSync();

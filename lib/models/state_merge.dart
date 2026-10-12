import 'dart:convert';

/// Three-way merge of two copies of the personal-system state (as JSON),
/// so the phone and the web app can both change it without one
/// overwriting the other.
///
/// [base] is the copy both last agreed on (null on a device's first sync).
/// Anything one side changed since [base] is kept; when both changed the
/// same thing, [local] wins. A deletion on one side survives unless the
/// other side changed that item.
///
/// - Logs, evidence, reports, briefs and custom cards merge item by item
///   (by `id`), so entries made on two devices all survive.
/// - Done keys and each day's checks merge as sets.
/// - Priorities, cues, reminders and card schedules merge key by key.
/// - Everything else (start date, gym days, …) is a single value.
Map<String, dynamic> mergeStateJson(
  Map<String, dynamic>? base,
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final b = base ?? const <String, dynamic>{};
  final out = <String, dynamic>{};
  final keys = {...local.keys, ...remote.keys};
  for (final key in keys) {
    final bv = b[key], lv = local[key], rv = remote[key];
    final Object? merged;
    if (_idLists.contains(key)) {
      merged = _mergeById(_asList(bv, base != null), _asList(lv, true),
          _asList(rv, true));
    } else if (key == 'done') {
      merged = _mergeSet(_asList(bv, base != null), _asList(lv, true),
          _asList(rv, true));
    } else if (key == 'daily_checks') {
      merged = _mergeMap(_asMap(bv), _asMap(lv), _asMap(rv),
          (b, l, r) {
        final set = _mergeSet(
            b == null ? null : _asList(b, true), _asList(l, true),
            _asList(r, true));
        return set.isEmpty ? null : set;
      }, hasBase: base != null);
    } else if (_keyedMaps.contains(key)) {
      merged = _mergeMap(_asMap(bv), _asMap(lv), _asMap(rv), _pick,
          hasBase: base != null);
    } else {
      merged = base == null
          ? (local.containsKey(key) ? lv : rv)
          : _pick(bv, lv, rv);
    }
    if (merged != null || local.containsKey(key) || remote.containsKey(key)) {
      out[key] = merged;
    }
  }
  return out;
}

const _idLists = {'logs', 'evidence', 'reports', 'briefs', 'custom_cards'};
const _keyedMaps = {'priorities', 'cues', 'reminders', 'card_schedules'};

/// Whether two JSON values are equal.
bool jsonEquals(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

/// One value changed on at most one side: take the changed one; both
/// changed: local wins.
Object? _pick(Object? base, Object? local, Object? remote) =>
    jsonEquals(local, base) ? remote : local;

List<Object?>? _asList(Object? v, bool present) =>
    v is List ? v : (present ? const [] : null);

Map<String, dynamic> _asMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

List<Object?> _mergeSet(
    List<Object?>? base, List<Object?>? local, List<Object?>? remote) {
  final b = {...?base}, l = {...?local}, r = {...?remote};
  return [
    for (final x in {...l, ...r})
      if ((l.contains(x) && r.contains(x)) ||
          (l.contains(x) && !b.contains(x)) ||
          (r.contains(x) && !b.contains(x)))
        x,
  ];
}

Map<String, dynamic> _mergeMap(
  Map<String, dynamic> base,
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
  Object? Function(Object? base, Object? local, Object? remote) merge, {
  required bool hasBase,
}) {
  final out = <String, dynamic>{};
  for (final k in {...local.keys, ...remote.keys}) {
    final inL = local.containsKey(k), inR = remote.containsKey(k);
    Object? v;
    if (inL && inR) {
      v = merge(base[k], local[k], remote[k]);
    } else if (inL) {
      // Missing remotely: deleted there unless changed here.
      v = hasBase && base.containsKey(k) && jsonEquals(local[k], base[k])
          ? null
          : local[k];
    } else {
      v = hasBase && base.containsKey(k) && jsonEquals(remote[k], base[k])
          ? null
          : remote[k];
    }
    if (v != null) out[k] = v;
  }
  return out;
}

List<Object?> _mergeById(
    List<Object?>? base, List<Object?>? local, List<Object?>? remote) {
  String? idOf(Object? e) => e is Map ? e['id']?.toString() : null;
  Map<String, Object?> index(List<Object?>? list) => {
        for (final e in list ?? const [])
          if (idOf(e) != null) idOf(e)!: e,
      };
  final b = index(base), l = index(local), r = index(remote);
  final hasBase = base != null;
  final out = <Object?>[];
  final seen = <String>{};
  // Local order first (it is the order this device shows), then new remote
  // items in their order.
  for (final id in [...l.keys, ...r.keys]) {
    if (!seen.add(id)) continue;
    final inL = l.containsKey(id), inR = r.containsKey(id);
    Object? v;
    if (inL && inR) {
      v = hasBase && b.containsKey(id) ? _pick(b[id], l[id], r[id]) : l[id];
    } else if (inL) {
      v = hasBase && b.containsKey(id) && jsonEquals(l[id], b[id])
          ? null
          : l[id];
    } else {
      v = hasBase && b.containsKey(id) && jsonEquals(r[id], b[id])
          ? null
          : r[id];
    }
    if (v != null) out.add(v);
  }
  return out;
}

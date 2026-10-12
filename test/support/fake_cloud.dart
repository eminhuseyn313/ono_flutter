import 'dart:convert';

import 'package:ono/gateways/supabase_personal_system_gateway.dart';

/// The `personal_system` table in memory, with the same rules: one row per
/// user, versioned writes, a new generation on every insert.
class FakeCloud implements PersonalSystemCloud {
  final rows = <String, CloudRow>{};
  int _generations = 0;

  /// While true, every call throws (no network).
  bool offline = false;

  /// Runs once just before the next update is applied — lets a test slip
  /// another device's write in between (a lost race).
  Future<void> Function()? beforeNextUpdate;

  int writes = 0;

  void _check() {
    if (offline) throw Exception('offline');
  }

  Map<String, dynamic> _copy(Map<String, dynamic> m) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(m)) as Map);

  @override
  Future<CloudRow?> fetch(String userId) async {
    _check();
    final r = rows[userId];
    return r == null ? null : CloudRow(_copy(r.state), r.version, r.generation);
  }

  @override
  Future<String?> insert(String userId, Map<String, dynamic> state) async {
    _check();
    if (rows.containsKey(userId)) return null;
    final generation = 'g${++_generations}';
    rows[userId] = CloudRow(_copy(state), 1, generation);
    writes++;
    return generation;
  }

  @override
  Future<bool> update(String userId, Map<String, dynamic> state,
      {required int expectedVersion}) async {
    _check();
    final hook = beforeNextUpdate;
    beforeNextUpdate = null;
    if (hook != null) await hook();
    final r = rows[userId];
    if (r == null || r.version != expectedVersion) return false;
    rows[userId] = CloudRow(_copy(state), expectedVersion + 1, r.generation);
    writes++;
    return true;
  }

  @override
  Future<void> delete(String userId) async {
    _check();
    rows.remove(userId);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/personal_system.dart';
import '../models/state_merge.dart';
import 'mock_personal_system_gateway.dart';
import 'personal_system_gateway.dart';

/// Local-first with a cloud copy in `personal_system` (RLS: owner only),
/// shared by every device signed in to the same account — the iPhone and
/// the web app.
///
/// Every change is saved on the device at once; [sync] then merges it with
/// the cloud copy three ways (see `mergeStateJson`), against the copy this
/// device last agreed on, so changes made on two devices both survive.
/// Writes are conditional on the row's `version`, so two devices syncing at
/// the same moment can't overwrite each other: the loser merges again.
class SyncedPersonalSystemGateway implements PersonalSystemGateway {
  final SupabaseClient _client;
  final PersonalSystemGateway _local;

  SyncedPersonalSystemGateway(this._client, {PersonalSystemGateway? local})
      : _local = local ?? MockPersonalSystemGateway();

  /// Where the offline build (`main.dart`) kept its data. Adopted once by
  /// the first account that signs in on this device, so switching the
  /// iPhone to the synced build keeps everything.
  static const offlineKey = 'personal_system_mock-user-001';

  String _key(String userId) => 'personal_system_$userId';
  String _baseKey(String userId) => 'personal_system_base_$userId';
  String _versionKey(String userId) => 'personal_system_version_$userId';

  @override
  Future<PersonalSystemState> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString(offlineKey);
    if (prefs.getString(_key(userId)) == null && offline != null) {
      await prefs.setString(_key(userId), offline);
      await prefs.remove(offlineKey);
    }
    return _local.load(userId);
  }

  @override
  Future<void> save(String userId, PersonalSystemState state) =>
      _local.save(userId, state);

  Future<PersonalSystemState?>? _running;

  @override
  Future<PersonalSystemState?> sync(String userId, PersonalSystemState state) {
    // One sync at a time; a second caller waits and then runs with its
    // own (newer) state.
    final previous = _running;
    final next = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return _sync(userId, state);
    }();
    _running = next;
    return next;
  }

  Future<PersonalSystemState?> _sync(
      String userId, PersonalSystemState state) async {
    final prefs = await SharedPreferences.getInstance();
    final rawBase = prefs.getString(_baseKey(userId));
    final base = rawBase == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(rawBase) as Map);
    final baseVersion = prefs.getInt(_versionKey(userId));
    final local = _json(state);

    for (var attempt = 0; attempt < 4; attempt++) {
      final row = await _client
          .from('personal_system')
          .select('state, version')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        if (base != null) {
          // Deleted everything on another device.
          await _local.erase(userId);
          await _forgetBase(prefs, userId);
          return _local.load(userId);
        }
        if (!state.commissioned) return null;
        try {
          await _client.from('personal_system').insert({
            'user_id': userId,
            'state': local,
            'version': 1,
          });
        } on PostgrestException {
          continue; // Another device created it first: merge with that.
        }
        await _remember(prefs, userId, local, 1);
        return null;
      }

      final remote = Map<String, dynamic>.from(row['state'] as Map);
      final version = (row['version'] as num).toInt();
      if (version == baseVersion && jsonEquals(local, base)) return null;

      final merged = base == null && !state.commissioned
          ? remote
          : mergeStateJson(base, local, remote);
      var savedVersion = version;
      if (!jsonEquals(merged, remote)) {
        final updated = await _client
            .from('personal_system')
            .update({
              'state': merged,
              'version': version + 1,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('version', version)
            .select('version');
        if ((updated as List).isEmpty) continue; // Lost a race: merge again.
        savedVersion = version + 1;
      }
      await _remember(prefs, userId, merged, savedVersion);
      if (jsonEquals(merged, local)) return null;
      final next = PersonalSystemState.fromJson(merged);
      await _local.save(userId, next);
      return next;
    }
    return null; // Busy; the next sync tries again.
  }

  Map<String, dynamic> _json(PersonalSystemState state) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(state.toJson())) as Map);

  Future<void> _remember(SharedPreferences prefs, String userId,
      Map<String, dynamic> state, int version) async {
    await prefs.setString(_baseKey(userId), jsonEncode(state));
    await prefs.setInt(_versionKey(userId), version);
  }

  Future<void> _forgetBase(SharedPreferences prefs, String userId) async {
    await prefs.remove(_baseKey(userId));
    await prefs.remove(_versionKey(userId));
  }

  @override
  bool get syncsToCloud => true;

  /// Deletes the cloud row first, so a failure leaves the device copy.
  /// Other devices see the row gone on their next sync and start over too.
  @override
  Future<void> erase(String userId) async {
    await _client.from('personal_system').delete().eq('user_id', userId);
    await _local.erase(userId);
    await _forgetBase(await SharedPreferences.getInstance(), userId);
  }
}

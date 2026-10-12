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
  final PersonalSystemCloud _cloud;
  final PersonalSystemGateway _local;

  /// Namespaces this device's keys on the device (tests run two devices in
  /// one process); empty in the app.
  final String _device;

  SyncedPersonalSystemGateway(this._cloud, {String device = ''})
      : _device = device,
        _local = MockPersonalSystemGateway(prefix: device);

  /// Where the offline build (`main.dart`) kept its data. Adopted once by
  /// the first account that signs in on this device, so switching the
  /// iPhone to the synced build keeps everything.
  static const offlineKey = 'personal_system_mock-user-001';

  String _key(String userId) => 'personal_system_$_device$userId';
  String _baseKey(String userId) => 'personal_system_base_$_device$userId';
  String _versionKey(String userId) => 'personal_system_version_$_device$userId';
  String _generationKey(String userId) =>
      'personal_system_generation_$_device$userId';

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
    final baseGeneration = prefs.getString(_generationKey(userId));
    final local = _json(state);

    for (var attempt = 0; attempt < 4; attempt++) {
      final row = await _cloud.fetch(userId);

      if (row == null) {
        if (base != null) {
          // Deleted everything on another device.
          await _local.erase(userId);
          await _forgetBase(prefs, userId);
          return _local.load(userId);
        }
        if (!state.commissioned) return null;
        final generation = await _cloud.insert(userId, local);
        // Another device created it first: merge with that.
        if (generation == null) continue;
        await _remember(prefs, userId, local, 1, generation);
        return null;
      }

      final remote = row.state;
      final version = row.version;
      final generation = row.generation;
      if (base != null &&
          baseGeneration != null &&
          baseGeneration != generation) {
        // Deleted everything on another device (and maybe started again):
        // this device starts over and takes the new program, if any.
        await _local.erase(userId);
        await _forgetBase(prefs, userId);
        final fresh = await _local.load(userId);
        if (remote['commissioned'] != true) return fresh;
        final next = PersonalSystemState.fromJson(remote);
        await _local.save(userId, next);
        await _remember(prefs, userId, remote, version, generation);
        return next;
      }
      if (version == baseVersion &&
          generation == baseGeneration &&
          jsonEquals(local, base)) {
        return null;
      }

      // A device without a program never overwrites one: whatever its
      // base says, an empty local copy is not a list of deletions.
      // A device that has never synced (it may have built a plan while
      // offline on its first open) keeps its logs and ticks, but the
      // cloud's program — start date, length, settings — wins.
      final merged = !state.commissioned && remote['commissioned'] == true
          ? remote
          : base == null && remote['commissioned'] == true
              ? mergeStateJson(null, remote, local)
              : mergeStateJson(base, local, remote);
      var savedVersion = version;
      if (!jsonEquals(merged, remote)) {
        final ok = await _cloud.update(userId, merged, expectedVersion: version);
        if (!ok) continue; // Lost a race: merge again.
        savedVersion = version + 1;
      }
      await _remember(prefs, userId, merged, savedVersion, generation);
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
      Map<String, dynamic> state, int version, String generation) async {
    await prefs.setString(_baseKey(userId), jsonEncode(state));
    await prefs.setInt(_versionKey(userId), version);
    await prefs.setString(_generationKey(userId), generation);
  }

  Future<void> _forgetBase(SharedPreferences prefs, String userId) async {
    await prefs.remove(_baseKey(userId));
    await prefs.remove(_versionKey(userId));
    await prefs.remove(_generationKey(userId));
  }

  @override
  bool get syncsToCloud => true;

  /// Deletes the cloud row first, so a failure leaves the device copy.
  /// Other devices see the row gone on their next sync and start over too.
  @override
  Future<void> erase(String userId) async {
    await _cloud.delete(userId);
    await _local.erase(userId);
    await _forgetBase(await SharedPreferences.getInstance(), userId);
  }
}

/// The cloud copy: one row per user holding the whole state, a `version`
/// bumped on every write and a `generation` new on every insert.
class CloudRow {
  final Map<String, dynamic> state;
  final int version;
  final String generation;
  const CloudRow(this.state, this.version, this.generation);
}

/// Where the synced gateway keeps the cloud copy. [SupabaseCloud] in the
/// app; an in-memory one in tests.
abstract class PersonalSystemCloud {
  Future<CloudRow?> fetch(String userId);

  /// Creates the row at version 1; returns its generation, or null when a
  /// row already exists.
  Future<String?> insert(String userId, Map<String, dynamic> state);

  /// Writes [state] only if the row is still at [expectedVersion], bumping
  /// it; false when another device wrote first.
  Future<bool> update(String userId, Map<String, dynamic> state,
      {required int expectedVersion});

  Future<void> delete(String userId);
}

/// The `personal_system` table (RLS: owner only).
class SupabaseCloud implements PersonalSystemCloud {
  final SupabaseClient _client;
  SupabaseCloud(this._client);

  /// Signed out (or someone else): row-level security would answer with
  /// no row and no error, which looks exactly like "deleted everywhere".
  void _signedInAs(String userId) {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Not signed in as this user');
    }
  }

  @override
  Future<CloudRow?> fetch(String userId) async {
    _signedInAs(userId);
    final row = await _client
        .from('personal_system')
        .select('state, version, generation')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return CloudRow(Map<String, dynamic>.from(row['state'] as Map),
        (row['version'] as num).toInt(), '${row['generation']}');
  }

  @override
  Future<String?> insert(String userId, Map<String, dynamic> state) async {
    _signedInAs(userId);
    try {
      final created = await _client
          .from('personal_system')
          .insert({'user_id': userId, 'state': state, 'version': 1})
          .select('generation')
          .single();
      return '${created['generation']}';
    } on PostgrestException catch (e) {
      // Only "the row already exists" means another device was first;
      // anything else (RLS, a bad column) is a real error.
      if (e.code == '23505') return null;
      rethrow;
    }
  }

  @override
  Future<bool> update(String userId, Map<String, dynamic> state,
      {required int expectedVersion}) async {
    _signedInAs(userId);
    final updated = await _client
        .from('personal_system')
        .update({
          'state': state,
          'version': expectedVersion + 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('version', expectedVersion)
        .select('version');
    return (updated as List).isNotEmpty;
  }

  @override
  Future<void> delete(String userId) async {
    _signedInAs(userId);
    await _client.from('personal_system').delete().eq('user_id', userId);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/personal_system.dart';
import 'mock_personal_system_gateway.dart';
import 'personal_system_gateway.dart';

/// Local-first with a cloud mirror: reads and writes go to the device
/// immediately, then the whole state is upserted to `personal_system`
/// (RLS: owner only). On load the newer of the two copies wins, so a new
/// phone restores the program after sign-in.
class SyncedPersonalSystemGateway implements PersonalSystemGateway {
  final SupabaseClient _client;
  final PersonalSystemGateway _local;

  SyncedPersonalSystemGateway(this._client,
      {PersonalSystemGateway? local})
      : _local = local ?? MockPersonalSystemGateway();

  String _savedAtKey(String userId) => 'personal_system_saved_at_$userId';

  @override
  Future<PersonalSystemState> load(String userId) async {
    final local = await _local.load(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAt =
          DateTime.tryParse(prefs.getString(_savedAtKey(userId)) ?? '');
      final row = await _client
          .from('personal_system')
          .select('state, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        if (local.commissioned) await _push(userId, local);
        return local;
      }
      final remoteAt = DateTime.parse(row['updated_at'] as String);
      if (localAt == null || remoteAt.isAfter(localAt) || !local.commissioned) {
        final remote = PersonalSystemState.fromJson(
            Map<String, dynamic>.from(row['state'] as Map));
        await _local.save(userId, remote);
        await prefs.setString(
            _savedAtKey(userId), remoteAt.toIso8601String());
        return remote;
      }
    } catch (_) {
      // Offline or table missing — the device copy is authoritative.
    }
    return local;
  }

  @override
  Future<void> save(String userId, PersonalSystemState state) async {
    await _local.save(userId, state);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _savedAtKey(userId), DateTime.now().toUtc().toIso8601String());
    try {
      await _push(userId, state);
    } catch (_) {
      // Retried on the next save.
    }
  }

  @override
  bool get syncsToCloud => true;

  /// Deletes the cloud row first, so a failure leaves the device copy.
  @override
  Future<void> erase(String userId) async {
    await _client.from('personal_system').delete().eq('user_id', userId);
    await _local.erase(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedAtKey(userId));
  }

  Future<void> _push(String userId, PersonalSystemState state) =>
      _client.from('personal_system').upsert({
        'user_id': userId,
        'state': jsonDecode(jsonEncode(state.toJson())),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
}

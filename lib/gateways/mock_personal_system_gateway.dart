import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/emin_system.dart';
import '../models/personal_system.dart';
import 'personal_system_gateway.dart';

/// Device-local implementation: the whole state is one JSON blob in
/// SharedPreferences, so check-offs survive restarts in both mock and
/// production builds. First load seeds the evidence archive with the
/// "knowledge others don't have" items from the profile.
class MockPersonalSystemGateway implements PersonalSystemGateway {
  String _key(String userId) => 'personal_system_$userId';

  /// Device-wide program start, readable by other gateways (e.g. the coach
  /// tip rotation) without depending on this one.
  static const programStartKey = 'ono_program_start';

  /// Day number of the program on this device (1-based), or null if the
  /// program hasn't been started yet.
  static Future<int?> programDay() async {
    final prefs = await SharedPreferences.getInstance();
    final start = DateTime.tryParse(prefs.getString(programStartKey) ?? '');
    if (start == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(start).inDays + 1;
  }

  @override
  Future<PersonalSystemState> load(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    final now = DateTime.now();
    if (raw != null) {
      try {
        return PersonalSystemState.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Keep the unreadable blob so it can be recovered, then start fresh.
        await prefs.setString('${_key(userId)}_corrupt_${now.millisecondsSinceEpoch}', raw);
      }
    }
    final seeded = PersonalSystemState(
      programStart: DateTime(now.year, now.month, now.day),
      commissioned: false,
      evidence: [
        for (var i = 0; i < evidenceSeeds.length; i++)
          EvidenceItem(
            id: 'seed_$i',
            section: 'knowledge',
            text: evidenceSeeds[i],
            createdAt: now,
          ),
      ],
    );
    await save(userId, seeded);
    return seeded;
  }

  @override
  bool get syncsToCloud => false;

  @override
  Future<PersonalSystemState?> sync(
          String userId, PersonalSystemState state) async =>
      null;

  @override
  Future<void> erase(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().toList()) {
      if (k == _key(userId) || k.startsWith('${_key(userId)}_corrupt_')) {
        await prefs.remove(k);
      }
    }
    await prefs.remove(programStartKey);
  }

  @override
  Future<void> save(String userId, PersonalSystemState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(state.toJson()));
    await prefs.setString(
        programStartKey, state.programStart.toIso8601String());
  }
}

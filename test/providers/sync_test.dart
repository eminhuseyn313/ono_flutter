import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/gateways/mock_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';

/// A cloud copy held in memory; [sync] adds a note "from the web" and
/// waits for [release], so a test can edit while the request is out.
class _CloudGateway extends MockPersonalSystemGateway {
  Completer<void> release = Completer()..complete();
  int syncs = 0;

  @override
  bool get syncsToCloud => true;

  @override
  Future<PersonalSystemState?> sync(
      String userId, PersonalSystemState state) async {
    syncs++;
    await release.future;
    if (state.logs.any((l) => l.id == 'web')) return null;
    return state.copyWith(logs: [
      ...state.logs,
      LogEntry(
          id: 'web',
          type: 'note',
          date: DateTime(2026, 10, 12),
          createdAt: DateTime(2026, 10, 12),
          text: 'from the web'),
    ]);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loading takes in what another device changed', () async {
    final cloud = _CloudGateway();
    final system = PersonalSystemProvider(gateway: cloud);
    await system.load('u1');
    expect(system.logsOf('note').map((l) => l.text), ['from the web']);
    system.dispose();
  });

  test('an edit made while a sync is out is kept', () async {
    final cloud = _CloudGateway();
    final system = PersonalSystemProvider(gateway: cloud);
    // Already has the web note, so load's sync changes nothing.
    await system.load('u1');
    system.removeLog('web');
    cloud.release = Completer();
    final pending = system.syncNow();
    system.addLog('note', text: 'from the phone');
    cloud.release.complete();
    await pending;
    expect(system.logsOf('note').map((l) => l.text),
        containsAll(['from the phone', 'from the web']));
    system.dispose();
  });
}

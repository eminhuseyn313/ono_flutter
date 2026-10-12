import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ono/gateways/supabase_personal_system_gateway.dart';
import 'package:ono/models/personal_system.dart';
import 'package:ono/providers/personal_system_provider.dart';

import '../support/fake_cloud.dart';

/// The real sync (gateway + merge + provider) between two devices signed in
/// to the same account, against an in-memory cloud.
void main() {
  const user = 'u1';
  final today = DateTime(2026, 10, 12, 12);
  late FakeCloud cloud;
  final open = <PersonalSystemProvider>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = FakeCloud();
  });

  tearDown(() {
    for (final p in open) {
      p.dispose();
    }
    open.clear();
  });

  Future<PersonalSystemProvider> device(String name) async {
    final p = PersonalSystemProvider(
        gateway: SyncedPersonalSystemGateway(cloud, device: name))
      ..clock = () => today;
    open.add(p);
    await p.load(user);
    return p;
  }

  Future<PersonalSystemProvider> commissioned(String name) async {
    final p = await device(name);
    await p.commission(
        start: DateTime(2026, 10, 1), gymDays: const [1, 3, 5], reminders: const {});
    await p.syncNow();
    return p;
  }

  List<String> notes(PersonalSystemProvider p) =>
      [for (final l in p.logsOf('note')) l.text]..sort();

  test('a second device gets the program on its first load', () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'from the phone');
    await phone.syncNow();
    final web = await device('web');
    expect(web.isCommissioned, isTrue);
    expect(notes(web), ['from the phone']);
  });

  test('notes and ticks made on both devices all survive', () async {
    final phone = await commissioned('phone');
    final web = await device('web');
    final first = phone.dailyItems.first.id, second = phone.dailyItems[1].id;
    phone.addLog('note', text: 'phone');
    phone.setCheck(today, first, true);
    web.addLog('note', text: 'web');
    web.setCheck(today, second, true);
    await phone.syncNow();
    await web.syncNow();
    await phone.syncNow();
    for (final p in [phone, web]) {
      expect(notes(p), ['phone', 'web']);
      expect(p.isChecked(today, first), isTrue);
      expect(p.isChecked(today, second), isTrue);
    }
  });

  test('a deletion travels; an edit on the other side wins over it', () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'delete me');
    phone.addLog('note', text: 'keep me');
    await phone.syncNow();
    final web = await device('web');
    web.removeLog(web.logsOf('note').firstWhere((l) => l.text == 'delete me').id);
    final keep = phone.logsOf('note').firstWhere((l) => l.text == 'keep me');
    web.removeLog(web.logsOf('note').firstWhere((l) => l.text == 'keep me').id);
    phone.updateLog(keep.copyWith(text: 'keep me, edited'));
    await web.syncNow();
    await phone.syncNow();
    await web.syncNow();
    expect(notes(phone), ['keep me, edited']);
    expect(notes(web), ['keep me, edited']);
  });

  test('a lost race merges again instead of overwriting', () async {
    final phone = await commissioned('phone');
    final web = await device('web');
    phone.addLog('note', text: 'phone');
    web.addLog('note', text: 'web');
    // The web's write lands between the phone's read and its write.
    cloud.beforeNextUpdate = () => web.syncNow();
    await phone.syncNow();
    await web.syncNow();
    expect(notes(phone), ['phone', 'web']);
    expect(notes(web), ['phone', 'web']);
    expect(cloud.rows[user]!.state['logs'], hasLength(greaterThanOrEqualTo(2)));
  });

  test('offline: nothing breaks, and the edits go up once back', () async {
    final phone = await commissioned('phone');
    cloud.offline = true;
    phone.addLog('note', text: 'written offline');
    await phone.syncNow();
    expect(notes(phone), ['written offline']);
    cloud.offline = false;
    await phone.syncNow();
    final web = await device('web');
    expect(notes(web), ['written offline']);
  });

  test('a device with no program never overwrites one in the cloud',
      () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'precious');
    await phone.syncNow();
    final web = await device('web');
    expect(web.isCommissioned, isTrue);
    // The web's provider somehow still holds an empty state (a load that
    // timed out): syncing it must not delete the program.
    final gateway = SyncedPersonalSystemGateway(cloud, device: 'web');
    final blank = PersonalSystemState(programStart: DateTime(2026, 10, 12));
    final result = await gateway.sync(user, blank);
    expect(result?.commissioned, isTrue);
    expect(cloud.rows[user]!.state['commissioned'], isTrue);
    expect((cloud.rows[user]!.state['logs'] as List)
        .any((l) => (l as Map)['text'] == 'precious'), isTrue);
  });

  test('delete everything on one device: the other starts over too',
      () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'old life');
    await phone.syncNow();
    final web = await device('web');
    expect(notes(web), ['old life']);
    await phone.eraseEverything();
    await web.syncNow();
    expect(web.isCommissioned, isFalse);
    expect(notes(web), isEmpty);
  });

  test('delete, then a new program elsewhere: the other device takes it',
      () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'old life');
    await phone.syncNow();
    final web = await device('web');
    await phone.eraseEverything();
    await phone.commission(
        start: DateTime(2026, 10, 12), gymDays: const [1], reminders: const {});
    phone.addLog('note', text: 'new life');
    await phone.syncNow();
    await web.syncNow();
    expect(web.isCommissioned, isTrue);
    expect(notes(web), ['new life']);
    // And the old note didn't come back to the phone.
    await phone.syncNow();
    expect(notes(phone), ['new life']);
  });

  test('the offline build\'s data moves into the first account', () async {
    final legacy = PersonalSystemState(
      programStart: DateTime(2026, 9, 1),
      commissioned: true,
      logs: [
        LogEntry(
            id: 'n1',
            type: 'note',
            date: DateTime(2026, 9, 2),
            createdAt: DateTime(2026, 9, 2),
            text: 'from before sync'),
      ],
    );
    SharedPreferences.setMockInitialValues({
      SyncedPersonalSystemGateway.offlineKey: _encode(legacy),
    });
    final phone = await device('');
    expect(phone.isCommissioned, isTrue);
    expect(notes(phone), ['from before sync']);
    expect(cloud.rows[user], isNotNull); // and it went up to the cloud
  });

  test('a program setting changed on one device reaches the other', () async {
    final phone = await commissioned('phone');
    final web = await device('web');
    web.setProgramLength(180);
    await web.syncNow();
    await phone.syncNow();
    expect(phone.programDays, 180);
  });

  test('a deletion pulled back from the cloud stays deleted', () async {
    // The cloud hands objects back in its own key order (jsonb); unchanged
    // items must still count as unchanged.
    final phone = await commissioned('phone');
    final web = await device('web');
    final b = phone.addLog('note', text: 'b')!;
    await phone.syncNow();
    await web.syncNow();
    expect(notes(web), ['b']);
    phone.removeLog(b.id);
    await phone.syncNow();
    await web.syncNow();
    await phone.syncNow();
    expect(notes(web), isEmpty);
    expect(notes(phone), isEmpty);
  });

  test('a second edit on one device is not undone by the other', () async {
    final phone = await commissioned('phone');
    final web = await device('web');
    final n = phone.addLog('note', text: 'v1')!;
    await phone.syncNow();
    phone.updateLog(n.copyWith(text: 'v2'));
    await phone.syncNow();
    await web.syncNow();
    phone.updateLog(phone.logsOf('note').single.copyWith(text: 'v3'));
    await phone.syncNow();
    await web.syncNow();
    await phone.syncNow();
    expect(notes(phone), ['v3']);
    expect(notes(web), ['v3']);
  });

  test('idle syncs do not write to the cloud', () async {
    final phone = await commissioned('phone');
    await phone.syncNow();
    final before = cloud.writes;
    for (var i = 0; i < 5; i++) {
      await phone.syncNow();
    }
    expect(cloud.writes, before);
  });

  test('signed out, syncing stops; nothing local is erased', () async {
    final phone = await commissioned('phone');
    phone.addLog('note', text: 'kept');
    await phone.syncNow();
    phone.signedOut();
    // Without a session the cloud answers "no row" — like a delete.
    final saved = cloud.rows.remove(user);
    phone.addLog('note', text: 'offline edit');
    await phone.syncNow();
    expect(phone.isCommissioned, isTrue);
    expect(notes(phone), ['kept', 'offline edit']);
    cloud.rows[user] = saved!;
    await phone.load(user); // signing in again picks up syncing
    await phone.syncNow();
    expect(notes(phone), ['kept', 'offline edit']);
    expect([for (final l in PersonalSystemState.fromJson(cloud.rows[user]!.state).logs) if (l.type == 'note') l.text]..sort(),
        ['kept', 'offline edit']);
  });

  test('a new device offline on its first open doesn\'t restart the program',
      () async {
    final phone = await commissioned('phone'); // started 1 Oct
    phone.addLog('note', text: 'phone');
    await phone.syncNow();
    cloud.offline = true;
    final web = await device('web');
    await web.commission(
        start: DateTime(2026, 10, 12), gymDays: const [2, 4], reminders: const {});
    web.addLog('note', text: 'web');
    cloud.offline = false;
    await web.syncNow();
    await phone.syncNow();
    for (final p in [phone, web]) {
      expect(p.programStart, DateTime(2026, 10, 1));
      expect(notes(p), ['phone', 'web']);
    }
  });
}

String _encode(PersonalSystemState s) => jsonEncode(s.toJson());

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/models/state_merge.dart';

Map<String, dynamic> log(String id, [String text = '']) =>
    {'id': id, 'type': 'note', 'text': text};

void main() {
  final base = <String, dynamic>{
    'program_start': '2026-10-01',
    'gym_days': [1, 3, 4],
    'done': ['a', 'b'],
    'daily_checks': {
      '2026-10-12': ['sigh'],
    },
    'cues': {'sigh': 'After coffee'},
    'logs': [log('1', 'one'), log('2', 'two')],
  };

  Map<String, dynamic> copy(Map<String, dynamic> m) => {
        for (final e in m.entries)
          e.key: e.value is List
              ? [...e.value as List]
              : e.value is Map
                  ? {...e.value as Map}
                  : e.value,
      };

  test('logs added on two devices both survive', () {
    final phone = copy(base)..['logs'] = [...base['logs'], log('p')];
    final web = copy(base)..['logs'] = [...base['logs'], log('w')];
    final ids = (mergeStateJson(base, phone, web)['logs'] as List)
        .map((l) => l['id']);
    expect(ids, ['1', '2', 'p', 'w']);
  });

  test('a deletion on one side wins over an unchanged item', () {
    final phone = copy(base)..['logs'] = [log('2', 'two')];
    final merged = mergeStateJson(base, phone, copy(base));
    expect((merged['logs'] as List).map((l) => l['id']), ['2']);
    // …but not over an edit on the other side.
    final web = copy(base)..['logs'] = [log('1', 'edited'), log('2', 'two')];
    final kept = mergeStateJson(base, phone, web);
    expect((kept['logs'] as List).map((l) => l['text']), ['two', 'edited']);
  });

  test('an edit on the other device is taken in', () {
    final web = copy(base)..['logs'] = [log('1', 'one!'), log('2', 'two')];
    final merged = mergeStateJson(base, copy(base), web);
    expect((merged['logs'] as List).first['text'], 'one!');
  });

  test('checks and done keys merge as sets', () {
    final phone = copy(base)
      ..['daily_checks'] = {
        '2026-10-12': ['sigh', 'read'],
      }
      ..['done'] = ['a'];
    final web = copy(base)
      ..['daily_checks'] = {
        '2026-10-12': ['sigh', 'bluf'],
        '2026-10-13': ['sigh'],
      }
      ..['done'] = ['a', 'b', 'c'];
    final merged = mergeStateJson(base, phone, web);
    expect((merged['daily_checks'] as Map)['2026-10-12'],
        unorderedEquals(['sigh', 'read', 'bluf']));
    expect((merged['daily_checks'] as Map)['2026-10-13'], ['sigh']);
    expect(merged['done'], unorderedEquals(['a', 'c']));
  });

  test('unticking on one device sticks', () {
    final phone = copy(base)..['daily_checks'] = {'2026-10-12': <String>[]};
    final merged = mergeStateJson(base, phone, copy(base));
    expect((merged['daily_checks'] as Map).containsKey('2026-10-12'), isFalse);
  });

  test('single values: the changed side wins, local on a clash', () {
    final web = copy(base)..['gym_days'] = [2, 4, 6];
    expect(mergeStateJson(base, copy(base), web)['gym_days'], [2, 4, 6]);
    final phone = copy(base)..['gym_days'] = [1, 2, 3];
    expect(mergeStateJson(base, phone, web)['gym_days'], [1, 2, 3]);
    final cues = copy(base)..['cues'] = {'sigh': 'Before the 10:00'};
    expect(mergeStateJson(base, copy(base), cues)['cues'],
        {'sigh': 'Before the 10:00'});
  });

  test('a first sync without a base keeps everything from both', () {
    final phone = copy(base)..['logs'] = [log('p')];
    final web = copy(base)..['logs'] = [log('w')];
    final merged = mergeStateJson(null, phone, web);
    expect((merged['logs'] as List).map((l) => l['id']), ['p', 'w']);
  });
}

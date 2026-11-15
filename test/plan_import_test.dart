import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/data/plan_content.dart';
import 'package:ono/data/plan_import.dart';
import 'package:ono/data/plan_prompt.dart';
import 'package:ono/router.dart';

bool _routeOk(String r) => appRoutes.contains(r.split('?').first) || appRoutes.contains(r);

void main() {
  test('a full plan file loads as it was written', () {
    final text = File('test/support/example_plan.json').readAsStringSync();
    final before = PlanContent.fromJson(jsonDecode(text) as Map);
    final r = importPlan(text, routeOk: _routeOk);
    expect(r.error, isNull);
    final p = r.plan!;
    expect(p.profile!.name, before.profile!.name);
    expect(p.dailyItems.map((n) => n.id), before.dailyItems.map((n) => n.id));
    expect(p.dailyItems.map((n) => n.route), before.dailyItems.map((n) => n.route));
    expect(p.cues, before.cues);
    expect(p.gym.map((g) => g.id), before.gym.map((g) => g.id));
    expect(p.gym.expand((g) => g.exercises).length, before.gym.expand((g) => g.exercises).length);
    expect(p.schedule.length, before.schedule.length);
    expect(p.growthAreas.map((a) => a.id), before.growthAreas.map((a) => a.id));
    expect(p.growthAreas.expand((a) => a.drills).length, before.growthAreas.expand((a) => a.drills).length);
    expect(p.books.length + p.novels.length, before.books.length + before.novels.length);
    expect(p.reminders.map((x) => x.id), before.reminders.map((x) => x.id));
    expect(p.unlocks.values.expand((u) => u).length, before.unlocks.values.expand((u) => u).length);
    expect(p.seedCards.map((c) => c.id), before.seedCards.map((c) => c.id), reason: 'review history is keyed by them');
    expect(p.ritual.map((s) => s.id), before.ritual.map((s) => s.id));
    expect(p.coachTips.map((t) => t['id']), before.coachTips.map((t) => t['id']));
    expect(p.linkedinAbout, before.linkedinAbout, reason: 'sections it doesn\'t reshape pass through');
    expect(r.warnings, isEmpty, reason: r.warnings.join('\n'));
    expect(r.loaded.first, startsWith('Profile: '));
  });

  test('an AI answer with chat, fences and loose formats still loads', () {
    const answer = '''Sure! Here is your ONO plan:

```json
{
  "ono_plan": {
    "profile": { "name": "Rae Lindqvist", "current_role": "Nurse", "becoming": "Ward manager",
      "key_people": ["Mina", {"name": "Tom", "relation": "Partner", "every": 7}] },
    "daily_items": [
      {"title": "Swim 20 minutes", "lane": "fitness", "when": "morning", "cue": "When I drop the kids, I drive to the pool"},
      "Read 10 pages",
      {"title": "Call home", "lane": "family", "when": "night", "minimum": "One text"},
      {"title": "Plan tomorrow", "lane": "career", "route": "/nowhere"}
    ],
    "schedule": [
      {"time": "7:30 pm", "title": "Dinner, phones away", "lane": "family"},
      {"time": "06:15", "title": "Swim"},
      {"title": "No time here"}
    ],
    "training": [
      {"name": "Upper body", "day": "Tuesday", "exercises": ["Push-ups 3x10", {"name": "Rows", "sets": "3×12", "key_lift": true}]}
    ],
    "growth_areas": [{"name": "Leading a team", "drills": ["Ask one question first in every meeting"]}],
    "books": [{"title": "The Making of a Manager", "author": "Julie Zhuo", "month": 1},
              {"title": "Piranesi", "author": "Susanna Clarke", "kind": "novel"}],
    "movies": ["Twelve Angry Men"],
    "reminders": [{"label": "Lights out", "time": "22:30", "days": ["Mon", "Tue", "wed"]},
                  {"label": "No time"}],
    "month_themes": [{"month": 1, "theme": "Find the rhythm"}],
    "unlocks": [{"month": 2, "kind": "book", "title": "Start the second book", "route": "/learning"}],
    "coach_tips": ["Small and daily beats big and rare."],
    "cards": [{"front": "Your one rule for hard shifts?", "back": "Water, food, then decide."}],
  }
}
```
Let me know if you'd like changes!''';
    final r = importPlan(answer, routeOk: _routeOk);
    expect(r.error, isNull, reason: r.error);
    final p = r.plan!;
    expect(p.profile!.name, 'Rae Lindqvist');
    expect(p.profile!.firstName, 'Rae');
    expect(p.profile!.targetRole, 'Ward manager');
    expect(p.profile!.keyPeople.map((k) => k.name), ['Mina', 'Tom']);
    expect(p.dailyItems.map((n) => n.id), ['swim_20_minutes', 'read_10_pages', 'call_home', 'plan_tomorrow']);
    expect(p.dailyItems.map((n) => n.lane), ['body', 'mind', 'social', 'skill']);
    expect(p.dailyItems.map((n) => n.when), ['morning', 'day', 'evening', 'day']);
    expect(p.dailyItems.last.route, isNull);
    expect(p.cues['swim_20_minutes'], startsWith('When I drop'));
    expect(p.minimums['call_home'], 'One text');
    expect(p.schedule.map((b) => b.timeLabel), ['06:15', '19:30'], reason: 'sorted, 12-hour times read');
    expect(p.gym.single.weekday, DateTime.tuesday);
    expect(p.gym.single.exercises.first.name, 'Push-ups');
    expect(p.gym.single.exercises.first.sets, '3x10');
    expect(p.gym.single.exercises.last.keyLift, isTrue);
    expect(p.growthAreas.single.drills.single.title, startsWith('Ask one question'));
    expect(p.books.single.month, 1);
    expect(p.novels.single.title, 'Piranesi');
    expect(p.films.single.title, 'Twelve Angry Men');
    expect(p.reminders.single.weekdays, [1, 2, 3]);
    expect(p.reminders.single.hour, 22);
    expect(p.monthThemes[1], 'Find the rhythm');
    expect(p.unlocks[2]!.single.route, '/learning');
    expect(p.coachTips.single['content'], startsWith('Small and daily'));
    expect(p.seedCards.single.back, startsWith('Water'));
    expect(r.warnings.join('\n'), allOf(contains('/nowhere'), contains('No time here'), contains('"No time"')));
    expect(r.loaded, contains('4 daily items'));
  });

  test('what can\'t be read says why, in words', () {
    expect(importPlan('hello').error, contains('no plan'));
    expect(importPlan('{"profile": {"name": "A"}, "daily_items": [').error, contains('cut off'));
    expect(importPlan('{"daily_items": []}').error, contains('no name'));
    expect(importPlan('[1, 2]').error, isNotNull);
    final many = {
      'profile': {'name': 'Kim'},
      'daily_items': [for (var i = 0; i < 20; i++) 'Item $i'],
    };
    final r = importPlan(jsonEncode(many));
    expect(r.plan!.dailyItems, hasLength(15));
    expect(r.warnings.single, contains('first 15'));
  });

  test('every link the prompt allows exists, and the prompt carries their answers', () {
    final allowed = RegExp(r'use only: ([^\n]+)\.').firstMatch(planFormatSpec)!.group(1)!.split(' ');
    for (final r in allowed) {
      expect(appRoutes, contains(r), reason: r);
    }
    final p = planPrompt(about: ['Name: Rae', '', 'Goal: Run 10 km'], programDays: 180);
    expect(p, contains('- Name: Rae'));
    expect(p, contains('- Goal: Run 10 km'));
    expect(p, contains('180 days (6 months)'));
    expect(p, contains('"daily_items"'));
    expect(p, isNot(contains('- \n')));
  });
}

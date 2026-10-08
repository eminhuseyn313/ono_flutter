# ONO — Emin's personal operating system

## What This Is
ONO is the personal operating system of Emin Huseynzade: Senior Product Owner for Business ID at Bir Ecosystem (PASHA Financial Holding), Baku. Archetype: **The Product Architect**. It runs one 18-month program (540 days, four phases: Foundation 1–2, Craft 3–6, Signal 7–12, Leverage 13–18) across four lanes: Mind, Body, Skill, Social. Flutter app, Supabase backend.

Everything shown comes from his profile (encoded in `lib/data/emin_system.dart`) or from what he logs. **No sample or fake numbers anywhere.** That was the #1 finding in `docs/CRITIQUE.md`.

## Architecture

```
Content (lib/data) ─┐
Models → Gateways (abstract + mock/Supabase) → Providers (ChangeNotifier) → Screens/Widgets
Services: ReminderService (local notifications), BriefGenerator (weekly brief)
```

- **Content**:
  - `lib/data/emin_system.dart`: schedule, gym plan, Daily 10 (`nonNegotiables`), rotations, library, protocols, style, career, journey (`phases`, `monthThemes`, `unlocksFor(month)`, `artifactFor`), reminders (`reminderDefs`), mastery levels.
  - `lib/data/emin_personal_content.dart`: morning ritual steps, coach tips (`coachTipForDay`), weekly review questions.
- **State**: `PersonalSystemProvider` (`lib/providers/personal_system_provider.dart`) holds everything:
  - commission and start date;
  - Daily 10 checks, priorities, done keys;
  - logs (weight, protein, gym, protocols, notes, wins, bloodwork, …), evidence, Sunday reports, briefs;
  - reminders, export/import.
  It persists through `PersonalSystemGateway`:
  - `MockPersonalSystemGateway`: SharedPreferences, offline.
  - `SyncedPersonalSystemGateway`: local-first plus the Supabase `personal_system` table.
- **Auth**: `AuthProvider(gateway:)` with `MockAuthGateway` (persists the email) or `SupabaseAuthGateway`.
- **Navigation**: GoRouter, `createRouter()` in `lib/router.dart`. `appRoutes` lists every concrete route and is used by the smoke test.
- **Entry points**: both build `OnoApp` (`lib/app.dart`).
  - `main.dart` is offline: mock gateways, local notifications.
  - `main_production.dart` is live: Supabase auth and sync, plus `RemoteBriefGenerator` → the `weekly-brief` edge function.

## Critical Conventions

- Providers take a named `gateway:` (`PersonalSystemProvider(gateway: …, reminders: …, briefGenerator: …)`). `clock` can be overridden in tests.
- **`withValues(alpha: 0.5)`, not `withOpacity`.** `PopScope` uses `onPopInvokedWithResult`.
- **No `\$` escaping in strings.** Use `'text $variable'`.
- **No chart packages.** All charts are `CustomPaint` (`lib/widgets/ono_charts.dart`).
- Dates: use `dateKey`, `dayOnly`, `weekStartOf` from `lib/models/personal_system.dart`. A program month is a 30-day block from `programStart`.
- Logs sort by the day they are for, then entry order (`logsOf` is newest first; `weightSeries` is oldest first).
- Every new screen must fit iPhone SE (375×667) with the real fonts. The smoke test fails on overflow.
- Every route a piece of content points to (`NonNegotiable.route`, `ReminderDef.route`, `Unlock.route`) must exist. The smoke test resolves each one.

### Theme
`lib/theme/app_theme.dart`: `AppColors`, `AppText`, `AppSpace`, radius 16. Charcoal surfaces, ivory text, one cognac accent, navy for journey surfaces. Dark only.

```dart
AppColors.background 0xFF0B0C0E · card 0xFF14161A · cardLight 0xFF1B1E23 · divider 0xFF24272D
AppColors.accent (= purple) 0xFFC8894A · accentPressed 0xFFA86D35 · ink 0xFF0B0C0E (text on accent)
AppColors.navy 0xFF18222F · navyLight 0xFF223042 · white 0xFFF3EFE7 · grey 0xFFA39E95 · faint 0xFF6E6A63
AppColors.mind 0xFF8FA3C8 · body 0xFF86B49A · skill 0xFF6FAFB3 · social 0xFFC49AC0 · AppColors.lane('mind')
```

Type:
- Display and section titles use **Instrument Serif**: `AppText.display()`, `title()`, `serif(size:)`.
- UI text uses **Plus Jakarta Sans**: `heading`, `body`, `small`, `eyebrow`, `number`.
- Both fonts are bundled in `assets/google_fonts/`, so runtime fetching is off.

Shared widgets:
- `lib/widgets/ono_ui.dart`: `OnoPage`, `OnoCard`, `SectionHeader`, `CheckRow` (with haptics), `PrimaryButton`, `GhostButton`, `Segmented`, `StatTile`, `LinkRow`, `toast`, …
- `lib/widgets/ono_charts.dart`: `DayDial`, `Spine`, `HeatGrid`, `TrendLine`, `WeekBars`.

## Routes

Bottom tabs: **Today** `/home` · **Program** `/program?tab=0..3` (Journey/Schedule/Body/Reference) · **Log** `/log?add=weight|protein|win|note|blood` · **Me** `/profile`.

```
/splash /welcome /sign-up /sign-in /forgot-password /commission
/manifesto /protocols /evidence /library /style /career /weekly-coaching /checkin /plans /review /habits /cockpit(?tab=0..2)
/shutdown /focus /letters /week /people
/ritual-flow/:ritualId /gym /gym/:dayId (push|pull|legs) /month/:m (1–18)
/tool/:id  sigh excited pause still bluf sixq read feynman scan pennebaker anki artifact(?month=) linkedin
```

Flow:
- Sign-up → `/commission`, five steps: identity, start date, gym days and weight, reminders, hold to sign the manifesto.
- Today redirects to `/commission` until the system is commissioned.

## Behaviour worth knowing
- **Today** is time-aware: morning, work, evening and Sunday modes, plus a Yesterday/Today switch (the 48-hour edit window). Its Day Dial shows the schedule as lane arcs.
- **Daily 10**: 7/10 holds the day. Tools tick their item:
  - sigh, bluf, pause, feynman, scan and read are ticked when the tool is used;
  - finishing the ritual ticks the manifesto;
  - protein ticks itself at 150 g.
- **Streak, "never miss twice"** (`_streaks` in the provider):
  - one day under 7 is forgiven if the next day is held (or is today, still open);
  - at most one forgiven day per 7 days;
  - two misses in a row reset the streak.
  - `isRecoveryDay` drives Today's recovery card.
- **Fresh starts**: `freshStartFor(day)` returns a Monday card (last week's weakest item plus its cue), a first-of-month card or a phase-change card. It is dismissed via its `done` key.
- **If-then plans**: `defaultCues` in `emin_system.dart`, with overrides in `PersonalSystemState.cues` (`cueFor` / `setCue`).
  - Cues show under unticked Daily 10 items and in the caffeine/bed reminders, and are edited on `/plans`.
  - `setCue` takes `reschedule: false` while typing; call `resyncReminders` afterwards.
- **Morning check-in** (`/checkin`): a `checkin` log, one per day, holding energy 1–5, mood −2…2, sleep h, shoulder pain 0–10 and stiffness bucket 0–4.
  - `shoulderFlag` = pain ≥ 5 or stiffness ≥ 3 (30+ min).
  - A flagged morning makes the gym screen shoulder-sparing: it skips `Exercise.shoulder` and adds `shoulderSparingAddOns`, with a switch back to the normal plan.
  - Me → Mornings shows the averages, the pain trend and a rheumatologist note at 3+ flagged days.
  - The Sunday brief gets avg energy, sleep and flag days.
  - Never give medication or supplement advice.
- **Review deck** (`/review`):
  - SM-2 scheduling via `CardSchedule.review` in `models/personal_system.dart`.
  - Cards are `seedCards` (key facts, thesis, protocols, RA rules), one card per Feynman note, and custom cards.
  - At most `newCardsPerDay` (5) new cards a day.
  - Finishing a session logs `anki` kind `review`, so the Anki streak keeps counting.
- **Career cockpit** (`/cockpit`): three tabs.
  - 1:1s are `one_on_one` logs; follow-ups use `done` keys `fu:<logId>:<i>` and show on Today.
  - Decisions are `decision` logs with `review_on` 90 days out; `dueDecisionReviews` and `reviewDecision` record right/mixed/wrong.
  - Readiness is a monthly `readiness` log rated 1–5 per `readinessDimensions` (bar 4). `readinessGap` feeds the brief.
- **Automaticity** (`/habits`): a monthly `automaticity` log, rated 1–5 per Daily 10 item.
  - `isAutomatic` = rating ≥ 4 and done on ≥ 80% of the last 30 days.
  - Automatic items move to a quiet group on Today, and their `itemReminder` is skipped.
  - The check is prompted from day 25 of each month.
- **Apple Health** (`lib/services/health_service*.dart`, `health` package):
  - Behind a `HealthService` with a conditional import, so web and tests use `NoopHealthService`; tests use `test/support/fake_health.dart`.
  - Connected = `done` key `health:connected` (Me → Mornings → Connect Apple Health).
  - `syncHealth()` runs on Today load and on pull-to-refresh. It upserts one `sleep` log (asleep h, bed start, wake) and one `vitals` log (HRV, resting HR) per morning for 3 days.
  - Bed start ≤ 22:45 ticks `bed` for that evening; it never un-ticks.
  - Overlapping samples are merged in `summarizeNight`.
  - The check-in pre-fills sleep from it, and `logWeight` also writes to Health.
  - Sleep and vitals logs show under Log → Body, not in All.
  - Needs the HealthKit entitlement: `bash scripts/capabilities.sh health on` (see below). Without it, `connectHealth` returns a message saying how to switch it on.
- **Home Screen / Lock Screen widget** (`ios/ONOWidget/ONOWidget.swift`, `home_widget` package):
  - `WidgetSync` (conditional import, as for Health) pushes a `WidgetSnapshot` 2 s after the last change, and on Today load.
  - The snapshot holds score, streak, day, protein, cards due, phase and the schedule blocks, written to app group `group.com.eminhuseynzade.ono`.
  - The Swift widget draws small and medium Home Screen sizes plus circular, rectangular and inline Lock Screen styles, with a timeline entry at each schedule block.
- **Opt-in iOS capabilities** (`scripts/capabilities.sh health|widget on|off`):
  - `scripts/ios_capabilities.rb` uses the xcodeproj gem to add the HealthKit entitlement and/or the ONOWidget target plus the app group to a pristine `project.pbxproj`.
  - Choices live in `ios/.capabilities/` (git-ignored). `common.sh` re-applies them after every pull, and `Install on my iPhone.command` asks once.
  - They are kept out of the committed project because a personal Apple team may not support them, and an unsupported one would block installs.
  - Never hand-edit these in Xcode: the launchers stash local project edits.
- **Gym rest timer** (`gym_session_screen.dart`): ticking a set starts `PersonalSystemProvider.restFor(exercise)` (90 s, 120 s for key lifts) with +15/Skip.
  - `startRest`/`cancelRest` schedule a one-off notification through `ReminderService.notifyOnce` (id `restNotificationId`, ≥ `onceIdBase`); it is silent while ONO is in the foreground.
  - Weekly `sync` only cancels ids below `onceIdBase`, so a running rest survives a reminder resync.
- **Tool timers** (`CountdownTimer` in `tool_screens.dart`) count from an end time, so they stay right after iOS suspends ONO, and notify at the end via `notifyTimerEnd` (id `timerNotificationId`).
- **Home Screen shortcuts** (`lib/services/app_shortcuts.dart`, `quick_actions`): long-press the icon for check-in, protein, gym and review. `appShortcutList` routes must exist (tested). On a cold start `OnoApp` holds the route until sign-in is restored, then opens it over Today.
- **Meetings** (`lib/services/calendar_service*.dart`, `device_calendar`, conditional import like Health; tests use `test/support/fake_calendar.dart`):
  - Connected = `done` key `calendar:connected` (Me → Connect your calendar). Needs only the `NSCalendars*UsageDescription` strings, no entitlement.
  - `syncCalendar()` runs on Today load and refresh. Meetings are held in memory only, never saved, exported or synced.
  - `isRealMeeting` = 2+ attendees or a key meeting; `isKeyMeeting` = a `keyPeople` name (Ali, Rustam) as a whole word in the title or invitees.
  - A nudge 10 min before each real meeting still ahead (ids from `onceIdBase + 100`, at most 8): `/tool/sixq` for key meetings, `/tool/sigh` otherwise.
  - Today's Meetings card shows hours in meetings and warns when one covers the 12:00 read.
- **Evening shutdown** (`/shutdown`): tick today's three, write tomorrow's (unfinished ones carry over via `carryOverFrom`), empty the head into a note. `completeShutdown` sets tomorrow's priorities and upserts one `shutdown` log per day. Today's evening card offers it until done; patterns compare it with that night's sleep.
- **Deep work** (`/focus`): 25/50/90-min `CountdownTimer` blocks on the artifact, a skill or other → `focus` logs (`logFocus`). `focusMinutesInWeek` and `artifactMinutesThisMonth` feed Today's inputs strip, Me and the brief.
  - `freeBlocks(day)`: gaps of 60+ min between 09:00 and 18:00 still ahead, around every calendar event and the 12:00–12:30 read. The first shows in Today's Meetings card.
- **Meeting debrief**: 5 min after a key meeting ends, a nudge opens `/cockpit` (ids from `onceIdBase + 120`). `debriefsDue` puts it on Today until a 1:1 is logged after the meeting.
- **Letters** (`/letters`): `letter` logs sealed until `open_on` (30/90 days, next phase, day 540 = `programEnd`). Never shown in the Log tab. `lettersToOpen` prompts on Today; `markLetterRead` sets `letter:<id>`.
- **Big 3** (`/week`): one `week_plan` log per week (dated `weekStartOf`) holding `outcomes` (3) and `done` indexes. `setWeekOutcome`/`toggleWeekOutcome`/`weekOutcomeScore`. Today shows them tickable (or a prompt to set them); from Saturday `/week` also plans next week; the Sunday report reviews them and the brief gets them as `[done]`/`[open]`.
- **People** (`/people`): `person` logs (name, `role`, `every` days); `touch` logs record contact. `lastContact` also counts `one_on_one` logs whose `with` matches the first name as a whole word. `peopleDue` (past cadence, most overdue first) prompts on Today and goes into the brief. People never show in the Log tab; `removePerson` also drops their touches.
- The shutdown's "one good thing" is saved as a `win` (once per text per day).
- **Patterns** (`patterns()` → `DayPattern`, Me → "What moves your day"): compares an outcome on days with vs without a habit over the last 60 closed days. Needs `minDays` (5) on each side and a minimum gap; shown as patterns, not proof. The top three go into the Sunday brief (`BriefInput.patterns`).
- **Sunday report** → `submitReport` → `BriefGenerator`:
  - `DeviceBriefGenerator` is rule-based and uses real data only.
  - `RemoteBriefGenerator` calls Claude via `supabase/functions/weekly-brief` and falls back to the device generator on any error.
- **Reminders**: `plannedReminders()` builds weekly notifications from `reminderDefs` with today's content. `LocalReminderService` schedules them (flutter_local_notifications); tapping one opens its route. Web uses `NoopReminderService`.

## Supabase (project `kkgkbfxvovrtmnoezcha`)
Not deployed from this repo automatically. To turn on sync and the Claude-written brief:
```bash
supabase link --project-ref kkgkbfxvovrtmnoezcha
supabase db push                                   # creates personal_system + RLS
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy weekly-brief
flutter run -t lib/main_production.dart
```

## Testing
- `flutter analyze` must report 0 issues.
- `flutter test`:
  - `test/widget_test.dart` covers first run (welcome → commission), then commissions and opens every route, plus all content links, at 393×852 and 375×667. It fails on any runtime error, overflow or dead route.
  - `test/providers/personal_system_provider_test.dart` covers timeline, scores, streaks, protein, mastery, gym, month stats, briefs, export/import and reminders.
- Manual testing uses one-click apps at the repo root, `ONO Simulator.app` and `ONO on iPhone.app`.
  - Each is a script bundle that runs `open -a Terminal` on its `.command`.
  - The launchers pull `main` and stash files that Flutter or Xcode rewrote (`scripts/common.sh`).
  - iOS helpers live in `scripts/ios.sh`. Xcode 27 replaced Simulator.app with Device Hub (`com.apple.dt.Devices`, opened via `devices://device/open?id=<udid>`); the helper supports both.
- Checklist: `TESTING.md`.
- `test/widget_test.dart` also renders with real iPhone insets (Dynamic Island and SE) and fails on text under the status bar.
- The web build here needs `--no-web-resources-cdn` when the CDN is unreachable.

### Physical iPhone & release
- `Install on my iPhone.command` installs a release build on a plugged-in iPhone. Shared iOS helpers live in `scripts/ios.sh`.
- `RELEASE.md` covers TestFlight and the App Store.
- Bundle ID `com.eminhuseynzade.ono`, iPhone only, team `XYY5Y3F4W5`.
- The icon is rendered from the Day Dial motif; regenerate every size if it changes.

## Not built (needs Xcode / native targets)
The native parts can't be compiled here:
- The widget's Swift code and the HealthKit/App Group signing are unverified until built on the Mac.
- Live Activities and on-device encryption of health fields are not built yet. The calendar plugin (EventKit) is unverified until built on the Mac.
- The project edits themselves are tested here with the xcodeproj gem. Row-level security protects the cloud copy.

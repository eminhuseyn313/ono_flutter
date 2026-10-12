# ONO — Emin's personal operating system

## What This Is
ONO is the personal operating system of Emin Huseynzade: Senior Product Owner for Business ID at Bir Ecosystem (PASHA Financial Holding), Baku. Archetype: **The Product Architect**. It runs one 18-month program (540 days, four phases: Foundation 1–2, Craft 3–6, Signal 7–12, Leverage 13–18) across four lanes: Mind, Body, Skill, Social. Flutter app, Supabase backend.

**Direction (from Emin):** ONO is about his personal and professional development, not about app mechanics. New work should help him grow: practice, reflection, feedback, learning and his relationships. Avoid adding phone plumbing (widgets, shortcuts, integrations) unless it directly serves that.

**Where it's going:** first make ONO genuinely useful for Emin, day to day; then configure it for many people — anyone (a leader, an athlete, a CEO, a parent) builds their own progress plan. Emin's profile is the first fully configured plan. So:
- Every feature built for him must work for anyone: no feature exists only for his job at Kapital Bank / Business ID.
- Names, roles, organisation, key people and the coach's context come from `activeProfile` (`Profile` in `lib/data/profile.dart`, his values in `emin_system.dart`). `test/generality_test.dart` fails if screens, providers, services or the edge function mention him, his people or his employer.
- Build new features as configurable data plus generic logic. Keep person-specific content in `lib/data/` (his profile) and never hard-code his specifics into providers or screens.
- General content (e.g. `lib/data/growth_templates.dart`) must not mention him, his employer or his people (tested).
- Cover the whole person — career, body, relationships, money, mind, meaning — not only his job.
- Be curious and careful: when a requirement is ambiguous, ask him rather than guess.
- Feature research starts from this vision and passes two tests: useful to Emin now, and useful to anyone. See `docs/PRODUCT_RESEARCH.md` (market, evidence, roadmap).

Everything shown comes from his profile (encoded in `lib/data/emin_system.dart`) or from what he logs. **No sample or fake numbers anywhere.** That was the #1 finding in `docs/CRITIQUE.md`.

## Architecture

```
Content (lib/data) ─┐
Models → Gateways (abstract + mock/Supabase) → Providers (ChangeNotifier) → Screens/Widgets
Services: ReminderService (local notifications), BriefGenerator (weekly brief)
```

- **Profile** (`lib/data/profile.dart`): `Profile` (name, first name, current/target role, organisation, focus, domain, location, archetype, tagline, identity statement, path, `KeyPerson`s with relation, contact rhythm and `primary`, `coachContext`; `toJson`/`fromJson`/`copyWith`, `roleLine`, `manager`, `keyPeopleNames`).
  - `activeProfile` (getter in `emin_system.dart`) = the edited profile (`profileOverride`) or `builtInProfile` (his, as shipped). Screens never use `EminIdentity` (tested).
  - Edited at Me → Settings → Your profile (`/profile/edit`): stored as one `profile` log (hidden from the Log tab, travels with export/import/sync); `saveProfile`/`resetProfile`; the provider applies it on `load` and `importJson`.
  - `keyPeople` (names) derives from it. `BriefInput.profile` defaults to it and goes to the coach, whose system prompt is general.
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
  - `SyncedPersonalSystemGateway`: local-first plus the Supabase `personal_system` table, merged between devices (see Sync).
- **Auth**: `AuthProvider(gateway:)` with `MockAuthGateway` (persists the email) or `SupabaseAuthGateway`.
- **Navigation**: GoRouter, `createRouter()` in `lib/router.dart`. `appRoutes` lists every concrete route and is used by the smoke test.
- **Entry points**: both build `OnoApp` (`lib/app.dart`).
  - `main.dart` is offline: mock gateways, local notifications.
  - `main_production.dart` is live: Supabase auth and sync, plus `RemoteBriefGenerator` → the `weekly-brief` edge function.

### The built-in plan vs. someone else
`isBuiltInPerson` (provider) = the active profile's name is `builtInProfile.name`. His plan's specifics apply only then; anyone else sees the general app built from their own plan:
- Today: the Day Dial without `dailySchedule` (`DayDial.schedule`); `_ModeCard._general` (check-in → first morning item, breathe/focus/pause/reset, shutdown → a win, Sunday report); `_GeneralInputs` (review, deep work, movement, learning) instead of the podcast/scan/read/outfit strip; no `_BodyCard` (protein/weight/gym) or `_CoachNote`.
- Program: the journey only — no Schedule/Body/Reference tabs, no month themes, unlocks or career milestones; `Spine.steps` from the profile's current and target role; phase text from `generalPhasePromises` (`lib/data/general_program.dart`); the month links to their growth area and goals.
- Growth: `allGrowthAreas` = their own areas; the chooser offers `areaTemplates`, adopted on focus (`focusOn`); `suggestedArea` follows the lowest life area.
- Me: no protocol mastery or readiness; Body shows `_MoveSummary`. Check-in: no shoulder pain/stiffness (his condition); Mornings shows mood instead.
- Evidence Archive: `activeEvidenceSections` = `generalEvidenceSections` (general prompts) instead of his.
- Review deck: no `seedCards`. Brief: `builtInPlan: false` drops gym, artifact, LinkedIn and unlock tasks and the month theme/artifact/book; no readiness gap. A new person's plan builder also removes the seeded evidence.
- New features must work in both modes; `test/widget_test.dart` renders a second person and fails if built-in specifics (shoulder pain, the 07:45 desk card and scan tile, face pulls, lunch read, LinkedIn posts, gym sessions) appear.

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

Me starts with "Find a tool" (`/tools`: every tool in `toolIndex`, `lib/data/tool_index.dart`, searchable by title, purpose and keywords; built-in-only tools hidden for anyone else; general content, tested), then groups its links as Direction, Practice, People, Hard days, then Settings. A new tool gets a `ToolEntry` (its route must exist — tested).

Bottom tabs: **Today** `/home` · **Program** `/program?tab=0..3` (Journey/Schedule/Body/Reference) · **Log** `/log?add=weight|protein|win|note|blood` · **Me** `/profile`.

```
/splash /welcome /sign-up /sign-in /forgot-password /commission
/manifesto /protocols /evidence /library /style /career /weekly-coaching /checkin /plans /review /habits /cockpit(?tab=0..2)
/shutdown /focus /letters /week /people /growth /values /coach /case /growth/area(?id=|template=) /goals /goals/edit /goals/view?id= /note /setback /quarter /profile/edit /daily /learning /experiments /rest /stop /gratitude /models /360 /energy /start /privacy /packs /partner /coach-report /odyssey /crafting /best-self /move /conversations /money /upkeep /stepback /decide /month-review /manual /us /brag /need /day /thought /best-future /kindness /worry /chapters /strengths /board /aar /next-program /promises /stories /year /asks /tools
/ritual-flow/:ritualId /gym /gym/:dayId (push|pull|legs) /month/:m (1–18)
/tool/:id  sigh excited pause still bluf sixq read feynman scan pennebaker anki artifact(?month=) linkedin
```

Flow:
- Sign-up → `/start` (the plan builder). Today redirects to `/start` until the system is commissioned, and so does Delete everything.
  - A new name: finishing the builder commissions the program from today with every built-in reminder off (they switch on what they want under Me).
  - The built-in person (name unchanged): the builder then hands over to `/commission`, five steps: identity, start date, gym days and weight, reminders, hold to sign the manifesto.

## Behaviour worth knowing
- **Program length and the next program** (Emin's decision, 12 Oct 2026):
  - `PersonalSystemState.programDays` (90/180/360/540 = `programLengths`, default 540) and `cycle` (1, 2, …). The provider's `programDays`, `programMonths` (= days/30) and `programQuarters` (= days/90) replace the old constants; `emin_system.dart`'s `programDays`/`programMonths` are only the built-in default. Chosen in the plan builder's goal step (`buildPlan(programLength:)`) and under Me → Settings → Program length (`setProgramLength`).
  - Phases keep their proportions: `phaseMonthAt(day)` maps a program day onto the 18-month phase scale; `phase`, `phaseOfMonth(m)`, `monthsOf(p)`, `phaseDays(p)`, `phaseSpanLabel(p)` ("Months 1–2" or "Days 1–10"), `nextPhaseStart`. The Spine widens columns for short programs and hides phase names too narrow to read (`currentPhaseId`).
  - `programComplete` (past the last day) → Today's first prompt → `/next-program`: summary (`programSummary`: held/counted, goals reached, wins, reps, lessons), letters waiting, what changed, what comes with you, next length → `startNextProgram(days:, changed:, carry:)` writes a `program_cycle` log and restarts `programStart` today with `cycle + 1`. Everything logged stays; can also close early from the length sheet.
  - Month- and quarter-keyed logs created in cycle 2+ carry `cycle` (stamped in `_entry`, kept by `updateLog`); always look them up with `atMonth(l, m)` / `atQuarter(l, q)`, never `number('month') == m`. Streaks run from `journeyStart` across programs; paused days before the current start are ignored.
- **Today** is time-aware: morning, work, evening and Sunday modes, plus a Yesterday/Today switch (the 48-hour edit window). Its Day Dial shows the schedule as lane arcs.
  - Calm by design (choice overload drives people away): dial → fresh start → the mode card (one action now) → check-in → recovery → `_Prompts` (ranked: first goal, growth area, then what is due; only 2 visible, the rest behind "N more for today") → Daily 10 → three priorities.
  - "Your plan" (`_PlanToggle`, done key `today:plan_open`, remembered) collapses goals, growth, the week, meetings, the brief, inputs, body and coach note into one summary line.
- **Daily items** (`/daily`, Today's "Edit"): `dailyItems` = built-in `nonNegotiables` not retired (done key `daily:off:<id>`) + his own `daily_item` logs (ids `d_…`, lane, when; cue via `setCue`). Between `minDailyItems` (3) and `maxDailyItems` (15). `holdTarget` = 70% rounded up (7 of 10); `isHeld(day)`. Score, streak, dial, habit check, if-then plans, the brief (`itemTitles`, `itemCount`, ratio thresholds) and the widget (`total`, `target`) all read the configured list. Always use `system.dailyItems`, never `nonNegotiables`, in screens and logic.
- **Daily 10** (his default list): tools tick their item:
  - sigh, bluf, pause, feynman, scan and read are ticked when the tool is used;
  - finishing the ritual ticks the manifesto;
  - protein ticks itself at 150 g.
- **Hard days** (see `docs/HARD_DAYS.md`): Today's "Hard day? Choose how today counts" (`showHardDaySheet`, today or yesterday) writes one `hard_day` log per day (`kind` minimum/sick/pass; `setHardDay(day, null)` clears).
  - Minimum day: `targetFor(day)` = `minimumTarget` (half, rounded up); items show `minimumFor(id)` (`defaultMinimums` in `emin_system.dart`, overrides as cues `min:<id>` via `setMinimum`, edited on `/plans`; `DailyIdea.minimum` and plan packs carry them).
  - Long illness: every day of a run of `pauseAfterSickDays` (7)+ sick days is paused (`isPaused`, `pausedDays`). `programDayOf(date)` = calendar days minus paused days before it; `dateForProgramDay(n)` skips them, and `monthStart`, `quarterStart` and `programEnd` use it. Never compute program dates as `programStart + n days`; use these. Me shows "paused N d" next to the end date.
  - Sick day and emergency skip (`passesPerMonth` per program month, set per person 0–`maxPassesPerMonth` (6) under Me → Emergency skips and stored as `PersonalSystemState.skipsPerMonth`, default 2; `passesLeft`) are `isExcused`, like planned rest: neutral in the streak and `isRecoveryDay`, excluded from `itemRates`.
  - `isReentryDay` (after a sick day or 2+ excused days) makes the day a minimum day automatically; Today shows `_HardDayCard` ("Welcome back"). `sickDaysInRow` ≥ 3 adds "see a doctor if it isn't getting better" — no other medical advice.
  - `isHeld` uses `targetFor`; hard days and rest ranges are indexed once per state (`_reindex`) because the streak checks every day. The brief gets `hardDays` (by kind).
- **Recovery planning** (`/rest`): `rest` logs (kind day/light/holiday from `restKinds`, `from`, `to`, note). `isRestDay` (day or holiday, not a lighter week) is neutral in the streak and suppresses the recovery card; Today shows `_RestCard` with a detachment question (`detach` log, 1–3). `restPlannedSoon` (next 8 weeks) → the brief suggests planning rest if false.
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
  - Cards are `seedCards` (key facts, thesis, protocols, RA rules — only while `isBuiltInPerson`), one card per Feynman note, rep lesson (`lesson:`), applied learning principle (`principle:`) and value meaning (`value:`), and custom cards.
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
- **Goals** (`/goals`, `/goals/edit?id=|title=`, `/goals/view?id=`): the 6–18-month outcomes everything serves. At most `maxActiveGoals` (3) active.
  - A `goal` log: text = the wish; `why`, `obstacle`, `plan` (WOOP), `identity`, `deadline`, `areas` (growth area ids), `status` (active/achieved/dropped, `closed_on`).
  - Measured by a number (`unit`, `start`, `target`; lower-is-better works) with `goal_value` logs, or by `milestones` (`{text, done}`; ticks survive edits).
  - `goalProgress` 0–1, `goalExpected` (straight line from start to deadline), `goalPace` (ahead/on track/behind, ±10 points). `goalsToMeasure` = numeric goals unmeasured for 14+ days (Today prompt).
  - Closing a goal (achieved or dropped) asks to look back: `reflectOnGoal(id, whatWorked:, advice:)` stores `reflection`/`advice` on the goal; an achieved one also logs a win and becomes a `goal:` review card. `goalsToReflect` (closed in the last 14 days, no reflection) prompts on Today.
  - Today's Goals card sits above the growth card; the profile suggests "Become <targetRole>"; `goalSummaries()` feed the brief.
- **Progress note** (`/note`): `progressNoteText(week, to:, ask:)` from goals, the Big 3, the growth area's reps and lesson, and wins; editable; "Copy and mark sent" writes a `progress_note` log (ONO never sends anything). Defaults to the profile's primary person. `noteDue` (Fri–Sun, something to report, not sent) prompts on Today; the brief gets `noteSent`.
- **Setback protocol** (`/setback`): kindness, facts, smallest next step → `setback` log; the next step fills today's first empty priority. Offered on the recovery card and Me; the brief counts `setbacksInWeek`.
- **Learning** (`/learning`): `learning` logs (title, kind from `learningKinds`, by, status queue → active → done). Finishing = `applyLearning` (one principle in his words + one experiment). `experimentsToReview` (done, no result after 7 days) prompts on Today; `recordExperimentResult`. The plan's book of the month can be added in one tap; the brief gets `learningApplied`.
- **Small tools** (`lib/screens/small_tools_screens.dart`, linked from Me → Growth):
  - Stop doing (`/stop`): `stop` logs (what, `room` it makes); weekly held/slipped via done keys `stop:<id>:<weekKey>:held|slipped`; `retireStop`.
  - Gratitude letter (`/gratitude`): `gratitude` logs (to, text, written → delivered with reaction); saving copies the text.
  - Role models (`/models`): `role_model` logs (name, what to learn, one question, the answer once asked).
- **Plan builder** (`/start`, Me → Build your plan; Today prompts it in the first 14 days while there is no plan or goal): five steps — who you are becoming (name, now, target), life wheel (8 areas → a `wheel` log; `latestWheel` reads the newest of `wheel` and `quarterly_review`), this month's area (templates for the two lowest areas first; a template becomes a custom area), one goal (WOOP, 3/6/12 months), and 3–7 daily items from `dailyLibrary` (`lib/data/daily_library.dart`, general, each with a cue). `buildPlan` applies it all; a new name starts a blank profile, and `replaceDaily` retires the current list. Done key `plan:built`. It is the first-run flow (see Flow); `showBack` is off until commissioned.
- **Plan packs** (`/packs`, Me → Plan packs, and from step 1 of the plan builder): `PlanPack` (`lib/data/plan_packs.dart`, general): name, for whom, growth areas with drills, a `PackGoal` shape (title, obstacle, plan, months — no numbers), daily items with cues, stops. Twelve built-in `planPacks` (new people manager, first half marathon, calmer parent, money reset, learn a language, sleep reset, founder's first year, exam season, new parent, back from burnout, career change, athlete's season). `applyPack(pack, replaceDaily:, withGoal:)` adds what isn't there yet (areas by name, items by title, goal if room) and returns counts. `myPack()` = own custom areas, the daily list with cues, the first goal's shape and the stop list — never the profile, people or logs; `toText()`/`PlanPack.fromText()` travel as a pasted message ("ONO plan: <name>" + JSON).
- **Accountability partner** (`/partner`, Me; Today prompts from the check-in weekday): one active `partner` log (name, `mine`, `theirs` commitments, optional `stake` if one misses — a commitment device, `weekday`, status; hidden from the Log tab). Weekly `partner_checkin` log dated `weekStartOf` (`mine`/`theirs` from `checkinAnswers` kept/partly/missed, note). `partnerUpdateText` (held days, hard days, Big 3, their turn) is copied, never sent; `partnerRecord()` over the last 4 → the brief (`accountability_partner`). `endPartnership` keeps the history.
- **Coach mode** (`/coach-report`, Me → Report for your coach): `coachReportText(from, to, mornings:)` for this month or quarter — goals and pace, daily plan held (excused days excluded) with hard days, weakest/strongest item, growth ratings, reps, lessons and feedback, experiments, wins and setbacks, optional energy and sleep. Never notes, letters or journal entries. Copied, never sent.
- **Month review for anyone** (`/month-review`; Today prompts from day 27 and in the first 5 days of the next month — the built-in person is sent to `/month/:m` instead; Program's month section links it for anyone else): `monthToReview`, `monthReviewDue`, `monthHeld(month)` (held of counted days, excused left out, hard days by kind), growth area end rating (`rateFocusEnd(rating, month:)`), wins, goals, one lesson → `saveMonthReview` writes the `month_review` log (`lesson` in data).
- **Your day** (`/day`, Me → Settings, Today prompts from day 2 for anyone but the built-in person): one `day_shape` log (`wake`, `work_start`, `work_end`, `bed` in minutes; equal work times = no fixed hours). `personalSchedule` (morning, work, evening or a day block, wind down, sleep) draws the Day Dial; `personalBlockAt` labels the dial centre; `activeReminderDefs` times the general reminders from it (check-in wake+30, items mid-work, shutdown bed−90). The Gym days setting is the built-in person's only.
- **What do you need right now?** (`/need`, a link under Today's priorities): sixteen moments (stressed, too close, deciding, hard conversation, a thought, worrying, slipped, hard day, circling problem, can't focus, closeness, something big just happened, an interview or review coming, self-doubt, direction, hope) each mapped to one tool. `NeedScreen.routes` are resolved by the smoke test.
- **Inner tools** (`lib/screens/inner_tools_screens.dart`; research section I):
  - Thought check (`/thought`, Me → Hard days, Need: "a thought keeps getting to me"): `logThought` → `thought` log (text = the thought; situation, feeling from `thoughtFeelings`, `before`/`after` 0–100, `for`, `against`, `balanced`). `thoughtRelief` = average drop over 30 days (2+ checks); `thoughtsInWeek` → the brief (count only). Log → Notes.
  - Best possible future (`/best-future`, Me → Direction, Need: "I need some hope"): `saveBestFuture(years:, areas:, step:)` → a `best_future` log per writing (`bestFutureAreas` work/people/body/self); `bestFuture` = latest.
  - Kindness day (`/kindness`, Me → People): `setKindnessDay(weekday)` (one `kindness_plan` log), `logKindness` → `kindness` logs (Log → People); `kindnessDue(day)` (the day, under `kindnessPerDay` 5) prompts on Today; `kindnessInWeek` → the brief.
  - Worry time (`/worry`, Me → Hard days, Need: "I can't stop worrying"): `setWorryTime(minute)` (`worry_plan`), `parkWorry` → `worry` log (status parked); `resolveWorry(id, outcome:)` from `worryOutcomes` (acted puts the step in today's first empty priority, let_go, keep); `worryTimeDue(now)` prompts on Today.
  - Life chapters (`/chapters`, Me → Direction): one `life_story` log edited in place (`chapters` {title, years, high, low, taught}, `now`, `next`); `lifeChapters`.
  - Thoughts, worries, best future and chapters are hidden from the Log tab (thoughts show under Notes) and never sent to the coach; `journalText` includes thoughts, kindness, best future and chapters.
- **Strengths, board, after-action review** (`lib/screens/strengths_board_screens.dart`; research section J):
  - Signature strengths (`/strengths`, Me → Direction): `characterStrengths` (the 24 VIA names with plain descriptions); `setSignatureStrengths` (one `strengths` log, at most `maxSignatureStrengths` 5); `strengthOfTheWeek` rotates weekly; `logStrengthUse` → `strength_use` logs (Log → Growth); the brief gets `signature_strengths` and `strength_uses_this_week` and nudges a new use when there was none.
  - Personal board (`/board`, Me → People): `boardRoles` (mentor, sponsor, peer, challenger, supporter, connector) stored as `board` on `person` logs (`setBoardRoles`, `boardRolesOf`, `board`); `boardGaps` (empty until someone is on it) → Me and the brief (`personal_board_gaps`; a missing sponsor gets a line).
  - After-action review (`/aar`, Me → Practice, Need: "something big just happened"): `logAar` → `aar` log (intended, happened, why, sustain, improve, went_well; Log → Growth); `improve` becomes an `aar:` review card; journal includes it.
- **Promises and story bank** (`lib/screens/word_screens.dart`; research section K):
  - Promises (`/promises`, Me → People): `addPromise(what:, to:, by:)` → `promise` log (status open); `openPromises`, `promisesDue(day)` (Today prompt); `closePromise(id, outcome)` from `promiseOutcomes` (kept, renegotiated = new date a week on, still open — refused once `promiseOverdue`; missed). `sayDo()` = kept/missed of closed in 90 days (3+). The brief gets `promises_kept_90_days` and `promises_overdue` (counts only). Log → People.
  - Story bank (`/stories`, Me → Direction, Need: "an interview or review coming"): `saveStory(id:, title:, situation:, task:, action:, result:, skills:, from:)` → `story` log; `storySkills` (10), `skillsOf`, `storyGaps`, `storyIdeas` (wins and after-action reviews of 180 days not yet a story), `storiesText(skill:)` to copy. The editor is `StoryEditScreen` (pushed). Log → Growth; journal includes it.
- **Year in review** (`/year`, Me → Direction; Today prompts from 15 Dec to 15 Jan while `yearReviewDue`): `yearToReview` (a calendar year ONO was used in), `yearSummary(year)` (held of counted days, wins and the wins in order, goals reached, reps, deep-work hours, kind acts, promises kept, lessons from month and quarter reviews), `yearQuestions` (proud, hard, learned, thanks, let go, what must hold) → `saveYearReview(year, answers:, word:)` → one `year_review` log per year (text = the word for next year; hidden from the Log tab, in the journal). `wordForTheYear` (last year's word) shows on Me and goes to the brief.
- **Ask for help** (`/asks`, Me → People, Need: "I need help but don't want to ask"): `addAsk(what:, of:, guess:)` → `ask` log (guess 0–100 of a yes, status asked); `asksToClose` (2+ days, no answer) prompts on Today; `closeAsk(id, outcome)` from `askOutcomes` (yes/partly/no); `askRecord()` (answered in 180 days, partly counts as yes, average guess; 3+). The brief gets `asks_for_help_this_week` and the record (counts only); the device brief nudges one ask when there was none. Log → People.
- **Brag document** (`/brag`, Me → Direction): `bragText(since:)` — goals reached (with how), wins by month, feedback-round themes and best-self portrait, people helped grow, learning applied; 3 months / 6 months / all; copied.
- **Question of the day** (anyone but the built-in person, in Today's plan section instead of the coach note): `questionOfTheDay` rotates `dailyQuestions` (`general_program.dart`, 21 across life areas) by program day; `answerQuestion` saves or updates one `note` per day with `question` in data.
- **How to work with me** (`/manual`, Me → People): one `manual` log; `manualSections` (best, values, energy, communication, feedback, watch); `manualSection(key)` = saved text or a draft from best-self portrait, values and energy peak; "Save and copy" → `manualText()`.
- **A check-in for two** (`/us`, Me → People): weekly `us_checkin` log dated `weekStartOf` (`with`, answers to `usQuestions`: appreciate, hard, need, plan); `usStreak` counts weeks in a row. Private (not in the Log tab).
- **Step back** (`/stepback`, Me → Hard days; the general work-mode tools): self-distanced reflection by first name (Kross et al. 2014) → `stepback` log (what, feeling, advice, `year` 0–2 how much it matters in a year). Notes filter.
- **Decide with your values** (`/decide`, Me → Hard days): options (2–4) scored −1/0/+1 against their values (or general criteria if none set), 10/10/10, premortem → `addValuesDecision` writes a normal `decision` log (reviewed after 90 days like career decisions).
- **Health upkeep** (`/upkeep`, Me → Body): `upkeep` logs (name, `every` days, `last` done) — the person sets intervals; ONO gives no medical advice. `upkeepSuggestions` (dentist, general check-up, blood tests, eye test) add in one tap. `upkeepNextDue`, `upkeepDue` (within 14 days, overdue first; never-done count as due); Today prompts the first one that has a date. Hidden from the Log tab.
- **Money check-in** (`/money`, Me → Direction): one `money_check` log per program month (`income`, `spent`, optional `savings`, `decision`, `worry`). `savingsRate`, `bufferMonths`, `moneySummary`. `moneyCheckDue` from day 25 once they've opened it (`money:on`) or done one; the brief gets only the savings rate and buffer (`money`), and the privacy screen says so. Hidden from the Log tab.
- **Hard conversations** (`/conversations`, Me → People; Today prompts on the day): `conversation` logs (text = about; `with`, `want_me`/`want_them`/`want_us`, `facts`, `my_story`, `their_story`, `opening`, `ask`, `by`, status planned → done with `outcome` from `conversationOutcomes` and `learned`). `saveConversation`, `debriefConversation`, `plannedConversations`, `conversationsDue(day)`. Private: hidden from the Log tab, never sent to the coach. The editor is `ConversationEditScreen` (pushed, not routed).
- **Movement** (`/move`, Me → Body's "N min moved"): `move` logs (`kind` from `moveKinds`, `minutes`, `vigorous`). `moveMinutesInWeek` = moderate-equivalent minutes (vigorous ×2) vs `weeklyMoveTarget` 150; `strengthDaysInWeek` counts strength moves and gym sessions vs 2 (WHO 2020). Shows under Log → Body; the brief gets both (minutes only once they log movement).
- **Direction tools** (`lib/screens/direction_screens.dart`, Me → Growth):
  - Odyssey plan (`/odyssey`): one `odyssey` log, edited in place: three lives (`odysseyPrompts`: the path you're on, if it disappeared, if money and opinion didn't matter), each with title, story and 1–5 `odysseyGauges` (resources, like, confidence, coherence); `leaning` index and a `prototype`. "Make it a goal" opens `/goals/edit?title=`. `odysseyLeaning` → the brief (`five_year_direction`).
  - What gives and drains you (`/crafting`, job crafting): one `energy_audit` log per program quarter (activities with energy −2…2, one `craft` activity with a `move` from `craftMoves` more/less/reshape and `how`). `craftingMove` → Me and the brief.
  - You, at your best (`/best-self`, reflected best self): one `best_self` log (stories `{from, story}`, themes, portrait). `bestSelfAsk` is copied; `bestSelfPortrait` shows on the setback screen.
  - All three are hidden from the Log tab.
- **Your data** (`/privacy`, Me → Your data & privacy): plain-words account of where data lives (`syncsToCloud` from the gateway), calendar (memory only), health, what the weekly coach receives (`coachIsRemote`; notes, letters and journal entries are never sent), and that ONO never messages anyone. `dataSummary` counts; Export everything; Export your journal (`journalText()`: wins, practice lessons, notes, reviews, setbacks, step-backs, conversations, feedback, applied learning, opened letters, gratitude — readable text by date, no body numbers); Delete everything (type DELETE) → `eraseEverything()` = `PersonalSystemGateway.erase` (the synced gateway deletes the cloud row first, so a failed delete leaves the data), cancels every reminder and one-off notification, reloads a fresh state and goes to `/commission`. Any new gateway must implement `erase` and `syncsToCloud`; any new data sent to the coach must be described on this screen.
- **Feedback round** (`/360`): one `feedback_round` log per program quarter: the question (default `defaultRoundQuestion`), up to 3 people, `answers` ({from, said}, one per person), `themes`. `roundDue` from day 45 of a quarter; starting copies the ask; themes go into `caseText()` as "What others say".
- **Energy map** (`/energy`): `energy` logs (level 1–5, hour) from "energy right now", plus `sharp` 1–5 on `focus` logs (rated after a block, counted at its start hour). `energyMap` averages the last 60 days per `energyBands` (early, morning, midday, afternoon, evening); `energyPeak` needs `minEnergySamples` (3) in two bands and a 0.3 lead. `energyByWeekday` uses check-in energy. The peak shows on `/focus` and goes into the brief (`energy_peak`), as does the latest feedback-round theme.
- **Experiments** (`/experiments`, linked under Me → What moves your day): `experiment` logs (change as text, `measure` from `experimentMeasures` = score/energy/sleep/mood, `days` 7/14/21, `expect`, `start`, status running/kept/dropped, `result`). `experimentCompare` = the measure's average for the same number of days before vs during (score excludes today). `experimentsToClose` prompts on Today; ideas come from `patterns()`; the brief gets running and kept ones.
- **Quarterly review** (`/quarter`): ends with "Go deeper this quarter" — the feedback round, energy audit, Odyssey plan (if older than ~80 days) and best self, whichever aren't done yet. `programQuarter` = 90-day blocks (1–6). `quarterReviewDue` from the last 7 days of a quarter to the first 7 of the next (`quarterToReview`). A `quarterly_review` log per quarter: life wheel (`lifeAreas` in `lib/data/life_wheel.dart`, 8 general areas rated 1–10, each mapped to a growth template), wins, lessons, goal decisions (keep/achieved/drop applied to goals), next focus. `lowestLifeArea` suggests a growth area and goes to the brief.
- **Growth plan** (`/growth`), the main development thread:
  - `growthAreas` in `emin_system.dart`: the 5 Head of Product readiness dimensions plus 3 personal areas from his diagnosis (self-trust, composure under pressure, public voice). Each has a `bar`, a feedback `ask` and 5 `Drill`s (how + signal) tied to his real job.
  - One `growth_focus` log per program month (`area`, `start`, `end` ratings 1–5). `setFocus`/`rateFocusEnd`/`focusRatings`; `suggestedArea` = the readiness gap.
  - `drillFor` suggests this week's drill (not yet practised this month, rotating by week). `logRep` saves a Kolb reflection (did, noticed, lesson, next) as a `rep` log; `logFeedback` saves a `feedback` log.
  - Configurable: `customAreas` (`growth_area` logs, ids `c_…`) from scratch or from `areaTemplates` (`lib/data/growth_templates.dart`: 14 general areas for anyone — strength, health, relationships, parenting, money, calm, learning, speaking, team leading, meaning, sleep, friendship, changing careers, building a business). `saveCustomArea`/`removeCustomArea` (not this month's area). `addDrill` adds to a custom area or, for a profile area, to `area_drills`; always read drills via `drillsOf(area)` and areas via `areaById`/`allGrowthAreas`. Editor: `/growth/area?id=|template=`.
  - Levels: `levelsOf(area)` = the area's own 5 `levels` (editable for custom areas) or a general ladder (aware → practising → consistent → at the bar [= `area.bar`] → role model). Shown under every 1–5 rating (growth start/end, readiness).
  - Today's growth card sits above the prompts; Log has a Growth filter; the brief leads with growth focus, reps this week and feedback this month.
- **Values** (`/values`): one `values` log (3–5 `{name, meaning}` from `valueOptions`, edited in place, hidden from the Log tab). The values affirmation writes an `affirmation` log (value, text, before what). A weekly `values_check` (ratings 1–5, dated `weekStartOf`); `valueGap` = lowest below 4 → the brief. Today prompts the check on Sundays.
- **Self-coaching** (`/coach`, GROW): `coaching` logs (goal as text; reality, options, will, `by`, commitment 1–10). `commitmentsDue(day)` until kept (`coach:<id>`) or dropped (`coach:<id>:dropped`); Today prompts the first; the brief gets open ones.
- **Head of Product case** (`/case`, linked from Career): `caseFor(area)` = readiness rating, reps and feedback per professional area; `caseText()` adds shipped/in-review artifacts, decisions reviewed right, evidence "built" items, wins and the readiness gap, for copying.
- **Big 3** (`/week`): one `week_plan` log per week (dated `weekStartOf`) holding `outcomes` (3), `done` indexes and `goals` (the goal id each serves; `setWeekOutcomeGoal`/`weekOutcomeGoal`/`weekOutcomesFor`, chips under each outcome on `/week`). `goalNextStep(goal)` = first open milestone, else an open outcome serving it, else its if-then plan — shown on Today's goal tiles with how many of the week's three serve it; the brief marks outcomes "(for: goal)". `setWeekOutcome`/`toggleWeekOutcome`/`weekOutcomeScore`. Today shows them tickable (or a prompt to set them); from Saturday `/week` also plans next week; the Sunday report reviews them and the brief gets them as `[done]`/`[open]`.
- **People** (`/people`): `person` logs (name, `role`, `every` days); `touch` logs record contact. `lastContact` also counts `one_on_one` logs whose `with` matches the first name as a whole word. `peopleDue` (past cadence, most overdue first) prompts on Today and goes into the brief. People never show in the Log tab; `removePerson` also drops their touches.
  - Helping them grow: `setGrowing(person, workingOn:, nextHelp:)` on the person; `logHelp` writes a `help` log (and clears the next help once done); `peopleGrowing`, `helpsInMonth`. People shows "Growing: …"; the brief gets `people_they_are_growing` and nudges when someone got no help this month. `removePerson` also drops their help logs.
  - Rituals and presence: `setRitual`/`ritualOf` (e.g. "Friday dinner, phones away", on the person); `logTouch(quality: 1–3)` (distracted/okay/fully present); `presenceOf` = average of the last 4 rated touches. Today's "Reach out" names the ritual.
- The shutdown's good things (one to three, one per line, plus why the first happened — "three good things", Seligman 2005) are each saved as a `win` (once per text per day; the first carries `why`).
- **Patterns** (`patterns()` → `DayPattern`, Me → "What moves your day"): compares an outcome on days with vs without a habit over the last 60 closed days. Needs `minDays` (5) on each side and a minimum gap; shown as patterns, not proof. The top three go into the Sunday brief (`BriefInput.patterns`).
- **Sunday report** → `submitReport` → `BriefGenerator`:
  - `DeviceBriefGenerator` is rule-based and uses real data only.
  - `RemoteBriefGenerator` calls Claude via `supabase/functions/weekly-brief` and falls back to the device generator on any error.
- **Reminders**: `plannedReminders()` builds weekly notifications from `activeReminderDefs` with today's content — `reminderDefs` (the built-in schedule) for the built-in person, `generalReminderDefs` (`lib/data/general_program.dart`: morning check-in 07:30, daily items 12:30, shutdown 21:00, Sunday report 18:00) for anyone else. `LocalReminderService` schedules them (flutter_local_notifications); tapping one opens its route. Web uses `NoopReminderService`.

## Sync between devices
- `SyncedPersonalSystemGateway(PersonalSystemCloud, device:)` (`lib/gateways/supabase_personal_system_gateway.dart`; `SupabaseCloud` in the app, `test/support/fake_cloud.dart` in tests): saves on the device at once; `sync(userId, state)` merges with the cloud row three ways against the last copy this device agreed on (`personal_system_base_<uid>` + version in prefs) and writes only over the version it merged with (`version` column, retried on a lost race).
- `mergeStateJson` (`lib/models/state_merge.dart`, `test/state_merge_test.dart`): logs, evidence, reports, briefs and custom cards merge by `id`; done keys and each day's checks as sets; priorities, cues, reminders and card schedules key by key; other fields as single values. A change on one side wins; on a clash this device wins; a deletion survives unless the other side edited the item.
- The provider syncs on load (8 s timeout, so a new device gets the program before Today decides on the plan builder), 3 s after the last change, every 60 s and on resume (`AppLifecycleListener` in `app.dart`). Edits made while a sync is out are merged in (`syncNow`, `test/providers/sync_test.dart`). Any new state field needs a rule in `mergeStateJson` if a single value is wrong for it.
- First sign-in on a device that ran the offline build adopts its data (`personal_system_mock-user-001`). A missing row, or a row whose `generation` (uuid, new on every insert) differs from the one this device remembered, means Delete everything ran elsewhere: the device starts over (and takes a new program if one was built since).
- `test/providers/two_devices_test.dart` runs two devices (`device:` namespaces their keys) against the in-memory cloud: first load, edits and ticks on both, deletions vs edits, a lost race, offline, a blank device, Delete everything (and a new program after it), the offline build's data, a setting change. New ids (`_uid`: time, counter and a random part) never collide between devices.
- Safety rules: a device whose state isn't commissioned never merges over a commissioned cloud copy — it takes it; `syncNow` is single-flight (a request while one is out sets `_syncAgain` and runs after it with the state as it is then); load waits up to 8 s, and a slower first sync is still merged in when it lands.
- Sign-up returns "Check your email…" when the project requires confirmation. Google/Apple buttons hide unless `AuthGateway.offersSocialSignIn` (false for Supabase until client IDs exist).

## Supabase (project `kkgkbfxvovrtmnoezcha`)
Live: `personal_system` (+ `version`, `generation`) with owner-only RLS, legacy functions locked (`20261012121000`), `weekly-brief` deployed. The brief uses the device generator until the `ANTHROPIC_API_KEY` secret is set. To redo it from scratch:
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
  - `test/performance_test.dart` loads 500 days of history and fails if the streak, patterns, journal or merge get slow, or Today/Me/Log/Program/Growth/Review take too long to build. Per-day lookups go through `_logsByDay` (rebuilt only when the state changes); `patterns()` is cached per state and day.
  - `test/large_text_test.dart` opens every route on an iPhone SE with text at 130% and fails on any overflow (buttons ellipsize their label; the welcome screen scrolls).
  - `test/flows_test.dart` taps through the newer tools as a person would (thought check, worry time, kindness, strengths, board, after-action review, best future, chapters, closing a program) and checks what was saved.
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

### Web (GitHub Pages)
- `.github/workflows/web.yml` builds `flutter build web -t lib/main_production.dart --base-href /ono_flutter/` on every push to `main` and deploys to https://eminhuseyn313.github.io/ono_flutter/ (needs a public repo and Settings → Pages → Source: GitHub Actions).
- The web app and the iPhone (`Install on my iPhone.command` builds `main_production.dart`) sign in to the same Supabase account and share one program (see Sync). No reminders, Health, calendar or widget on the web.
- `PhoneFrame` (`lib/app.dart`) keeps a 480 px column on wide windows and sets `MediaQuery.size` to it (`test/phone_frame_test.dart`).
- The site and the repo are public: the bundle contains the built-in profile (`emin_system.dart`). Logged data is never in the bundle; it lives on the device and in his RLS-protected row.

## Not built (needs Xcode / native targets)
The native parts can't be compiled here:
- The widget's Swift code and the HealthKit/App Group signing are unverified until built on the Mac.
- Live Activities and on-device encryption of health fields are not built yet. The calendar plugin (EventKit) is unverified until built on the Mac.
- The project edits themselves are tested here with the xcodeproj gem. Row-level security protects the cloud copy.

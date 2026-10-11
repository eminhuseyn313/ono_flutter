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

Me groups its links as Direction, Practice, People, Hard days, then Settings.

Bottom tabs: **Today** `/home` · **Program** `/program?tab=0..3` (Journey/Schedule/Body/Reference) · **Log** `/log?add=weight|protein|win|note|blood` · **Me** `/profile`.

```
/splash /welcome /sign-up /sign-in /forgot-password /commission
/manifesto /protocols /evidence /library /style /career /weekly-coaching /checkin /plans /review /habits /cockpit(?tab=0..2)
/shutdown /focus /letters /week /people /growth /values /coach /case /growth/area(?id=|template=) /goals /goals/edit /goals/view?id= /note /setback /quarter /profile/edit /daily /learning /experiments /rest /stop /gratitude /models /360 /energy /start /privacy /packs /partner /coach-report /odyssey /crafting /best-self /move
/ritual-flow/:ritualId /gym /gym/:dayId (push|pull|legs) /month/:m (1–18)
/tool/:id  sigh excited pause still bluf sixq read feynman scan pennebaker anki artifact(?month=) linkedin
```

Flow:
- Sign-up → `/start` (the plan builder). Today redirects to `/start` until the system is commissioned, and so does Delete everything.
  - A new name: finishing the builder commissions the program from today with every built-in reminder off (they switch on what they want under Me).
  - The built-in person (name unchanged): the builder then hands over to `/commission`, five steps: identity, start date, gym days and weight, reminders, hold to sign the manifesto.

## Behaviour worth knowing
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
  - Today's Goals card sits above the growth card; the profile suggests "Become <targetRole>"; `goalSummaries()` feed the brief.
- **Progress note** (`/note`): `progressNoteText(week, to:, ask:)` from goals, the Big 3, the growth area's reps and lesson, and wins; editable; "Copy and mark sent" writes a `progress_note` log (ONO never sends anything). Defaults to the profile's primary person. `noteDue` (Fri–Sun, something to report, not sent) prompts on Today; the brief gets `noteSent`.
- **Setback protocol** (`/setback`): kindness, facts, smallest next step → `setback` log; the next step fills today's first empty priority. Offered on the recovery card and Me; the brief counts `setbacksInWeek`.
- **Learning** (`/learning`): `learning` logs (title, kind from `learningKinds`, by, status queue → active → done). Finishing = `applyLearning` (one principle in his words + one experiment). `experimentsToReview` (done, no result after 7 days) prompts on Today; `recordExperimentResult`. The plan's book of the month can be added in one tap; the brief gets `learningApplied`.
- **Small tools** (`lib/screens/small_tools_screens.dart`, linked from Me → Growth):
  - Stop doing (`/stop`): `stop` logs (what, `room` it makes); weekly held/slipped via done keys `stop:<id>:<weekKey>:held|slipped`; `retireStop`.
  - Gratitude letter (`/gratitude`): `gratitude` logs (to, text, written → delivered with reaction); saving copies the text.
  - Role models (`/models`): `role_model` logs (name, what to learn, one question, the answer once asked).
- **Plan builder** (`/start`, Me → Build your plan; Today prompts it in the first 14 days while there is no plan or goal): five steps — who you are becoming (name, now, target), life wheel (8 areas → a `wheel` log; `latestWheel` reads the newest of `wheel` and `quarterly_review`), this month's area (templates for the two lowest areas first; a template becomes a custom area), one goal (WOOP, 3/6/12 months), and 3–7 daily items from `dailyLibrary` (`lib/data/daily_library.dart`, general, each with a cue). `buildPlan` applies it all; a new name starts a blank profile, and `replaceDaily` retires the current list. Done key `plan:built`. It is the first-run flow (see Flow); `showBack` is off until commissioned.
- **Plan packs** (`/packs`, Me → Plan packs, and from step 1 of the plan builder): `PlanPack` (`lib/data/plan_packs.dart`, general): name, for whom, growth areas with drills, a `PackGoal` shape (title, obstacle, plan, months — no numbers), daily items with cues, stops. Five built-in `planPacks` (new people manager, first half marathon, calmer parent, money reset, learn a language). `applyPack(pack, replaceDaily:, withGoal:)` adds what isn't there yet (areas by name, items by title, goal if room) and returns counts. `myPack()` = own custom areas, the daily list with cues, the first goal's shape and the stop list — never the profile, people or logs; `toText()`/`PlanPack.fromText()` travel as a pasted message ("ONO plan: <name>" + JSON).
- **Accountability partner** (`/partner`, Me; Today prompts from the check-in weekday): one active `partner` log (name, `mine`, `theirs` commitments, `weekday`, status; hidden from the Log tab). Weekly `partner_checkin` log dated `weekStartOf` (`mine`/`theirs` from `checkinAnswers` kept/partly/missed, note). `partnerUpdateText` (held days, hard days, Big 3, their turn) is copied, never sent; `partnerRecord()` over the last 4 → the brief (`accountability_partner`). `endPartnership` keeps the history.
- **Coach mode** (`/coach-report`, Me → Report for your coach): `coachReportText(from, to, mornings:)` for this month or quarter — goals and pace, daily plan held (excused days excluded) with hard days, weakest/strongest item, growth ratings, reps, lessons and feedback, experiments, wins and setbacks, optional energy and sleep. Never notes, letters or journal entries. Copied, never sent.
- **Movement** (`/move`, Me → Body's "N min moved"): `move` logs (`kind` from `moveKinds`, `minutes`, `vigorous`). `moveMinutesInWeek` = moderate-equivalent minutes (vigorous ×2) vs `weeklyMoveTarget` 150; `strengthDaysInWeek` counts strength moves and gym sessions vs 2 (WHO 2020). Shows under Log → Body; the brief gets both (minutes only once they log movement).
- **Direction tools** (`lib/screens/direction_screens.dart`, Me → Growth):
  - Odyssey plan (`/odyssey`): one `odyssey` log, edited in place: three lives (`odysseyPrompts`: the path you're on, if it disappeared, if money and opinion didn't matter), each with title, story and 1–5 `odysseyGauges` (resources, like, confidence, coherence); `leaning` index and a `prototype`. "Make it a goal" opens `/goals/edit?title=`. `odysseyLeaning` → the brief (`five_year_direction`).
  - What gives and drains you (`/crafting`, job crafting): one `energy_audit` log per program quarter (activities with energy −2…2, one `craft` activity with a `move` from `craftMoves` more/less/reshape and `how`). `craftingMove` → Me and the brief.
  - You, at your best (`/best-self`, reflected best self): one `best_self` log (stories `{from, story}`, themes, portrait). `bestSelfAsk` is copied; `bestSelfPortrait` shows on the setback screen.
  - All three are hidden from the Log tab.
- **Your data** (`/privacy`, Me → Your data & privacy): plain-words account of where data lives (`syncsToCloud` from the gateway), calendar (memory only), health, what the weekly coach receives (`coachIsRemote`; notes, letters and journal entries are never sent), and that ONO never messages anyone. `dataSummary` counts; Export everything; Delete everything (type DELETE) → `eraseEverything()` = `PersonalSystemGateway.erase` (the synced gateway deletes the cloud row first, so a failed delete leaves the data), cancels every reminder and one-off notification, reloads a fresh state and goes to `/commission`. Any new gateway must implement `erase` and `syncsToCloud`; any new data sent to the coach must be described on this screen.
- **Feedback round** (`/360`): one `feedback_round` log per program quarter: the question (default `defaultRoundQuestion`), up to 3 people, `answers` ({from, said}, one per person), `themes`. `roundDue` from day 45 of a quarter; starting copies the ask; themes go into `caseText()` as "What others say".
- **Energy map** (`/energy`): `energy` logs (level 1–5, hour) from "energy right now", plus `sharp` 1–5 on `focus` logs (rated after a block, counted at its start hour). `energyMap` averages the last 60 days per `energyBands` (early, morning, midday, afternoon, evening); `energyPeak` needs `minEnergySamples` (3) in two bands and a 0.3 lead. `energyByWeekday` uses check-in energy. The peak shows on `/focus` and goes into the brief (`energy_peak`), as does the latest feedback-round theme.
- **Experiments** (`/experiments`, linked under Me → What moves your day): `experiment` logs (change as text, `measure` from `experimentMeasures` = score/energy/sleep/mood, `days` 7/14/21, `expect`, `start`, status running/kept/dropped, `result`). `experimentCompare` = the measure's average for the same number of days before vs during (score excludes today). `experimentsToClose` prompts on Today; ideas come from `patterns()`; the brief gets running and kept ones.
- **Quarterly review** (`/quarter`): `programQuarter` = 90-day blocks (1–6). `quarterReviewDue` from the last 7 days of a quarter to the first 7 of the next (`quarterToReview`). A `quarterly_review` log per quarter: life wheel (`lifeAreas` in `lib/data/life_wheel.dart`, 8 general areas rated 1–10, each mapped to a growth template), wins, lessons, goal decisions (keep/achieved/drop applied to goals), next focus. `lowestLifeArea` suggests a growth area and goes to the brief.
- **Growth plan** (`/growth`), the main development thread:
  - `growthAreas` in `emin_system.dart`: the 5 Head of Product readiness dimensions plus 3 personal areas from his diagnosis (self-trust, composure under pressure, public voice). Each has a `bar`, a feedback `ask` and 5 `Drill`s (how + signal) tied to his real job.
  - One `growth_focus` log per program month (`area`, `start`, `end` ratings 1–5). `setFocus`/`rateFocusEnd`/`focusRatings`; `suggestedArea` = the readiness gap.
  - `drillFor` suggests this week's drill (not yet practised this month, rotating by week). `logRep` saves a Kolb reflection (did, noticed, lesson, next) as a `rep` log; `logFeedback` saves a `feedback` log.
  - Configurable: `customAreas` (`growth_area` logs, ids `c_…`) from scratch or from `areaTemplates` (`lib/data/growth_templates.dart`: 10 general areas for anyone — strength, health, relationships, parenting, money, calm, learning, speaking, team leading, meaning). `saveCustomArea`/`removeCustomArea` (not this month's area). `addDrill` adds to a custom area or, for a profile area, to `area_drills`; always read drills via `drillsOf(area)` and areas via `areaById`/`allGrowthAreas`. Editor: `/growth/area?id=|template=`.
  - Levels: `levelsOf(area)` = the area's own 5 `levels` (editable for custom areas) or a general ladder (aware → practising → consistent → at the bar [= `area.bar`] → role model). Shown under every 1–5 rating (growth start/end, readiness).
  - Today's growth card sits above the prompts; Log has a Growth filter; the brief leads with growth focus, reps this week and feedback this month.
- **Values** (`/values`): one `values` log (3–5 `{name, meaning}` from `valueOptions`, edited in place, hidden from the Log tab). The values affirmation writes an `affirmation` log (value, text, before what). A weekly `values_check` (ratings 1–5, dated `weekStartOf`); `valueGap` = lowest below 4 → the brief. Today prompts the check on Sundays.
- **Self-coaching** (`/coach`, GROW): `coaching` logs (goal as text; reality, options, will, `by`, commitment 1–10). `commitmentsDue(day)` until kept (`coach:<id>`) or dropped (`coach:<id>:dropped`); Today prompts the first; the brief gets open ones.
- **Head of Product case** (`/case`, linked from Career): `caseFor(area)` = readiness rating, reps and feedback per professional area; `caseText()` adds shipped/in-review artifacts, decisions reviewed right, evidence "built" items, wins and the readiness gap, for copying.
- **Big 3** (`/week`): one `week_plan` log per week (dated `weekStartOf`) holding `outcomes` (3) and `done` indexes. `setWeekOutcome`/`toggleWeekOutcome`/`weekOutcomeScore`. Today shows them tickable (or a prompt to set them); from Saturday `/week` also plans next week; the Sunday report reviews them and the brief gets them as `[done]`/`[open]`.
- **People** (`/people`): `person` logs (name, `role`, `every` days); `touch` logs record contact. `lastContact` also counts `one_on_one` logs whose `with` matches the first name as a whole word. `peopleDue` (past cadence, most overdue first) prompts on Today and goes into the brief. People never show in the Log tab; `removePerson` also drops their touches.
  - Rituals and presence: `setRitual`/`ritualOf` (e.g. "Friday dinner, phones away", on the person); `logTouch(quality: 1–3)` (distracted/okay/fully present); `presenceOf` = average of the last 4 rated touches. Today's "Reach out" names the ritual.
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

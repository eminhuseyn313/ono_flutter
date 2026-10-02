# ONO — critical review (2 Oct 2026)

Four independent reviewers judged the current build. They used 27 screenshots of the real flow at iPhone width, the code, and Emin's full development profile.

- **The owner**: Emin as a daily user over 18 months.
- **Senior product designer**: bar set at Linear, Things, Oura.
- **Behavior-change UX researcher**: habit loops, onboarding, IA.
- **Product strategist**: completeness, data, readiness.

All four reached the same verdict without seeing each other's work:

> **ONO is a well-typeset reference binder of Emin's profile with a checklist attached, sitting on top of ~55 legacy screens that show fabricated data. It is not yet a transformation journey, not a behavior-change product, and not trustworthy.**

What works, in one line: the content is accurate. Plan (day/train/health), protocols, style and career faithfully transcribe the profile, and the manifesto reader is the best screen.

---

## 1. Trust: fake numbers contradict his real data (all 4 reviewers, #1–2 priority)

- **AI Coach** (`mock_ai_coach_gateway.dart`) shows "72 score", "14-day streak", "Body 58→85" and "protect your 12-day streak" on Day 1. Today shows 0/10 and streak 0. It also tells him to "connect with the Brotherhood".
- **Progress** shows a full week of bars, "32%" and "90 days until Version 2.0" next to "0 days active".
- **Timelines conflict**:
  - Blueprint says 30/60/90 days.
  - Role model and journey say 30 days.
  - Progress says 90 days.
  - The program is 18 months.
  - Coach tips loop every 30 days, so Day 31 repeats Day 1.
- **Names conflict**: "The Product Leader" (blueprint) vs "The Product Architect" (everywhere else). Me shows a raw lowercase `executive` chip and gamer achievements ("Monthly Legend").
- **Me settings are dead**: Notifications, Theme and Export only trigger a haptic (`profile_screen.dart:779–806`).
- **Legacy screens run on seeded fiction**: Brotherhood, Social Feed, Power Rankings, Trending, Radio, Wakz, Mirror Match, Council, Ghost Mode, Vault, Forge, etc. The feature grid exposes 55 of them.

**Why it matters:** for a self-honesty tool (impostor syndrome, evidence archive), one fake number makes every number suspect.

## 2. No journey: Month 1→18 is a counter, not an arc

- "Month 1 of 18" is just `programDay ~/ 30`. Nothing unlocks, gates, or changes from Month 1 to Month 2.
- Profile items that should switch on over time stay static:
  - LinkedIn 2/week from Month 2
  - Book per month
  - Skincare steps by month
  - Wardrobe by week
  - PR/FAQ in Month 3
  - Certificates
- There is no month review, no phase map, no "how far I've come".
- **Onboarding ignores what the app already knows.** It runs a generic 6-archetype picker, a 10-question quiz ("What's your fitness level?"), then a 30/60/90 blueprint. It never sets the program start date, schedule or gym days. `setProgramStart` is never called from the UI; Day 1 silently becomes the install date.

## 3. No behavior loop: nothing triggers, responds, or compounds

- **No notifications at all.** There is no plugin in `pubspec.yaml`. A day built on 06:00 / 07:45 / 12:00 / 19:00 / 22:00 / Sunday never prompts him.
- **The Sunday report gets no response.** The profile's core promise is to report 5 things and get back next week's tasks, a domain brief, coaching and plan adjustments. The app only offers "Copy" and "Save".
- **Protocols are text, not tools.** Each gap below is what the app is missing:
  - No guided sigh timer before a meeting.
  - No six-questions prep tied to a meeting with Ali.
  - No BLUF drafter.
  - No Pennebaker 15-min session or 4-Tuesday tracker.
  - No Feynman note tied to the current book.
  - No Anki counter.
  - No monthly-artifact tracker.
  - No LinkedIn post log or 2/week cadence.
- **Logging is binary ticks only.** It is missing:
  - Gym sets and weights (gym is one boolean).
  - Weight log ("83 kg" is hard-coded).
  - Protein grams.
  - Bloodwork values.
  - Sleep.
- **No history.** The Daily 10 only writes to today; there is no yesterday, no heat map, and no week-over-week view. "In bed by 10:30" can only be ticked before he goes to bed.
- **Disconnected flows:**
  - Finishing the morning ritual doesn't tick the Daily 10.
  - Today's training card can't log the session.
- **Not time-aware.** At 19:00 Today still asks "What must be true by 6pm?" and shows the morning manifesto as missed. On Friday (a non-gym day), Train shows Day A.

## 4. UI: competent dark card list, no identity, no visualization

- **Everything is text in bordered rectangles.** Nothing is visualized: no hero, no imagery, no diagrams.
- **Long pages**: Today ~3,000pt, Career ~4,200pt, Style ~3,400pt, Library ~3,200pt of label/value walls.
- **Flat, small type**: body 14pt (iOS default is 17), eyebrows and tags 11pt, every title the same weight.
- **Lane colors conflict between screens**, and Skill = accent cognac (the same color as "now / primary action").
- **Weak progress visuals**: 5pt rings, 4pt bars. An empty ring around "0" looks broken.
- **Two apps stapled together.** New and legacy screens have different:
  - headers
  - back buttons (5 styles)
  - CTA styles (gradient glow vs flat vs ghost)
  - glass/glow cards
  - emoji vs Material icons
- **Contrast fails**: ivory text on cognac CTAs (~2.5:1), disabled buttons (~2:1), faded past rows.
- **Ritual flow is generic**: a 20° sliver ring, grey countdown, a ghost "Done" in the corner, and no end summary.
- **No craft moments**: checking an item does nothing visible; there is no 7/10 or 10/10 moment.

## 5. Completeness & platform gaps

- **Storage risk.** The whole personal system is one SharedPreferences JSON blob, even in production:
  - deleting the app or changing phones loses everything
  - a corrupt blob silently resets
  - no backup, export, or sync
- **No platform integrations:**
  - widgets, Lock Screen, Live Activities
  - Apple Health/Watch (weight, sleep, Zone 2 heart rate)
  - calendar (meetings with Ali)
  - Shortcuts
- **Health data** (thalassemia, RA, bloodwork) is stored in plaintext.

---

## Completeness vs. the profile

| Status | Elements |
|---|---|
| **Actionable** | Manifesto read, Daily 10 ticks, 3 priorities, evidence add/remove, wardrobe ticks, certificate ticks |
| **Minimal (tick only)** | Gym session, bloodwork, books/films, milestones, LinkedIn rewrites, ritual flow (not linked to Daily 10) |
| **Display-only** | Schedule, sigh / "I am excited" / still body / pause, BLUF, six-questions-deep, Feynman, domain scan, podcasts, RA mods, protein, supplements, sleep, style/beard/grooming/skincare |
| **Missing** | Weekly coaching response, Pennebaker sessions, Anki, monthly artifact, LinkedIn cadence, weight/trends, notifications, history, program start date, backup |

---

## Agreed direction

**Positioning:** "ONO — a personal operating system for one ambitious man, coached weekly." Delete or hide the social/gamified shell. Turn Emin's system into a template for other users only later.

**Information architecture (4 tabs):**
- **Today**: time-aware (morning ritual → day protocols → evening close → Sunday report), a date strip for the last 48h, and a hero "Day Dial".
- **Program**: 18-month Spine, plan, gym, health, and the library/reference (the former Playbook).
- **Log**: evidence, notes (Feynman/Pennebaker/BLUF/6Q), gym history, weekly briefs.
- **Me**: real trends, settings, export/backup, start date, notifications.

**Merge:**
- AI Coach → Sunday brief
- Progress, Analytics, Dashboard, Heat Map → one honest Me chart
- Weekly Review → Sunday report
- Blueprint and Role Model → Program header
- Daily Check-in and Planner → Daily 10

**Delete:** Brotherhood, Social Feed, Accountability, Mirror Match, Power Rankings, Trending, Wakz, Community Challenges, Radio, Council, Ghost/Monk/Time Mode, Vault, Vision Board, Forge, Gamification, Achievement Hub, Legacy Score, Becoming Arc, generic onboarding, `/features`.

**Core loop:**

| Time | Trigger (push) | Action | Reward / investment |
|---|---|---|---|
| 06:00 | "Water. Then ritual." | 5-step ritual | Ticks manifesto and sigh; priorities captured |
| 07:45 | "Scan: CIAM Compass" | Source and 15-min timer | One insight saved to the domain bank |
| Before meetings | "Exec meeting in 10 min" | Sigh + "I am excited" + 6Q card | Pressure use logged; held/shaky |
| 12:00 | "Ch. 3 of Torres" | Read timer, then Feynman note | Book progress, note saved |
| 19:00 Mon/Wed/Thu | "Day B Pull" | Set/weight log | Volume trend, PRs |
| 22:00 | "Lay out tomorrow" | Evening close | Day score, streak, win to evidence |
| Sun 19:00 | "Week N report" | 5 answers | Claude-written brief Monday 06:00 → next week's priorities |

**Journey phases:**
- M1–2 Foundation
- M3–6 Craft
- M7–12 Signal
- M13–18 Leverage

Month gates unlock books, cadence, skincare and artifacts. Each month ends with a review that compares this month with last. Protocol mastery levels are earned by logged uses (Aware → Practised → Automatic).

**Visual direction:**
- **Type**: a serif for voice (manifesto, titles) with Plus Jakarta Sans for UI; body 17pt.
- **Palette**: add his wardrobe's navy as the hero band (`#18222F`). Reserve cognac for "now / primary action".
- **Lane colors**: mind `#8FA3C8`, body `#86B49A`, skill `#6FAFB3`, social `#C49AC0`.
- **Contrast**: ink text on cognac fills.
- **Signature visuals**:
  - Today's **Day Dial**: a 06:00–22:30 ring with lane arcs, a "now" needle, and Daily 10 ticks.
  - Program's **18-month Spine**: month columns with milestone dots and role step-ups, plus a 540-day Daily 10 heat map.
  - Style swatches.
- **Craft**: springs and haptics on check-offs, a "Day held" moment at 10/10, and a rebuilt ritual flow.

## Roadmap

**Phase 1: honest & coherent (foundation)**
1. Remove or hide the legacy social/gamified screens and `/features`. Rebuild AI Coach, Progress and Me on real data only. One timeline (18 months), one name (Product Architect).
2. A "Commission" onboarding that replaces archetype/quiz/blueprint:
   - pre-filled identity
   - start date
   - schedule anchors
   - notification permission
   - sign the manifesto
3. Local notifications generated from the schedule, with per-block toggles.
4. Ritual completion ticks the Daily 10. Today can log gym. Today is time-aware. Last 48h are editable.
5. Settings: start-date picker, JSON export/import, working notification toggles.

**Phase 2: the journey & the look**
6. 18-month Spine with phases, month gates and a monthly review.
7. New type and palette, the Day Dial on Today, merged IA (Today / Program / Log / Me), consistent components.
8. History: heat map and trends (CustomPaint).

**Phase 3: tools that produce records**
9. Guided protocol flows: sigh timer, 6Q prep, BLUF drafter, Pennebaker session and 4-week tracker, Feynman notes per book, Anki counter, monthly artifact tracker, LinkedIn post log.
10. Logging: weight, protein, gym sets/weights with progression, bloodwork values.

**Phase 4: real coaching & platform**
11. Sunday report → Claude-written weekly brief (Supabase edge function, reusing `generate-blueprint`). Tasks flow into next week.
12. Supabase backup/sync for the personal system, with encrypted health fields.
13. Widgets, Apple Health, calendar (meeting prep).

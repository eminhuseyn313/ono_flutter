# ONO — feature research (6 Oct 2026)

Research covered four areas:
- the behaviour science of sticking with a long program;
- what iOS 26/27 now lets an app do;
- what the strongest self-improvement apps get right;
- the specifics of your profile: Senior PO → Head of Product, RA in the shoulders, beta thalassemia, sleep, presence with Ali.

Each idea below was checked against what ONO already does. Ideas it already covers are left out.

**Effort:**
- **S** is about a day.
- **M** is two to four days.
- **L** is a week or more.

**Where it's built:**
- **Here** means pure Flutter/Dart. I can build and test it in this environment, and it reaches you through the launchers.
- **Mac** means it needs a native iOS extension or entitlement, built and signed in Xcode.

---

## Tier 1: highest value, buildable here

### 1. Never miss twice (streak that forgives one day) · S · Here
**Today:** one day under 7/10 resets the streak to 0.

**Evidence:**
- Missing once doesn't hurt habit formation, but letting one miss turn into a run of misses does. A "never miss twice" rule beats zero-tolerance streaks over the long term.
- Lally et al. (2010) found it takes a median of **66 days** to reach automaticity, with a range of 18–254. In their data, a single missed day didn't change the curve.

**Build:**
- The streak survives one missed day.
- After a miss, Today shows a **Recovery day** card ("Yesterday slipped. Today counts double: hit 7").
- Me shows both "streak" and "days held this month".

### 2. Fresh-start moments · S · Here
**Evidence:** Dai, Milkman & Riis (2014) found that goal-pursuit spikes after *temporal landmarks*: Mondays, the first of a month, birthdays.

**Build:**
- **Monday:** a one-screen "new week" card on Today. It shows last week's weakest item from the brief and the one commitment for this week.
- **First day of each program month:** an opening screen for the month's theme, its unlocks and the artifact of the month.
- **A phase change (month 3, 7, 13):** a full-screen phase transition. ONO has the spine for this already; it just never makes the moment felt.

### 3. If-then plans on the Daily 10 · S · Here
**Evidence:** Implementation intentions ("When X happens, I will Y") increase follow-through substantially. A 2025 study found that adding a short mental rehearsal raised habit strength at 3 weeks, and the gain held at 12 weeks.

**Build:**
- Each Daily 10 item gets an editable cue: "When I park at the office → sigh ×3", "When I open Slack the first time → BLUF".
- The cue is shown on the item and inside its reminder.
- Once a week, a 20-second "picture it" prompt for the weakest item.

### 4. Morning check-in: energy, mood, sleep, shoulders · M · Here
**Today:** ONO knows what you *did*, never how you *were*. Your profile has RA in the shoulders, chronic low O₂ (beta thalassemia) and sleep issues, so state matters as much as behaviour.

**Evidence:**
- Exercise reduces RA pain, morning stiffness and fatigue without raising disease activity.
- Stiffness lasting 30–45 minutes or more, on a regular basis, is a clinical signal of ongoing inflammation.
- Inflamed joints shouldn't be trained during a flare.
- Daily app check-ins are how RA studies capture flares in real time.

**Build:** a 15-second check-in inside the morning ritual.
- **What it records:**
  - energy 1–5;
  - mood (pleasant ↔ unpleasant, the same scale Apple Health uses);
  - hours slept;
  - shoulder pain 0–10;
  - morning stiffness (none / <15 / 15–30 / 30–60 / 60+ min).
- **What it changes:**
  - On a gym day with shoulder pain ≥ 5 or stiffness ≥ 30 min, the gym screen switches to a **shoulder-sparing variant**: no pressing, more legs and core, Zone 2. It says why.
  - Three such days in a week shows a gentle note: "worth mentioning to your rheumatologist", with the log ready to show.
  - The weekly brief and Me get energy / sleep / pain trends.

These are logs to support conversations with your doctor, not medical advice. ONO won't change medication or supplements.

### 5. Real spaced repetition (replaces the Anki counter) · M · Here
**Today:** the Anki tool only counts reviews you did in another app.

**Evidence:**
- Spaced retrieval beats massed review by a large margin (meta-analysis g = 0.74).
- The best gap between reviews is roughly 10–20% of how long you want to remember (Cepeda et al., 2008).
- Explaining in your own words (Feynman / self-explanation) adds g = 0.55 (Bisra et al., 2018).

**Build:** ONO's own card deck, scheduled on the device (SM-2 / FSRS).
- **Seeded from your content:**
  - the key domain facts (Grab, identity, payments, agentic commerce);
  - certificate topics;
  - every **Feynman note becomes a card automatically**: the prompt is the concept, the answer is your own explanation.
- **Daily:** 5–10 cards after the lunch read. The "read" item ticks when they're done.

### 6. Career cockpit: 1:1s, decisions, promotion case · M · Here
**Today:** the Evidence Archive collects wins, but nothing turns them into a case for Head of Product. Nothing records your 1:1s with Ali either.

**Evidence:** PM career guidance agrees on three things.
- Do the next role before you get it.
- Keep a running check-in log with your manager.
- Keep a gap sheet between your current level and the next, so evidence isn't rebuilt from memory at review time.

**Build:**
- **1:1 log with Ali:**
  - Before the meeting: agenda and the six-questions prep.
  - After: what was decided, plus your follow-ups, which become tasks on Today.
- **Decision journal:** the decision, the options, why, what you expect to happen, and a **review date 90 days out**. ONO brings it back on that date ("was the call right?"). This is the fastest way to build product judgment.
- **Head of Product readiness:** a short scorecard across Product sense / Execution / Leadership / Strategy, with evidence items linked to each row. The gaps feed the Sunday brief.

### 7. Automaticity check (is it a habit yet?) · S · Here
**Evidence:** automaticity can be measured with a 4-question self-report (the SRBAI).

**Build:**
- **Monthly:** rate each Daily 10 item on "I do it without thinking".
- **Once an item is automatic:**
  - It moves to a quiet **Automatic** section.
  - Its reminder turns off, which cuts notification noise.
  - The month review celebrates it.

---

## Tier 2: native iPhone features (built on your Mac with Xcode)

| # | Feature | What you'd get | Effort |
|---|---|---|---|
| 8 | **Home & Lock Screen widgets** (`home_widget`) | Today's score ring, the next block of the day and the streak. Interactive ticks (iOS 17+) let you check "manifesto" or "+40 g protein" without opening the app. | M |
| 9 | **Live Activity / Dynamic Island** (`live_activities`) | Gym rest timer, current set and next exercise on the Lock Screen. The same for Pennebaker, Feynman and ritual timers. | M |
| 10 | **Apple Health** (`health` package) | **Reads** sleep stages, HRV, resting HR and workouts: auto-tick "bed by 22:30" from real sleep data, and a readiness line on Today. **Writes** gym workouts and State of Mind (mood from #4) into Health. | M |
| 11 | **Siri & Shortcuts / App Intents** | "Log 40 grams protein", "Start sigh", "What's my Daily 10?". A **Work Focus filter** shows only the "At work" items while your Work Focus is on. | M |
| 12 | **AlarmKit wake-up (iOS 26)** | A real alarm at 06:00 that opens straight into the morning ritual, more reliable than a notification. | M |
| 13 | **On-device AI (Foundation Models)** | A private, free, offline version of the weekly brief and journal reflections. Nothing leaves the phone. | L |
| 14 | **Screen Time shield** (FamilyControls) | Blocks chosen apps during the 07:45 scan and the lunch read. Apple must approve a special entitlement before it can ship. | L |

**Recommended order on the Mac:** 8 → 10 → 9. Widgets and Health change daily use the most.

---

## Tier 4: second research round (built)

| Feature | Why it works | Source |
|---|---|---|
| **Evening shutdown** | Making a plan for an unfinished goal stops it intruding; writing tomorrow's to-do list at bedtime cut sleep onset by ~9 minutes. | Masicampo & Baumeister 2011; Scullin et al. 2018; Newport, *Deep Work* |
| **Deep work blocks + free gaps from the calendar** | Attention residue from task switching lowers performance on the next task; long, protected blocks are where the artifact gets written. | Leroy 2009; Newport 2016 |
| **Meeting debrief** | After-action reviews soon after the event improve learning; recall is best while fresh. | US Army AAR; Keiser & Arthur 2021 meta-analysis |
| **Letters to future you** | Feeling connected to your future self improves long-term choices; writing to your future self increased exercise. | Hershfield 2011; Rutchick et al. 2018 |

## Tier 5: third research round (built)

| Feature | Why it works | Source |
|---|---|---|
| **Big 3 for the week** | Specific, hard goals beat "do your best"; a weekly review closes open loops. Daily priorities ladder up to them. | Locke & Latham 2002; Allen, *Getting Things Done* |
| **People and contact rhythm** | Emotional closeness decays without contact; weak ties carry new opportunities — central to the Signal phase. | Roberts & Dunbar 2011; Granovetter 1973 |
| **One good thing at shutdown** | Writing down what went well and why raised wellbeing for six months. | Seligman et al. 2005 |

## Tier 3: later

- **Reflection journal with Claude** (Rosebud-style follow-up questions). Use the `weekly-brief` edge function once Supabase is back.
- **Generic onboarding**, needed for a public App Store release (see `RELEASE.md`).
- **Apple Watch app:** a tick-off complication plus a gym set logger.

## Deliberately not recommended
- **Leaderboards, XP, social feeds.** These were removed in the rebuild. They reward looking busy over holding the line, and the critique called them out.
- **More content screens.** ONO's weakness was never missing content. It was the missing loop: cue → action → feedback → adjustment. Every Tier 1 item strengthens that loop.

## Status
- **Built (7 Oct 2026):** items 1–4 (never miss twice, fresh starts, if-then plans, morning check-in with shoulder-sparing gym).
- **Built:** items 5–7 (spaced repetition deck, career cockpit, automaticity check). All of Tier 1 is done.
- **Built:** #10 Apple Health (sleep → check-in and bed tick, HRV, resting HR, weigh-ins to Health); needs the HealthKit capability ticked in Xcode.
- **Built:** #8 Home & Lock Screen widget (display; switched on with `scripts/capabilities.sh widget on`).
- **Built:** gym rest timer (the first half of #9, no native code): tick a set → 90 s rest (2 min on key lifts), +15 / Skip, haptics, and a notification when the rest ends if ONO is in the background.
- **Built:** "What moves your day" on Me: personal patterns from his own logs (sleep → Daily 10, bedtime → morning energy, caffeine → sleep, gym → energy, ritual → the rest of the day). Each needs 5+ days on both sides; labelled as patterns, not proof.
- **Built:** Home Screen quick actions (the no-entitlement part of #11), background-safe tool timers with an end notification, and patterns in the Sunday brief.
- **Built:** meeting prep from the iPhone calendar: Today's Meetings card, a nudge 10 min before each real meeting (six questions for Ali/Rustam, the sigh otherwise), a lunch-read warning. Read-only, in memory only.
- **Next:** the Lock Screen / Dynamic Island view of the rest timer (#9, native); interactive widget ticks (iOS 17 App Intents). Both after the current native build is confirmed on the iPhone.

## Suggested next build
1. Tier 1 items **1, 2, 3, 4** together, as one release: "the loop". They are small, all buildable here, and change every single day.
2. Then **5 and 6**: learning and career.
3. Then Tier 2 on the Mac: **8 and 10**.

---

### Sources
- Never miss twice / streak design: [Never Miss Twice](https://medium.com/@TheChosenVictor/never-miss-twice-c430ea069833) · [Habit streaks: when they backfire](https://www.ehm-tech.com/habit/blog/habit-streaks-do-they-actually-work/) · [Streak resets and quitting](https://tracebyme.com/blog/habit-tracker-streak-anxiety-two-day-rule/)
- Lally et al. 2010: [What Lally et al. actually found](https://www.thebehavioralscientist.com/articles/how-long-to-form-a-habit) · [BPS Research Digest](https://bps.org.uk/research-digest/how-form-habit)
- Fresh start effect: [Dai, Milkman & Riis 2014 (PDF)](https://faculty.wharton.upenn.edu/wp-content/uploads/2014/06/Dai_Fresh_Start_2014_Mgmt_Sci.pdf) · [Wharton summary](https://knowledge.wharton.upenn.edu/article/need-fresh-start-heres-begin/)
- Implementation intentions: [Divine et al. 2025, BJHP](https://bpspsychub.onlinelibrary.wiley.com/doi/full/10.1111/bjhp.12795) · [Instant habits vs flexible tenacity](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10585941/)
- RA and exercise / flare tracking: [Benefits of exercise in RA (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3042669/) · [Exercise is Medicine: RA](https://www.exerciseismedicine.org/assets/page_documents/EIM%20Rx%20series_Exercising%20with%20Rheumatoid%20Arthritis.pdf) · [Real-time RA flares from an app](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8982773/) · [Adapting exercises for RA](https://www.webmd.com/rheumatoid-arthritis/adapt-exercises-for-rheumatoid-arthritis)
- Spaced repetition / self-explanation: [Cepeda et al.](https://www.yorku.ca/ncepeda/publications/CPVWR2006.html) · [Spaced retrieval meta-analysis](https://bmcmededuc.biomedcentral.com/counter/pdf/10.1186/s12909-021-03075-y.pdf) · [Feynman technique evidence](https://www.scotthyoung.com/blog/2024/03/26/5-keys-feynman-technique/)
- PM career growth: [PM Goals & Growth Plan](https://obvious.ai/templates/pm-goals-growth-plan) · [PM career path](https://prepfully.com/articles/career-path-product-manager)
- iOS platform:
  - AI and system features: [Foundation Models (WWDC26)](https://developer.apple.com/videos/play/wwdc2026/241/) · [AlarmKit (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/230/) · [iOS 26 widget & control surface](https://blakecrosley.com/blog/ios-26-widget-and-control-surface) · [App Intents in iOS 26](https://blakecrosley.com/blog/app-intents-2-ios-26-additions) · [Focus filters](https://wwdcnotes.com/notes/wwdc22/10121)
  - Health and mood: [State of Mind & Journaling Suggestions (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10209/?time=0)
  - Screen Time: [Screen Time APIs guide](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7)
- Flutter packages: [home_widget](https://pub.dev/packages/home_widget) · [live_activities](https://pub.dev/packages/live_activities) · [health](https://pub.dev/packages/health/changelog)
- Comparable apps: [Rosebud](https://apps.apple.com/us/app/rosebud-ai-journal-diary/id6451135127) · [Best self-improvement apps 2026](https://riseguide.com/blog/best-self-improvement-apps)

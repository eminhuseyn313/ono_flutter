# ONO — test checklist

## One click

In **Finder**, open `Downloads/ono_flutter` and double-click:
- **ONO Simulator**: builds ONO and shows it on a simulated iPhone. Xcode 27 shows it in **Device Hub**; older Xcode uses Simulator.
- **ONO on iPhone**: installs ONO on your plugged-in iPhone so you can use it for days.

Each one opens a Terminal window that shows progress. Leave that window open.
Both pull the latest `main` first, so you never need to run `git pull` yourself.
The first build takes a few minutes.

If macOS asks whether to open an app downloaded from the internet, click **Open**.
In ONO, tap **Begin** and create an account with any email and a 6+ character password.
App Store / TestFlight steps: see `RELEASE.md`.

## Browser link (no Xcode)

Open **https://claude.ai/artifact/PrmHk7YA9w96nyZhesjKbt** on your iPhone (Safari) or laptop while
signed in to claude.ai. It is the full app running in the browser; data stays in that browser.
Sign up with any email and a 6+ character password (not "Continue with Google").
On iPhone: Share → **Add to Home Screen** to open it like an app.

## 1. Commission (2 min)
- [ ] Welcome → **Begin** → create an account → lands on **Commission · 1 of 5**
- [ ] Identity card shows your role and the path (Senior PO → Global Manager)
- [ ] Pick a start date (Today / Next Monday / any date) → "Program ends …" updates
- [ ] Gym days: one day per A/B/C; enter today's weight
- [ ] Reminders: toggle a few → iPhone asks for notification permission
- [ ] **Hold to sign** the manifesto → Today

## 2. Today
- [ ] Header: date · Day N · phase. Greeting matches the time of day
- [ ] Day Dial: the needle sits on the current block of your schedule
- [ ] Tick Daily 10 items → dial and count update; at 7/10 "Day held" appears
- [ ] Arrows on items open the tool (sigh, scan, BLUF, read, Feynman, protein)
- [ ] **Yesterday** switch lets you fix yesterday's ticks
- [ ] Protein chips add grams; the item ticks itself at 150 g
- [ ] Kill and reopen the app → everything is still there

## 2b. New: the loop
- [ ] Before 14:00 Today shows **Morning check-in**. Set pain 7 or stiffness 60+ → save → Today says shoulder-sparing; the gym screen skips presses and adds legs/trunk (switch restores the normal plan)
- [ ] Unticked Daily 10 items show their **if-then plan**; **If-then plans** (top right of Daily 10) lets you edit them
- [ ] A day under 7 followed by a held day keeps the streak (never miss twice); after a slip Today shows **Recovery day**
- [ ] Monday shows a **New week** card with last week's weakest item; day 1 of each month shows the month card
- [ ] Me → **Mornings**: averages and the shoulder-pain trend

## 2c. New: learning & career
- [ ] Today → inputs strip → **Review**: 5 new cards a day; reveal, grade Again/Hard/Good/Easy; a Feynman note shows up as a card; **+** adds your own
- [ ] Log → **Career cockpit**: log a 1:1 with follow-ups → they appear on Today; tick one off
- [ ] Record a decision → it comes back for review in 90 days (Right / Mixed / Wrong)
- [ ] Readiness tab: rate the 5 dimensions → Me shows the gap; the Sunday brief names it
- [ ] Me → **Is it a habit yet?**: rate items; an item rated 4–5 and done on 80% of the last 30 days moves to "Automatic" on Today and its reminder stops

## 2d. New: Apple Health (iPhone only)
- [ ] **ONO on iPhone** asks once about Apple Health and the widget: answer **y**. Or later, in the `ono_flutter` folder: `bash scripts/capabilities.sh health on`
- [ ] Me → Mornings → **Connect Apple Health** → allow Sleep, Heart, Weight
- [ ] Next morning: the check-in shows "Sleep last night · Apple Health"; Me shows sleep, HRV, resting HR; "In bed by 10:30pm" is ticked if you were in bed by 22:45
- [ ] Log a weigh-in → it appears in the Health app

## 2e. New: widget
- [ ] Turn it on: answer **y** when **ONO on iPhone** asks, or run `bash scripts/capabilities.sh widget on`, then install again
- [ ] Long-press the Home Screen → **+** → **ONO** → add small or medium; on the Lock Screen → Customize → add ONO
- [ ] Tick Daily 10 items in the app → the widget updates within a few seconds; "NOW" follows your schedule through the day
- [ ] If install fails with an App Groups / HealthKit signing error: `bash scripts/capabilities.sh widget off` (or `health off`) and install again

## 2f. New: rest timer & patterns
- [ ] Gym → tick the circle after a set → a rest countdown appears above **Finish session** (90 s, 2 min on key lifts); **+15** and **Skip** work
- [ ] Start a rest, lock the phone → a "Rest done" notification arrives when it ends
- [ ] Me → **What moves your day**: empty at first; after 5+ days with and without a habit (e.g. caffeine cut-off, bedtime) a pattern shows, e.g. "No caffeine after 1pm → sleep that night 7.4 h vs 6.6 h"

## 2g. New: shortcuts & timers
- [ ] Long-press the ONO icon → Morning check-in / Log protein / Start gym session / Review cards → each opens straight there (also when ONO was closed)
- [ ] Domain scan → Start 15 min → lock the phone → a "15 minutes done" notification arrives; reopening shows the right time left
- [ ] Sunday report with 2+ weeks of check-ins → the brief may quote a pattern "from your own last 60 days"

## 2h. New: meetings
- [ ] Me → **Connect your calendar** → Allow. Your work calendar must be on the iPhone (Settings → Calendar → Accounts)
- [ ] Today → **Meetings**: today's meetings with other people, hours in meetings; a warning if one covers 12:00
- [ ] A meeting with Ali or Rustam shows **6 Qs**; others show **Sigh**
- [ ] 10 minutes before a meeting a nudge arrives; tapping it opens six questions or the sigh

## 2i. New: evenings, deep work, letters
- [ ] After 18:00 Today offers **Start shutdown** → tick today's three; unfinished ones are pre-filled for tomorrow → **Shutdown complete** → tomorrow morning the three are already there
- [ ] Today → inputs strip → **Deep work** → pick Artifact, 90 min → Start; or "Already did a block — log it" → hours show on Me
- [ ] With the calendar connected, Today's Meetings card shows the next free hour as "Free — deep work block"
- [ ] After a meeting with Ali ends, a **Debrief** nudge arrives; Today shows Debrief → Log until you log the 1:1
- [ ] Me → **Letters to future you** → write, pick "In 30 days" → sealed with a lock; on that day Today says a letter is ready

## 2j. New: Big 3, people
- [ ] Today → **Set this week's Big 3** → three outcomes → back on Today they're tickable under "This week"
- [ ] Sunday report shows the Big 3 with ticks and a link to plan next week (from Saturday)
- [ ] Me → **People** → "Add Ali and Rustam" → tap a person → **In touch today**; a 1:1 logged with Ali counts too
- [ ] When someone is past their rhythm, Today says **Reach out: <name>**
- [ ] Shutdown → **One good thing today** → it appears in Log as a win

## 3. Tools & logging
- [ ] Morning ritual (from Today before 11:00): 5 steps → finishing ticks the manifesto
- [ ] Sigh tool: run it → "uses" and mastery level go up; the sigh item is ticked
- [ ] Gym: open Push → enter kg/reps → **Finish session** → next time the sets are pre-filled
- [ ] Log tab: add weight, protein, a win, a note, a bloodwork value → they show on the timeline

## 4. Program
- [ ] Journey: the Spine shows 18 months; tap month 1 → unlocks, milestones, artifact
- [ ] Schedule / Body / Reference tabs open and scroll

## 5. Sunday report
- [ ] Log → Sunday reports → fill the three text fields → **Send report → get brief**
- [ ] The brief names your weakest Daily 10 items and coaches your work situation

## 6. Me
- [ ] Stats: day of 540, streak, best streak, days held; the heat map fills as you go
- [ ] Settings: change start date, gym days, reminders; **Export backup** shares it;
      **Restore from clipboard** brings a copied backup back

## Report back
For anything wrong, send: screen name, what you tapped, what you expected, and a screenshot.

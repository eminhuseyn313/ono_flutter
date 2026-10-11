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

## 2k. New: growth plan
- [ ] Today → **What are you growing this month?** → pick an area (professional or personal), rate where you are → **Grow this**
- [ ] Today's card shows this week's drill; do it at work, then Growth → **I did it — reflect** → four short answers
- [ ] **Ask for feedback** shows the exact question; after asking, **Log what they said**
- [ ] End of month: rate again → the start → now change shows; next month starts fresh

## 2l. New: values, self-coaching, your case
- [ ] Me → **Your values** → pick 3–5, one sentence each → Save
- [ ] Before a hard meeting: Values → **Affirm before a hard moment** → pick one, write why → Done
- [ ] Sunday: Today asks whether the week reflected your values → rate each 1–5
- [ ] Me → **Think it through** → goal, reality, three options, will, check-back day → Commit; on that day Today asks: kept it, or drop it on purpose
- [ ] Program → Career → **Your Head of Product case** → per-dimension reps and feedback → Copy the whole case

## 2m. New: your own growth areas
- [ ] Growth → **Create your own area** → tap a template (e.g. Marriage & close relationships) → edit name, bar, drills → Save
- [ ] It appears under "Your own areas" when choosing next month's area
- [ ] In any area's plan: **Add your own drill** → it joins the list and can be suggested as a weekly drill

## 2n. New: goals
- [ ] Today → **Set your first goal** → tap the suggestion from your profile, or **New goal**
- [ ] Walk through wish, outcome, obstacle, plan; pick a number (e.g. minutes or kg) or milestones; pick a deadline → Save
- [ ] The goal page shows % done vs % of time used and the pace; log a number → the line appears after two
- [ ] Today shows the goals compactly; after 14 days without a number it asks you to measure
- [ ] Mark achieved / drop on purpose → it moves to Closed; a fourth active goal is refused

## 2o. New: progress note, setback reset
- [ ] Friday: Today offers **Send your progress note** → pick the person, add one ask → the note is written from your week → edit → **Copy and mark sent** → paste it in WhatsApp or email
- [ ] On a recovery day: **Reset in 3 minutes** → kindness, what happened, smallest next step → it appears in today's priorities
- [ ] Me → **It slipped — reset** works any time

## 2p. New: quarterly review
- [ ] Me → **Quarterly review** (Today prompts it in the last week of each 90-day quarter) → rate the 8 life areas → the lowest suggests a growth area template
- [ ] Wins, lessons, keep / achieved / drop for each goal, the focus for the next quarter → **Close the quarter**

## 2q. New: your profile
- [ ] Me → Settings → **Your profile** → change e.g. the organisation or add a key person → Save → Today greets you by first name, Career and Me show the new details, People offers to add the new person, the progress note defaults to the primary person
- [ ] **Reset to the original profile** brings everything back

## 2r. New: a calmer Today
- [ ] Today shows the time-of-day action, at most two next steps (tap "N more for today" for the rest), then the Daily 10 and three priorities
- [ ] **Your plan** shows one summary line (goals · growth area · week · meetings); tap to open goals, growth, the week, meetings, inputs and body — it stays open next time

## 2s. New: your daily items
- [ ] Today → Daily → **Edit** → retire an item (–) → the count and "to hold the day" adjust (70% of the list)
- [ ] Add an item with a lane, a time of day and an if-then cue → it shows on Today with its cue and counts towards the score
- [ ] Retired items can be brought back; the list never drops below 3 or above 15
- [ ] With the widget on: the ring shows your own total, not /10 (needs a Mac build)

## 2t. New: what each level means
- [ ] Growth → choose an area → tap 1–5 → the matching description appears (level 4 is the area's bar)
- [ ] Career cockpit → Readiness → rate a dimension → its level description shows
- [ ] Create your own area → optionally write your own five levels

## 2u. New: learning, applied
- [ ] Me → **Learning** → add this month's book in one tap, or any book, course, podcast, talk
- [ ] **Start** → when done, **Finished — apply it** → one principle in your words + one experiment this week
- [ ] A week later Today asks **How did the experiment go?** → write the result

## 2v. New: rituals and presence
- [ ] People → tap someone → set **Your ritual together** (e.g. Friday dinner, phones away)
- [ ] When logging contact, pick how present you were → the row shows the ritual and your presence over the last 4 times

## 2w. New: experiments
- [ ] Me → What moves your day → **Experiments** → a change, what you expect, what to watch (daily score, energy, sleep, mood), 7/14/21 days → Start (or tap a pattern to pre-fill)
- [ ] While it runs: day X of N and the measure before vs during (morning check-ins feed energy, mood and sleep)
- [ ] When it ends Today asks **keep or drop?**

## 2x. New: planned rest
- [ ] Me → **Plan your rest** → Rest day / Lighter week / Holiday → This Saturday or pick dates → Plan it
- [ ] On a planned rest day Today says rest is part of the plan and asks whether you switched off; the streak isn't broken by the day
- [ ] With nothing planned in 8 weeks, the Sunday brief suggests planning rest

## 2y. New: stop doing, gratitude letter, role models
- [ ] Me → **Stop doing** → add what you give up and what it makes room for → each week mark Held / Slipped
- [ ] Me → **Gratitude letter** → pick a person → write → Save (copied) → deliver it → **I delivered it** → how they reacted
- [ ] Me → **Role models** → who, what to learn, one question → after asking, save their answer

## 2z. New: quarterly feedback round
- [ ] Me → **Feedback round** (Today prompts it from day 45 of each quarter) → pick up to three people → **Start the round** (the ask is copied) → send it
- [ ] Save each answer in their words → write what repeats → it appears in your career case under "What others say"

## 2za. New: energy map
- [ ] Me → **Energy map** → tap a number under "Energy right now" a few times a day; it shows under Log → Body
- [ ] Finish a block on `/focus` → rate "How sharp were you?"
- [ ] After a couple of weeks a peak appears; `/focus` suggests blocking that window, and the Sunday brief books deep work there

## 2zb. New: plan builder
- [ ] Me → **Build your plan** → keep your name → rate the wheel → pick an area (lowest first) → a goal → add 3 daily items to your list → Today shows the goal, the area and the new items with their cues
- [ ] Try a different name (then Me → Your profile → reset): the profile starts blank and "Replace my current daily list" is on by default

## 2zc. New: your data & privacy
- [ ] Me → **Your data & privacy**: the text matches your build (phone only offline; phone + private cloud in production; device coach vs cloud coach)
- [ ] **Export everything** opens the share sheet with the JSON
- [ ] On a test install only: **Delete everything** → the Delete button stays disabled until you type DELETE → the app returns to setup, reminders are gone, and (production) the `personal_system` row is deleted

## 2zo. New: someone else sees a general app
- [ ] Fresh install → the welcome screen says what ONO is for anyone (no training plan or career path) → the plan builder starts empty
- [ ] Build a plan as someone else → Today: the dial has no schedule arcs and its centre shows your next item; the mode card offers check-in / breathe-focus-pause-step back / shutdown; Inputs show review, deep work, movement, learning; the question of the day sits in Your plan
- [ ] Program shows only the journey (your roles on the spine, general phase text, your area and goals, Close the month); Me has no protocol mastery, readiness or gym body card; the check-in has no shoulder questions; reminders are check-in, daily items, shutdown and Sunday report
- [ ] The Sunday report shows minutes moved instead of gym sessions; the brief has no scan, BLUF, artifact or LinkedIn lines

## 2zp. New: month review, manual, check-in for two, brag document, journal export
- [ ] From day 27 Today offers **Close month N** (someone else → `/month-review`; the built-in person → the month page): held days, area rating, wins, goals, lesson, carry-over → Save
- [ ] Me → People → **How to work with me**: drafted from your values, best-self portrait and energy peak → edit → Save and copy
- [ ] Me → People → **A check-in for two**: four answers → Save; next week the count says "2 weeks in a row"
- [ ] Me → Direction → **Brag document**: 3/6 months/all → goals reached, wins by month, feedback, people helped, learning → Copy
- [ ] Me → Your data & privacy → **Export your journal**: readable text by date
- [ ] Accountability partner: add a stake → it shows on the pact and in the copied update

## 2zn. New: step back and decide
- [ ] Me → Hard days → **Step back**: the questions use your first name → Done → it shows in Log → Notes
- [ ] **Decide with your values**: a question, two options → each option shows your values with Against/Neutral/For and a total → Choose → 10/10/10 and premortem → saved to Career → Decisions, due for review in 90 days

## 2zm. New: health upkeep
- [ ] Me → Body → **Health upkeep** → tap Dentist check-up and Blood tests → add your own with an interval → **Done** sets the next date; overdue ones show in amber and on Today

## 2zl. New: money check-in
- [ ] Me → **Money check-in** → in, out, set aside → saved % and months of buffer update as you type → one decision → Save; Me shows "Last: saved …"
- [ ] From day 25 of the next program month Today prompts it

## 2zk. New: people you're helping grow
- [ ] People → tap someone → **Helping them grow**: what they're working on and your next help → Save → the row shows "Growing: …"
- [ ] **I helped today** logs it (Log → Social) and clears the next help; Me → People shows "helping N grow"

## 2zj. New: hard conversations
- [ ] Me → People → **Hard conversations** → Prepare: with whom, about, what you want (you/them/us), facts, your story, their story, first sentence, ask → **Today**
- [ ] Today prompts "The conversation with …"; open it → mark how it went and what you learned → it moves to "Had"

## 2zi. New: movement
- [ ] Me → Body → **N min moved** → log a 30-min walk and a 20-min vigorous run → 70 of 150 this week; a gym session counts as a strength day

## 2zh. New: direction tools (Me → Growth)
- [ ] **Three possible lives**: write three, rate each, star one, add a prototype → Save → Me shows "Leaning towards …"; **Make it a goal** opens the goal editor with the title filled
- [ ] **What gives and drains you**: list activities, rate −2…+2, pick one and a move → Save → Me and the next Sunday brief show the move
- [ ] **You, at your best**: Copy the ask → add two stories → themes and portrait → Save → the setback screen shows the portrait at the top

## 2zg. New: accountability partner and coach report
- [ ] Me → **Accountability partner** → name, your commitment, theirs, a check-in day → **Save the pact**
- [ ] On the check-in day Today prompts it → **Copy my update** (held days, hard days, the week's three, their turn) → record Kept/Partly/Missed for each → the record line updates
- [ ] Me → **Report for your coach** → month/quarter → the text has goals, the daily plan, growth, wins and no private notes → **Copy the report**

## 2zf. New: hard days
- [ ] Today → under the daily list, **Hard day? Choose how today counts** → **Minimum day** → the card says half holds the day and each unticked item shows "Minimum: …"; **Undo** clears it
- [ ] **Sick day** → "nothing is expected"; your streak doesn't drop tomorrow; the next day shows **Welcome back** and counts on the minimum
- [ ] **Emergency skip** → 2 per month; the third is greyed out
- [ ] If-then plans → edit an item's minimum version; it shows on the next minimum day
- [ ] Two sick days in a week → the Sunday brief suggests coming back with the minimum
- [ ] Seven sick days in a row → the card says the program clock is paused; Me shows "paused 7 d" and the end date moves a week later
- [ ] Me → **Emergency skips** → choose 0–6 a month; the hard-day sheet shows the new number

## 2ze. New: first run starts with the plan builder
- [ ] Fresh install (or Delete everything) → sign up → the plan builder opens, with no back arrow
- [ ] A new name → finish → Today opens, set up, with your 3–7 items and no reminders on
- [ ] Your own name → finish → the original setup (start date, training days, reminders, manifesto) follows

## 2zd. New: plan packs
- [ ] Me → **Plan packs** → open "Money reset" → preview shows areas, goal, daily items with cues, stops → **Use this plan** → the toast counts what was added; using it again adds nothing
- [ ] **Copy my plan to share** → paste it in Notes: first line "ONO plan: My plan", no names or numbers → copy it back → **Use a plan someone sent you** opens the preview

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

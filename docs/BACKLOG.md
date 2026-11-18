# Backlog

Emin, 15 Nov 2026: "in case somebody uploads an AI-created plan, our app will be covering it" and "phone, Apple Watch, MacBook — one application, interconnected, so I can follow everything and reach my goals."

Order = what to build next. Each item passes the two tests: useful to Emin now, useful to anyone.

## A. Any AI-written plan is covered fully

What works today: any plan that loads (file or paste) becomes the person's own — profile, day, daily items with cues, training, reading, films, practices, growth areas, monthly themes, reminders, ritual, coach notes, cards. A partial plan opens every screen (`test/partial_plan_test.dart`).

1. ✅ Done 15 Nov 2026. **Plan-driven switches, not "the built-in person".** Each part turns on only when the person's plan includes it: shoulder checks (`shoulder_sparing` / `avoid_lifts`), the posting task (`linkedin_*`), the monthly artifact (`month_artifacts`), the sessions target (`gym`), readiness (`readiness`). Later: a general `checkin_checks` section so any plan can add its own body checks (a knee, blood sugar, mood).
2. ✅ Done 17 Nov 2026 (`/plan-more`). **Show everything the AI wrote.** Sections ONO doesn't use yet pass through silently. Add "More from your plan" (one generic page listing unknown sections as titled lists).
3. ✅ Done 17 Nov 2026 (what changes, before it's applied; ids and history kept, undo after). **Update a plan without losing anything.** Loading version 2 over version 1: keep ids, show what changed (added / removed / edited) before applying, history untouched.
4. **ONO writes the plan itself.** Instead of copy → AI → paste: the plan builder's answers go to the `weekly-brief`-style edge function and come back as a plan. Needs the `ANTHROPIC_API_KEY` secret.
5. ✅ Done 17 Nov 2026 (the prompt carries the record from day 7). **Refresh the plan from what you did.** Each quarter, the prompt includes the record (held days, goals' pace, slipping items, lessons) so the AI's next plan fits reality.

## B. One ONO on every device

1. **Mac, today (no code):** the web app in Safari → File → Add to Dock. Same account, same data.
2. **Mac, soon (no code):** App Store Connect → the app → Pricing and Availability → allow "iPhone and iPad Apps on Apple Silicon Macs".
3. **Mac app (Flutter macOS target):** ✅ the app, ⌘K and ⌘1–4, notifications (15 Nov 2026; build with `Install ONO on this Mac.command`). Still to do: a menu bar item with today's three and the focus timer; keyboard ticking. Plugins without macOS support (Health, widget, quick actions) are already behind conditional imports. Needs building on the Mac.
4. **Handoff between devices:** start a focus block on the Mac, see it on the watch and Lock Screen; finish the shutdown on the phone after starting it on the Mac.

## C. New features for reaching goals

1. **Ask ONO** — ✅ on-device answers (15 Nov 2026: what now, how am I doing, what's slipping, goals, lessons, what helps). Still to do: the AI version — a coach chat that knows your plan and your record ("What should I do right now?", "Why do I keep missing bed?"). Same privacy rules as the brief.
2. ✅ Partly done 17 Nov 2026 (Plan the day → Put these in my calendar). **Goals into the calendar** — each Sunday, ONO proposes time blocks for the week's three and writes them into the calendar (with a yes per block).
3. **Watch: hard-moment button** — one tap starts the breathing tool with haptics; one tap logs a win.
4. ✅ Done 17 Nov 2026 (on each goal, with Copy). **Proof of progress** — a timeline per goal of the numbers, milestones, wins and lessons behind it, for reviews and for motivation.
5. **Share with a coach or partner** — a read-only weekly page you choose to send (goals, held days, the week's three), never notes or private writing.

## D. Experience (Emin, 18 Nov 2026)

1. ✅ **Watch without opening the iPhone.** A new day rolls the watch's list over, and the watch asks the iPhone (woken in the background) for the latest copy.
2. **Notifications that do more** (lower priority; "when I say it, give me"): today a notification is marked done or snoozed from its buttons; tapping should always open exactly what it's about, with richer actions (log a number, write a line) from the notification itself.
3. **Less text, more glance.** Me (and the app as a whole) reads as a lot of text. Pass: one line per row, numbers and small charts instead of sentences, details one tap away.
4. **Pull to keep going.** What makes people come back for progress (not for streaks alone): visible proof (the goal timeline), a weekly "what changed" moment, and Ask ONO as the front door.

## E. An ecosystem (Emin, 18 Nov 2026: Paya, Oku, Oruta)

Ideas to discuss; nothing built. ONO stays the plan and the reflection; each other app owns one domain and reports back.

1. **One account, one profile.** Sign in once (Supabase or Sign in with Apple), the same name, goals and life areas in every app.
2. **Each app feeds ONO's daily list.** A gym session or health check in Paya ticks ONO's training item and fills its "Body" numbers; a book finished in a reading app becomes a learning item to apply.
3. **ONO sends the plan out.** A goal like "first half marathon" creates the training block in Paya; a book on ONO's list appears in the reading app.
4. **One weekly brief across apps.** The Sunday brief reads all of them and says what moved.
5. **Shared growth packs.** A plan pack (e.g. "back from burnout") carries parts for each app.
6. **Privacy the same everywhere.** Each app shares only what the person allows, listed on one page.

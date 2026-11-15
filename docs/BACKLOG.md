# Backlog

Emin, 15 Nov 2026: "in case somebody uploads an AI-created plan, our app will be covering it" and "phone, Apple Watch, MacBook — one application, interconnected, so I can follow everything and reach my goals."

Order = what to build next. Each item passes the two tests: useful to Emin now, useful to anyone.

## A. Any AI-written plan is covered fully

What works today: any plan that loads (file or paste) becomes the person's own — profile, day, daily items with cues, training, reading, films, practices, growth areas, monthly themes, reminders, ritual, coach notes, cards. A partial plan opens every screen (`test/partial_plan_test.dart`).

1. **Plan-driven switches, not "the built-in person".** Today some of Emin's specifics turn on for anyone with a full plan (`isBuiltInPerson`):
   - shoulder pain / stiffness in the check-in → only when the plan declares body checks (new `checkin_checks` section: name, scale, flag threshold);
   - "2 LinkedIn posts a week" → only when the plan has a `linkedin_*` section or a posting habit;
   - gym-sessions target → from the plan's training days (0 days = no task);
   - monthly artifact → only when `month_artifacts` exist;
   - Career readiness tab → only when `readiness` exists.
   Add these to `planFormatSpec` and `docs/PLAN_FORMAT.md`; test with `partial_plan.json` that none appear when absent.
2. **Show everything the AI wrote.** Sections ONO doesn't use yet pass through silently. Add "More from your plan" (one generic page listing unknown sections as titled lists).
3. **Update a plan without losing anything.** Loading version 2 over version 1: keep ids, show what changed (added / removed / edited) before applying, history untouched.
4. **ONO writes the plan itself.** Instead of copy → AI → paste: the plan builder's answers go to the `weekly-brief`-style edge function and come back as a plan. Needs the `ANTHROPIC_API_KEY` secret.
5. **Refresh the plan from what you did.** Each quarter, the prompt includes the record (held days, goals' pace, slipping items, lessons) so the AI's next plan fits reality.

## B. One ONO on every device

1. **Mac, today (no code):** the web app in Safari → File → Add to Dock. Same account, same data.
2. **Mac, soon (no code):** App Store Connect → the app → Pricing and Availability → allow "iPhone and iPad Apps on Apple Silicon Macs".
3. **Mac app (Flutter macOS target):** menu bar with today's three and the focus timer; ⌘K search over tools; notifications; keyboard ticking. Plugins without macOS support (Health, widget, quick actions) are already behind conditional imports. Needs building on the Mac.
4. **Handoff between devices:** start a focus block on the Mac, see it on the watch and Lock Screen; finish the shutdown on the phone after starting it on the Mac.

## C. New features for reaching goals

1. **Ask ONO** — a coach chat that knows your plan and your record ("What should I do right now?", "Why do I keep missing bed?"). Same privacy rules as the brief.
2. **Goals into the calendar** — each Sunday, ONO proposes time blocks for the week's three and writes them into the calendar (with a yes per block).
3. **Watch: hard-moment button** — one tap starts the breathing tool with haptics; one tap logs a win.
4. **Proof of progress** — a timeline per goal of the numbers, milestones, wins and lessons behind it, for reviews and for motivation.
5. **Share with a coach or partner** — a read-only weekly page you choose to send (goals, held days, the week's three), never notes or private writing.

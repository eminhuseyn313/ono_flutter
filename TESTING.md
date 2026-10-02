# ONO — test checklist

## Start here (easiest)

1. **First time only — get the new launchers.** Open **Terminal** and paste:
   ```bash
   cd ~/Downloads/ono_flutter && git checkout main && git pull
   ```
2. In **Finder**, open the `ono_flutter` folder and **double-click** one of:
   - **`Test in Chrome.command`** — opens the app in Chrome. No Xcode needed. Quickest.
   - **`Test on iPhone Simulator.command`** — opens a virtual iPhone. Needs Xcode.
3. A Terminal window shows progress. The first start takes 1–5 minutes.
   Press `q` in that window to stop.

If macOS says it can't open the file: right-click it → **Open** → **Open**.
In the app, create an account with any email and a 6+ character password.

## Real iPhone (optional)

```bash
cd ~/Downloads/ono_flutter
git fetch origin && git checkout main && git pull
flutter upgrade
flutter clean && flutter pub get
open ios/Runner.xcworkspace     # Runner → Signing & Capabilities → pick your Team (once)
flutter run --release           # iPhone plugged in, unlocked, "Trust this computer"
```

If Xcode says the developer isn't trusted: on the iPhone, Settings → General →
VPN & Device Management → trust your Apple ID.

Mock mode signs you in with any email and a password of 6+ characters.

## 1. Onboarding (2 min)
- [ ] Welcome → **Begin my transformation** → create an account
- [ ] Pick **The Executive** → answer the assessment → blueprint shows your 5 domains
- [ ] **Start my journey** lands on **Today**

## 2. Today
- [ ] Greeting, date and "Day 1 · Month 1 of 18" are correct
- [ ] **Now** card shows the current block of your schedule; tapping opens Plan
- [ ] Before 11:00: **Start the morning ritual** → 5 steps (water, manifesto, priorities, sigh, statement)
- [ ] Tick a few of the **Daily 10** → score ring updates; kill and reopen the app → ticks are still there
- [ ] Type **three priorities** → reopen the app → still there
- [ ] Domain scan row opens today's source in Safari
- [ ] On Mon/Wed/Thu: **Log session + Zone 2** → Plan → Train shows 1/3

## 3. Plan
- [ ] **Day**: timeline highlights the current block
- [ ] **Week**: podcast, domain scan and evening plan per day; today highlighted
- [ ] **Train**: Day A/B/C exercises, face pulls highlighted, RA "never" list
- [ ] **Health**: tick bloodwork items; supplements and sleep rules

## 4. Playbook
- [ ] Manifesto → **I've read it** ticks "Read manifesto" on Today
- [ ] Protocols expand; BLUF shows before / after
- [ ] Evidence Archive: 7 seeded items; add one; swipe left to delete
- [ ] Sunday report: averages fill in; **Copy** puts the report on the clipboard
- [ ] Library, Style (tick a wardrobe item), Career (copy the LinkedIn headline, tick a milestone)

## 5. Everything else
- [ ] Today → **Explore every feature** → open a few cards in each group
- [ ] AI Coach daily tip matches the "Carry this" note on Today

## Report back
For anything wrong, send: screen name, what you tapped, what you expected, and a screenshot.

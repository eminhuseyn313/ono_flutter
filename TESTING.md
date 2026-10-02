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
If Terminal says "Syncing files to device" but no iPhone window appears: press
⌘-Space, type **Simulator**, press Enter — the app is already running in it.
In the app, tap **Begin** and create an account with any email and a 6+ character password.

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

Mock mode signs you in with any email and a password o## 1. Commission (2 min)
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

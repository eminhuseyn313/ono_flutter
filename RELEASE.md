# ONO — from Simulator to the App Store

Bundle ID: `com.eminhuseynzade.ono` · Name: **ONO** · iPhone only · version in `pubspec.yaml` (`1.0.0+1` = version 1.0.0, build 1).

## 1. Simulator (today)
Double-click **ONO Simulator** in the `ono_flutter` folder. Xcode 27 shows the simulated iPhone in Device Hub; older Xcode uses the Simulator window.

## 2. Your iPhone for a few days
Double-click **ONO on iPhone** with the phone plugged in and unlocked. It walks you through:
- Trust This Computer.
- Developer Mode.
- One-time signing in Xcode: pick your Team under Runner → Signing & Capabilities.
- Trusting the developer on the phone.

The app runs on its own once installed; data stays on the phone.

How long it runs:
- **Free Apple ID:** the app stops opening after 7 days. Run the installer again; your data is kept.
- **Apple Developer Program ($99/year):** it lasts much longer. It's also needed for steps 3–4.

## 3. TestFlight (recommended)
TestFlight installs ONO from Apple, with no Mac or cable, and builds last 90 days. Internal testers (you) need no App Review.

Once:
1. Apple Developer Program: done.
2. Xcode → Settings → Accounts: sign in with that Apple ID; team `XYY5Y3F4W5` should show.
3. In App Store Connect (appstoreconnect.apple.com), go to Apps → **+** → New App:
   - Platform: iOS
   - Name: ONO (pick another if it's taken)
   - Bundle ID: `com.eminhuseynzade.ono`
   - SKU: `ono`
   If an agreement is waiting under Business, accept it.

Every time: double-click **ONO to TestFlight**. It updates the code, builds with the next build number (the commit count, so it always goes up), and uploads (`ios/ExportOptions-TestFlight.plist`). Apple emails you when the build is processed (5–15 minutes).

The first time only: App Store Connect → ONO → TestFlight → Internal Testing → add yourself. On the iPhone, install the **TestFlight** app, accept the invite and install ONO. Later uploads appear there by themselves.

If the upload is refused, the launcher says why and opens the archive in Xcode; Distribute App → App Store Connect → Upload does the same by hand.

## 4. Public App Store release
In App Store Connect you also need:
- **Screenshots** for the 6.9" iPhone (1320 × 2868). Take them in the Simulator (iPhone 17 Pro Max) with ⌘S.
- **Description**, keywords, support URL, and a **privacy policy URL**.
- **App Privacy**: in offline mode ONO collects nothing ("Data Not Collected"). If you switch to the Supabase build, declare the account email and the health/fitness data you sync.
- **Age rating** questionnaire, category (Health & Fitness or Productivity), and pricing.

Before you submit to the public store, decide one thing. Today the app is written for one person: your name, employer, manager, gym plan and medical notes are built in. Apple reviews public apps for a general audience. Expect App Review to question an app that only makes sense for one named person, and everything in it would be visible to anyone who downloads it.

So:
- **Personal use:** stay on TestFlight. It needs no review and is private.
- **Public app:** the content needs a generic version first. Onboarding would collect each user's own profile and fill `emin_system.dart`'s structure from it.

## Apple Health, widget, Lock Screen timer, Sign in with Apple
These need a paid team (a free Apple ID can't sign them). **ONO on iPhone** and **ONO to TestFlight** ask once: "Paid Apple Developer Program? [Y/n]". Yes switches on:
- `health`: Apple Health (sleep, HRV, weigh-ins).
- `widget`: the Home and Lock Screen widget. It also carries the Lock Screen timer: a Live Activity counting down deep-work blocks, tool timers and rest between sets on the Lock Screen and in the Dynamic Island.
- `apple`: Sign in with Apple.

To change one later, run this in the `ono_flutter` folder:
```bash
bash scripts/capabilities.sh health on    # or off; also widget, apple
bash scripts/capabilities.sh status
```
The choice is remembered and re-applied after every update. Don't add these by hand in Xcode: the launchers reset hand edits to the project.

If signing complains about a profile after switching them on: Xcode → Settings → Accounts → your team → Download Manual Profiles, then run the launcher again. Automatic signing registers the App ID's capabilities and the app group by itself.

### Sign in with Apple: one setting in Supabase
The button calls Apple on the phone and hands Supabase the token, so no secret key is needed:
1. Supabase → project Ono → Authentication → Sign In / Providers → **Apple** → Enable.
2. Client IDs: `com.eminhuseynzade.ono`. Leave the secret key empty (it's only for sign-in on the web). Save.

Use the Apple ID whose email is your ONO email and choose **Share My Email**: Supabase then signs you in to the same account (same verified email). "Hide My Email" makes a separate, empty account. Until the provider is on, the button says Sign in with Apple isn't switched on yet.

Minimum iOS is 16.2 (Live Activities).

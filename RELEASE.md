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

## 3. TestFlight (recommended next)
TestFlight installs ONO from Apple, with no Mac or cable, and builds last 90 days. Internal testers (you) need no App Review.

1. Join the Apple Developer Program: developer.apple.com/programs.
2. In App Store Connect, go to Apps → **+** → New App:
   - Platform: iOS
   - Name: ONO (pick another if it's taken)
   - Bundle ID: `com.eminhuseynzade.ono`
   - SKU: `ono`
3. Bump the build number in `pubspec.yaml` for every upload (`1.0.0+2`, `+3`, …).
4. Build the archive and open it:
   ```bash
   flutter build ipa --release
   open build/ios/archive/Runner.xcarchive
   ```
   Xcode Organizer opens. Click **Distribute App** → **App Store Connect** → Upload.
5. In App Store Connect → TestFlight, add yourself as an internal tester. Install the **TestFlight** app on the iPhone and accept the invite.

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

## Apple Health and the widget (opt-in)
These need capabilities your Apple team must support: HealthKit, and App Groups for the widget. **ONO on iPhone** asks once. To change it later, run this in the `ono_flutter` folder:
```bash
bash scripts/capabilities.sh health on    # or off
bash scripts/capabilities.sh widget on    # or off
bash scripts/capabilities.sh status
```
The choice is remembered and re-applied after every update. Don't add these by hand in Xcode: the launchers reset hand edits to the project.

For App Store review:
- Mention Health use in the privacy policy.
- Declare "Health & Fitness" data under App Privacy.
- The widget needs no extra review.

## Already set up in the project
- iPhone-only (no iPad screenshots or iPad review needed).
- Export compliance answered (`ITSAppUsesNonExemptEncryption = NO`).
- App icon in every size, with no transparency.
- Dark launch screen.
- Portrait only.
- Local notifications (no extra permissions text needed).
- Calendar usage text (read-only meeting prep); declare nothing extra in App Privacy, since meetings never leave the phone.

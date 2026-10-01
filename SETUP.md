# Ono — Setup & Run Guide

## Quick Start (No CocoaPods Needed)

If you just want to see the app running right now, skip to **Option A** below — it runs in Chrome with zero native dependencies.

---

## Run Options

### Option A: Run on Chrome (fastest, no native setup)

```bash
cd ~/Downloads/ono_flutter
flutter run --target lib/main_production.dart -d chrome
```

This launches the production app in your browser. Auth, blueprint generation, daily actions — everything works. No CocoaPods, no Xcode issues.

For the mock/offline version:

```bash
flutter run -d chrome
```

### Option B: Run on macOS Desktop

Requires CocoaPods. See the **Fix CocoaPods** section below, then:

```bash
cd ~/Downloads/ono_flutter
flutter run --target lib/main_production.dart -d macos
```

### Option C: Run on iPhone (your "emin's iPhone")

Requires CocoaPods + a valid Apple signing team. See **Fix CocoaPods** below, then:

```bash
cd ~/Downloads/ono_flutter
flutter run --target lib/main_production.dart -d 00008140-001C756A0402201C
```

You may need to set your development team in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Pick your Apple ID / team
4. Trust the developer profile on your iPhone (Settings → General → VPN & Device Management)

---

## Fix CocoaPods on macOS 26

macOS 26 (Tahoe) ships with a newer Ruby and updated system protections that break the standard CocoaPods install paths. Here's the fix, in order of reliability:

### Step 1: Update Command Line Tools

This is the root cause of most issues on macOS 26.

```bash
# Remove the old CLT
sudo rm -rf /Library/Developer/CommandLineTools

# Re-install
sudo xcode-select --install
```

A dialog will pop up — click **Install** and wait for it to finish. If no dialog appears, download manually from https://developer.apple.com/download/all/ (search "Command Line Tools for Xcode 26.3").

### Step 2: Install CocoaPods

Try these in order. Stop as soon as one works.

**Method 1 — Ruby gem (most reliable on macOS 26):**

```bash
sudo gem install cocoapods
```

If you get a permissions error:

```bash
gem install cocoapods --user-install
```

Then add the gem bin to your PATH. Check where it installed:

```bash
gem environment gemdir
```

Add this to your `~/.zshrc`:

```bash
export PATH="$HOME/.gem/ruby/3.x.0/bin:$PATH"
```

(Replace `3.x.0` with whatever version `gem environment` showed.)

Then reload:

```bash
source ~/.zshrc
```

**Method 2 — Homebrew (if brew works after CLT update):**

```bash
brew install cocoapods
```

**Method 3 — Bundler (isolated Ruby environment):**

```bash
cd ~/Downloads/ono_flutter
gem install bundler --user-install

# Create a Gemfile
cat > Gemfile << 'EOF'
source 'https://rubygems.org'
gem 'cocoapods'
EOF

bundle install --path vendor/bundle
bundle exec pod install --project-directory=ios
```

With this method, always prefix pod commands with `bundle exec`.

### Step 3: Run pod install

```bash
cd ~/Downloads/ono_flutter/ios
pod install
```

If it fails with repo errors:

```bash
pod repo update
pod install
```

### Step 4: Run the app

```bash
cd ~/Downloads/ono_flutter
flutter run --target lib/main_production.dart
```

---

## Entry Points

| File | Backend | Use Case |
|------|---------|----------|
| `lib/main.dart` | Mock (offline) | UI development, testing |
| `lib/main_production.dart` | Supabase (live) | Real auth, AI blueprints, streaks |

---

## Supabase Configuration

Already done:
- [x] Anon key set in `main_production.dart`
- [x] Edge Functions deployed (`generate-blueprint`, `seed-actions`)
- [x] Archetypes seeded in database
- [x] Schema migrated (lane_scores, weekly_snapshots, added columns)

Still needed:
- [ ] Set `ANTHROPIC_API_KEY` secret in Supabase Dashboard → Edge Functions → Secrets
  (Required for AI blueprint generation to work)

---

## Project Structure

```
lib/
  main.dart                    # Mock entry point (offline)
  main_production.dart         # Production entry point (Supabase)
  router.dart                  # GoRouter with auth guards

  gateways/                    # Data layer (abstract + implementations)
    auth_gateway.dart            # Interface
    mock_auth_gateway.dart       # Offline mock
    supabase_auth_gateway.dart   # Production
    profile_gateway.dart
    mock_profile_gateway.dart
    supabase_profile_gateway.dart
    actions_gateway.dart
    mock_actions_gateway.dart
    supabase_actions_gateway.dart
    progress_gateway.dart
    mock_progress_gateway.dart
    supabase_progress_gateway.dart
    blueprint_gateway.dart
    mock_blueprint_gateway.dart
    supabase_blueprint_gateway.dart

  providers/                   # State management (ChangeNotifier)
    auth_provider.dart
    user_profile_provider.dart
    daily_actions_provider.dart
    progress_provider.dart
    blueprint_provider.dart

  screens/                     # UI layer
    splash_screen.dart
    onboarding_welcome_screen.dart
    sign_up_screen.dart
    sign_in_screen.dart
    archetype_screen.dart
    assessment_screen.dart
    blueprint_loading_screen.dart
    blueprint_screen.dart
    main_screen.dart            # Bottom nav shell
    home_screen.dart
    progress_screen.dart
    profile_screen.dart

  theme/
    app_theme.dart              # Dark theme, colors, typography

supabase/
  migrations/
    20250101000000_initial_schema.sql
  functions/
    generate-blueprint/index.ts  # Claude API → blueprint JSON
    seed-actions/index.ts        # Blueprint → daily_actions rows

test/
    auth_provider_test.dart
    user_profile_provider_test.dart
    daily_actions_provider_test.dart
    progress_provider_test.dart
    blueprint_provider_test.dart
```

---

## Troubleshooting

**"CocoaPods not installed"** → See Fix CocoaPods section above, or run on Chrome.

**"No matching provisioning profile"** → Open `ios/Runner.xcworkspace` in Xcode, set your signing team.

**"supabase: command not found"** → Not needed. Use the Supabase web dashboard instead.

**Auth not working** → Make sure you're running `main_production.dart`, not `main.dart`.

**Blueprint generation fails** → Check that `ANTHROPIC_API_KEY` is set as a secret in Supabase Dashboard → Edge Functions → Secrets.

**App builds but shows blank screen** → Check the Flutter console for errors. Most likely a missing provider — make sure you're using the right entry point.

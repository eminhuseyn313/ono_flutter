# ONO — Flutter App

> Your guardian for becoming your best self.

## What's Built

Complete Flutter mobile app with Supabase backend:

### UI & Screens
- ✅ Splash screen with animated logo
- ✅ Onboarding welcome screen
- ✅ Archetype picker (6 archetypes)
- ✅ 10-question assessment flow
- ✅ Blueprint loading animation with AI generation
- ✅ Blueprint reveal screen with lane-based actions
- ✅ Daily home screen (The Nudge) — streak badge, progress ring, action cards with haptics
- ✅ Progress screen (The Shift) — weekly bar chart, lane progress bars, stat cards
- ✅ Profile screen — editable name, daily nudge toggle, account deletion, share/invite
- ✅ Bottom navigation (Home / Progress / Profile)
- ✅ Full dark theme with purple accents
- ✅ iOS + Android + Web ready

### Backend & Data
- ✅ Supabase Auth (email/password sign-up, sign-in, sign-out)
- ✅ PostgreSQL schema (10 tables with RLS policies)
- ✅ Gateway pattern — abstract interfaces, mock impls for offline, Supabase impls for production
- ✅ Provider (ChangeNotifier) state management
- ✅ GoRouter with auth redirect guard

### AI & Logic
- ✅ `generate-blueprint` Edge Function — Claude API generates personalized blueprints
- ✅ `seed-actions` Edge Function — creates daily_actions rows from blueprint lanes
- ✅ Auto-seed on home screen — if no actions today, re-seeds from active blueprint
- ✅ Onboarding redirect — new users sent to archetype picker automatically
- ✅ DB triggers — auto streak update + lane score recalculation on action toggle

### Dual Entry Points
- `lib/main.dart` — Mock/offline mode (no backend needed)
- `lib/main_production.dart` — Production mode (Supabase live)

## How to Run

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- VS Code with Flutter extension (recommended)

### Install dependencies
```bash
cd ono_flutter
flutter pub get
```

### Run in production mode (Supabase)
```bash
flutter run --target lib/main_production.dart -d chrome
```

### Run in mock/offline mode
```bash
flutter run -d chrome
```

### Hot reload
Press `r` in the terminal for hot reload, `R` for hot restart.

## Project Structure
```
lib/
├── main.dart                         # Mock/offline entry point
├── main_production.dart              # Production entry point (Supabase)
├── theme/
│   └── app_theme.dart                # Colors + typography
├── models/
│   └── models.dart                   # Archetype, BlueprintDomain, AssessmentQuestion
├── providers/
│   ├── auth_provider.dart            # Auth state (sign in/up/out)
│   ├── daily_actions_provider.dart   # Today's actions + streak + history
│   ├── user_profile_provider.dart    # Profile, name, notifications, delete
│   ├── blueprint_provider.dart       # Blueprint load/generation
│   └── progress_provider.dart        # Lane scores + overall score
├── gateways/
│   ├── auth_gateway.dart             # Abstract auth interface
│   ├── supabase_auth_gateway.dart    # Supabase auth impl
│   ├── mock_auth_gateway.dart        # Mock auth impl
│   ├── actions_gateway.dart          # Abstract actions + DailyAction/DayRecord models
│   ├── supabase_actions_gateway.dart # Supabase actions impl
│   ├── mock_actions_gateway.dart     # Mock actions impl
│   ├── profile_gateway.dart          # Abstract profile interface
│   ├── supabase_profile_gateway.dart # Supabase profile impl
│   ├── mock_profile_gateway.dart     # Mock profile impl
│   ├── blueprint_gateway.dart        # Abstract blueprint interface
│   ├── supabase_blueprint_gateway.dart
│   ├── mock_blueprint_gateway.dart
│   ├── progress_gateway.dart         # Abstract progress interface
│   ├── supabase_progress_gateway.dart
│   └── mock_progress_gateway.dart
├── widgets/
│   └── ono_button.dart               # Reusable button component
├── router.dart                       # GoRouter config with auth guard
└── screens/
    ├── splash_screen.dart
    ├── onboarding_welcome_screen.dart
    ├── archetype_screen.dart
    ├── assessment_screen.dart
    ├── blueprint_loading_screen.dart
    ├── blueprint_screen.dart
    ├── main_screen.dart              # Bottom nav shell
    ├── home_screen.dart              # The Nudge (daily actions)
    ├── progress_screen.dart          # The Shift (stats + charts)
    └── profile_screen.dart           # Profile + settings

supabase/functions/
├── generate-blueprint/               # Claude API blueprint generation
└── seed-actions/                     # Seed daily_actions from blueprint
```

## Colors
```
Background:  #0F0F1A
Card:        #1A1A2E
Purple:      #6C63FF
Soft purple: #A89FF5
White:       #FFFFFF
Grey:        #888899
```

## Supabase
- **Project:** `kkgkbfxvovrtmnoezcha`
- **URL:** `https://kkgkbfxvovrtmnoezcha.supabase.co`
- Already configured in `main_production.dart`

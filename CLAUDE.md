# ONO — Personal Transformation App

## What This Is
ONO is a personal transformation app for young men (18-30) built in Flutter with Supabase backend. It has 4 development lanes: Mind, Body, Social, Skill. The app is built around archetypes, blueprints, daily actions, journeys, rituals, and AI coaching.

The primary test user is Emin Huseynzade (archetype: 'executive' / "The Product Leader"). His personalized content layer lives at `lib/data/emin_personal_content.dart`.

## Architecture

```
Models → Gateways (abstract + mock impl) → Providers (ChangeNotifier) → Screens/Widgets
```

- **Models**: `lib/models/` — every model needs `copyWith`, `toJson`, `fromJson`
- **Gateways**: `lib/gateways/` — abstract class + mock implementation. Mock gateways use `Future.delayed(Duration(milliseconds: 150-250))` for realistic async
- **Providers**: `lib/providers/` — extend `ChangeNotifier`, injected via `Provider`
- **Navigation**: GoRouter (`lib/router.dart`)
- **State**: Provider package (ChangeNotifier pattern)
- **Entry points**: `main.dart` (mock/offline mode), `main_production.dart` (Supabase/live)

## Critical Conventions — READ THESE

### Provider Constructor Rules (causes crashes if wrong)
- `TimeCapsuleProvider` takes a **positional** argument: `TimeCapsuleProvider(_gateway)`
- `BlueprintProvider` takes a **positional** argument: `BlueprintProvider(_blueprintGateway)`
- **All other providers** use named parameter: `SomeProvider(gateway: _gateway)`

### Dart/Flutter Rules
- **`withValues(alpha: 0.5)` NOT `withOpacity(0.5)`** — `withOpacity` is deprecated
- **`PopScope`**: Use `onPopInvokedWithResult` callback, NOT `onPopInvokedWithPop`
- **No `\$` escaping in strings** — use proper Dart string interpolation `'text $variable text'` (escaped `\${...}` renders literally on screen; Trending/Wakz/Forge had this bug)
- **No external chart packages** — build all charts with `CustomPaint` / `CustomPainter`
- **Font**: Google Fonts Plus Jakarta Sans

### Theme & Colors
Use `AppColors` (+ `AppText`, `AppSpace`) from `lib/theme/app_theme.dart`. "Architect" palette: charcoal surfaces, ivory text, one cognac accent, steel-navy secondary. Flat bordered cards (no neon, no glass). Field names kept from the old palette — `purple*` is now the cognac accent family, `cyan` is steel blue.

```dart
AppColors.background   // 0xFF0C0D0F
AppColors.card         // 0xFF15171B
AppColors.cardLight    // 0xFF1E2126
AppColors.purple       // 0xFFC8894A (primary accent — cognac; alias AppColors.accent)
AppColors.purpleSoft   // 0xFFE8C9A3
AppColors.purpleDark   // 0xFF4A2F18
AppColors.cyan         // 0xFF7C9CC4 (steel; alias AppColors.steel)
AppColors.green        // 0xFF7DB495
AppColors.white        // 0xFFF3EFE7 (ivory text)
AppColors.grey         // 0xFF8E8A82
AppColors.greyLight    // 0xFFCFCAC1
AppColors.warning      // 0xFFE2B354
AppColors.divider      // 0xFF272A30
AppColors.danger       // 0xFFE0605A
AppColors.mind/body/skill/social, AppColors.lane('mind')  // lane colors
```

Text on the accent uses `AppColors.ink` (dark). Shared widgets for new screens: `lib/widgets/ono_ui.dart` (`OnoPage`, `OnoCard`, `SectionHeader`, `CheckRow`, `ScoreRing`, `Tag`, …).

### Personal operating system
Bottom tabs: Today (`/home`) · Plan (`/plan`) · Playbook (`/playbook`) · Me (`/profile`). Content lives in `lib/data/emin_system.dart` (schedule, gym plan, rotations, library, protocols, style, career, Daily 10). State (checks, priorities, evidence, Sunday reports) goes through `PersonalSystemProvider(gateway: ...)` → `MockPersonalSystemGateway` (SharedPreferences). Detail routes: `/manifesto`, `/protocols`, `/evidence`, `/library`, `/style`, `/career`, `/weekly-coaching`, `/features`.

### Supabase
- Project ID: `kkgkbfxvovrtmnoezcha`
- Used in `main_production.dart` for live/production mode

## Key Models

### BlueprintDomain (`lib/models/models.dart`)
```dart
BlueprintDomain(name: String, emoji: String, actions: List<String>, active: bool)
// NO 'lane' parameter
```

### RitualStep (`lib/models/ritual.dart`)
```dart
RitualStep(id, title, subtitle, lane: RitualLane, durationSeconds: int, iconData: IconData, instruction: String)
// RitualLane enum: mind, body, social, skill
// NO 'duration:' or 'why:' parameters
```

### JourneyAction (`lib/models/role_model.dart`)
```dart
JourneyAction(title: String, subtitle: String, lane: String)
// lane is a plain String like 'mind', 'skill' — NOT RitualLane enum
// NO id, description, or xpReward parameters
```

### JourneyMilestone (`lib/models/journey.dart`)
```dart
MilestoneType enum: streak, completion, lane, special
// NO 'actions' value in the enum
```

### Blueprint system (`lib/gateways/blueprint_gateway.dart`)
```dart
Blueprint(archetypeId, title, summary, lanes, generatedAt)
BlueprintLane(id, name, description, actions)
BlueprintAction(id, title, subtitle, laneId, durationMinutes, orderIndex)
```

### DailyCoachTip (`lib/models/ai_coach.dart`)
```dart
DailyCoachTip(id, title, content, lane, laneColorValue, date, isBookmarked)
```

## All Routes

Bottom nav tabs: `/home` (Today), `/plan`, `/playbook`, `/profile` (Me). `/progress` and `/journal` stay in the shell, reached from Playbook.

All available routes:
```
/splash, /welcome, /sign-up, /sign-in, /forgot-password,
/archetype, /assessment/:archetypeId, /loading/:archetypeId,
/blueprint/:archetypeId, /weekly-review, /role-models, /role-model/:id,
/achievements, /heat-map, /morning-ritual, /lane-analytics, /monk-mode,
/legacy-score, /notification-settings, /becoming-arc, /arc-layer,
/arc/:arcId/assessment/:dayNumber, /notification-feed, /ghost-mode,
/ritual-flow/:ritualId, /ritual-setup, /council, /phase-transition,
/time-mode, /brotherhood, /radio, /radio/:roleModelId, /trending,
/mirror-match, /forge, /forge/:courseId, /forge/:courseId/lesson/:lessonId,
/adaptive-settings, /wakz-challenges, /forge-analytics, /accountability,
/vault, /gamification, /planner, /vision-board, /power-rankings,
/settings, /onboarding-flow, /dashboard, /achievement-hub, /analytics,
/weekly-review-flow, /social-feed, /habit-streaks, /daily-checkin,
/ai-coach, /content-library, /community-challenges, /home, /progress,
/journal, /profile, /plan, /playbook, /manifesto, /protocols, /evidence,
/library, /style, /career, /weekly-coaching, /features
```

`/phase-transition` and `/arc-layer` fall back to sample data when opened without `extra`.

## Personalized Content Layer

File: `lib/data/emin_personal_content.dart`

Contains Emin's personalized data that should be wired into mock gateways:
- `eminArchetype` — Archetype for 'executive'
- `eminBlueprint` — 5 BlueprintDomains (Product Craft, Domain Intelligence, Mental Performance, Physical Foundation, Executive Presence)
- `eminMorningRitual` — 5 RitualSteps for the morning sequence
- `productArchitectRoleModel` — RoleModel with 6 JourneyActions
- `productLeaderJourney` — Journey with 3 phases, 12 milestones over 30 days
- `eminCoachTips` — 30 DailyCoachTips (one per day for a month)
- `eminWeeklyReviewQuestions` — 12 weekly review questions
- `eminAssessmentProfile` — Map of assessment answers

## Roadmap status

All items done:
1. **Content layer wired** — executive blueprint, actions seeding, morning ritual, coach tips (rotated by program day), Product Architect role model, Product Leader journey.
2. **Feature discovery** — grid lives at `/features` (linked from Today and Playbook) instead of inside the home screen.
3. **Personal operating system + redesign** — see "Personal operating system" above.
4. **Quality** — 0 analyzer errors; `flutter test` green. `test/widget_test.dart` signs in and opens every route at iPhone 15 and iPhone SE sizes, failing on any runtime error including layout overflow (it renders with the bundled Plus Jakarta Sans). Run it after touching screens.
5. **Me tab** reads the Daily 10 (streak = days at 7+/10, today's score, week average, per-lane ticks).

Still to do: run on a physical iPhone (needs macOS + Xcode; see below). Production mode still has only 5 Supabase gateways — the rest are mock.

### Build for iOS testing
```bash
git pull && git checkout main-ntyuqf
flutter upgrade          # older Flutter can't launch on iOS 27 simulators
flutter clean && flutter pub get
open ios/Runner.xcworkspace   # set your Team under Signing & Capabilities once
flutter run --release     # with the iPhone plugged in and trusted
```

Fonts are bundled (`assets/google_fonts/`), so the app looks right offline.

## File Structure Notes

- `home_screen.dart` is the Today screen (~600 lines): now card, ritual, Daily 10, priorities, inputs, training, coach note, protocol
- Mock gateways contain static data per archetype — the 'executive' archetype paths need personalized content
- `PrebuiltRituals` class has `morning()` and `evening()` factory methods

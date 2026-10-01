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
- **No `\$` escaping in strings** — use proper Dart string interpolation `'text $variable text'`
- **No external chart packages** — build all charts with `CustomPaint` / `CustomPainter`
- **Font**: Google Fonts Plus Jakarta Sans

### Theme & Colors
Use `AppColors` class. Dark theme with glassmorphic cards.

```dart
AppColors.background   // 0xFF0A0C14
AppColors.card         // 0xFF121826
AppColors.cardLight    // 0xFF1B2336
AppColors.purple       // 0xFF8B5CF6 (primary accent)
AppColors.purpleSoft   // 0xFFC4B5FD
AppColors.purpleDark   // 0xFF4C1D95
AppColors.cyan         // 0xFF22D3EE
AppColors.green        // 0xFF34D399
AppColors.white        // 0xFFF8FAFC
AppColors.grey         // 0xFF9AA6B2
AppColors.greyLight    // 0xFFD5DEE8
AppColors.success      // 0xFF34D399
AppColors.warning      // 0xFFF59E0B
AppColors.divider      // 0xFF202B3F
```

**There is NO `AppColors.error`** — use `Color(0xFFEF4444)` directly.

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

Bottom nav tabs: `/home`, `/progress`, `/journal`, `/profile`

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
/journal, /profile
```

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

## Pending Work

### 1. Wire Content Layer into Mock Gateways
The personalized content in `lib/data/emin_personal_content.dart` needs to be integrated:

- **`lib/gateways/mock_blueprint_gateway.dart`**: When archetypeId is 'executive', use `eminBlueprint` domains to generate `BlueprintLane` objects with `BlueprintAction` items (map each domain's action strings into BlueprintActions)
- **`lib/gateways/mock_actions_gateway.dart`**: Has `seedFromBlueprint()` — ensure it works with the personalized blueprint data
- **Morning ritual provider/gateway**: Wire `eminMorningRitual` steps into the ritual system
- **AI coach provider/gateway**: Wire `eminCoachTips` into the coach tip system
- **Role model data source**: Add `productArchitectRoleModel` to available role models
- **Journey data source**: Add `productLeaderJourney` to available journeys

### 2. Feature Discovery Grid
Add a scrollable grid to `lib/screens/home_screen.dart` (currently 1553 lines) that shows all app features as tappable cards, so every screen can be discovered and tested. Each card should navigate to its route.

### 3. Build for iOS Testing
After wiring is complete, build and deploy to iPhone for testing:
```bash
cd ~/Downloads/ono_flutter
flutter clean
flutter pub get
flutter build ios --debug
# Then open in Xcode:
open ios/Runner.xcworkspace
# Or run directly:
flutter run
```

## File Structure Notes

- `home_screen.dart` is ~1553 lines with: header, progress hero, lane scores, active journey, challenges, today's actions, explore journeys, daily wisdom
- Mock gateways contain static data per archetype — the 'executive' archetype paths need personalized content
- `PrebuiltRituals` class has `morning()` and `evening()` factory methods

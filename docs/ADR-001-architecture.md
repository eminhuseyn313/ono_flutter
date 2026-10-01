# ADR-001: Ono Flutter App Architecture — Auth, State, Routing & Layer Boundaries

**Status:** Proposed
**Date:** 2026-08-17
**Deciders:** Emin Huseynzade (founder / sole developer)

---

## Context

Ono is a Flutter mobile app (iOS, Android, Web) for personal transformation. The Phase 1 prototype is complete with 10 screens, static data, and no backend. Phase 2 introduces Supabase auth, AI-generated blueprints via Claude API, push notifications, and persistent user data.

The current codebase has these structural realities:

1. **No layered separation.** Screens import models directly, navigation is hardcoded via `Navigator.push`, and data is served by static methods on `AppData`.
2. **No state management layer.** All state lives in `StatefulWidget`s. The `provider` and `go_router` packages are in `pubspec.yaml` but unused.
3. **Tight coupling to static data.** `AppData.getTodayActions()`, `AppData.getDomains()`, and `AppData.archetypes` are called directly from screens, making it impossible to swap in API-driven data without rewriting every screen.
4. **Hardcoded navigation.** Splash → Onboarding is a `Future.delayed` push. Assessment → BlueprintLoading → Blueprint → MainScreen is a chain of `Navigator.push` calls. No route guards exist for auth state.
5. **No auth.** Supabase is imported but not initialised.

The auth provider and gateway we just built (Task #1–4) are the first pieces of the new architecture. This ADR records the decisions for the full layer structure going forward.

---

## Decision

Adopt a **three-layer architecture** with clear dependency rules, Provider for state management, GoRouter for declarative routing, and the Gateway pattern for all external services.

---

## Architecture Layers

```
┌──────────────────────────────────────────────────┐
│                  UI Layer                        │
│   screens/  widgets/  theme/                     │
│   • Stateless where possible                     │
│   • Reads state via context.watch<Provider>()    │
│   • Calls provider methods for user actions      │
│   • Never imports gateways or Supabase directly  │
└────────────────────┬─────────────────────────────┘
                     │ depends on
┌────────────────────▼─────────────────────────────┐
│               State Layer                        │
│   providers/                                     │
│   • ChangeNotifier classes                       │
│   • Owns app state and business logic            │
│   • Delegates I/O to gateways                    │
│   • Unit-testable with mock gateways             │
└────────────────────┬─────────────────────────────┘
                     │ depends on
┌────────────────────▼─────────────────────────────┐
│              Gateway Layer                       │
│   gateways/                                      │
│   • Abstract interface per external service       │
│   • One production impl per interface             │
│   • Wraps Supabase, Claude API, Firebase, etc.    │
│   • Returns domain types, never raw responses     │
└──────────────────────────────────────────────────┘
```

**Dependency rule:** UI → Providers → Gateways. Never the reverse. Screens never import gateway implementations. Providers never import Flutter UI.

---

## Options Considered

### Option A: Provider + Gateway (Selected)

| Dimension | Assessment |
|-----------|------------|
| Complexity | Low |
| Cost | Zero (already in pubspec) |
| Scalability | Sufficient for 5–8 providers, single-dev team |
| Team familiarity | High — Provider is Flutter's recommended starting point |
| Testability | High — gateway abstraction enables pure-Dart unit tests |

**Pros:**
- Already partially implemented (AuthProvider + AuthGateway are built and tested)
- Minimal boilerplate — no code generation, no build_runner dependency
- ChangeNotifier + `context.watch` is simple mental model
- Gateway pattern isolates every external dependency behind a seam
- Hand-rolled mocks keep the test suite fast and dependency-light

**Cons:**
- No built-in immutability — state mutations rely on discipline
- Manual `notifyListeners()` calls can be forgotten
- If the app grows to 15+ providers, wiring gets verbose

### Option B: Riverpod + Repository

| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium |
| Cost | Migration effort from current Provider setup |
| Scalability | Very high — compile-time safety, auto-disposal |
| Team familiarity | Medium — steeper learning curve |
| Testability | Very high — overrides baked into the framework |

**Pros:**
- Compile-time provider safety (no runtime `ProviderNotFoundException`)
- Auto-disposal of unused providers
- Built-in async state handling (`AsyncValue`)

**Cons:**
- Heavier API surface for a solo developer
- Requires rewriting the AuthProvider we just built
- Code generation (`riverpod_generator`) adds build complexity

### Option C: BLoC + Repository

| Dimension | Assessment |
|-----------|------------|
| Complexity | High |
| Cost | Significant boilerplate per feature |
| Scalability | Enterprise-grade |
| Team familiarity | Low |
| Testability | Very high |

**Pros:**
- Enforced separation of events and states
- Predictable state transitions, great for debugging

**Cons:**
- Heavy boilerplate for each feature (event classes, state classes, bloc class)
- Overkill for a solo-dev app with 5 providers
- Slower iteration speed during early product development

---

## Trade-off Analysis

The core trade-off is **iteration speed vs. structural safety**.

BLoC maximises structure but halves the speed at which a solo developer can ship features. Riverpod sits in the middle — better safety than Provider but with a migration cost and a learning investment that doesn't pay off until the provider count exceeds ~10.

Provider + Gateway is the right fit *today* because:

1. The app has 5 planned providers (Auth, Blueprint, DailyActions, Progress, UserProfile). Provider handles this comfortably.
2. The Gateway pattern gives us the testability benefit that's usually Riverpod/BLoC's strongest argument — we already proved this with 13 passing AuthProvider tests.
3. If the app outgrows Provider (15+ providers, complex inter-provider dependencies), migrating to Riverpod is a contained refactor: the gateway layer stays identical, only the provider wiring changes.

---

## Detailed Decisions

### 1. Folder Structure (Target)

```
lib/
├── main.dart                        # Supabase.initialize, Provider wiring, GoRouter
├── gateways/
│   ├── auth_gateway.dart            # ✅ Built — abstract interface
│   ├── supabase_auth_gateway.dart   # ✅ Built — production impl
│   ├── blueprint_gateway.dart       # Abstract — Claude API calls
│   ├── claude_blueprint_gateway.dart
│   ├── actions_gateway.dart         # Abstract — daily actions CRUD
│   └── supabase_actions_gateway.dart
├── providers/
│   ├── auth_provider.dart           # ✅ Built — auth state + session restore
│   ├── blueprint_provider.dart      # Blueprint generation + caching
│   ├── daily_actions_provider.dart  # Today's actions, completion, streaks
│   ├── progress_provider.dart       # Stats aggregation
│   └── user_profile_provider.dart   # Archetype, settings, preferences
├── models/
│   └── models.dart                  # Domain types (keep, extend)
├── screens/                         # UI screens (keep, refactor to read providers)
├── widgets/                         # Reusable components (keep, extend)
└── theme/
    └── app_theme.dart               # Colours + typography (keep)

test/
├── auth_provider_test.dart          # ✅ Built — 13 tests
├── blueprint_provider_test.dart
├── daily_actions_provider_test.dart
└── progress_provider_test.dart
```

### 2. Routing — GoRouter with Auth Redirect

Replace all `Navigator.push` chains with declarative GoRouter. Auth state drives route guards.

```dart
// Simplified routing logic
GoRouter(
  refreshListenable: authProvider,            // re-evaluate on auth change
  redirect: (context, state) {
    final authed = authProvider.isAuthenticated;
    final onAuthRoute = state.matchedLocation.startsWith('/auth');

    if (!authed && !onAuthRoute) return '/auth/welcome';
    if (authed && onAuthRoute) return '/home';
    return null;                              // no redirect
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/home'),
    // Auth shell
    GoRoute(path: '/auth/welcome', builder: ...),
    GoRoute(path: '/auth/archetype', builder: ...),
    GoRoute(path: '/auth/assessment/:archetypeId', builder: ...),
    GoRoute(path: '/auth/loading', builder: ...),
    GoRoute(path: '/auth/blueprint/:archetypeId', builder: ...),
    // Main app shell (requires auth)
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: ...),
        GoRoute(path: '/progress', builder: ...),
        GoRoute(path: '/profile', builder: ...),
      ],
    ),
  ],
)
```

**Key decision:** The onboarding flow (archetype → assessment → blueprint) lives under `/auth/*` because it runs once before the user enters the main app. After blueprint reveal, the user's profile is created in Supabase and they become "fully onboarded." Future launches skip straight to `/home`.

### 3. Session Restoration Flow

```
App start
  │
  ├─ Supabase.initialize()
  ├─ AuthProvider.init()        ← recovers persisted session
  │
  ├─ Session exists?
  │   ├─ YES → has completed onboarding?
  │   │         ├─ YES → /home
  │   │         └─ NO  → /auth/archetype (resume onboarding)
  │   └─ NO  → /auth/welcome
  │
  └─ AuthProvider.listenToAuthChanges()  ← react to token refresh / remote sign-out
```

The splash screen becomes a thin shell that shows the animated logo while `init()` runs, then GoRouter's redirect takes over.

### 4. Provider Wiring in main.dart

```dart
MultiProvider(
  providers: [
    // Gateways (injected into providers)
    Provider<AuthGateway>(create: (_) => SupabaseAuthGateway(Supabase.instance.client)),
    Provider<BlueprintGateway>(create: (_) => ClaudeBlueprintGateway(...)),
    Provider<ActionsGateway>(create: (_) => SupabaseActionsGateway(...)),

    // State providers
    ChangeNotifierProxyProvider<AuthGateway, AuthProvider>(
      create: (ctx) => AuthProvider(gateway: ctx.read<AuthGateway>()),
      update: (_, gateway, prev) => prev!,
    ),
    ChangeNotifierProxyProvider<ActionsGateway, DailyActionsProvider>(...),
    ChangeNotifierProxyProvider<BlueprintGateway, BlueprintProvider>(...),
  ],
  child: OnoApp(),
)
```

### 5. Testing Strategy

| Layer | Test type | Tooling |
|-------|-----------|---------|
| Gateways | Integration tests (optional, against Supabase local) | `supabase start`, `flutter_test` |
| Providers | Unit tests with mock gateways | `flutter_test`, hand-rolled mocks |
| Screens | Widget tests with mock providers | `flutter_test`, `Provider.value` overrides |

No `mockito` or `build_runner` — hand-rolled mocks keep the feedback loop fast. Each provider gets its own test file. Tests are written *before* the implementation (TDD, as established with AuthProvider).

---

## Consequences

**What becomes easier:**
- Adding new features (new gateway + provider + screen, wired in `main.dart`)
- Testing any layer in isolation
- Swapping backends (e.g. replacing Supabase with Firebase) — only gateway impls change
- Auth-guarded routing — handled declaratively, no scattered `if (loggedIn)` checks
- Session restoration — single `init()` call, GoRouter handles the rest

**What becomes harder:**
- Every new external service requires an abstract gateway + implementation (more files, but worth the seam)
- Screens must go through providers — no shortcutting to Supabase directly (this is a feature, not a bug)

**What we'll need to revisit:**
- If provider count exceeds ~12, evaluate Riverpod migration (the gateway layer ports unchanged)
- If complex inter-provider dependencies emerge (e.g. BlueprintProvider depends on AuthProvider's user AND DailyActionsProvider's history), consider a coordination layer or Riverpod's ref system
- Push notification handling may need a separate service layer outside the provider tree

---

## Action Items

1. [x] Implement `AuthGateway` interface
2. [x] Implement `SupabaseAuthGateway`
3. [x] Implement `AuthProvider` with session restoration
4. [x] Write AuthProvider unit tests (13 tests, all passing)
5. [ ] Add `Supabase.initialize()` to `main.dart`
6. [ ] Wire `MultiProvider` in `main.dart`
7. [ ] Replace `Navigator.push` chains with GoRouter
8. [ ] Add auth redirect guard to GoRouter
9. [ ] Refactor `SplashScreen` to await `AuthProvider.init()` then let GoRouter redirect
10. [ ] Build `BlueprintGateway` + `ClaudeBlueprintGateway` (Claude API)
11. [ ] Build `DailyActionsProvider` + `ActionsGateway` (Supabase CRUD)
12. [ ] Build `ProgressProvider` (computed from actions data)
13. [ ] Build `UserProfileProvider` (archetype, settings)
14. [ ] Refactor all screens to read from providers instead of `AppData` statics

# Foundation Client Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Ono a guest-first, retry-safe account conversion path that persists a user's transformation journey to Supabase.

**Architecture:** A versioned `JourneyDraft` is persisted before a network call and contains all cloud primary keys. `SyncAdapter` uses a single-flight guard and a small gateway interface to make the ordered sync testable; `AuthProvider` subscribes to Supabase state, exposes account actions, and only requests sync when a pending draft exists.

**Tech Stack:** Flutter, Provider, Supabase Flutter, SharedPreferences, flutter_timezone, uuid, flutter_test.

## Global Constraints

- Keep Provider and StatefulWidget; do not add Riverpod.
- Keep all Supabase credentials in `--dart-define` values; never commit service-role or secret keys.
- Store IANA timezone names; fall back to `UTC`.
- Persist IDs before sync; clear guest staging only after every remote write succeeds.
- Cloud writes must be ordered: profile, assessment, blueprint, daily actions.

---

### Task 1: Add runtime dependencies and Supabase bootstrap

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: initialized `Supabase.instance.client` before `runApp`.

- [ ] **Step 1: Add packages**

Add pinned compatible dependencies:

```yaml
flutter_timezone: ^3.0.1
uuid: ^4.4.2
```

- [ ] **Step 2: Initialize Supabase from compile-time configuration**

```dart
const url = String.fromEnvironment('SUPABASE_URL');
const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
if (url.isEmpty || key.isEmpty) throw StateError('Missing Supabase configuration.');
await Supabase.initialize(url: url, anonKey: key);
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`

Expected: no errors from the bootstrap change.

### Task 2: Persist the guest journey draft

**Files:**
- Create: `lib/services/journey_draft_store.dart`
- Create: `test/services/journey_draft_store_test.dart`

**Interfaces:**
- Produces: `JourneyDraftStore.saveAssessment`, `saveBlueprint`, `saveActions`, `load`, `hasPendingSync`, and `clearAfterSync`.
- Consumes: `SharedPreferences`.

- [ ] **Step 1: Write failing persistence tests**

```dart
test('persists the same assessment id across load', () async {
  final store = JourneyDraftStore(preferences);
  final draft = await store.saveAssessment(answers: {'0': 2});
  expect((await store.load())!.assessment!.id, draft.assessment!.id);
});

test('retains a pending draft until cloud sync is acknowledged', () async {
  final store = JourneyDraftStore(preferences);
  await store.saveBlueprint(lanes: const [], milestones: const []);
  expect(await store.hasPendingSync(), isTrue);
  await store.clearAfterSync();
  expect(await store.load(), isNull);
});
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/services/journey_draft_store_test.dart`

Expected: FAIL because `JourneyDraftStore` does not exist.

- [ ] **Step 3: Implement immutable draft serialization**

Use one JSON key, schema version `1`, `Uuid().v4()` only when a persisted entity lacks an ID, and write the revised draft immediately.

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/services/journey_draft_store_test.dart`

Expected: PASS.

### Task 3: Implement retry-safe cloud sync

**Files:**
- Create: `lib/services/sync_adapter.dart`
- Create: `test/services/sync_adapter_test.dart`

**Interfaces:**
- Produces: `SyncAdapter.syncPendingGuestJourney(String userId)`.
- Consumes: `JourneyDraftStore`, `JourneyGateway`, and `TimezoneResolver`.
- `JourneyGateway` exposes `upsertProfile`, `upsertAssessment`, `upsertBlueprint`, and `upsertActions`.

- [ ] **Step 1: Write failing ordered-sync tests**

```dart
test('writes profile, assessment, blueprint, and actions before clearing draft', () async {
  await adapter.syncPendingGuestJourney('user-id');
  expect(gateway.calls, ['profile', 'assessment', 'blueprint', 'actions']);
  expect(await store.load(), isNull);
});

test('retains the draft when an action write fails', () async {
  gateway.throwOn = 'actions';
  await expectLater(adapter.syncPendingGuestJourney('user-id'), throwsA(isA<Object>()));
  expect(await store.hasPendingSync(), isTrue);
});
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/services/sync_adapter_test.dart`

Expected: FAIL because `SyncAdapter` does not exist.

- [ ] **Step 3: Implement gateway-backed sequential sync**

Use `FlutterTimezone.getLocalTimezone()` with a `UTC` fallback. Coalesce overlapping calls into one `Future<void>` and clear the draft only after all gateway calls complete.

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/services/sync_adapter_test.dart`

Expected: PASS.

### Task 4: Add authentication state management

**Files:**
- Create: `lib/providers/auth_provider.dart`
- Create: `test/providers/auth_provider_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `AuthProvider`, `AuthStatus`, `signInWithEmail`, `signUpWithEmail`, `signInWithOAuth`, `signOut`, and `retryPendingSync`.
- Consumes: Supabase auth events and `SyncAdapter`.

- [ ] **Step 1: Write failing provider tests**

```dart
test('starts as guest without a session', () async {
  expect(provider.status, AuthStatus.guest);
});

test('syncs a pending journey after authentication', () async {
  auth.emitAuthenticated(user);
  await pumpEventQueue();
  expect(sync.calls, 1);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/providers/auth_provider_test.dart`

Expected: FAIL because `AuthProvider` does not exist.

- [ ] **Step 3: Implement provider and register it**

Wrap the root app with `ChangeNotifierProvider(create: (_) => AuthProvider(...))`; cancel the auth stream in `dispose`.

- [ ] **Step 4: Run provider tests**

Run: `flutter test test/providers/auth_provider_test.dart`

Expected: PASS.

### Task 5: Save onboarding data and gate journey activation

**Files:**
- Modify: `lib/screens/assessment_screen.dart`
- Modify: `lib/screens/blueprint_screen.dart`
- Modify: `lib/screens/home_screen.dart`
- Create: `lib/widgets/account_conversion_sheet.dart`
- Create: `test/widgets/account_conversion_sheet_test.dart`

**Interfaces:**
- Consumes: `JourneyDraftStore` and `AuthProvider` through Provider.
- Produces: email-first account conversion sheet before action completion/streak activation.

- [ ] **Step 1: Write a failing sheet test**

```dart
testWidgets('submits email credentials through the auth provider', (tester) async {
  await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
  await tester.tap(find.text('Continue'));
  expect(auth.signUpCalls, 1);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/widgets/account_conversion_sheet_test.dart`

Expected: FAIL because the sheet does not exist.

- [ ] **Step 3: Persist assessment and blueprint drafts, then add gate**

Save the assessment before leaving the assessment flow, save the static blueprint before `MainScreen`, and show the sheet from the first daily action completion when `context.read<AuthProvider>().isGuest`.

- [ ] **Step 4: Run all tests and analyzer**

Run: `flutter test && flutter analyze`

Expected: PASS with no analyzer errors.

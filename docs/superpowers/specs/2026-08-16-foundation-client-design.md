# Ono Foundation Client Design

## Goal

Let a guest complete Ono onboarding immediately, then safely convert to an authenticated account and persist the same transformation journey without duplicate cloud records.

## Scope

- Keep `provider` and `ChangeNotifier` for Release 1.
- Support session restoration, email auth now, and Apple/Google provider methods for the next UI release.
- Persist guest assessment, blueprint, and daily actions locally.
- Sync the local journey only after authentication, retrying safely after failures.

## Architecture

`JourneyDraftStore` is the local source of truth before authentication. It stores a single versioned draft JSON document in `SharedPreferences`, including stable UUIDs for the assessment, blueprint, and actions, selected archetype, local IANA timezone, and `syncPending`.

`SyncAdapter` is a single-flight service: overlapping auth events share one in-progress sync instead of issuing concurrent writes. It loads the draft, upserts `profiles`, `assessments`, `blueprints`, and `daily_actions` in that order, then clears the draft only after the full sequence succeeds. A failed write leaves the complete draft intact for a later retry.

`AuthProvider` owns the Supabase auth subscription, session restoration, authenticated user, loading/error state, and calls the adapter only when a draft marked `syncPending` exists. It cancels its stream subscription in `dispose`.

## Data Contract

The local draft stores schema version 1 and these fields:

- `assessment`: `id`, `version`, `answers`
- `blueprint`: `id`, `version`, `lanes`, `milestones`
- `actions`: `id`, `action_date`, `lane`, `title`, `description`, `completed_at`
- `archetype`, `timezone`, `journey_start_date`, `syncPending`

IDs are created and persisted at the same time as their domain data. The sync adapter never generates IDs during a cloud write.

## Cloud Sync

1. Resolve an IANA timezone with `flutter_timezone`; fall back to `UTC`.
2. Upsert the authenticated profile.
3. Upsert the assessment using its persisted ID.
4. Upsert the blueprint using its persisted ID and the assessment ID.
5. Upsert all daily actions using their persisted IDs.
6. Mark the draft as synced and remove its staged payload only after every prior write succeeds.

RLS remains the authorization boundary. The client always submits the authenticated user ID, which must match `auth.uid()` under the Foundation policies.

## UI Integration

Guest onboarding and blueprint reveal remain available without an account. The first attempt to lock daily actions or begin a streak presents an email account-conversion sheet. Email sign-up/sign-in is the Release 1 surface; Apple and Google provider methods are available in `AuthProvider` but their controls wait for the next UI release and provider dashboard configuration.

## Error Handling

Authentication failures stay in `AuthProvider.errorMessage` and never delete guest data. Sync failures are captured for retry, do not sign the user out, and leave the local draft untouched. The UI can surface a non-blocking retry control after account conversion.

## Testing

Unit tests cover draft ID persistence, successful sync cleanup, failure retention, and single-flight sync behavior. Provider tests cover guest initialization, authenticated session restoration, and error propagation. Widget tests cover the action-lock conversion trigger.

## Dependencies

- `provider`
- `supabase_flutter`
- `shared_preferences`
- `flutter_timezone`
- `uuid`

No Riverpod, server-side service key, or client-visible secret is permitted.

# ONO — Progress Roadmap

Last updated: August 2026

---

## Phase 1 — Core App Shell ✅

| Feature | Status |
|---------|--------|
| Splash screen with animated logo | ✅ Done |
| Onboarding welcome screen | ✅ Done |
| Archetype picker (6 archetypes) | ✅ Done |
| 10-question assessment flow | ✅ Done |
| Blueprint loading animation | ✅ Done |
| Blueprint reveal screen | ✅ Done |
| Home screen (The Nudge) | ✅ Done |
| Progress screen (The Shift) | ✅ Done |
| Profile screen | ✅ Done |
| Bottom navigation shell | ✅ Done |
| Dark theme + purple accents | ✅ Done |
| GoRouter with navigation | ✅ Done |

---

## Phase 2 — Backend & Auth ✅

| Feature | Status |
|---------|--------|
| Supabase project setup (10 tables, RLS) | ✅ Done |
| Email/password auth (sign up, sign in, sign out) | ✅ Done |
| Gateway pattern (abstract + mock + Supabase impls) | ✅ Done |
| Provider state management | ✅ Done |
| Auth redirect guard | ✅ Done |
| Dual entry points (mock vs production) | ✅ Done |
| Profile CRUD (name, notifications, delete) | ✅ Done |

---

## Phase 3 — AI & Daily Actions ✅

| Feature | Status |
|---------|--------|
| `generate-blueprint` Edge Function (Claude API) | ✅ Done |
| `seed-actions` Edge Function | ✅ Done |
| Daily action cards with toggle + haptics | ✅ Done |
| Auto-seed today's actions from blueprint | ✅ Done |
| Onboarding redirect (new user → archetype) | ✅ Done |
| DB trigger: auto streak update on completion | ✅ Done |
| DB trigger: lane score recalculation | ✅ Done |

---

## Phase 4 — Progress & Analytics ✅

| Feature | Status |
|---------|--------|
| Weekly bar chart (fl_chart) | ✅ Done |
| Lane progress bars (per-lane %) | ✅ Done |
| Stat cards (streak, overall score, days active) | ✅ Done |
| Strongest/weakest lane callout | ✅ Done |
| "Days into transformation" counter | ✅ Done |
| Pull-to-refresh on home + progress | ✅ Done |

---

## Phase 5 — Polish & Remaining ✅

| Feature | Status | Notes |
|---------|--------|-------|
| Native share sheet (share_plus) | ✅ Done | Profile → Share Ono uses OS share sheet |
| Theme picker (dark/light) | ✅ Done | Toggle in Settings, persists via SharedPreferences |
| Language selector | ⏳ Deferred | Settings item present, i18n not yet wired |
| Privacy Policy page | ✅ Done | Opens externally via url_launcher |
| About Ono dialog | ✅ Done | showAboutDialog with app info |
| Password reset flow | ✅ Done | Forgot-password screen + Supabase resetPasswordForEmail |
| Weekly snapshots generation | ✅ Done | `weekly-snapshot` Edge Function deployed |
| Body / Intellect / Social module content | ✅ Done | Real actions for all 4 lanes |
| Unit tests (providers) | ✅ Done | 6 test files: auth, profile, actions, progress, blueprint, theme |

---

## Phase 6 — Launch 🚀

| Feature | Status | Notes |
|---------|--------|-------|
| Push notifications (Firebase) | ❌ Not started | Daily nudge toggle exists in UI |
| App icon + splash branding | ✅ Done | Custom icons for iOS, Android, Web |
| App Store submission (iOS) | ❌ Not started | |
| Play Store submission (Android) | ❌ Not started | |

---

## Summary

| Phase | Progress |
|-------|----------|
| Phase 1 — Core Shell | ✅ Complete |
| Phase 2 — Backend & Auth | ✅ Complete |
| Phase 3 — AI & Actions | ✅ Complete |
| Phase 4 — Progress & Analytics | ✅ Complete |
| Phase 5 — Polish & Remaining | ✅ Complete (1 deferred) |
| Phase 6 — Launch | 1 / 3 |

**MVP is functional.** Phases 1–5 cover the full loop: onboard → generate blueprint → daily actions → track progress → polish. Phase 6 is launch prep — push notifications and store submissions remain.

---

## Phase 7 — Engagement & Growth 🔥

| Feature | Status | Notes |
|---------|--------|-------|
| Daily challenges (20 micro-challenges, XP rewards) | ✅ Done | Client-side, deterministic by day-of-year |
| Weekly challenges (8 stretch goals) | ✅ Done | Client-side, rotate weekly |
| Challenge card UI (accept → complete flow) | ✅ Done | Animated 3-state card with haptics |
| Streak celebrations (confetti at milestones) | ✅ Done | Milestones: 3, 7, 14, 21, 30, 60, 100, 365 days |
| Achievement badges (15 unlockable) | ✅ Done | Grid on profile, tap for detail |
| Reflection journal (bottom sheet after action) | ✅ Done | UI complete, persistence TODO |
| Weekly review screen | ✅ Done | Full breakdown with lane analysis + focus recommendation |
| FEATURES.md catalog | ✅ Done | 38 features documented |
| Challenge persistence (Supabase) | 🔜 Planned | XP tracking, accepted/completed state |
| Reflection persistence (Supabase) | 🔜 Planned | Journal view, browse by lane/date |
| XP & leveling system | 🔜 Planned | Level progression with titles |
| Habit heat map | 💡 Idea | GitHub-style contribution grid |
| Social / accountability partner | 💡 Idea | Pair with a friend |
| AI coach chat | 💡 Idea | Context-aware conversational coach |
| Custom user actions | 💡 Idea | Personal goals mixed with blueprint |

---

## Updated Summary

| Phase | Progress |
|-------|----------|
| Phase 1 — Core Shell | ✅ Complete |
| Phase 2 — Backend & Auth | ✅ Complete |
| Phase 3 — AI & Actions | ✅ Complete |
| Phase 4 — Progress & Analytics | ✅ Complete |
| Phase 5 — Polish & Remaining | ✅ Complete (1 deferred) |
| Phase 6 — Launch | 1 / 3 |
| Phase 7 — Engagement & Growth | 7 / 15 |

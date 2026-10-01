# ONO — Product Backlog & Roadmap

> **Last updated:** September 2026
> **Product:** ONO — Personal transformation app for young men (18–30)
> **Vision:** The app that makes you feel you're genuinely becoming the person you want to be — not someday, but today.

---

## How This Document Works

This backlog is structured in **tiers** — from critical bugs that block users right now, to ambitious features that will define ONO's long-term moat. Each item is tagged with the **expert domain** it needs consultancy from, so when we bring in specialists (fitness, finance, psychology, social dynamics, spirituality), they know exactly where to plug in.

**Priority tiers:**
- 🔴 **P0 — Ship-blocking** — Bugs and broken flows that lose users on Day 1
- 🟠 **P1 — Core value** — Features that make users say "this app gets it"
- 🟡 **P2 — Differentiation** — What makes ONO unbeatable vs. competitors
- 🟢 **P3 — Delight & scale** — Polish, virality, monetization

**Expert tags:**
- `[HEALTH]` — Fitness trainers, nutritionists, biohackers
- `[PSYCH]` — Psychologists, therapists, behavioral scientists
- `[FINANCE]` — Financial advisors, wealth coaches
- `[SOCIAL]` — Social skills coaches, dating coaches, communication experts
- `[SPIRITUAL]` — Meditation teachers, stoic philosophy practitioners
- `[TECH]` — Engineers, ML/AI specialists, data scientists
- `[DESIGN]` — UI/UX designers, motion designers, brand specialists
- `[CONTENT]` — Writers, researchers, social media trend analysts
- `[LEGAL]` — IP, celebrity likeness, user data compliance

---

## 🔴 P0 — Ship-Blocking (Fix Now)

### BUG-001: Social sign-in not working
**Status:** Auth gateway written, but Google/Apple client IDs not configured
**What's broken:**
- Google Sign-In: Missing `webClientId` and `iosClientId` in `supabase_auth_gateway.dart`
- Apple Sign-In: "Sign In with Apple" capability not enabled in Xcode, Apple provider not enabled in Supabase dashboard
- iOS URL scheme for Google not configured in `Info.plist`

**To fix:**
1. Create Google Cloud OAuth 2.0 client credentials (web + iOS)
2. Add client IDs to `supabase_auth_gateway.dart` (lines with `// TODO`)
3. Add iOS URL scheme `com.googleusercontent.apps.<CLIENT_ID>` to `Info.plist`
4. Enable Apple provider in Supabase Dashboard → Auth → Providers
5. Enable "Sign In with Apple" capability in Xcode → Signing & Capabilities
6. Test full sign-in → home screen flow for both providers

**Expert:** `[TECH]`
**Effort:** 2–4 hours (mostly config, no code changes)

---

### BUG-002: Reflection sheet feels broken / "Save reflection seems stupid"
**Status:** Reflection sheet appears after completing an action but save is a no-op
**What's broken:**
- `onSave` callback only calls `debugPrint` — nothing persists to Supabase
- The sheet feels intrusive — it pops up on every single action completion
- Content is generic, not contextual to the action or lane

**To fix:**
1. Create `reflections` table in Supabase (user_id, action_id, note, mood, created_at)
2. Wire `onSave` to insert into the table via a reflections gateway
3. Make the sheet optional — show a subtle "Add reflection?" chip instead of auto-popup
4. Make prompts lane-specific (body: "How did that feel physically?", mind: "What did you learn?")
5. Show reflection history in the journal screen

**Expert:** `[PSYCH]` `[TECH]`
**Effort:** 1 sprint

---

### BUG-003: iOS debug mode launch issue
**Status:** Known Flutter behavior — "In iOS 14+, debug mode apps can only be launched from Flutter tooling"
**Impact:** Not a code bug, but confusing for testing
**Workaround:** Always launch from Xcode or `flutter run`, or build in release mode

---

### BUG-004: Deprecated `withOpacity` warnings
**Status:** 35+ instances across 7 files (not build errors, but noisy)
**Files affected:**
- `lib/screens/onboarding_welcome_screen.dart` (2)
- `lib/widgets/streak_celebration.dart` (5)
- `lib/widgets/achievements_section.dart` (3)
- `lib/widgets/reflection_sheet.dart` (3)
- `lib/widgets/challenge_card.dart` (8)
- `lib/widgets/gradient_progress_ring.dart` (1)

**To fix:** Replace all `.withOpacity(x)` with `.withValues(alpha: x)` — mechanical find-replace
**Effort:** 1 hour

---

## 🟠 P1 — Core Value (This Sprint)

### FEAT-001: Comprehensive transformation journeys `[PSYCH]` `[HEALTH]` `[SPIRITUAL]`
**The problem:** "Our app gives less to turn into that person. We should be building a more comprehensive roadmap/journey to make him/her feel they're on the way."

**Current state:** 10 pre-built 30-day journeys with 3 phases each. Good start, but:
- Journeys are static — same actions every day regardless of progress
- No adaptive difficulty
- No branching based on user's weak lanes
- No real "transformation arc" feeling

**What we need (with expert input):**
- `[PSYCH]` Design the emotional arc — when to push hard, when to rest, when to celebrate
- `[HEALTH]` Progressive overload model — Week 1 body actions are easier than Week 4
- `[SPIRITUAL]` Meditation progression — from 2-min breathing to 20-min sessions
- `[TECH]` Adaptive engine that adjusts based on completion rate and lane scores
- Phase transitions should feel like leveling up (animation, unlocks, new content)
- Mid-journey check-ins: "You're 40% through. Here's how you've changed."
- End-of-journey reflection: before/after comparison of lane scores

**Deliverable:** Journey v2 system with adaptive phases, progressive difficulty, and emotional arc
**Effort:** 2–3 sprints

---

### FEAT-002: Notification system that actually motivates `[PSYCH]` `[DESIGN]`
**The problem:** "Building very motivating and interesting, dynamic, modern, animated notifications and notification center to motivate people to do what they committed."

**What to build:**
- **Smart timing:** Don't notify at 8 AM — notify when the user usually opens the app but hasn't yet
- **Contextual copy:** Not "Complete your actions" → "David Goggins wouldn't skip leg day. Neither should you." (tied to active journey)
- **Streak-at-risk alerts:** "You've been on fire for 12 days. Don't let today be the one that breaks it."
- **Social proof:** "1,247 ONO users already completed their actions today"
- **In-app notification center:** Beautiful feed of milestones, achievements, journey progress, and community highlights
- **Rich notifications:** Custom sounds, haptic patterns, inline action buttons
- **Animated in-app banners:** Slide-in celebrations when milestones are hit

**Expert input needed:**
- `[PSYCH]` What notification frequency keeps users engaged without causing burnout?
- `[PSYCH]` Positive reinforcement vs. loss aversion — which works better for 18–30 males?
- `[DESIGN]` Motion design for notification center and celebration animations

**Effort:** 2 sprints

---

### FEAT-003: Meditation & focus mode `[SPIRITUAL]` `[PSYCH]` `[TECH]`
**The problem:** "Meditation — what else can we do? Maybe block the screen or do something to facilitate meditation, providing music while blocking the screen."

**What to build:**
- **Focus Lock mode:** When user starts a meditation or deep work session, dim/lock the screen to a minimal timer view — no notifications, no distractions
- **Ambient soundscapes:** Rain, forest, bowls, lo-fi — no external API needed, bundle 5–8 high-quality 10-min loops as assets
- **Guided breathing:** Visual breathing circle (expand = inhale, hold, contract = exhale) with haptic rhythm
- **Progressive meditation journeys:** Day 1: 2 min. Day 30: 15 min. Guided → unguided progression
- **Post-session insight:** "You meditated for 8 minutes. Your average is 5. You're growing."
- **Screen blocking integration:** iOS Screen Time API or custom overlay that discourages leaving the app during a session

**Expert input needed:**
- `[SPIRITUAL]` Design a 30-day meditation curriculum (beginner → intermediate)
- `[PSYCH]` Optimal session lengths by experience level
- `[TECH]` iOS/Android background audio + screen lock feasibility

**Effort:** 2 sprints

---

### FEAT-004: Role model profile images `[LEGAL]` `[DESIGN]`
**The problem:** "We can use pics of public people as role models. Current design is so bad and not pro."

**Options (need legal review):**
1. **AI-generated stylized portraits** — Artistic/illustrated style (not photorealistic) of public figures. Safest legally. Can be branded as ONO's signature style.
2. **Licensed stock photos** — Some editorial-use photos available. Expensive per-image.
3. **Icon/silhouette style** — Abstract representations with signature items (Goggins: skull bandana, Jobs: turtleneck). Zero legal risk.
4. **User-submitted fan art** — Community-driven. Legal grey area.

**Recommendation:** Option 1 (AI-generated stylized art) + Option 3 fallback for legally sensitive figures.

**Expert input needed:**
- `[LEGAL]` Right of publicity laws per jurisdiction — can we use stylized AI portraits of public figures in a commercial app?
- `[DESIGN]` Create a consistent illustration style guide — all portraits should feel like the same "ONO universe"

**Effort:** 1–2 sprints (depends on legal clearance)

---

## 🟡 P2 — Differentiation (Next Quarter)

### FEAT-005: Trending celebrity & role model updates `[CONTENT]` `[TECH]`
**The problem:** "Create a service that does two weekly research for social networks to update the celebrity list — using technical job logic to get the list of celebrities or popular TikTokers or footballers turning into a star. We should be keeping the app attractive based on daily/weekly news."

**What to build:**
- **Backend service** (Supabase Edge Function + cron): Twice weekly, scrape trending figures from:
  - TikTok trending creators API / scraping
  - Twitter/X trending topics (sports, business, mindset)
  - Google Trends (rising personalities)
  - Sports APIs (breakout athletes, transfer news)
- **"Trending Now" section** on home screen — 3–5 figures that are having a moment
- **Auto-generated micro-profiles:** Quick role model cards for trending figures with AI-generated taglines and 3-day mini-challenges based on their recent achievement
- **Content team review:** AI generates drafts → human reviews before publish (no hallucinated quotes)
- **Push notification:** "Kylian Mbappé just broke the Champions League record. Try his 3-day speed challenge."

**Expert input needed:**
- `[CONTENT]` Which platforms matter most for 18–30 male audience? Prioritize sources.
- `[TECH]` API availability and rate limits for trend detection
- `[LEGAL]` Can we feature real people in "trending" without consent if it's editorial?

**Effort:** 3 sprints (backend infra + content pipeline + UI)

---

### FEAT-006: Location-based community & social proof `[SOCIAL]` `[TECH]`
**The problem:** "Consider using location and dream person data to match people and show how they are doing to make the app competitive."

**What to build:**
- **City leaderboards:** "Top 10 ONO users in Baku this week" — anonymous or opt-in display names
- **Nearby accountability partners:** Opt-in location sharing to find users on similar journeys within X km
- **Journey cohorts:** "127 people in your city started the Goggins challenge this week. Join them."
- **Dream person matching:** Users who chose the same role model → automatic group or chat channel
- **Heat map:** "ONO activity in your area" — gamified map showing where transformation is happening

**Expert input needed:**
- `[SOCIAL]` How do you design accountability without toxicity? Peer pressure vs. peer support.
- `[TECH]` Privacy-first location architecture — never store precise coordinates, use city/neighborhood granularity
- `[LEGAL]` GDPR/privacy implications of location-based social features

**Effort:** 3–4 sprints

---

### FEAT-007: Wakz-style social proof challenges `[SOCIAL]` `[CONTENT]` `[TECH]`
**The problem:** "Consider adding challenges in the logic of Wakz — taking pictures of book reading, using social proof."

**What to build:**
- **Photo proof challenges:** "Read 10 pages → snap a photo of the book" — verified with image recognition
- **Streak verification:** Optional daily selfie/photo to prove you did the action (gym check-in, meal prep, etc.)
- **Community feed:** See other users' proof photos (opt-in, anonymous or named)
- **Challenge battles:** 1v1 or group challenges — "Who can meditate more days this week?"
- **Badges & trophies** for verified completions (different from self-reported)
- **Integration with native camera** — quick capture → auto-tag lane and action

**Expert input needed:**
- `[SOCIAL]` How to prevent fake proofs without making verification annoying
- `[TECH]` On-device image classification to verify (is this actually a gym? a book?)
- `[CONTENT]` Design challenge formats that are fun, not tedious

**Effort:** 3 sprints

---

### FEAT-008: Expert-curated content verticals `[HEALTH]` `[FINANCE]` `[PSYCH]` `[SPIRITUAL]`
**The problem:** The app needs domain-specific depth from real experts, not just generic tips.

**What to build:**
- **Expert corner:** Short video/audio clips or written micro-lessons from consultants
- **Verticals with real curriculum:**
  - `[HEALTH]` 12-week body transformation program (progressive overload, nutrition, recovery)
  - `[FINANCE]` 30-day financial foundations (budgeting, investing basics, emergency fund)
  - `[PSYCH]` Confidence & social anxiety 8-week program
  - `[SPIRITUAL]` Stoic journaling + meditation 30-day reset
- **Expert Q&A:** Weekly AMA sessions (async — users submit, expert answers top 5)
- **Personalized recommendations:** Based on lane scores, suggest which expert content to engage with

**Effort:** Ongoing (content production pipeline)

---

## 🟢 P3 — Delight & Scale (Future)

### FEAT-009: AI personal coach
`[TECH]` `[PSYCH]`
On-demand chat with an AI that knows your journey, lane scores, streak, and goals. Not generic — it references your actual data: "You've been crushing Body this week but Mind dropped. Want a focus plan?"

### FEAT-010: Monetization layer
`[FINANCE]` `[TECH]`
Free tier: 1 active journey, basic challenges, daily actions. Premium: unlimited journeys, expert content, AI coach, community features, advanced analytics.

### FEAT-011: Apple Watch / wearable integration
`[HEALTH]` `[TECH]`
Auto-complete Body lane actions from HealthKit data (steps, workouts, sleep). Reduces friction dramatically.

### FEAT-012: Gamification v2
`[DESIGN]` `[PSYCH]`
XP system, levels, unlockable themes, avatar customization, seasonal events ("Summer Grind 2027 — 90 day mega-challenge").

### FEAT-013: Referral & viral loops
`[SOCIAL]` `[TECH]`
"Challenge a friend" share cards, referral rewards, shareable achievement cards for Instagram stories.

### FEAT-014: Localization
`[CONTENT]`
Turkish, Arabic, Russian, Spanish — key markets for the 18–30 male self-improvement audience.

---

## Expert Consultancy Plan

| Domain | What We Need | When | How |
|--------|-------------|------|-----|
| `[PSYCH]` Psychology | Emotional arc design for journeys, notification psychology, reflection prompts | P1 (now) | 2–3 sessions with behavioral psychologist |
| `[HEALTH]` Fitness | Progressive body programs, workout verification logic, nutrition basics | P1 (now) | Certified PT to design 12-week curriculum |
| `[SPIRITUAL]` Mindfulness | Meditation curriculum, breathing exercises, stoic philosophy integration | P1 (now) | Meditation teacher for 30-day program |
| `[SOCIAL]` Social dynamics | Accountability design, community moderation, social challenge formats | P2 (next quarter) | Social skills coach + community manager |
| `[FINANCE]` Financial literacy | 30-day money program, budgeting actions, investing micro-lessons | P2 (next quarter) | Certified financial planner |
| `[LEGAL]` IP & Privacy | Celebrity likeness rights, location data compliance, GDPR | P1 (before any images) | IP attorney consultation |
| `[DESIGN]` UI/UX | Role model portrait style, notification animations, onboarding redesign | P1 (now) | Motion designer + brand designer |
| `[CONTENT]` Trend research | Weekly celebrity/trend updates, social media monitoring setup | P2 (next quarter) | Content researcher (part-time) |

---

## Sprint Plan (Suggested)

**Sprint 1 (Current):** BUG-001 (social sign-in config), BUG-002 (reflections), BUG-004 (withOpacity cleanup)
**Sprint 2:** FEAT-002 (notifications v1), FEAT-003 (meditation/focus mode)
**Sprint 3:** FEAT-001 (journey v2 — adaptive), FEAT-004 (role model images — pending legal)
**Sprint 4:** FEAT-005 (trending celebrities backend), FEAT-006 (location/community — design phase)
**Sprint 5:** FEAT-007 (Wakz-style challenges), FEAT-008 (first expert vertical — Health)

---

## Competitive Landscape

| App | Strength | ONO Advantage |
|-----|----------|---------------|
| **Habitual / Habitify** | Habit tracking | ONO has identity (role models), not just checkboxes |
| **Headspace / Calm** | Meditation only | ONO covers all 4 lanes — mind, body, social, skill |
| **Strava / Nike Run Club** | Fitness social proof | ONO includes mental, social, and skill growth too |
| **Wakz** | Photo-proof challenges | ONO adds role model journeys + structured transformation arcs |
| **BetterMe** | Body focus | ONO is holistic — the whole man, not just the body |

**ONO's moat:** No other app combines role-model-based identity transformation across mind, body, social, and skill with adaptive journeys, social proof, and expert-curated content. The closest competitor is "a shelf of 5 different apps."

---

*This document is a living artifact. Update it after every consultancy session, sprint review, or user feedback round.*

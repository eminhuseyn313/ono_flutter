# ONO — Unified Product Roadmap

> **Last updated:** September 2026
> **Product:** ONO — Personal transformation app for young men (18–30)
> **Vision:** The app that makes you feel you're genuinely becoming the person you want to be — not someday, but today.
> **Source:** Merged from ONO_BACKLOG.md (operational items) and ONO_INNOVATION_LAB.md (innovation concepts). This is the single source of truth for what to build and when.

---

## Prioritization Methodology

Every item is scored on 5 weighted criteria:

| Criterion | Weight | Question |
|-----------|--------|----------|
| **User impact** | 30% | Does this make a user's day measurably better? |
| **Retention lift** | 25% | Will this bring people back tomorrow? |
| **Differentiation** | 20% | Can a competitor copy this in 2 weeks? |
| **Technical effort** | 15% | Can we ship a v1 in 1 sprint? (higher = easier) |
| **Expert dependency** | 10% | Do we need outside help? (higher = less dependency) |

Items are grouped into **5 phases** — from immediate fixes to long-term vision. Within each phase, items are ranked by weighted score.

**Expert tags:**
`[HEALTH]` Fitness/nutrition · `[PSYCH]` Psychology/behavioral science · `[FINANCE]` Financial literacy · `[SOCIAL]` Social dynamics · `[SPIRITUAL]` Meditation/philosophy · `[TECH]` Engineering/AI/ML · `[DESIGN]` UI/UX/motion · `[CONTENT]` Writers/researchers · `[LEGAL]` IP/privacy/compliance

---

## Phase 0: Ship-Blocking — Fix Now (Week 1)

> These are bugs and broken flows that lose users on Day 1. Nothing else matters until these are resolved.

### 0.1 — Social sign-in not working `[TECH]`
**ID:** BUG-001 · **Score:** N/A (blocker) · **Effort:** 2–4 hours

Google Sign-In and Apple Sign-In are coded but not configured. Users who prefer social auth (the majority of 18–30 males) hit a wall.

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

---

### 0.2 — Reflection sheet is broken / "Save reflection seems stupid" `[PSYCH]` `[TECH]`
**ID:** BUG-002 · **Score:** N/A (blocker) · **Effort:** 1 sprint

`onSave` callback only calls `debugPrint` — nothing persists. The sheet auto-pops on every action completion (annoying), and prompts are generic.

**To fix:**
1. Create `reflections` table in Supabase (user_id, action_id, note, mood, created_at)
2. Wire `onSave` to insert via a reflections gateway
3. Make the sheet optional — show a subtle "Add reflection?" chip instead of auto-popup
4. Make prompts lane-specific (Body: "How did that feel physically?" Mind: "What did you learn?")
5. Show reflection history in the journal screen

---

### 0.3 — Deprecated `withOpacity` warnings `[TECH]`
**ID:** BUG-004 · **Score:** N/A (cleanup) · **Effort:** 1 hour

35+ instances across 7 files. Not build errors, but noisy and unprofessional.

**Files:** onboarding_welcome_screen.dart (2), streak_celebration.dart (5), achievements_section.dart (3), reflection_sheet.dart (3), challenge_card.dart (8), gradient_progress_ring.dart (1)

**Fix:** Replace all `.withOpacity(x)` with `.withValues(alpha: x)` — mechanical find-replace.

---

### 0.4 — iOS debug mode launch issue `[TECH]`
**ID:** BUG-003 · **Score:** N/A (known) · **Effort:** 0 (workaround exists)

Known Flutter behavior — "In iOS 14+, debug mode apps can only be launched from Flutter tooling." Always launch from Xcode or `flutter run`, or build in release mode. Not a code bug.

---

## Phase 1: Core Value — The Foundation (Sprints 1–3)

> Features that make users say "this app gets it." These are what separate ONO from a to-do list with celebrity names.

### 1.1 — Apprentice Mode: "Can't do 100%? Do 10%." `[PSYCH]`
**ID:** INNOV-011 · **Score: 8.8** · **Effort:** 1–2 days · **Sprint:** 1

All-or-nothing thinking is the #1 reason people quit habit apps. A broken streak causes "what's the point" spiraling. Apprentice Mode reframes failure as reduced intensity rather than giving up.

**How it works:**
- If past 9 PM and < 50% of actions complete → gentle card: "Tough day? One action, two minutes, streak saved."
- One micro-action per weakest incomplete lane (10 pushups / read one page / send one compliment / write one learning)
- Streak is preserved with a modified marker (smaller flame, not full fire)
- Recovery bonus: Coming back to full mode after Apprentice Mode earns bonus Legacy points

**Needs from experts:**
- `[PSYCH]` Validate the "10% is infinitely more than 0%" framing with behavioral science literature

---

### 1.2 — Time Capsule: Letters From Your Past Self `[TECH]`
**ID:** INNOV-006 · **Score: 8.8** · **Effort:** 1–2 days · **Sprint:** 1

At journey start, write a letter to Day-30 you. The app locks it — unreadable until journey completion. On Day 30, you read your own words from 30 days ago. Emotionally powerful, zero engineering complexity.

**Build:**
- Day 1: "Write a letter to the person you'll be in 30 days"
- Day 15 (optional): "Write a progress letter"
- Day 30: Both letters unlock side-by-side
- Shareable completion card with journey stats

**Technical:** `time_capsules` table (user_id, journey_id, letter_text encrypted, unlock_day, created_at). Client-side lock: don't fetch decrypted text until `current_day >= unlock_day`.

---

### 1.3 — Monk Mode: Meditation That Takes Over Your Phone `[SPIRITUAL]` `[TECH]`
**ID:** INNOV-001 / FEAT-003 · **Score: 8.6** · **Effort:** 1 sprint (v1) · **Sprint:** 2

When you enter Monk Mode, ONO *becomes* your phone. Breathing circle + ambient soundscapes + exit friction + Focus Mode integration. Progressive unlocks over 30 days (guided → ambient → body scan → silent).

**v1 (ship in Sprint 2):** Breathing circle + timer + exit friction message + one ambient track. No Focus Mode integration, no progressive unlocks.

**v2 (Sprint 4):** iOS Focus Mode via `INSetFocusModeSettingIntent`, progressive unlocks, ambient-responsive flame via microphone amplitude metering.

**Needs from experts:**
- `[SPIRITUAL]` Design 30-day meditation curriculum (beginner → intermediate)
- `[PSYCH]` Optimal session lengths by experience level

---

### 1.4 — Legacy Score: Your Lifetime Transformation Metric `[TECH]` `[DESIGN]`
**ID:** INNOV-010 · **Score: 8.5** · **Effort:** 1 sprint · **Sprint:** 2

A single number that represents total transformation over all time. It never goes down. Milestone tiers: Initiate → Apprentice → Warrior → Master → Legend → Legacy.

**Build:**
- `legacy_scores` table + Supabase trigger on action completion
- `action_weights` table (meditation_10min = 15 pts, pushups_50 = 10 pts, etc.)
- Animated score display with tier progress bar
- At 1,000 pts: unlock special theme. At 5,000: "Mentor Mode." At 10,000: custom badge.

---

### 1.5 — Notification System That Actually Motivates `[PSYCH]` `[DESIGN]`
**ID:** FEAT-002 · **Score: 8.0** · **Effort:** 2 sprints · **Sprint:** 2–3

Not "Complete your actions" → "David Goggins wouldn't skip leg day. Neither should you."

**Build:**
- Smart timing (notify when user usually opens but hasn't yet)
- Contextual copy tied to active journey and role model
- Streak-at-risk alerts ("12-day fire. Don't let today break it.")
- Social proof ("1,247 ONO users already completed their actions today")
- Animated in-app celebration banners
- Rich notifications with custom sounds and haptic patterns

**Needs from experts:**
- `[PSYCH]` Optimal notification frequency. Positive reinforcement vs. loss aversion for 18–30 males.
- `[DESIGN]` Motion design for notification center and celebration animations

---

### 1.6 — The Becoming Arc: 5-Layer Transformation Journeys `[PSYCH]` `[HEALTH]` `[SPIRITUAL]`
**ID:** INNOV-003 / FEAT-001 · **Score: 7.9** · **Effort:** 2–3 sprints · **Sprint:** 2–4

Every journey gets 5 layers (Identity → Habit → Knowledge → Challenge → Reflection), not just daily checkboxes. Adaptive difficulty engine. Self-assessment at Day 1/15/30 with before/after visualization. Phase transitions that feel like leveling up.

**Needs from experts:**
- `[PSYCH]` Design the emotional arc — when to push hard, when to rest, when to celebrate
- `[HEALTH]` Progressive overload model — Week 1 body actions easier than Week 4
- `[SPIRITUAL]` Meditation progression — from 2-min breathing to 20-min sessions

---

### 1.7 — Compound Effect Visualizer `[TECH]` `[DESIGN]`
**ID:** INNOV-007 · **Score: 7.9** · **Effort:** 2–3 days · **Sprint:** 1

"At your current pace, in 365 days you will have: meditated for 91 hours, done 7,300 pushups, read 36 books." Animated number ticker. Trajectory modes (conservative/current/best week). Milestone date markers.

**Technical:** Pure client-side calculation. No backend changes. Animated counter with `TweenAnimationBuilder`. Hardcoded comparison benchmarks.

---

### 1.8 — Role Model Profile Images `[LEGAL]` `[DESIGN]`
**ID:** FEAT-004 · **Score: 7.5** · **Effort:** 1–2 sprints · **Sprint:** 3 (pending legal)

Current design is "so bad and not pro." Recommended approach: AI-generated stylized portraits (artistic, not photorealistic) as ONO's signature style. Icon/silhouette fallback for legally sensitive figures.

**Needs from experts:**
- `[LEGAL]` Right of publicity laws — can we use stylized AI portraits in a commercial app?
- `[DESIGN]` Consistent illustration style guide — all portraits should feel like the same "ONO universe"

---

## Phase 2: Differentiation — The Moat (Sprints 4–7)

> What makes ONO unbeatable vs. competitors. These features create defensible differentiation.

### 2.1 — The Council: AI-Powered Multi-Role-Model Advice `[TECH]` `[PSYCH]`
**ID:** INNOV-015 · **Score: 8.3** · **Effort:** 1–2 sprints · **Sprint:** 4

Ask a question, get perspectives from multiple role model AI personas. "I want to start a business but I'm scared." → Goggins says fight, Naval says iterate, Aurelius says focus on effort. No competitor has this.

**Build:**
- Claude API with system prompts per role model (philosophy, style, principles)
- `council_sessions` table (user_id, question, responses_json, created_at)
- Rate limiting: 3 questions/day (free), unlimited (premium)
- Safety: Redirect financial/legal/medical queries to real professionals

---

### 2.2 — The Ritual: Morning & Evening Routine Flows `[PSYCH]` `[SPIRITUAL]`
**ID:** INNOV-013 · **Score: 7.8** · **Effort:** 1 sprint · **Sprint:** 4

Bundle 3–5 actions into a timed, full-screen flow. Morning Ritual (affirmation → movement → mind primer → intention) and Evening Ritual (gratitude → reflection → tomorrow prep → wind-down). Reduces decision fatigue. Creates "I do my ritual" identity.

**Build:**
- `rituals` table (user_id, ritual_type, steps_json, preferred_time)
- Flow UI: PageView with auto-advance timer + manual skip
- Integration: Ritual completion marks individual actions as done
- Notification: "Your Morning Ritual is ready" at user-set time

---

### 2.3 — Ghost Mode: Compete Against Your Past Self `[TECH]`
**ID:** INNOV-014 · **Score: 7.8** · **Effort:** 3–5 days · **Sprint:** 4

See last week's you as a "ghost" line on your progress chart. Your only competition is the person you were 7 days ago. Weekly "Beat Your Ghost" challenge. Monthly comparison visualization.

**Build:** Extends existing `weekly_snapshots` in ProgressProvider. Client-side overlay chart. No new backend logic.

---

### 2.4 — Contextual Time-of-Day Modes `[DESIGN]`
**ID:** INNOV-009 · **Score: 7.7** · **Effort:** 3–5 days · **Sprint:** 5

Dawn Mode (4–7 AM): warm sunrise gradient, "Early Bird" bonus action, morning discipline quotes. Day Mode: standard. Evening Mode (6–9 PM): warmer tones, evening actions surfaced first, "prepare for tomorrow" card. Night Mode (9 PM–4 AM): amber accents, slow animations, reflection focus, sleep reminder.

**Build:** Client-side `DateTime.now().hour` check in theme provider. 4 gradient presets, 4 quote pools. No backend changes.

---

### 2.5 — The Brotherhood: Anonymous Squad Accountability `[SOCIAL]` `[TECH]`
**ID:** INNOV-004 / FEAT-006 · **Score: 7.3** · **Effort:** 2–3 sprints · **Sprint:** 5–6

Auto-matched with 4 users on the same journey. Anonymous avatars ("Warrior #3"). See their streaks and completion rates. Gentle social pressure when someone falls behind. Optional photo proof (verified by on-device ML).

**Needs from experts:**
- `[SOCIAL]` How to design accountability without toxicity? Peer pressure vs. peer support.
- `[TECH]` Privacy-first architecture — never store precise coordinates

---

### 2.6 — Mirror Match: Your Transformation Twin `[TECH]` `[PSYCH]`
**ID:** INNOV-005 · **Score: 7.0** · **Effort:** 1–2 sprints · **Sprint:** 6

Find users who had similar starting scores 30/60/90 days ago. See their anonymous progress trajectory. Statistical proof that transformation works. Optional 1:1 anonymous chat with someone 30 days ahead of you.

**Build:**
- Matching algorithm: Euclidean distance across normalized lane scores + role model affinity
- "Path Proof" visualization: Line chart of Mirror's trajectory from Day 1 (similar to yours) to now
- Anonymous chat via Supabase Realtime

---

### 2.7 — Trending Celebrity & Role Model Updates `[CONTENT]` `[TECH]`
**ID:** INNOV-002 / FEAT-005 · **Score: 6.7** · **Effort:** 3 sprints · **Sprint:** 5–7

"The Pulse" — twice-weekly automated scan of Google Trends, Twitter/X, sports APIs, TikTok, YouTube. Auto-generated micro-profiles with 3-day mini-challenges mapped to ONO's 4 lanes. Human review before publish. 7-day TTL auto-expiry.

**v1:** Manual curation. One person, 30 minutes twice a week, 5 trending figures.
**v2:** Supabase Edge Function + cron + Claude API for auto-generation.

**Needs from experts:**
- `[CONTENT]` Which platforms matter most for 18–30 male audience?
- `[TECH]` API availability and rate limits for trend detection
- `[LEGAL]` Can we feature real people in "trending" without consent if it's editorial?

---

### 2.8 — The Forge: Skill-Building Micro-Courses `[CONTENT]` `[TECH]`
**ID:** INNOV-012 · **Score: 6.7** · **Effort:** 2–3 sprints · **Sprint:** 6–7

Transform Skill lane from checkboxes into 5-minute interactive micro-lessons. Each role model's Skill actions link to bite-sized lessons: scenarios, timed exercises, comprehension checks, interactive worksheets.

**v1:** 3 role models × 5 micro-courses = 15 total. Custom Flutter widget tree that interprets content_json blocks.

**Needs from experts:** Subject matter experts per domain + content writers.

---

### 2.9 — Wakz-Style Social Proof Challenges `[SOCIAL]` `[CONTENT]` `[TECH]`
**ID:** FEAT-007 · **Score: 6.5** · **Effort:** 3 sprints · **Sprint:** 7

Photo proof challenges: "Read 10 pages → snap a photo of the book." On-device image classification to verify (is this a gym? a book?). Community feed (opt-in). Challenge battles (1v1 or group). Badges for verified completions.

**Needs from experts:**
- `[SOCIAL]` How to prevent fake proofs without annoying verification
- `[TECH]` On-device image classification (TensorFlow Lite)

---

### 2.10 — Role Model Radio: Curated Media `[CONTENT]`
**ID:** INNOV-008 · **Score: 6.3** · **Effort:** 1 sprint + ongoing · **Sprint:** 5

Three channels per role model: Their Words (podcast links), Their Soundtrack (Spotify playlists), Their Library (books). Deep links to Spotify/YouTube/Apple Podcasts. Context-aware (morning → energizing, evening → reflective).

**Revenue:** Affiliate links to books via Amazon Associates (4.5% commission).

---

## Phase 3: Expert-Powered Content (Sprints 6–10)

> Domain-specific depth from real experts. This is what transforms ONO from a tech product into a transformation platform.

### 3.1 — Expert-Curated Content Verticals `[HEALTH]` `[FINANCE]` `[PSYCH]` `[SPIRITUAL]`
**ID:** FEAT-008 · **Effort:** Ongoing (content production pipeline)

- `[HEALTH]` 12-week body transformation program (progressive overload, nutrition, recovery)
- `[FINANCE]` 30-day financial foundations (budgeting, investing basics, emergency fund)
- `[PSYCH]` Confidence & social anxiety 8-week program
- `[SPIRITUAL]` Stoic journaling + meditation 30-day reset
- Expert Q&A: Weekly AMA sessions (async — users submit, expert answers top 5)
- Personalized recommendations based on lane scores

---

## Phase 4: Delight & Scale (Sprints 8–12+)

> Polish, virality, and monetization. These turn a great product into a business.

### 4.1 — AI Personal Coach `[TECH]` `[PSYCH]`
**ID:** FEAT-009 · **Effort:** 2–3 sprints

On-demand chat with an AI that knows your journey, lane scores, streak, and goals. References your actual data: "You've been crushing Body this week but Mind dropped. Want a focus plan?" Built on Claude API with full user context.

### 4.2 — Monetization Layer `[FINANCE]` `[TECH]`
**ID:** FEAT-010 · **Effort:** 2 sprints

**Free tier:** 1 active journey, basic challenges, daily actions, Apprentice Mode, 1 Council question/day.

**Premium ($7.99/month or $59.99/year):**
- Unlimited journeys
- Full Council access (unlimited questions)
- All ambient soundscapes for Monk Mode
- Expert content verticals
- Advanced analytics (Ghost Mode, Compound Visualizer)
- Community features (The Brotherhood, Mirror Match)
- Role Model Radio
- Custom themes and Legacy badges

**Revenue projections (conservative):**
- 10,000 free users × 5% conversion = 500 premium users
- 500 × $7.99/month = $3,995/month
- With growth to 50,000 users: $19,975/month

### 4.3 — Apple Watch / Wearable Integration `[HEALTH]` `[TECH]`
**ID:** FEAT-011 · **Effort:** 2 sprints

Auto-complete Body lane actions from HealthKit data (steps, workouts, sleep). Reduces friction dramatically. Glanceable Legacy Score on watch face.

### 4.4 — Gamification v2 `[DESIGN]` `[PSYCH]`
**ID:** FEAT-012 · **Effort:** 2–3 sprints

XP system integrated with Legacy Score. Unlockable themes. Avatar customization. Seasonal events ("Summer Grind 2027 — 90-day mega-challenge"). Leaderboards (anonymous, opt-in).

### 4.5 — Referral & Viral Loops `[SOCIAL]` `[TECH]`
**ID:** FEAT-013 · **Effort:** 1–2 sprints

"Challenge a friend" share cards. Referral rewards (both get +50 Legacy points). Shareable achievement cards for Instagram Stories. "This Week in Greatness" shareable digest. Journey completion certificates.

### 4.6 — Localization `[CONTENT]`
**ID:** FEAT-014 · **Effort:** 1 sprint per language + ongoing

Turkish, Arabic, Russian, Spanish — key markets for the 18–30 male self-improvement audience. RTL support for Arabic. Localized role models per region.

---

## Sprint Allocation Plan

| Sprint | Duration | Items | Focus |
|--------|----------|-------|-------|
| **Sprint 1** | 2 weeks | BUG-001, BUG-002, BUG-004, Apprentice Mode, Time Capsule, Compound Visualizer | Fix blockers + quick wins with maximum emotional impact |
| **Sprint 2** | 2 weeks | Monk Mode v1, Legacy Score, Notifications v1 | Core meditation + retention hooks + engagement system |
| **Sprint 3** | 2 weeks | Notifications v2, Becoming Arc (Phase 1), Role Model Images (if legal cleared) | Journey depth + professional visual identity |
| **Sprint 4** | 2 weeks | The Council, The Ritual, Ghost Mode, Becoming Arc (Phase 2) | AI differentiation + daily structure + self-competition |
| **Sprint 5** | 2 weeks | Time-of-Day Modes, Brotherhood v1, Role Model Radio, Trending v1 (manual) | Contextual UI + social foundation + content freshness |
| **Sprint 6** | 2 weeks | Mirror Match, The Forge v1, Becoming Arc (Phase 3 — adaptive engine) | Social matching + micro-learning + adaptive journeys |
| **Sprint 7** | 2 weeks | Wakz Challenges, Trending v2 (automated), The Forge expansion | Photo proof + automated content pipeline |
| **Sprint 8** | 2 weeks | Expert Health Vertical, AI Coach v1 | First expert content + AI personalization |
| **Sprint 9** | 2 weeks | Monetization Layer, Expert Finance Vertical | Revenue + financial content |
| **Sprint 10** | 2 weeks | Apple Watch, Referral System | Wearable integration + growth engine |
| **Sprint 11–12** | 4 weeks | Gamification v2, Localization (Turkish first), Seasonal events | Polish + international expansion |

---

## Expert Consultancy Plan

| Domain | What We Need | When | How | Items Affected |
|--------|-------------|------|-----|----------------|
| `[PSYCH]` | Emotional arc design, notification psychology, reflection prompts, Apprentice Mode validation | Sprint 1 (now) | 2–3 sessions with behavioral psychologist | 1.1, 1.5, 1.6, 2.2, 2.6 |
| `[HEALTH]` | Progressive body programs, workout verification logic, nutrition basics | Sprint 2–3 | Certified PT to design 12-week curriculum | 1.6, 3.1 |
| `[SPIRITUAL]` | Meditation curriculum, breathing exercises, stoic philosophy integration | Sprint 2 | Meditation teacher for 30-day program | 1.3, 1.6, 2.2, 3.1 |
| `[LEGAL]` | Celebrity likeness rights, location data compliance, GDPR | Sprint 1 (before images) | IP attorney consultation | 1.8, 2.7 |
| `[DESIGN]` | Role model portrait style, notification animations, onboarding redesign | Sprint 2–3 | Motion designer + brand designer | 1.5, 1.8 |
| `[SOCIAL]` | Accountability design, community moderation, social challenge formats | Sprint 5 | Social skills coach + community manager | 2.5, 2.9 |
| `[FINANCE]` | 30-day money program, budgeting actions, investing micro-lessons | Sprint 9 | Certified financial planner | 3.1, 4.2 |
| `[CONTENT]` | Weekly celebrity/trend updates, micro-course content, Role Model Radio curation | Sprint 5 (ongoing) | Content researcher (part-time) | 2.7, 2.8, 2.10 |

---

## Competitive Landscape

| App | Strength | ONO Advantage |
|-----|----------|---------------|
| **Habitual / Habitify** | Habit tracking | ONO has identity (role models + Becoming Arc), not just checkboxes |
| **Headspace / Calm** | Meditation only | ONO's Monk Mode is integrated into 4-lane transformation, not standalone |
| **Strava / Nike Run Club** | Fitness social proof | ONO includes mental, social, and skill growth — the whole person |
| **Wakz** | Photo-proof challenges | ONO adds The Brotherhood (anonymous), The Council (AI), and transformation arcs |
| **BetterMe** | Body focus | ONO is holistic — mind, body, social, skill with adaptive journeys |
| **Finch / Forest** | Gamified self-care | ONO has real role models, Legacy Score, and expert-curated content depth |

**ONO's moat:** No other app combines role-model-based identity transformation across mind, body, social, and skill with adaptive journeys, AI Council, anonymous accountability, and expert-curated content. The closest competitor is "a shelf of 6 different apps."

**Unique features no competitor has:**
1. The Council (AI multi-role-model advice)
2. The Becoming Arc (5-layer adaptive journeys)
3. Apprentice Mode (streak-saving micro-actions)
4. Legacy Score (lifetime never-decreasing metric)
5. Time Capsule (locked self-letters)
6. Ghost Mode (compete against past self)
7. Time-of-Day contextual personality shifts

---

## Key Metrics to Track

| Metric | Current | Sprint 3 Target | Sprint 6 Target | Sprint 12 Target |
|--------|---------|-----------------|-----------------|------------------|
| DAU/MAU ratio | — | 30% | 45% | 60% |
| D7 retention | — | 40% | 55% | 65% |
| D30 retention | — | 20% | 35% | 45% |
| Avg. daily actions completed | — | 2.5 | 4.0 | 5.5 |
| Journey completion rate | — | 15% | 30% | 45% |
| Apprentice Mode saves/week | — | — | 500 | 2,000 |
| Legacy Score avg (active users) | — | 50 | 300 | 1,500 |
| Premium conversion rate | — | — | 3% | 7% |
| NPS | — | 30 | 50 | 65 |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Celebrity likeness legal issues | Medium | High | AI-generated stylized art + legal review before launch |
| Low user acquisition | Medium | High | Focus on referral loops + shareable moments (Time Capsule, Compound Visualizer) |
| Expert consultancy costs | Medium | Medium | Start with 1 expert per domain, async sessions. Budget ~$5K for Phase 1 |
| AI Council generates harmful advice | Low | High | System prompt guardrails + redirect medical/legal/financial to professionals |
| Content staleness (Trending) | Medium | Medium | Manual v1 is sustainable at 30 min/2x week. Automate only after proving format |
| Notification burnout | Medium | Medium | `[PSYCH]` consultant sets frequency caps. Easy opt-out per category |
| Squad member dropout (Brotherhood) | High | Low | Silent replacement within 24 hours. Minimum 3 active members to sustain squad |

---

*This roadmap is a living document. Update it after every consultancy session, sprint review, or user feedback round. Innovation Lab ideas that score above 7.0 auto-graduate here. Items below 6.0 stay in the lab for incubation.*

*Source documents: ONO_INNOVATION_LAB.md (creative concepts), ONO_BACKLOG.md (operational detail). This file supersedes both for prioritization and sprint planning.*

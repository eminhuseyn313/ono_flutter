# ONO Expert Domain Index

## Overview
Nine expert domain guidelines governing quality, safety, and consultant engagement for the ONO personal transformation app. Each file defines standards a real consultant can immediately act on.

**Target Users**: Males 18-30 | **Lanes**: Mind, Body, Social, Skill

---

## Expert Files

| # | File | Tag | One-Line Description |
|---|------|-----|----------------------|
| 1 | [EXPERT_PSYCHOLOGY.md](./EXPERT_PSYCHOLOGY.md) | `[PSYCH]` | Habit formation, emotional arcs, notification psychology, Apprentice Mode, all-or-nothing prevention |
| 2 | [EXPERT_HEALTH.md](./EXPERT_HEALTH.md) | `[HEALTH]` | Workout programming, progressive overload, nutrition, recovery, injury prevention for Body lane |
| 3 | [EXPERT_SPIRITUAL.md](./EXPERT_SPIRITUAL.md) | `[SPIRITUAL]` | Meditation curriculum, breathwork, stoic philosophy, mindfulness progression for Mind lane |
| 4 | [EXPERT_SOCIAL.md](./EXPERT_SOCIAL.md) | `[SOCIAL]` | Accountability design, community moderation, peer support vs. pressure, identity model |
| 5 | [EXPERT_FINANCE.md](./EXPERT_FINANCE.md) | `[FINANCE]` | Budgeting, investing basics, debt management, financial literacy for Skill lane |
| 6 | [EXPERT_TECH.md](./EXPERT_TECH.md) | `[TECH]` | Flutter/Dart, Supabase, Claude API integration, image classification, privacy-first architecture |
| 7 | [EXPERT_DESIGN.md](./EXPERT_DESIGN.md) | `[DESIGN]` | Dark theme (#0A0C14), purple accent (#8B5CF6), glassmorphism, motion design, celebration animations |
| 8 | [EXPERT_CONTENT.md](./EXPERT_CONTENT.md) | `[CONTENT]` | Role model curation, trending content (7-day TTL), micro-courses, tone of voice, moderation |
| 9 | [EXPERT_LEGAL.md](./EXPERT_LEGAL.md) | `[LEGAL]` | Celebrity likeness, GDPR, location privacy, AI disclaimers, content moderation liability |

---

## Roadmap Impact Matrix

Which experts are needed for which areas of the product roadmap:

### Apprentice Mode (First 21 Days)
- `[PSYCH]` — Onboarding psychology, habit formation scaffolding, exit criteria validation
- `[HEALTH]` — Beginner-safe Body lane programming
- `[SPIRITUAL]` — Introductory meditation and breathwork sequences
- `[DESIGN]` — First-run experience, progressive disclosure UI
- `[CONTENT]` — Onboarding micro-course content and tone

### Mind Lane
- `[SPIRITUAL]` — Primary: meditation curriculum, breathwork, stoic philosophy
- `[PSYCH]` — Reflection prompt design, emotional arc across the lane
- `[CONTENT]` — Micro-course writing for philosophical and mindfulness content
- `[DESIGN]` — Mind lane visual theming (indigo #818CF8)

### Body Lane
- `[HEALTH]` — Primary: all workout programming, nutrition, recovery
- `[TECH]` — Workout verification (image classification), exercise tracking
- `[PSYCH]` — Body image sensitivity, progress framing without dysmorphia triggers
- `[DESIGN]` — Body lane visual theming (orange #F97316)
- `[LEGAL]` — Health disclaimer requirements

### Social Lane
- `[SOCIAL]` — Primary: accountability systems, moderation, community design
- `[PSYCH]` — Peer pressure vs. support psychology, social anxiety considerations
- `[TECH]` — Real-time features, presence channels, notification delivery
- `[LEGAL]` — Content moderation liability, user data in social contexts
- `[DESIGN]` — Social lane visual theming (cyan #06B6D4)

### Skill Lane
- `[FINANCE]` — Financial literacy track content
- `[CONTENT]` — Micro-course writing across all skill domains
- `[PSYCH]` — Learning psychology, skill acquisition motivation
- `[DESIGN]` — Skill lane visual theming (purple #8B5CF6)

### Notification System
- `[PSYCH]` — Notification timing, tone, frequency caps, escalation psychology
- `[DESIGN]` — Notification animations, visual feedback patterns
- `[TECH]` — FCM/APNs delivery, Edge Function orchestration

### Role Model / Trending Content
- `[CONTENT]` — Primary: research methodology, curation, 7-day TTL enforcement
- `[LEGAL]` — Celebrity likeness, right of publicity, fair use analysis
- `[PSYCH]` — Role model selection psychology, avoiding parasocial dynamics

### AI Features (Claude Integration)
- `[TECH]` — API integration, prompt safety, cost control, proxy architecture
- `[LEGAL]` — AI-generated content disclaimers, liability limitations
- `[PSYCH]` — AI coaching tone, boundary between tool and therapist
- `[CONTENT]` — AI content quality standards, tone consistency

### Data & Privacy
- `[LEGAL]` — Primary: GDPR, CCPA, data processing agreements, breach response
- `[TECH]` — Encryption, access control, data minimization implementation
- `[SOCIAL]` — Anonymous identity protection, social data handling

### Streak & Reward Mechanics
- `[PSYCH]` — Primary: intrinsic vs. extrinsic motivation, streak freeze design
- `[DESIGN]` — Celebration animations, progress visualization
- `[CONTENT]` — Achievement copy, milestone messaging tone

---

## How to Use This Index

1. **Starting a new feature**: Check the matrix above to identify which expert domains apply
2. **Hiring a consultant**: Open the relevant expert file, use the Consultant Brief Template at the bottom
3. **Content review**: Match content to the appropriate expert file's Quality Standards and Red Flags
4. **Cross-domain conflicts**: When two expert domains give conflicting guidance, `[PSYCH]` and `[LEGAL]` take precedence on safety matters; `[DESIGN]` takes precedence on visual/interaction decisions

## Consultant Engagement Priority

For initial launch, engage in this order:
1. `[LEGAL]` — Foundational; blocks launch if non-compliant
2. `[PSYCH]` — Foundational; affects every feature's emotional safety
3. `[HEALTH]` — High liability; Body lane needs clinical validation
4. `[CONTENT]` — Tone of voice sets the product's identity
5. `[TECH]` — Architecture review before scale
6. `[DESIGN]` — Visual polish after core UX is validated
7. `[SPIRITUAL]` — Curriculum depth after initial content is live
8. `[SOCIAL]` — Community features typically launch after core app
9. `[FINANCE]` — Skill lane financial track can follow initial launch

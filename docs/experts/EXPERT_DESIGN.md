# [DESIGN] Expert Domain: Visual & Motion Design

## Purpose
Define and protect ONO's visual identity — dark-theme UI, purple accent system, typography, motion design, and celebration animations. Ensure every screen feels premium, cohesive, and distinctly ONO. The design language must appeal to 18-30 males without relying on aggressive or hyper-masculine aesthetics.

## Scope Within ONO
- **Visual Identity**: Color system, typography, spacing, iconography
- **Component Library**: Glassmorphic cards, gradient backgrounds, interactive elements
- **Motion Design**: Transitions, micro-interactions, celebration animations
- **Notification Animations**: Contextual visual feedback for achievements and nudges
- **Lane-Specific Theming**: Visual differentiation across Mind, Body, Social, Skill
- **Dark Theme System**: Primary dark palette with accessible contrast ratios

## Quality Standards
1. All color combinations must meet WCAG 2.1 AA contrast ratios (4.5:1 text, 3:1 UI elements)
2. Animations must not exceed 300ms for micro-interactions, 500ms for page transitions
3. All animations must respect `prefers-reduced-motion` system setting
4. Glassmorphic effects must degrade gracefully on lower-end devices
5. Typography hierarchy must be consistent — no more than 3 font weights per screen
6. Dark theme must avoid pure black (#000000) — use deep navy/charcoal for depth
7. Purple accent usage must be intentional — CTAs, progress indicators, achievements — never decorative noise

## Core Design Tokens

### Colors
| Token | Value | Usage |
|-------|-------|-------|
| `background-primary` | `#0A0C14` | Main app background |
| `background-secondary` | `#12141E` | Card backgrounds, elevated surfaces |
| `background-tertiary` | `#1A1D2E` | Input fields, secondary cards |
| `accent-primary` | `#8B5CF6` | Primary CTA, active states, progress |
| `accent-secondary` | `#A78BFA` | Secondary actions, hover states |
| `accent-tertiary` | `#C4B5FD` | Subtle highlights, disabled accent |
| `text-primary` | `#F1F5F9` | Headings, primary text |
| `text-secondary` | `#94A3B8` | Body text, descriptions |
| `text-tertiary` | `#64748B` | Placeholder text, timestamps |
| `success` | `#10B981` | Completion, positive feedback |
| `warning` | `#F59E0B` | Caution states, partial completion |
| `error` | `#EF4444` | Errors, destructive actions |

### Lane Colors
| Lane | Primary | Gradient Start | Gradient End |
|------|---------|---------------|--------------|
| Mind | `#818CF8` | `#6366F1` | `#818CF8` |
| Body | `#F97316` | `#EA580C` | `#F97316` |
| Social | `#06B6D4` | `#0891B2` | `#06B6D4` |
| Skill | `#8B5CF6` | `#7C3AED` | `#8B5CF6` |

### Typography
- **Font Family**: Plus Jakarta Sans (Google Fonts, variable weight)
- **Heading 1**: 28px / 700 weight / -0.02em tracking
- **Heading 2**: 22px / 600 weight / -0.01em tracking
- **Body**: 16px / 400 weight / 0 tracking
- **Caption**: 13px / 500 weight / 0.01em tracking
- **Mono (stats)**: JetBrains Mono, 14px / 400 weight

## Review Checklist
- [ ] Do all interactive elements have visible focus states for accessibility?
- [ ] Are glassmorphic blur effects GPU-accelerated (BackdropFilter in Flutter)?
- [ ] Does the celebration animation complete in under 2 seconds?
- [ ] Is the gradient usage consistent with the lane color system?
- [ ] Do cards maintain readable contrast when overlaid on gradient backgrounds?
- [ ] Are touch targets at minimum 44x44dp?
- [ ] Does the design work on screens from 320dp to 428dp width?
- [ ] Are all icons from a single system (Lucide, Phosphor, or custom set)?

## Content Guidelines
### Glassmorphic Cards
- Background: `background-secondary` with 0.6-0.8 opacity
- Blur: 12-20px backdrop blur
- Border: 1px solid `rgba(255, 255, 255, 0.08)`
- Border radius: 16px for cards, 12px for nested elements
- Shadow: `0 4px 24px rgba(0, 0, 0, 0.3)` — subtle depth, never heavy

### Gradient Backgrounds
- Screen backgrounds: Radial gradient from lane color (10% opacity) over `background-primary`
- Cards: Linear gradient at 135deg for progress indicators and achievement badges
- Never: Full-opacity gradients as text backgrounds (readability risk)

### Motion Design Principles
- **Enter**: Fade + slide up (200ms ease-out) for content loading
- **Exit**: Fade out (150ms ease-in) — exits faster than enters
- **Celebration**: Scale bounce (1.0 → 1.15 → 1.0) + particle burst for achievements
- **Progress**: Smooth fill animation (400ms ease-in-out) for progress bars
- **Haptics**: Light impact on button press, medium on achievement, none on navigation
- **Spring Physics**: Use spring curves for draggable elements (damping 0.7, stiffness 300)

### Notification Animations
- **Achievement**: Purple glow pulse + confetti particles (lane-colored)
- **Reminder**: Subtle slide-in from top, no disruptive animation
- **Social**: Avatar bounce-in for accountability partner messages
- **Streak**: Flame icon with animated gradient on milestone days (7, 30, 90)

### Celebration Animations
- Keep under 2 seconds total duration
- Particle count: 20-40 for minor achievements, 60-100 for milestones
- Sound: Optional, always respecting device silent mode
- Screen takeover: Never — celebrations overlay current content without blocking interaction

## Red Flags to Avoid
- **Pure black backgrounds**: Creates harsh contrast, feels lifeless — use deep navy/charcoal
- **Neon/cyberpunk aesthetics**: Trendy but fatiguing for daily use
- **Aggressive masculine design**: Skulls, flames, military themes, "war room" metaphors
- **Overly complex glassmorphism**: Multiple stacked blur layers destroy performance
- **Inconsistent spacing**: Must use 4px base grid (4, 8, 12, 16, 24, 32, 48)
- **Decorative animation**: Every animation must communicate something — progress, completion, transition
- **Font variety**: Stick to Plus Jakarta Sans + one mono font — no third typeface

## Consultant Brief Template

### Project: ONO Personal Transformation App
**Domain**: Visual Identity, UI/UX, Motion Design
**Platform**: Flutter (iOS + Android), dark theme primary

#### What We Need From You
1. **Audit scope**: _(specific screens, component library, animation set, or brand system)_
2. **Key questions**: _(list 3-5 specific design questions)_
3. **Deliverable format**: Annotated design feedback + revised components (Figma preferred)
4. **Timeline**: _(target date)_

#### Context to Review Before Session
- Design token documentation (this file)
- Current Figma component library
- Animation prototype videos
- Competitor visual analysis

#### Specific Concerns
- _(list any screens with accessibility issues)_
- _(note any performance concerns with current animation approach)_

#### Success Criteria
- Visual consistency audit across all primary screens
- Accessibility compliance verification (WCAG 2.1 AA)
- Motion design review with performance impact assessment
- Component library gaps identified with design recommendations

#### Consultant Fills In
- **Assessment date**: ___
- **Screens/components reviewed**: ___
- **Consistency issues**: ___
- **Accessibility findings**: ___
- **Motion design notes**: ___
- **Recommended refinements**: ___
- **Design tools used**: ___
- **Signed**: ___

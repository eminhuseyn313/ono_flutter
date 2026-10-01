# ONO — Complete Data Structures Export

> **Purpose**: Share with another conversation to build the personal development content layer.
> **App**: ONO — Personal transformation app for young men (18–30)
> **Stack**: Flutter + Supabase
> **4 Lanes**: Mind, Body, Social, Skill

---

## 1. LANE DEFINITIONS

The four lanes are the organizing axis for everything in the app — actions, rituals, check-ins, coaching, and progress.

### Lane Enum (`FocusArea` in `daily_checkin.dart`)

```dart
enum FocusArea {
  mind,   // color: 0xFF8B5CF6 (purple),   icon: Icons.psychology
  body,   // color: 0xFF22D3EE (cyan),     icon: Icons.fitness_center
  social, // color: 0xFF34D399 (green),    icon: Icons.people
  skill,  // color: 0xFFF59E0B (amber),    icon: Icons.auto_awesome
}
```

### Lane Enum (`RitualLane` in `ritual.dart`)

```dart
enum RitualLane { mind, body, social, skill }
```

### Onboarding Lane Config (`OnboardingLanes` in `onboarding.dart`)

```dart
static const List<Map<String, dynamic>> defaults = [
  { 'id': 'mind',   'name': 'Mind',   'description': 'Meditation, journaling, focus & mental clarity',      'icon': 'psychology' },
  { 'id': 'body',   'name': 'Body',   'description': 'Workouts, nutrition, sleep & physical health',        'icon': 'fitness_center' },
  { 'id': 'social', 'name': 'Social', 'description': 'Communication, networking & relationships',           'icon': 'groups' },
  { 'id': 'skill',  'name': 'Skill',  'description': 'Learning, career growth & creative projects',         'icon': 'auto_awesome' },
];
```

### Lane Colors (from `OnboardingLanes.colorForLane`)

| Lane   | Hex        | Name   |
|--------|------------|--------|
| Mind   | `#8B5CF6`  | Purple |
| Body   | `#22D3EE`  | Cyan   |
| Social | `#34D399`  | Green  |
| Skill  | `#F59E0B`  | Amber  |

---

## 2. BLUEPRINT / ARCHETYPE MODEL

### Archetype (`models/models.dart`)

6 archetypes the user selects during onboarding to shape their transformation blueprint:

```dart
class Archetype {
  final String id;
  final String emoji;
  final String title;
  final String tagline;
  final String description;
}
```

**Built-in archetypes:**

| ID             | Emoji | Title            | Tagline                | Description                              |
|----------------|-------|------------------|------------------------|------------------------------------------|
| `executive`    | 🏆    | The Executive    | Leads with authority   | Strategic, decisive, commands respect    |
| `athlete`      | 💪    | The Athlete      | Built and disciplined  | Peak performance, physical excellence    |
| `creative`     | 🎨    | The Creative     | Original and expressive| Unique perspective, artistic vision      |
| `intellectual` | 📚    | The Intellectual | Sharp and well-read    | Wisdom, depth, continuous learning       |
| `entrepreneur` | 🚀    | The Entrepreneur | Bold and driven        | Builder, risk-taker, visionary           |
| `gentleman`    | 👔    | The Gentleman    | Refined and magnetic   | Polished, charming, impeccable presence  |

### Blueprint Domains (`BlueprintDomain` in `models/models.dart`)

After archetype selection, the user gets a blueprint with 5 life domains and daily actions:

```dart
class BlueprintDomain {
  final String name;
  final String emoji;
  final List<String> actions;
  final bool active;
}
```

**Built-in domains with actions:**

1. **💼 Career**
   - Optimise your LinkedIn headline
   - Engage daily with industry content
   - Write one post per week in your voice

2. **👕 Style**
   - Audit your wardrobe — remove what doesn't fit
   - Book your barber every 3 weeks
   - Build a signature grooming routine

3. **💪 Body**
   - Train 3–4x per week — progressive overload
   - Hit 2g protein per kg bodyweight daily
   - Sleep 7–8 hours — consistent wake time
   - Walk 8,000+ steps on rest days
   - Drink 3L water daily — track it

4. **📚 Intellect**
   - Read 20 pages per day — non-fiction or classics
   - Listen to one long-form podcast per week
   - Write a 5-minute journal entry each evening
   - Learn one new concept or skill each week
   - Replace 30 min of scrolling with reading

5. **🗣 Social**
   - Start one conversation with a stranger per week
   - Reach out to one old friend each week
   - Practice active listening — no interrupting
   - Attend one social event or meetup per month
   - Give one genuine compliment per day

### Assessment Questions (`AssessmentQuestion` in `models/models.dart`)

10 questions asked during onboarding to calibrate the blueprint:

```dart
class AssessmentQuestion {
  final String question;
  final List<String> options;
}
```

| # | Question                              | Options                                      |
|---|---------------------------------------|----------------------------------------------|
| 1 | What's your current fitness level?    | Never gym, Occasionally, 3x per week, Daily training |
| 2 | How would you describe your style?    | No system, Basic, Developing, Sharp          |
| 3 | Where are you in your career?         | Student, Early career, Mid career, Senior    |
| 4 | How often do you read?                | Never, Monthly, Weekly, Daily                |
| 5 | How confident are you socially?       | Anxious, Okay, Confident, Very confident     |
| 6 | Is your LinkedIn profile complete?    | Empty, Basic, Good, Optimised                |
| 7 | Describe your mornings                | Chaotic, Okay, Routine, Optimised            |
| 8 | What's your biggest weakness?         | Consistency, Focus, Confidence, Direction    |
| 9 | Who do you admire most?               | Athlete, CEO/Founder, Artist, Intellectual   |
|10 | When do you want to see results?      | 1 month, 3 months, 6 months, 1 year         |

### Onboarding Profile (`OnboardingProfile` in `onboarding.dart`)

```dart
class OnboardingProfile {
  final String name;
  final int? age;
  final String motivation;
  final List<LanePreference> lanePreferences;  // priority + weeklyGoalHours per lane
  final List<OnboardingGoal> goals;              // title, lane, targetDate, description
  final SchedulePreference? schedule;            // wakeUpTime, bedTime, sessionLength, activeDays
  final Set<OnboardingStep> completedSteps;
}

class LanePreference {
  final String laneId;       // 'mind', 'body', 'social', 'skill'
  final int priority;        // ordering
  final double weeklyGoalHours;  // default 3.0
}

class OnboardingGoal {
  final String id;
  final String title;
  final String lane;
  final DateTime? targetDate;
  final String description;
}

class SchedulePreference {
  final String wakeUpTime;               // default '07:00'
  final String bedTime;                  // default '23:00'
  final int preferredSessionLength;      // default 30 (minutes)
  final List<int> activeDays;            // default [0,1,2,3,4] (Mon-Fri)
}
```

---

## 3. DAILY ACTIONS / CHECK-IN MODEL

### Daily Check-in (`DailyCheckin` in `daily_checkin.dart`)

The core daily engagement loop — split into morning and evening:

```dart
class DailyCheckin {
  final String id;
  final DateTime date;
  
  // Morning check-in
  final CheckinMood? morningMood;        // terrible/low/neutral/good/great/amazing
  final double? energyLevel;             // 0.0 - 1.0
  final List<String> gratitudes;         // free-text entries
  final String? intention;               // today's intention
  final FocusArea? primaryFocus;         // mind/body/social/skill
  final bool morningComplete;
  final DateTime? morningCompletedAt;
  
  // Evening check-in
  final String? eveningReflection;       // free-text reflection
  final double? dayRating;               // 0.0 - 5.0
  final CheckinMood? eveningMood;
  final bool eveningComplete;
  final DateTime? eveningCompletedAt;
}
```

### Mood Enum

```dart
enum CheckinMood {
  terrible,  // 😞  color: #EF4444 (red)
  low,       // 😔  color: #F97316 (orange)
  neutral,   // 😐  color: #FBBF24 (yellow)
  good,      // 🙂  color: #34D399 (green)
  great,     // 😊  color: #22D3EE (cyan)
  amazing,   // 🔥  color: #8B5CF6 (purple)
}
```

### Check-in History

```dart
class CheckinHistory {
  final List<DailyCheckin> recentCheckins;
  final int morningStreak;
  final int eveningStreak;
  final double averageMood;
  final int totalCheckins;
}
```

### Role Model Daily Actions (`JourneyAction` in `role_model.dart`)

Each role model carries 6 daily actions the user can adopt:

```dart
class JourneyAction {
  final String title;
  final String subtitle;
  final String lane;    // 'mind', 'body', 'social', 'skill'
}
```

### Rituals — Morning & Evening (`ritual.dart`)

Structured step-by-step rituals with timed steps:

```dart
class RitualStep {
  final String id;
  final String title;          // e.g. 'Affirmation'
  final String subtitle;       // e.g. 'Set your mindset'
  final RitualLane lane;       // mind/body/social/skill
  final int durationSeconds;   // step timer
  final IconData iconData;
  final String instruction;    // full guidance text
  final bool isOptional;
}

class Ritual {
  final String id;
  final String userId;
  final RitualType type;           // morning/evening
  final List<RitualStep> steps;
  final TimeOfDay preferredTime;
  final bool isActive;
  final DateTime createdAt;
}
```

**Default Morning Ritual** (5 steps, ~6.5 min total):
1. **Affirmation** (Mind, 60s) — Repeat personal affirmation 3x
2. **Movement** (Body, 120s) — Stretch, squats, shake out stiffness
3. **Mind Primer** (Skill, 90s) — Read a page, flashcard, or podcast clip
4. **Intention Setting** (Mind, 60s) — Pick one way of being for the day
5. **Gratitude** (Social, 60s) — 3 things: self, someone loved, the world

**Default Evening Ritual** (5 steps, ~7 min total):
1. **Gratitude** (Social, 60s) — 3 good moments from today
2. **Reflection** (Mind, 90s) — What went well, what to improve
3. **Tomorrow Prep** (Skill, 90s) — Top 3 priorities, lay out what you need
4. **Wind-Down** (Body, 120s) — Body scan, deep breathing
5. **Sleep Intention** (Mind, 60s) — Set a gentle intention for rest

---

## 4. AI COACH MODEL

### Coach Insight (`CoachInsight` in `ai_coach.dart`)

The AI coach generates contextual insights based on user behavior:

```dart
class CoachInsight {
  final String id;
  final InsightType type;       // pattern/nudge/tip/celebration/warning
  final String title;
  final String message;
  final String? actionLabel;    // CTA text, e.g. "Start Morning Ritual"
  final String? actionRoute;    // route to navigate to, e.g. '/morning-ritual'
  final String? relatedLane;    // 'mind', 'body', 'social', 'skill'
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;
}
```

### Insight Types

```dart
enum InsightType {
  pattern,      // 📊 color: #8B5CF6 — Detected behavioral patterns
  nudge,        // 👆 color: #22D3EE — Gentle push toward action
  tip,          // 💡 color: #F59E0B — Practical advice
  celebration,  // 🎉 color: #34D399 — Achievement/streak recognition
  warning,      // ⚠️ color: #EF4444 — Declining metrics alert
}
```

### Coach Tone

```dart
enum CoachTone {
  motivational,   // Hype and energy
  analytical,     // Data-driven observations
  gentle,         // Supportive and empathetic
  challenging,    // Push harder, tough love
}
```

### Daily Coach Tip

```dart
class DailyCoachTip {
  final String id;
  final String title;
  final String content;          // full tip text
  final String lane;             // which lane this tip relates to
  final int laneColorValue;      // color for display
  final DateTime date;
  final bool isBookmarked;
}
```

### Coach Data (aggregate view)

```dart
class CoachData {
  final List<CoachInsight> insights;
  final DailyCoachTip dailyTip;
  final CoachTone preferredTone;
  final int streakDays;
  final double overallScore;               // 0.0 - 1.0
  final Map<String, double> laneScores;    // { 'mind': 0.72, 'body': 0.85, ... }
}
```

---

## 5. ROLE MODELS (for content generation context)

### Role Model Structure

```dart
class RoleModel {
  final String id;
  final String name;
  final String emoji;
  final RoleModelSector sector;     // mindset/sports/business/creativity/science/technology/music
  final String tagline;
  final String bio;
  final String philosophy;
  final String philosophyQuote;
  final List<String> keyDisciplines;
  final List<JourneyAction> dailyActions;   // 6 actions per role model
  final int journeyDays;                     // default 30
}
```

### All Role Models in the App

**Mindset & Philosophy:**
- Marcus Aurelius — The Philosopher King (Stoic mastery)
- David Goggins — The Hardest Man Alive (40% Rule, suffering as growth)
- Miyamoto Musashi — The Undefeated Swordsman (mastery through training)
- Ryan Holiday — The Modern Stoic (obstacle is the way)
- Wim Hof — The Iceman (breathwork, cold therapy)
- Tim Ferriss — The Life Hacker (80/20, lifestyle design)

**Sports & Fitness:**
- Cristiano Ronaldo — The Relentless Machine (discipline, diet, work ethic)
- Kobe Bryant — Mamba Mentality (4AM workouts, obsessive improvement)
- Arnold Schwarzenegger — The Self-Made Titan (vision + relentless work)
- Michael Jordan — His Airness (competitive fire, practice harder than you play)
- LeBron James — The Longevity King (body investment, recovery)
- Muhammad Ali — The Greatest (courage, standing for beliefs)
- Conor McGregor — (and more in the full database)

**Business:**
- Naval Ravikant, Alex Hormozi, and others

**Science/Technology:**
- Andrew Huberman, and others

### 30-Day Journey System (`journey.dart`)

Each role model has a 30-day journey with 3 phases and milestones:

```dart
class Journey {
  final String id;
  final String roleModelId;
  final String title;           // e.g. "The Mamba Path"
  final String description;
  final int totalDays;          // 30
  final List<JourneyPhase> phases;
  final List<String> rewards;   // emoji rewards at completion
}

class JourneyPhase {
  final String id;
  final String title;               // e.g. "Week 1-2: Foundation"
  final String description;
  final int startDay;
  final int endDay;
  final List<JourneyMilestone> milestones;
  final String motivationalQuote;
}

class JourneyMilestone {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int requiredDay;
  final MilestoneType type;    // streak/completion/lane/special
}
```

**Example Journey — "The Mamba Path" (Kobe Bryant):**
- Phase 1 (Days 1-14): Foundation — Build 4AM discipline
  - Day 1: First Rep Down (🌱)
  - Day 7: 7 Days Straight (🔥)
  - Day 14: Body Locked In (💪)
- Phase 2 (Days 15-21): Intensity — Push past the plateau
  - Day 15: 14-Day Streak (⚡)
  - Day 21: Mind Over Matter (🧠)
- Phase 3 (Days 22-30): Mastery — Finish like a champion
  - Day 25: 25 Actions Total (🏀)
  - Day 30: Mamba Mentality Achieved (🐍)

Pre-built journeys exist for: Kobe, Goggins, Marcus Aurelius, Naval, Huberman, Hormozi, CR7, Bruce Lee, Arnold, and Jocko Willink.

---

## 6. XP & GAMIFICATION

### XP System (`xp_system.dart`)

```dart
class XpLevel {
  final int level;
  final String title;
  final int xpRequired;
}

class XpSystem {
  static const levels = [
    XpLevel(1, 'Beginner',    0),
    XpLevel(2, 'Apprentice',  100),
    XpLevel(3, 'Dedicated',   300),
    XpLevel(4, 'Consistent',  600),
    XpLevel(5, 'Disciplined', 1000),
    XpLevel(6, 'Committed',   1500),
    XpLevel(7, 'Advanced',    2100),
    XpLevel(8, 'Elite',       2800),
    XpLevel(9, 'Master',      3600),
    XpLevel(10,'Legend',       4500),
  ];
}
```

### Achievement Model (`achievement.dart`)

```dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final int iconCodePoint;        // MaterialIcons code point
  final int colorValue;           // ARGB color value
  final AchievementCategory category;  // streak/actions/lanes/social/milestones/special
  final AchievementRarity rarity;      // common/rare/epic/legendary
  final int requiredProgress;
  final int currentProgress;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}
```

---

## 7. APP THEME & COLORS

```dart
class AppColors {
  static const background  = Color(0xFF0A0C14);
  static const card        = Color(0xFF121826);
  static const cardLight   = Color(0xFF1B2336);
  static const purple      = Color(0xFF8B5CF6);
  static const purpleSoft  = Color(0xFFC4B5FD);
  static const purpleDark  = Color(0xFF4C1D95);
  static const cyan        = Color(0xFF22D3EE);
  static const green       = Color(0xFF34D399);
  static const white       = Color(0xFFF8FAFC);
  static const grey        = Color(0xFF9AA6B2);
  static const greyLight   = Color(0xFFD5DEE8);
  static const success     = Color(0xFF34D399);
  static const warning     = Color(0xFFF59E0B);
  static const divider     = Color(0xFF202B3F);
  // No AppColors.error — use Color(0xFFEF4444) directly
}
```

- **Font**: Google Fonts Plus Jakarta Sans
- **Style**: Dark theme, glassmorphic cards
- **Background**: #0A0C14
- **Primary accent**: #8B5CF6 (purple)

---

## 8. KEY NAVIGATION ROUTES

Bottom tabs: `/home`, `/progress`, `/journal`, `/profile`

Feature routes: `/achievements`, `/ai-coach`, `/daily-checkin`, `/morning-ritual`, `/ritual-flow/:ritualId`, `/ritual-setup`, `/social-feed`, `/habit-streaks`, `/weekly-review`, `/role-models`, `/role-model/:id`, `/monk-mode`, `/ghost-mode`, `/legacy-score`, `/becoming-arc`, `/forge`, `/forge/:courseId`, `/dashboard`, `/analytics`, `/planner`, `/vision-board`, `/power-rankings`, `/gamification`, `/vault`, `/accountability`, `/brotherhood`, `/council`, `/radio`, `/trending`, `/mirror-match`, `/wakz-challenges`, `/community-challenges`, `/content-library`, `/phase-transition`, `/time-mode`, `/adaptive-settings`, `/notification-feed`, `/settings`

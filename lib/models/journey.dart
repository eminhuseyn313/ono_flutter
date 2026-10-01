/// A multi-week transformation journey tied to a role model.
/// Each journey has phases (e.g. "Foundation", "Building", "Mastery")
/// with milestones that unlock as the user progresses.

enum MilestoneType {
  streak, // consecutive days completed
  completion, // X total actions done
  lane, // X actions in a specific lane
  special, // custom achievement
}

class JourneyMilestone {
  final String id;
  final String title; // e.g. "Complete 7 consecutive days"
  final String description;
  final String emoji;
  final int requiredDay; // day it unlocks on
  final MilestoneType type;

  const JourneyMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredDay,
    required this.type,
  });
}

class JourneyPhase {
  final String id;
  final String title; // e.g. "Week 1-2: Foundation"
  final String description;
  final int startDay;
  final int endDay;
  final List<JourneyMilestone> milestones;
  final String motivationalQuote;

  const JourneyPhase({
    required this.id,
    required this.title,
    required this.description,
    required this.startDay,
    required this.endDay,
    required this.milestones,
    required this.motivationalQuote,
  });
}

class Journey {
  final String id;
  final String roleModelId; // links to RoleModel.id
  final String title; // e.g. "The Mamba Path"
  final String description;
  final int totalDays;
  final List<JourneyPhase> phases;
  final List<String> rewards; // emoji rewards unlocked at completion

  const Journey({
    required this.id,
    required this.roleModelId,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.phases,
    required this.rewards,
  });

  Journey copyWith({
    String? id,
    String? roleModelId,
    String? title,
    String? description,
    int? totalDays,
    List<JourneyPhase>? phases,
    List<String>? rewards,
  }) {
    return Journey(
      id: id ?? this.id,
      roleModelId: roleModelId ?? this.roleModelId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalDays: totalDays ?? this.totalDays,
      phases: phases ?? this.phases,
      rewards: rewards ?? this.rewards,
    );
  }
}

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

/// Returns the journey configured for the given role model, or null if none.
Journey? getJourneyForRoleModel(String roleModelId) {
  for (final journey in allJourneys) {
    if (journey.roleModelId == roleModelId) return journey;
  }
  return null;
}

/// Returns the phase that contains the given day of the journey, or null.
JourneyPhase? getPhaseForDay(Journey journey, int day) {
  for (final phase in journey.phases) {
    if (day >= phase.startDay && day <= phase.endDay) return phase;
  }
  return null;
}

/// Returns every milestone across the journey whose requiredDay has been
/// reached (i.e. requiredDay <= day), in ascending order of requiredDay.
List<JourneyMilestone> getMilestonesUpToDay(Journey journey, int day) {
  final milestones = <JourneyMilestone>[];
  for (final phase in journey.phases) {
    for (final milestone in phase.milestones) {
      if (milestone.requiredDay <= day) milestones.add(milestone);
    }
  }
  milestones.sort((a, b) => a.requiredDay.compareTo(b.requiredDay));
  return milestones;
}

// ---------------------------------------------------------------------------
// Pre-built journeys
// ---------------------------------------------------------------------------

final List<Journey> allJourneys = [
  // ---------------------------------------------------------------------
  // Kobe Bryant — The Mamba Path
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_mamba_path',
    roleModelId: 'rm_kobe_bryant',
    title: 'The Mamba Path',
    description:
        'Thirty days of relentless, obsessive craft. No shortcuts, no excuses — just the work, repeated until it becomes who you are.',
    totalDays: 30,
    rewards: ['🐍', '🏆', '🌅'],
    phases: [
      JourneyPhase(
        id: 'mamba_phase_1',
        title: 'Week 1-2: Foundation',
        description:
            'Before you can outwork anyone, you have to show up for yourself first. Build the 4am discipline — not the highlight, the habit.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"The most important thing is to try and inspire people so that they can be great in whatever they want to do." — Kobe Bryant',
        milestones: [
          JourneyMilestone(
            id: 'mamba_m1',
            title: 'First Rep Down',
            description: 'Complete your very first daily action.',
            emoji: '🌱',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'mamba_m2',
            title: '7 Days Straight',
            description: 'Complete 7 consecutive days — the streak begins.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'mamba_m3',
            title: 'Body Locked In',
            description: 'Log 5 body-lane actions in the foundation phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'mamba_phase_2',
        title: 'Week 3: Intensity',
        description:
            'This is where the work gets uncomfortable — and where Mambas separate from everyone else. Push past the plateau.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Rest at the end, not in the middle." — Kobe Bryant',
        milestones: [
          JourneyMilestone(
            id: 'mamba_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'mamba_m5',
            title: 'Mind Over Matter',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'mamba_phase_3',
        title: 'Week 4: Mastery',
        description:
            'The final stretch. Everything you built is about to compound into an identity. Finish like a champion.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"Everything negative — pressure, challenges — is all an opportunity for me to rise." — Kobe Bryant',
        milestones: [
          JourneyMilestone(
            id: 'mamba_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🏀',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'mamba_m7',
            title: 'Mamba Mentality Achieved',
            description: 'Complete all 30 days of the journey.',
            emoji: '🐍',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // David Goggins — The 40% Challenge
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_40_percent',
    roleModelId: 'rm_david_goggins',
    title: 'The 40% Challenge',
    description:
        'When your mind tells you you\'re done, you\'re only at 40% of your capacity. Thirty days to find the other 60%.',
    totalDays: 30,
    rewards: ['🪖', '🔋', '🏔️'],
    phases: [
      JourneyPhase(
        id: 'goggins_phase_1',
        title: 'Week 1-2: Foundation',
        description:
            'Get comfortable being uncomfortable. Show up on the days you don\'t feel like it — that\'s where this starts.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"Suffering is the true test of life." — David Goggins',
        milestones: [
          JourneyMilestone(
            id: 'goggins_m1',
            title: 'Callus the Mind',
            description: 'Complete your first daily action.',
            emoji: '✊',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'goggins_m2',
            title: '7-Day Grind',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'goggins_m3',
            title: 'Body Armor',
            description: 'Log 5 body-lane actions in the foundation phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'goggins_phase_2',
        title: 'Week 3: The Governor',
        description:
            'Your brain is lying to you about your limits. Push through the wall you think is the finish line.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Don\'t stop when you\'re tired. Stop when you\'re done." — David Goggins',
        milestones: [
          JourneyMilestone(
            id: 'goggins_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'goggins_m5',
            title: 'Mental Toughness',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'goggins_phase_3',
        title: 'Week 4: Uncommon Amongst Uncommon',
        description:
            'Most people quit long before this. You\'re still here. Finish the challenge and prove it to yourself, not anyone else.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"You are in danger of living a life so comfortable and soft, that you will die without ever realizing your true potential." — David Goggins',
        milestones: [
          JourneyMilestone(
            id: 'goggins_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🎖️',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'goggins_m7',
            title: 'Found the Other 60%',
            description: 'Complete all 30 days of the journey.',
            emoji: '🪖',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Marcus Aurelius — The Stoic Way
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_stoic_way',
    roleModelId: 'rm_marcus_aurelius',
    title: 'The Stoic Way',
    description:
        'Command your mind, and it will not matter what happens to you. Thirty days of daily reflection and disciplined virtue.',
    totalDays: 30,
    rewards: ['🏛️', '📜', '🕊️'],
    phases: [
      JourneyPhase(
        id: 'stoic_phase_1',
        title: 'Week 1-2: The Discipline of Perception',
        description:
            'You don\'t control events, only your judgment of them. Start seeing clearly before reacting.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"You have power over your mind — not outside events. Realize this, and you will find strength." — Marcus Aurelius',
        milestones: [
          JourneyMilestone(
            id: 'stoic_m1',
            title: 'First Reflection',
            description: 'Complete your first daily action.',
            emoji: '🌅',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'stoic_m2',
            title: '7 Days of Discipline',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'stoic_m3',
            title: 'Clear Mind',
            description: 'Log 5 mind-lane actions in this phase.',
            emoji: '🧠',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'stoic_phase_2',
        title: 'Week 3: The Discipline of Action',
        description:
            'Virtue is a practice, not a thought. Act with justice and purpose in everything you do, however small.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Waste no more time arguing about what a good man should be. Be one." — Marcus Aurelius',
        milestones: [
          JourneyMilestone(
            id: 'stoic_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'stoic_m5',
            title: 'Service to Others',
            description: 'Log 5 social-lane actions this phase.',
            emoji: '🗣️',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'stoic_phase_3',
        title: 'Week 4: The Discipline of Will',
        description:
            'Amor fati — love your fate. Accept what you cannot change, and finish the journey with unshakeable calm.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"The impediment to action advances action. What stands in the way becomes the way." — Marcus Aurelius',
        milestones: [
          JourneyMilestone(
            id: 'stoic_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '📜',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'stoic_m7',
            title: 'Philosopher King',
            description: 'Complete all 30 days of the journey.',
            emoji: '🏛️',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Naval Ravikant — The Almanack Path
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_almanack_path',
    roleModelId: 'rm_naval',
    title: 'The Almanack Path',
    description:
        'Wealth, health, and happiness aren\'t luck — they\'re systems. Thirty days building the habits that compound forever.',
    totalDays: 30,
    rewards: ['♾️', '🧘', '💰'],
    phases: [
      JourneyPhase(
        id: 'naval_phase_1',
        title: 'Week 1-2: Specific Knowledge',
        description:
            'Find what you can\'t stop thinking about and start building leverage around it. Curiosity is the compass.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"Escape competition through authenticity." — Naval Ravikant',
        milestones: [
          JourneyMilestone(
            id: 'naval_m1',
            title: 'First Insight',
            description: 'Complete your first daily action.',
            emoji: '💡',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'naval_m2',
            title: '7-Day Compounding',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'naval_m3',
            title: 'Skill Stacking',
            description: 'Log 5 skill-lane actions in this phase.',
            emoji: '📚',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'naval_phase_2',
        title: 'Week 3: Judgment & Leverage',
        description:
            'Play long-term games with long-term people. Build the judgment that lets leverage compound in your favor.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Desire is a contract you make with yourself to be unhappy until you get what you want." — Naval Ravikant',
        milestones: [
          JourneyMilestone(
            id: 'naval_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'naval_m5',
            title: 'Calm Mind',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'naval_phase_3',
        title: 'Week 4: Peace of Mind',
        description:
            'The final destination isn\'t wealth — it\'s freedom from anxious craving. Finish the almanack in stillness.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"A calm mind, a fit body, and a house full of love. These things cannot be bought." — Naval Ravikant',
        milestones: [
          JourneyMilestone(
            id: 'naval_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '⚙️',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'naval_m7',
            title: 'Almanack Complete',
            description: 'Complete all 30 days of the journey.',
            emoji: '♾️',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Andrew Huberman — The Protocol Stack
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_protocol_stack',
    roleModelId: 'rm_huberman',
    title: 'The Protocol Stack',
    description:
        'Your biology is trainable. Thirty days of science-backed protocols to rewire your energy, focus, and sleep.',
    totalDays: 30,
    rewards: ['🔬', '☀️', '😴'],
    phases: [
      JourneyPhase(
        id: 'huberman_phase_1',
        title: 'Week 1-2: The Foundational Stack',
        description:
            'Morning light, consistent sleep, and movement — the non-negotiables everything else is built on.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"Consistency in behaviors is more important than any single heroic effort." — Andrew Huberman',
        milestones: [
          JourneyMilestone(
            id: 'huberman_m1',
            title: 'Protocol Zero',
            description: 'Complete your first daily action.',
            emoji: '🌤️',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'huberman_m2',
            title: '7-Day Consistency',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'huberman_m3',
            title: 'Physical Baseline',
            description: 'Log 5 body-lane actions in this phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'huberman_phase_2',
        title: 'Week 3: Focus & Dopamine Regulation',
        description:
            'Learn to earn your dopamine instead of borrowing it. Build sustained focus without burning out your drive.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Dopamine is the molecule of more — manage it, don\'t let it manage you." — Andrew Huberman',
        milestones: [
          JourneyMilestone(
            id: 'huberman_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'huberman_m5',
            title: 'Deep Focus',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'huberman_phase_3',
        title: 'Week 4: The Full Stack',
        description:
            'Every protocol running together — sleep, light, movement, focus. This is what optimized actually feels like.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"The plasticity of your brain never turns off — you can direct it deliberately." — Andrew Huberman',
        milestones: [
          JourneyMilestone(
            id: 'huberman_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🧬',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'huberman_m7',
            title: 'Protocol Master',
            description: 'Complete all 30 days of the journey.',
            emoji: '🔬',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Alex Hormozi — The 100M Grind
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_100m_grind',
    roleModelId: 'rm_hormozi',
    title: 'The 100M Grind',
    description:
        'Volume negates luck. Thirty days of relentless execution, output, and value creation with zero excuses.',
    totalDays: 30,
    rewards: ['📈', '💵', '🏗️'],
    phases: [
      JourneyPhase(
        id: 'hormozi_phase_1',
        title: 'Week 1-2: Reps Over Everything',
        description:
            'Stop optimizing before you\'ve even started. Get your reps in — quantity is the fastest path to quality.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"The size of your success is determined by the size of your Belief multiplied by the size of your Action." — Alex Hormozi',
        milestones: [
          JourneyMilestone(
            id: 'hormozi_m1',
            title: 'First Output',
            description: 'Complete your first daily action.',
            emoji: '📦',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'hormozi_m2',
            title: '7-Day Volume',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'hormozi_m3',
            title: 'Skill Reps',
            description: 'Log 5 skill-lane actions in this phase.',
            emoji: '📚',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'hormozi_phase_2',
        title: 'Week 3: Value Creation',
        description:
            'Everyone wants the outcome. Few will do the boring reps that create real value. Be the few.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"You don\'t need more time, you need more decisiveness." — Alex Hormozi',
        milestones: [
          JourneyMilestone(
            id: 'hormozi_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'hormozi_m5',
            title: 'Network Building',
            description: 'Log 5 social-lane actions this phase.',
            emoji: '🗣️',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'hormozi_phase_3',
        title: 'Week 4: Compounding Gains',
        description:
            'This is where consistency starts paying off exponentially. Close out the month like you\'re building an empire.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"I\'m not competing with you, I\'m competing with the person I was yesterday." — Alex Hormozi',
        milestones: [
          JourneyMilestone(
            id: 'hormozi_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '📊',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'hormozi_m7',
            title: 'Grind Complete',
            description: 'Complete all 30 days of the journey.',
            emoji: '📈',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Cristiano Ronaldo — The CR7 Standard
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_cr7_standard',
    roleModelId: 'rm_cristiano_ronaldo',
    title: 'The CR7 Standard',
    description:
        'Talent without work is nothing. Thirty days of elite discipline in body, mind, and craft — the standard of a champion.',
    totalDays: 30,
    rewards: ['⚽', '👑', '🥇'],
    phases: [
      JourneyPhase(
        id: 'cr7_phase_1',
        title: 'Week 1-2: The Base',
        description:
            'Champions are built in the gym before they\'re seen on the field. Lock in the physical foundation first.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"Your love makes me strong, your hate makes me unstoppable." — Cristiano Ronaldo',
        milestones: [
          JourneyMilestone(
            id: 'cr7_m1',
            title: 'First Training Session',
            description: 'Complete your first daily action.',
            emoji: '⚽',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'cr7_m2',
            title: '7-Day Streak',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'cr7_m3',
            title: 'Peak Physical Form',
            description: 'Log 5 body-lane actions in this phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'cr7_phase_2',
        title: 'Week 3: The Mentality',
        description:
            'Ronaldo\'s edge isn\'t just physical — it\'s the obsession to always be the best version of himself. Build that mindset.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"I always felt like I have this responsibility to show my quality every single day." — Cristiano Ronaldo',
        milestones: [
          JourneyMilestone(
            id: 'cr7_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'cr7_m5',
            title: 'Champion\'s Mind',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'cr7_phase_3',
        title: 'Week 4: The Standard',
        description:
            'This is what separates the greats from the good — showing up at the same intensity every single day, no exceptions.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"I am never satisfied. I always want more." — Cristiano Ronaldo',
        milestones: [
          JourneyMilestone(
            id: 'cr7_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🥇',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'cr7_m7',
            title: 'CR7 Standard Achieved',
            description: 'Complete all 30 days of the journey.',
            emoji: '👑',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Bruce Lee — Way of the Dragon
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_way_of_the_dragon',
    roleModelId: 'rm_bruce_lee',
    title: 'Way of the Dragon',
    description:
        'Be water. Thirty days of adaptable, disciplined training that forges body and mind into one instrument.',
    totalDays: 30,
    rewards: ['🐉', '🥋', '💧'],
    phases: [
      JourneyPhase(
        id: 'brucelee_phase_1',
        title: 'Week 1-2: The Empty Cup',
        description:
            'Before you can master anything, you must empty your cup. Show up daily with humility and repetition.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"I fear not the man who has practiced 10,000 kicks once, but I fear the man who has practiced one kick 10,000 times." — Bruce Lee',
        milestones: [
          JourneyMilestone(
            id: 'brucelee_m1',
            title: 'First Strike',
            description: 'Complete your first daily action.',
            emoji: '👊',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'brucelee_m2',
            title: '7-Day Discipline',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'brucelee_m3',
            title: 'Body of a Warrior',
            description: 'Log 5 body-lane actions in this phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'brucelee_phase_2',
        title: 'Week 3: Be Water',
        description:
            'Rigid habits break under pressure. Learn to adapt your practice to whatever the day throws at you.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Be water, my friend." — Bruce Lee',
        milestones: [
          JourneyMilestone(
            id: 'brucelee_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'brucelee_m5',
            title: 'Mind Like Water',
            description: 'Log 5 mind-lane actions this phase.',
            emoji: '🧠',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'brucelee_phase_3',
        title: 'Week 4: The Dragon Emerges',
        description:
            'What you\'ve built is no longer a routine — it\'s an expression of who you are. Complete the transformation.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"A goal is not always meant to be reached, it often serves simply as something to aim at." — Bruce Lee',
        milestones: [
          JourneyMilestone(
            id: 'brucelee_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🥋',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'brucelee_m7',
            title: 'Dragon Awakened',
            description: 'Complete all 30 days of the journey.',
            emoji: '🐉',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Arnold Schwarzenegger — The Blueprint
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_the_blueprint',
    roleModelId: 'rm_arnold',
    title: 'The Blueprint',
    description:
        'From nothing to everything — Arnold\'s formula is repeatable. Thirty days building the vision, the reps, and the will.',
    totalDays: 30,
    rewards: ['🏗️', '🏋️', '🎬'],
    phases: [
      JourneyPhase(
        id: 'arnold_phase_1',
        title: 'Week 1-2: Vision & Reps',
        description:
            'Every empire starts with a clear vision and unglamorous daily reps. Put in the work no one sees yet.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"The pump — feeling the blood pumping into your muscles — is the greatest feeling you can get." — Arnold Schwarzenegger',
        milestones: [
          JourneyMilestone(
            id: 'arnold_m1',
            title: 'First Rep',
            description: 'Complete your first daily action.',
            emoji: '🏋️',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'arnold_m2',
            title: '7-Day Streak',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'arnold_m3',
            title: 'Building the Physique',
            description: 'Log 5 body-lane actions in this phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'arnold_phase_2',
        title: 'Week 3: Breaking Barriers',
        description:
            'Bodybuilder, actor, governor — Arnold rewrote his own limits at every stage. Break through yours this week.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"Strength does not come from winning. Your struggles develop your strengths." — Arnold Schwarzenegger',
        milestones: [
          JourneyMilestone(
            id: 'arnold_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'arnold_m5',
            title: 'Skill Building',
            description: 'Log 5 skill-lane actions this phase.',
            emoji: '📚',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'arnold_phase_3',
        title: 'Week 4: The Blueprint Realized',
        description:
            'This is the month you stopped dreaming and started building. Finish the blueprint you set out to follow.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"The mind is the limit. As long as the mind can envision the fact that you can do something, you can do it." — Arnold Schwarzenegger',
        milestones: [
          JourneyMilestone(
            id: 'arnold_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🎬',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'arnold_m7',
            title: 'Blueprint Complete',
            description: 'Complete all 30 days of the journey.',
            emoji: '🏗️',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------------------
  // Jocko Willink — Extreme Ownership
  // ---------------------------------------------------------------------
  Journey(
    id: 'journey_extreme_ownership',
    roleModelId: 'rm_jocko',
    title: 'Extreme Ownership',
    description:
        'No excuses. No blame. Thirty days of taking full ownership of your discipline, your decisions, and your day.',
    totalDays: 30,
    rewards: ['⏰', '🫡', '🛡️'],
    phases: [
      JourneyPhase(
        id: 'jocko_phase_1',
        title: 'Week 1-2: Discipline Equals Freedom',
        description:
            'Get up before the excuses do. The 4:30am wake-up isn\'t about the hour — it\'s about proving you own your day.',
        startDay: 1,
        endDay: 14,
        motivationalQuote:
            '"Discipline equals freedom." — Jocko Willink',
        milestones: [
          JourneyMilestone(
            id: 'jocko_m1',
            title: 'Own Day One',
            description: 'Complete your first daily action.',
            emoji: '⏰',
            requiredDay: 1,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'jocko_m2',
            title: '7-Day Ownership',
            description: 'Complete 7 consecutive days.',
            emoji: '🔥',
            requiredDay: 7,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'jocko_m3',
            title: 'Physical Standard',
            description: 'Log 5 body-lane actions in this phase.',
            emoji: '💪',
            requiredDay: 14,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'jocko_phase_2',
        title: 'Week 3: Detach & Lead',
        description:
            'A good leader detaches from the chaos to see the bigger picture. Lead yourself the same way — plan, then execute.',
        startDay: 15,
        endDay: 21,
        motivationalQuote:
            '"It is not what you preach, it\'s what you tolerate." — Jocko Willink',
        milestones: [
          JourneyMilestone(
            id: 'jocko_m4',
            title: '14-Day Streak',
            description: 'Complete 14 consecutive days.',
            emoji: '⚡',
            requiredDay: 15,
            type: MilestoneType.streak,
          ),
          JourneyMilestone(
            id: 'jocko_m5',
            title: 'Chain of Command',
            description: 'Log 5 social-lane actions this phase.',
            emoji: '🗣️',
            requiredDay: 21,
            type: MilestoneType.lane,
          ),
        ],
      ),
      JourneyPhase(
        id: 'jocko_phase_3',
        title: 'Week 4: No Excuses',
        description:
            'This is the final test of ownership — finish what you started, with no one to credit or blame but yourself.',
        startDay: 22,
        endDay: 30,
        motivationalQuote:
            '"Good." — Jocko Willink',
        milestones: [
          JourneyMilestone(
            id: 'jocko_m6',
            title: '25 Actions Total',
            description: 'Complete 25 total actions across the journey.',
            emoji: '🛡️',
            requiredDay: 25,
            type: MilestoneType.completion,
          ),
          JourneyMilestone(
            id: 'jocko_m7',
            title: 'Extreme Ownership Achieved',
            description: 'Complete all 30 days of the journey.',
            emoji: '🫡',
            requiredDay: 30,
            type: MilestoneType.special,
          ),
        ],
      ),
    ],
  ),
];

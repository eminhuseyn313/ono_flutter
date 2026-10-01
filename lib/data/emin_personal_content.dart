// ============================================================
// EMIN HUSEYNZADE — ONO PERSONAL DEVELOPMENT CONTENT LAYER
// ============================================================
// lib/data/emin_personal_content.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/daily_checkin.dart';
import '../models/ritual.dart';
import '../models/role_model.dart';
import '../models/journey.dart';
import '../models/ai_coach.dart';

// ============================================================
// 1. YOUR ARCHETYPE — The Product Leader
// ============================================================

final Archetype eminArchetype = Archetype(
  id: 'executive',
  emoji: '🏆',
  title: 'The Product Leader',
  tagline: 'Builds what others can\'t see yet',
  description:
      'Strategic, technically fluent, and building toward global recognition. '
      'You operate at the intersection of identity, payments, and ecosystem strategy — '
      'a domain almost nobody in your region understands. '
      'Your path: Senior PO → Head of Product → CPO or Founder.',
);

// ============================================================
// 2. YOUR BLUEPRINT DOMAINS
// ============================================================

final List<BlueprintDomain> eminBlueprint = [
  BlueprintDomain(
    name: 'Product Craft',
    emoji: '💼',
    active: true,
    actions: [
      'BLUF every output — decision first, reasons second, always',
      'Six-questions-deep prep before every meeting with Ali or senior stakeholders',
      'One framework per week — Feynman write after: close notes, explain from memory',
      'Anki review — 5 min at breakfast, 5 cards per week added',
      'One artifact per month — PR/FAQ, OST, strategy doc, or 6-pager',
      'Lenny\'s Podcast one episode per commute — one takeaway written at desk',
    ],
  ),
  BlueprintDomain(
    name: 'Domain Intelligence',
    emoji: '🌐',
    active: true,
    actions: [
      'Mon: Fintech Brainfood (fintechbrainfood.com) — 15 min morning scan',
      'Tue: CIAM Compass (guptadeepak.com) — identity and agent identity news',
      'Wed: Stratechery free post — platform and ecosystem strategy',
      'Thu: Lenny\'s Newsletter — product craft and leadership',
      'Fri: Product Compass by Paweł Huryn — modern PM frameworks',
      'One domain insight written per day — one sentence in journal',
      'Own this thesis: agent identity is the next frontier of merchant ecosystems',
    ],
  ),
  BlueprintDomain(
    name: 'Mental Performance',
    emoji: '🧠',
    active: true,
    actions: [
      'Read manifesto — 2 min while drinking first water every morning',
      'Physiological sigh before every high-pressure moment — 30 seconds',
      'Say "I am excited" before every high-stakes interaction — not "calm down"',
      'Evidence Archive — add 3 items every Sunday, read every Monday',
      'Pennebaker writing — 15 min once per week for 4 consecutive weeks',
      'Six-questions-deep — write 6 hardest questions before every Ali meeting',
      'Deliberate pause — one breath before answering anything challenging',
    ],
  ),
  BlueprintDomain(
    name: 'Physical Foundation',
    emoji: '💪',
    active: true,
    actions: [
      'Gym 3x per week — Push / Pull / Legs split (RA-shoulder safe)',
      'Face pulls 3×15 every session — builds posture and shoulder health',
      'Zone 2 cardio 20 min after 2 of 3 sessions — conversational pace',
      'Protein 150g daily — critical for beta thalassemia and recomposition',
      'Water 2.5L daily — dehydration measurably impairs cognition',
      'In bed 10:30pm — sleep is the foundation everything else runs on',
      'Nasal strip every night — improves sleep architecture immediately',
      'Supplements: Vitamin D3 2000IU + Creatine 5g + Omega-3 2g at breakfast',
      'Magnesium Glycinate 400mg before bed — sleep quality and stress response',
      'Body recomposition target: 76-78kg from current 83kg over 5-6 months',
    ],
  ),
  BlueprintDomain(
    name: 'Executive Presence',
    emoji: '👔',
    active: true,
    actions: [
      'Outfit check before leaving — "Do I belong in every room today?"',
      'Still body in every meeting — feet flat, hands still, no phone',
      'Downward vocal inflection on statements — not seeking permission',
      'Beard edge-up every Sunday evening — 10 min, sharp lines',
      'LinkedIn: 2 posts per week from Month 2 — domain insight + craft',
      'Professional headshot — book this month',
      'Build advisory board: 5 seats — internal sponsor, external PM, domain expert, founder, peer',
    ],
  ),
];

// ============================================================
// 3. YOUR MORNING RITUAL SEQUENCE
// ============================================================

final List<RitualStep> eminMorningRitual = [
  RitualStep(
    id: 'water',
    title: 'First water',
    subtitle: 'Hydration affects cognitive function within minutes',
    lane: RitualLane.body,
    durationSeconds: 60,
    iconData: Icons.water_drop,
    instruction: '500ml water immediately on waking. Before coffee. Before phone.',
  ),
  RitualStep(
    id: 'manifesto',
    title: 'Read your manifesto',
    subtitle: 'Identity-based priming anchors your day',
    lane: RitualLane.mind,
    durationSeconds: 120,
    iconData: Icons.auto_stories,
    instruction:
        '"I do not need to know everything. Competence is finding answers fast, '
        'making good decisions with incomplete information, and learning faster '
        'than the room. I have built real things. I am not a fraud — '
        'I hold myself to a high standard. Today I build something permanent."',
  ),
  RitualStep(
    id: 'three_priorities',
    title: '3 priorities for today',
    subtitle: 'Reduces decision fatigue throughout the day',
    lane: RitualLane.skill,
    durationSeconds: 90,
    iconData: Icons.flag_outlined,
    instruction:
        'Write exactly 3 things that must happen today. Not a to-do list. '
        '3 outcomes. Open Ono journal and write them now.',
  ),
  RitualStep(
    id: 'sigh',
    title: 'Physiological sigh',
    subtitle: 'Fastest method to activate parasympathetic nervous system',
    lane: RitualLane.mind,
    durationSeconds: 30,
    iconData: Icons.self_improvement,
    instruction:
        'Double inhale through nose (big breath, then squeeze more air in), '
        'then long slow exhale through mouth until empty. Repeat 3 times.',
  ),
  RitualStep(
    id: 'identity',
    title: 'Say your statement',
    subtitle: 'Verbal commitment increases follow-through',
    lane: RitualLane.mind,
    durationSeconds: 10,
    iconData: Icons.record_voice_over,
    instruction: 'Say aloud: "Today I build something permanent."',
  ),
];

// ============================================================
// 4. YOUR ROLE MODEL — "The Product Architect"
// ============================================================

final RoleModel productArchitectRoleModel = RoleModel(
  id: 'product_architect',
  name: 'The Product Architect',
  emoji: '🏗️',
  sector: RoleModelSector.technology,
  tagline: 'Built from zero. Known globally.',
  bio:
      'Started as a senior PO in an emerging market nobody had heard of. '
      'Built the identity layer of his country\'s first integrated digital ecosystem. '
      'Became the world\'s most recognized voice on B2B merchant identity. '
      'Headhunted by Revolut. Eventually built his own company. '
      'This is the person you are becoming.',
  philosophy:
      'Depth before visibility. Foundation before structure. '
      'Build what only you can build — from where only you stand.',
  philosophyQuote:
      '"The person who knows what\'s coming before others do — '
      'and can explain why it matters — owns the room."',
  keyDisciplines: [
    'Domain mastery — 15 min daily compounds into world-class expertise',
    'BLUF communication — decision first, always',
    'Zone 2 training — energy is cognitive capital',
    'Deliberate presence — still body, pause, downward inflection',
    'Evidence-based confidence — archive what you build',
  ],
  journeyDays: 30,
  dailyActions: [
    JourneyAction(
      title: 'Morning manifesto',
      subtitle: 'Read your identity statement before anything else',
      lane: 'mind',
    ),
    JourneyAction(
      title: 'Domain scan',
      subtitle: 'Read your assigned domain source for today — 15 min',
      lane: 'skill',
    ),
    JourneyAction(
      title: 'BLUF in action',
      subtitle: 'Apply BLUF to at least one work output today',
      lane: 'skill',
    ),
    JourneyAction(
      title: 'Physiological sigh',
      subtitle: 'Use it before your most challenging moment today',
      lane: 'mind',
    ),
    JourneyAction(
      title: 'Presence practice',
      subtitle: 'Still body + deliberate pause in every meeting today',
      lane: 'social',
    ),
    JourneyAction(
      title: 'Evidence archive',
      subtitle: 'Add one item to your evidence archive today',
      lane: 'mind',
    ),
  ],
);

// ============================================================
// 5. YOUR 30-DAY JOURNEY — "The Product Leader Path"
// ============================================================

final Journey productLeaderJourney = Journey(
  id: 'product_leader_path',
  roleModelId: 'product_architect',
  title: 'The Product Leader Path',
  description:
      'Month 1 of your 18-month transformation. '
      'Not motivation. Not hype. A specific system that builds '
      'the biological foundation, installs the daily protocols, '
      'and starts showing the world a different version of you.',
  totalDays: 30,
  rewards: ['🏆', '⚡', '🌍', '💎'],
  phases: [
    JourneyPhase(
      id: 'phase_foundation',
      title: 'Week 1-2: Foundation',
      description:
          'Fix the biological base. Install the daily systems. '
          'Stop the energy leak. Start showing up differently.',
      startDay: 1,
      endDay: 10,
      motivationalQuote:
          '"You cannot build a skyscraper on a cracked foundation. '
          'Fix the base first. Everything else follows."',
      milestones: [
        JourneyMilestone(
          id: 'm_day1',
          title: 'Day 1: System Installed',
          description: 'Completed your first morning ritual and read the manifesto',
          emoji: '🌱',
          requiredDay: 1,
          type: MilestoneType.completion,
        ),
        JourneyMilestone(
          id: 'm_day3',
          title: 'Day 3: Sigh Master',
          description: 'Used the physiological sigh before 3 different pressure moments',
          emoji: '🫁',
          requiredDay: 3,
          type: MilestoneType.special,
        ),
        JourneyMilestone(
          id: 'm_day5',
          title: 'Day 5: First Domain Win',
          description: 'Completed 5 consecutive morning domain scans',
          emoji: '🌐',
          requiredDay: 5,
          type: MilestoneType.streak,
        ),
        JourneyMilestone(
          id: 'm_day7',
          title: 'Day 7: First Week Complete',
          description: 'Seven days. The foundation is being built.',
          emoji: '🔥',
          requiredDay: 7,
          type: MilestoneType.streak,
        ),
        JourneyMilestone(
          id: 'm_day10',
          title: 'Day 10: BLUF Installed',
          description: 'Applied BLUF structure to 10 work outputs',
          emoji: '📢',
          requiredDay: 10,
          type: MilestoneType.completion,
        ),
      ],
    ),
    JourneyPhase(
      id: 'phase_construction',
      title: 'Week 3-4: Construction',
      description:
          'Domain knowledge building. Communication architecture. '
          'First artifact produced. Presence practiced daily.',
      startDay: 11,
      endDay: 22,
      motivationalQuote:
          '"The person who reads 15 minutes on their domain daily '
          'for 52 weeks reads the equivalent of 25 books per year. '
          'You are that person now."',
      milestones: [
        JourneyMilestone(
          id: 'm_day14',
          title: 'Day 14: Two Weeks Locked In',
          description: '14-day streak. The habits are forming.',
          emoji: '⚡',
          requiredDay: 14,
          type: MilestoneType.streak,
        ),
        JourneyMilestone(
          id: 'm_day16',
          title: 'Day 16: Evidence Archive Built',
          description: '30+ items in your evidence archive',
          emoji: '📋',
          requiredDay: 16,
          type: MilestoneType.special,
        ),
        JourneyMilestone(
          id: 'm_day20',
          title: 'Day 20: First Six-Questions',
          description: 'Completed six-questions-deep prep before an executive meeting',
          emoji: '🎯',
          requiredDay: 20,
          type: MilestoneType.special,
        ),
        JourneyMilestone(
          id: 'm_day22',
          title: 'Day 22: Domain Voice',
          description:
              'Can explain Mastercard Agent Pay, FAPI 2.0, and Kaspi\'s merchant strategy in plain language',
          emoji: '🌐',
          requiredDay: 22,
          type: MilestoneType.special,
        ),
      ],
    ),
    JourneyPhase(
      id: 'phase_signal',
      title: 'Week 5: First Signal',
      description:
          'The world starts to see something different. '
          'LinkedIn updated. Headshot taken or booked. '
          'First artifact complete. You walk into rooms differently.',
      startDay: 23,
      endDay: 30,
      motivationalQuote:
          '"Month 1 changes nothing visible to others. '
          'It changes everything internal. '
          'The visible change is coming. This is the work that makes it permanent."',
      milestones: [
        JourneyMilestone(
          id: 'm_day25',
          title: 'Day 25: LinkedIn Transformed',
          description: 'New headline live. New photo planned or taken.',
          emoji: '💼',
          requiredDay: 25,
          type: MilestoneType.special,
        ),
        JourneyMilestone(
          id: 'm_day28',
          title: 'Day 28: First Artifact',
          description: 'PR/FAQ or strategy document completed and ready to share',
          emoji: '📄',
          requiredDay: 28,
          type: MilestoneType.completion,
        ),
        JourneyMilestone(
          id: 'm_day30',
          title: 'Day 30: Month 1 Complete',
          description:
              '30 days. Foundation built. Systems running. '
              'The person in the mirror has started to change.',
          emoji: '🏆',
          requiredDay: 30,
          type: MilestoneType.completion,
        ),
      ],
    ),
  ],
);

// ============================================================
// 6. YOUR DAILY COACH TIPS — 30 Days
// ============================================================

final List<DailyCoachTip> eminCoachTips = [
  DailyCoachTip(
    id: 'tip_d1', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'The manifesto is not motivation',
    content: 'Reading your manifesto every morning is neurological priming, not positive thinking. Stanford researcher Hal Hershfield showed that people who regularly visualize their future identity make measurably different decisions in the present. Your brain starts filtering reality through the identity you claim. Two minutes. Every morning. This is the anchor the whole program runs on.',
  ),
  DailyCoachTip(
    id: 'tip_d2', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Why "I am excited" beats "I am calm"',
    content: 'Harvard professor Alison Wood Brooks proved in 2014 that people who say "I am excited" before high-stakes performance outperform those who try to calm down. Anxiety and excitement are physiologically identical — same cortisol, same adrenaline. The only difference is interpretation. One phrase. Before every hard moment today.',
  ),
  DailyCoachTip(
    id: 'tip_d3', date: DateTime.now(), lane: 'body', laneColorValue: 0xFF22D3EE, isBookmarked: false,
    title: 'Your energy has a biological cause',
    content: 'Beta thalassemia means your red blood cells carry less oxygen than average. This is not a motivation problem. It is a physiological reality. Zone 2 training builds mitochondrial density, the cellular machinery that extracts more energy from the oxygen you do have. 20 minutes after two of your three weekly gym sessions. The effect accumulates over 8-12 weeks.',
  ),
  DailyCoachTip(
    id: 'tip_d4', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'BLUF — why decision first changes everything',
    content: 'Jeff Bezos banned PowerPoint at Amazon because bullets allow you to hide weak thinking. Executives process top-down. They want to know what you think first, then decide if the reasoning is worth reading. From today: every email, every update, every meeting contribution — decision first. One sentence. Then your three supporting points.',
  ),
  DailyCoachTip(
    id: 'tip_d5', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'The 15-minute domain scan that compounds into expertise',
    content: 'The professional who reads 15 minutes on their domain daily for 52 weeks reads the equivalent of 25 books per year. Your domain — B2B identity, payments, AI agents, ecosystem strategy — is at an inflection point in 2026. The person who knows what\'s happening before others do owns the room. That person is you.',
  ),
  DailyCoachTip(
    id: 'tip_d6', date: DateTime.now(), lane: 'body', laneColorValue: 0xFF22D3EE, isBookmarked: false,
    title: 'Why face pulls belong in every session',
    content: 'Face pulls directly strengthen the rear deltoids and rotator cuff muscles that keep your shoulders healthy — critical with rheumatoid arthritis. But they also build the upper back musculature that creates upright posture with an open chest. That posture is the single most visible executive presence signal. 3x15 every session. Non-negotiable.',
  ),
  DailyCoachTip(
    id: 'tip_d7', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Week 1 complete — what actually happened this week',
    content: 'You installed the physiological sigh. You started reading the manifesto. You applied BLUF to some outputs. You did your domain scans. The world doesn\'t see any of this yet. That\'s correct. Month 1 changes nothing externally. It changes everything internally. Keep going.',
  ),
  DailyCoachTip(
    id: 'tip_d8', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Your impostor syndrome type: Expert + Soloist',
    content: 'Dr. Valerie Young identifies 5 impostor types. Yours are Expert + Soloist. The Expert believes they must know everything before speaking with authority. The Soloist believes asking for help proves inadequacy. The reframe: competence is not knowing everything. It is knowing how to find answers fast and learn faster than the room.',
  ),
  DailyCoachTip(
    id: 'tip_d9', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Six-questions-deep: how gravitas is built',
    content: 'Sylvia Ann Hewlett surveyed 268 senior executives on what signals gravitas. The ability to "go six questions deep" on any topic was one of the top responses. Before your next meeting with Ali: write his 6 hardest questions. Write your answers. Walk in having already had the hard conversation 6 times in your head.',
  ),
  DailyCoachTip(
    id: 'tip_d10', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'Your beard is your most powerful tool',
    content: 'A well-shaped beard adds vertical length to the chin, creates jaw definition, and frames your face with structure. The shape: fuller at the chin, sharp precise line at the neck, clean defined cheek line. Sunday evening, 10 minutes with a trimmer. This single grooming change will visibly change how people see your face.',
  ),
  DailyCoachTip(
    id: 'tip_d11', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'The Feynman technique: why production beats reading',
    content: 'Roediger and Karpicke (2006) proved that retrieval practice — writing from memory — produces 50% better long-term retention than re-reading. After reading, close everything. Open Ono journal. Write the concept in plain language from memory. Where you blank = where your understanding has gaps. Fill those gaps.',
  ),
  DailyCoachTip(
    id: 'tip_d12', date: DateTime.now(), lane: 'body', laneColorValue: 0xFF22D3EE, isBookmarked: false,
    title: 'Get bloodwork done this week',
    content: 'With beta thalassemia, your ferritin, hemoglobin, Vitamin D, testosterone, and thyroid levels directly affect your daily energy. Low ferritin is extremely common with thalassemia and dramatically worsens fatigue. A blood test is the only way to know. Book it this week.',
  ),
  DailyCoachTip(
    id: 'tip_d13', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'The deliberate pause: one breath changes how you read',
    content: 'A 1-2 second pause before answering is perceived as thoughtful and confident. Immediate answers are perceived as defensive or impulsive. Before answering anything challenging, take one slow breath. It will feel strange. It reads as authority.',
  ),
  DailyCoachTip(
    id: 'tip_d14', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Day 14 — two weeks. What has actually changed.',
    content: 'You are two weeks in. The physiological sigh is becoming automatic. Your morning starts with intention instead of chaos. None of this is visible to anyone yet. That is correct. This is the unsexy work that makes the visible change permanent instead of temporary.',
  ),
  DailyCoachTip(
    id: 'tip_d15', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Kaspi: the reference model for Business ID',
    content: 'Kaspi.kz: 764,000 active merchants, 95% accepting Kaspi QR, \$97.3B total payment volume. Merchant loans are tied to transaction history — identity + data = underwriting infrastructure. This is what Business ID is building toward. Identity is not a security feature. Identity is the foundation of every financial service that follows.',
  ),
  DailyCoachTip(
    id: 'tip_d16', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'Your LinkedIn headline is your first impression',
    content: 'Change it today to: "Building platform identity for 5M+ users @ Bir Ecosystem (PASHA) | Payments · Identity · AI Agents". This signals scale, employer, and three frontier topics in one line. Every recruiter from Revolut, Wise, or Stripe who searches these terms will find you.',
  ),
  DailyCoachTip(
    id: 'tip_d17', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Agent identity: your frontier thesis',
    content: 'Non-human identities now outnumber human users 45:1 on average. 92% of IT professionals say their tools cannot handle AI agent authentication. Your thesis: "The next interface of a super-app is an agent. Ecosystems that turn existing identity and payment trust into agent permissions will win." Own this. It is yours.',
  ),
  DailyCoachTip(
    id: 'tip_d18', date: DateTime.now(), lane: 'body', laneColorValue: 0xFF22D3EE, isBookmarked: false,
    title: 'Why your capsule wardrobe starts with knitwear',
    content: 'The modern tech-fintech executive look in 2026 is "quiet luxury" — dark colors, no visible logos, high-quality fabric, excellent fit. A fine merino crewneck in navy or charcoal, over dark fitted chinos, with minimal white leather sneakers. The navy merino is your first purchase.',
  ),
  DailyCoachTip(
    id: 'tip_d19', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Your evidence archive at Day 19',
    content: 'You have: built a complex identity product for an ecosystem with 5M+ users. Data engineering skills rare for any PO globally. 6 years of domain experience. Built Paya, Zimba, Duyit, Nimat, and Ono alongside your full-time role. 4 languages. The impostor says none of this is enough. The evidence says otherwise.',
  ),
  DailyCoachTip(
    id: 'tip_d20', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'The PR/FAQ: your most important artifact this month',
    content: 'Amazon\'s Working Backwards method starts with the press release. Write it as if the product already launched successfully. Then write 5 customer questions and 5 leadership questions. Write your PR/FAQ for the Business ID entrepreneur integration this week. Not for Ali. For yourself.',
  ),
  DailyCoachTip(
    id: 'tip_d21', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Day 21: the habit research says something important',
    content: 'The actual science: Phillippa Lally at UCL tracked 96 people. Median time to automaticity: 66 days. You are at Day 21. The habit is not automatic yet. That is correct. The people who give up now miss the automaticity that arrives around Day 40-60. Keep going.',
  ),
  DailyCoachTip(
    id: 'tip_d22', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'Your first LinkedIn post: the formula',
    content: 'Line 1 (hook): A counterintuitive claim or surprising number. Lines 2-5: Your real insight. Line 6: One specific example. Final line: One question for your network. 150-250 words. No external links in the post body. Topic: something you genuinely learned this month.',
  ),
  DailyCoachTip(
    id: 'tip_d23', date: DateTime.now(), lane: 'body', laneColorValue: 0xFF22D3EE, isBookmarked: false,
    title: 'The body recomposition timeline',
    content: 'At 83kg/176cm, your target is 76-78kg over 5-6 months while maintaining muscle. The formula: slight caloric deficit, 150g+ protein daily, consistent training, Zone 2 for energy. No crash diet. Slow and permanent. The person in your headshot at Month 6 will look different.',
  ),
  DailyCoachTip(
    id: 'tip_d24', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Anki: why 5 minutes beats 1 hour',
    content: 'Ebbinghaus\'s forgetting curve: we forget 70% of new information within 24 hours unless we review it. Spaced repetition is the evidence-based solution. 5 minutes of Anki daily produces more retention than an hour of re-reading. 5 cards per week. Review every morning.',
  ),
  DailyCoachTip(
    id: 'tip_d25', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'The professional headshot: why it matters',
    content: 'Nalini Ambady\'s Harvard research: people form stable impressions of competence in under 7 seconds. Your current LinkedIn photo reads as "employee applying for a job." A proper headshot reads as "expert worth following." Book a photographer this week. Not a friend with an iPhone.',
  ),
  DailyCoachTip(
    id: 'tip_d26', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Grab\'s retention data and what it means for Business ID',
    content: 'When Grab integrated identity across services, multi-service adoption grew from 12% to 54%. One-year retention grew from 47% to 79%. Business ID is building the same infrastructure for Bir. A merchant verified once across the entire ecosystem becomes a merchant who can be offered credit, insurance, and growth tools.',
  ),
  DailyCoachTip(
    id: 'tip_d27', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'The Pennebaker protocol: why it works',
    content: 'Writing about your deepest fears and anxieties for 15-20 minutes, four sessions over four weeks, produces measurable reductions in anxiety markers and improved cognitive performance. The mechanism: translating emotional experience into language activates the prefrontal cortex. This is your weekly Friday practice.',
  ),
  DailyCoachTip(
    id: 'tip_d28', date: DateTime.now(), lane: 'skill', laneColorValue: 0xFFF59E0B, isBookmarked: false,
    title: 'Your first artifact is almost done',
    content: 'By Day 28 your PR/FAQ should be complete or close. Ask yourself: Would Ali read this and understand immediately what we are building? Does the press release make me excited? Do the FAQs answer the questions I\'m afraid of being asked? A PM who can write a compelling PR/FAQ is a PM who has done the thinking.',
  ),
  DailyCoachTip(
    id: 'tip_d29', date: DateTime.now(), lane: 'social', laneColorValue: 0xFF34D399, isBookmarked: false,
    title: 'Viktor Frankl and the depleted motivation system',
    content: 'Viktor Frankl\'s concept of "tragic optimism" — finding meaning despite suffering. The question underneath your depleted state is not "how do I get more motivated?" It is: "what am I building this for?" The answer: recognition, impact, freedom, legacy. All of them. The full life. That is your meaning.',
  ),
  DailyCoachTip(
    id: 'tip_d30', date: DateTime.now(), lane: 'mind', laneColorValue: 0xFF8B5CF6, isBookmarked: false,
    title: 'Day 30: Month 1 complete. What actually happened.',
    content: 'You did not become a different person in 30 days. You built the infrastructure that makes becoming a different person possible. This is Month 1. Not the result. The foundation. Month 2 starts tomorrow. The system continues. You continue. That is the whole program.',
  ),
];

// ============================================================
// 7. WEEKLY REVIEW QUESTIONS
// ============================================================

final List<String> eminWeeklyReviewQuestions = [
  'Did I hit 10:30pm bedtime most nights this week? If not — what got in the way?',
  'Did I use the physiological sigh before pressure moments? How many times?',
  'Did I apply BLUF to my most important work output this week?',
  'Did I do my morning domain scan every day? What was the best insight?',
  'Did I go to the gym 3 times? Did I do face pulls every session?',
  'What is one thing I learned this week that I did not know last Monday?',
  'What happened at work that I handled better than I would have a month ago?',
  'Did I add to my Evidence Archive this week? What did I add?',
  'What was the hardest moment this week — and what did it reveal?',
  'What is the single most important thing I must do next week?',
  'What did I say I would do this week that I did not do? Why?',
  'Is there a real work situation I should bring to my coaching session?',
];

// ============================================================
// 8. ASSESSMENT PROFILE MAPPING
// ============================================================

Map<String, dynamic> eminAssessmentProfile = {
  'archetype': 'executive',
  'fitnessLevel': '3x per week',
  'styleLevel': 'Developing',
  'careerLevel': 'Senior',
  'readingLevel': 'Weekly',
  'socialConfidence': 'Okay',
  'linkedinStatus': 'Basic',
  'morningStatus': 'Chaotic',
  'biggestWeakness': 'Consistency',
  'admires': 'CEO/Founder',
  'timeframe': '6 months',
  'primaryLanes': ['skill', 'mind', 'body', 'social'],
  'weeklyGoalHours': {'skill': 4.0, 'mind': 2.0, 'body': 3.0, 'social': 1.0},
  'wakeUpTime': '06:00',
  'bedTime': '22:30',
  'preferredSessionLength': 30,
  'activeDays': [0, 1, 2, 3, 4],
};

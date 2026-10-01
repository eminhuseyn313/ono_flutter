import '../data/emin_personal_content.dart';

/// Role Model Journey System
///
/// Users choose an iconic figure as inspiration and start a transformation
/// path built around that person's known habits, philosophy, and disciplines.

enum RoleModelSector {
  mindset,
  sports,
  business,
  creativity,
  science,
  technology,
  music,
}

class JourneyAction {
  final String title;
  final String subtitle;
  final String lane; // mind, body, social, skill

  const JourneyAction({
    required this.title,
    required this.subtitle,
    required this.lane,
  });
}

class RoleModel {
  final String id;
  final String name;
  final String emoji;
  final RoleModelSector sector;
  final String tagline;
  final String bio;
  final String philosophy;
  final String philosophyQuote;
  final List<String> keyDisciplines;
  final List<JourneyAction> dailyActions;
  final int journeyDays; // recommended journey length

  const RoleModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.sector,
    required this.tagline,
    required this.bio,
    required this.philosophy,
    required this.philosophyQuote,
    required this.keyDisciplines,
    required this.dailyActions,
    this.journeyDays = 30,
  });
}

// ─── SECTOR METADATA ─────────────────────────────────────────────────────────

String sectorName(RoleModelSector s) {
  switch (s) {
    case RoleModelSector.mindset:
      return 'Mindset';
    case RoleModelSector.sports:
      return 'Sports';
    case RoleModelSector.business:
      return 'Business';
    case RoleModelSector.creativity:
      return 'Creativity';
    case RoleModelSector.science:
      return 'Science';
    case RoleModelSector.technology:
      return 'Technology';
    case RoleModelSector.music:
      return 'Music';
  }
}

String sectorEmoji(RoleModelSector s) {
  switch (s) {
    case RoleModelSector.mindset:
      return '🧠';
    case RoleModelSector.sports:
      return '🏆';
    case RoleModelSector.business:
      return '💼';
    case RoleModelSector.creativity:
      return '🎨';
    case RoleModelSector.science:
      return '🔬';
    case RoleModelSector.technology:
      return '💻';
    case RoleModelSector.music:
      return '🎵';
  }
}

// ─── ROLE MODELS DATABASE ────────────────────────────────────────────────────

/// Every role model in the app, with the personal one featured first.
final List<RoleModel> allRoleModels = [
  productArchitectRoleModel,
  ..._builtInRoleModels,
];

const _builtInRoleModels = <RoleModel>[
  // ══════════════════════════════════════════════════════════════════════════
  // MINDSET & PHILOSOPHY
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_marcus_aurelius',
    name: 'Marcus Aurelius',
    emoji: '🏛',
    sector: RoleModelSector.mindset,
    tagline: 'The Philosopher King',
    bio: 'Roman Emperor and Stoic philosopher who ruled one of history\'s greatest empires while maintaining inner discipline. His private journal, Meditations, became one of the most influential philosophy texts ever written.',
    philosophy: 'Stoic mastery — control what you can, accept what you can\'t, and find virtue in every challenge.',
    philosophyQuote: 'You have power over your mind — not outside events. Realize this, and you will find strength.',
    keyDisciplines: ['Morning journaling & self-examination', 'Negative visualization (premeditatio malorum)', 'Emotional control under pressure', 'Evening review of the day\'s actions'],
    dailyActions: [
      JourneyAction(title: 'Morning Meditation', subtitle: '10 minutes of silent reflection on what you can control today', lane: 'mind'),
      JourneyAction(title: 'Stoic Journal Entry', subtitle: 'Write 3 things: what went well, what didn\'t, what you\'ll improve', lane: 'skill'),
      JourneyAction(title: 'Voluntary Discomfort', subtitle: 'Cold shower, skip a meal, or walk in bad weather — build resilience', lane: 'body'),
      JourneyAction(title: 'Practice Empathy', subtitle: 'In every interaction today, assume the best in people', lane: 'social'),
      JourneyAction(title: 'Evening Review', subtitle: 'Before bed: "Did I act with virtue today? Where did I fall short?"', lane: 'mind'),
      JourneyAction(title: 'Read Philosophy', subtitle: '15 minutes of Stoic texts — Meditations, Seneca, Epictetus', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_david_goggins',
    name: 'David Goggins',
    emoji: '🔥',
    sector: RoleModelSector.mindset,
    tagline: 'The Hardest Man Alive',
    bio: 'Former Navy SEAL, ultra-endurance athlete, and the embodiment of mental toughness. Went from 300 pounds to completing Hell Week three times, running 100-mile races, and breaking pull-up records.',
    philosophy: 'The 40% Rule — when your mind tells you you\'re done, you\'re only at 40% of your capacity. Suffering is the path to growth.',
    philosophyQuote: 'You are in danger of living a life so comfortable and soft that you will die without ever realizing your true potential.',
    keyDisciplines: ['Wake up before dawn — no snooze', 'Run when you don\'t want to', 'Embrace suffering as fuel', 'Accountability mirror — face the truth daily'],
    dailyActions: [
      JourneyAction(title: '5 AM Wake-Up', subtitle: 'Alarm goes off, feet hit the floor. No negotiation.', lane: 'mind'),
      JourneyAction(title: 'Hard Workout', subtitle: 'Run, lift, or PT — push past the point where you want to quit', lane: 'body'),
      JourneyAction(title: 'Accountability Mirror', subtitle: 'Look yourself in the eye and state what you need to fix', lane: 'mind'),
      JourneyAction(title: 'Do Something You Hate', subtitle: 'Pick the task you\'ve been avoiding all week — do it first', lane: 'skill'),
      JourneyAction(title: 'No Complaining', subtitle: 'Zero complaints today — not even in your own head', lane: 'social'),
      JourneyAction(title: 'Stretch Session', subtitle: '15 minutes of deep stretching — take care of your body', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_miyamoto_musashi',
    name: 'Miyamoto Musashi',
    emoji: '⚔️',
    sector: RoleModelSector.mindset,
    tagline: 'The Undefeated Swordsman',
    bio: 'Legendary Japanese swordsman, undefeated in 61 duels. Author of The Book of Five Rings. Mastered the way of strategy and lived as a ronin who perfected every aspect of himself.',
    philosophy: 'The Way is in training. Master yourself, study broadly, and never stop refining your craft.',
    philosophyQuote: 'There is nothing outside of yourself that can ever enable you to get better, stronger, richer, quicker, or smarter. Everything is within.',
    keyDisciplines: ['Practice your craft daily without exception', 'Study widely — art, strategy, nature', 'Accept death to live without fear', 'Never rely on a single skill'],
    dailyActions: [
      JourneyAction(title: 'Focused Craft Practice', subtitle: '30 minutes of deliberate practice on your primary skill', lane: 'skill'),
      JourneyAction(title: 'Physical Training', subtitle: 'Bodyweight exercises or martial arts — sharpen the body', lane: 'body'),
      JourneyAction(title: 'Study Something New', subtitle: 'Read or study a field outside your expertise for 20 min', lane: 'mind'),
      JourneyAction(title: 'Sit in Silence', subtitle: '10 minutes of stillness — observe your thoughts without reacting', lane: 'mind'),
      JourneyAction(title: 'Teach or Share Knowledge', subtitle: 'Explain something you know well to someone today', lane: 'social'),
      JourneyAction(title: 'Simplify One Thing', subtitle: 'Remove one unnecessary possession, habit, or distraction', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_ryan_holiday',
    name: 'Ryan Holiday',
    emoji: '📚',
    sector: RoleModelSector.mindset,
    tagline: 'The Modern Stoic',
    bio: 'Bestselling author who brought Stoicism to a new generation through books like The Obstacle Is the Way and Ego Is the Enemy. Dropped out of college at 19 to become a marketing strategist, then pivoted to philosophy.',
    philosophy: 'The obstacle is the way. Turn every setback into fuel. The ego is your enemy; discipline and humility are your allies.',
    philosophyQuote: 'The impediment to action advances action. What stands in the way becomes the way.',
    keyDisciplines: ['Read one book per week minimum', 'Morning journaling before anything else', 'Physical exercise daily — usually swimming', 'Practice negative visualization'],
    dailyActions: [
      JourneyAction(title: 'Morning Pages', subtitle: 'Write freely for 15 minutes before checking any screen', lane: 'mind'),
      JourneyAction(title: 'Read for 45 Minutes', subtitle: 'Philosophy, biography, history — no social media substitutes', lane: 'skill'),
      JourneyAction(title: 'Physical Movement', subtitle: '30 min of swimming, running, or hiking — clear the mind', lane: 'body'),
      JourneyAction(title: 'Practice Gratitude', subtitle: 'Write 3 specific things you\'re grateful for today', lane: 'mind'),
      JourneyAction(title: 'Deep Conversation', subtitle: 'Have one meaningful exchange without checking your phone', lane: 'social'),
      JourneyAction(title: 'Create One Thing', subtitle: 'Write a page, draft an idea, or make something tangible', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_wim_hof',
    name: 'Wim Hof',
    emoji: '🧊',
    sector: RoleModelSector.mindset,
    tagline: 'The Iceman',
    bio: 'Dutch extreme athlete who holds 26 world records including longest ice bath. Developed the Wim Hof Method combining cold therapy, breathwork, and meditation — scientifically proven to influence the immune system.',
    philosophy: 'We can do more than we think. The cold is your warm friend. Through breath and cold, you master your own biology.',
    philosophyQuote: 'If you can learn how to use your mind, anything is possible.',
    keyDisciplines: ['Cold exposure every single day', 'Breathwork practice morning and evening', 'Meditation in extreme conditions', 'Push comfort zones progressively'],
    dailyActions: [
      JourneyAction(title: 'Wim Hof Breathing', subtitle: '3 rounds of 30 power breaths with retention holds', lane: 'mind'),
      JourneyAction(title: 'Cold Shower', subtitle: '2-3 minutes under cold water — breathe through the discomfort', lane: 'body'),
      JourneyAction(title: 'Meditation', subtitle: '10 minutes of focused breathing meditation', lane: 'mind'),
      JourneyAction(title: 'Outdoor Exercise', subtitle: '30 min exercise outdoors regardless of weather', lane: 'body'),
      JourneyAction(title: 'Share the Method', subtitle: 'Teach someone about breathwork or cold therapy today', lane: 'social'),
      JourneyAction(title: 'Journal Your Limits', subtitle: 'Write about a comfort zone you pushed past today', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_tim_ferriss',
    name: 'Tim Ferriss',
    emoji: '⏱',
    sector: RoleModelSector.mindset,
    tagline: 'The Life Hacker',
    bio: 'Author of The 4-Hour Workweek, angel investor, and podcast host who has deconstructed world-class performers across every field. Pioneer of lifestyle design and systematic self-experimentation.',
    philosophy: 'Focus on the 20% that produces 80% of results. Fear-setting over goal-setting. Life is too short for long-term misery.',
    philosophyQuote: 'A person\'s success in life can usually be measured by the number of uncomfortable conversations they are willing to have.',
    keyDisciplines: ['Morning routine: make bed, journal, meditate, exercise', 'Batch tasks and eliminate the unimportant', 'Run small experiments on everything', 'Seek out world-class mentors'],
    dailyActions: [
      JourneyAction(title: '5-Minute Journal', subtitle: 'Morning: 3 gratitudes, 3 priorities. Evening: 3 wins.', lane: 'mind'),
      JourneyAction(title: 'Morning Movement', subtitle: '20 min exercise — AcroYoga, kettlebells, or cold plunge', lane: 'body'),
      JourneyAction(title: 'One Scary Thing', subtitle: 'Do something that makes you uncomfortable — a call, a pitch, a ask', lane: 'social'),
      JourneyAction(title: 'Skill Deconstruction', subtitle: 'Break down one skill into its smallest learnable parts', lane: 'skill'),
      JourneyAction(title: 'Eliminate One Task', subtitle: 'Remove or automate one thing from your to-do list', lane: 'skill'),
      JourneyAction(title: 'Read or Listen', subtitle: '30 min of non-fiction — books or in-depth interviews', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // SPORTS & FITNESS
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_cristiano_ronaldo',
    name: 'Cristiano Ronaldo',
    emoji: '⚽',
    sector: RoleModelSector.sports,
    tagline: 'The Relentless Machine',
    bio: 'From humble beginnings in Madeira to becoming one of the greatest athletes in history. 5x Ballon d\'Or winner whose obsessive discipline, diet, and work ethic set the standard for athletic excellence.',
    philosophy: 'Talent is nothing without relentless work. Your body is your instrument — treat it like one.',
    philosophyQuote: 'I\'m not going to change the way I am. I will always want to be the best, and that requires sacrifice.',
    keyDisciplines: ['Strict sleep schedule — 5 naps of 90 min', 'Clean diet — no sugar, no alcohol', 'Extra training sessions beyond the team', 'Visualization before every game'],
    dailyActions: [
      JourneyAction(title: 'Morning Workout', subtitle: '45 min of strength or cardio — before anything else', lane: 'body'),
      JourneyAction(title: 'Clean Eating', subtitle: 'No processed food, no sugar today. Fuel the machine.', lane: 'body'),
      JourneyAction(title: 'Visualization', subtitle: '10 min: close your eyes and visualize your perfect performance', lane: 'mind'),
      JourneyAction(title: 'Extra Practice', subtitle: '20 min of skill work beyond your normal routine', lane: 'skill'),
      JourneyAction(title: 'Sleep by 10:30 PM', subtitle: 'Recovery is non-negotiable. Lights out early.', lane: 'body'),
      JourneyAction(title: 'Motivate Someone', subtitle: 'Encourage a teammate, friend, or family member today', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_kobe_bryant',
    name: 'Kobe Bryant',
    emoji: '🏀',
    sector: RoleModelSector.sports,
    tagline: 'Mamba Mentality',
    bio: '5x NBA champion who embodied relentless competitive drive. Created the "Mamba Mentality" — a philosophy of obsessive improvement, fearlessness, and never settling for good enough.',
    philosophy: 'Mamba Mentality is about the constant quest to be the best version of yourself. It\'s not about the result — it\'s about the process.',
    philosophyQuote: 'I have nothing in common with lazy people who blame others for their lack of success.',
    keyDisciplines: ['4 AM workouts — outwork everyone', 'Study film obsessively — learn from the greats', 'Ask questions constantly — stay curious', 'Never take a day off mentally'],
    dailyActions: [
      JourneyAction(title: 'Early Morning Session', subtitle: 'Train before the world wakes up — 4 or 5 AM', lane: 'body'),
      JourneyAction(title: 'Study the Greats', subtitle: 'Watch or read about someone elite in your field for 20 min', lane: 'skill'),
      JourneyAction(title: 'Ask One Great Question', subtitle: 'Find someone knowledgeable and ask a deep, thoughtful question', lane: 'social'),
      JourneyAction(title: 'Reps, Reps, Reps', subtitle: 'Repeat one skill 100+ times until the movement is automatic', lane: 'skill'),
      JourneyAction(title: 'Mental Film Study', subtitle: 'Replay today in your mind — what would Mamba do differently?', lane: 'mind'),
      JourneyAction(title: 'Recovery & Stretch', subtitle: '15 min of stretching, foam rolling, and breath work', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_arnold',
    name: 'Arnold Schwarzenegger',
    emoji: '💪',
    sector: RoleModelSector.sports,
    tagline: 'The Self-Made Titan',
    bio: 'From a small Austrian village to Mr. Olympia, Hollywood icon, and Governor. The ultimate proof that vision plus relentless work can rewrite your entire life story.',
    philosophy: 'Have a vision so clear you can taste it, then work so hard that talent becomes irrelevant.',
    philosophyQuote: 'The mind is the limit. As long as the mind can envision the fact that you can do something, you can do it.',
    keyDisciplines: ['Train twice a day — no shortcuts', 'Set clear, written goals', 'Learn something new every day', 'Help others on their journey'],
    dailyActions: [
      JourneyAction(title: 'Lift Heavy', subtitle: '45+ min of strength training — progressive overload', lane: 'body'),
      JourneyAction(title: 'Write Your Goals', subtitle: 'Review and write down your top 3 goals for this week', lane: 'mind'),
      JourneyAction(title: 'Learn a New Skill', subtitle: '20 min learning something outside your comfort zone', lane: 'skill'),
      JourneyAction(title: 'High-Protein Meal Prep', subtitle: 'Prepare or plan at least one clean, high-protein meal', lane: 'body'),
      JourneyAction(title: 'Connect & Inspire', subtitle: 'Reach out to someone and share genuine encouragement', lane: 'social'),
      JourneyAction(title: 'Evening Cardio', subtitle: '20 min walk, bike, or swim — second session of movement', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_michael_jordan',
    name: 'Michael Jordan',
    emoji: '🐐',
    sector: RoleModelSector.sports,
    tagline: 'His Airness',
    bio: '6x NBA champion, 5x MVP, and widely regarded as the greatest basketball player ever. His ruthless competitiveness, clutch performances, and refusal to lose redefined what it means to be the best.',
    philosophy: 'I\'ve failed over and over and over again in my life. And that is why I succeed. Winning isn\'t given — it\'s taken.',
    philosophyQuote: 'Some people want it to happen, some wish it would happen, others make it happen.',
    keyDisciplines: ['Use every slight as fuel — create motivation from nothing', 'Practice harder than you play', 'Be the first in the gym and the last to leave', 'Demand excellence from yourself and everyone around you'],
    dailyActions: [
      JourneyAction(title: 'Competitive Workout', subtitle: '45 min of intense training — compete against yourself', lane: 'body'),
      JourneyAction(title: 'Find Your Fuel', subtitle: 'Identify one thing that motivates you today and channel it', lane: 'mind'),
      JourneyAction(title: 'Skill Drilling', subtitle: '30 min of deliberate, focused practice on your weakest area', lane: 'skill'),
      JourneyAction(title: 'Lead by Example', subtitle: 'Show someone what excellence looks like through action, not words', lane: 'social'),
      JourneyAction(title: 'Film Study', subtitle: 'Analyze your own performance — where did you fall short?', lane: 'mind'),
      JourneyAction(title: 'Recovery Protocol', subtitle: 'Stretch, hydrate, sleep prep — champions recover hard', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_lebron_james',
    name: 'LeBron James',
    emoji: '👑',
    sector: RoleModelSector.sports,
    tagline: 'The Longevity King',
    bio: 'From Akron to becoming a 4x NBA champion and billionaire athlete. Spends over \$1.5M annually on body maintenance. Proof that greatness is sustained through investment in yourself.',
    philosophy: 'Nothing is given. Everything is earned. Take care of your body — it\'s the only one you get. Strive for greatness.',
    philosophyQuote: 'I like criticism. It makes you strong.',
    keyDisciplines: ['Sleep 8-10 hours with strict routine', 'Invest heavily in body recovery', 'Study film of every opponent', 'Give back to the community that raised you'],
    dailyActions: [
      JourneyAction(title: 'Morning Activation', subtitle: 'Mobility work, stretching, and core activation — prep the body', lane: 'body'),
      JourneyAction(title: 'Skill Work', subtitle: '30 min of focused practice on your craft', lane: 'skill'),
      JourneyAction(title: 'Recovery Investment', subtitle: 'Cryotherapy, massage, or deep stretching — invest in longevity', lane: 'body'),
      JourneyAction(title: 'Study Your Field', subtitle: '20 min analyzing top performers or studying your next challenge', lane: 'mind'),
      JourneyAction(title: 'Mentor Someone', subtitle: 'Share wisdom or encouragement with someone coming up behind you', lane: 'social'),
      JourneyAction(title: 'Sleep Protocol', subtitle: 'No screens 1 hour before bed, room at 67°F, 8+ hours', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_muhammad_ali',
    name: 'Muhammad Ali',
    emoji: '🦋',
    sector: RoleModelSector.sports,
    tagline: 'The Greatest',
    bio: 'Three-time world heavyweight champion who transcended boxing to become the most recognizable person on earth. Stood for his beliefs at the cost of his career, proving that true champions fight for more than titles.',
    philosophy: 'Float like a butterfly, sting like a bee. Champions are made from something deep inside — a desire, a dream, a vision.',
    philosophyQuote: 'He who is not courageous enough to take risks will accomplish nothing in life.',
    keyDisciplines: ['Train with absolute intensity', 'Speak your truth fearlessly', 'Sacrifice comfort for your beliefs', 'Visualize victory before the fight'],
    dailyActions: [
      JourneyAction(title: 'Roadwork', subtitle: '30 min of running or intense cardio — build your engine', lane: 'body'),
      JourneyAction(title: 'Affirm Yourself', subtitle: 'Stand in the mirror and state who you are and what you will become', lane: 'mind'),
      JourneyAction(title: 'Shadow Practice', subtitle: '15 min of shadow boxing or skill visualization', lane: 'skill'),
      JourneyAction(title: 'Stand for Something', subtitle: 'Speak up about something you believe in, even if it\'s unpopular', lane: 'social'),
      JourneyAction(title: 'Study the Greats', subtitle: 'Read about a historical figure who stood their ground', lane: 'mind'),
      JourneyAction(title: 'Flexibility Work', subtitle: '15 min of stretching — speed requires flexibility', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_conor_mcgregor',
    name: 'Conor McGregor',
    emoji: '☘️',
    sector: RoleModelSector.sports,
    tagline: 'The Notorious',
    bio: 'From collecting welfare checks in Dublin to becoming the first UFC fighter to hold titles in two weight classes simultaneously. His unshakeable self-belief and visualization made the impossible inevitable.',
    philosophy: 'If you can see it and believe it, it is a lot easier to achieve it. Doubt is only removed by action.',
    philosophyQuote: 'We\'re not just here to take part — we\'re here to take over.',
    keyDisciplines: ['Visualize success in vivid detail', 'Movement practice — flow like water', 'Absolute self-belief — speak it into existence', 'Train across multiple disciplines'],
    dailyActions: [
      JourneyAction(title: 'Movement Training', subtitle: '45 min of martial arts, mobility, or dynamic movement', lane: 'body'),
      JourneyAction(title: 'Visualization', subtitle: '10 min: see yourself succeeding in vivid, emotional detail', lane: 'mind'),
      JourneyAction(title: 'Speak It Into Existence', subtitle: 'State your goals out loud — to yourself or someone else', lane: 'social'),
      JourneyAction(title: 'Cross-Train', subtitle: '20 min practicing a skill outside your main discipline', lane: 'skill'),
      JourneyAction(title: 'Believe the Impossible', subtitle: 'Write down one "impossible" goal and one step toward it', lane: 'mind'),
      JourneyAction(title: 'Conditioning', subtitle: '15 min of intense cardio — build an unbreakable engine', lane: 'body'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // BUSINESS & LEADERSHIP
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_naval',
    name: 'Naval Ravikant',
    emoji: '🧭',
    sector: RoleModelSector.business,
    tagline: 'The Angel Philosopher',
    bio: 'Silicon Valley angel investor and philosopher who broke down wealth creation and happiness into first principles. His tweetstorms and podcast appearances became a blueprint for the modern polymath.',
    philosophy: 'Seek wealth, not money. Build leverage through code, media, and capital. Happiness is a skill you train.',
    philosophyQuote: 'Earn with your mind, not your time.',
    keyDisciplines: ['Read for 1+ hours daily — foundational knowledge', 'Meditate daily — clear the mental cache', 'Build specific knowledge that can\'t be taught', 'Create accountability by putting your name on things'],
    dailyActions: [
      JourneyAction(title: 'Read for 60 Minutes', subtitle: 'Books, not feeds. Science, philosophy, history, biography.', lane: 'mind'),
      JourneyAction(title: 'Meditate', subtitle: '20 min of silent, unguided meditation — sit with your thoughts', lane: 'mind'),
      JourneyAction(title: 'Build in Public', subtitle: 'Create one piece of content, code, or work under your own name', lane: 'skill'),
      JourneyAction(title: 'Exercise', subtitle: '30 min — walking, lifting, or yoga. Healthy body, clear mind.', lane: 'body'),
      JourneyAction(title: 'Have a Real Conversation', subtitle: 'One deep, unrushed conversation with someone interesting', lane: 'social'),
      JourneyAction(title: 'Write One Idea', subtitle: 'Capture one original thought or insight in writing', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_hormozi',
    name: 'Alex Hormozi',
    emoji: '📈',
    sector: RoleModelSector.business,
    tagline: 'The Acquisition Machine',
    bio: 'Built and scaled multiple businesses from zero to \$100M+. Known for his no-BS approach to business, obsessive work ethic, and philosophy that volume is the prerequisite to mastery.',
    philosophy: 'Do more. Volume negates luck. The person who takes the most shots wins. Stop overthinking, start executing.',
    philosophyQuote: 'You\'re one skill away from changing your entire financial trajectory.',
    keyDisciplines: ['Work 12+ focused hours daily', 'Track everything — what gets measured gets managed', 'Sell every single day', 'Invest in skills, not status'],
    dailyActions: [
      JourneyAction(title: 'Deep Work Block', subtitle: '3 hours of uninterrupted, high-value work. Phone off.', lane: 'skill'),
      JourneyAction(title: 'Make an Offer', subtitle: 'Pitch, sell, or propose something to someone today', lane: 'social'),
      JourneyAction(title: 'Track Your Numbers', subtitle: 'Log your key metrics — revenue, leads, output, progress', lane: 'skill'),
      JourneyAction(title: 'Train Your Body', subtitle: '45 min of lifting — discipline transfers to business', lane: 'body'),
      JourneyAction(title: 'Learn One Business Concept', subtitle: 'Read, watch, or study one marketing/sales/ops idea', lane: 'mind'),
      JourneyAction(title: 'Eliminate One Distraction', subtitle: 'Cut one time-wasting habit or task that doesn\'t drive results', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_jocko',
    name: 'Jocko Willink',
    emoji: '🎖',
    sector: RoleModelSector.business,
    tagline: 'Discipline Equals Freedom',
    bio: 'Retired Navy SEAL commander, author, and leadership expert. Led SEAL Team 3\'s Task Unit Bruiser in Ramadi. Turned extreme ownership and military discipline into a framework for civilian success.',
    philosophy: 'Discipline equals freedom. Take extreme ownership of everything in your life. There are no bad teams, only bad leaders.',
    philosophyQuote: 'Don\'t expect to be motivated every day. You must be disciplined.',
    keyDisciplines: ['4:30 AM wake-up — every single day', 'Train first thing in the morning', 'Extreme ownership — no excuses, no blame', 'Lead from the front in everything'],
    dailyActions: [
      JourneyAction(title: '4:30 AM Alarm', subtitle: 'Get up. Get after it. Post the watch. No excuses.', lane: 'mind'),
      JourneyAction(title: 'Morning PT', subtitle: 'Lift, run, or do calisthenics — before sunrise', lane: 'body'),
      JourneyAction(title: 'Take Ownership', subtitle: 'Find one problem today and own it completely — no blame', lane: 'mind'),
      JourneyAction(title: 'Lead Someone', subtitle: 'Help, mentor, or guide someone who needs direction', lane: 'social'),
      JourneyAction(title: 'Read 30 Minutes', subtitle: 'History, leadership, strategy — sharpen the mind', lane: 'skill'),
      JourneyAction(title: 'Plan Tomorrow Tonight', subtitle: 'Write down tomorrow\'s priorities before lights out', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_gary_vee',
    name: 'Gary Vaynerchuk',
    emoji: '📱',
    sector: RoleModelSector.business,
    tagline: 'Hustle & Heart',
    bio: 'Built his family wine business from \$3M to \$60M, then built VaynerMedia into a global agency. Known for his relentless content output, brutal honesty about entrepreneurship, and genuine care for people.',
    philosophy: 'Patience + hustle. Create content, build your brand, and play the long game. Macro patience, micro speed.',
    philosophyQuote: 'Skills are cheap. Passion is priceless.',
    keyDisciplines: ['Create 100+ pieces of content daily', 'DM people, build real relationships', 'Document, don\'t create', 'Practice radical self-awareness'],
    dailyActions: [
      JourneyAction(title: 'Create 3 Pieces of Content', subtitle: 'Write, record, or design — put yourself out there', lane: 'skill'),
      JourneyAction(title: 'DM 5 People', subtitle: 'Reach out to 5 people with genuine value — no pitching', lane: 'social'),
      JourneyAction(title: 'Self-Awareness Check', subtitle: 'Honestly assess: what are you good at? What should you stop doing?', lane: 'mind'),
      JourneyAction(title: 'Move Your Body', subtitle: '30 min workout — energy is the foundation of hustle', lane: 'body'),
      JourneyAction(title: 'Consume Zero News', subtitle: 'No news, no doomscrolling — protect your mental energy', lane: 'mind'),
      JourneyAction(title: 'Study a Platform', subtitle: '15 min studying what works on one social platform', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_ray_dalio',
    name: 'Ray Dalio',
    emoji: '📊',
    sector: RoleModelSector.business,
    tagline: 'Principles-Based',
    bio: 'Founded Bridgewater Associates, the world\'s largest hedge fund. Built a culture of radical transparency and systematic decision-making. His book Principles became the definitive framework for rational life design.',
    philosophy: 'Pain + reflection = progress. Write down principles for every decision. Radical truth and radical transparency lead to meaningful work.',
    philosophyQuote: 'He who lives by the crystal ball will eat shattered glass.',
    keyDisciplines: ['Write principles for every major decision', 'Seek out disagreement from smart people', 'Meditate daily for clarity', 'Systematize everything that can be systematized'],
    dailyActions: [
      JourneyAction(title: 'Morning Meditation', subtitle: '20 minutes of Transcendental Meditation — clarity first', lane: 'mind'),
      JourneyAction(title: 'Write a Principle', subtitle: 'Turn one lesson or failure into a written principle you can reuse', lane: 'skill'),
      JourneyAction(title: 'Seek Disagreement', subtitle: 'Ask someone to challenge your thinking on a decision you\'re facing', lane: 'social'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of movement — walking, swimming, or weights', lane: 'body'),
      JourneyAction(title: 'Reflect on Pain', subtitle: 'Identify one failure or frustration and extract the lesson', lane: 'mind'),
      JourneyAction(title: 'Study Systems', subtitle: '20 min learning about how economic, natural, or social systems work', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_robert_greene',
    name: 'Robert Greene',
    emoji: '📕',
    sector: RoleModelSector.business,
    tagline: 'The Strategist',
    bio: 'Author of The 48 Laws of Power, Mastery, and The Laws of Human Nature. Spent decades studying history\'s greatest strategists to extract timeless principles of power, influence, and self-mastery.',
    philosophy: 'Master yourself first. Understand human nature deeply. Apprentice under a master. Never outshine the master until you\'re ready.',
    philosophyQuote: 'The future belongs to those who learn more skills and combine them in creative ways.',
    keyDisciplines: ['Observe people deeply before speaking', 'Study history obsessively', 'Apprentice in a craft for years before creating', 'Practice strategic patience'],
    dailyActions: [
      JourneyAction(title: 'Deep Reading', subtitle: '45 min of history, biography, or psychology — study human nature', lane: 'mind'),
      JourneyAction(title: 'Observe Without Speaking', subtitle: 'In one conversation today, listen twice as much as you talk', lane: 'social'),
      JourneyAction(title: 'Deliberate Practice', subtitle: '30 min of focused skill-building in your chosen craft', lane: 'skill'),
      JourneyAction(title: 'Physical Discipline', subtitle: '30 min exercise — the body trains the mind\'s discipline', lane: 'body'),
      JourneyAction(title: 'Strategic Thinking', subtitle: 'Map out a challenge you\'re facing — what are the hidden dynamics?', lane: 'mind'),
      JourneyAction(title: 'Write a Page', subtitle: 'Write one page of notes, observations, or original thinking', lane: 'skill'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // CREATIVITY
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_da_vinci',
    name: 'Leonardo da Vinci',
    emoji: '🎨',
    sector: RoleModelSector.creativity,
    tagline: 'The Ultimate Polymath',
    bio: 'Painter, inventor, scientist, engineer, anatomist, writer. The original Renaissance man who proved that curiosity, observation, and relentless experimentation can unlock genius across every field.',
    philosophy: 'Curiosity is the engine of achievement. Observe everything. Question everything. Connect everything.',
    philosophyQuote: 'Learning never exhausts the mind.',
    keyDisciplines: ['Keep a daily notebook of observations and ideas', 'Study nature and anatomy in detail', 'Cross-pollinate knowledge across fields', 'Iterate and prototype relentlessly'],
    dailyActions: [
      JourneyAction(title: 'Fill a Notebook Page', subtitle: 'Sketch, write, or diagram one idea or observation', lane: 'skill'),
      JourneyAction(title: 'Observe Nature', subtitle: '15 min of close observation — how does light fall? How do things move?', lane: 'mind'),
      JourneyAction(title: 'Cross-Pollinate', subtitle: 'Connect an idea from one field to a completely different one', lane: 'mind'),
      JourneyAction(title: 'Build or Prototype', subtitle: 'Make something with your hands — rough is fine', lane: 'skill'),
      JourneyAction(title: 'Walk & Think', subtitle: '30 min walk without headphones — let ideas collide', lane: 'body'),
      JourneyAction(title: 'Discuss an Idea', subtitle: 'Share a half-formed idea with someone and invite their perspective', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_bruce_lee',
    name: 'Bruce Lee',
    emoji: '🐉',
    sector: RoleModelSector.creativity,
    tagline: 'Be Water, My Friend',
    bio: 'Martial artist, philosopher, filmmaker, and cultural icon. Created Jeet Kune Do by breaking the rules of traditional martial arts. Proved that mastery comes from absorbing what is useful and discarding what is not.',
    philosophy: 'Absorb what is useful, discard what is useless, add what is specifically your own. Be formless, shapeless — like water.',
    philosophyQuote: 'I fear not the man who has practiced 10,000 kicks once, but I fear the man who has practiced one kick 10,000 times.',
    keyDisciplines: ['Train the body and mind as one system', 'Simplify — strip away the unnecessary', 'Practice one technique until it\'s instinct', 'Express yourself honestly through your craft'],
    dailyActions: [
      JourneyAction(title: 'Martial Arts or Movement', subtitle: '30 min of structured physical practice — controlled, intentional', lane: 'body'),
      JourneyAction(title: 'Master One Move', subtitle: 'Pick one technique or skill and drill it 50+ times', lane: 'skill'),
      JourneyAction(title: 'Read Philosophy', subtitle: '15 min of Tao, Zen, or martial arts philosophy', lane: 'mind'),
      JourneyAction(title: 'Flexibility Training', subtitle: '15 min of deep stretching — a flexible body = a flexible mind', lane: 'body'),
      JourneyAction(title: 'Express Yourself', subtitle: 'Create, write, or perform something authentically you', lane: 'skill'),
      JourneyAction(title: 'Honest Conversation', subtitle: 'Be direct and genuine with someone — no masks, no filters', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_steve_jobs',
    name: 'Steve Jobs',
    emoji: '🍎',
    sector: RoleModelSector.creativity,
    tagline: 'The Visionary Craftsman',
    bio: 'Co-founder of Apple who merged technology and liberal arts to create products that changed the world. Obsessed with design, simplicity, and creating things that make people\'s lives better.',
    philosophy: 'Stay hungry, stay foolish. Simplicity is the ultimate sophistication. Connect the dots looking backward.',
    philosophyQuote: 'Your time is limited — don\'t waste it living someone else\'s life.',
    keyDisciplines: ['Obsess over the details others ignore', 'Say no to 1,000 things to say yes to 1', 'Walk meetings — think on your feet', 'Seek the intersection of technology and art'],
    dailyActions: [
      JourneyAction(title: 'Morning Walk', subtitle: '30 min walk — Steve\'s go-to for thinking clearly', lane: 'body'),
      JourneyAction(title: 'Simplify Something', subtitle: 'Take one thing in your work or life and make it simpler', lane: 'skill'),
      JourneyAction(title: 'Say No', subtitle: 'Decline one request that doesn\'t align with your focus', lane: 'mind'),
      JourneyAction(title: 'Study Great Design', subtitle: 'Spend 15 min analyzing a beautifully designed product or space', lane: 'mind'),
      JourneyAction(title: 'Create Something', subtitle: 'Build, write, design, or prototype — ship, don\'t just plan', lane: 'skill'),
      JourneyAction(title: 'Inspire Your Team', subtitle: 'Share your vision with someone and make them believe in it', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_christopher_nolan',
    name: 'Christopher Nolan',
    emoji: '🎥',
    sector: RoleModelSector.creativity,
    tagline: 'The Time Architect',
    bio: 'Director of The Dark Knight, Inception, Interstellar, and Oppenheimer. Known for bending narrative structure, shooting on film, and creating intellectually ambitious blockbusters that respect the audience\'s intelligence.',
    philosophy: 'Tell stories that challenge people. Use limitations as creative fuel. The audience is smarter than you think — trust them.',
    philosophyQuote: 'Every film should have its own world, a logic and feel to it that expands beyond the edges of the screen.',
    keyDisciplines: ['No smartphone — protect your focus', 'Work with constraints, not despite them', 'Research obsessively before creating', 'Tell the story only you can tell'],
    dailyActions: [
      JourneyAction(title: 'Phone-Free Morning', subtitle: 'First 2 hours: no phone, no email — think freely', lane: 'mind'),
      JourneyAction(title: 'Deep Research', subtitle: '30 min diving deep into a subject that fascinates you', lane: 'skill'),
      JourneyAction(title: 'Create Within Constraints', subtitle: 'Set a limitation on a project and solve within it', lane: 'skill'),
      JourneyAction(title: 'Long Walk', subtitle: '30 min walk — Nolan\'s primary thinking tool', lane: 'body'),
      JourneyAction(title: 'Share a Complex Idea Simply', subtitle: 'Explain something complex to someone in a way they feel, not just understand', lane: 'social'),
      JourneyAction(title: 'Study Structure', subtitle: '15 min analyzing how a great story, product, or argument is structured', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_hayao_miyazaki',
    name: 'Hayao Miyazaki',
    emoji: '🎬',
    sector: RoleModelSector.creativity,
    tagline: 'The Dream Weaver',
    bio: 'Co-founder of Studio Ghibli and creator of Spirited Away, Princess Mononoke, and My Neighbor Totoro. Hand-draws every frame with relentless perfectionism. Makes art that matters, not art that sells.',
    philosophy: 'Create with your hands, not just your mind. Find beauty in nature and ordinary life. Never compromise on quality for speed.',
    philosophyQuote: 'I would like to make a film to tell children it\'s good to be alive.',
    keyDisciplines: ['Draw every single day by hand', 'Walk in nature for inspiration', 'Never rush the creative process', 'Care deeply about craft over commerce'],
    dailyActions: [
      JourneyAction(title: 'Draw or Create by Hand', subtitle: '30 min of handmade creative work — no digital shortcuts', lane: 'skill'),
      JourneyAction(title: 'Nature Walk', subtitle: '20 min in nature, observing details most people miss', lane: 'body'),
      JourneyAction(title: 'Protect Your Standards', subtitle: 'Refuse to ship one thing today that isn\'t your best work', lane: 'mind'),
      JourneyAction(title: 'Study the Mundane', subtitle: 'Find beauty in something ordinary — a meal, a shadow, a gesture', lane: 'mind'),
      JourneyAction(title: 'Mentor with Patience', subtitle: 'Help someone with their creative work without taking over', lane: 'social'),
      JourneyAction(title: 'Slow Down', subtitle: 'Do one task today at half speed with twice the attention', lane: 'skill'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // SCIENCE & OPTIMIZATION
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_huberman',
    name: 'Andrew Huberman',
    emoji: '🧬',
    sector: RoleModelSector.science,
    tagline: 'The Protocol Master',
    bio: 'Stanford neuroscientist who made cutting-edge brain and body science accessible to millions. His evidence-based protocols for sleep, focus, and performance have become the gold standard for self-optimization.',
    philosophy: 'Use science as your compass. Small, evidence-based protocols compound into massive life improvements.',
    philosophyQuote: 'The best tool for focus is your own ability to deliberately direct your attention.',
    keyDisciplines: ['Morning sunlight exposure within 30 min of waking', 'Deliberate cold exposure for dopamine', 'Non-sleep deep rest (NSDR) for recovery', 'Precise sleep timing and environment'],
    dailyActions: [
      JourneyAction(title: 'Morning Sunlight', subtitle: 'Get 10 min of direct sunlight within 30 min of waking', lane: 'body'),
      JourneyAction(title: 'Cold Exposure', subtitle: '1-3 min cold shower — deliberate cold for dopamine boost', lane: 'body'),
      JourneyAction(title: 'Focus Protocol', subtitle: '90 min deep work session — single task, no interruptions', lane: 'skill'),
      JourneyAction(title: 'NSDR Session', subtitle: '10 min non-sleep deep rest — guided body scan or yoga nidra', lane: 'mind'),
      JourneyAction(title: 'Exercise', subtitle: 'Resistance training or zone 2 cardio — alternate days', lane: 'body'),
      JourneyAction(title: 'Learn One Protocol', subtitle: 'Read or watch one evidence-based health/performance insight', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_feynman',
    name: 'Richard Feynman',
    emoji: '⚛️',
    sector: RoleModelSector.science,
    tagline: 'The Curious Genius',
    bio: 'Nobel Prize-winning physicist who cracked quantum electrodynamics, helped build the atomic bomb, and never lost his childlike curiosity. Famous for making complex ideas simple and for relentless intellectual honesty.',
    philosophy: 'The first principle is that you must not fool yourself — and you are the easiest person to fool. Stay curious. Teach to learn.',
    philosophyQuote: 'I would rather have questions that can\'t be answered than answers that can\'t be questioned.',
    keyDisciplines: ['Learn by teaching — the Feynman Technique', 'Play with problems — approach with curiosity', 'Admit what you don\'t know — honestly', 'Cross boundaries between fields freely'],
    dailyActions: [
      JourneyAction(title: 'Teach One Thing', subtitle: 'Explain a concept to someone as if they\'re 12 — if you can\'t, you don\'t know it', lane: 'social'),
      JourneyAction(title: 'Ask a Dumb Question', subtitle: 'Challenge an assumption you\'ve never questioned before', lane: 'mind'),
      JourneyAction(title: 'Play with a Problem', subtitle: '20 min on a puzzle, math problem, or intellectual challenge — for fun', lane: 'skill'),
      JourneyAction(title: 'Learn from a New Field', subtitle: 'Read or watch something from a domain you know nothing about', lane: 'mind'),
      JourneyAction(title: 'Write Simply', subtitle: 'Take something complex and write it in plain language', lane: 'skill'),
      JourneyAction(title: 'Move Your Body', subtitle: 'Walk, drum, dance — Feynman believed play unlocks insight', lane: 'body'),
    ],
  ),

  RoleModel(
    id: 'rm_nikola_tesla',
    name: 'Nikola Tesla',
    emoji: '⚡',
    sector: RoleModelSector.science,
    tagline: 'The Visionary Inventor',
    bio: 'Serbian-American inventor who gave the world alternating current, radio foundations, and over 300 patents. Visualized complete inventions in his mind before building them. The archetype of pure, obsessive genius.',
    philosophy: 'The present is theirs. The future, for which I really worked, is mine. Imagination is the preview of life\'s coming attractions.',
    philosophyQuote: 'If you want to find the secrets of the universe, think in terms of energy, frequency and vibration.',
    keyDisciplines: ['Visualize inventions completely before building', 'Walk 10+ miles daily for thinking', 'Work in deep isolation when creating', 'Sleep precisely — short and scheduled'],
    dailyActions: [
      JourneyAction(title: 'Visualization Practice', subtitle: '15 min: close your eyes and build a complete idea in your mind', lane: 'mind'),
      JourneyAction(title: 'Long Walk', subtitle: '45+ min walk — Tesla\'s primary thinking tool', lane: 'body'),
      JourneyAction(title: 'Deep Focus Session', subtitle: '2 hours of solitary, uninterrupted creative work', lane: 'skill'),
      JourneyAction(title: 'Study Electricity or Physics', subtitle: '20 min learning about energy, systems, or engineering', lane: 'mind'),
      JourneyAction(title: 'Invent or Design', subtitle: 'Sketch, prototype, or plan something original — however rough', lane: 'skill'),
      JourneyAction(title: 'Share Your Vision', subtitle: 'Tell someone about an idea you\'re excited about', lane: 'social'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // TECHNOLOGY
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_elon_musk',
    name: 'Elon Musk',
    emoji: '🚀',
    sector: RoleModelSector.technology,
    tagline: 'The Mars Architect',
    bio: 'Built PayPal, Tesla, SpaceX, and Neuralink. Known for first-principles thinking, insane work ethic, and tackling problems most people consider impossible. Wants to make humanity multi-planetary.',
    philosophy: 'Think from first principles, not by analogy. If something is important enough, you should try — even if the probable outcome is failure.',
    philosophyQuote: 'When something is important enough, you do it even if the odds are not in your favor.',
    keyDisciplines: ['First-principles reasoning for every decision', 'Time-blocking in 5-minute increments', 'Sleep 6 hours — no more, no less', 'Rapid iteration — fail fast, learn faster'],
    dailyActions: [
      JourneyAction(title: 'First Principles Thinking', subtitle: 'Take one belief or problem and break it down to fundamental truths', lane: 'mind'),
      JourneyAction(title: 'Time-Block Your Day', subtitle: 'Schedule your day in tight blocks — protect every hour', lane: 'skill'),
      JourneyAction(title: 'Build Something', subtitle: '60 min of building — code, design, write, create', lane: 'skill'),
      JourneyAction(title: 'Physical Training', subtitle: '30 min workout — Elon lifts and does cardio for mental clarity', lane: 'body'),
      JourneyAction(title: 'Learn Physics or Engineering', subtitle: '20 min studying how things actually work at a fundamental level', lane: 'mind'),
      JourneyAction(title: 'Collaborate on a Hard Problem', subtitle: 'Work with someone on a challenge neither of you can solve alone', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_sam_altman',
    name: 'Sam Altman',
    emoji: '🤖',
    sector: RoleModelSector.technology,
    tagline: 'The AI Pioneer',
    bio: 'CEO of OpenAI and former president of Y Combinator. Went from running the world\'s top startup accelerator to leading the company building artificial general intelligence. Thinks in decades, not quarters.',
    philosophy: 'Be optimistic about the future. Compound growth applies to skills, relationships, and ideas — not just money. Think long-term.',
    philosophyQuote: 'It\'s easier to do a hard startup than an easy startup.',
    keyDisciplines: ['Think about what matters on a 10-year timescale', 'Write to clarify your thinking', 'Build genuine relationships with brilliant people', 'Stay optimistic while being realistic'],
    dailyActions: [
      JourneyAction(title: 'Think Long-Term', subtitle: 'Ask yourself: what am I doing today that compounds over 10 years?', lane: 'mind'),
      JourneyAction(title: 'Write to Think', subtitle: 'Spend 20 min writing about a problem or idea — clarity comes from writing', lane: 'skill'),
      JourneyAction(title: 'Reach Out to Someone Smart', subtitle: 'Connect with someone you admire — ask a question, share an idea', lane: 'social'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of movement — running, weights, or a long walk', lane: 'body'),
      JourneyAction(title: 'Learn About AI or Technology', subtitle: '20 min exploring what\'s new in tech, AI, or science', lane: 'mind'),
      JourneyAction(title: 'Ship Something', subtitle: 'Make one thing more real today — a prototype, a draft, a commit', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_jensen_huang',
    name: 'Jensen Huang',
    emoji: '💚',
    sector: RoleModelSector.technology,
    tagline: 'The GPU Visionary',
    bio: 'Co-founder and CEO of NVIDIA, who spent decades building GPU technology that nobody wanted — until it became the backbone of AI. Patient, relentless, and always betting on the future before others see it.',
    philosophy: 'Suffer and endure. Great companies are built by people willing to do things that are extraordinarily hard for a very long time.',
    philosophyQuote: 'I wish upon you ample doses of pain and suffering.',
    keyDisciplines: ['Work on what will matter in 10 years', 'Start every meeting with the most important topic', 'Stay close to the technology — never become just a manager', 'Embrace suffering as the price of greatness'],
    dailyActions: [
      JourneyAction(title: 'Work on the Hardest Problem', subtitle: 'Start your day with the thing you\'d rather avoid', lane: 'skill'),
      JourneyAction(title: 'Go Deep on Technology', subtitle: '30 min of hands-on learning or technical exploration', lane: 'skill'),
      JourneyAction(title: 'Future Thinking', subtitle: 'Spend 15 min thinking about what the world needs in 5-10 years', lane: 'mind'),
      JourneyAction(title: 'Train Your Body', subtitle: '30 min exercise — Jensen is known for staying physically active', lane: 'body'),
      JourneyAction(title: 'Direct Communication', subtitle: 'Have one conversation today where you skip the pleasantries and go straight to what matters', lane: 'social'),
      JourneyAction(title: 'Embrace Difficulty', subtitle: 'Choose the harder option today when both paths are available', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_lex_fridman',
    name: 'Lex Fridman',
    emoji: '🎙',
    sector: RoleModelSector.technology,
    tagline: 'The Deep Thinker',
    bio: 'MIT researcher, AI scientist, and host of one of the world\'s most influential podcasts. Known for marathon conversations with the most brilliant minds alive, and for training jiu-jitsu and running ultramarathons.',
    philosophy: 'Love is the answer. Seek understanding over judgment. Train the body, feed the mind, and have deep conversations that matter.',
    philosophyQuote: 'The most beautiful thing about the human mind is that it can always learn.',
    keyDisciplines: ['Train jiu-jitsu regularly — physical intelligence', 'Have deep, long-form conversations', 'Maintain an intense work schedule', 'Practice kindness and empathy in all interactions'],
    dailyActions: [
      JourneyAction(title: 'Jiu-Jitsu or Martial Arts', subtitle: '45 min of training — learn through the body', lane: 'body'),
      JourneyAction(title: 'Deep Conversation', subtitle: 'Have one long, unrushed conversation about ideas that matter', lane: 'social'),
      JourneyAction(title: 'Code or Research', subtitle: '90 min of focused intellectual work — AI, math, or engineering', lane: 'skill'),
      JourneyAction(title: 'Read Broadly', subtitle: '30 min of reading — science, philosophy, literature, history', lane: 'mind'),
      JourneyAction(title: 'Run or Endurance Work', subtitle: '20 min of running or long-distance cardio — build mental toughness', lane: 'body'),
      JourneyAction(title: 'Practice Empathy', subtitle: 'In every interaction today, lead with kindness before judgment', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_mark_zuckerberg',
    name: 'Mark Zuckerberg',
    emoji: '👤',
    sector: RoleModelSector.technology,
    tagline: 'The Builder',
    bio: 'Built Facebook in a dorm room into a platform connecting 3 billion people. Known for radical focus, learning by building, and constantly reinventing himself — from coding prodigy to MMA fighter to metaverse architect.',
    philosophy: 'Move fast. Build things. The biggest risk is not taking any risk. In a world changing quickly, the only strategy guaranteed to fail is not taking risks.',
    philosophyQuote: 'The biggest risk is not taking any risk.',
    keyDisciplines: ['Set a yearly personal challenge', 'Build prototypes before perfecting plans', 'Train MMA and jiu-jitsu for mental edge', 'Wear the same thing every day — minimize decisions'],
    dailyActions: [
      JourneyAction(title: 'Build Something', subtitle: '60 min of hands-on creation — code, prototype, or design', lane: 'skill'),
      JourneyAction(title: 'MMA or Jiu-Jitsu Training', subtitle: '45 min of combat training — physical and mental sharpening', lane: 'body'),
      JourneyAction(title: 'Set a Challenge', subtitle: 'Pick one ambitious thing to accomplish this week', lane: 'mind'),
      JourneyAction(title: 'Minimize Decisions', subtitle: 'Automate or eliminate 3 trivial decisions from your day', lane: 'mind'),
      JourneyAction(title: 'Connect with Your Team', subtitle: 'Have a direct, no-BS conversation with someone you work with', lane: 'social'),
      JourneyAction(title: 'Learn a New Technology', subtitle: '20 min exploring a technology or tool you haven\'t used before', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_patrick_collison',
    name: 'Patrick Collison',
    emoji: '💳',
    sector: RoleModelSector.technology,
    tagline: 'The Quiet Builder',
    bio: 'Co-founded Stripe at 19, building it into one of the most valuable private companies in the world. Voracious reader who thinks deeply about progress, science, and building institutions that last.',
    philosophy: 'Increase the GDP of the internet. Read voraciously. Think carefully. Build patiently. Speed matters — fast is a competitive advantage.',
    philosophyQuote: 'Thinking about what you want to build is as important as actually building it.',
    keyDisciplines: ['Read 50+ books per year', 'Write to clarify thinking', 'Move fast but think carefully', 'Invest in fundamental research'],
    dailyActions: [
      JourneyAction(title: 'Read for 60 Minutes', subtitle: 'Science, economics, history, technical papers — read broadly', lane: 'mind'),
      JourneyAction(title: 'Write Something', subtitle: '20 min of writing — notes, blog post draft, or structured thinking', lane: 'skill'),
      JourneyAction(title: 'Build with Speed', subtitle: 'Ship one improvement today — bias toward action', lane: 'skill'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of running or weights — clear thinking requires a healthy body', lane: 'body'),
      JourneyAction(title: 'Learn from Experts', subtitle: 'Read or watch content from someone at the frontier of their field', lane: 'mind'),
      JourneyAction(title: 'Thoughtful Conversation', subtitle: 'Discuss an idea deeply with someone curious and smart', lane: 'social'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // MUSIC
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_kendrick_lamar',
    name: 'Kendrick Lamar',
    emoji: '👑',
    sector: RoleModelSector.music,
    tagline: 'The Conscious Craftsman',
    bio: 'Pulitzer Prize-winning rapper from Compton who elevated hip-hop into high art. Every album is a conceptual masterpiece. Proves that artistic depth, technical skill, and commercial success can coexist.',
    philosophy: 'Be humble but relentless. Use your art to tell the truth. Craftsmanship over clout. Every bar matters.',
    philosophyQuote: 'If I\'m gonna tell a real story, I\'m gonna start with my name.',
    keyDisciplines: ['Revise relentlessly — every word must earn its place', 'Study other art forms for inspiration', 'Stay connected to where you came from', 'Create from pain and truth, not trends'],
    dailyActions: [
      JourneyAction(title: 'Write Every Day', subtitle: '30 min of writing — lyrics, prose, journaling, or storytelling', lane: 'skill'),
      JourneyAction(title: 'Study Great Art', subtitle: '20 min studying music, film, poetry, or painting', lane: 'mind'),
      JourneyAction(title: 'Physical Training', subtitle: '30 min workout — Kendrick trains to maintain energy and focus', lane: 'body'),
      JourneyAction(title: 'Revise Your Work', subtitle: 'Take something you made recently and make it tighter', lane: 'skill'),
      JourneyAction(title: 'Connect with Your Roots', subtitle: 'Call someone from your past, check on family, stay grounded', lane: 'social'),
      JourneyAction(title: 'Practice Humility', subtitle: 'Acknowledge something you\'re wrong about or don\'t know', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_tyler_creator',
    name: 'Tyler, The Creator',
    emoji: '🌻',
    sector: RoleModelSector.music,
    tagline: 'The Authentic Vision',
    bio: 'Self-taught musician, fashion designer, and creative director who went from making music in his bedroom to winning Grammys. Built everything on his own terms — never compromised his weird, wonderful vision.',
    philosophy: 'Create the world you want to live in. Don\'t wait for permission. Be so unapologetically yourself that people have no choice but to respect it.',
    philosophyQuote: 'I\'m not a follower. I\'m a leader. And anyone who speaks their mind is always criticized.',
    keyDisciplines: ['Create across multiple mediums — music, fashion, design', 'Never follow trends — set them', 'Build your own brand and world', 'Stay curious about everything visual and sonic'],
    dailyActions: [
      JourneyAction(title: 'Create Something Original', subtitle: '45 min making music, designing, drawing, or building — your voice', lane: 'skill'),
      JourneyAction(title: 'Study Design & Color', subtitle: '20 min exploring architecture, fashion, or visual art', lane: 'mind'),
      JourneyAction(title: 'Be Unapologetically You', subtitle: 'Do one thing today that is purely you — no audience, no approval needed', lane: 'mind'),
      JourneyAction(title: 'Move Your Body', subtitle: '30 min of skating, biking, or any movement you enjoy', lane: 'body'),
      JourneyAction(title: 'Collaborate', subtitle: 'Work on something creative with another person — different perspective', lane: 'social'),
      JourneyAction(title: 'Build Your World', subtitle: 'Add one element to your personal brand, space, or style', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_j_cole',
    name: 'J. Cole',
    emoji: '🌍',
    sector: RoleModelSector.music,
    tagline: 'The Thoughtful Grind',
    bio: 'First artist signed to Jay-Z\'s Roc Nation, went platinum with no features. From Fayetteville, NC to stadiums worldwide. Known for deeply personal music, zero gimmicks, and genuine connection with his audience.',
    philosophy: 'No shortcuts. Put in the real work. Stay humble, stay hungry. Let your work speak louder than your marketing.',
    philosophyQuote: 'There\'s no such thing as a life that\'s better than yours.',
    keyDisciplines: ['Write from real experience, not personas', 'Practice your craft daily with no shortcuts', 'Stay humble regardless of success', 'Give back — Dreamville is about lifting others'],
    dailyActions: [
      JourneyAction(title: 'Journal from Real Life', subtitle: '20 min writing about your actual life — observations, feelings, stories', lane: 'skill'),
      JourneyAction(title: 'Practice Your Craft', subtitle: '45 min of focused creative work — music, writing, or your chosen art', lane: 'skill'),
      JourneyAction(title: 'Stay Humble', subtitle: 'Do one ordinary thing today — cook, clean, walk — stay connected to reality', lane: 'mind'),
      JourneyAction(title: 'Basketball or Sport', subtitle: '30 min playing a sport — Cole plays basketball almost daily', lane: 'body'),
      JourneyAction(title: 'Lift Someone Up', subtitle: 'Help someone with their dream today — advice, connection, or time', lane: 'social'),
      JourneyAction(title: 'Study the Greats', subtitle: '20 min listening deeply to a classic album or reading great writing', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_the_weeknd',
    name: 'The Weeknd',
    emoji: '🌙',
    sector: RoleModelSector.music,
    tagline: 'The Reinventor',
    bio: 'Abel Tesfaye went from anonymous mixtapes on YouTube to the biggest pop star in the world. Each album is a complete reinvention — new sound, new look, new era. Proof that artistic evolution is the key to longevity.',
    philosophy: 'Reinvent yourself constantly. Create entire worlds around your art. Never stay comfortable in one place — evolve or die.',
    philosophyQuote: 'I always wanted to be faceless. I let the music speak for itself.',
    keyDisciplines: ['Reinvent your creative identity regularly', 'Build complete aesthetic worlds', 'Work late — creativity peaks at night', 'Study every genre of music'],
    dailyActions: [
      JourneyAction(title: 'Create at Night', subtitle: '60 min of creative work in the evening — find your peak hours', lane: 'skill'),
      JourneyAction(title: 'Study a New Genre', subtitle: '20 min exploring music you\'ve never listened to before', lane: 'mind'),
      JourneyAction(title: 'Reinvent One Thing', subtitle: 'Change one element of your routine, style, or approach today', lane: 'mind'),
      JourneyAction(title: 'Workout', subtitle: '30 min of exercise — stamina matters for performance', lane: 'body'),
      JourneyAction(title: 'Build Your Aesthetic', subtitle: 'Curate one aspect of your visual identity or personal brand', lane: 'skill'),
      JourneyAction(title: 'Connect Authentically', subtitle: 'Have one real conversation — no masks, no performance', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_drake',
    name: 'Drake',
    emoji: '🦉',
    sector: RoleModelSector.music,
    tagline: 'The Output Machine',
    bio: 'From Degrassi actor to the most-streamed artist in Spotify history. Dominates through sheer volume of output, emotional vulnerability in music, and an uncanny ability to stay culturally relevant across decades.',
    philosophy: 'Outwork everyone. Stay in the conversation. Be willing to be vulnerable — it\'s a strength, not a weakness. Started from the bottom.',
    philosophyQuote: 'Sometimes it\'s the journey that teaches you a lot about your destination.',
    keyDisciplines: ['Release music constantly — volume matters', 'Stay culturally plugged in', 'Embrace vulnerability in your work', 'Build a brand beyond your craft'],
    dailyActions: [
      JourneyAction(title: 'Create Daily', subtitle: '45 min of creative output — write, record, produce, design', lane: 'skill'),
      JourneyAction(title: 'Stay Culturally Current', subtitle: '15 min exploring what\'s trending in music, fashion, and culture', lane: 'mind'),
      JourneyAction(title: 'Be Vulnerable', subtitle: 'Share something real with someone — a feeling, a fear, a hope', lane: 'social'),
      JourneyAction(title: 'Train', subtitle: '30 min workout — Drake maintains a serious gym routine', lane: 'body'),
      JourneyAction(title: 'Network', subtitle: 'Reach out to one person in your field — build the relationship', lane: 'social'),
      JourneyAction(title: 'Brand Building', subtitle: 'Do one thing that builds your personal brand or presence', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_travis_scott',
    name: 'Travis Scott',
    emoji: '🌵',
    sector: RoleModelSector.music,
    tagline: 'The World Builder',
    bio: 'Created an entire universe around his music — from Astroworld to Cactus Jack. Merges music, fashion, gaming, and live experiences into immersive worlds. Turned being a creative into being an architect of culture.',
    philosophy: 'Build worlds, not just songs. Create experiences people can live inside. Every detail of the aesthetic matters.',
    philosophyQuote: 'You just gotta keep going and going and going. Never stop creating.',
    keyDisciplines: ['Think in experiences, not just products', 'Obsess over sonic and visual aesthetics', 'Collaborate across every creative field', 'Never stop creating — quantity breeds quality'],
    dailyActions: [
      JourneyAction(title: 'Build a World', subtitle: '30 min designing an experience — not just a thing, but a world around it', lane: 'skill'),
      JourneyAction(title: 'Study Sound & Visuals', subtitle: '20 min exploring new sounds, visual art, or immersive experiences', lane: 'mind'),
      JourneyAction(title: 'Cross-Discipline Collab', subtitle: 'Connect with someone in a completely different creative field', lane: 'social'),
      JourneyAction(title: 'Physical Movement', subtitle: '30 min workout — creative energy requires physical energy', lane: 'body'),
      JourneyAction(title: 'Create Without Judgment', subtitle: '30 min making something — don\'t edit, don\'t judge, just create', lane: 'skill'),
      JourneyAction(title: 'Curate Your Aesthetic', subtitle: 'Refine one element of your visual or sonic identity', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL TECHNOLOGY
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_satoshi_nakamoto',
    name: 'Satoshi Nakamoto',
    emoji: '₿',
    sector: RoleModelSector.technology,
    tagline: 'The Phantom Architect',
    bio: 'The pseudonymous creator of Bitcoin and blockchain technology who solved the double-spending problem, published the whitepaper, launched the network, then vanished — letting the work speak for itself forever.',
    philosophy: 'Build systems that don\'t need you. Trust math, not institutions. Let your work be your identity.',
    philosophyQuote: 'If you don\'t believe it or don\'t get it, I don\'t have the time to try to convince you, sorry.',
    keyDisciplines: ['Think in systems, not products', 'Write precisely — every word must be exact', 'Prioritize privacy and focus over fame', 'Ship and iterate in the open'],
    dailyActions: [
      JourneyAction(title: 'Systems Thinking', subtitle: '20 min analyzing a system — what are the incentives? Where are the failure points?', lane: 'mind'),
      JourneyAction(title: 'Deep Technical Work', subtitle: '90 min of focused building — code, write, or design a system', lane: 'skill'),
      JourneyAction(title: 'Write Precisely', subtitle: 'Draft one page explaining a complex idea with zero ambiguity', lane: 'skill'),
      JourneyAction(title: 'Study Cryptography or Math', subtitle: '20 min learning about cryptography, game theory, or distributed systems', lane: 'mind'),
      JourneyAction(title: 'Walk in Solitude', subtitle: '30 min walk alone — deep thinking requires deep quiet', lane: 'body'),
      JourneyAction(title: 'Contribute Anonymously', subtitle: 'Help someone or share knowledge today without seeking credit', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_vitalik_buterin',
    name: 'Vitalik Buterin',
    emoji: '🔷',
    sector: RoleModelSector.technology,
    tagline: 'The Crypto Philosopher',
    bio: 'Co-founder of Ethereum who envisioned a world computer at age 19. A polymath who bridges computer science, economics, and philosophy. Lives minimally, thinks maximally, and builds infrastructure for a decentralized future.',
    philosophy: 'Build public goods. Think from first principles about coordination problems. Subtlety and nuance are strengths, not weaknesses.',
    philosophyQuote: 'The thing that I often ask is: can you have mass adoption of something that is not just an easy-to-use thing but also a thing that respects users?',
    keyDisciplines: ['Learn multiple languages and fields simultaneously', 'Write long-form to clarify thinking', 'Live simply — minimize material distractions', 'Think about mechanism design and incentives'],
    dailyActions: [
      JourneyAction(title: 'Study a New Field', subtitle: '30 min learning about economics, philosophy, math, or a foreign language', lane: 'mind'),
      JourneyAction(title: 'Write Long-Form', subtitle: '45 min of structured writing — blog post, essay, or technical analysis', lane: 'skill'),
      JourneyAction(title: 'Build or Code', subtitle: '60 min of hands-on technical work — prototyping or contributing', lane: 'skill'),
      JourneyAction(title: 'Walk or Stretch', subtitle: '30 min of walking or light exercise — Vitalik walks constantly', lane: 'body'),
      JourneyAction(title: 'Engage in Debate', subtitle: 'Discuss a complex topic with someone who disagrees with you — learn from it', lane: 'social'),
      JourneyAction(title: 'Simplify Your Life', subtitle: 'Remove one unnecessary possession, subscription, or commitment', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_andrej_karpathy',
    name: 'Andrej Karpathy',
    emoji: '🧠',
    sector: RoleModelSector.technology,
    tagline: 'The Neural Network Teacher',
    bio: 'Former Director of AI at Tesla, founding member of OpenAI, and Stanford PhD who made deep learning accessible to millions through his lectures and tutorials. Builds at the frontier and teaches at every level.',
    philosophy: 'Understand things deeply from the ground up. The best way to learn is to build it yourself from scratch. Teach what you learn.',
    philosophyQuote: 'The most important thing is to just start coding. You learn so much more by building than by reading.',
    keyDisciplines: ['Build from scratch to understand deeply', 'Teach publicly — writing and video', 'Stay hands-on with code every day', 'Read papers and implement them yourself'],
    dailyActions: [
      JourneyAction(title: 'Code from Scratch', subtitle: '60 min of hands-on coding — implement something from the ground up', lane: 'skill'),
      JourneyAction(title: 'Read a Research Paper', subtitle: '30 min reading and annotating a technical paper', lane: 'mind'),
      JourneyAction(title: 'Teach Something', subtitle: 'Explain a concept you learned recently — tweet, video, or conversation', lane: 'social'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of running, cycling, or gym — physical health fuels cognitive work', lane: 'body'),
      JourneyAction(title: 'Build a Side Project', subtitle: '30 min on a personal project — curiosity-driven, no deadlines', lane: 'skill'),
      JourneyAction(title: 'Think from First Principles', subtitle: '15 min questioning an assumption in your field — what if the opposite were true?', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL SPORTS
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_neymar',
    name: 'Neymar Jr',
    emoji: '🇧🇷',
    sector: RoleModelSector.sports,
    tagline: 'The Jogo Bonito',
    bio: 'Brazilian football prodigy who brought flair, creativity, and joy back to the beautiful game. From the streets of Santos to Barcelona and PSG, his skill and showmanship made him one of the most electrifying athletes alive.',
    philosophy: 'Play with joy. Football is art — express yourself. Creativity wins when discipline backs it up.',
    philosophyQuote: 'I learned everything on the street. Football should be about happiness and fun.',
    keyDisciplines: ['Practice freestyle skills daily — creativity is a muscle', 'Play with joy — never lose the love', 'Study the game film obsessively', 'Maintain explosive speed and agility'],
    dailyActions: [
      JourneyAction(title: 'Skill Practice', subtitle: '30 min of technical drills or freestyle — master the fundamentals', lane: 'skill'),
      JourneyAction(title: 'Sprint Training', subtitle: '20 min of explosive speed and agility work', lane: 'body'),
      JourneyAction(title: 'Play for Fun', subtitle: 'Do something you love purely for enjoyment — no goals, no pressure', lane: 'mind'),
      JourneyAction(title: 'Stretching & Recovery', subtitle: '20 min of dynamic stretching and mobility work', lane: 'body'),
      JourneyAction(title: 'Watch Film', subtitle: '20 min studying top performers — what makes them creative?', lane: 'skill'),
      JourneyAction(title: 'Connect with Friends', subtitle: 'Spend time with people who keep you grounded and laughing', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_usain_bolt',
    name: 'Usain Bolt',
    emoji: '⚡',
    sector: RoleModelSector.sports,
    tagline: 'The Fastest Man Ever',
    bio: 'Jamaican sprinter who holds the world records in the 100m and 200m. Won 8 Olympic gold medals while making it look effortless. Proved that confidence, charisma, and relentless training create legends.',
    philosophy: 'Train like a beast, perform like a champion, celebrate like it\'s your last race. Confidence is earned through preparation.',
    philosophyQuote: 'I don\'t think limits. I trained hard to be the best in the world — worrying gets you nowhere.',
    keyDisciplines: ['Train with absolute intensity — every rep matters', 'Sleep and recovery are non-negotiable', 'Stay loose and confident under pressure', 'Enjoy the process — bring energy to everything'],
    dailyActions: [
      JourneyAction(title: 'Speed Work', subtitle: '30 min of sprint intervals or explosive training — build raw power', lane: 'body'),
      JourneyAction(title: 'Strength Training', subtitle: '30 min of lifting — legs, core, and posterior chain', lane: 'body'),
      JourneyAction(title: 'Visualize Success', subtitle: '10 min seeing yourself performing at your absolute peak', lane: 'mind'),
      JourneyAction(title: 'Recovery Protocol', subtitle: '20 min of stretching, foam rolling, and active recovery', lane: 'body'),
      JourneyAction(title: 'Bring Energy', subtitle: 'Show up to every interaction with positive energy — lift the room', lane: 'social'),
      JourneyAction(title: 'Sharpen Your Edge', subtitle: '15 min studying technique or analyzing where you can improve', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_floyd_mayweather',
    name: 'Floyd Mayweather',
    emoji: '🥊',
    sector: RoleModelSector.sports,
    tagline: 'The Undefeated',
    bio: '50-0 professional boxing record — the greatest defensive fighter in history. Built a billion-dollar brand through self-promotion, obsessive training, and an unbreakable will to never lose. Hard work and dedication.',
    philosophy: 'Hard work, dedication. Nobody can outwork me. Defense wins — master the fundamentals until nobody can touch you.',
    philosophyQuote: 'Hard work and dedication. There\'s no shortcut to success.',
    keyDisciplines: ['Train at midnight — outwork everyone while they sleep', 'Master defense before offense', 'Protect your body — it\'s your business', 'Control the narrative — own your brand'],
    dailyActions: [
      JourneyAction(title: 'Late Night Training', subtitle: '45 min of intense cardio, bag work, or shadowboxing', lane: 'body'),
      JourneyAction(title: 'Master the Basics', subtitle: '30 min drilling fundamentals — footwork, defense, timing', lane: 'skill'),
      JourneyAction(title: 'Financial Discipline', subtitle: 'Track your money — know what comes in and what goes out', lane: 'skill'),
      JourneyAction(title: 'Roadwork', subtitle: '30 min of running — build the engine that outlasts everyone', lane: 'body'),
      JourneyAction(title: 'Self-Promotion', subtitle: 'Put yourself out there today — own your story and your brand', lane: 'social'),
      JourneyAction(title: 'Mental Toughness', subtitle: 'When you want to quit today, do 10 more reps — then 10 more', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_khabib',
    name: 'Khabib Nurmagomedov',
    emoji: '🦅',
    sector: RoleModelSector.sports,
    tagline: 'The Eagle',
    bio: 'Retired 29-0 undefeated UFC lightweight champion from Dagestan. Trained by wrestling bears as a child. His humility, discipline, faith, and suffocating fighting style made him one of the greatest combat athletes ever.',
    philosophy: 'Discipline and faith above everything. Respect your father, honor your word, and never give up — no matter the pressure.',
    philosophyQuote: 'Father plan. Father always had a plan for me, and I have to finish this plan.',
    keyDisciplines: ['Train in the mountains — embrace harsh conditions', 'Wrestling and grappling daily', 'Faith and prayer as daily anchors', 'Humility regardless of success'],
    dailyActions: [
      JourneyAction(title: 'Wrestling Practice', subtitle: '45 min of grappling, wrestling, or ground work — dominate the basics', lane: 'body'),
      JourneyAction(title: 'Morning Reflection', subtitle: '15 min of prayer, meditation, or quiet gratitude', lane: 'mind'),
      JourneyAction(title: 'Conditioning', subtitle: '30 min of mountain runs, hill sprints, or brutal cardio', lane: 'body'),
      JourneyAction(title: 'Study Your Opponent', subtitle: '20 min analyzing competition — find patterns and weaknesses', lane: 'skill'),
      JourneyAction(title: 'Honor Your Word', subtitle: 'Follow through on every commitment you made — no matter how small', lane: 'social'),
      JourneyAction(title: 'Stay Humble', subtitle: 'Reflect on where you came from — never let success change your character', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL BUSINESS
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_jeff_bezos',
    name: 'Jeff Bezos',
    emoji: '📦',
    sector: RoleModelSector.business,
    tagline: 'The Day One Thinker',
    bio: 'Founded Amazon in his garage and built it into the most valuable company on earth. Obsessed with customer experience, long-term thinking, and maintaining a "Day 1" startup mentality even at massive scale.',
    philosophy: 'It\'s always Day 1. Focus on the customer obsessively. Make decisions with 70% of the information you wish you had — then move fast.',
    philosophyQuote: 'Your brand is what other people say about you when you\'re not in the room.',
    keyDisciplines: ['Write 6-page memos instead of presentations', 'Make reversible decisions quickly', 'Sleep 8 hours — protect decision quality', 'Think in 5-7 year time horizons'],
    dailyActions: [
      JourneyAction(title: 'Morning Routine', subtitle: 'No meetings before 10 AM — use mornings for thinking and family', lane: 'mind'),
      JourneyAction(title: 'Write a Memo', subtitle: '30 min of structured writing — clarify one idea in complete sentences', lane: 'skill'),
      JourneyAction(title: 'Customer Obsession', subtitle: 'Ask: "What does the customer actually need?" — start from there', lane: 'mind'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of fitness — Bezos credits physical health for mental sharpness', lane: 'body'),
      JourneyAction(title: 'Make a Decision', subtitle: 'Stop deliberating on one thing — decide now with the info you have', lane: 'skill'),
      JourneyAction(title: 'Laugh and Connect', subtitle: 'Bezos is known for his laugh — bring genuine joy to one interaction today', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_peter_thiel',
    name: 'Peter Thiel',
    emoji: '♟',
    sector: RoleModelSector.business,
    tagline: 'The Contrarian',
    bio: 'Co-founder of PayPal and Palantir, first outside investor in Facebook. Chess master turned venture capitalist who built a philosophy around contrarian thinking: the best opportunities are the ones nobody else sees.',
    philosophy: 'Competition is for losers. What great company is nobody building? Go from zero to one. Secrets are hidden in plain sight.',
    philosophyQuote: 'What important truth do very few people agree with you on?',
    keyDisciplines: ['Ask contrarian questions — challenge consensus', 'Focus on monopoly, not competition', 'Think in decades, not quarters', 'Study philosophy and history deeply'],
    dailyActions: [
      JourneyAction(title: 'Contrarian Thinking', subtitle: '15 min: pick a popular belief and argue the opposite — what if everyone is wrong?', lane: 'mind'),
      JourneyAction(title: 'Read Deeply', subtitle: '45 min of philosophy, history, or political theory', lane: 'mind'),
      JourneyAction(title: 'Strategic Planning', subtitle: '30 min working on your long-term strategy — not today\'s fires', lane: 'skill'),
      JourneyAction(title: 'Physical Training', subtitle: '30 min of exercise — chess players and thinkers need physical stamina', lane: 'body'),
      JourneyAction(title: 'Challenge Someone\'s Thinking', subtitle: 'Ask a hard question in a conversation — push beyond surface-level', lane: 'social'),
      JourneyAction(title: 'Find a Secret', subtitle: 'Identify one thing in your field that most people miss or get wrong', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_marc_andreessen',
    name: 'Marc Andreessen',
    emoji: '🌐',
    sector: RoleModelSector.business,
    tagline: 'The Techno-Optimist',
    bio: 'Co-creator of the first web browser (Mosaic), co-founder of Netscape, and co-founder of a16z — one of Silicon Valley\'s most powerful venture firms. A relentless optimist who believes technology is the solution to every problem.',
    philosophy: 'Software is eating the world. Be a builder, not a critic. Techno-optimism is a moral imperative. It\'s time to build.',
    philosophyQuote: 'The best way to predict the future is to invent it. It\'s time to build.',
    keyDisciplines: ['Read voraciously — 3+ hours daily', 'Write to sharpen and share your thinking', 'Invest in builders, not talkers', 'Stay optimistic — pessimism is a luxury'],
    dailyActions: [
      JourneyAction(title: 'Read for 2 Hours', subtitle: 'Books, papers, blogs, tweets — consume ideas aggressively', lane: 'mind'),
      JourneyAction(title: 'Write Your Thinking', subtitle: '30 min writing about technology, markets, or ideas', lane: 'skill'),
      JourneyAction(title: 'Build Something', subtitle: 'Spend time creating — code, write, design, prototype', lane: 'skill'),
      JourneyAction(title: 'Exercise', subtitle: '30 min of physical training — energy fuels productivity', lane: 'body'),
      JourneyAction(title: 'Connect with a Builder', subtitle: 'Reach out to someone building something interesting — offer help or ideas', lane: 'social'),
      JourneyAction(title: 'Optimism Practice', subtitle: 'Counter one negative narrative today with a constructive alternative', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL MINDSET
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_jordan_peterson',
    name: 'Jordan Peterson',
    emoji: '🦞',
    sector: RoleModelSector.mindset,
    tagline: 'The Responsibility Architect',
    bio: 'Clinical psychologist and University of Toronto professor whose lectures on meaning, responsibility, and self-improvement reached millions. Author of 12 Rules for Life. Argues that order comes from taking on maximum responsibility.',
    philosophy: 'Clean your room. Stand up straight. Tell the truth — or at least don\'t lie. Aim at the highest good you can conceive of and pursue it.',
    philosophyQuote: 'Compare yourself to who you were yesterday, not to who someone else is today.',
    keyDisciplines: ['Take on the heaviest responsibility you can bear', 'Tell the truth — especially when it\'s difficult', 'Put your house in order before criticizing the world', 'Articulate your thoughts precisely'],
    dailyActions: [
      JourneyAction(title: 'Clean Your Room', subtitle: 'Organize your physical space — outer order creates inner order', lane: 'skill'),
      JourneyAction(title: 'Write Out Your Thoughts', subtitle: '20 min of precise writing — articulate what you actually think', lane: 'mind'),
      JourneyAction(title: 'Take Responsibility', subtitle: 'Identify one thing in your life that\'s broken and own fixing it', lane: 'mind'),
      JourneyAction(title: 'Stand Up Straight', subtitle: '30 min exercise — posture, lifting, or physical training', lane: 'body'),
      JourneyAction(title: 'Have a Difficult Conversation', subtitle: 'Say one true thing today that you\'ve been avoiding', lane: 'social'),
      JourneyAction(title: 'Read Great Literature', subtitle: '30 min of Dostoevsky, Solzhenitsyn, Jung, or Nietzsche', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_james_clear',
    name: 'James Clear',
    emoji: '🔄',
    sector: RoleModelSector.mindset,
    tagline: 'The Habit Architect',
    bio: 'Author of Atomic Habits, one of the bestselling books of the decade. Turned the science of habit formation into a practical system anyone can use. Proof that small, consistent actions compound into extraordinary results.',
    philosophy: 'You do not rise to the level of your goals — you fall to the level of your systems. Get 1% better every day.',
    philosophyQuote: 'Every action you take is a vote for the type of person you wish to become.',
    keyDisciplines: ['Stack habits — attach new behaviors to existing ones', 'Make good habits obvious, attractive, easy, and satisfying', 'Track your habits — what gets measured improves', 'Focus on identity, not outcomes'],
    dailyActions: [
      JourneyAction(title: 'Habit Stacking', subtitle: 'Attach one new positive behavior to something you already do', lane: 'skill'),
      JourneyAction(title: 'Track Your Habits', subtitle: 'Mark off your habits for the day — don\'t break the chain', lane: 'skill'),
      JourneyAction(title: '2-Minute Rule', subtitle: 'Start one task you\'ve been avoiding — but only commit to 2 minutes', lane: 'mind'),
      JourneyAction(title: 'Move for 30 Minutes', subtitle: 'Walk, run, lift, stretch — make movement a default, not a decision', lane: 'body'),
      JourneyAction(title: 'Teach a Habit', subtitle: 'Share one habit tip or system with someone who could benefit', lane: 'social'),
      JourneyAction(title: 'Environment Design', subtitle: 'Change one thing in your environment to make a good habit easier', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_cal_newport',
    name: 'Cal Newport',
    emoji: '📵',
    sector: RoleModelSector.mindset,
    tagline: 'The Deep Worker',
    bio: 'Georgetown computer science professor and bestselling author of Deep Work and Digital Minimalism. Champions focused, distraction-free work in a world designed to scatter your attention. Has never had a social media account.',
    philosophy: 'Deep work is the superpower of the 21st century. Quit social media. A deep life is a good life.',
    philosophyQuote: 'If you don\'t produce, you won\'t thrive — no matter how skilled or talented you are.',
    keyDisciplines: ['No social media — protect your attention', 'Time-block every minute of your workday', 'Shut down work completely by 5:30 PM', 'Embrace boredom — don\'t reach for your phone'],
    dailyActions: [
      JourneyAction(title: 'Deep Work Block', subtitle: '90 min of completely focused work — no phone, no email, no interruptions', lane: 'skill'),
      JourneyAction(title: 'Time-Block Your Day', subtitle: 'Plan every hour of your day on paper before starting', lane: 'skill'),
      JourneyAction(title: 'No Social Media', subtitle: 'Zero social media today — experience boredom without reaching for your phone', lane: 'mind'),
      JourneyAction(title: 'Walk Without Inputs', subtitle: '30 min walk with no headphones — let your mind wander and process', lane: 'body'),
      JourneyAction(title: 'Shutdown Ritual', subtitle: 'At end of work, review tasks, close loops, and say "shutdown complete"', lane: 'mind'),
      JourneyAction(title: 'Quality Leisure', subtitle: 'Replace screen time with a real conversation, board game, or craft', lane: 'social'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL MUSIC
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_kanye_west',
    name: 'Kanye West',
    emoji: '🐻',
    sector: RoleModelSector.music,
    tagline: 'The Creative Maximalist',
    bio: 'Producer, rapper, fashion designer, and cultural lightning rod who reshaped hip-hop, sneaker culture, and pop music multiple times over. From The College Dropout to Yeezus, every era was a complete artistic reinvention.',
    philosophy: 'Believe in your vision when nobody else does. Break every rule. Create at the highest level across every medium.',
    philosophyQuote: 'I am a god. I\'m not comfortable unless I\'m trying to make something that doesn\'t exist yet.',
    keyDisciplines: ['Create across every medium — music, fashion, design, architecture', 'Never settle — tear it down and rebuild if it\'s not perfect', 'Study art history and design obsessively', 'Back your vision with unshakeable belief'],
    dailyActions: [
      JourneyAction(title: 'Create Across Mediums', subtitle: '60 min working in a creative field — music, design, fashion, writing', lane: 'skill'),
      JourneyAction(title: 'Study Art & Design', subtitle: '20 min studying architecture, fashion, or visual art — fill the well', lane: 'mind'),
      JourneyAction(title: 'Break a Rule', subtitle: 'Do one thing today that goes against convention — find a better way', lane: 'mind'),
      JourneyAction(title: 'Physical Training', subtitle: '30 min of intense exercise — creative energy demands physical energy', lane: 'body'),
      JourneyAction(title: 'Collaborate Boldly', subtitle: 'Reach out to someone in a different field and propose something creative', lane: 'social'),
      JourneyAction(title: 'Refine Relentlessly', subtitle: 'Take something you made and make it 10% better — don\'t ship mediocrity', lane: 'skill'),
    ],
  ),

  RoleModel(
    id: 'rm_frank_ocean',
    name: 'Frank Ocean',
    emoji: '🌊',
    sector: RoleModelSector.music,
    tagline: 'The Elusive Perfectionist',
    bio: 'Singer, songwriter, and visual artist who redefined R&B with Channel Orange and Blonde. Releases music on his own timeline, refuses to play the industry game, and creates with a level of emotional depth that resonates for generations.',
    philosophy: 'Quality over quantity. Take your time. Art should make people feel something they can\'t name. Never rush for the market.',
    philosophyQuote: 'Work hard in silence, let success be your noise.',
    keyDisciplines: ['Create on your own timeline — never rush', 'Blend genres fearlessly — R&B, pop, electronic, experimental', 'Journal and write constantly — the lyrics come from life', 'Protect your creative space — say no to everything that doesn\'t serve the art'],
    dailyActions: [
      JourneyAction(title: 'Journal Your Emotions', subtitle: '20 min of raw, honest writing — feelings, memories, observations', lane: 'skill'),
      JourneyAction(title: 'Listen Deeply', subtitle: '30 min of music from a genre you rarely explore — expand your palette', lane: 'mind'),
      JourneyAction(title: 'Create Something Honest', subtitle: '45 min making art that reflects your real emotional state', lane: 'skill'),
      JourneyAction(title: 'Slow Movement', subtitle: '30 min of swimming, yoga, or walking — slow down to feel more', lane: 'body'),
      JourneyAction(title: 'Say No to One Thing', subtitle: 'Protect your time by declining something that doesn\'t serve your vision', lane: 'mind'),
      JourneyAction(title: 'Deep Connection', subtitle: 'Have one real, vulnerable conversation — authenticity fuels art', lane: 'social'),
    ],
  ),

  RoleModel(
    id: 'rm_21_savage',
    name: '21 Savage',
    emoji: '🗡',
    sector: RoleModelSector.music,
    tagline: 'The Survivor',
    bio: 'From the streets of Atlanta to Grammy-winning rapper and financial literacy advocate. Used music to escape violence, then used his platform to teach young people about money, investing, and breaking cycles.',
    philosophy: 'Survive first, then thrive. Stack your money, invest in yourself, and use your platform to break the cycle for others.',
    philosophyQuote: 'I came from nothing. Now I make sure the people around me don\'t have to come from nothing too.',
    keyDisciplines: ['Financial literacy — learn money before spending it', 'Stay disciplined when success comes', 'Give back — build programs for the community', 'Keep your circle small and loyal'],
    dailyActions: [
      JourneyAction(title: 'Financial Check-In', subtitle: '15 min reviewing your budget, investments, or savings plan', lane: 'skill'),
      JourneyAction(title: 'Create Music or Content', subtitle: '45 min of focused creative work — write, record, produce', lane: 'skill'),
      JourneyAction(title: 'Stay Grounded', subtitle: 'Remember where you came from — gratitude for how far you\'ve come', lane: 'mind'),
      JourneyAction(title: 'Workout', subtitle: '30 min of strength or cardio training — stay physically sharp', lane: 'body'),
      JourneyAction(title: 'Help Someone', subtitle: 'Share knowledge, money advice, or time with someone who needs it', lane: 'social'),
      JourneyAction(title: 'Study Investing', subtitle: '15 min learning about markets, real estate, or building wealth', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_metro_boomin',
    name: 'Metro Boomin',
    emoji: '🎹',
    sector: RoleModelSector.music,
    tagline: 'The Beat Architect',
    bio: 'Grammy-winning super producer who shaped the sound of modern hip-hop. Started making beats at 13, moved to Atlanta alone at 18, and built a production empire through relentless output and an unmatched ear for sonic innovation.',
    philosophy: 'If young Metro don\'t trust you, it\'s gonna be a problem. Master your craft so thoroughly that your name becomes a stamp of quality.',
    philosophyQuote: 'I was making 5 beats a day when I was in high school. Volume is how you find your sound.',
    keyDisciplines: ['Make beats every single day — volume breeds mastery', 'Study music production and sound design obsessively', 'Collaborate with the best — iron sharpens iron', 'Stay ahead of trends by creating them'],
    dailyActions: [
      JourneyAction(title: 'Make 3 Beats', subtitle: 'Produce at least 3 instrumentals today — quantity builds quality', lane: 'skill'),
      JourneyAction(title: 'Study Sound Design', subtitle: '20 min exploring new sounds, synths, samples, or production techniques', lane: 'skill'),
      JourneyAction(title: 'Listen to New Music', subtitle: '20 min discovering music outside your comfort zone — sample everything', lane: 'mind'),
      JourneyAction(title: 'Physical Training', subtitle: '30 min of exercise — creative stamina requires physical health', lane: 'body'),
      JourneyAction(title: 'Collaborate', subtitle: 'Send a beat, give feedback, or work on something with another creator', lane: 'social'),
      JourneyAction(title: 'Innovate One Thing', subtitle: 'Try one technique you\'ve never used before — push your sound forward', lane: 'mind'),
    ],
  ),

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL CREATIVITY
  // ══════════════════════════════════════════════════════════════════════════

  RoleModel(
    id: 'rm_virgil_abloh',
    name: 'Virgil Abloh',
    emoji: '🏗',
    sector: RoleModelSector.creativity,
    tagline: 'The 3% Approach',
    bio: 'Architect, DJ, fashion designer, and artistic director of Louis Vuitton menswear. Created Off-White and proved that a kid from Rockford, Illinois could reshape luxury fashion. His "3% approach" — changing an existing design by 3% — became a creative philosophy.',
    philosophy: 'Everything is a remix. Change something 3% and it becomes new. Break the barriers between streetwear and high fashion, art and commerce.',
    philosophyQuote: 'The best designs are born from a dialogue between the old and the new.',
    keyDisciplines: ['Work across disciplines — fashion, architecture, music, art', 'The 3% approach — iterate on what exists', 'Put quotation marks on everything — reframe the ordinary', 'Build bridges between worlds that don\'t usually meet'],
    dailyActions: [
      JourneyAction(title: 'Cross-Discipline Work', subtitle: '45 min creating in a medium outside your main one — design, music, writing', lane: 'skill'),
      JourneyAction(title: 'The 3% Rule', subtitle: 'Take something existing and change it just enough to make it feel new', lane: 'skill'),
      JourneyAction(title: 'Study Architecture & Design', subtitle: '20 min exploring buildings, products, or spaces — how are they structured?', lane: 'mind'),
      JourneyAction(title: 'Move Your Body', subtitle: '30 min of exercise — Virgil DJed, walked, and stayed active constantly', lane: 'body'),
      JourneyAction(title: 'Bridge Two Worlds', subtitle: 'Connect two people, ideas, or fields that don\'t usually overlap', lane: 'social'),
      JourneyAction(title: 'Reframe the Ordinary', subtitle: 'Look at something everyday and find a way to make it extraordinary', lane: 'mind'),
    ],
  ),

  RoleModel(
    id: 'rm_takashi_murakami',
    name: 'Takashi Murakami',
    emoji: '🌸',
    sector: RoleModelSector.creativity,
    tagline: 'The Superflat Visionary',
    bio: 'Japanese contemporary artist who blurred the line between fine art and pop culture. Created the Superflat movement, collaborated with Louis Vuitton, Kanye West, and Billie Eilish. Runs a factory of 100+ assistants producing art at industrial scale.',
    philosophy: 'There is no boundary between high and low art. Work with the intensity of a factory. Understand both Eastern and Western culture deeply.',
    philosophyQuote: 'If you want to be creative, you have to work harder than anyone else.',
    keyDisciplines: ['Work insane hours — creativity is a volume game', 'Blend Eastern and Western aesthetics', 'Collaborate across fashion, music, and commercial worlds', 'Study art history deeply before breaking the rules'],
    dailyActions: [
      JourneyAction(title: 'Studio Time', subtitle: '90 min of focused creative work — painting, drawing, designing, sculpting', lane: 'skill'),
      JourneyAction(title: 'Study Art History', subtitle: '20 min studying traditional Japanese art, Western masters, or contemporary work', lane: 'mind'),
      JourneyAction(title: 'Create at Volume', subtitle: 'Make 3 sketches, drafts, or variations — don\'t be precious, be prolific', lane: 'skill'),
      JourneyAction(title: 'Walk or Stretch', subtitle: '30 min of movement — long studio hours demand physical maintenance', lane: 'body'),
      JourneyAction(title: 'Cross-Cultural Connection', subtitle: 'Explore an art form, food, or tradition from a culture different from yours', lane: 'social'),
      JourneyAction(title: 'Break a Boundary', subtitle: 'Combine two things that "don\'t belong together" — high and low, East and West', lane: 'mind'),
    ],
  ),
];

/// Get all role models for a given sector.
List<RoleModel> getRoleModelsBySector(RoleModelSector sector) {
  return allRoleModels.where((rm) => rm.sector == sector).toList();
}

/// Find a role model by ID.
RoleModel? getRoleModelById(String id) {
  try {
    return allRoleModels.firstWhere((rm) => rm.id == id);
  } catch (_) {
    return null;
  }
}

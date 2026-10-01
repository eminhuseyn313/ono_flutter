/// Challenge system — pushes users beyond their daily actions.
///
/// Daily challenges are quick 5-minute pushes.
/// Weekly challenges are bigger stretch goals.

enum ChallengeType { daily, weekly }
enum ChallengeLane { mind, body, social, skill, any }

class Challenge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeLane lane;
  final int xp; // reward points

  const Challenge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.type,
    required this.lane,
    required this.xp,
  });
}

/// Pool of daily micro-challenges — one offered per day.
const dailyChallenges = [
  // Mind
  Challenge(
    id: 'dc_cold_open',
    emoji: '🧊',
    title: 'Cold Open',
    description: 'No phone for the first 30 minutes after waking up.',
    type: ChallengeType.daily,
    lane: ChallengeLane.mind,
    xp: 15,
  ),
  Challenge(
    id: 'dc_focus_block',
    emoji: '🎯',
    title: 'Deep Focus Block',
    description: 'Do 25 minutes of uninterrupted work — no tabs, no notifications.',
    type: ChallengeType.daily,
    lane: ChallengeLane.mind,
    xp: 20,
  ),
  Challenge(
    id: 'dc_gratitude',
    emoji: '🙏',
    title: 'Gratitude Drop',
    description: 'Write down 3 things you\'re grateful for right now.',
    type: ChallengeType.daily,
    lane: ChallengeLane.mind,
    xp: 10,
  ),
  Challenge(
    id: 'dc_breathe',
    emoji: '🌬',
    title: 'Box Breathing',
    description: '4 rounds of box breathing: inhale 4s, hold 4s, exhale 4s, hold 4s.',
    type: ChallengeType.daily,
    lane: ChallengeLane.mind,
    xp: 10,
  ),
  Challenge(
    id: 'dc_learn_word',
    emoji: '📖',
    title: 'New Word',
    description: 'Learn one new word today and use it in a sentence.',
    type: ChallengeType.daily,
    lane: ChallengeLane.mind,
    xp: 10,
  ),

  // Body
  Challenge(
    id: 'dc_cold_shower',
    emoji: '🚿',
    title: 'Cold Finish',
    description: 'End your shower with 30 seconds of cold water.',
    type: ChallengeType.daily,
    lane: ChallengeLane.body,
    xp: 20,
  ),
  Challenge(
    id: 'dc_pushups',
    emoji: '💪',
    title: 'Drop & Give 20',
    description: 'Do 20 push-ups right now. No warm-up, no excuses.',
    type: ChallengeType.daily,
    lane: ChallengeLane.body,
    xp: 15,
  ),
  Challenge(
    id: 'dc_stretch',
    emoji: '🧘',
    title: 'Full Stretch',
    description: '10-minute full body stretch session.',
    type: ChallengeType.daily,
    lane: ChallengeLane.body,
    xp: 10,
  ),
  Challenge(
    id: 'dc_stairs',
    emoji: '🏃',
    title: 'Take the Stairs',
    description: 'Skip every elevator today. Stairs only.',
    type: ChallengeType.daily,
    lane: ChallengeLane.body,
    xp: 15,
  ),
  Challenge(
    id: 'dc_water',
    emoji: '💧',
    title: 'Hydration King',
    description: 'Drink a full glass of water right now, then one every hour.',
    type: ChallengeType.daily,
    lane: ChallengeLane.body,
    xp: 10,
  ),

  // Social
  Challenge(
    id: 'dc_compliment',
    emoji: '💬',
    title: 'Genuine Compliment',
    description: 'Give a specific, genuine compliment to someone today.',
    type: ChallengeType.daily,
    lane: ChallengeLane.social,
    xp: 15,
  ),
  Challenge(
    id: 'dc_eye_contact',
    emoji: '👁',
    title: 'Eye Contact',
    description: 'Maintain strong eye contact in every conversation today.',
    type: ChallengeType.daily,
    lane: ChallengeLane.social,
    xp: 15,
  ),
  Challenge(
    id: 'dc_text_first',
    emoji: '📱',
    title: 'Reach Out First',
    description: 'Message someone you haven\'t talked to in a while. No reason needed.',
    type: ChallengeType.daily,
    lane: ChallengeLane.social,
    xp: 15,
  ),
  Challenge(
    id: 'dc_no_complain',
    emoji: '🤐',
    title: 'Zero Complaints',
    description: 'Go the entire day without complaining — not even internally.',
    type: ChallengeType.daily,
    lane: ChallengeLane.social,
    xp: 20,
  ),
  Challenge(
    id: 'dc_ask_question',
    emoji: '❓',
    title: 'Curious Mind',
    description: 'Ask someone a thoughtful question about their life and really listen.',
    type: ChallengeType.daily,
    lane: ChallengeLane.social,
    xp: 15,
  ),

  // Skill
  Challenge(
    id: 'dc_teach',
    emoji: '🎓',
    title: 'Teach Something',
    description: 'Explain something you know well to someone else today.',
    type: ChallengeType.daily,
    lane: ChallengeLane.skill,
    xp: 20,
  ),
  Challenge(
    id: 'dc_write',
    emoji: '✍️',
    title: 'Write 200 Words',
    description: 'Write 200 words about anything — a thought, a plan, an idea.',
    type: ChallengeType.daily,
    lane: ChallengeLane.skill,
    xp: 15,
  ),
  Challenge(
    id: 'dc_no_scroll',
    emoji: '📵',
    title: 'No Scroll Zone',
    description: 'Replace 30 min of scrolling with reading or learning.',
    type: ChallengeType.daily,
    lane: ChallengeLane.skill,
    xp: 20,
  ),
  Challenge(
    id: 'dc_plan_tomorrow',
    emoji: '📋',
    title: 'Plan Tomorrow',
    description: 'Write down your top 3 priorities for tomorrow before bed.',
    type: ChallengeType.daily,
    lane: ChallengeLane.skill,
    xp: 10,
  ),
  Challenge(
    id: 'dc_new_skill',
    emoji: '🛠',
    title: '15-Min Skill',
    description: 'Spend 15 minutes learning a completely new skill.',
    type: ChallengeType.daily,
    lane: ChallengeLane.skill,
    xp: 15,
  ),
];

/// Weekly stretch challenges — bigger commitments.
const weeklyChallenges = [
  Challenge(
    id: 'wc_no_sugar',
    emoji: '🚫',
    title: 'Sugar-Free Week',
    description: 'Cut all added sugar for 7 days. Your body will thank you.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.body,
    xp: 100,
  ),
  Challenge(
    id: 'wc_read_book',
    emoji: '📚',
    title: 'Finish a Book',
    description: 'Read an entire book this week — any book, any genre.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.mind,
    xp: 100,
  ),
  Challenge(
    id: 'wc_5am_club',
    emoji: '⏰',
    title: '5AM Club',
    description: 'Wake up at 5 AM every day this week.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.mind,
    xp: 120,
  ),
  Challenge(
    id: 'wc_social_event',
    emoji: '🤝',
    title: 'Host Something',
    description: 'Organize a meetup, dinner, or activity with friends this week.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.social,
    xp: 100,
  ),
  Challenge(
    id: 'wc_digital_detox',
    emoji: '📴',
    title: 'Digital Detox Day',
    description: 'One full day this week with no social media at all.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.skill,
    xp: 80,
  ),
  Challenge(
    id: 'wc_workout_5x',
    emoji: '🏋️',
    title: 'Iron Week',
    description: 'Work out 5 times this week. No excuses.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.body,
    xp: 120,
  ),
  Challenge(
    id: 'wc_journal_daily',
    emoji: '📓',
    title: 'Daily Journal',
    description: 'Write a journal entry every single day this week.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.mind,
    xp: 80,
  ),
  Challenge(
    id: 'wc_stranger',
    emoji: '🗣',
    title: 'Talk to 5 Strangers',
    description: 'Have a real conversation with 5 new people this week.',
    type: ChallengeType.weekly,
    lane: ChallengeLane.social,
    xp: 100,
  ),
];

/// Picks today's daily challenge based on the day of year.
Challenge getTodayChallenge() {
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
  return dailyChallenges[dayOfYear % dailyChallenges.length];
}

/// Picks this week's weekly challenge based on the week number.
Challenge getWeeklyChallenge() {
  final weekOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays ~/ 7;
  return weeklyChallenges[weekOfYear % weeklyChallenges.length];
}

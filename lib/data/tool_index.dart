/// Every tool in ONO, for "Find a tool": what it is for in plain words, and
/// words people might search for. General: nothing here names a person or
/// employer (tested).
class ToolEntry {
  final String title;
  final String what;
  final String route;
  final String group;
  final List<String> words;

  /// Only part of the built-in plan (its protocols, career and body).
  final bool builtInOnly;

  const ToolEntry(this.title, this.what, this.route, this.group,
      {this.words = const [], this.builtInOnly = false});

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [title, what, group, ...words].join(' ').toLowerCase();
    final hayWords = hay.split(RegExp(r'[^a-z0-9]+'));
    // "anxious" finds "anxiety", "worried" finds "worry": a word matches
    // when its stem (all but the last three letters, at least four) starts
    // a word in the tool's text.
    bool hit(String w) {
      if (hay.contains(w)) return true;
      if (w.length < 5) return false;
      final stem = w.substring(0, (w.length - 3).clamp(4, w.length));
      return hayWords.any((h) => h.startsWith(stem));
    }

    return q.split(RegExp(r'\s+')).every(hit);
  }
}

const toolGroups = [
  'Plan',
  'Direction',
  'Practice',
  'People',
  'Hard moments',
  'Body',
  'Look back',
];

const List<ToolEntry> toolIndex = [
  // Plan
  ToolEntry('Your daily items', 'The few things you do every day, with their cues', '/daily', 'Plan',
      words: ['habits', 'routine', 'daily 10', 'checklist']),
  ToolEntry('If–then plans', 'When this happens, I will… — for each daily item', '/plans', 'Plan',
      words: ['cues', 'implementation intentions', 'minimum']),
  ToolEntry('Big 3 this week', 'Three outcomes that make the week a win', '/week', 'Plan',
      words: ['weekly', 'priorities', 'outcomes']),
  ToolEntry('Evening shutdown', 'Close the day, write tomorrow\'s three, empty your head', '/shutdown', 'Plan',
      words: ['evening', 'tomorrow', 'good things']),
  ToolEntry('Deep work', 'One focused block, phone away', '/focus', 'Plan',
      words: ['focus', 'timer', 'pomodoro', 'concentration']),
  ToolEntry('Morning check-in', 'Energy, mood and sleep in thirty seconds', '/checkin', 'Plan',
      words: ['morning', 'energy', 'sleep', 'mood']),
  ToolEntry('Your day', 'Wake, work and bed shape your dial and reminders', '/day', 'Plan',
      words: ['schedule', 'wake', 'bedtime']),
  ToolEntry('Build your plan', 'Who you\'re becoming, one goal, a few daily items', '/start', 'Plan',
      words: ['start', 'setup', 'onboarding']),
  ToolEntry('Plan packs', 'Start from a ready plan, or share yours', '/packs', 'Plan',
      words: ['template', 'share', 'marathon', 'parent', 'manager', 'exam', 'burnout']),
  ToolEntry('Promises', 'What you said you\'d do — kept or renegotiated in time', '/promises', 'Plan',
      words: ['commitments', 'trust', 'deadline', 'word']),

  // Direction
  ToolEntry('Goals', 'The outcomes everything else serves', '/goals', 'Direction',
      words: ['woop', 'targets', 'objectives']),
  ToolEntry('Growth plan', 'One area a month, practised in reps', '/growth', 'Direction',
      words: ['skills', 'develop', 'drills', 'practice']),
  ToolEntry('Your values', 'Three to five, in your own words', '/values', 'Direction',
      words: ['meaning', 'principles']),
  ToolEntry('Three possible lives', 'An Odyssey plan for the next five years', '/odyssey', 'Direction',
      words: ['future', 'career', 'direction', 'five years']),
  ToolEntry('Your best possible future', 'Write it as if it already happened', '/best-future', 'Direction',
      words: ['hope', 'optimism', 'vision']),
  ToolEntry('Life chapters', 'Your story so far, and the next chapter', '/chapters', 'Direction',
      words: ['story', 'identity', 'meaning']),
  ToolEntry('Signature strengths', 'Your top five, used in a new way', '/strengths', 'Direction',
      words: ['strengths', 'via', 'talents']),
  ToolEntry('What gives and drains you', 'Rate your week, then make one change', '/crafting', 'Direction',
      words: ['energy', 'job crafting', 'work']),
  ToolEntry('Money check-in', 'In, out, set aside, one decision', '/money', 'Direction',
      words: ['finance', 'savings', 'budget', 'buffer']),
  ToolEntry('Story bank', 'Your best stories, ready for an interview or review', '/stories', 'Direction',
      words: ['interview', 'star', 'promotion', 'cv', 'review']),
  ToolEntry('Brag document', 'What you\'ve done, ready to copy', '/brag', 'Direction',
      words: ['achievements', 'promotion', 'cv', 'review']),
  ToolEntry('Letters to future you', 'Sealed until the day you choose', '/letters', 'Direction',
      words: ['letter', 'future self']),
  ToolEntry('Career', 'Milestones on the path to the next role', '/career', 'Direction',
      builtInOnly: true, words: ['promotion', 'milestones']),
  ToolEntry('1:1s and decisions', 'Follow-ups you own, decisions reviewed in 90 days',
      '/cockpit', 'Direction',
      words: ['one on one', 'manager', 'decisions', 'readiness', 'career cockpit']),

  // Practice
  ToolEntry('Your playbook', 'Every lesson you wrote, in one place — pin the ones to live by', '/playbook', 'Practice',
      words: ['lessons', 'learned', 'principles', 'rules', 'insights', 'wisdom']),
  ToolEntry('Self-compassion break', 'Notice it\'s hard, you\'re not alone, be kind', '/compassion', 'Hard moments',
      words: ['self-compassion', 'kind', 'critic', 'hard on myself', 'shame', 'guilt', 'failure']),
  ToolEntry('Courage ladder', 'What you avoid, one rung at a time — and how hard it really was', '/courage', 'Practice',
      words: ['fear', 'avoid', 'anxiety', 'confidence', 'brave', 'comfort zone', 'exposure']),
  ToolEntry('Learning', 'Learn it, then apply it', '/learning', 'Practice',
      words: ['books', 'courses', 'reading', 'podcast']),
  ToolEntry('Write from memory', 'Close the book and explain what you just read — the gaps show what to reread', '/tool/feynman', 'Practice',
      words: ['feynman', 'recall', 'reading', 'notes', 'study', 'understand']),
  ToolEntry('Review deck', 'Spaced repetition of what you learned', '/review', 'Practice',
      words: ['flashcards', 'anki', 'memory', 'cards']),
  ToolEntry('After-action review', 'After something that mattered: keep one thing, change one', '/aar', 'Practice',
      words: ['debrief', 'retro', 'lessons', 'retrospective']),
  ToolEntry('Experiments', 'Test one change for a week or two', '/experiments', 'Practice',
      words: ['test', 'try', 'measure']),
  ToolEntry('Is it a habit yet?', 'How automatic each daily item feels', '/habits', 'Practice',
      words: ['automaticity', 'habit']),
  ToolEntry('Energy map', 'When in the day you\'re sharpest', '/energy', 'Practice',
      words: ['energy', 'peak', 'chronotype']),
  ToolEntry('Stop doing', 'What you\'re giving up to make room', '/stop', 'Practice',
      words: ['quit', 'remove', 'less']),
  ToolEntry('Self-coaching', 'Goal, reality, options, will', '/coach', 'Practice',
      words: ['grow', 'problem', 'coach']),
  ToolEntry('Evidence archive', 'Proof of what you\'ve built, for doubtful days', '/evidence', 'Practice',
      words: ['impostor', 'proof', 'confidence']),

  // People
  ToolEntry('People', 'Who matters and when you last reached out', '/people', 'People',
      words: ['friends', 'family', 'contacts', 'relationships']),
  ToolEntry('Your personal board', 'Mentor, sponsor, peer, challenger — and the gaps', '/board', 'People',
      words: ['mentor', 'sponsor', 'network']),
  ToolEntry('Hard conversations', 'Prepare what you want, the facts and your first sentence', '/conversations', 'People',
      words: ['conflict', 'feedback', 'difficult', 'talk']),
  ToolEntry('Negotiation planner', 'Your alternative, bottom line and first offer', '/negotiate', 'People',
      words: ['negotiate', 'salary', 'raise', 'pay', 'offer', 'deal', 'rent', 'price']),
  ToolEntry('Advice', 'Write it down, try it, tell them how it went', '/advice', 'People',
      words: ['advice', 'mentor', 'tip', 'suggestion', 'feedback']),
  ToolEntry('What you know about them', 'What they\'re working towards, what weighs on them', '/know', 'People',
      words: ['love maps', 'understand', 'know', 'stakeholder', 'closeness']),
  ToolEntry('A check-in for two', 'Weekly: appreciation, what was hard, what you need', '/us', 'People',
      words: ['partner', 'marriage', 'couple', 'relationship']),
  ToolEntry('How to work with me', 'A short manual for your team or partner', '/manual', 'People',
      words: ['manual', 'team', 'working style']),
  ToolEntry('Progress note', 'Your week in five lines for someone who cares', '/note', 'People',
      words: ['update', 'report', 'manager']),
  ToolEntry('Accountability partner', 'A weekly pact with one person', '/partner', 'People',
      words: ['buddy', 'pact', 'accountability']),
  ToolEntry('Feedback round', 'Ask three people one question each quarter', '/360', 'People',
      words: ['feedback', '360', 'blind spots']),
  ToolEntry('You, at your best', 'Stories from others of you at your best', '/best-self', 'People',
      words: ['strengths', 'reflected best self']),
  ToolEntry('Kindness day', 'Five small kind acts, one day a week', '/kindness', 'People',
      words: ['kindness', 'giving', 'generosity']),
  ToolEntry('Gratitude letter', 'To someone who changed your life', '/gratitude', 'People',
      words: ['thanks', 'gratitude']),
  ToolEntry('Role models', 'What to learn from whom, and one question to ask', '/models', 'People',
      words: ['mentor', 'inspiration']),
  ToolEntry('Ask for help', 'Guess the chance of a yes, ask, count the yeses', '/asks', 'People',
      words: ['help', 'support', 'favour', 'favor', 'request']),
  ToolEntry('Report for your coach', 'This month or quarter, ready to copy', '/coach-report', 'People',
      words: ['coach', 'therapist', 'report']),

  // Hard moments
  ToolEntry('What do you need right now?', 'Pick the moment, get one tool', '/need', 'Hard moments',
      words: ['help', 'now', 'stuck']),
  ToolEntry('It slipped — reset', 'Kindness, the facts, the smallest next step', '/setback', 'Hard moments',
      words: ['setback', 'failure', 'relapse', 'slip']),
  ToolEntry('Step back', 'Talk to yourself by name', '/stepback', 'Hard moments',
      words: ['stress', 'perspective', 'distance']),
  ToolEntry('Thought check', 'Put a painful thought to the test', '/thought', 'Hard moments',
      words: ['anxiety', 'cbt', 'negative thoughts', 'doubt']),
  ToolEntry('Worry time', 'Park worries, deal with them once a day', '/worry', 'Hard moments',
      words: ['worry', 'anxiety', 'rumination']),
  ToolEntry('Decide with your values', 'Options, what matters, 10/10/10, a premortem', '/decide', 'Hard moments',
      words: ['decision', 'choice', 'dilemma']),
  ToolEntry('Plan your rest', 'Rest days, lighter weeks, holidays', '/rest', 'Hard moments',
      words: ['rest', 'holiday', 'recovery', 'burnout']),
  ToolEntry('Breathe', 'Two minutes of slow breathing', '/tool/sigh', 'Hard moments',
      words: ['breathing', 'calm', 'stress', 'panic']),

  // Body
  ToolEntry('Movement', 'Minutes moved this week and strength days', '/move', 'Body',
      words: ['exercise', 'walk', 'run', 'workout', 'sport']),
  ToolEntry('Care', 'Check-ups, haircut, nails, the car — due dates and bookings', '/upkeep', 'Body',
      words: ['doctor', 'dentist', 'blood tests', 'checkup', 'barber', 'haircut', 'nails',
        'manicure', 'beard', 'grooming', 'skin', 'self-care', 'car', 'appointment', 'upkeep']),
  ToolEntry('Gym', 'Today\'s session with rest timer', '/gym', 'Body',
      builtInOnly: true, words: ['training', 'weights', 'workout']),

  // Look back
  ToolEntry('Sunday report', 'Your week, then next week\'s brief', '/weekly-coaching', 'Look back',
      words: ['weekly review', 'brief', 'coach']),
  ToolEntry('Month review', 'What held, one lesson, what comes with you', '/month-review', 'Look back',
      words: ['monthly', 'review']),
  ToolEntry('Quarterly review', 'Life wheel, wins, lessons, next 90 days', '/quarter', 'Look back',
      words: ['quarter', 'life wheel', 'review']),
  ToolEntry('Year in review', 'What the year added up to, and one word for the next', '/year', 'Look back',
      words: ['annual', 'new year', 'yearly', 'resolution', 'december']),
  ToolEntry('Your data & privacy', 'Where your data lives, export, delete', '/privacy', 'Look back',
      words: ['export', 'delete', 'journal', 'backup']),
];

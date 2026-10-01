import 'dart:math';

import '../models/notification_model.dart';

/// Generates contextual, role-model-specific notification copy
/// that matches ONO's direct, motivational tone.
class ContextualCopyService {
  ContextualCopyService();

  final _random = Random();

  /// Generates a simple UUID from timestamp + random digits.
  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(999999);
    return '$now-$rand';
  }

  /// Picks a random element from a list.
  T _pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  // ---------------------------------------------------------------------------
  // Role-model quote banks
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _roleModelQuotes = {
    'goggins': [
      'Goggins ran 100 miles on broken feet. You can handle today.',
      'Goggins was 300 lbs and became a Navy SEAL. Your excuses are lighter.',
      'Goggins says: "Nobody cares what you did yesterday." Prove it today.',
      '"Stay hard." — Goggins. Your action is waiting.',
      'Goggins carried boats and logs. You just need to show up.',
      'Goggins didn\'t stop at mile 70 with kidney failure. Don\'t stop now.',
    ],
    'kobe': [
      'Kobe made 800 shots before practice started. Your turn.',
      '"Everything negative — pressure, challenges — is an opportunity." — Kobe',
      'Kobe watched film at 4AM. What time are you putting in work?',
      'Mamba Mentality: obsess over the details. Start with today\'s action.',
      '"I can\'t relate to lazy people. We don\'t speak the same language." — Kobe',
      'Kobe scored 60 in his last game. Finish strong today.',
    ],
    'marcus_aurelius': [
      '"The impediment to action advances action." — Marcus Aurelius',
      '"Waste no more time arguing about what a good man should be. Be one." — Marcus',
      'Marcus Aurelius ruled Rome and still journaled daily. You can do your action.',
      '"You have power over your mind — not outside events." — Marcus Aurelius',
      '"At dawn, tell yourself: today I will meet interference." Then conquer it.',
      '"The best revenge is not to be like your enemy." Rise above. — Marcus',
    ],
    'naval': [
      '"Specific knowledge is found by pursuing your genuine curiosity." — Naval',
      'Naval says: "Play long-term games with long-term people." Keep your streak.',
      '"Desire is a contract you make with yourself to be unhappy until you get what you want." — Naval',
      'Naval built wealth with leverage. Build your life with consistency.',
      '"An unhappy person who acts is better than a happy person who doesn\'t." — Naval',
      '"All the real benefits come from compound interest." Your streak IS compound interest.',
    ],
    'huberman': [
      'Huberman: morning sunlight rewires your brain. Stack your protocol.',
      '"Dopamine is not about reward — it\'s about pursuit." — Huberman. Pursue your action.',
      'Huberman protocols: cold exposure, focus, growth. You have one action. Do it.',
      'Your nervous system adapts to stress. Each day you train it. — Huberman',
      '"The science is clear: consistency changes neural architecture." — Huberman',
      'Huberman says deliberate effort drives neuroplasticity. Your daily action IS that effort.',
    ],
    'hormozi': [
      'Hormozi made \$100M by doing boring work consistently. Your action is waiting.',
      '"Most people need to hear this: you\'re not working hard enough." — Hormozi',
      'Hormozi: "Volume negates luck." More reps. More days. Keep going.',
      '"The way to get what you want is to deserve what you want." — Hormozi',
      'Hormozi says the game is simple: do more than everyone else. Start now.',
      '"If you can\'t outspend them, outwork them." — Hormozi. Today counts.',
    ],
    'cr7': [
      'Ronaldo is always the last to leave training. Don\'t leave early today.',
      '"Talent without work is nothing." — CR7. Put in the work.',
      'CR7 scores in his sleep because he trains while others rest.',
      'Ronaldo does 3,000 sit-ups a day. You have one action. Handle it.',
      '"Your love for what you do and your will to win should be bigger than your talent." — CR7',
      'CR7 at 39 still outworks 20-year-olds. Age is not your excuse.',
    ],
    'bruce_lee': [
      '"I fear not the man who practiced 10,000 kicks once, but the man who practiced one kick 10,000 times." — Bruce Lee',
      '"Be water, my friend." Adapt. Flow. Complete your action. — Bruce Lee',
      'Bruce Lee did 2-finger push-ups. You can do your daily action.',
      '"Knowing is not enough, we must apply." — Bruce Lee. Apply yourself today.',
      '"The successful warrior is the average man with laser-like focus." — Bruce Lee',
      '"Do not pray for an easy life, pray for the strength to endure a hard one." — Bruce Lee',
    ],
    'arnold': [
      'Arnold trained 5 hours a day while working construction. You have one action.',
      '"The worst thing I can be is the same as everybody else." — Arnold',
      'Arnold visualized every rep. Visualize completing your action. Then do it.',
      '"Strength does not come from winning. Your struggles develop your strengths." — Arnold',
      'Arnold won 7 Mr. Olympias through obsession. Be obsessed with your growth.',
      '"The mind is the limit. As long as the mind can envision it, you can do it." — Arnold',
    ],
    'jocko': [
      '"Discipline equals freedom." — Jocko. Your freedom starts with today\'s action.',
      'Jocko wakes at 4:30AM every day. No alarm needed. Build that discipline.',
      '"Don\'t expect to be motivated every day. Get disciplined." — Jocko',
      '"Good." Something went wrong? Good. Now you have a chance to grow. — Jocko',
      'Jocko: "Default: aggressive." Attack your action today.',
      '"Get after it." — Jocko. No more waiting. Your action is live.',
    ],
  };

  /// Returns a role-model display name.
  String _roleModelName(String roleModelId) {
    const names = {
      'goggins': 'David Goggins',
      'kobe': 'Kobe Bryant',
      'marcus_aurelius': 'Marcus Aurelius',
      'naval': 'Naval Ravikant',
      'huberman': 'Andrew Huberman',
      'hormozi': 'Alex Hormozi',
      'cr7': 'Cristiano Ronaldo',
      'bruce_lee': 'Bruce Lee',
      'arnold': 'Arnold Schwarzenegger',
      'jocko': 'Jocko Willink',
    };
    return names[roleModelId] ?? roleModelId;
  }

  // ---------------------------------------------------------------------------
  // Streak alerts
  // ---------------------------------------------------------------------------

  static const List<String> _streakAlertTitles = [
    '🔥 Your streak is on the line',
    '⚠️ Don\'t break the chain',
    '🔥 Streak check',
    '💀 Your streak won\'t save itself',
    '⏰ Time\'s running out',
    '🔥 Protect what you built',
  ];

  static const List<String> _streakAlertBodies = [
    '{days}-day streak. Don\'t let today be day zero.',
    'You\'ve shown up {days} days straight. One more won\'t kill you.',
    '{days} days of proof you\'re not average. Keep it going.',
    'Your {days}-day streak dies at midnight. Move.',
    '{days} days in. The version of you that quits doesn\'t exist.',
    'Day {days}. The chain breaks or you do. Choose.',
  ];

  /// Generates a streak-risk notification with optional role-model flavor.
  OnoNotification generateStreakAlert({
    required int streakDays,
    required String? roleModelId,
  }) {
    String title = _pick(_streakAlertTitles);
    String body = _pick(_streakAlertBodies).replaceAll('{days}', '$streakDays');

    // Append a role-model line if available.
    if (roleModelId != null && _roleModelQuotes.containsKey(roleModelId)) {
      body = '$body\n${_pick(_roleModelQuotes[roleModelId]!)}';
    }

    return OnoNotification(
      id: _generateId(),
      type: NotificationType.streakRisk,
      title: title,
      body: body,
      lane: null,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: '/actions',
    );
  }

  // ---------------------------------------------------------------------------
  // Social proof
  // ---------------------------------------------------------------------------

  static const List<String> _socialProofTitles = [
    '🏆 The tribe is moving',
    '⚡ Warriors are active',
    '💪 The pack is hunting',
    '🔥 Others aren\'t waiting',
    '🌍 The movement is live',
  ];

  static const List<String> _socialProofBodies = [
    '{count} warriors completed their actions today. Join them.',
    '{count} men showed up today. Will you?',
    '{count} users already crushed it. Don\'t get left behind.',
    '{count} people chose discipline over comfort today.',
    '{count} actions completed across the ONO network. Add yours.',
    'Right now, {count} men are building. Are you?',
  ];

  /// Generates a social-proof notification.
  OnoNotification generateSocialProof({
    required int usersCompletedToday,
  }) {
    final countStr = _formatCount(usersCompletedToday);
    return OnoNotification(
      id: _generateId(),
      type: NotificationType.socialProof,
      title: _pick(_socialProofTitles),
      body: _pick(_socialProofBodies).replaceAll('{count}', countStr),
      lane: null,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: '/community',
    );
  }

  // ---------------------------------------------------------------------------
  // Milestone alerts
  // ---------------------------------------------------------------------------

  static const List<String> _milestoneTitles = [
    'You\'re almost there',
    'Milestone incoming',
    'Big moment ahead',
    'Unlock approaching',
    'Level up imminent',
  ];

  static const List<String> _milestoneBodies = [
    '{emoji} "{name}" is within reach. Finish what you started.',
    '{emoji} You\'re about to unlock "{name}". Don\'t stop now.',
    '{emoji} "{name}" — one of the hardest milestones. And you\'re close.',
    '{emoji} Keep pushing. "{name}" is right around the corner.',
    '{emoji} The "{name}" milestone separates talkers from doers. Claim it.',
    '{emoji} Almost earned: "{name}". This is where most men quit. Not you.',
  ];

  /// Generates a milestone-approaching notification.
  OnoNotification generateMilestoneAlert({
    required String milestoneName,
    required String emoji,
  }) {
    return OnoNotification(
      id: _generateId(),
      type: NotificationType.milestone,
      title: '$emoji ${_pick(_milestoneTitles)}',
      body: _pick(_milestoneBodies)
          .replaceAll('{name}', milestoneName)
          .replaceAll('{emoji}', emoji),
      lane: null,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: '/milestones',
    );
  }

  // ---------------------------------------------------------------------------
  // Role-model nudges
  // ---------------------------------------------------------------------------

  /// Generates a role-model motivational nudge.
  OnoNotification generateRoleModelNudge({
    required String roleModelId,
    required String? lane,
  }) {
    final name = _roleModelName(roleModelId);
    final quotes = _roleModelQuotes[roleModelId];

    final String body;
    if (quotes != null && quotes.isNotEmpty) {
      body = _pick(quotes);
    } else {
      body = 'Channel $name today. Show up and do the work.';
    }

    return OnoNotification(
      id: _generateId(),
      type: NotificationType.roleModel,
      title: '💬 Words from $name',
      body: body,
      lane: lane,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: '/role-models/$roleModelId',
    );
  }

  // ---------------------------------------------------------------------------
  // Journey phase transitions
  // ---------------------------------------------------------------------------

  static const List<String> _journeyTransitionTitles = [
    '🚀 New phase unlocked',
    '⬆️ You leveled up',
    '🔓 Phase transition',
    '🎯 Next chapter begins',
    '📈 Evolution detected',
  ];

  static const List<String> _journeyTransitionBodies = [
    'You\'ve entered "{phase}" in {journey}. The real work starts now.',
    '"{phase}" is live. {journey} just got harder — and so did you.',
    'New phase: "{phase}" in {journey}. Everything before was preparation.',
    'Welcome to "{phase}". This is where {journey} separates the committed from the curious.',
    '"{phase}" unlocked in {journey}. You earned this. Now defend it.',
    '{journey} update: you\'re in "{phase}" now. Raise your standard.',
  ];

  /// Generates a journey-phase-transition notification.
  OnoNotification generateJourneyPhaseTransition({
    required String journeyTitle,
    required String phaseName,
  }) {
    return OnoNotification(
      id: _generateId(),
      type: NotificationType.milestone,
      title: _pick(_journeyTransitionTitles),
      body: _pick(_journeyTransitionBodies)
          .replaceAll('{journey}', journeyTitle)
          .replaceAll('{phase}', phaseName),
      lane: null,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: '/journeys',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Formats large numbers with commas: 1247 → "1,247".
  String _formatCount(int count) {
    final str = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

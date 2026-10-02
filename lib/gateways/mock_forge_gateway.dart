// gateways/mock_forge_gateway.dart — Mock Forge Gateway v2 (30 courses)

import '../models/forge.dart';
import 'forge_gateway.dart';

class MockForgeGateway implements ForgeGateway {
  final List<ForgeCourse> _courses = _buildAllCourses();
  final Set<String> _completedLessons = {};
  final Map<String, List<String>> _worksheetAnswers = {};
  final Map<String, List<bool>> _checklistStates = {};

  // ── v1 methods ──

  @override
  Future<List<ForgeCourse>> loadCourses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_courses);
  }

  @override
  Future<ForgeCourse> loadCourse(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _courses.firstWhere((c) => c.id == courseId);
  }

  @override
  Future<ForgeProgress> loadProgress() async {
    await Future.delayed(const Duration(milliseconds: 180));
    final totalLessons =
        _courses.fold<int>(0, (sum, c) => sum + c.lessons.length);
    final completedCourses = _courses.where((c) {
      return c.lessons.every((l) => _completedLessons.contains(l.id));
    }).length;

    return ForgeProgress(
      totalCourses: _courses.length,
      completedCourses: completedCourses,
      totalLessons: totalLessons,
      completedLessons: _completedLessons.length,
      totalMinutesSpent: _completedLessons.length * 8,
      laneStats: {
        'Mind': const ForgeLaneStats(
          lane: 'Mind',
          coursesCompleted: 2,
          lessonsCompleted: 8,
          minutesSpent: 64,
          averageScore: 0.82,
          strongestTopic: 'Meditation',
          weakestTopic: 'Stoic Journaling',
        ),
        'Body': const ForgeLaneStats(
          lane: 'Body',
          coursesCompleted: 1,
          lessonsCompleted: 5,
          minutesSpent: 40,
          averageScore: 0.75,
          strongestTopic: 'Cold Exposure',
          weakestTopic: 'Sleep Optimization',
        ),
        'Craft': const ForgeLaneStats(
          lane: 'Craft',
          coursesCompleted: 1,
          lessonsCompleted: 6,
          minutesSpent: 48,
          averageScore: 0.88,
          strongestTopic: 'Deep Work',
          weakestTopic: 'Creative Flow',
        ),
        'Soul': const ForgeLaneStats(
          lane: 'Soul',
          coursesCompleted: 0,
          lessonsCompleted: 3,
          minutesSpent: 24,
          averageScore: 0.70,
          strongestTopic: 'Gratitude Practice',
          weakestTopic: 'Purpose Discovery',
        ),
      },
      currentStreak: 5,
      lastCompletedAt: DateTime.now().subtract(const Duration(hours: 6)),
    );
  }

  @override
  Future<void> completeLesson(String courseId, String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _completedLessons.add(lessonId);
  }

  @override
  Future<List<ForgeCourse>> loadCoursesByRoleModel(String roleModelId) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _courses.where((c) => c.roleModelId == roleModelId).toList();
  }

  @override
  Future<List<ForgeCourse>> loadCoursesByLane(String lane) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _courses.where((c) => c.lane == lane).toList();
  }

  // ── v2 methods ──

  @override
  Future<List<ForgeRecommendation>> getRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      ForgeRecommendation(
        courseId: 'course_16',
        reason: 'Based on your Mind lane progress',
        matchScore: 0.95,
        basedOn: RecommendationBasis.laneScore,
      ),
      ForgeRecommendation(
        courseId: 'course_20',
        reason: 'You completed a Huberman course recently',
        matchScore: 0.88,
        basedOn: RecommendationBasis.completionHistory,
      ),
      ForgeRecommendation(
        courseId: 'course_25',
        reason: 'Fans of Goggins also take this course',
        matchScore: 0.82,
        basedOn: RecommendationBasis.roleModelAffinity,
      ),
      ForgeRecommendation(
        courseId: 'course_28',
        reason: 'Trending among all learners this week',
        matchScore: 0.78,
        basedOn: RecommendationBasis.popular,
      ),
    ];
  }

  @override
  Future<ForgeLaneStats> getLaneStats(String lane) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final progress = await loadProgress();
    return progress.laneStats[lane] ??
        ForgeLaneStats(
          lane: lane,
          coursesCompleted: 0,
          lessonsCompleted: 0,
          minutesSpent: 0,
          averageScore: 0.0,
          strongestTopic: 'N/A',
          weakestTopic: 'N/A',
        );
  }

  @override
  Future<void> saveWorksheetAnswers(
    String courseId,
    String lessonId,
    String blockId,
    List<String> answers,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final key = '${courseId}_${lessonId}_${blockId}';
    _worksheetAnswers[key] = answers;
  }

  @override
  Future<void> toggleChecklistItem(
    String courseId,
    String lessonId,
    String blockId,
    int itemIndex,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final key = '${courseId}_${lessonId}_${blockId}';
    final course = _courses.firstWhere((c) => c.id == courseId);
    final lesson = course.lessons.firstWhere((l) => l.id == lessonId);
    final block = lesson.blocks.firstWhere((b) => b.id == blockId);
    final itemCount = block.checklistItems?.length ?? 0;

    if (!_checklistStates.containsKey(key)) {
      _checklistStates[key] = List.filled(itemCount, false);
    }
    if (itemIndex >= 0 && itemIndex < (_checklistStates[key]?.length ?? 0)) {
      _checklistStates[key]![itemIndex] = !_checklistStates[key]![itemIndex];
    }
  }
}

// ── Course Builder ──

List<ForgeCourse> _buildAllCourses() {
  return [
    // ── Original 15 courses (Sprint 6 — v1 block types only) ──
    _course(
      id: 'course_1',
      title: 'Mental Toughness 101',
      description: 'Build an unbreakable mindset with Goggins-style discipline.',
      roleModelId: 'goggins',
      roleModelName: 'David Goggins',
      roleModelEmoji: '\u{1F525}',
      lane: 'Mind',
      difficulty: 'beginner',
      rating: 4.8,
      enrolledCount: 4200,
      totalMinutes: 25,
      lessons: [
        _lesson('l1_1', 'The Cookie Jar', 'Access past victories for strength.', 8, [
          _textBlock('b1', 'The Cookie Jar Method', 'When life gets hard, reach into your cookie jar of past victories. Every challenge you have overcome is a cookie you can pull out to remind yourself what you are capable of.'),
          _scenarioBlock('b2', 'Morning Alarm Challenge', 'Your alarm goes off at 4:30 AM. It is cold and dark. What do you do?', ['Hit snooze and sleep in', 'Get up immediately, no negotiation', 'Bargain with yourself for 10 more minutes'], 1, 'Goggins says: get up. No negotiation. The moment you start bargaining, you have already lost.'),
          _reflectionBlock('b3', 'Your Cookie Jar', 'Write down three moments in your life when you pushed through something difficult. These are your cookies.'),
        ]),
        _lesson('l1_2', 'Callousing the Mind', 'Embrace discomfort to grow stronger.', 10, [
          _textBlock('b4', 'Embrace the Suck', 'Growth happens outside your comfort zone. Every time you do something uncomfortable, you callous your mind just like callouses form on your hands from hard work.'),
          _timedBlock('b5', 'Cold Shower Challenge', 'Turn your shower to cold for the remaining duration. Focus on controlling your breath.', 120),
          _keyTakeawayBlock('b6', 'Key Insight', 'Suffering is the true test of life. The more you seek discomfort, the more comfortable you become with the uncomfortable.'),
        ]),
        _lesson('l1_3', 'The 40% Rule', 'You have more in the tank than you think.', 7, [
          _textBlock('b7', 'The 40 Percent Rule', 'When your mind tells you that you are done, you are really only 40 percent done. Your mind is the governor that limits your output.'),
          _multipleChoiceBlock('b8', 'Test Your Knowledge', 'According to Goggins, when your mind says you are done, how much capacity do you actually have left?', ['10%', '25%', '60%', '80%'], 2, 'You are only at 40% when your mind says quit — meaning 60% remains.'),
        ]),
      ],
    ),
    _course(
      id: 'course_2',
      title: 'Naval\'s Wealth Principles',
      description: 'Learn the principles of building wealth without getting lucky.',
      roleModelId: 'naval',
      roleModelName: 'Naval Ravikant',
      roleModelEmoji: '\u{2693}',
      lane: 'Craft',
      difficulty: 'intermediate',
      rating: 4.7,
      enrolledCount: 3800,
      totalMinutes: 20,
      lessons: [
        _lesson('l2_1', 'Specific Knowledge', 'Find what feels like play to you but looks like work to others.', 10, [
          _textBlock('b9', 'Specific Knowledge', 'Specific knowledge is found by pursuing your genuine curiosity and passion rather than whatever is hot right now. It cannot be trained; if it can be trained, someone else will be trained to replace you.'),
          _reflectionBlock('b10', 'Your Specific Knowledge', 'What do people often come to you for help with? What feels like play to you but work to others?'),
        ]),
        _lesson('l2_2', 'Leverage', 'Use code, media, and capital as leverage.', 10, [
          _textBlock('b11', 'Three Forms of Leverage', 'Labor is the oldest form of leverage. Capital is more modern. But the newest and most democratic forms of leverage are code and media — they work while you sleep.'),
          _multipleChoiceBlock('b12', 'Leverage Quiz', 'Which form of leverage does Naval consider the most democratic?', ['Labor', 'Capital', 'Code and Media', 'Real Estate'], 2, 'Code and media are permissionless — you do not need anyone\'s permission to create a podcast or write software.'),
        ]),
      ],
    ),
    _course(
      id: 'course_3',
      title: 'Stoic Daily Practice',
      description: 'Apply Marcus Aurelius\' timeless wisdom to modern life.',
      roleModelId: 'aurelius',
      roleModelName: 'Marcus Aurelius',
      roleModelEmoji: '\u{1F3DB}',
      lane: 'Mind',
      difficulty: 'beginner',
      rating: 4.6,
      enrolledCount: 3200,
      totalMinutes: 18,
      lessons: [
        _lesson('l3_1', 'Morning Reflection', 'Start your day with Stoic clarity.', 9, [
          _textBlock('b13', 'The Morning Ritual', 'Each morning, before the day begins, remind yourself: today I will encounter interference, ingratitude, insolence, and selfishness. But I shall not be disturbed, for I understand the nature of things.'),
          _timedBlock('b14', 'Morning Meditation', 'Sit quietly. Reflect on what is within your control today and what is not. Release attachment to the external.', 180),
        ]),
        _lesson('l3_2', 'Evening Review', 'End your day with honest self-assessment.', 9, [
          _textBlock('b15', 'The Evening Audit', 'Each evening, the Stoic reviews the day: What did I do well? Where did I fall short? What can I improve? This is not about guilt — it is about growth.'),
          _reflectionBlock('b16', 'Tonight\'s Review', 'Reflect on your day. What went well? What challenged you? What would you do differently?'),
        ]),
      ],
    ),
    _course(
      id: 'course_4',
      title: 'Sleep Optimization',
      description: 'Huberman\'s science-backed protocols for better sleep.',
      roleModelId: 'huberman',
      roleModelName: 'Andrew Huberman',
      roleModelEmoji: '\u{1F9E0}',
      lane: 'Body',
      difficulty: 'beginner',
      rating: 4.9,
      enrolledCount: 5000,
      totalMinutes: 22,
      lessons: [
        _lesson('l4_1', 'Light Exposure Protocol', 'Use sunlight to set your circadian rhythm.', 11, [
          _textBlock('b17', 'Morning Sunlight', 'Get 10 minutes of sunlight within the first hour of waking. This triggers a cortisol pulse that sets your circadian clock and promotes alertness. On cloudy days, get 20 minutes.'),
          _scenarioBlock('b18', 'Rainy Morning', 'It is a cloudy, rainy morning. You have 30 minutes before you need to leave for work.', ['Skip sunlight today', 'Use a light therapy lamp for 15 minutes', 'Spend 20 minutes outside despite clouds'], 2, 'Cloudy days still provide sufficient lux. Huberman recommends doubling the time outdoors on overcast days.'),
        ]),
        _lesson('l4_2', 'Evening Wind-Down', 'Optimize your pre-sleep environment.', 11, [
          _textBlock('b19', 'Dim the Lights', 'After sunset, reduce overhead lighting. Use only dim, low-placed lights. Avoid screens or use blue-light filters. The goal is to allow melatonin to rise naturally.'),
          _keyTakeawayBlock('b20', 'Sleep Stack', 'Morning sunlight + evening dim lights + cool bedroom (65-68 degrees F) + consistent schedule = optimized sleep architecture.'),
        ]),
      ],
    ),
    _course(
      id: 'course_5',
      title: '\$100M Offers',
      description: 'Create irresistible business offers with Hormozi\'s framework.',
      roleModelId: 'hormozi',
      roleModelName: 'Alex Hormozi',
      roleModelEmoji: '\u{1F4B0}',
      lane: 'Craft',
      difficulty: 'intermediate',
      rating: 4.8,
      enrolledCount: 4500,
      totalMinutes: 24,
      lessons: [
        _lesson('l5_1', 'The Value Equation', 'Understand what makes an offer irresistible.', 12, [
          _textBlock('b21', 'The Value Equation', 'Value = (Dream Outcome x Perceived Likelihood) / (Time Delay x Effort & Sacrifice). To increase value: increase the dream outcome, increase perceived likelihood, decrease time delay, decrease effort.'),
          _multipleChoiceBlock('b22', 'Value Equation', 'Which factor should you DECREASE to increase perceived value?', ['Dream Outcome', 'Perceived Likelihood', 'Time Delay', 'None of the above'], 2, 'Decreasing time delay (faster results) and effort/sacrifice increases the perceived value of your offer.'),
        ]),
        _lesson('l5_2', 'Naming Your Offer', 'Create a name that sells itself.', 12, [
          _textBlock('b23', 'The MAGIC Formula', 'Make a Magnetic reason why, Announce your Avatar, Give them a Goal, Indicate a time Interval, Complete with a Container. Example: "Free 6-Week Lean Body Challenge for Busy Moms"'),
          _reflectionBlock('b24', 'Name Your Offer', 'Using the MAGIC formula, create a name for your product or service that communicates value instantly.'),
        ]),
      ],
    ),
    _course(
      id: 'course_6',
      title: 'Champion Mentality',
      description: 'Develop the mindset of a world-class athlete with CR7.',
      roleModelId: 'cr7',
      roleModelName: 'Cristiano Ronaldo',
      roleModelEmoji: '\u{26BD}',
      lane: 'Body',
      difficulty: 'beginner',
      rating: 4.5,
      enrolledCount: 3600,
      totalMinutes: 20,
      lessons: [
        _lesson('l6_1', 'Daily Discipline', 'The habits behind sustained excellence.', 10, [
          _textBlock('b25', 'First In, Last Out', 'Ronaldo is known for being the first to arrive at training and the last to leave. Excellence is not a single act — it is a habit performed consistently over years.'),
          _timedBlock('b26', 'Bodyweight Circuit', 'Perform 20 push-ups, 30 squats, and a 60-second plank. No rest between exercises.', 180),
        ]),
        _lesson('l6_2', 'Recovery as Performance', 'Rest smarter to perform better.', 10, [
          _textBlock('b27', 'Active Recovery', 'CR7 sleeps in 90-minute cycles (5 naps per day during peak season). Recovery is not laziness — it is a performance strategy.'),
          _keyTakeawayBlock('b28', 'Recovery Principle', 'Your body does not get stronger during training — it gets stronger during recovery. Prioritize sleep, nutrition, and active rest.'),
        ]),
      ],
    ),
    _course(
      id: 'course_7',
      title: 'Creative Mastery',
      description: 'Channel Miyamoto\'s design philosophy into your creative work.',
      roleModelId: 'miyamoto',
      roleModelName: 'Shigeru Miyamoto',
      roleModelEmoji: '\u{1F3AE}',
      lane: 'Craft',
      difficulty: 'beginner',
      rating: 4.6,
      enrolledCount: 2800,
      totalMinutes: 18,
      lessons: [
        _lesson('l7_1', 'Play as Design', 'Great design starts with a feeling of fun.', 9, [
          _textBlock('b29', 'Fun First', 'Miyamoto never starts with technology or market trends. He starts with a feeling — what emotion should the player experience? Every game mechanic serves that feeling.'),
          _reflectionBlock('b30', 'Your Fun Factor', 'Think about your current project. What feeling should your user/reader/customer experience? How can you amplify that feeling?'),
        ]),
        _lesson('l7_2', 'Simplicity in Design', 'Reduce to the essential.', 9, [
          _textBlock('b31', 'Less Is More', 'Miyamoto\'s genius is subtraction. Super Mario has only two actions: run and jump. Yet from those two inputs, infinite gameplay emerges.'),
          _scenarioBlock('b32', 'Feature Creep', 'Your project has 12 features planned. The deadline is in 2 weeks. What is the Miyamoto approach?', ['Work overtime to ship all 12', 'Cut to the 3 most essential features and polish them', 'Ship all 12 at lower quality'], 1, 'Miyamoto delayed games rather than ship mediocre work. "A delayed game is eventually good, but a rushed game is forever bad."'),
        ]),
      ],
    ),
    _course(
      id: 'course_8',
      title: 'Conversation Mastery',
      description: 'Learn deep listening and curious questioning from Rogan.',
      roleModelId: 'rogan',
      roleModelName: 'Joe Rogan',
      roleModelEmoji: '\u{1F399}',
      lane: 'Soul',
      difficulty: 'beginner',
      rating: 4.4,
      enrolledCount: 3100,
      totalMinutes: 16,
      lessons: [
        _lesson('l8_1', 'The Art of Listening', 'Listen to understand, not to respond.', 8, [
          _textBlock('b33', 'Genuine Curiosity', 'Rogan\'s secret is not his questions — it is his genuine curiosity. He listens to understand, not to respond. This creates space for guests to share deeply.'),
          _timedBlock('b34', 'Active Listening Exercise', 'In your next conversation, practice listening without preparing your response. Simply be present with the other person.', 300),
        ]),
        _lesson('l8_2', 'Asking Better Questions', 'Open doors with the right questions.', 8, [
          _textBlock('b35', 'Open-Ended Questions', 'The best questions cannot be answered with yes or no. They start with "how" and "why" and "what was that like." They invite stories, not data.'),
          _reflectionBlock('b36', 'Your Question Bank', 'Write down 5 open-ended questions you could ask someone you admire. Focus on their experience and feelings, not just facts.'),
        ]),
      ],
    ),
    _course(
      id: 'course_9',
      title: 'Order from Chaos',
      description: 'Peterson\'s practical rules for structuring your life.',
      roleModelId: 'peterson',
      roleModelName: 'Jordan Peterson',
      roleModelEmoji: '\u{1F409}',
      lane: 'Mind',
      difficulty: 'intermediate',
      rating: 4.5,
      enrolledCount: 3400,
      totalMinutes: 22,
      lessons: [
        _lesson('l9_1', 'Clean Your Room', 'Start with the smallest unit of order.', 11, [
          _textBlock('b37', 'Start Small', 'Before you attempt to reorganize the world, organize your immediate environment. Your room is a reflection of your mind. Put it in order, and your mind follows.'),
          _timedBlock('b38', 'Room Reset', 'Spend the next 10 minutes tidying one area of your space. Make your bed, clear your desk, or organize a drawer.', 600),
        ]),
        _lesson('l9_2', 'Aim at Something', 'Define your highest possible good.', 11, [
          _textBlock('b39', 'The Necessity of Aim', 'Without a target, you cannot orient yourself. You need a star to navigate by — not because you will reach it, but because it gives your life direction and meaning.'),
          _reflectionBlock('b40', 'Your North Star', 'If you could become the best version of yourself in 5 years, what would that look like? Describe that person in detail.'),
        ]),
      ],
    ),
    _course(
      id: 'course_10',
      title: 'First Principles Thinking',
      description: 'Break problems down to fundamentals the Elon Musk way.',
      roleModelId: 'musk',
      roleModelName: 'Elon Musk',
      roleModelEmoji: '\u{1F680}',
      lane: 'Craft',
      difficulty: 'advanced',
      rating: 4.7,
      enrolledCount: 4100,
      totalMinutes: 20,
      lessons: [
        _lesson('l10_1', 'Reasoning from First Principles', 'Strip away assumptions.', 10, [
          _textBlock('b41', 'First Principles', 'Instead of reasoning by analogy ("this is how it has always been done"), break a problem down to its fundamental truths and build up from there. What do we know to be absolutely true?'),
          _scenarioBlock('b42', 'Battery Cost Problem', 'Battery packs cost \$600/kWh. Everyone says batteries are expensive. How does Musk think about this?', ['Accept the market price and work around it', 'Break down the raw materials cost and find it is only \$80/kWh', 'Wait for batteries to get cheaper over time'], 1, 'Musk asked: what are batteries made of? The raw materials cost a fraction of the pack price. The rest is manufacturing inefficiency — solvable.'),
        ]),
        _lesson('l10_2', 'Impossible Deadlines', 'Use urgency as a creative force.', 10, [
          _textBlock('b43', 'The Impossible Timeline', 'Musk sets deadlines that seem impossible. Why? Because conventional timelines include conventional thinking. An impossible deadline forces you to rethink everything.'),
          _multipleChoiceBlock('b44', 'Deadline Philosophy', 'Why does Musk set seemingly impossible deadlines?', ['To stress employees', 'To force unconventional thinking', 'For PR purposes', 'He is bad at estimation'], 1, 'Impossible deadlines force teams to abandon incremental thinking and find truly novel solutions.'),
        ]),
      ],
    ),
    _course(
      id: 'course_11',
      title: 'Cold Exposure Protocol',
      description: 'Huberman\'s cold therapy for resilience and health.',
      roleModelId: 'huberman',
      roleModelName: 'Andrew Huberman',
      roleModelEmoji: '\u{1F9E0}',
      lane: 'Body',
      difficulty: 'intermediate',
      rating: 4.7,
      enrolledCount: 2900,
      totalMinutes: 15,
      lessons: [
        _lesson('l11_1', 'The Science of Cold', 'How cold exposure triggers resilience.', 8, [
          _textBlock('b45', 'Dopamine Surge', 'Cold water immersion causes a 250% increase in dopamine that lasts for hours. Unlike caffeine or other stimulants, this is a sustained, healthy elevation of baseline dopamine.'),
          _keyTakeawayBlock('b46', 'Protocol', '11 total minutes of cold exposure per week, spread across 2-4 sessions. Water should be cold enough to make you want to get out but safe enough to stay in.'),
        ]),
        _lesson('l11_2', 'Building Your Practice', 'Start small and build tolerance.', 7, [
          _textBlock('b47', 'Gradual Approach', 'Start with 30 seconds of cold water at the end of your shower. Add 15 seconds each week. Within a month, you will be doing 2 minutes comfortably.'),
          _timedBlock('b48', 'Cold Finish', 'End your next shower with 30 seconds of the coldest water you can tolerate. Control your breathing.', 30),
        ]),
      ],
    ),
    _course(
      id: 'course_12',
      title: 'Gratitude Practice',
      description: 'Cultivate deep appreciation with Stoic-inspired exercises.',
      roleModelId: 'aurelius',
      roleModelName: 'Marcus Aurelius',
      roleModelEmoji: '\u{1F3DB}',
      lane: 'Soul',
      difficulty: 'beginner',
      rating: 4.5,
      enrolledCount: 2600,
      totalMinutes: 14,
      lessons: [
        _lesson('l12_1', 'Negative Visualization', 'Appreciate by imagining loss.', 7, [
          _textBlock('b49', 'Premeditatio Malorum', 'The Stoics practiced imagining losing what they valued — not to be pessimistic, but to deepen appreciation for what they have right now.'),
          _reflectionBlock('b50', 'What You Take for Granted', 'List three things you take for granted daily. Now imagine life without them. How does this shift your perspective?'),
        ]),
        _lesson('l12_2', 'Daily Gratitude Ritual', 'A simple practice for contentment.', 7, [
          _textBlock('b51', 'Three Good Things', 'Each evening, write down three good things that happened today and why they happened. Research shows this simple practice increases happiness within two weeks.'),
          _timedBlock('b52', 'Gratitude Writing', 'Write down three good things from today. For each, explain why it happened and what role you played.', 300),
        ]),
      ],
    ),
    _course(
      id: 'course_13',
      title: 'Lead Generation Machine',
      description: 'Hormozi\'s framework for building a lead generation system.',
      roleModelId: 'hormozi',
      roleModelName: 'Alex Hormozi',
      roleModelEmoji: '\u{1F4B0}',
      lane: 'Craft',
      difficulty: 'advanced',
      rating: 4.8,
      enrolledCount: 3900,
      totalMinutes: 26,
      prerequisites: ['course_5'],
      lessons: [
        _lesson('l13_1', 'The Four Lead Sources', 'Warm outreach, cold outreach, content, paid ads.', 13, [
          _textBlock('b53', 'Core Four', 'There are only four ways to get customers: warm outreach, cold outreach, content (free value), and paid ads. Master one before adding another.'),
          _scenarioBlock('b54', 'Starting from Zero', 'You are starting a new business with \$0 marketing budget. Which lead source do you start with?', ['Paid ads on Facebook', 'Cold calling strangers', 'Warm outreach to your network', 'Creating viral content'], 2, 'Hormozi says: always start with warm outreach. It is free, it has the highest conversion rate, and it proves your offer works.'),
        ]),
        _lesson('l13_2', 'Content as Leverage', 'Create content that generates leads forever.', 13, [
          _textBlock('b55', 'Give Away the Secrets', 'Give away your best knowledge for free. Sell the implementation. People will pay you to do what they already know because execution is the hard part.'),
          _reflectionBlock('b56', 'Your Content Plan', 'What are 3 pieces of valuable knowledge you could share for free that would attract your ideal customer?'),
        ]),
      ],
    ),
    _course(
      id: 'course_14',
      title: 'Purpose Discovery',
      description: 'Find your deeper purpose through Rogan-style self-examination.',
      roleModelId: 'rogan',
      roleModelName: 'Joe Rogan',
      roleModelEmoji: '\u{1F399}',
      lane: 'Soul',
      difficulty: 'intermediate',
      rating: 4.3,
      enrolledCount: 2400,
      totalMinutes: 18,
      lessons: [
        _lesson('l14_1', 'Follow Your Fascination', 'Passion emerges from curiosity.', 9, [
          _textBlock('b57', 'Curiosity Over Passion', 'Rogan did not plan to become the world\'s biggest podcaster. He followed his curiosity — martial arts, comedy, psychedelics, science. The career emerged from authentic interest.'),
          _reflectionBlock('b58', 'Your Fascinations', 'What topics could you talk about for hours without getting bored? These fascinations are clues to your purpose.'),
        ]),
        _lesson('l14_2', 'The Compound Effect', 'Small daily actions build extraordinary outcomes.', 9, [
          _textBlock('b59', 'Show Up Daily', 'Rogan has released over 2,000 podcast episodes. The secret is not genius — it is showing up consistently. Each episode compounds on the last.'),
          _keyTakeawayBlock('b60', 'Compound Principle', 'You do not need to be great to start. But you need to start to be great. Show up daily, and let compounding do the work.'),
        ]),
      ],
    ),
    _course(
      id: 'course_15',
      title: 'Running Mental Battles',
      description: 'Conquer your inner voice during physical challenges.',
      roleModelId: 'goggins',
      roleModelName: 'David Goggins',
      roleModelEmoji: '\u{1F525}',
      lane: 'Body',
      difficulty: 'intermediate',
      rating: 4.9,
      enrolledCount: 4800,
      totalMinutes: 20,
      prerequisites: ['course_1'],
      lessons: [
        _lesson('l15_1', 'The Accountability Mirror', 'Face the truth about yourself.', 10, [
          _textBlock('b61', 'Mirror Work', 'Stand in front of a mirror and tell yourself the truth. No excuses, no sugar-coating. Where are you falling short? What are you avoiding? The mirror does not lie.'),
          _timedBlock('b62', 'Mirror Session', 'Stand in front of a mirror. Look yourself in the eyes. Ask: What am I avoiding? What am I afraid of? Be honest.', 180),
        ]),
        _lesson('l15_2', 'Embracing the Suck', 'Find comfort in discomfort.', 10, [
          _textBlock('b63', 'Suffering as Fuel', 'Most people run from suffering. Goggins runs toward it. He views every painful moment as a deposit in the mental bank — the harder the experience, the bigger the deposit.'),
          _scenarioBlock('b64', 'Mile 20', 'You are at mile 20 of a marathon. Your body screams to stop. What do you do?', ['Walk and recover', 'Dig into your cookie jar and push harder', 'Drop out to prevent injury'], 1, 'Goggins: your body has reserves. Access them through mental fortitude. The pain is temporary; the pride of finishing lasts forever.'),
        ]),
      ],
    ),

    // ── New 15 courses (v2 — use audio, worksheet, checklist, quote blocks) ──
    _course(
      id: 'course_16',
      title: 'Meditation for Warriors',
      description: 'Goggins-style meditation that builds focus under pressure.',
      roleModelId: 'goggins',
      roleModelName: 'David Goggins',
      roleModelEmoji: '\u{1F525}',
      lane: 'Mind',
      difficulty: 'intermediate',
      rating: 4.7,
      enrolledCount: 3100,
      prerequisites: ['course_1'],
      totalMinutes: 22,
      lessons: [
        _lesson('l16_1', 'Stillness Under Pressure', 'Train your mind to be calm amid chaos.', 11, [
          _quoteBlock('b65', 'Goggins on Stillness', 'The only way to grow is to step into the darkness of the unknown and find the light within yourself.', 'David Goggins'),
          _audioBlock('b66', 'Guided Warrior Meditation', 'https://mock.audio/goggins-meditation.mp3', 'Close your eyes. Imagine the hardest moment of your life. Now breathe through it. You survived that. You can survive anything. Focus on your breath. In for four counts, hold for four, out for four. Every exhale releases a weakness. Every inhale builds strength.'),
          _checklistBlock('b67', 'Daily Warrior Meditation Setup', [
            'Find a quiet space with no distractions',
            'Set a timer for 10 minutes',
            'Sit upright with eyes closed',
            'Focus only on breathing for the full duration',
            'Journal one insight after the session',
          ]),
        ]),
        _lesson('l16_2', 'Visualization Power', 'See the victory before it happens.', 11, [
          _textBlock('b68', 'Mental Rehearsal', 'Before every challenge, Goggins visualizes the entire experience — the pain, the doubt, and the triumph. By the time he faces reality, he has already lived through it mentally.'),
          _worksheetBlock('b69', 'Visualization Planner', ['Your next big challenge', 'The hardest moment you expect', 'How you will push through', 'How victory will feel'], null),
          _keyTakeawayBlock('b70', 'Visualize Victory', 'Your mind cannot tell the difference between vivid imagination and reality. Use that to your advantage.'),
        ]),
      ],
    ),
    _course(
      id: 'course_17',
      title: 'Happiness Algorithms',
      description: 'Naval\'s framework for engineering personal happiness.',
      roleModelId: 'naval',
      roleModelName: 'Naval Ravikant',
      roleModelEmoji: '\u{2693}',
      lane: 'Soul',
      difficulty: 'beginner',
      rating: 4.8,
      enrolledCount: 4000,
      totalMinutes: 18,
      lessons: [
        _lesson('l17_1', 'Desire Is Suffering', 'Reduce desire to increase peace.', 9, [
          _quoteBlock('b71', 'Naval on Desire', 'Desire is a contract you make with yourself to be unhappy until you get what you want.', 'Naval Ravikant'),
          _textBlock('b72', 'The Happiness Equation', 'Happiness = Reality minus Expectations. You can chase a bigger reality, or you can release expectations. The truly wise do both.'),
          _worksheetBlock('b73', 'Desire Audit', ['A desire causing you stress', 'Why you think you need it', 'What life looks like without it', 'A desire you can release today'], null),
        ]),
        _lesson('l17_2', 'Present Moment Mastery', 'The only moment that exists is now.', 9, [
          _audioBlock('b74', 'Naval on Presence', 'https://mock.audio/naval-presence.mp3', 'The reality is, the present moment is all you have and all you will ever have. The past is a memory. The future is imagination. Both are thoughts happening now. If you can master the present moment, you have mastered life.'),
          _reflectionBlock('b75', 'Your Present Moment', 'Right now, what are you feeling? Not what you think you should feel — what do you actually feel? Describe it without judgment.'),
        ]),
      ],
    ),
    _course(
      id: 'course_18',
      title: 'Stoic Leadership',
      description: 'Lead others through self-mastery with Aurelius\' principles.',
      roleModelId: 'aurelius',
      roleModelName: 'Marcus Aurelius',
      roleModelEmoji: '\u{1F3DB}',
      lane: 'Craft',
      difficulty: 'advanced',
      rating: 4.6,
      enrolledCount: 2200,
      prerequisites: ['course_3'],
      totalMinutes: 24,
      lessons: [
        _lesson('l18_1', 'Leading by Example', 'The emperor who led from the front.', 12, [
          _quoteBlock('b76', 'Aurelius on Leadership', 'Waste no more time arguing about what a good man should be. Be one.', 'Marcus Aurelius'),
          _textBlock('b77', 'Actions Over Words', 'Marcus Aurelius led the Roman Empire not through rhetoric but through personal example. He endured the same hardships as his soldiers, slept in the same camps, and ate the same food.'),
          _checklistBlock('b78', 'Leader Self-Assessment', [
            'I lead by example, not just words',
            'I remain calm when others panic',
            'I take responsibility for failures',
            'I give credit to others for successes',
            'I make decisions based on principles, not emotions',
            'I treat everyone with the same respect',
          ]),
        ]),
        _lesson('l18_2', 'Decisions Under Pressure', 'How to decide when stakes are high.', 12, [
          _textBlock('b79', 'The Stoic Decision Framework', 'Ask three questions: Is this within my control? Does this align with virtue? Will this matter in a year? If the answer to any is no, let it go.'),
          _worksheetBlock('b80', 'Decision Framework', ['A decision weighing on you', 'Is it within your control?', 'Does it align with your values?', 'Will it matter in one year?'], null),
          _scenarioBlock('b81', 'Crisis Leadership', 'Your team has just lost a major client. Morale is low. As the leader, what is the Stoic approach?', ['Blame the responsible team member publicly', 'Take responsibility, analyze what happened, and chart a new path', 'Minimize the loss and pretend everything is fine'], 1, 'Aurelius would take responsibility, learn from the failure without bitterness, and redirect the team with clarity and calm.'),
        ]),
      ],
    ),
    _course(
      id: 'course_19',
      title: 'Dopamine Control',
      description: 'Master your reward circuitry with neuroscience protocols.',
      roleModelId: 'huberman',
      roleModelName: 'Andrew Huberman',
      roleModelEmoji: '\u{1F9E0}',
      lane: 'Mind',
      difficulty: 'intermediate',
      rating: 4.8,
      enrolledCount: 4300,
      totalMinutes: 20,
      lessons: [
        _lesson('l19_1', 'The Dopamine Baseline', 'Understand your reward system.', 10, [
          _textBlock('b83', 'Dopamine Basics', 'Dopamine is not about pleasure — it is about motivation and pursuit. Every spike is followed by a trough below baseline. The bigger the spike, the deeper the trough.'),
          _audioBlock('b84', 'Huberman on Dopamine', 'https://mock.audio/huberman-dopamine.mp3', 'The key insight about dopamine is that it is not the molecule of pleasure. It is the molecule of motivation. It drives you to seek, to pursue, to work toward goals. When you understand this, you can use it rather than be used by it.'),
          _multipleChoiceBlock('b85', 'Dopamine Quiz', 'What happens to your dopamine baseline after a large spike?', ['It stays elevated', 'It drops below the original baseline', 'It returns to normal immediately', 'It has no effect on baseline'], 1, 'After every dopamine peak, there is a trough below baseline. This is why people feel low after intense pleasure.'),
        ]),
        _lesson('l19_2', 'Dopamine Scheduling', 'Protocol for sustained motivation.', 10, [
          _checklistBlock('b86', 'Weekly Dopamine Protocol', [
            'Limit phone scrolling to under 30 minutes daily',
            'Do one hard workout without music',
            'Delay caffeine 90 minutes after waking',
            'Practice one boring task without distraction',
            'Take a cold shower at least twice this week',
          ]),
          _keyTakeawayBlock('b87', 'Protect Your Baseline', 'Guard your dopamine baseline like you guard your bank account. Every mindless scroll is a withdrawal. Every disciplined action is a deposit.'),
        ]),
      ],
    ),
    _course(
      id: 'course_20',
      title: 'Business Scaling Playbook',
      description: 'Hormozi\'s proven systems for scaling past \$1M.',
      roleModelId: 'hormozi',
      roleModelName: 'Alex Hormozi',
      roleModelEmoji: '\u{1F4B0}',
      lane: 'Craft',
      difficulty: 'advanced',
      rating: 4.9,
      enrolledCount: 3500,
      prerequisites: ['course_5', 'course_13'],
      totalMinutes: 28,
      lessons: [
        _lesson('l20_1', 'The Constraint Audit', 'Find and fix your bottleneck.', 14, [
          _textBlock('b88', 'One Constraint Rule', 'At any given time, your business has exactly one bottleneck limiting growth. Find it, fix it, then find the next one. Do not try to fix everything at once.'),
          _worksheetBlock('b89', 'Constraint Finder', ['Your current revenue level', 'What is preventing growth right now?', 'If you fixed only one thing, what would it be?', 'What would revenue look like after fixing it?'], null),
          _quoteBlock('b90', 'Hormozi on Focus', 'The man who chases two rabbits catches neither. The entrepreneur who fixes two constraints fixes neither.', 'Alex Hormozi'),
        ]),
        _lesson('l20_2', 'Systems Over Hustle', 'Build systems that scale without you.', 14, [
          _textBlock('b91', 'The Scaling Paradox', 'To grow, you must make yourself replaceable. Document every process. Train others to execute. Your job is to build the machine, not be the machine.'),
          _checklistBlock('b92', 'Systems Audit', [
            'Document your top 5 recurring processes',
            'Record a training video for each process',
            'Assign ownership of each process to a team member',
            'Create quality check metrics for each process',
            'Schedule monthly process review meetings',
          ]),
        ]),
      ],
    ),
    _course(
      id: 'course_21',
      title: 'Athletic Recovery Science',
      description: 'CR7\'s recovery methods backed by sports science.',
      roleModelId: 'cr7',
      roleModelName: 'Cristiano Ronaldo',
      roleModelEmoji: '\u{26BD}',
      lane: 'Body',
      difficulty: 'intermediate',
      rating: 4.6,
      enrolledCount: 2700,
      prerequisites: ['course_6'],
      totalMinutes: 20,
      lessons: [
        _lesson('l21_1', 'Sleep as a Superpower', 'Optimize your sleep for performance.', 10, [
          _audioBlock('b93', 'CR7 on Sleep', 'https://mock.audio/cr7-sleep.mp3', 'I sleep five times a day for 90 minutes each. But for most people, the key is getting a solid 8 hours and making those hours count. Dark room, cool temperature, no phone. Your body repairs itself during deep sleep.'),
          _checklistBlock('b94', 'Sleep Optimization Checklist', [
            'Set a consistent bedtime and wake time',
            'Make bedroom completely dark',
            'Set room temperature to 65-68 degrees',
            'No screens 1 hour before bed',
            'No caffeine after 2 PM',
            'Do a 5-minute stretch before bed',
          ]),
        ]),
        _lesson('l21_2', 'Nutrition for Recovery', 'Fuel your body for peak repair.', 10, [
          _textBlock('b95', 'The Recovery Plate', 'Post-workout: lean protein within 30 minutes, complex carbs within 2 hours, and hydration throughout. CR7\'s diet is meticulous — every meal serves a purpose.'),
          _worksheetBlock('b96', 'Recovery Meal Plan', ['Your typical post-workout meal', 'Protein source and grams', 'Carb source and timing', 'Hydration plan for tomorrow'], null),
        ]),
      ],
    ),
    _course(
      id: 'course_22',
      title: 'Game Design Thinking',
      description: 'Apply Miyamoto\'s design principles beyond games.',
      roleModelId: 'miyamoto',
      roleModelName: 'Shigeru Miyamoto',
      roleModelEmoji: '\u{1F3AE}',
      lane: 'Mind',
      difficulty: 'intermediate',
      rating: 4.5,
      enrolledCount: 1900,
      prerequisites: ['course_7'],
      totalMinutes: 20,
      lessons: [
        _lesson('l22_1', 'Iterative Design', 'Prototype, test, refine, repeat.', 10, [
          _quoteBlock('b97', 'Miyamoto on Iteration', 'An idea that is developed and put into action is more important than an idea that exists only as an idea.', 'Shigeru Miyamoto'),
          _textBlock('b98', 'Rapid Prototyping', 'Miyamoto builds rough prototypes within days. He does not wait for perfection — he creates something playable and tests it with real people immediately. Feedback drives the next iteration.'),
          _worksheetBlock('b99', 'Prototype Plan', ['Your current idea or project', 'Simplest possible version to test', 'Who will you test it with?', 'Three questions to ask testers'], null),
        ]),
        _lesson('l22_2', 'Surprise and Delight', 'Hidden rewards keep people engaged.', 10, [
          _textBlock('b100', 'Secret Discoveries', 'Every Miyamoto game has hidden areas and secrets. Why? Because unexpected rewards create the most powerful dopamine responses. Apply this: add unexpected value to everything you create.'),
          _reflectionBlock('b101', 'Your Hidden Gems', 'What unexpected bonus or surprise could you add to your work that would delight someone? Think beyond the expected deliverable.'),
        ]),
      ],
    ),
    _course(
      id: 'course_23',
      title: 'Fearless Communication',
      description: 'Rogan\'s approach to authentic and bold conversations.',
      roleModelId: 'rogan',
      roleModelName: 'Joe Rogan',
      roleModelEmoji: '\u{1F399}',
      lane: 'Craft',
      difficulty: 'intermediate',
      rating: 4.4,
      enrolledCount: 2600,
      prerequisites: ['course_8'],
      totalMinutes: 22,
      lessons: [
        _lesson('l23_1', 'Speaking Your Truth', 'Authenticity over approval.', 11, [
          _quoteBlock('b102', 'Rogan on Authenticity', 'Be the hero of your own movie. If your movie was a film about a guy who sits on the couch, nobody would watch it.', 'Joe Rogan'),
          _audioBlock('b103', 'Finding Your Voice', 'https://mock.audio/rogan-voice.mp3', 'The biggest mistake people make in communication is trying to say what others want to hear. When you speak your truth, you attract the right people and repel the wrong ones. That is not a bug — it is a feature.'),
          _checklistBlock('b104', 'Authenticity Audit', [
            'Identify one opinion you hold back in conversations',
            'Practice sharing it respectfully with someone you trust',
            'Notice how it feels to speak authentically',
            'Reflect on the response you received',
          ]),
        ]),
        _lesson('l23_2', 'Handling Disagreement', 'Disagree without being disagreeable.', 11, [
          _textBlock('b105', 'Steel Man Arguments', 'Before disagreeing with someone, first present their argument in its strongest possible form. This shows respect and often reveals that the disagreement is smaller than you thought.'),
          _scenarioBlock('b106', 'Heated Discussion', 'A friend shares a strong opinion you completely disagree with. What is the Rogan approach?', ['Immediately counter with your own opinion', 'Ask them to explain more and try to understand their reasoning first', 'Change the subject to avoid conflict'], 1, 'Rogan always seeks to understand first. He asks follow-up questions, repeats back what he heard, and only then shares his perspective.'),
        ]),
      ],
    ),
    _course(
      id: 'course_24',
      title: 'Meaning Through Responsibility',
      description: 'Peterson\'s guide to finding meaning in daily obligations.',
      roleModelId: 'peterson',
      roleModelName: 'Jordan Peterson',
      roleModelEmoji: '\u{1F409}',
      lane: 'Soul',
      difficulty: 'intermediate',
      rating: 4.6,
      enrolledCount: 2800,
      prerequisites: ['course_9'],
      totalMinutes: 22,
      lessons: [
        _lesson('l24_1', 'The Weight of Meaning', 'Carry a heavy load voluntarily.', 11, [
          _quoteBlock('b107', 'Peterson on Meaning', 'The purpose of life is finding the largest burden that you can bear and bearing it.', 'Jordan Peterson'),
          _textBlock('b108', 'Voluntary Suffering', 'Meaning is not found in comfort. It is found in taking on responsibility that matters — raising children well, building something of value, serving your community. The weight gives your life structure.'),
          _worksheetBlock('b109', 'Responsibility Inventory', ['A responsibility you have been avoiding', 'Why you have been avoiding it', 'What would change if you embraced it fully', 'Your first step toward accepting it'], null),
        ]),
        _lesson('l24_2', 'Truth as Foundation', 'Build your life on truth-telling.', 11, [
          _audioBlock('b110', 'Peterson on Truth', 'https://mock.audio/peterson-truth.mp3', 'Every time you tell a lie, you weaken yourself. Every time you tell the truth, especially when it is difficult, you strengthen yourself. Truth is the foundation upon which a meaningful life is built. Without it, everything you construct is built on sand.'),
          _reflectionBlock('b111', 'Your Truth Practice', 'Where in your life are you being less than fully honest? With others? With yourself? What is one truth you need to tell this week?'),
        ]),
      ],
    ),
    _course(
      id: 'course_25',
      title: 'Moonshot Thinking',
      description: 'Think 10x bigger with Musk\'s visionary framework.',
      roleModelId: 'musk',
      roleModelName: 'Elon Musk',
      roleModelEmoji: '\u{1F680}',
      lane: 'Mind',
      difficulty: 'advanced',
      rating: 4.7,
      enrolledCount: 3300,
      prerequisites: ['course_10'],
      totalMinutes: 24,
      lessons: [
        _lesson('l25_1', 'The 10x Mindset', 'Why thinking bigger is easier than thinking small.', 12, [
          _quoteBlock('b112', 'Musk on Ambition', 'If something is important enough, you should try, even if the probable outcome is failure.', 'Elon Musk'),
          _textBlock('b113', '10x vs 10%', 'A 10% improvement requires optimizing the existing system. A 10x improvement requires rethinking the entire approach. Paradoxically, 10x goals attract better talent, more resources, and generate more creative solutions.'),
          _worksheetBlock('b114', '10x Goal Setting', ['Your current biggest goal', 'What would 10x of that goal look like?', 'Why is the 10x version actually exciting?', 'What would you need to rethink entirely?'], null),
        ]),
        _lesson('l25_2', 'Multi-Planetary Thinking', 'Expand your time horizon.', 12, [
          _textBlock('b115', 'Long-Term Vision', 'Musk operates on a 20-50 year timeline. When you extend your time horizon, decisions that seem risky in the short term become obvious in the long term. SpaceX makes no sense on a 5-year timeline. On a 50-year timeline, it is humanity\'s most important project.'),
          _audioBlock('b116', 'Thinking in Decades', 'https://mock.audio/musk-decades.mp3', 'Most people overestimate what they can do in one year and underestimate what they can do in ten years. The key is to set a direction that matters on a 20-year horizon, then work backward to what you should do today. Every day becomes a step toward something monumental.'),
        ]),
      ],
    ),
    _course(
      id: 'course_26',
      title: 'Breath Work Mastery',
      description: 'Huberman\'s breathing protocols for focus, calm, and energy.',
      roleModelId: 'huberman',
      roleModelName: 'Andrew Huberman',
      roleModelEmoji: '\u{1F9E0}',
      lane: 'Body',
      difficulty: 'beginner',
      rating: 4.8,
      enrolledCount: 4600,
      totalMinutes: 16,
      lessons: [
        _lesson('l26_1', 'The Physiological Sigh', 'The fastest way to calm down.', 8, [
          _textBlock('b117', 'Double Inhale, Long Exhale', 'The physiological sigh — two quick inhales through the nose followed by a long exhale through the mouth — is the fastest real-time tool for reducing stress. It reinflates the alveoli and offloads CO2 rapidly.'),
          _audioBlock('b118', 'Guided Physiological Sigh', 'https://mock.audio/huberman-sigh.mp3', 'Take a deep inhale through your nose. Now, without exhaling, inhale again to top off your lungs. Now exhale slowly and completely through your mouth. Feel the calm wash over you. Repeat three times. This is the physiological sigh — it works in real time to activate your parasympathetic nervous system.'),
          _timedBlock('b119', 'Practice Session', 'Perform 5 physiological sighs: double inhale through the nose, long exhale through the mouth. Notice how you feel after.', 120),
        ]),
        _lesson('l26_2', 'Cyclic Hyperventilation', 'Use breath to energize.', 8, [
          _textBlock('b120', 'Controlled Adrenaline', 'Wim Hof-style cyclic hyperventilation (25-30 deep breaths followed by a hold) releases adrenaline and increases alertness. Huberman recommends this before workouts or creative sessions — never before driving or swimming.'),
          _checklistBlock('b121', 'Breath Work Safety Checklist', [
            'Practice seated or lying down only',
            'Never do breath work in water or while driving',
            'Start with 15 breaths if you are new',
            'Stop if you feel tingling in fingers',
            'Always end with a calming breath cycle',
          ]),
        ]),
      ],
    ),
    _course(
      id: 'course_27',
      title: 'Peak Performance Mindset',
      description: 'CR7\'s mental approach to competition and excellence.',
      roleModelId: 'cr7',
      roleModelName: 'Cristiano Ronaldo',
      roleModelEmoji: '\u{26BD}',
      lane: 'Soul',
      difficulty: 'beginner',
      rating: 4.5,
      enrolledCount: 3000,
      totalMinutes: 18,
      lessons: [
        _lesson('l27_1', 'Self-Belief as Fuel', 'Confidence is a choice you make daily.', 9, [
          _quoteBlock('b122', 'CR7 on Belief', 'Your love makes me strong, your hate makes me unstoppable.', 'Cristiano Ronaldo'),
          _textBlock('b123', 'Manufactured Confidence', 'Ronaldo\'s confidence is not innate — it is manufactured through preparation. When you have done the work, belief in yourself is rational, not arrogant.'),
          _worksheetBlock('b124', 'Confidence Builder', ['Something you lack confidence in', 'What specific preparation would build confidence?', 'A daily practice to build that skill', 'How you will measure progress'], null),
        ]),
        _lesson('l27_2', 'Legacy Thinking', 'Play for something bigger than today.', 9, [
          _textBlock('b125', 'Beyond the Game', 'CR7 does not play for the next match — he plays for history. When you shift your frame from short-term results to long-term legacy, your daily decisions become more purposeful.'),
          _reflectionBlock('b126', 'Your Legacy', 'In 20 years, what do you want to be remembered for? How does that legacy inform what you do today?'),
        ]),
      ],
    ),
    _course(
      id: 'course_28',
      title: 'Innovation Through Play',
      description: 'Miyamoto\'s secrets to creative breakthroughs.',
      roleModelId: 'miyamoto',
      roleModelName: 'Shigeru Miyamoto',
      roleModelEmoji: '\u{1F3AE}',
      lane: 'Soul',
      difficulty: 'beginner',
      rating: 4.7,
      enrolledCount: 2100,
      totalMinutes: 16,
      lessons: [
        _lesson('l28_1', 'Childlike Wonder', 'See the world through fresh eyes.', 8, [
          _quoteBlock('b127', 'Miyamoto on Wonder', 'What if everything you see is more than what you see? What if the person next to you is a world that is just as interesting as the one you see out of a window on a train?', 'Shigeru Miyamoto'),
          _textBlock('b128', 'The Explorer\'s Mindset', 'Miyamoto designed Zelda based on his childhood explorations of caves and forests near Kyoto. The sense of wonder and discovery that children feel naturally is a creative superpower that most adults abandon.'),
          _checklistBlock('b129', 'Weekly Wonder Practice', [
            'Take a different route to work or school',
            'Visit a place you have never been in your city',
            'Talk to a stranger about their interests',
            'Try a creative medium you have never tried before',
            'Spend 30 minutes observing nature without your phone',
          ]),
        ]),
        _lesson('l28_2', 'Constraints as Freedom', 'Limitations breed creativity.', 8, [
          _textBlock('b130', 'The NES Constraint', 'The NES had 2KB of RAM and no ability to scroll. Miyamoto turned these constraints into features — Mario\'s design, the level structure, and even the iconic question-mark blocks were all born from hardware limitations.'),
          _worksheetBlock('b131', 'Constraint Reframe', ['A limitation you are currently facing', 'How could this limitation become a feature?', 'What creative solution does this constraint suggest?', 'What advantage does this give you over those without the constraint?'], null),
        ]),
      ],
    ),
    _course(
      id: 'course_29',
      title: 'Discipline Equals Freedom',
      description: 'Transform your daily routine with structured discipline.',
      roleModelId: 'goggins',
      roleModelName: 'David Goggins',
      roleModelEmoji: '\u{1F525}',
      lane: 'Body',
      difficulty: 'advanced',
      rating: 4.9,
      enrolledCount: 3800,
      prerequisites: ['course_1', 'course_15'],
      totalMinutes: 26,
      lessons: [
        _lesson('l29_1', 'The 4 AM Protocol', 'Win the morning, win the day.', 13, [
          _audioBlock('b132', 'Goggins on Mornings', 'https://mock.audio/goggins-morning.mp3', 'When that alarm goes off, you have a choice. Stay comfortable, or get up and attack the day. Every morning you choose comfort, you lose. Every morning you choose discipline, you deposit strength into your mental bank. There is no snooze button in combat.'),
          _checklistBlock('b133', 'Morning Attack Checklist', [
            'Wake at 4:00 AM — no snooze',
            'Make your bed immediately',
            'Drink 16oz of water',
            'Stretch or mobility work for 10 minutes',
            'Run or workout for 30+ minutes',
            'Cold shower to finish',
            'Journal your intentions for the day',
          ]),
          _keyTakeawayBlock('b134', 'Non-Negotiables', 'The morning routine is not optional — it is the foundation of everything that follows. Discipline in the first hour sets the tone for the next 23.'),
        ]),
        _lesson('l29_2', 'Suffering as a Skill', 'Train your ability to endure.', 13, [
          _textBlock('b135', 'Voluntary Hardship', 'Goggins intentionally seeks suffering: ultra-marathons, pull-up records, SEAL training three times. Why? Because suffering is a skill, and like any skill, it improves with practice.'),
          _worksheetBlock('b136', 'Hardship Plan', ['A physical challenge to attempt this month', 'Why this scares you', 'How you will prepare', 'What you will learn about yourself'], null),
          _quoteBlock('b137', 'Goggins on Growth', 'You are in danger of living a life so comfortable and soft that you will die without ever realizing your potential.', 'David Goggins'),
        ]),
      ],
    ),
    _course(
      id: 'course_30',
      title: 'Naval\'s Reading Method',
      description: 'Build a knowledge compounding system through reading.',
      roleModelId: 'naval',
      roleModelName: 'Naval Ravikant',
      roleModelEmoji: '\u{2693}',
      lane: 'Mind',
      difficulty: 'beginner',
      rating: 4.6,
      enrolledCount: 3500,
      totalMinutes: 16,
      lessons: [
        _lesson('l30_1', 'Read What You Love', 'Follow your curiosity, not bestseller lists.', 8, [
          _quoteBlock('b138', 'Naval on Reading', 'Read what you love until you love to read.', 'Naval Ravikant'),
          _textBlock('b139', 'The Anti-Curriculum', 'Naval reads dozens of books simultaneously and drops any book that loses his interest. He re-reads favorites instead of forcing through new books. The goal is knowledge compounding, not completion metrics.'),
          _checklistBlock('b140', 'Reading System Setup', [
            'List 5 topics you are genuinely curious about',
            'Get 3 books on your top topic',
            'Start all three — keep reading whichever grabs you',
            'Give yourself permission to quit books that bore you',
            'Re-read one book that changed your thinking',
          ]),
        ]),
        _lesson('l30_2', 'Knowledge Compounding', 'Build mental models that stack.', 8, [
          _textBlock('b141', 'Foundation Books', 'Naval recommends building foundational knowledge in math, science, and philosophy before specializing. These mental models compound — each new idea connects to existing ones and multiplies understanding.'),
          _worksheetBlock('b142', 'Knowledge Map', ['A foundational concept you understand well', 'A new concept you are learning', 'How do these two concepts connect?', 'What third concept bridges them?'], null),
        ]),
      ],
    ),
  ];
}

// ── Block Builders ──

ForgeBlock _textBlock(String id, String title, String content) {
  return ForgeBlock(id: id, type: ForgeBlockType.text, title: title, content: content);
}

ForgeBlock _scenarioBlock(String id, String title, String content, List<String> choices, int correct, String explanation) {
  return ForgeBlock(id: id, type: ForgeBlockType.scenario, title: title, content: content, choices: choices, correctChoice: correct, explanation: explanation);
}

ForgeBlock _timedBlock(String id, String title, String instruction, int seconds) {
  return ForgeBlock(id: id, type: ForgeBlockType.timedExercise, title: title, instruction: instruction, durationSeconds: seconds);
}

ForgeBlock _multipleChoiceBlock(String id, String title, String content, List<String> options, int correct, String explanation) {
  return ForgeBlock(id: id, type: ForgeBlockType.multipleChoice, title: title, content: content, options: options, correctOption: correct, explanation: explanation);
}

ForgeBlock _reflectionBlock(String id, String title, String content) {
  return ForgeBlock(id: id, type: ForgeBlockType.reflection, title: title, content: content);
}

ForgeBlock _keyTakeawayBlock(String id, String title, String content) {
  return ForgeBlock(id: id, type: ForgeBlockType.keyTakeaway, title: title, content: content);
}

// v2 block builders

ForgeBlock _audioBlock(String id, String title, String audioUrl, String transcript) {
  return ForgeBlock(id: id, type: ForgeBlockType.audio, title: title, audioUrl: audioUrl, transcript: transcript);
}

ForgeBlock _worksheetBlock(String id, String title, List<String> blanks, List<String>? answers) {
  return ForgeBlock(id: id, type: ForgeBlockType.worksheet, title: title, worksheetBlanks: blanks, worksheetAnswers: answers);
}

ForgeBlock _checklistBlock(String id, String title, List<String> items) {
  return ForgeBlock(id: id, type: ForgeBlockType.checklist, title: title, checklistItems: items, checklistChecked: List.filled(items.length, false));
}

ForgeBlock _quoteBlock(String id, String title, String content, String author) {
  return ForgeBlock(id: id, type: ForgeBlockType.quote, title: title, content: content, quoteAuthor: author);
}

// ── Course Builder ──

ForgeCourse _course({
  required String id,
  required String title,
  required String description,
  required String roleModelId,
  required String roleModelName,
  required String roleModelEmoji,
  required String lane,
  required List<ForgeLesson> lessons,
  required int totalMinutes,
  String difficulty = 'beginner',
  List<String> prerequisites = const [],
  double rating = 0.0,
  int enrolledCount = 0,
}) {
  return ForgeCourse(
    id: id,
    title: title,
    description: description,
    roleModelId: roleModelId,
    roleModelName: roleModelName,
    roleModelEmoji: roleModelEmoji,
    lane: lane,
    lessons: lessons,
    totalMinutes: totalMinutes,
    difficulty: difficulty,
    prerequisites: prerequisites,
    rating: rating,
    enrolledCount: enrolledCount,
  );
}

ForgeLesson _lesson(String id, String title, String summary, int minutes, List<ForgeBlock> blocks) {
  return ForgeLesson(id: id, title: title, summary: summary, estimatedMinutes: minutes, blocks: blocks);
}

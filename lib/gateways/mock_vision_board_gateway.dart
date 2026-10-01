import '../models/vision_board.dart';
import 'vision_board_gateway.dart';

class MockVisionBoardGateway implements VisionBoardGateway {
  final List<VisionGoal> _goals = [
    VisionGoal(
      id: 'goal_1',
      title: 'Read 24 books this year',
      description:
          'Expand my mind by reading two books every month across philosophy, psychology, and business.',
      emoji: '📚',
      category: VisionCategory.mind,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.year,
      targetDate: DateTime(2026, 12, 31),
      progress: 0.58,
      createdAt: DateTime(2026, 1, 5),
      affirmation:
          'Every page I read adds a new dimension to my thinking.',
      milestones: [
        Milestone(
          id: 'ms_1_1',
          title: 'Read 6 books (Q1)',
          isCompleted: true,
          completedAt: DateTime(2026, 3, 28),
          order: 1,
        ),
        Milestone(
          id: 'ms_1_2',
          title: 'Read 12 books (Q2)',
          isCompleted: true,
          completedAt: DateTime(2026, 6, 22),
          order: 2,
        ),
        Milestone(
          id: 'ms_1_3',
          title: 'Read 18 books (Q3)',
          isCompleted: false,
          order: 3,
        ),
        Milestone(
          id: 'ms_1_4',
          title: 'Read 24 books (Q4)',
          isCompleted: false,
          order: 4,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_2',
      title: 'Run a half marathon',
      description:
          'Train consistently to complete a half marathon under 2 hours. Build endurance and discipline.',
      emoji: '🏃',
      category: VisionCategory.body,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.year,
      targetDate: DateTime(2026, 11, 15),
      progress: 0.35,
      createdAt: DateTime(2026, 2, 1),
      affirmation:
          'My body grows stronger with every run. The finish line is calling.',
      milestones: [
        Milestone(
          id: 'ms_2_1',
          title: 'Run 5K without stopping',
          isCompleted: true,
          completedAt: DateTime(2026, 3, 10),
          order: 1,
        ),
        Milestone(
          id: 'ms_2_2',
          title: 'Run 10K under 60 minutes',
          isCompleted: true,
          completedAt: DateTime(2026, 5, 18),
          order: 2,
        ),
        Milestone(
          id: 'ms_2_3',
          title: 'Run 15K comfortably',
          isCompleted: false,
          order: 3,
        ),
        Milestone(
          id: 'ms_2_4',
          title: 'Complete practice half marathon',
          isCompleted: false,
          order: 4,
        ),
        Milestone(
          id: 'ms_2_5',
          title: 'Race day — finish under 2 hours',
          isCompleted: false,
          order: 5,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_3',
      title: 'Build 3 close friendships',
      description:
          'Invest deeply in three meaningful friendships with regular check-ins, shared experiences, and vulnerability.',
      emoji: '🫂',
      category: VisionCategory.social,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.year,
      targetDate: DateTime(2026, 12, 31),
      progress: 0.67,
      createdAt: DateTime(2026, 1, 15),
      affirmation:
          'I attract and nurture friendships that bring out the best in me.',
      milestones: [
        Milestone(
          id: 'ms_3_1',
          title: 'Identify 3 people to invest in',
          isCompleted: true,
          completedAt: DateTime(2026, 2, 1),
          order: 1,
        ),
        Milestone(
          id: 'ms_3_2',
          title: 'Schedule monthly hangouts',
          isCompleted: true,
          completedAt: DateTime(2026, 3, 5),
          order: 2,
        ),
        Milestone(
          id: 'ms_3_3',
          title: 'Have a deep conversation with each',
          isCompleted: true,
          completedAt: DateTime(2026, 4, 20),
          order: 3,
        ),
        Milestone(
          id: 'ms_3_4',
          title: 'Plan a group trip or experience',
          isCompleted: false,
          order: 4,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_4',
      title: 'Learn Flutter',
      description:
          'Master Flutter development by building real apps, contributing to open source, and understanding the framework deeply.',
      emoji: '💻',
      category: VisionCategory.skill,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.quarter,
      targetDate: DateTime(2026, 9, 30),
      progress: 0.80,
      createdAt: DateTime(2026, 4, 1),
      affirmation:
          'I am becoming a skilled developer who builds things that matter.',
      milestones: [
        Milestone(
          id: 'ms_4_1',
          title: 'Complete Flutter fundamentals course',
          isCompleted: true,
          completedAt: DateTime(2026, 4, 25),
          order: 1,
        ),
        Milestone(
          id: 'ms_4_2',
          title: 'Build a todo app with state management',
          isCompleted: true,
          completedAt: DateTime(2026, 5, 15),
          order: 2,
        ),
        Milestone(
          id: 'ms_4_3',
          title: 'Build a full app with API integration',
          isCompleted: true,
          completedAt: DateTime(2026, 7, 1),
          order: 3,
        ),
        Milestone(
          id: 'ms_4_4',
          title: 'Contribute to an open source Flutter package',
          isCompleted: true,
          completedAt: DateTime(2026, 8, 10),
          order: 4,
        ),
        Milestone(
          id: 'ms_4_5',
          title: 'Publish an app to the Play Store',
          isCompleted: false,
          order: 5,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_5',
      title: 'Launch my side project',
      description:
          'Ship a real product that solves a problem I care about. Get 100 users in the first month.',
      emoji: '🚀',
      category: VisionCategory.skill,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.quarter,
      targetDate: DateTime(2026, 10, 31),
      progress: 0.45,
      createdAt: DateTime(2026, 5, 1),
      affirmation:
          'I create value by shipping real products into the world.',
      milestones: [
        Milestone(
          id: 'ms_5_1',
          title: 'Validate the idea with 10 potential users',
          isCompleted: true,
          completedAt: DateTime(2026, 5, 20),
          order: 1,
        ),
        Milestone(
          id: 'ms_5_2',
          title: 'Build the MVP',
          isCompleted: true,
          completedAt: DateTime(2026, 7, 15),
          order: 2,
        ),
        Milestone(
          id: 'ms_5_3',
          title: 'Set up landing page and waitlist',
          isCompleted: false,
          order: 3,
        ),
        Milestone(
          id: 'ms_5_4',
          title: 'Launch publicly',
          isCompleted: false,
          order: 4,
        ),
        Milestone(
          id: 'ms_5_5',
          title: 'Reach 100 users',
          isCompleted: false,
          order: 5,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_6',
      title: 'Meditate 100 days',
      description:
          'Build an unshakeable meditation habit. Start with 5 minutes, build to 20 minutes daily.',
      emoji: '🧘',
      category: VisionCategory.mind,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.year,
      targetDate: DateTime(2026, 12, 31),
      progress: 0.72,
      createdAt: DateTime(2026, 1, 1),
      affirmation:
          'Stillness is my superpower. I train my mind every single day.',
      milestones: [
        Milestone(
          id: 'ms_6_1',
          title: 'Meditate for 7 consecutive days',
          isCompleted: true,
          completedAt: DateTime(2026, 1, 8),
          order: 1,
        ),
        Milestone(
          id: 'ms_6_2',
          title: 'Reach 30-day streak',
          isCompleted: true,
          completedAt: DateTime(2026, 2, 1),
          order: 2,
        ),
        Milestone(
          id: 'ms_6_3',
          title: 'Increase to 15 minutes per session',
          isCompleted: true,
          completedAt: DateTime(2026, 4, 15),
          order: 3,
        ),
        Milestone(
          id: 'ms_6_4',
          title: 'Complete 100 total sessions',
          isCompleted: false,
          order: 4,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_7',
      title: 'Save \$5000 emergency fund',
      description:
          'Build financial security by saving consistently every month. Automate savings and reduce unnecessary spending.',
      emoji: '💰',
      category: VisionCategory.life,
      status: GoalStatus.in_progress,
      timeframe: GoalTimeframe.year,
      targetDate: DateTime(2026, 12, 31),
      progress: 0.60,
      createdAt: DateTime(2026, 1, 1),
      affirmation:
          'I am building the financial foundation for the life I want.',
      milestones: [
        Milestone(
          id: 'ms_7_1',
          title: 'Set up automatic transfers',
          isCompleted: true,
          completedAt: DateTime(2026, 1, 10),
          order: 1,
        ),
        Milestone(
          id: 'ms_7_2',
          title: 'Save \$1000',
          isCompleted: true,
          completedAt: DateTime(2026, 3, 1),
          order: 2,
        ),
        Milestone(
          id: 'ms_7_3',
          title: 'Save \$3000',
          isCompleted: true,
          completedAt: DateTime(2026, 6, 15),
          order: 3,
        ),
        Milestone(
          id: 'ms_7_4',
          title: 'Save \$5000',
          isCompleted: false,
          order: 4,
        ),
      ],
    ),
    VisionGoal(
      id: 'goal_8',
      title: 'Speak at a meetup',
      description:
          'Overcome the fear of public speaking by giving a talk at a local tech or personal development meetup.',
      emoji: '🎤',
      category: VisionCategory.social,
      status: GoalStatus.not_started,
      timeframe: GoalTimeframe.quarter,
      targetDate: DateTime(2026, 12, 15),
      progress: 0.0,
      createdAt: DateTime(2026, 8, 1),
      affirmation:
          'My voice matters. I have valuable ideas worth sharing with the world.',
      milestones: [
        Milestone(
          id: 'ms_8_1',
          title: 'Research local meetups and events',
          isCompleted: false,
          order: 1,
        ),
        Milestone(
          id: 'ms_8_2',
          title: 'Choose a topic and write an outline',
          isCompleted: false,
          order: 2,
        ),
        Milestone(
          id: 'ms_8_3',
          title: 'Practice in front of friends',
          isCompleted: false,
          order: 3,
        ),
        Milestone(
          id: 'ms_8_4',
          title: 'Apply to speak at a meetup',
          isCompleted: false,
          order: 4,
        ),
        Milestone(
          id: 'ms_8_5',
          title: 'Deliver the talk',
          isCompleted: false,
          order: 5,
        ),
      ],
    ),
  ];

  final List<VisionSnapshot> _snapshots = [
    VisionSnapshot(
      id: 'snap_1',
      date: DateTime(2026, 6, 1),
      goalsTotal: 7,
      goalsAchieved: 0,
      categoryBreakdown: {
        VisionCategory.mind: 0.35,
        VisionCategory.body: 0.15,
        VisionCategory.social: 0.40,
        VisionCategory.skill: 0.50,
        VisionCategory.life: 0.25,
      },
      notes: 'Steady progress on most fronts. Social goals moving fastest.',
    ),
    VisionSnapshot(
      id: 'snap_2',
      date: DateTime(2026, 7, 1),
      goalsTotal: 8,
      goalsAchieved: 0,
      categoryBreakdown: {
        VisionCategory.mind: 0.45,
        VisionCategory.body: 0.22,
        VisionCategory.social: 0.52,
        VisionCategory.skill: 0.60,
        VisionCategory.life: 0.38,
      },
      notes:
          'Added a new goal. Flutter learning accelerating. Need to push harder on running.',
    ),
    VisionSnapshot(
      id: 'snap_3',
      date: DateTime(2026, 8, 1),
      goalsTotal: 8,
      goalsAchieved: 0,
      categoryBreakdown: {
        VisionCategory.mind: 0.55,
        VisionCategory.body: 0.28,
        VisionCategory.social: 0.60,
        VisionCategory.skill: 0.70,
        VisionCategory.life: 0.48,
      },
      notes:
          'Great momentum on skill goals. Meditation habit is solid. Body goals need more focus.',
    ),
    VisionSnapshot(
      id: 'snap_4',
      date: DateTime(2026, 9, 1),
      goalsTotal: 8,
      goalsAchieved: 1,
      categoryBreakdown: {
        VisionCategory.mind: 0.65,
        VisionCategory.body: 0.35,
        VisionCategory.social: 0.67,
        VisionCategory.skill: 0.80,
        VisionCategory.life: 0.60,
      },
      notes:
          'Best month yet. Flutter goal nearly complete. Emergency fund on track. Started thinking about the meetup talk.',
    ),
  ];

  final List<VisionQuote> _quotes = [
    const VisionQuote(
      id: 'quote_1',
      text: 'The only way to do great work is to love what you do.',
      author: 'Steve Jobs',
      category: VisionCategory.skill,
    ),
    const VisionQuote(
      id: 'quote_2',
      text:
          'Take care of your body. It\'s the only place you have to live.',
      author: 'Jim Rohn',
      category: VisionCategory.body,
    ),
    const VisionQuote(
      id: 'quote_3',
      text:
          'The mind is everything. What you think you become.',
      author: 'Buddha',
      category: VisionCategory.mind,
    ),
    const VisionQuote(
      id: 'quote_4',
      text:
          'You are the average of the five people you spend the most time with.',
      author: 'Jim Rohn',
      category: VisionCategory.social,
    ),
    const VisionQuote(
      id: 'quote_5',
      text:
          'The best time to plant a tree was 20 years ago. The second best time is now.',
      author: 'Chinese Proverb',
      category: VisionCategory.life,
    ),
  ];

  @override
  Future<List<VisionGoal>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_goals);
  }

  @override
  Future<VisionGoal> getGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _goals.firstWhere((g) => g.id == id);
  }

  @override
  Future<void> saveGoal(VisionGoal goal) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
    } else {
      _goals.add(goal);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 180));
    _goals.removeWhere((g) => g.id == id);
  }

  @override
  Future<void> updateMilestone(
    String goalId,
    String milestoneId,
    bool isCompleted,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex >= 0) {
      final goal = _goals[goalIndex];
      final updatedMilestones = goal.milestones.map((m) {
        if (m.id == milestoneId) {
          return m.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return m;
      }).toList();

      final completedCount =
          updatedMilestones.where((m) => m.isCompleted).length;
      final newProgress = updatedMilestones.isNotEmpty
          ? completedCount / updatedMilestones.length
          : 0.0;

      _goals[goalIndex] = goal.copyWith(
        milestones: updatedMilestones,
        progress: newProgress,
        status: newProgress >= 1.0
            ? GoalStatus.achieved
            : newProgress > 0
                ? GoalStatus.in_progress
                : GoalStatus.not_started,
        achievedAt: newProgress >= 1.0 ? DateTime.now() : null,
      );
    }
  }

  @override
  Future<List<VisionSnapshot>> getSnapshots() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_snapshots);
  }

  @override
  Future<VisionBoardStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final achieved = _goals.where((g) => g.status == GoalStatus.achieved).length;
    final inProgress =
        _goals.where((g) => g.status == GoalStatus.in_progress).length;
    return VisionBoardStats(
      totalGoals: _goals.length,
      achievedGoals: achieved,
      inProgressGoals: inProgress,
      achievementRate:
          _goals.isNotEmpty ? achieved / _goals.length : 0.0,
      longestGoalStreak: 14,
      categoryProgress: {
        VisionCategory.mind: 0.65,
        VisionCategory.body: 0.35,
        VisionCategory.social: 0.67,
        VisionCategory.skill: 0.80,
        VisionCategory.life: 0.60,
      },
    );
  }

  @override
  Future<List<VisionQuote>> getQuotes() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_quotes);
  }
}

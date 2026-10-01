import '../models/planner.dart';
import 'planner_gateway.dart';

class MockPlannerGateway implements PlannerGateway {
  final Map<String, DailyPlan> _plans = {};
  final List<PlannerTemplate> _templates = [];
  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _plans[today.toIso8601String()] = DailyPlan(
      id: 'plan_today',
      date: today,
      morningIntention: 'Stay focused and push through resistance. Every rep counts.',
      eveningReflection: null,
      items: [
        PlannerItem(
          id: 'item_1',
          title: 'Morning Ritual',
          description: 'Cold shower, breathwork, and journaling to start the day with intention.',
          emoji: '🧊',
          type: PlannerItemType.ritual,
          priority: PlannerPriority.high,
          timeBlock: TimeBlock.morning,
          scheduledTime: DateTime(today.year, today.month, today.day, 6, 0),
          durationMinutes: 45,
          isCompleted: true,
          lane: ChallengeLane.discipline,
          linkedId: 'ritual_morning_001',
        ),
        PlannerItem(
          id: 'item_2',
          title: 'Strength Training',
          description: 'Upper body push day: bench press, overhead press, dips, and tricep work.',
          emoji: '💪',
          type: PlannerItemType.action,
          priority: PlannerPriority.high,
          timeBlock: TimeBlock.morning,
          scheduledTime: DateTime(today.year, today.month, today.day, 7, 0),
          durationMinutes: 60,
          isCompleted: true,
          lane: ChallengeLane.body,
          linkedId: 'action_workout_003',
        ),
        PlannerItem(
          id: 'item_3',
          title: 'Deep Work Session',
          description: 'Two hours of focused, distraction-free work on the main project.',
          emoji: '🎯',
          type: PlannerItemType.action,
          priority: PlannerPriority.high,
          timeBlock: TimeBlock.morning,
          scheduledTime: DateTime(today.year, today.month, today.day, 9, 0),
          durationMinutes: 120,
          isCompleted: false,
          lane: ChallengeLane.mind,
          linkedId: 'action_deepwork_007',
        ),
        PlannerItem(
          id: 'item_4',
          title: 'Lunch Break',
          description: 'High-protein meal and a short walk outside to reset.',
          emoji: '🥗',
          type: PlannerItemType.breakTime,
          priority: PlannerPriority.medium,
          timeBlock: TimeBlock.afternoon,
          scheduledTime: DateTime(today.year, today.month, today.day, 12, 30),
          durationMinutes: 45,
          isCompleted: false,
        ),
        PlannerItem(
          id: 'item_5',
          title: 'Skill Practice',
          description: 'Practice public speaking — record and review a 5-minute talk.',
          emoji: '🎤',
          type: PlannerItemType.challenge,
          priority: PlannerPriority.medium,
          timeBlock: TimeBlock.afternoon,
          scheduledTime: DateTime(today.year, today.month, today.day, 14, 0),
          durationMinutes: 45,
          isCompleted: false,
          lane: ChallengeLane.mind,
          linkedId: 'challenge_speaking_002',
        ),
        PlannerItem(
          id: 'item_6',
          title: 'Social Connection Call',
          description: 'Call a friend or mentor to maintain meaningful relationships.',
          emoji: '📞',
          type: PlannerItemType.action,
          priority: PlannerPriority.medium,
          timeBlock: TimeBlock.afternoon,
          scheduledTime: DateTime(today.year, today.month, today.day, 16, 0),
          durationMinutes: 30,
          isCompleted: false,
          lane: ChallengeLane.soul,
          linkedId: 'action_social_005',
        ),
        PlannerItem(
          id: 'item_7',
          title: 'Reading Block',
          description: 'Read 30 pages of current book: Meditations by Marcus Aurelius.',
          emoji: '📚',
          type: PlannerItemType.action,
          priority: PlannerPriority.low,
          timeBlock: TimeBlock.evening,
          scheduledTime: DateTime(today.year, today.month, today.day, 19, 0),
          durationMinutes: 40,
          isCompleted: false,
          lane: ChallengeLane.mind,
          linkedId: 'action_reading_010',
        ),
        PlannerItem(
          id: 'item_8',
          title: 'Evening Journal',
          description: 'Reflect on wins, lessons, and gratitude. Plan tomorrow.',
          emoji: '📝',
          type: PlannerItemType.ritual,
          priority: PlannerPriority.high,
          timeBlock: TimeBlock.night,
          scheduledTime: DateTime(today.year, today.month, today.day, 21, 30),
          durationMinutes: 20,
          isCompleted: false,
          lane: ChallengeLane.soul,
          linkedId: 'ritual_journal_001',
        ),
      ],
    );

    _templates.addAll([
      PlannerTemplate(
        id: 'template_warrior',
        name: 'Warrior Day',
        emoji: '⚔️',
        description: 'An intense day built for maximum output and growth. For days when you want to push limits.',
        isDefault: true,
        items: [
          PlannerItem(
            id: 'tw_1',
            title: 'Cold Exposure & Breathwork',
            emoji: '🧊',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.morning,
            durationMinutes: 30,
            lane: ChallengeLane.discipline,
          ),
          PlannerItem(
            id: 'tw_2',
            title: 'Heavy Lifting Session',
            emoji: '🏋️',
            type: PlannerItemType.action,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.morning,
            durationMinutes: 75,
            lane: ChallengeLane.body,
          ),
          PlannerItem(
            id: 'tw_3',
            title: 'Deep Work Sprint 1',
            emoji: '🔥',
            type: PlannerItemType.action,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.morning,
            durationMinutes: 120,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tw_4',
            title: 'Fuel Up',
            emoji: '🥩',
            type: PlannerItemType.breakTime,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 30,
          ),
          PlannerItem(
            id: 'tw_5',
            title: 'Deep Work Sprint 2',
            emoji: '⚡',
            type: PlannerItemType.action,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 120,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tw_6',
            title: 'Challenge Task',
            emoji: '🎯',
            type: PlannerItemType.challenge,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 60,
            lane: ChallengeLane.discipline,
          ),
          PlannerItem(
            id: 'tw_7',
            title: 'Combat Training',
            emoji: '🥊',
            type: PlannerItemType.action,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.evening,
            durationMinutes: 60,
            lane: ChallengeLane.body,
          ),
          PlannerItem(
            id: 'tw_8',
            title: 'War Journal',
            emoji: '📝',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.night,
            durationMinutes: 20,
            lane: ChallengeLane.soul,
          ),
        ],
      ),
      PlannerTemplate(
        id: 'template_balanced',
        name: 'Balanced Day',
        emoji: '⚖️',
        description: 'A well-rounded day that blends productivity, health, and rest. Sustainable and effective.',
        isDefault: false,
        items: [
          PlannerItem(
            id: 'tb_1',
            title: 'Morning Meditation',
            emoji: '🧘',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.morning,
            durationMinutes: 20,
            lane: ChallengeLane.soul,
          ),
          PlannerItem(
            id: 'tb_2',
            title: 'Movement Session',
            emoji: '🏃',
            type: PlannerItemType.action,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.morning,
            durationMinutes: 45,
            lane: ChallengeLane.body,
          ),
          PlannerItem(
            id: 'tb_3',
            title: 'Focused Work',
            emoji: '💻',
            type: PlannerItemType.action,
            priority: PlannerPriority.high,
            timeBlock: TimeBlock.morning,
            durationMinutes: 90,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tb_4',
            title: 'Mindful Lunch',
            emoji: '🥗',
            type: PlannerItemType.breakTime,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 45,
          ),
          PlannerItem(
            id: 'tb_5',
            title: 'Creative Work',
            emoji: '🎨',
            type: PlannerItemType.action,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 60,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tb_6',
            title: 'Social Time',
            emoji: '👥',
            type: PlannerItemType.action,
            priority: PlannerPriority.low,
            timeBlock: TimeBlock.evening,
            durationMinutes: 60,
            lane: ChallengeLane.soul,
          ),
          PlannerItem(
            id: 'tb_7',
            title: 'Evening Reading',
            emoji: '📖',
            type: PlannerItemType.action,
            priority: PlannerPriority.low,
            timeBlock: TimeBlock.evening,
            durationMinutes: 30,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tb_8',
            title: 'Gratitude Journal',
            emoji: '🙏',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.night,
            durationMinutes: 15,
            lane: ChallengeLane.soul,
          ),
        ],
      ),
      PlannerTemplate(
        id: 'template_recovery',
        name: 'Recovery Day',
        emoji: '🌿',
        description: 'A lighter day focused on rest, reflection, and gentle movement. Recharge to come back stronger.',
        isDefault: false,
        items: [
          PlannerItem(
            id: 'tr_1',
            title: 'Gentle Stretching',
            emoji: '🧘',
            type: PlannerItemType.action,
            priority: PlannerPriority.low,
            timeBlock: TimeBlock.morning,
            durationMinutes: 20,
            lane: ChallengeLane.body,
          ),
          PlannerItem(
            id: 'tr_2',
            title: 'Journaling & Reflection',
            emoji: '📓',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.morning,
            durationMinutes: 30,
            lane: ChallengeLane.soul,
          ),
          PlannerItem(
            id: 'tr_3',
            title: 'Nature Walk',
            emoji: '🌳',
            type: PlannerItemType.action,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.morning,
            durationMinutes: 45,
            lane: ChallengeLane.body,
          ),
          PlannerItem(
            id: 'tr_4',
            title: 'Nourishing Meal',
            emoji: '🍲',
            type: PlannerItemType.breakTime,
            priority: PlannerPriority.medium,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 45,
          ),
          PlannerItem(
            id: 'tr_5',
            title: 'Light Reading',
            emoji: '📚',
            type: PlannerItemType.action,
            priority: PlannerPriority.low,
            timeBlock: TimeBlock.afternoon,
            durationMinutes: 45,
            lane: ChallengeLane.mind,
          ),
          PlannerItem(
            id: 'tr_6',
            title: 'Evening Breathwork',
            emoji: '🌬️',
            type: PlannerItemType.ritual,
            priority: PlannerPriority.low,
            timeBlock: TimeBlock.evening,
            durationMinutes: 15,
            lane: ChallengeLane.soul,
          ),
        ],
      ),
    ]);
  }

  @override
  Future<DailyPlan> getTodayPlan() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureInitialized();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _plans[today.toIso8601String()] ??
        DailyPlan(
          id: 'plan_${today.millisecondsSinceEpoch}',
          date: today,
          morningIntention: '',
        );
  }

  @override
  Future<DailyPlan> getPlanForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 180));
    _ensureInitialized();
    final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();
    return _plans[dateKey] ??
        DailyPlan(
          id: 'plan_${date.millisecondsSinceEpoch}',
          date: DateTime(date.year, date.month, date.day),
          morningIntention: '',
        );
  }

  @override
  Future<void> savePlan(DailyPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _ensureInitialized();
    final dateKey = DateTime(plan.date.year, plan.date.month, plan.date.day)
        .toIso8601String();
    _plans[dateKey] = plan;
  }

  @override
  Future<List<PlannerTemplate>> getTemplates() async {
    await Future.delayed(const Duration(milliseconds: 170));
    _ensureInitialized();
    return List.unmodifiable(_templates);
  }

  @override
  Future<void> saveTemplate(PlannerTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 160));
    _ensureInitialized();
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      _templates[index] = template;
    } else {
      _templates.add(template);
    }
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _ensureInitialized();
    _templates.removeWhere((t) => t.id == templateId);
  }

  @override
  Future<PlannerStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureInitialized();
    return const PlannerStats(
      averageCompletionRate: 0.78,
      totalPlannedDays: 45,
      currentPlanStreak: 12,
      bestPlanStreak: 18,
      mostProductiveBlock: TimeBlock.morning,
      averageItemsPerDay: 7.2,
    );
  }

  @override
  Future<List<PlannerItem>> getSuggestedItems() async {
    await Future.delayed(const Duration(milliseconds: 220));
    _ensureInitialized();
    return [
      const PlannerItem(
        id: 'suggest_1',
        title: 'Meditation Session',
        description: 'Guided 15-minute meditation for mental clarity and calm.',
        emoji: '🧘',
        type: PlannerItemType.ritual,
        priority: PlannerPriority.medium,
        timeBlock: TimeBlock.morning,
        durationMinutes: 15,
        lane: ChallengeLane.soul,
        linkedId: 'ritual_meditate_002',
      ),
      const PlannerItem(
        id: 'suggest_2',
        title: 'Cold Approach Practice',
        description: 'Start 3 conversations with strangers to build social confidence.',
        emoji: '🗣️',
        type: PlannerItemType.challenge,
        priority: PlannerPriority.high,
        timeBlock: TimeBlock.afternoon,
        durationMinutes: 30,
        lane: ChallengeLane.discipline,
        linkedId: 'challenge_social_004',
      ),
      const PlannerItem(
        id: 'suggest_3',
        title: 'Meal Prep',
        description: 'Prepare clean meals for the next two days. Fuel the machine.',
        emoji: '🍳',
        type: PlannerItemType.action,
        priority: PlannerPriority.medium,
        timeBlock: TimeBlock.evening,
        durationMinutes: 60,
        lane: ChallengeLane.body,
        linkedId: 'action_mealprep_006',
      ),
      const PlannerItem(
        id: 'suggest_4',
        title: 'Mobility Routine',
        description: 'Full-body mobility flow targeting hips, shoulders, and spine.',
        emoji: '🤸',
        type: PlannerItemType.action,
        priority: PlannerPriority.low,
        timeBlock: TimeBlock.evening,
        durationMinutes: 20,
        lane: ChallengeLane.body,
        linkedId: 'action_mobility_008',
      ),
      const PlannerItem(
        id: 'suggest_5',
        title: 'Financial Review',
        description: 'Track spending, review budgets, and set financial goals for the week.',
        emoji: '💰',
        type: PlannerItemType.action,
        priority: PlannerPriority.medium,
        timeBlock: TimeBlock.afternoon,
        durationMinutes: 30,
        lane: ChallengeLane.mind,
        linkedId: 'action_finance_012',
      ),
    ];
  }
}

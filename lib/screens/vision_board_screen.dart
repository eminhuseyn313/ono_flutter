import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vision_board.dart';
import '../providers/vision_board_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_progress_chart.dart';
import '../widgets/vision_goal_card.dart';

class VisionBoardScreen extends StatefulWidget {
  const VisionBoardScreen({super.key});

  @override
  State<VisionBoardScreen> createState() => _VisionBoardScreenState();
}

class _VisionBoardScreenState extends State<VisionBoardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentQuoteIndex = 0;
  late PageController _quotePageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quotePageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisionBoardProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quotePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<VisionBoardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.purple,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildHeroSection(provider)),
              SliverToBoxAdapter(child: _buildQuoteRotator(provider)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGoalsTab(provider),
                    _buildSnapshotsTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      pinned: false,
      elevation: 0,
      title: const Row(
        children: [
          Text(
            '🎯',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(width: 10),
          Text(
            'Vision Board',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.read<VisionBoardProvider>().loadAll();
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(VisionBoardProvider provider) {
    final stats = provider.stats;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark.withValues(alpha: 0.6),
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                value: '${stats.achievedGoals}/${stats.totalGoals}',
                label: 'Goals Achieved',
                color: AppColors.green,
              ),
              _buildStatDivider(),
              _buildStatItem(
                value: '${stats.inProgressGoals}',
                label: 'In Progress',
                color: AppColors.cyan,
              ),
              _buildStatDivider(),
              _buildStatItem(
                value: '${stats.longestGoalStreak}',
                label: 'Day Streak',
                color: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.achievementRate,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(stats.achievementRate * 100).round()}% overall completion',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }

  Widget _buildQuoteRotator(VisionBoardProvider provider) {
    if (provider.quotes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 80,
      child: PageView.builder(
        controller: _quotePageController,
        itemCount: provider.quotes.length,
        onPageChanged: (index) {
          setState(() {
            _currentQuoteIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final quote = provider.quotes[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${quote.text}"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    color: Color(quote.category.colorValue),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.grey,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Goals'),
          Tab(text: 'Snapshots'),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(VisionBoardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildCategoryFilters(provider),
        const SizedBox(height: 12),
        Expanded(
          child: provider.goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: provider.goals.length,
                  itemBuilder: (context, index) {
                    final goal = provider.goals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VisionGoalCard(
                        goal: goal,
                        onToggleMilestone: (milestoneId, isCompleted) {
                          provider.toggleMilestone(
                            goal.id,
                            milestoneId,
                            isCompleted,
                          );
                        },
                        onEdit: () => _showEditGoalSheet(goal),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(VisionBoardProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: provider.selectedCategory == null,
            color: AppColors.purple,
            onTap: () => provider.setSelectedCategory(null),
          ),
          const SizedBox(width: 8),
          ...VisionCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: '${category.emoji} ${category.label}',
                isSelected: provider.selectedCategory == category,
                color: Color(category.colorValue),
                onTap: () => provider.setSelectedCategory(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎯',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'No goals yet',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first vision goal',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotsTab(VisionBoardProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          if (provider.stats.categoryProgress.isNotEmpty)
            CategoryProgressChart(
              categoryProgress: provider.stats.categoryProgress,
            ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Progress Timeline',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...provider.snapshots.map(
            (snapshot) => _buildSnapshotCard(snapshot),
          ),
          if (provider.snapshots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No snapshots recorded yet',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard(VisionSnapshot snapshot) {
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateLabel =
        '${monthNames[snapshot.date.month]} ${snapshot.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${snapshot.goalsAchieved}/${snapshot.goalsTotal} achieved',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: snapshot.categoryBreakdown.entries.map((entry) {
              final percentage = (entry.value * 100).round();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      Color(entry.key.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.key.emoji} $percentage%',
                  style: TextStyle(
                    color: Color(entry.key.colorValue),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          if (snapshot.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              snapshot.notes,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showNewGoalSheet,
      backgroundColor: AppColors.purple,
      child: const Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showNewGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewGoalBottomSheet(),
    );
  }

  void _showEditGoalSheet(VisionGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewGoalBottomSheet(existingGoal: goal),
    );
  }
}

class _NewGoalBottomSheet extends StatefulWidget {
  final VisionGoal? existingGoal;

  const _NewGoalBottomSheet({this.existingGoal});

  @override
  State<_NewGoalBottomSheet> createState() => _NewGoalBottomSheetState();
}

class _NewGoalBottomSheetState extends State<_NewGoalBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _affirmationController;
  late TextEditingController _milestoneController;

  VisionCategory _selectedCategory = VisionCategory.mind;
  GoalTimeframe _selectedTimeframe = GoalTimeframe.month;
  String _selectedEmoji = '🎯';
  final List<String> _milestones = [];

  bool get _isEditing => widget.existingGoal != null;

  final List<String> _emojiOptions = [
    '🎯', '📚', '🏃', '💻', '🚀', '🧘', '💰', '🎤',
    '🏋️', '🎨', '📝', '🌟', '🔥', '💎', '🧠', '⚡',
  ];

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: goal?.description ?? '');
    _affirmationController =
        TextEditingController(text: goal?.affirmation ?? '');
    _milestoneController = TextEditingController();

    if (goal != null) {
      _selectedCategory = goal.category;
      _selectedTimeframe = goal.timeframe;
      _selectedEmoji = goal.emoji;
      _milestones.addAll(goal.milestones.map((m) => m.title));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _affirmationController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    final text = _milestoneController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _milestones.add(text);
        _milestoneController.clear();
      });
    }
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _saveGoal() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final provider = context.read<VisionBoardProvider>();
    final now = DateTime.now();

    final milestoneObjects = _milestones.asMap().entries.map((entry) {
      return Milestone(
        id: 'ms_${now.millisecondsSinceEpoch}_${entry.key}',
        title: entry.value,
        order: entry.key + 1,
      );
    }).toList();

    final goal = VisionGoal(
      id: widget.existingGoal?.id ??
          'goal_${now.millisecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim(),
      emoji: _selectedEmoji,
      category: _selectedCategory,
      status: widget.existingGoal?.status ?? GoalStatus.not_started,
      timeframe: _selectedTimeframe,
      progress: widget.existingGoal?.progress ?? 0.0,
      milestones: _isEditing
          ? widget.existingGoal!.milestones
          : milestoneObjects,
      createdAt: widget.existingGoal?.createdAt ?? now,
      affirmation: _affirmationController.text.trim(),
    );

    if (_isEditing) {
      provider.updateGoal(goal);
    } else {
      provider.addGoal(goal);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit Goal' : 'New Vision Goal',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('Choose an emoji'),
            const SizedBox(height: 8),
            _buildEmojiPicker(),
            const SizedBox(height: 16),
            _buildSectionLabel('Title'),
            const SizedBox(height: 8),
            _buildTextField(_titleController, 'What do you want to achieve?'),
            const SizedBox(height: 16),
            _buildSectionLabel('Description'),
            const SizedBox(height: 8),
            _buildTextField(
              _descriptionController,
              'Describe your goal in detail...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Category'),
            const SizedBox(height: 8),
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildSectionLabel('Timeframe'),
            const SizedBox(height: 8),
            _buildTimeframePicker(),
            const SizedBox(height: 16),
            _buildSectionLabel('Affirmation'),
            const SizedBox(height: 8),
            _buildTextField(
              _affirmationController,
              'Write a motivational statement...',
              maxLines: 2,
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              _buildSectionLabel('Milestones'),
              const SizedBox(height: 8),
              _buildMilestoneInput(),
              const SizedBox(height: 8),
              _buildMilestoneList(),
            ],
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.grey,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.grey.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.purple.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _emojiOptions.map((emoji) {
        final isSelected = _selectedEmoji == emoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmoji = emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.purple
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VisionCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        final color = Color(category.colorValue);

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.grey,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeframePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GoalTimeframe.values.map((timeframe) {
        final isSelected = _selectedTimeframe == timeframe;

        return GestureDetector(
          onTap: () => setState(() => _selectedTimeframe = timeframe),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.purple.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              timeframe.label,
              style: TextStyle(
                color: isSelected ? AppColors.purple : AppColors.grey,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMilestoneInput() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            _milestoneController,
            'Add a milestone...',
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addMilestone,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.purple,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneList() {
    if (_milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _milestones.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeMilestone(entry.key),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          _isEditing ? 'Save Changes' : 'Create Goal',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

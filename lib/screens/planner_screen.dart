import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planner.dart';
import '../providers/planner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/plan_completion_ring.dart';
import '../widgets/planner_timeline_item.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late ScrollController _scrollController;
  late PageController _weekController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _weekController = PageController(initialPage: 500);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlannerProvider>();
      provider.loadTodayPlan();
      provider.loadTemplates();
      provider.loadStats();
      provider.loadSuggestedItems();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PlannerProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(provider),
              SliverToBoxAdapter(child: _buildDateSelector(provider)),
              SliverToBoxAdapter(child: _buildHeroSection(provider)),
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.purple,
                    ),
                  ),
                )
              else ...[
                ..._buildTimelineBlocks(provider),
                SliverToBoxAdapter(child: _buildStatsSection(provider)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(PlannerProvider provider) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      title: const Text(
        'Daily Planner',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showTemplatesSheet(provider),
          icon: const Icon(
            Icons.dashboard_customize_outlined,
            color: AppColors.grey,
          ),
          tooltip: 'Templates',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDateSelector(PlannerProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = provider.selectedDate;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: 3 - index));
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return GestureDetector(
            onTap: () => provider.loadPlanForDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.purple : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.purple.withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildHeroSection(PlannerProvider provider) {
    final plan = provider.currentPlan;
    if (plan == null) return const SizedBox.shrink();

    final blockCompletions = <TimeBlock, double>{};
    for (final block in TimeBlock.values) {
      final blockItems = plan.itemsForBlock(block);
      if (blockItems.isEmpty) {
        blockCompletions[block] = 0.0;
      } else {
        final completed = blockItems.where((i) => i.isCompleted).length;
        blockCompletions[block] = completed / blockItems.length;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          PlanCompletionRing(
            completionRate: provider.completionRate,
            completedCount: provider.completedCount,
            totalCount: provider.totalCount,
            blockCompletions: blockCompletions,
            size: 120,
          ),
          const SizedBox(height: 16),
          if (plan.morningIntention.isNotEmpty)
            GestureDetector(
              onTap: () => _showIntentionEditor(provider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        plan.morningIntention,
                        style: TextStyle(
                          color: AppColors.purpleSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.purple.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _showIntentionEditor(provider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: AppColors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Set your morning intention',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineBlocks(PlannerProvider provider) {
    final slivers = <Widget>[];
    for (final block in TimeBlock.values) {
      final items = provider.itemsForBlock(block);
      slivers.add(
        SliverToBoxAdapter(
          child: _buildBlockHeader(block, items.length),
        ),
      );
      if (items.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: _buildEmptyBlock(block),
          ),
        );
      } else {
        slivers.add(
          SliverToBoxAdapter(
            child: _buildReorderableBlock(provider, block, items),
          ),
        );
      }
    }
    return slivers;
  }

  Widget _buildBlockHeader(TimeBlock block, int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(block.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            block.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            block.timeRange,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$itemCount',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBlock(TimeBlock block) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            'No items scheduled',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableBlock(
    PlannerProvider provider,
    TimeBlock block,
    List<PlannerItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final elevation = Tween<double>(begin: 0, end: 8)
                  .animate(animation)
                  .value;
              return Material(
                color: Colors.transparent,
                elevation: elevation,
                shadowColor: AppColors.purple.withValues(alpha: 0.3),
                child: child,
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderItems(block, oldIndex, newIndex);
        },
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return PlannerTimelineItem(
            key: ValueKey(item.id),
            item: item,
            isFirst: index == 0,
            isLast: index == items.length - 1,
            onToggleComplete: () => provider.toggleItemComplete(item.id),
            onDelete: () => provider.removeItem(item.id),
            onTap: () => _showItemDetail(item),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(PlannerProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.divider, height: 32),
          const Text(
            'Your Planning Stats',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                '🔥',
                '${stats.currentPlanStreak}',
                'Day Streak',
                AppColors.purple,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                '🏆',
                '${stats.bestPlanStreak}',
                'Best Streak',
                const Color(0xFFE2B354),
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                '📊',
                stats.formattedCompletionRate,
                'Avg Complete',
                const Color(0xFF7DB495),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                '📅',
                '${stats.totalPlannedDays}',
                'Days Planned',
                const Color(0xFF7C9CC4),
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                '📋',
                stats.formattedAverageItems,
                'Avg Items',
                AppColors.purpleSoft,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                stats.mostProductiveBlock.emoji,
                stats.mostProductiveBlock.label,
                'Peak Block',
                AppColors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    String value,
    String label,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddItemSheet,
      backgroundColor: AppColors.purple,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  void _showAddItemSheet() {
    final provider = context.read<PlannerProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddItemSheet(
        suggestedItems: provider.suggestedItems,
        onAddCustom: (item) {
          provider.addItem(item);
          Navigator.pop(context);
        },
        onAddSuggested: (item) {
          final newItem = item.copyWith(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          );
          provider.addItem(newItem);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTemplatesSheet(PlannerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplatesSheet(
        templates: provider.templates,
        isLoading: provider.isLoadingTemplates,
        onApply: (templateId) {
          provider.applyTemplate(templateId);
          Navigator.pop(context);
        },
        onSaveCurrentAsTemplate: () {
          Navigator.pop(context);
          _showSaveTemplateDialog(provider);
        },
      ),
    );
  }

  void _showSaveTemplateDialog(PlannerProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '📋';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Save as Template',
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Template name',
                hintStyle: TextStyle(color: AppColors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.purple),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: TextStyle(color: AppColors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.purple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.saveAsTemplate(
                  nameController.text,
                  selectedEmoji,
                  descController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }

  void _showIntentionEditor(PlannerProvider provider) {
    final controller = TextEditingController(
      text: provider.currentPlan?.morningIntention ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Morning Intention',
          style: TextStyle(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.white),
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'What is your focus for today?',
            hintStyle: TextStyle(color: AppColors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.purple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.updateMorningIntention(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.purple)),
          ),
        ],
      ),
    );
  }

  void _showItemDetail(PlannerItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item.type.label,
                            style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.formattedDuration,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                          if (item.formattedTime.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.formattedTime,
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                item.description,
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (item.lane != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(item.lane!.colorValue).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.lane!.label} Lane',
                      style: TextStyle(
                        color: Color(item.lane!.colorValue),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final List<PlannerItem> suggestedItems;
  final ValueChanged<PlannerItem> onAddCustom;
  final ValueChanged<PlannerItem> onAddSuggested;

  const _AddItemSheet({
    required this.suggestedItems,
    required this.onAddCustom,
    required this.onAddSuggested,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  bool _showCustomForm = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedEmoji = '📋';
  PlannerPriority _selectedPriority = PlannerPriority.medium;
  TimeBlock _selectedBlock = TimeBlock.morning;
  int _durationMinutes = 30;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Add Item',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!_showCustomForm)
                  TextButton.icon(
                    onPressed: () => setState(() => _showCustomForm = true),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Custom'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.purple,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _showCustomForm
                  ? _buildCustomForm()
                  : _buildSuggestionsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (widget.suggestedItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No suggestions available',
            style: TextStyle(color: AppColors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested for you',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.suggestedItems.map((item) => _buildSuggestionTile(item)),
      ],
    );
  }

  Widget _buildSuggestionTile(PlannerItem item) {
    return GestureDetector(
      onTap: () => widget.onAddSuggested(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.timeBlock.label} - ${item.formattedDuration}',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.purple,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          style: const TextStyle(color: AppColors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Item title',
            hintStyle: TextStyle(color: AppColors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.purple),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          style: const TextStyle(color: AppColors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Description (optional)',
            hintStyle: TextStyle(color: AppColors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.purple),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Time Block',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TimeBlock.values.map((block) {
            final isSelected = _selectedBlock == block;
            return ChoiceChip(
              label: Text('${block.emoji} ${block.label}'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedBlock = block),
              backgroundColor: AppColors.cardLight,
              selectedColor: AppColors.purple.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.purple : AppColors.grey,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.purple : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.purple,
                                surface: AppColors.card,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime?.format(context) ?? 'Pick time',
                            style: TextStyle(
                              color: _selectedTime != null
                                  ? AppColors.white
                                  : AppColors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _durationMinutes,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                        isExpanded: true,
                        items: [15, 20, 30, 45, 60, 90, 120]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 > 0 ? " ${m % 60}m" : ""}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _durationMinutes = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Priority',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PlannerPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final color = switch (priority) {
              PlannerPriority.high => const Color(0xFFE0605A),
              PlannerPriority.medium => const Color(0xFFE2B354),
              PlannerPriority.low => const Color(0xFF7DB495),
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(priority.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedPriority = priority),
                backgroundColor: AppColors.cardLight,
                selectedColor: color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? color : AppColors.grey,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? color : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _titleController.text.isNotEmpty ? _submitCustomItem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add to Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submitCustomItem() {
    if (_titleController.text.isEmpty) return;

    DateTime? scheduledTime;
    if (_selectedTime != null) {
      final now = DateTime.now();
      scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    final item = PlannerItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      description: _descController.text,
      emoji: _selectedEmoji,
      type: PlannerItemType.custom,
      priority: _selectedPriority,
      timeBlock: _selectedBlock,
      scheduledTime: scheduledTime,
      durationMinutes: _durationMinutes,
    );

    widget.onAddCustom(item);
  }
}

class _TemplatesSheet extends StatelessWidget {
  final List<PlannerTemplate> templates;
  final bool isLoading;
  final ValueChanged<String> onApply;
  final VoidCallback onSaveCurrentAsTemplate;

  const _TemplatesSheet({
    required this.templates,
    required this.isLoading,
    required this.onApply,
    required this.onSaveCurrentAsTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Templates',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onSaveCurrentAsTemplate,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Current'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _buildTemplateTile(template);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(PlannerTemplate template) {
    return GestureDetector(
      onTap: () => onApply(template.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (template.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${template.items.length} items',
                    style: TextStyle(
                      color: AppColors.grey.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

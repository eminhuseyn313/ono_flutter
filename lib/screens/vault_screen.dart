import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vault_entry_card.dart';
import '../widgets/vault_insight_card.dart';
import '../widgets/mood_timeline.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaultProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _moodEmoji(double avgMood) {
    if (avgMood >= 4.5) return '🔥';
    if (avgMood >= 3.5) return '💪';
    if (avgMood >= 2.5) return '😐';
    if (avgMood >= 1.5) return '😴';
    return '😤';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.entries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.purple,
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: AppColors.background,
                floating: true,
                pinned: true,
                expandedHeight: 60,
                title: const Row(
                  children: [
                    Text(
                      '🗄️',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'The Vault',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (provider.hasActiveFilters)
                    IconButton(
                      onPressed: () {
                        provider.clearFilters();
                        _searchController.clear();
                      },
                      icon: const Icon(
                        Icons.filter_alt_off_rounded,
                        color: AppColors.cyan,
                        size: 22,
                      ),
                    ),
                ],
              ),

              // Stats hero
              if (provider.stats != null)
                SliverToBoxAdapter(
                  child: _buildStatsHero(provider.stats!),
                ),

              // Mood timeline
              if (provider.moodTimeline.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MoodTimeline(dataPoints: provider.moodTimeline),
                  ),
                ),

              // Search bar
              SliverToBoxAdapter(
                child: _buildSearchBar(provider),
              ),

              // Filter chips
              if (provider.hasActiveFilters)
                SliverToBoxAdapter(
                  child: _buildActiveFilters(provider),
                ),

              // Tab bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.purple,
                    unselectedLabelColor: AppColors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        text: 'All Entries (${provider.filteredEntries.length})',
                      ),
                      Tab(
                        text: 'Insights (${provider.insights.length})',
                      ),
                      Tab(
                        text: 'Patterns (${provider.patterns.length})',
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // Tab content
              if (_tabController.index == 0)
                _buildEntriesTab(provider)
              else if (_tabController.index == 1)
                _buildInsightsTab(provider)
              else
                _buildPatternsTab(provider),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new entry
        },
        backgroundColor: AppColors.purple,
        child: const Icon(
          Icons.edit_rounded,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildStatsHero(VaultStats stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purpleSoft.withValues(alpha: 0.15),
              AppColors.purple.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildStatItem(
              '${stats.totalEntries}',
              'Entries',
              Icons.book_rounded,
              AppColors.purple,
            ),
            _buildStatDivider(),
            _buildStatItem(
              '${stats.currentWritingStreak}',
              'Day Streak',
              Icons.local_fire_department_rounded,
              const Color(0xFFE0605A),
            ),
            _buildStatDivider(),
            _buildStatItem(
              _formatWordCount(stats.totalWords),
              'Words',
              Icons.text_fields_rounded,
              AppColors.cyan,
            ),
            _buildStatDivider(),
            _buildStatItem(
              _moodEmoji(stats.averageMood),
              'Avg Mood',
              null,
              AppColors.green,
              isEmoji: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData? icon,
    Color color, {
    bool isEmoji = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          if (isEmoji)
            Text(
              value,
              style: const TextStyle(fontSize: 24),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider,
    );
  }

  Widget _buildSearchBar(VaultProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => provider.setSearchQuery(value),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search entries...',
                hintStyle: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  provider.isSearching
                      ? Icons.hourglass_top_rounded
                      : Icons.search_rounded,
                  color: AppColors.grey.withValues(alpha: 0.5),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.grey.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips row
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Mood filter
                _buildFilterDropdown<VaultMood>(
                  label: 'Mood',
                  icon: Icons.emoji_emotions_rounded,
                  selectedValue: provider.selectedMood,
                  items: VaultMood.values,
                  itemLabel: (m) => '${m.emoji} ${m.label}',
                  onSelected: (m) => provider.setMoodFilter(m),
                ),
                const SizedBox(width: 8),
                // Tag filter
                _buildFilterDropdown<VaultTag>(
                  label: 'Tag',
                  icon: Icons.tag_rounded,
                  selectedValue: provider.selectedTag,
                  items: VaultTag.values,
                  itemLabel: (t) => '${t.emoji} ${t.label}',
                  onSelected: (t) => provider.setTagFilter(t),
                ),
                const SizedBox(width: 8),
                // Lane filter
                _buildFilterDropdown<String>(
                  label: 'Lane',
                  icon: Icons.route_rounded,
                  selectedValue: provider.selectedLane,
                  items: const ['Mind', 'Body', 'Social', 'Skill'],
                  itemLabel: (l) => l,
                  onSelected: (l) => provider.setLaneFilter(l),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required IconData icon,
    required T? selectedValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onSelected,
  }) {
    final isActive = selectedValue != null;
    return PopupMenuButton<T?>(
      onSelected: (value) => onSelected(value),
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<T?>(
            value: null,
            child: Text(
              'All $label',
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ),
          ...items.map((item) {
            return PopupMenuItem<T?>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(
                  color: item == selectedValue
                      ? AppColors.purple
                      : AppColors.white,
                  fontSize: 13,
                  fontWeight: item == selectedValue
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.purple.withValues(alpha: 0.4)
                : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.purple : AppColors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              selectedValue != null ? itemLabel(selectedValue) : label,
              style: TextStyle(
                color: isActive ? AppColors.purple : AppColors.grey,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? AppColors.purple : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(VaultProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 14,
            color: AppColors.grey.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            '${provider.filteredEntries.length} entries matching filters',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              provider.clearFilters();
              _searchController.clear();
            },
            child: const Text(
              'Clear all',
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildEntriesTab(VaultProvider provider) {
    final entries = provider.filteredEntries;

    if (entries.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.book_outlined,
            title: 'No entries found',
            subtitle: provider.hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Start journaling to fill your vault',
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VaultEntryCard(
              entry: entry,
              onTap: () {
                // Open entry detail
              },
              onBookmarkTap: () => provider.toggleBookmark(entry.id),
              onFavoriteTap: () => provider.toggleFavorite(entry.id),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }

  SliverList _buildInsightsTab(VaultProvider provider) {
    final insights = provider.insights;

    if (insights.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'No insights yet',
            subtitle: 'Keep journaling and AI insights will appear',
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final insight = insights[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VaultInsightCard(
              insight: insight,
              onViewRelated: () {
                // Navigate to related entries
              },
            ),
          );
        },
        childCount: insights.length,
      ),
    );
  }

  SliverList _buildPatternsTab(VaultProvider provider) {
    final patterns = provider.patterns;

    if (patterns.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildEmptyState(
            icon: Icons.insights_outlined,
            title: 'No patterns detected',
            subtitle: 'Growth patterns emerge over time',
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final pattern = patterns[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPatternCard(pattern),
          );
        },
        childCount: patterns.length,
      ),
    );
  }

  Widget _buildPatternCard(GrowthPattern pattern) {
    final correlationPercent = (pattern.moodCorrelation * 100).round();
    final Color correlationColor;
    if (pattern.moodCorrelation >= 0.7) {
      correlationColor = AppColors.green;
    } else if (pattern.moodCorrelation >= 0.4) {
      correlationColor = AppColors.warning;
    } else {
      correlationColor = AppColors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.insights_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.patternName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (pattern.lane != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pattern.lane!,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Description
          Text(
            pattern.description,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          // Stats row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Frequency
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${pattern.frequency}x',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Frequency',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.divider,
                ),
                // Mood correlation
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: correlationColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$correlationPercent%',
                            style: TextStyle(
                              color: correlationColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mood Match',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.divider,
                ),
                // Duration
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${pattern.lastSeen.difference(pattern.firstSeen).inDays}d',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tracked',
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

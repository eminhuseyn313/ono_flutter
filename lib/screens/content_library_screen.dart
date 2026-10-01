import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/content_library.dart';
import '../providers/content_library_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/content_player_sheet.dart';

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentLibraryProvider>().loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search content...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (q) =>
                    context.read<ContentLibraryProvider>().search(q),
              )
            : Text(
                'Content Library',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: AppColors.grey,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<ContentLibraryProvider>().search('');
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<ContentLibraryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.libraryData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.libraryData == null) {
            return Center(
              child: Text(
                'No content available',
                style: GoogleFonts.plusJakartaSans(color: AppColors.grey),
              ),
            );
          }

          final data = provider.libraryData!;

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: () => provider.loadLibrary(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  _buildStatsRow(data),

                  const SizedBox(height: 16),

                  // Lane filter chips
                  _buildLaneFilters(provider),

                  const SizedBox(height: 12),

                  // Type filter chips
                  _buildTypeFilters(provider),

                  const SizedBox(height: 20),

                  // Recommended section (only when no search/filter)
                  if (provider.searchQuery.isEmpty &&
                      provider.selectedLane == 'All' &&
                      provider.selectedType == null &&
                      data.recommended.isNotEmpty) ...[
                    Text(
                      'Recommended for You',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.recommended.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = data.recommended[index];
                          return SizedBox(
                            width: 260,
                            child: _buildRecommendedCard(item, provider),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.searchQuery.isNotEmpty
                            ? 'Search Results'
                            : 'All Content',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${provider.filteredItems.length} items',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...provider.filteredItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ContentCard(
                          item: item,
                          onTap: () => ContentPlayerSheet.show(
                            context,
                            item,
                            onBookmark: () => provider.toggleBookmark(item.id),
                            onMarkComplete: () =>
                                provider.markCompleted(item.id),
                          ),
                          onBookmark: () => provider.toggleBookmark(item.id),
                        ),
                      )),

                  if (provider.filteredItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              color: AppColors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'No content found',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Try adjusting your filters or search.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(ContentLibraryData data) {
    return Row(
      children: [
        _buildStatCard(
          '${data.totalItems}',
          'Total',
          AppColors.purple,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          '${data.completedItems}',
          'Done',
          AppColors.green,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          '${data.bookmarkedCount}',
          'Saved',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaneFilters(ContentLibraryProvider provider) {
    final lanes = ['All', 'Mind', 'Body', 'Social', 'Skill'];
    final laneColors = {
      'All': AppColors.purple,
      'Mind': AppColors.purple,
      'Body': AppColors.cyan,
      'Social': AppColors.green,
      'Skill': AppColors.warning,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: lanes.map((lane) {
          final isSelected = provider.selectedLane == lane;
          final color = laneColors[lane] ?? AppColors.purple;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.setLaneFilter(lane),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : AppColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.4)
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  lane,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? color : AppColors.grey,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeFilters(ContentLibraryProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeChip(null, 'All Types', provider),
          ...ContentType.values
              .map((t) => _buildTypeChip(t, t.label, provider)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
      ContentType? type, String label, ContentLibraryProvider provider) {
    final isSelected = provider.selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => provider.setTypeFilter(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.purple.withValues(alpha: 0.15)
                : AppColors.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.3)
                  : AppColors.divider.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type != null) ...[
                Icon(
                  IconData(type.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: isSelected ? AppColors.purple : AppColors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? AppColors.purple : AppColors.grey,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(ContentItem item, ContentLibraryProvider provider) {
    final laneColor = Color(item.laneColorValue);
    return GestureDetector(
      onTap: () => ContentPlayerSheet.show(
        context,
        item,
        onBookmark: () => provider.toggleBookmark(item.id),
        onMarkComplete: () => provider.markCompleted(item.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              laneColor.withValues(alpha: 0.15),
              AppColors.card.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: laneColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconData(item.type.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: laneColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.lane,
                    style: GoogleFonts.plusJakartaSans(
                      color: laneColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.durationMinutes}m',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.author,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              item.description,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.greyLight,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

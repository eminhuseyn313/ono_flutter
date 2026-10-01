import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/radio.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/equalizer_animation.dart';
import '../widgets/radio_item_card.dart';

class RadioScreen extends StatefulWidget {
  final String? roleModelId;

  const RadioScreen({super.key, this.roleModelId});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedRoleModelId;

  static const _tabs = [
    RadioChannel.theirWords,
    RadioChannel.soundtrack,
    RadioChannel.library,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedRoleModelId = widget.roleModelId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<RadioProvider>();
      if (widget.roleModelId != null) {
        provider.loadPlaylist(widget.roleModelId!);
      } else {
        provider.loadAllPlaylists();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<RadioProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.playlists.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverAppBar(
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Role Model Radio',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('📻', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const EqualizerAnimation(
                      barCount: 4,
                      width: 28,
                      height: 18,
                    ),
                  ],
                ),
                centerTitle: true,
                floating: true,
                pinned: true,
                bottom: widget.roleModelId != null || _selectedRoleModelId != null
                    ? TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.purple,
                        labelColor: AppColors.white,
                        unselectedLabelColor: AppColors.grey,
                        tabs: const [
                          Tab(text: 'Words'),
                          Tab(text: 'Soundtrack'),
                          Tab(text: 'Library'),
                        ],
                      )
                    : null,
              ),

              // ── Role model selector (if showing all) ──
              if (widget.roleModelId == null)
                SliverToBoxAdapter(
                  child: _buildRoleModelSelector(provider),
                ),

              // ── Featured section ──
              if (_selectedRoleModelId == null &&
                  provider.featuredItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(provider),
                ),

              // ── Content ──
              if (_selectedRoleModelId != null)
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((channel) {
                      return _buildChannelList(
                        provider,
                        _selectedRoleModelId!,
                        channel,
                      );
                    }).toList(),
                  ),
                )
              else if (provider.playlists.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildAllPlaylistsPreview(provider),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleModelSelector(RadioProvider provider) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: provider.playlists.length,
        itemBuilder: (context, index) {
          final playlist =
              provider.playlists.values.elementAt(index);
          final isSelected = playlist.roleModelId == _selectedRoleModelId;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRoleModelId =
                    isSelected ? null : playlist.roleModelId;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple.withValues(alpha: 0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.divider,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.roleModelEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.roleModelName.split(' ').last,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFeaturedSection(RadioProvider provider) {
    final items = provider.filterByTimeOfDay(provider.featuredItems);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For You Right Now',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...items.take(3).map((item) => RadioItemCard(
                item: item,
                isListened: provider.listenedIds.contains(item.id),
                onTap: () => provider.openItem(item),
              )),
        ],
      ),
    );
  }

  Widget _buildChannelList(
    RadioProvider provider,
    String roleModelId,
    RadioChannel channel,
  ) {
    final playlist = provider.playlists[roleModelId];
    if (playlist == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }

    final items = playlist.channels[channel] ?? [];
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items yet',
          style: TextStyle(color: AppColors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return RadioItemCard(
          item: item,
          isListened: provider.listenedIds.contains(item.id),
          onTap: () => provider.openItem(item),
        );
      },
    );
  }

  Widget _buildAllPlaylistsPreview(RadioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: provider.playlists.values.map((playlist) {
        final listened = provider.listenedCount(playlist.roleModelId);
        final total = provider.totalCount(playlist.roleModelId);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRoleModelId = playlist.roleModelId;
            });
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Text(
                  playlist.roleModelEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.roleModelName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total items · $listened listened',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

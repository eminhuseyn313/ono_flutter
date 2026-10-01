import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/social_feed.dart';
import '../providers/social_feed_provider.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/comment_sheet.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialFeedProvider>().loadFeed();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SocialFeedProvider>().loadMore();
    }
  }

  void _showCommentSheet(FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        comments: post.comments,
        onSubmit: (content) {
          context.read<SocialFeedProvider>().addComment(post.id, content);
        },
      ),
    );
  }

  void _showCreatePostSheet() {
    PostType selectedType = PostType.win;
    final contentController = TextEditingController();
    final highlightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 16),
                Text(
                  'Share with the Community',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                // Type selector
                Wrap(
                  spacing: 8,
                  children: PostType.values.map((type) {
                    final isSelected = type == selectedType;
                    final color = _postTypeColor(type);
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? color : AppColors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                    ),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: highlightController,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Highlight (optional, e.g. "14-day streak!")',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.cardLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.purple),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (contentController.text.trim().isEmpty) return;
                      context.read<SocialFeedProvider>().createPost(
                            selectedType,
                            contentController.text.trim(),
                            highlightValue:
                                highlightController.text.trim().isEmpty
                                    ? null
                                    : highlightController.text.trim(),
                          );
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Post',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _postTypeColor(PostType type) {
    switch (type) {
      case PostType.win:
        return AppColors.cyan;
      case PostType.milestone:
        return AppColors.purple;
      case PostType.streak:
        return AppColors.green;
      case PostType.reflection:
        return AppColors.purpleSoft;
      case PostType.challenge:
        return AppColors.warning;
    }
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
        title: Text(
          'Community',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.purple,
        child: const Icon(Icons.edit, color: AppColors.white),
      ),
      body: Consumer<SocialFeedProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: const Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load feed',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.loadFeed(),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: () => provider.loadFeed(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.posts.length + 1, // +1 for stats header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildStatsHeader(provider.stats);
                }
                final post = provider.posts[index - 1];
                return FeedPostCard(
                  post: post,
                  onLike: () => provider.toggleLike(post.id),
                  onComment: () => _showCommentSheet(post),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(FeedStats? stats) {
    if (stats == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Posts', '${stats.totalPosts}'),
          _statItem('Likes', '${stats.totalLikes}'),
          _statItem('Following', '${stats.followingCount}'),
          _statItem('Followers', '${stats.followersCount}'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

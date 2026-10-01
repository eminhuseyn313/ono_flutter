import '../models/social_feed.dart';

abstract class SocialFeedGateway {
  Future<List<FeedPost>> loadFeed({int page = 0});
  Future<FeedStats> loadFeedStats();
  Future<FeedPost> likePost(String postId);
  Future<FeedPost> unlikePost(String postId);
  Future<FeedComment> addComment(String postId, String content);
  Future<FeedPost> createPost(PostType type, String content, {String? highlightValue});
}

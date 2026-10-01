import 'package:flutter/foundation.dart';

import '../gateways/social_feed_gateway.dart';
import '../models/social_feed.dart';

class SocialFeedProvider extends ChangeNotifier {
  final SocialFeedGateway _gateway;

  SocialFeedProvider({required SocialFeedGateway gateway}) : _gateway = gateway;

  List<FeedPost> _posts = [];
  FeedStats? _stats;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 0;

  List<FeedPost> get posts => _posts;
  FeedStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadFeed() async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    notifyListeners();

    try {
      final results = await Future.wait([
        _gateway.loadFeed(page: 0),
        _gateway.loadFeedStats(),
      ]);
      _posts = results[0] as List<FeedPost>;
      _stats = results[1] as FeedStats;
      _hasMore = _posts.isNotEmpty;
      _currentPage = 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newPosts = await _gateway.loadFeed(page: _currentPage);
      if (newPosts.isEmpty) {
        _hasMore = false;
      } else {
        _posts = [..._posts, ...newPosts];
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    try {
      final updated = post.isLikedByMe
          ? await _gateway.unlikePost(postId)
          : await _gateway.likePost(postId);
      _posts = List.from(_posts);
      _posts[index] = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      final comment = await _gateway.addComment(postId, content);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;
      final post = _posts[index];
      final updatedComments = [...post.comments, comment];
      _posts = List.from(_posts);
      _posts[index] = post.copyWith(
        comments: updatedComments,
        commentCount: post.commentCount + 1,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createPost(PostType type, String content,
      {String? highlightValue}) async {
    try {
      final post = await _gateway.createPost(type, content,
          highlightValue: highlightValue);
      _posts = [post, ..._posts];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

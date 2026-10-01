import 'dart:math';

import '../models/social_feed.dart';
import 'social_feed_gateway.dart';

class MockSocialFeedGateway implements SocialFeedGateway {
  final _random = Random();

  final _authors = const [
    FeedAuthor(
      id: 'user_marcus',
      name: 'Marcus T.',
      avatarUrl: '',
      level: 7,
      levelName: 'Architect',
    ),
    FeedAuthor(
      id: 'user_jaylen',
      name: 'Jaylen K.',
      avatarUrl: '',
      level: 4,
      levelName: 'Builder',
    ),
    FeedAuthor(
      id: 'user_darius',
      name: 'Darius W.',
      avatarUrl: '',
      level: 5,
      levelName: 'Warrior',
    ),
    FeedAuthor(
      id: 'user_alex',
      name: 'Alex M.',
      avatarUrl: '',
      level: 3,
      levelName: 'Explorer',
    ),
    FeedAuthor(
      id: 'user_me',
      name: 'You',
      avatarUrl: '',
      level: 5,
      levelName: 'Warrior',
    ),
  ];

  late final List<FeedPost> _posts = _generatePosts();

  List<FeedPost> _generatePosts() {
    final now = DateTime.now();
    return [
      FeedPost(
        id: 'post_1',
        author: _authors[0], // Marcus
        type: PostType.win,
        content:
            'Crushed my morning workout — 5am cold plunge + 45min lifting session. Body feels electric.',
        highlightValue: null,
        colorValue: 0xFF7C9CC4, // cyan
        iconCodePoint: 0xe5d5, // Icons.fitness_center
        createdAt: now.subtract(const Duration(minutes: 23)),
        likeCount: 34,
        commentCount: 5,
        isLikedByMe: true,
        comments: [
          FeedComment(
            id: 'comment_1a',
            author: _authors[1], // Jaylen
            content: 'Cold plunge at 5am is elite. Respect.',
            createdAt: now.subtract(const Duration(minutes: 18)),
            likeCount: 7,
            isLikedByMe: false,
          ),
          FeedComment(
            id: 'comment_1b',
            author: _authors[3], // Alex
            content: 'What temp do you keep the plunge at?',
            createdAt: now.subtract(const Duration(minutes: 12)),
            likeCount: 2,
            isLikedByMe: false,
          ),
          FeedComment(
            id: 'comment_1c',
            author: _authors[0], // Marcus
            content: '50°F. Started at 60 and worked down over a month.',
            createdAt: now.subtract(const Duration(minutes: 8)),
            likeCount: 5,
            isLikedByMe: true,
          ),
        ],
      ),
      FeedPost(
        id: 'post_2',
        author: _authors[4], // You
        type: PostType.milestone,
        content:
            'Just hit Level 5 Warrior! The grind pays off. Every rep, every page, every early morning led here.',
        highlightValue: 'Level 5 reached!',
        colorValue: 0xFFC8894A, // purple
        iconCodePoint: 0xe838, // Icons.emoji_events
        createdAt: now.subtract(const Duration(hours: 2)),
        likeCount: 45,
        commentCount: 8,
        isLikedByMe: false,
        comments: [
          FeedComment(
            id: 'comment_2a',
            author: _authors[2], // Darius
            content: 'Warrior gang! Welcome to the club.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
            likeCount: 12,
            isLikedByMe: true,
          ),
          FeedComment(
            id: 'comment_2b',
            author: _authors[0], // Marcus
            content: 'Level 5 is where it gets real. Keep pushing.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
            likeCount: 8,
            isLikedByMe: false,
          ),
          FeedComment(
            id: 'comment_2c',
            author: _authors[1], // Jaylen
            content: 'Congrats bro! Inspiring to see.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
            likeCount: 3,
            isLikedByMe: false,
          ),
          FeedComment(
            id: 'comment_2d',
            author: _authors[3], // Alex
            content: 'How long did it take you?',
            createdAt: now.subtract(const Duration(hours: 1)),
            likeCount: 1,
            isLikedByMe: false,
          ),
        ],
      ),
      FeedPost(
        id: 'post_3',
        author: _authors[2], // Darius
        type: PostType.streak,
        content:
            '14-day streak and counting. No days off. Mind lane and Body lane every single day.',
        highlightValue: '14-day streak!',
        colorValue: 0xFF7DB495, // green
        iconCodePoint: 0xe80e, // Icons.local_fire_department
        createdAt: now.subtract(const Duration(hours: 4)),
        likeCount: 28,
        commentCount: 3,
        isLikedByMe: true,
        comments: [
          FeedComment(
            id: 'comment_3a',
            author: _authors[4], // You
            content: "Beast mode. I'm on day 9, catching up!",
            createdAt: now.subtract(const Duration(hours: 3, minutes: 30)),
            likeCount: 6,
            isLikedByMe: false,
          ),
          FeedComment(
            id: 'comment_3b',
            author: _authors[0], // Marcus
            content: 'Consistency is the real flex.',
            createdAt: now.subtract(const Duration(hours: 3)),
            likeCount: 9,
            isLikedByMe: true,
          ),
        ],
      ),
      FeedPost(
        id: 'post_4',
        author: _authors[1], // Jaylen
        type: PostType.reflection,
        content:
            'This week taught me that consistency > intensity. Small steps compound. One percent better every day beats burning out trying to do everything at once.',
        highlightValue: null,
        colorValue: 0xFFE8C9A3, // purpleSoft
        iconCodePoint: 0xe3ae, // Icons.lightbulb
        createdAt: now.subtract(const Duration(hours: 6)),
        likeCount: 19,
        commentCount: 2,
        isLikedByMe: false,
        comments: [],
      ),
      FeedPost(
        id: 'post_5',
        author: _authors[3], // Alex
        type: PostType.challenge,
        content:
            "Who's joining the 30-day Mind lane challenge? Let's go! Daily meditation + journaling. Drop a comment if you're in.",
        highlightValue: '30-day challenge',
        colorValue: 0xFFE2B354, // warning
        iconCodePoint: 0xf06bb, // Icons.bolt
        createdAt: now.subtract(const Duration(hours: 8)),
        likeCount: 38,
        commentCount: 12,
        isLikedByMe: true,
        comments: [],
      ),
      FeedPost(
        id: 'post_6',
        author: _authors[0], // Marcus
        type: PostType.win,
        content:
            "Finished reading Atomic Habits. Mind lane XP feels different when you're actually applying what you learn.",
        highlightValue: null,
        colorValue: 0xFF7C9CC4, // cyan
        iconCodePoint: 0xe866, // Icons.menu_book
        createdAt: now.subtract(const Duration(hours: 12)),
        likeCount: 22,
        commentCount: 4,
        isLikedByMe: false,
        comments: [],
      ),
      FeedPost(
        id: 'post_7',
        author: _authors[2], // Darius
        type: PostType.milestone,
        content:
            'Hit 100 total workouts logged. Started 4 months ago barely able to do 10 pushups. Now repping 50 easy.',
        highlightValue: '100 workouts!',
        colorValue: 0xFFC8894A, // purple
        iconCodePoint: 0xe838, // Icons.emoji_events
        createdAt: now.subtract(const Duration(hours: 18)),
        likeCount: 41,
        commentCount: 6,
        isLikedByMe: true,
        comments: [],
      ),
      FeedPost(
        id: 'post_8',
        author: _authors[4], // You
        type: PostType.reflection,
        content:
            "Realized I've been neglecting the Soul lane. Time to balance out. Gratitude practice starts tomorrow.",
        highlightValue: null,
        colorValue: 0xFFE8C9A3, // purpleSoft
        iconCodePoint: 0xe3ae, // Icons.lightbulb
        createdAt: now.subtract(const Duration(days: 1)),
        likeCount: 15,
        commentCount: 1,
        isLikedByMe: false,
        comments: [],
      ),
      FeedPost(
        id: 'post_9',
        author: _authors[1], // Jaylen
        type: PostType.streak,
        content:
            '7-day Body lane streak! First full week without missing. Feels like a superpower.',
        highlightValue: '7-day streak!',
        colorValue: 0xFF7DB495, // green
        iconCodePoint: 0xe80e, // Icons.local_fire_department
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        likeCount: 3,
        commentCount: 0,
        isLikedByMe: false,
        comments: [],
      ),
    ];
  }

  Future<void> _simulateDelay() async {
    final delay = 150 + _random.nextInt(101); // 150-250ms
    await Future.delayed(Duration(milliseconds: delay));
  }

  @override
  Future<List<FeedPost>> loadFeed({int page = 0}) async {
    await _simulateDelay();
    const pageSize = 5;
    final start = page * pageSize;
    if (start >= _posts.length) return [];
    final end = (start + pageSize).clamp(0, _posts.length);
    return _posts.sublist(start, end);
  }

  @override
  Future<FeedStats> loadFeedStats() async {
    await _simulateDelay();
    return const FeedStats(
      totalPosts: 156,
      totalLikes: 892,
      totalComments: 234,
      followingCount: 28,
      followersCount: 42,
    );
  }

  @override
  Future<FeedPost> likePost(String postId) async {
    await _simulateDelay();
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw Exception('Post not found');
    final post = _posts[index];
    final updated = post.copyWith(
      likeCount: post.likeCount + 1,
      isLikedByMe: true,
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<FeedPost> unlikePost(String postId) async {
    await _simulateDelay();
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw Exception('Post not found');
    final post = _posts[index];
    final updated = post.copyWith(
      likeCount: (post.likeCount - 1).clamp(0, 999999),
      isLikedByMe: false,
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<FeedComment> addComment(String postId, String content) async {
    await _simulateDelay();
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw Exception('Post not found');
    final comment = FeedComment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      author: _authors[4], // "You"
      content: content,
      createdAt: DateTime.now(),
      likeCount: 0,
      isLikedByMe: false,
    );
    final post = _posts[index];
    final updatedComments = [...post.comments, comment];
    _posts[index] = post.copyWith(
      comments: updatedComments,
      commentCount: post.commentCount + 1,
    );
    return comment;
  }

  @override
  Future<FeedPost> createPost(PostType type, String content,
      {String? highlightValue}) async {
    await _simulateDelay();
    int color;
    int icon;
    switch (type) {
      case PostType.win:
        color = 0xFF7C9CC4;
        icon = 0xe5d5; // fitness_center
        break;
      case PostType.milestone:
        color = 0xFFC8894A;
        icon = 0xe838; // emoji_events
        break;
      case PostType.streak:
        color = 0xFF7DB495;
        icon = 0xe80e; // local_fire_department
        break;
      case PostType.reflection:
        color = 0xFFE8C9A3;
        icon = 0xe3ae; // lightbulb
        break;
      case PostType.challenge:
        color = 0xFFE2B354;
        icon = 0xf06bb; // bolt
        break;
    }
    final post = FeedPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      author: _authors[4], // "You"
      type: type,
      content: content,
      highlightValue: highlightValue,
      colorValue: color,
      iconCodePoint: icon,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      isLikedByMe: false,
      comments: [],
    );
    _posts.insert(0, post);
    return post;
  }
}

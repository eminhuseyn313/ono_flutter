enum PostType { win, milestone, streak, reflection, challenge }

class FeedAuthor {
  final String id;
  final String name;
  final String avatarUrl;
  final int level;
  final String levelName;

  const FeedAuthor({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.level,
    required this.levelName,
  });

  FeedAuthor copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? level,
    String? levelName,
  }) {
    return FeedAuthor(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      levelName: levelName ?? this.levelName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'level': level,
      'levelName': levelName,
    };
  }

  factory FeedAuthor.fromJson(Map<String, dynamic> json) {
    return FeedAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      level: json['level'] as int,
      levelName: json['levelName'] as String,
    );
  }
}

class FeedComment {
  final String id;
  final FeedAuthor author;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;

  const FeedComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.isLikedByMe,
  });

  FeedComment copyWith({
    String? id,
    FeedAuthor? author,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    bool? isLikedByMe,
  }) {
    return FeedComment(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'isLikedByMe': isLikedByMe,
    };
  }

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      author: FeedAuthor.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int,
      isLikedByMe: json['isLikedByMe'] as bool,
    );
  }
}

class FeedPost {
  final String id;
  final FeedAuthor author;
  final PostType type;
  final String content;
  final String? highlightValue;
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final List<FeedComment> comments;

  const FeedPost({
    required this.id,
    required this.author,
    required this.type,
    required this.content,
    this.highlightValue,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByMe,
    required this.comments,
  });

  FeedPost copyWith({
    String? id,
    FeedAuthor? author,
    PostType? type,
    String? content,
    String? Function()? highlightValue,
    int? colorValue,
    int? iconCodePoint,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    List<FeedComment>? comments,
  }) {
    return FeedPost(
      id: id ?? this.id,
      author: author ?? this.author,
      type: type ?? this.type,
      content: content ?? this.content,
      highlightValue: highlightValue != null ? highlightValue() : this.highlightValue,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'type': type.name,
      'content': content,
      'highlightValue': highlightValue,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLikedByMe': isLikedByMe,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      author: FeedAuthor.fromJson(json['author'] as Map<String, dynamic>),
      type: PostType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'] as String,
      highlightValue: json['highlightValue'] as String?,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int,
      commentCount: json['commentCount'] as int,
      isLikedByMe: json['isLikedByMe'] as bool,
      comments: (json['comments'] as List<dynamic>)
          .map((c) => FeedComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeedStats {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int followingCount;
  final int followersCount;

  const FeedStats({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.followingCount,
    required this.followersCount,
  });

  FeedStats copyWith({
    int? totalPosts,
    int? totalLikes,
    int? totalComments,
    int? followingCount,
    int? followersCount,
  }) {
    return FeedStats(
      totalPosts: totalPosts ?? this.totalPosts,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPosts': totalPosts,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'followingCount': followingCount,
      'followersCount': followersCount,
    };
  }

  factory FeedStats.fromJson(Map<String, dynamic> json) {
    return FeedStats(
      totalPosts: json['totalPosts'] as int,
      totalLikes: json['totalLikes'] as int,
      totalComments: json['totalComments'] as int,
      followingCount: json['followingCount'] as int,
      followersCount: json['followersCount'] as int,
    );
  }
}

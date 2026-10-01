enum ContentType {
  article,
  video,
  podcast,
  exercise;

  String get label {
    switch (this) {
      case ContentType.article:
        return 'Article';
      case ContentType.video:
        return 'Video';
      case ContentType.podcast:
        return 'Podcast';
      case ContentType.exercise:
        return 'Exercise';
    }
  }

  int get iconCodePoint {
    switch (this) {
      case ContentType.article:
        return 0xe873; // Icons.article
      case ContentType.video:
        return 0xe63a; // Icons.play_circle
      case ContentType.podcast:
        return 0xe310; // Icons.headphones
      case ContentType.exercise:
        return 0xe39e; // Icons.fitness_center
    }
  }
}

class ContentItem {
  final String id;
  final String title;
  final String description;
  final String author;
  final ContentType type;
  final String lane;
  final int laneColorValue;
  final int durationMinutes;
  final String? imageUrl;
  final String? sourceUrl;
  final bool isBookmarked;
  final bool isCompleted;
  final double progress; // 0.0 - 1.0
  final DateTime publishedAt;
  final List<String> tags;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.type,
    required this.lane,
    required this.laneColorValue,
    required this.durationMinutes,
    this.imageUrl,
    this.sourceUrl,
    this.isBookmarked = false,
    this.isCompleted = false,
    this.progress = 0.0,
    required this.publishedAt,
    this.tags = const [],
  });

  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    ContentType? type,
    String? lane,
    int? laneColorValue,
    int? durationMinutes,
    String? imageUrl,
    String? sourceUrl,
    bool? isBookmarked,
    bool? isCompleted,
    double? progress,
    DateTime? publishedAt,
    List<String>? tags,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      type: type ?? this.type,
      lane: lane ?? this.lane,
      laneColorValue: laneColorValue ?? this.laneColorValue,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      publishedAt: publishedAt ?? this.publishedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'author': author,
        'type': type.name,
        'lane': lane,
        'lane_color_value': laneColorValue,
        'duration_minutes': durationMinutes,
        'image_url': imageUrl,
        'source_url': sourceUrl,
        'is_bookmarked': isBookmarked,
        'is_completed': isCompleted,
        'progress': progress,
        'published_at': publishedAt.toIso8601String(),
        'tags': tags,
      };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        author: json['author'] as String,
        type: ContentType.values.firstWhere((e) => e.name == json['type']),
        lane: json['lane'] as String,
        laneColorValue: json['lane_color_value'] as int,
        durationMinutes: json['duration_minutes'] as int,
        imageUrl: json['image_url'] as String?,
        sourceUrl: json['source_url'] as String?,
        isBookmarked: json['is_bookmarked'] as bool? ?? false,
        isCompleted: json['is_completed'] as bool? ?? false,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        publishedAt: DateTime.parse(json['published_at'] as String),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

class ContentLibraryData {
  final List<ContentItem> items;
  final List<ContentItem> recommended;
  final int totalItems;
  final int completedItems;
  final int bookmarkedCount;

  const ContentLibraryData({
    required this.items,
    required this.recommended,
    required this.totalItems,
    required this.completedItems,
    required this.bookmarkedCount,
  });

  ContentLibraryData copyWith({
    List<ContentItem>? items,
    List<ContentItem>? recommended,
    int? totalItems,
    int? completedItems,
    int? bookmarkedCount,
  }) {
    return ContentLibraryData(
      items: items ?? this.items,
      recommended: recommended ?? this.recommended,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      bookmarkedCount: bookmarkedCount ?? this.bookmarkedCount,
    );
  }
}

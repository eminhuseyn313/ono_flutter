import '../models/content_library.dart';
import 'content_library_gateway.dart';

class MockContentLibraryGateway implements ContentLibraryGateway {
  List<ContentItem> _items = [];

  List<ContentItem> _generateItems() {
    final now = DateTime.now();
    return [
      // Mind lane
      ContentItem(
        id: 'cl_1',
        title: 'The Science of Meditation',
        description: 'How daily meditation rewires your brain for focus, calm, and emotional resilience. Based on neuroscience research.',
        author: 'Dr. Sarah Chen',
        type: ContentType.article,
        lane: 'Mind',
        laneColorValue: 0xFFC8894A,
        durationMinutes: 8,
        isBookmarked: true,
        isCompleted: true,
        progress: 1.0,
        publishedAt: now.subtract(const Duration(days: 2)),
        tags: ['meditation', 'neuroscience', 'focus'],
      ),
      ContentItem(
        id: 'cl_2',
        title: 'Morning Journaling Routine',
        description: 'A guided 10-minute journaling exercise to start your day with clarity and intention.',
        author: 'ONO Team',
        type: ContentType.exercise,
        lane: 'Mind',
        laneColorValue: 0xFFC8894A,
        durationMinutes: 10,
        isCompleted: false,
        progress: 0.0,
        publishedAt: now.subtract(const Duration(days: 5)),
        tags: ['journaling', 'morning routine', 'clarity'],
      ),
      ContentItem(
        id: 'cl_3',
        title: 'Stoicism for Modern Men',
        description: 'Ancient wisdom meets modern challenges. Learn practical Stoic techniques for emotional mastery.',
        author: 'Marcus Wilson',
        type: ContentType.podcast,
        lane: 'Mind',
        laneColorValue: 0xFFC8894A,
        durationMinutes: 25,
        isCompleted: false,
        progress: 0.4,
        publishedAt: now.subtract(const Duration(days: 1)),
        tags: ['stoicism', 'philosophy', 'emotional intelligence'],
      ),

      // Body lane
      ContentItem(
        id: 'cl_4',
        title: 'No-Equipment HIIT Workout',
        description: 'A 20-minute high-intensity interval training session you can do anywhere. All bodyweight exercises.',
        author: 'Coach Mike',
        type: ContentType.video,
        lane: 'Body',
        laneColorValue: 0xFF7C9CC4,
        durationMinutes: 20,
        isBookmarked: true,
        isCompleted: false,
        progress: 0.0,
        publishedAt: now.subtract(const Duration(days: 3)),
        tags: ['HIIT', 'bodyweight', 'fitness'],
      ),
      ContentItem(
        id: 'cl_5',
        title: 'Sleep Optimization Guide',
        description: 'Science-backed strategies to improve sleep quality, from light exposure to temperature regulation.',
        author: 'Dr. James Liu',
        type: ContentType.article,
        lane: 'Body',
        laneColorValue: 0xFF7C9CC4,
        durationMinutes: 12,
        isCompleted: true,
        progress: 1.0,
        publishedAt: now.subtract(const Duration(days: 7)),
        tags: ['sleep', 'recovery', 'health'],
      ),
      ContentItem(
        id: 'cl_6',
        title: 'Nutrition for Peak Performance',
        description: 'Simple meal prep strategies and macro tracking for young men who want to perform at their best.',
        author: 'Alex Rivera',
        type: ContentType.video,
        lane: 'Body',
        laneColorValue: 0xFF7C9CC4,
        durationMinutes: 15,
        isCompleted: false,
        progress: 0.7,
        publishedAt: now.subtract(const Duration(days: 4)),
        tags: ['nutrition', 'meal prep', 'performance'],
      ),

      // Social lane
      ContentItem(
        id: 'cl_7',
        title: 'The Art of Active Listening',
        description: 'Master the skill that transforms every relationship. Practical exercises for deeper connections.',
        author: 'Emma Torres',
        type: ContentType.article,
        lane: 'Social',
        laneColorValue: 0xFF7DB495,
        durationMinutes: 6,
        isCompleted: false,
        progress: 0.0,
        publishedAt: now.subtract(const Duration(days: 6)),
        tags: ['communication', 'relationships', 'listening'],
      ),
      ContentItem(
        id: 'cl_8',
        title: 'Building Your Network',
        description: 'How to build meaningful professional relationships without feeling fake or transactional.',
        author: 'David Park',
        type: ContentType.podcast,
        lane: 'Social',
        laneColorValue: 0xFF7DB495,
        durationMinutes: 30,
        isBookmarked: true,
        isCompleted: false,
        progress: 0.2,
        publishedAt: now.subtract(const Duration(days: 8)),
        tags: ['networking', 'career', 'relationships'],
      ),
      ContentItem(
        id: 'cl_9',
        title: 'Conflict Resolution Workshop',
        description: 'Interactive exercises to practice healthy conflict resolution in personal and professional life.',
        author: 'ONO Team',
        type: ContentType.exercise,
        lane: 'Social',
        laneColorValue: 0xFF7DB495,
        durationMinutes: 15,
        isCompleted: false,
        progress: 0.0,
        publishedAt: now.subtract(const Duration(days: 10)),
        tags: ['conflict', 'communication', 'growth'],
      ),

      // Skill lane
      ContentItem(
        id: 'cl_10',
        title: 'Deep Work: How to Focus',
        description: 'Techniques from Cal Newport and others to achieve flow state and do meaningful work.',
        author: 'Ryan Foster',
        type: ContentType.article,
        lane: 'Skill',
        laneColorValue: 0xFFE2B354,
        durationMinutes: 10,
        isCompleted: true,
        progress: 1.0,
        publishedAt: now.subtract(const Duration(days: 9)),
        tags: ['focus', 'productivity', 'deep work'],
      ),
      ContentItem(
        id: 'cl_11',
        title: 'Public Speaking Basics',
        description: 'Overcome the fear and learn to command any room. From team meetings to conference stages.',
        author: 'Coach Tara',
        type: ContentType.video,
        lane: 'Skill',
        laneColorValue: 0xFFE2B354,
        durationMinutes: 18,
        isBookmarked: false,
        isCompleted: false,
        progress: 0.5,
        publishedAt: now.subtract(const Duration(days: 11)),
        tags: ['public speaking', 'confidence', 'leadership'],
      ),
      ContentItem(
        id: 'cl_12',
        title: 'Financial Literacy 101',
        description: 'Budgeting, investing, and building wealth in your 20s. The essentials no one taught you in school.',
        author: 'Jordan Blake',
        type: ContentType.podcast,
        lane: 'Skill',
        laneColorValue: 0xFFE2B354,
        durationMinutes: 35,
        isCompleted: false,
        progress: 0.0,
        publishedAt: now.subtract(const Duration(days: 12)),
        tags: ['finance', 'investing', 'budgeting'],
      ),
    ];
  }

  @override
  Future<ContentLibraryData> loadLibrary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items = _generateItems();
    final completed = _items.where((i) => i.isCompleted).length;
    final bookmarked = _items.where((i) => i.isBookmarked).length;
    final recommended = _items.where((i) => !i.isCompleted).take(4).toList();
    return ContentLibraryData(
      items: _items,
      recommended: recommended,
      totalItems: _items.length,
      completedItems: completed,
      bookmarkedCount: bookmarked,
    );
  }

  @override
  Future<List<ContentItem>> loadByLane(String lane) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _items.where((i) => i.lane == lane).toList();
  }

  @override
  Future<List<ContentItem>> searchContent(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final q = query.toLowerCase();
    return _items.where((i) =>
        i.title.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q) ||
        i.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  @override
  Future<void> toggleBookmark(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _items = _items.map((i) {
      if (i.id == itemId) return i.copyWith(isBookmarked: !i.isBookmarked);
      return i;
    }).toList();
  }

  @override
  Future<void> markCompleted(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _items = _items.map((i) {
      if (i.id == itemId) return i.copyWith(isCompleted: true, progress: 1.0);
      return i;
    }).toList();
  }
}

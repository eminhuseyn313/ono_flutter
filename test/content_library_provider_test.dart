import 'package:flutter_test/flutter_test.dart';

import 'package:ono/gateways/content_library_gateway.dart';
import 'package:ono/models/content_library.dart';
import 'package:ono/providers/content_library_provider.dart';

// ---------------------------------------------------------------------------
// Mock gateway
// ---------------------------------------------------------------------------
class MockContentLibraryGateway implements ContentLibraryGateway {
  ContentLibraryData? data;
  Exception? loadError;
  Exception? searchError;
  final List<String> bookmarkedIds = [];
  final List<String> completedIds = [];

  @override
  Future<ContentLibraryData> loadLibrary() async {
    if (loadError != null) throw loadError!;
    return data!;
  }

  @override
  Future<List<ContentItem>> loadByLane(String lane) async {
    return data!.items.where((i) => i.lane == lane).toList();
  }

  @override
  Future<List<ContentItem>> searchContent(String query) async {
    if (searchError != null) throw searchError!;
    return data!.items
        .where((i) => i.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> toggleBookmark(String itemId) async {
    bookmarkedIds.add(itemId);
  }

  @override
  Future<void> markCompleted(String itemId) async {
    completedIds.add(itemId);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
ContentItem _item({
  String id = 'c1',
  String title = 'Test Article',
  String lane = 'Mind',
  ContentType type = ContentType.article,
  bool isBookmarked = false,
  bool isCompleted = false,
  double progress = 0.0,
}) =>
    ContentItem(
      id: id,
      title: title,
      description: 'Description',
      author: 'Author',
      type: type,
      lane: lane,
      laneColorValue: 0xFF8B5CF6,
      durationMinutes: 10,
      isBookmarked: isBookmarked,
      isCompleted: isCompleted,
      progress: progress,
      publishedAt: DateTime(2026, 1, 1),
      tags: ['tag1'],
    );

ContentLibraryData _libraryData({List<ContentItem>? items}) {
  final list = items ??
      [
        _item(id: 'c1', lane: 'Mind', type: ContentType.article),
        _item(id: 'c2', lane: 'Body', type: ContentType.video),
        _item(id: 'c3', lane: 'Mind', type: ContentType.podcast),
        _item(id: 'c4', lane: 'Social', type: ContentType.exercise, isBookmarked: true),
      ];
  return ContentLibraryData(
    items: list,
    recommended: [list.first],
    totalItems: list.length,
    completedItems: list.where((i) => i.isCompleted).length,
    bookmarkedCount: list.where((i) => i.isBookmarked).length,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockContentLibraryGateway gateway;
  late ContentLibraryProvider provider;

  setUp(() {
    gateway = MockContentLibraryGateway();
    provider = ContentLibraryProvider(gateway: gateway);
  });

  tearDown(() => provider.dispose());

  // -- Initial state -------------------------------------------------------

  group('initial state', () {
    test('empty before load', () {
      expect(provider.libraryData, isNull);
      expect(provider.filteredItems, isEmpty);
      expect(provider.selectedLane, 'All');
      expect(provider.selectedType, isNull);
      expect(provider.searchQuery, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });
  });

  // -- Load library --------------------------------------------------------

  group('loadLibrary', () {
    test('loads all items', () async {
      gateway.data = _libraryData();

      await provider.loadLibrary();

      expect(provider.libraryData, isNotNull);
      expect(provider.libraryData!.totalItems, 4);
      expect(provider.filteredItems.length, 4);
      expect(provider.isLoading, false);
    });

    test('sets isLoading during fetch', () async {
      gateway.data = _libraryData();

      bool wasLoading = false;
      provider.addListener(() {
        if (provider.isLoading) wasLoading = true;
      });

      await provider.loadLibrary();

      expect(wasLoading, true);
    });

    test('load error sets error message', () async {
      gateway.loadError = Exception('timeout');

      await provider.loadLibrary();

      expect(provider.libraryData, isNull);
      expect(provider.error, isNotNull);
    });
  });

  // -- Lane filter ---------------------------------------------------------

  group('setLaneFilter', () {
    test('filters by lane', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      provider.setLaneFilter('Mind');

      expect(provider.selectedLane, 'Mind');
      expect(provider.filteredItems.length, 2);
      expect(provider.filteredItems.every((i) => i.lane == 'Mind'), true);
    });

    test('All shows everything', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      provider.setLaneFilter('Mind');
      provider.setLaneFilter('All');

      expect(provider.filteredItems.length, 4);
    });
  });

  // -- Type filter ---------------------------------------------------------

  group('setTypeFilter', () {
    test('filters by content type', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      provider.setTypeFilter(ContentType.article);

      expect(provider.selectedType, ContentType.article);
      expect(provider.filteredItems.length, 1);
      expect(provider.filteredItems.first.type, ContentType.article);
    });

    test('null clears type filter', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      provider.setTypeFilter(ContentType.article);
      provider.setTypeFilter(null);

      expect(provider.filteredItems.length, 4);
    });

    test('combined lane + type filter', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      provider.setLaneFilter('Mind');
      provider.setTypeFilter(ContentType.podcast);

      expect(provider.filteredItems.length, 1);
      expect(provider.filteredItems.first.id, 'c3');
    });
  });

  // -- Search --------------------------------------------------------------

  group('search', () {
    test('searches via gateway', () async {
      gateway.data = _libraryData(items: [
        _item(id: 'c1', title: 'Meditation Guide'),
        _item(id: 'c2', title: 'HIIT Workout'),
      ]);
      await provider.loadLibrary();

      await provider.search('meditation');

      expect(provider.filteredItems.length, 1);
      expect(provider.filteredItems.first.id, 'c1');
      expect(provider.searchQuery, 'meditation');
    });

    test('empty query resets to all items', () async {
      gateway.data = _libraryData();
      await provider.loadLibrary();

      await provider.search('');

      expect(provider.filteredItems.length, 4);
    });
  });

  // -- Toggle bookmark -----------------------------------------------------

  group('toggleBookmark', () {
    test('toggles bookmark and updates count', () async {
      gateway.data = _libraryData(items: [
        _item(id: 'c1', isBookmarked: false),
      ]);
      await provider.loadLibrary();

      await provider.toggleBookmark('c1');

      expect(gateway.bookmarkedIds, ['c1']);
      expect(provider.libraryData!.items.first.isBookmarked, true);
      expect(provider.libraryData!.bookmarkedCount, 1);
    });
  });

  // -- Mark completed ------------------------------------------------------

  group('markCompleted', () {
    test('marks item completed with full progress', () async {
      gateway.data = _libraryData(items: [
        _item(id: 'c1', isCompleted: false, progress: 0.5),
      ]);
      await provider.loadLibrary();

      await provider.markCompleted('c1');

      expect(gateway.completedIds, ['c1']);
      final item = provider.libraryData!.items.first;
      expect(item.isCompleted, true);
      expect(item.progress, 1.0);
      expect(provider.libraryData!.completedItems, 1);
    });
  });

  // -- Model serialization -------------------------------------------------

  group('ContentItem toJson/fromJson', () {
    test('round-trips correctly', () {
      final original = _item(
        id: 'x1',
        isBookmarked: true,
        isCompleted: true,
        progress: 0.75,
      );
      final json = original.toJson();
      final restored = ContentItem.fromJson(json);

      expect(restored.id, 'x1');
      expect(restored.isBookmarked, true);
      expect(restored.isCompleted, true);
      expect(restored.progress, 0.75);
      expect(restored.type, ContentType.article);
      expect(restored.tags, ['tag1']);
    });
  });
}

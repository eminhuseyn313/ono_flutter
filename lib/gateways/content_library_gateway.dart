import '../models/content_library.dart';

abstract class ContentLibraryGateway {
  Future<ContentLibraryData> loadLibrary();
  Future<List<ContentItem>> loadByLane(String lane);
  Future<List<ContentItem>> searchContent(String query);
  Future<void> toggleBookmark(String itemId);
  Future<void> markCompleted(String itemId);
}

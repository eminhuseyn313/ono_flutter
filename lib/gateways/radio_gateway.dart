import '../models/radio.dart';

/// Abstract gateway for Role Model Radio feature.
abstract class RadioGateway {
  /// Load a single role model's playlist by ID.
  Future<RadioPlaylist> loadPlaylist(String roleModelId);

  /// Load all available playlists.
  Future<List<RadioPlaylist>> loadAllPlaylists();

  /// Load featured items based on time of day.
  /// Morning items (before noon) are energizing; evening items are reflective.
  Future<List<RadioItem>> loadFeaturedItems(String timeOfDay);

  /// Mark an item as listened/consumed.
  Future<void> markAsListened(String itemId);

  /// Get set of all item IDs that have been marked as listened.
  Future<Set<String>> getListenedIds();
}

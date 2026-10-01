import '../models/vault.dart';

abstract class VaultGateway {
  Future<List<VaultEntry>> loadEntries();
  Future<VaultEntry> loadEntry(String id);
  Future<List<VaultEntry>> searchEntries(String query);
  Future<List<VaultInsight>> loadInsights();
  Future<List<GrowthPattern>> loadPatterns();
  Future<VaultStats> loadStats();
  Future<List<MoodDataPoint>> loadMoodTimeline();
  Future<VaultEntry> createEntry(VaultEntry entry);
  Future<VaultEntry> updateEntry(VaultEntry entry);
  Future<void> deleteEntry(String id);
  Future<VaultEntry> toggleBookmark(String id);
  Future<VaultEntry> toggleFavorite(String id);
}

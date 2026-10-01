// gateways/trending_gateway.dart — Trending v2 (abstract gateway)

import '../models/trending.dart';

abstract class TrendingGateway {
  // v1 methods
  Future<TrendingFeed> loadTrendingFeed();
  Future<TrendingProfile> loadProfile(String id);
  Future<void> startChallenge(String profileId);
  Future<void> completeChallenge(String profileId, String challengeId);
  Future<List<TrendingChallenge>> getActiveChallenges();
  Future<void> dismissProfile(String id);

  // v2 methods
  Future<TrendingPipelineStatus> getPipelineStatus();
  Future<void> refreshFeed();
  Future<List<TrendingProfile>> loadArchive();
}

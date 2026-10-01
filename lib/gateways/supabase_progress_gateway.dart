import 'package:supabase_flutter/supabase_flutter.dart';
import 'progress_gateway.dart';

/// Production implementation that stores progress data in Supabase.
///
/// Expects tables:
///   `lane_scores` — user_id (uuid), lane (text), score (float8),
///     updated_at (timestamptz). PK: (user_id, lane)
///   `weekly_snapshots` — id (uuid PK), user_id (uuid), week_start (date),
///     lane_scores (jsonb), overall_score (float8),
///     actions_completed (int), actions_total (int)
class SupabaseProgressGateway implements ProgressGateway {
  final SupabaseClient _client;

  SupabaseProgressGateway(this._client);

  @override
  Future<Map<String, double>> loadLaneScores(String userId) async {
    try {
      final data = await _client
          .from('lane_scores')
          .select('lane, score')
          .eq('user_id', userId);

      final scores = <String, double>{};
      for (final row in data as List) {
        scores[row['lane'] as String] = (row['score'] as num).toDouble();
      }

      // Return defaults if no scores exist yet
      if (scores.isEmpty) {
        return {
          'mind': 0.0,
          'body': 0.0,
          'social': 0.0,
          'skill': 0.0,
        };
      }

      return scores;
    } catch (e) {
      throw Exception('Failed to load lane scores: $e');
    }
  }

  @override
  Future<List<WeeklySnapshot>> loadWeeklySnapshots(
    String userId, {
    required int weeks,
  }) async {
    try {
      final data = await _client
          .from('weekly_snapshots')
          .select()
          .eq('user_id', userId)
          .order('week_start', ascending: false)
          .limit(weeks);

      return (data as List).map((row) {
        final rawScores = row['lane_scores'] as Map<String, dynamic>? ?? {};
        return WeeklySnapshot(
          weekStart: DateTime.parse(row['week_start'] as String),
          laneScores:
              rawScores.map((k, v) => MapEntry(k, (v as num).toDouble())),
          overallScore: (row['overall_score'] as num).toDouble(),
          actionsCompleted: row['actions_completed'] as int? ?? 0,
          actionsTotal: row['actions_total'] as int? ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    } catch (e) {
      throw Exception('Failed to load weekly snapshots: $e');
    }
  }

  @override
  Future<void> saveLaneScores(
      String userId, Map<String, double> scores) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Upsert each lane score
      final rows = scores.entries
          .map((e) => {
                'user_id': userId,
                'lane': e.key,
                'score': e.value,
                'updated_at': now,
              })
          .toList();

      await _client
          .from('lane_scores')
          .upsert(rows, onConflict: 'user_id,lane');
    } catch (e) {
      throw Exception('Failed to save lane scores: $e');
    }
  }
}

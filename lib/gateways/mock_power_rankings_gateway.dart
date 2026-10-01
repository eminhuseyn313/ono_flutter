import '../models/power_rankings.dart';
import 'power_rankings_gateway.dart';

class MockPowerRankingsGateway implements PowerRankingsGateway {
  final DateTime _now = DateTime.now();

  DateTime get _currentWeekStart {
    final weekday = _now.weekday;
    return DateTime(_now.year, _now.month, _now.day - (weekday - 1));
  }

  DateTime get _currentWeekEnd => _currentWeekStart.add(const Duration(days: 6));

  final List<Map<String, dynamic>> _weeklyData = const [
    {'overall': 74, 'mind': 82, 'body': 71, 'social': 68, 'skill': 75},
    {'overall': 71, 'mind': 76, 'body': 70, 'social': 72, 'skill': 70},
    {'overall': 68, 'mind': 72, 'body': 67, 'social': 65, 'skill': 68},
    {'overall': 65, 'mind': 69, 'body': 64, 'social': 63, 'skill': 66},
    {'overall': 70, 'mind': 74, 'body': 68, 'social': 67, 'skill': 71},
    {'overall': 63, 'mind': 66, 'body': 62, 'social': 60, 'skill': 64},
    {'overall': 72, 'mind': 78, 'body': 69, 'social': 66, 'skill': 73},
    {'overall': 86, 'mind': 89, 'body': 84, 'social': 82, 'skill': 87},
    {'overall': 75, 'mind': 80, 'body': 72, 'social': 70, 'skill': 76},
    {'overall': 60, 'mind': 64, 'body': 58, 'social': 56, 'skill': 62},
    {'overall': 55, 'mind': 58, 'body': 54, 'social': 52, 'skill': 56},
    {'overall': 48, 'mind': 52, 'body': 46, 'social': 44, 'skill': 50},
  ];

  WeeklyDigest _buildDigest(int weeksAgo) {
    final data = _weeklyData[weeksAgo];
    final previousData =
        weeksAgo + 1 < _weeklyData.length ? _weeklyData[weeksAgo + 1] : data;
    final weekStart =
        _currentWeekStart.subtract(Duration(days: 7 * weeksAgo));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekNumber = 12 - weeksAgo;

    final scores = {
      'mind': data['mind'] as int,
      'body': data['body'] as int,
      'social': data['social'] as int,
      'skill': data['skill'] as int,
    };

    final previousScores = {
      'mind': previousData['mind'] as int,
      'body': previousData['body'] as int,
      'social': previousData['social'] as int,
      'skill': previousData['skill'] as int,
    };

    final sortedLanes = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final previousSortedLanes = previousScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final previousRankMap = <String, int>{};
    for (var i = 0; i < previousSortedLanes.length; i++) {
      previousRankMap[previousSortedLanes[i].key] = i + 1;
    }

    final laneRankings = <LaneRanking>[];
    for (var i = 0; i < sortedLanes.length; i++) {
      final lane = sortedLanes[i].key;
      final score = sortedLanes[i].value;
      final prevScore = previousScores[lane] ?? score;
      final rank = i + 1;
      final prevRank = previousRankMap[lane] ?? rank;

      RankTrend trend;
      if (score > prevScore) {
        trend = RankTrend.up;
      } else if (score < prevScore) {
        trend = RankTrend.down;
      } else {
        trend = RankTrend.stable;
      }

      laneRankings.add(LaneRanking(
        lane: lane,
        score: score,
        previousScore: prevScore,
        rank: rank,
        previousRank: prevRank,
        trend: trend,
        streakDays: _getStreakDays(lane, weeksAgo),
        completionRate: _getCompletionRate(lane, score),
        topAction: _getTopAction(lane, weeksAgo),
        improvementTip: _getImprovementTip(lane, score),
      ));
    }

    return WeeklyDigest(
      id: 'digest_w$weekNumber',
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      overallScore: data['overall'] as int,
      previousOverallScore: previousData['overall'] as int,
      tier: PerformanceTier.fromScore(data['overall'] as int),
      laneRankings: laneRankings,
      highlights: _getHighlights(weeksAgo),
      totalActionsCompleted: _getActionsCompleted(data['overall'] as int),
      totalXpEarned: _getXpEarned(data['overall'] as int),
      weekNumber: weekNumber,
    );
  }

  int _getStreakDays(String lane, int weeksAgo) {
    final streaks = {
      0: {'mind': 7, 'body': 4, 'social': 3, 'skill': 5},
      1: {'mind': 5, 'body': 4, 'social': 6, 'skill': 3},
      2: {'mind': 4, 'body': 3, 'social': 2, 'skill': 4},
    };
    return streaks[weeksAgo]?[lane] ?? (3 + (lane.length % 4));
  }

  double _getCompletionRate(String lane, int score) {
    return (score / 100.0 * 0.85 + 0.1).clamp(0.0, 1.0);
  }

  String _getTopAction(String lane, int weeksAgo) {
    final actions = {
      'mind': [
        'Morning meditation (7-day streak)',
        'Journaling practice',
        'Mindfulness exercises',
      ],
      'body': [
        'Strength training sessions',
        'Running 5K personal best',
        'Consistent sleep schedule',
      ],
      'social': [
        'Accountability check-ins',
        'Community event attendance',
        'Mentorship session',
      ],
      'skill': [
        'Completed 2 Forge lessons',
        'Side project milestone',
        'Reading challenge progress',
      ],
    };
    final laneActions = actions[lane] ?? ['General progress'];
    return laneActions[weeksAgo % laneActions.length];
  }

  String _getImprovementTip(String lane, int score) {
    if (score >= 85) {
      return 'You\'re in the elite zone. Maintain consistency and mentor others.';
    }
    final tips = {
      'mind': 'Try adding a 5-minute evening reflection to your routine.',
      'body': 'Increase workout frequency by one session this week.',
      'social': 'Reach out to one new person in the community this week.',
      'skill': 'Dedicate 30 minutes daily to focused skill practice.',
    };
    return tips[lane] ?? 'Keep pushing forward with daily consistency.';
  }

  List<String> _getHighlights(int weeksAgo) {
    final allHighlights = [
      [
        '7-day meditation streak',
        'Completed 2 Forge lessons',
        '3 accountability check-ins',
        'Hit 74 overall score - Strong tier',
      ],
      [
        'Consistent morning routine all week',
        'Social lane peaked at 72',
        'First community event hosted',
      ],
      [
        'Body training consistency improved',
        'Started new skill track',
        'Mind score climbing steadily',
      ],
      [
        'Recovered from dip with renewed focus',
        'Set weekly planning habit',
      ],
      [
        'Strong week across all lanes',
        'Meditation habit solidified',
        'Skill practice became daily',
      ],
      [
        'Challenging week but stayed active',
        'Identified key improvement areas',
      ],
      [
        'Breakthrough in Mind lane',
        'Body consistency returned',
        'Skill score jump of +9 points',
      ],
      [
        'Best week ever - Elite tier reached',
        'All lanes above 80',
        'Personal records in 3 categories',
        'Community recognition earned',
      ],
      [
        'Solid performance maintained',
        'Body and Skill lanes strong',
      ],
      [
        'Rebuilding after slow start',
        'Focus on fundamentals',
      ],
      [
        'Getting into the groove',
        'First consistent workout week',
      ],
      [
        'Journey begins - baseline established',
        'Onboarding completed',
      ],
    ];
    return allHighlights[weeksAgo.clamp(0, allHighlights.length - 1)];
  }

  int _getActionsCompleted(int overallScore) {
    return (overallScore * 0.4 + 8).round();
  }

  int _getXpEarned(int overallScore) {
    return overallScore * 15 + 200;
  }

  @override
  Future<WeeklyDigest> getCurrentWeekDigest() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _buildDigest(0);
  }

  @override
  Future<WeeklyDigest> getDigestForWeek(DateTime weekStart) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final weeksAgo =
        _currentWeekStart.difference(weekStart).inDays ~/ 7;
    final clampedWeeksAgo = weeksAgo.clamp(0, _weeklyData.length - 1);
    return _buildDigest(clampedWeeksAgo);
  }

  @override
  Future<List<RankingHistory>> getHistory(int weeks) async {
    await Future.delayed(const Duration(milliseconds: 220));
    final historyWeeks = weeks.clamp(1, _weeklyData.length);
    return List.generate(historyWeeks, (i) {
      final data = _weeklyData[i];
      final weekStart =
          _currentWeekStart.subtract(Duration(days: 7 * i));
      return RankingHistory(
        week: weekStart,
        overallScore: data['overall'] as int,
        laneScores: {
          'mind': data['mind'] as int,
          'body': data['body'] as int,
          'social': data['social'] as int,
          'skill': data['skill'] as int,
        },
      );
    }).reversed.toList();
  }

  @override
  Future<PowerRankingsStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final history = await getHistory(12);
    return PowerRankingsStats(
      currentTier: PerformanceTier.strong,
      bestTier: PerformanceTier.elite,
      averageOverallScore: 69.0,
      totalWeeksTracked: 12,
      bestWeekScore: 86,
      worstWeekScore: 48,
      mostImprovedLane: 'mind',
      strongestLane: 'mind',
      weakestLane: 'social',
      weeklyHistory: history,
    );
  }

  @override
  Future<RecapCard> generateRecapCard(String digestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final weeksAgo = int.tryParse(
            digestId.replaceAll('digest_w', '')) ??
        12;
    final weekIndex = 12 - weeksAgo;
    final digest = _buildDigest(weekIndex.clamp(0, _weeklyData.length - 1));

    final laneLines = digest.laneRankings.map((l) {
      final arrow = l.trend == RankTrend.up
          ? '↑'
          : l.trend == RankTrend.down
              ? '↓'
              : '→';
      return '${l.laneEmoji} ${l.lane.substring(0, 1).toUpperCase()}${l.lane.substring(1)}: ${l.score} $arrow';
    }).join('\n');

    final shareText = '''ONO Power Rankings - Week ${digest.weekNumber}

${digest.tier.emoji} ${digest.tier.displayName} Tier
Overall Score: ${digest.overallScore}/100

$laneLines

Highlights:
${digest.highlights.map((h) => '  - $h').join('\n')}

Total Actions: ${digest.totalActionsCompleted} | XP Earned: ${digest.totalXpEarned}

Level up with ONO - Your transformation journey awaits.''';

    return RecapCard(
      id: 'recap_${digest.id}',
      weekDigest: digest,
      generatedAt: DateTime.now(),
      shareText: shareText,
    );
  }
}

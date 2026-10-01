import 'dart:math';

import 'package:flutter/material.dart';

import '../models/analytics.dart';
import 'analytics_gateway.dart';

class MockAnalyticsGateway implements AnalyticsGateway {
  final _random = Random(42);

  List<DataPoint> _generateDataPoints(int count, double baseValue, double variance) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final offset = count - 1 - i;
      final noise = (_random.nextDouble() - 0.5) * variance;
      final trendBoost = i * (variance * 0.05);
      return DataPoint(
        date: now.subtract(Duration(days: offset)),
        value: (baseValue + noise + trendBoost).clamp(0, 100),
      );
    });
  }

  List<DataPoint> _generateXpDataPoints(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final offset = count - 1 - i;
      final base = 30 + _random.nextInt(40);
      final spike = _random.nextDouble() > 0.85 ? _random.nextInt(100) : 0;
      return DataPoint(
        date: now.subtract(Duration(days: offset)),
        value: (base + spike).toDouble(),
      );
    });
  }

  Map<int, bool> _generateLast30Days() {
    final map = <int, bool>{};
    for (int i = 0; i < 30; i++) {
      if (i < 14) {
        map[i] = true;
      } else if (i == 16 || i == 19 || i == 22 || i == 25 || i == 28) {
        map[i] = false;
      } else {
        map[i] = _random.nextDouble() > 0.3;
      }
    }
    return map;
  }

  LaneAnalytics _buildLane({
    required String name,
    required int color,
    required int icon,
    required double score,
    required double trend,
    required int pointCount,
  }) {
    final previousScore = score - trend;
    return LaneAnalytics(
      laneName: name,
      colorValue: color,
      iconCodePoint: icon,
      currentScore: score,
      previousScore: previousScore,
      history: _generateDataPoints(pointCount, score - 10, 20),
      actionsCompleted: 15 + _random.nextInt(30),
      totalTimeMinutes: 120 + _random.nextInt(300),
      trend: trend,
    );
  }

  @override
  Future<AnalyticsSummary> loadAnalytics(AnalyticsPeriod period) async {
    await Future.delayed(const Duration(milliseconds: 180));

    final pointCount = period == AnalyticsPeriod.week ? 7 : 30;

    final lanes = [
      _buildLane(
        name: 'Mind',
        color: 0xFF8B5CF6,
        icon: Icons.psychology.codePoint,
        score: 72,
        trend: 5,
        pointCount: pointCount,
      ),
      _buildLane(
        name: 'Body',
        color: 0xFF22D3EE,
        icon: Icons.fitness_center.codePoint,
        score: 85,
        trend: 12,
        pointCount: pointCount,
      ),
      _buildLane(
        name: 'Social',
        color: 0xFF34D399,
        icon: Icons.people.codePoint,
        score: 58,
        trend: -3,
        pointCount: pointCount,
      ),
      _buildLane(
        name: 'Skill',
        color: 0xFFF59E0B,
        icon: Icons.auto_awesome.codePoint,
        score: 67,
        trend: 8,
        pointCount: pointCount,
      ),
    ];

    final streaks = StreakAnalytics(
      currentStreak: 14,
      longestStreak: 23,
      totalActiveDays: 45,
      weeklyStreaks: _generateDataPoints(pointCount, 5, 3),
      last30Days: _generateLast30Days(),
    );

    final xp = XpAnalytics(
      totalXp: 2340,
      currentLevel: 5,
      levelName: 'Warrior',
      progressToNext: 0.62,
      xpHistory: _generateXpDataPoints(pointCount),
      avgDailyXp: 42,
      bestDayXp: 185,
      bestDayDate: DateTime.now().subtract(const Duration(days: 3)),
    );

    return AnalyticsSummary(
      lanes: lanes,
      streaks: streaks,
      xp: xp,
      totalActions: 87,
      totalJournals: 23,
      totalReflections: 12,
      overallScore: 70.5,
      period: period,
    );
  }

  @override
  Future<LaneAnalytics> loadLaneDetail(
      String laneName, AnalyticsPeriod period) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final pointCount = period == AnalyticsPeriod.week ? 7 : 30;

    final laneConfigs = {
      'Mind': (color: 0xFF8B5CF6, icon: Icons.psychology.codePoint, score: 72.0, trend: 5.0),
      'Body': (color: 0xFF22D3EE, icon: Icons.fitness_center.codePoint, score: 85.0, trend: 12.0),
      'Social': (color: 0xFF34D399, icon: Icons.people.codePoint, score: 58.0, trend: -3.0),
      'Skill': (color: 0xFFF59E0B, icon: Icons.auto_awesome.codePoint, score: 67.0, trend: 8.0),
    };

    final config = laneConfigs[laneName] ??
        (color: 0xFF8B5CF6, icon: Icons.psychology.codePoint, score: 50.0, trend: 0.0);

    return _buildLane(
      name: laneName,
      color: config.color,
      icon: config.icon,
      score: config.score,
      trend: config.trend,
      pointCount: pointCount,
    );
  }

  @override
  Future<XpAnalytics> loadXpHistory(AnalyticsPeriod period) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final pointCount = period == AnalyticsPeriod.week ? 7 : 30;

    return XpAnalytics(
      totalXp: 2340,
      currentLevel: 5,
      levelName: 'Warrior',
      progressToNext: 0.62,
      xpHistory: _generateXpDataPoints(pointCount),
      avgDailyXp: 42,
      bestDayXp: 185,
      bestDayDate: DateTime.now().subtract(const Duration(days: 3)),
    );
  }
}

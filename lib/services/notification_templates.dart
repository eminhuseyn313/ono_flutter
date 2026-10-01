import 'dart:math';

import '../models/notification_model.dart';

/// Static library of ONO's motivational notification copy, plus the
/// interpolation helpers used to fill it in with live user data.
///
/// The tone is deliberately blunt and specific — never a generic
/// "Don't forget to check in!" This is what makes v1 feel like a
/// motivator instead of an alarm clock.
class NotificationTemplates {
  NotificationTemplates._();

  static final Random _random = Random();

  // ──────────────────────────────────────────
  // STREAK AT RISK
  // ──────────────────────────────────────────
  static const List<String> _streakTitles = [
    '🔥 {streak} days strong.',
    "Your {streak}-day streak is waiting.",
    'The old you would skip today.',
    "{streak} days of proof you're different now.",
    "Don't be the reason it ends at {streak}.",
    'Day {streak}. Still showing up?',
  ];

  static const List<String> _streakBodies = [
    "Don't let today be day zero.",
    '23 hours left. Prove them wrong.',
    'One action. That\'s all it takes to keep it alive.',
    'Streaks die from excuses, not accidents.',
    "You've come too far to let it slip now.",
    "Future you is counting on the you right now.",
  ];

  // ──────────────────────────────────────────
  // ROLE MODEL / CONTEXTUAL
  // ──────────────────────────────────────────
  static const List<Map<String, String>> _roleModelCopy = [
    {
      'title': 'Marcus Aurelius journaled every morning. 🧠',
      'body': 'Your Mind lane awaits.',
      'lane': 'mind',
    },
    {
      'title': 'Goggins ran 100 miles on broken feet. 💪',
      'body': 'Your 20 pushups are nothing. Go.',
      'lane': 'body',
    },
    {
      'title': "Naval says specific knowledge can't be taught. 📚",
      'body': 'Keep building yours.',
      'lane': 'skill',
    },
    {
      'title': 'Marcus Aurelius wrote to no one but himself. 🧠',
      'body': 'Your reflection is overdue.',
      'lane': 'mind',
    },
    {
      'title': 'David Goggins calls it callusing the mind. 💪',
      'body': "Today's the day you callus a little more.",
      'lane': 'body',
    },
    {
      'title': 'Naval says play long-term games with long-term people. 📚',
      'body': 'Show up for your Skill lane today.',
      'lane': 'skill',
    },
    {
      'title': 'Cal Newport built a career on deep work. 🧠',
      'body': 'Block out distractions. Your Mind lane is calling.',
      'lane': 'mind',
    },
    {
      'title': 'Jocko Willink wakes up at 4:30am. Every day. 💪',
      'body': 'No excuses. Your Body lane is waiting.',
      'lane': 'body',
    },
  ];

  // ──────────────────────────────────────────
  // SOCIAL PROOF
  // ──────────────────────────────────────────
  static const List<String> _socialProofTitles = [
    '{count} warriors completed their actions today.',
    "You're in the top {percent}% this week.",
    '{count} people just like you showed up today.',
    'The community just crossed {count} actions today.',
    "You're outpacing {percent}% of ONO users this week.",
    '{count} streaks were extended in the last hour.',
  ];

  static const List<String> _socialProofBodies = [
    'Join them.',
    'Keep climbing.',
    'Your action is one tap away.',
    'Momentum compounds. Add yours.',
    "Don't fall behind the pack.",
    'This is what discipline looks like at scale.',
  ];

  // ──────────────────────────────────────────
  // MILESTONE
  // ──────────────────────────────────────────
  static const List<String> _milestoneTitles = [
    '🏆 New achievement unlocked: {title}',
    '⬆️ Legacy Score hit {score}!',
    "🎯 You just hit {streak} days. That's a milestone.",
    '🥇 {title} — earned, not given.',
    '🚀 Legacy Score: {score}. New personal best.',
  ];

  static const List<String> _milestoneBodies = [
    "You're now a {tier}.",
    'Consistency did this. Keep going.',
    'This one goes in the highlight reel.',
    "You're proving it, one day at a time.",
    'Screenshot this. You earned it.',
  ];

  static String _pick(List<String> options) {
    return options[_random.nextInt(options.length)];
  }

  static String _fill(
    String template, {
    int? streak,
    String? roleModel,
    int? count,
    int? percent,
    int? score,
    String? tier,
    String? title,
  }) {
    return template
        .replaceAll('{streak}', '${streak ?? 0}')
        .replaceAll('{roleModel}', roleModel ?? '')
        .replaceAll('{count}', _formatCount(count ?? 0))
        .replaceAll('{percent}', '${percent ?? 0}')
        .replaceAll('{score}', _formatCount(score ?? 0))
        .replaceAll('{tier}', tier ?? '')
        .replaceAll('{title}', title ?? '');
  }

  static String _formatCount(int value) {
    if (value >= 1000) {
      final thousands = value / 1000.0;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k'
          .replaceAll('.0k', 'k');
    }
    // Add thousands separators for readability, e.g. 1247 -> 1,247.
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  /// Generate a random streak-at-risk notification for the given streak count.
  static OnoNotification streakRisk({
    required String id,
    required int streak,
    String? actionRoute,
  }) {
    return OnoNotification(
      id: id,
      type: NotificationType.streakRisk,
      title: _fill(_pick(_streakTitles), streak: streak),
      body: _fill(_pick(_streakBodies), streak: streak),
      createdAt: DateTime.now(),
      actionRoute: actionRoute ?? '/home',
    );
  }

  /// Generate a random role-model notification, optionally scoped to a lane.
  static OnoNotification roleModel({
    required String id,
    String? lane,
    String? actionRoute,
  }) {
    final candidates = lane == null
        ? _roleModelCopy
        : _roleModelCopy.where((c) => c['lane'] == lane).toList();
    final pool = candidates.isEmpty ? _roleModelCopy : candidates;
    final entry = pool[_random.nextInt(pool.length)];

    return OnoNotification(
      id: id,
      type: NotificationType.roleModel,
      title: entry['title']!,
      body: entry['body']!,
      lane: entry['lane'],
      createdAt: DateTime.now(),
      actionRoute: actionRoute ?? '/lane/${entry['lane']}',
    );
  }

  /// Generate a random social-proof notification.
  static OnoNotification socialProof({
    required String id,
    int count = 1247,
    int percent = 10,
    String? actionRoute,
  }) {
    return OnoNotification(
      id: id,
      type: NotificationType.socialProof,
      title: _fill(_pick(_socialProofTitles), count: count, percent: percent),
      body: _pick(_socialProofBodies),
      createdAt: DateTime.now(),
      actionRoute: actionRoute ?? '/home',
    );
  }

  /// Generate a random milestone celebration notification.
  static OnoNotification milestone({
    required String id,
    String title = 'Iron Will',
    int score = 0,
    String tier = 'Disciplined Operator',
    int streak = 0,
    String? actionRoute,
  }) {
    return OnoNotification(
      id: id,
      type: NotificationType.milestone,
      title: _fill(
        _pick(_milestoneTitles),
        title: title,
        score: score,
        streak: streak,
      ),
      body: _fill(_pick(_milestoneBodies), tier: tier),
      createdAt: DateTime.now(),
      actionRoute: actionRoute ?? '/achievements',
    );
  }

  /// Raw preview copy for the settings screen — one example per category,
  /// with placeholders already filled with representative sample values.
  static Map<NotificationType, ({String title, String body})> previewSamples() {
    return {
      NotificationType.streakRisk: (
        title: _fill(_streakTitles[0], streak: 12),
        body: _streakBodies[1],
      ),
      NotificationType.roleModel: (
        title: _roleModelCopy[1]['title']!,
        body: _roleModelCopy[1]['body']!,
      ),
      NotificationType.socialProof: (
        title: _fill(_socialProofTitles[0], count: 1247),
        body: _socialProofBodies[0],
      ),
      NotificationType.milestone: (
        title: _fill(_milestoneTitles[0], title: 'Iron Will'),
        body: _fill(_milestoneBodies[0], tier: 'Disciplined Operator'),
      ),
    };
  }
}

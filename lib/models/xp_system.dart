/// XP & levelling system for ONO.
///
/// Every completed action, streak milestone, and journey finish earns XP.
/// 10 levels span the full arc from newcomer to master.
library;

class XpLevel {
  final int level;
  final String title;
  final String emoji;
  final int xpRequired; // cumulative XP to *reach* this level

  const XpLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.xpRequired,
  });
}

class XpSystem {
  // ── XP rewards ──────────────────────────────────────────────
  static const int actionComplete = 15;
  static const int journalEntry = 20;
  static const int morningRitual = 25;
  static const int streak3 = 50;
  static const int streak7 = 120;
  static const int streak14 = 250;
  static const int streak30 = 600;
  static const int journeyComplete = 300;
  static const int weeklyReview = 40;
  static const int roleModelRead = 10;

  // ── Level table ─────────────────────────────────────────────
  static const List<XpLevel> levels = [
    XpLevel(level: 1, title: 'Rookie', emoji: '🌱', xpRequired: 0),
    XpLevel(level: 2, title: 'Explorer', emoji: '🧭', xpRequired: 100),
    XpLevel(level: 3, title: 'Apprentice', emoji: '🔧', xpRequired: 300),
    XpLevel(level: 4, title: 'Builder', emoji: '🏗️', xpRequired: 600),
    XpLevel(level: 5, title: 'Warrior', emoji: '⚔️', xpRequired: 1000),
    XpLevel(level: 6, title: 'Strategist', emoji: '♟️', xpRequired: 1600),
    XpLevel(level: 7, title: 'Champion', emoji: '🏆', xpRequired: 2500),
    XpLevel(level: 8, title: 'Master', emoji: '🎓', xpRequired: 3800),
    XpLevel(level: 9, title: 'Legend', emoji: '🌟', xpRequired: 5500),
    XpLevel(level: 10, title: 'Transcendent', emoji: '👑', xpRequired: 8000),
  ];

  /// Returns the [XpLevel] for the given cumulative XP.
  static XpLevel levelFor(int totalXp) {
    XpLevel current = levels.first;
    for (final l in levels) {
      if (totalXp >= l.xpRequired) {
        current = l;
      } else {
        break;
      }
    }
    return current;
  }

  /// Progress fraction (0.0 → 1.0) toward the *next* level.
  static double progressToNext(int totalXp) {
    final current = levelFor(totalXp);
    if (current.level == levels.last.level) return 1.0;
    final next = levels[current.level]; // levels are 1-indexed in meaning
    final range = next.xpRequired - current.xpRequired;
    if (range <= 0) return 1.0;
    return ((totalXp - current.xpRequired) / range).clamp(0.0, 1.0);
  }

  /// XP needed to reach the next level (0 if already max).
  static int xpToNextLevel(int totalXp) {
    final current = levelFor(totalXp);
    if (current.level == levels.last.level) return 0;
    final next = levels[current.level];
    return (next.xpRequired - totalXp).clamp(0, next.xpRequired);
  }
}

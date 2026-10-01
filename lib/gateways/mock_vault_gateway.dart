import '../models/vault.dart';
import 'vault_gateway.dart';

class MockVaultGateway implements VaultGateway {
  final List<VaultEntry> _entries = [
    VaultEntry(
      id: 'v1',
      title: 'First Day Back at the Gym',
      content:
          'Finally dragged myself to the gym after two weeks off. Started light — just bench press, rows, and some core work. My numbers dropped but I expected that. The important thing is I showed up. Talked to a guy who spotted me on bench and we exchanged workout tips. Felt like a small social win too. Need to remember this feeling of accomplishment when I want to skip tomorrow.',
      mood: VaultMood.motivated,
      tags: [VaultTag.win, VaultTag.reflection],
      lane: 'Body',
      createdAt: DateTime.now().subtract(const Duration(days: 89)),
      updatedAt: DateTime.now().subtract(const Duration(days: 89)),
      wordCount: 72,
      isBookmarked: true,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v2',
      title: 'Atomic Habits Chapter 3 Notes',
      content:
          'James Clear talks about identity-based habits. Instead of "I want to read more" it should be "I am a reader." This hits different. I have been saying "I want to get fit" but what if I just start calling myself an athlete? The 1% improvement idea is powerful — small daily progress compounds. Applied this to my morning routine: wake up 10 minutes earlier each week instead of trying to become a 5am person overnight.',
      mood: VaultMood.onFire,
      tags: [VaultTag.lesson, VaultTag.idea],
      lane: 'Mind',
      createdAt: DateTime.now().subtract(const Duration(days: 85)),
      updatedAt: DateTime.now().subtract(const Duration(days: 85)),
      wordCount: 89,
      isBookmarked: false,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v3',
      title: 'Awkward Networking Event',
      content:
          'Went to the tech meetup downtown. Stood by myself for the first 20 minutes feeling like an idiot. Almost left. Then forced myself to introduce myself to a group talking about mobile dev. Turns out they were super welcoming. Got two LinkedIn connections. One guy is building a Flutter app and wants to collaborate. Still felt drained after but proud I pushed through the discomfort.',
      mood: VaultMood.tired,
      tags: [VaultTag.win, VaultTag.lesson],
      lane: 'Social',
      createdAt: DateTime.now().subtract(const Duration(days: 78)),
      updatedAt: DateTime.now().subtract(const Duration(days: 78)),
      wordCount: 81,
      isBookmarked: false,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v4',
      title: 'Learning Dart Generics',
      content:
          'Spent 3 hours on Dart generics and type constraints. Finally understand the difference between covariance and contravariance. Built a generic repository pattern for my side project. This is the kind of deep work Cal Newport talks about — when you hit flow state and time just vanishes. Need to protect these deep work blocks. Added a 2-hour block to my calendar every morning.',
      mood: VaultMood.onFire,
      tags: [VaultTag.win, VaultTag.idea],
      lane: 'Skill',
      createdAt: DateTime.now().subtract(const Duration(days: 72)),
      updatedAt: DateTime.now().subtract(const Duration(days: 72)),
      wordCount: 74,
      isBookmarked: true,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v5',
      title: 'Skipped Gym Three Days Straight',
      content:
          'I keep telling myself I will go tomorrow. Work has been stressful and I used that as an excuse. But honestly, the days I work out are the days I handle stress better. Need to break this cycle. Setting my gym clothes out tonight. Non-negotiable tomorrow morning. Even if it is just 20 minutes. Something is better than nothing.',
      mood: VaultMood.struggling,
      tags: [VaultTag.setback, VaultTag.reflection],
      lane: 'Body',
      createdAt: DateTime.now().subtract(const Duration(days: 65)),
      updatedAt: DateTime.now().subtract(const Duration(days: 65)),
      wordCount: 71,
      isBookmarked: false,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v6',
      title: 'Grateful for My Morning Routine',
      content:
          'Three weeks into my new morning routine and it is transforming my days. Wake at 6:30, 10 minutes meditation, cold shower, journal, then coffee. The cold shower was the hardest habit to build but now I crave it. My focus at work has improved noticeably. My manager even commented that my code reviews have been more thorough. Small habits, big results.',
      mood: VaultMood.motivated,
      tags: [VaultTag.gratitude, VaultTag.win],
      lane: 'Mind',
      createdAt: DateTime.now().subtract(const Duration(days: 58)),
      updatedAt: DateTime.now().subtract(const Duration(days: 58)),
      wordCount: 76,
      isBookmarked: true,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v7',
      title: 'Had a Real Conversation',
      content:
          'Met up with Marcus for coffee. Instead of the usual surface-level banter, I asked him how he was really doing. He opened up about his career doubts. I shared mine too. We talked for two hours and it felt like the first genuine connection I have had in months. I need to do this more — quality over quantity in relationships. Going to reach out to one old friend each week.',
      mood: VaultMood.onFire,
      tags: [VaultTag.gratitude, VaultTag.reflection],
      lane: 'Social',
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      updatedAt: DateTime.now().subtract(const Duration(days: 50)),
      wordCount: 78,
      isBookmarked: false,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v8',
      title: 'Deadlift PR and What It Taught Me',
      content:
          'Hit 315 on deadlift today. Three months ago I could barely pull 225. The progression was not linear — had weeks where I stalled or even went backwards. But I kept showing up. The gym is the best metaphor for life: consistent effort beats sporadic intensity. Applied the same principle to my coding — 1 hour of deliberate practice daily instead of marathon weekend sessions.',
      mood: VaultMood.onFire,
      tags: [VaultTag.win, VaultTag.lesson],
      lane: 'Body',
      createdAt: DateTime.now().subtract(const Duration(days: 42)),
      updatedAt: DateTime.now().subtract(const Duration(days: 42)),
      wordCount: 75,
      isBookmarked: true,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v9',
      title: 'Failed My First Technical Interview',
      content:
          'Bombed the system design round at that startup. Froze on the database sharding question. Felt terrible for about an hour, then reviewed my notes and realized I actually knew the concepts but panicked under pressure. Need to practice mock interviews. Going to sign up for Pramp and do two mock interviews per week. Failure is data, not a verdict.',
      mood: VaultMood.struggling,
      tags: [VaultTag.setback, VaultTag.lesson],
      lane: 'Skill',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      wordCount: 72,
      isBookmarked: false,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v10',
      title: 'Sunday Reset and Weekly Review',
      content:
          'Started doing weekly reviews every Sunday. Looked back at what went well, what did not, and what I want to focus on next week. This week: hit the gym 4 out of 5 days, read 50 pages, had two meaningful conversations, shipped one feature at work. Not perfect but trending in the right direction. The compound effect is real — I can see the progress when I zoom out.',
      mood: VaultMood.motivated,
      tags: [VaultTag.reflection, VaultTag.gratitude],
      lane: 'Mind',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      updatedAt: DateTime.now().subtract(const Duration(days: 28)),
      wordCount: 82,
      isBookmarked: false,
      isFavorite: false,
    ),
    VaultEntry(
      id: 'v11',
      title: 'Built My First Open Source Contribution',
      content:
          'Submitted a PR to a popular Flutter package today. Just a small bug fix — a null check that was missing in the text field validation. But it got merged within 4 hours and the maintainer thanked me. 47 stars on the repo. This is how you build a portfolio and give back to the community. Going to aim for one contribution per month.',
      mood: VaultMood.onFire,
      tags: [VaultTag.win, VaultTag.idea],
      lane: 'Skill',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 14)),
      wordCount: 70,
      isBookmarked: true,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v12',
      title: 'Meditation Breakthrough',
      content:
          'Day 30 of consistent meditation. Something shifted today. For the first time I noticed my thoughts without getting pulled into them. It was like watching clouds pass — I could see the anxiety about work, acknowledge it, and let it go. Only lasted about 2 minutes of actual clarity but it felt profound. This practice is rewiring my brain. The science backs it up — grey matter density changes after 8 weeks.',
      mood: VaultMood.motivated,
      tags: [VaultTag.win, VaultTag.reflection],
      lane: 'Mind',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      wordCount: 84,
      isBookmarked: false,
      isFavorite: true,
    ),
    VaultEntry(
      id: 'v13',
      title: 'Hosting My First Game Night',
      content:
          'Invited six people over for board games. Was nervous nobody would show but all six came. Played Codenames and Settlers of Catan until midnight. Everyone said they had a great time and asked when the next one is. Realized I have been waiting for invitations instead of creating them. Being the host gives you social leverage and builds deeper friendships. Planning a monthly game night now.',
      mood: VaultMood.onFire,
      tags: [VaultTag.win, VaultTag.gratitude],
      lane: 'Social',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      wordCount: 77,
      isBookmarked: false,
      isFavorite: false,
    ),
  ];

  final List<VaultInsight> _insights = [
    VaultInsight(
      id: 'i1',
      type: InsightType.pattern,
      title: 'Gym Consistency Drives Overall Mood',
      description:
          'Your entries show a strong correlation between gym attendance and positive mood ratings. Weeks where you trained 4+ times had an average mood of 4.2 vs 2.8 for weeks with fewer sessions. Physical activity appears to be a keystone habit for your overall well-being.',
      relatedEntryIds: ['v1', 'v5', 'v8'],
      generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      iconEmoji: '🏋️',
    ),
    VaultInsight(
      id: 'i2',
      type: InsightType.milestone,
      title: '30-Day Writing Streak Achieved',
      description:
          'You have journaled every day for the past 30 days. Research shows that consistent journaling improves emotional processing, goal clarity, and self-awareness. You are in the top 5% of consistent writers. Keep the momentum going.',
      relatedEntryIds: ['v10', 'v12'],
      generatedAt: DateTime.now().subtract(const Duration(days: 3)),
      iconEmoji: '🔥',
    ),
    VaultInsight(
      id: 'i3',
      type: InsightType.suggestion,
      title: 'Social Lane Needs Attention',
      description:
          'Your Social lane has the fewest entries (3 out of 13). While your recent game night was a big win, consider scheduling one social activity per week. Your highest-mood entries often involve meaningful conversations with others.',
      relatedEntryIds: ['v3', 'v7', 'v13'],
      generatedAt: DateTime.now().subtract(const Duration(days: 2)),
      iconEmoji: '🤝',
    ),
    VaultInsight(
      id: 'i4',
      type: InsightType.streak,
      title: 'Morning Routine Streak: 21 Days',
      description:
          'Your morning routine entries show 21 consecutive days of wake-up, meditation, cold shower, and journaling. This aligns with habit formation research suggesting 21 days builds the neural pathway. Your focus and mood scores have trended upward during this period.',
      relatedEntryIds: ['v6', 'v12'],
      generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      iconEmoji: '🌅',
    ),
  ];

  final List<GrowthPattern> _patterns = [
    GrowthPattern(
      id: 'p1',
      patternName: 'Post-Setback Resilience',
      description:
          'After every setback entry, you write a follow-up entry within 48 hours with a concrete action plan. This bounce-back pattern has accelerated over time — your recovery cycle shortened from 5 days to 2 days over the past 3 months.',
      frequency: 4,
      firstSeen: DateTime.now().subtract(const Duration(days: 85)),
      lastSeen: DateTime.now().subtract(const Duration(days: 14)),
      moodCorrelation: 0.78,
      lane: null,
    ),
    GrowthPattern(
      id: 'p2',
      patternName: 'Cross-Lane Synergy',
      description:
          'Your Mind and Body lanes reinforce each other. Meditation entries are followed by higher-quality gym entries, and gym wins lead to more reflective Mind entries. This virtuous cycle is your strongest growth engine.',
      frequency: 8,
      firstSeen: DateTime.now().subtract(const Duration(days: 72)),
      lastSeen: DateTime.now().subtract(const Duration(days: 5)),
      moodCorrelation: 0.85,
      lane: null,
    ),
    GrowthPattern(
      id: 'p3',
      patternName: 'Skill Compound Effect',
      description:
          'Your Skill lane entries show a clear progression curve — from learning basics to building features to open source contributions. Each skill entry builds on the previous one, and your confidence in technical entries has measurably increased based on language analysis.',
      frequency: 5,
      firstSeen: DateTime.now().subtract(const Duration(days: 72)),
      lastSeen: DateTime.now().subtract(const Duration(days: 14)),
      moodCorrelation: 0.72,
      lane: 'Skill',
    ),
  ];

  List<MoodDataPoint> _generateMoodTimeline() {
    final moods = [
      VaultMood.motivated,
      VaultMood.motivated,
      VaultMood.neutral,
      VaultMood.onFire,
      VaultMood.motivated,
      VaultMood.tired,
      VaultMood.neutral,
      VaultMood.motivated,
      VaultMood.onFire,
      VaultMood.onFire,
      VaultMood.motivated,
      VaultMood.neutral,
      VaultMood.tired,
      VaultMood.struggling,
      VaultMood.neutral,
      VaultMood.motivated,
      VaultMood.motivated,
      VaultMood.onFire,
      VaultMood.motivated,
      VaultMood.neutral,
      VaultMood.motivated,
      VaultMood.onFire,
      VaultMood.onFire,
      VaultMood.motivated,
      VaultMood.tired,
      VaultMood.motivated,
      VaultMood.onFire,
      VaultMood.motivated,
      VaultMood.onFire,
      VaultMood.onFire,
    ];

    final counts = [
      1, 1, 0, 2, 1, 1, 0, 1, 1, 2,
      1, 0, 1, 1, 0, 1, 1, 2, 1, 0,
      1, 1, 2, 1, 1, 1, 1, 1, 2, 1,
    ];

    return List.generate(30, (i) {
      return MoodDataPoint(
        date: DateTime.now().subtract(Duration(days: 29 - i)),
        mood: moods[i],
        entryCount: counts[i],
      );
    });
  }

  @override
  Future<List<VaultEntry>> loadEntries() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List<VaultEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<VaultEntry> loadEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<List<VaultEntry>> searchEntries(String query) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
          e.content.toLowerCase().contains(lowerQuery) ||
          e.tags.any((t) => t.label.toLowerCase().contains(lowerQuery));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<VaultInsight>> loadInsights() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_insights);
  }

  @override
  Future<List<GrowthPattern>> loadPatterns() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_patterns);
  }

  @override
  Future<VaultStats> loadStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final tagCounts = <VaultTag, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final laneCounts = <String, int>{};
    for (final entry in _entries) {
      if (entry.lane != null) {
        laneCounts[entry.lane!] = (laneCounts[entry.lane!] ?? 0) + 1;
      }
    }
    return VaultStats(
      totalEntries: _entries.length,
      totalWords: _entries.fold(0, (sum, e) => sum + e.wordCount),
      currentWritingStreak: 12,
      longestWritingStreak: 30,
      averageMood: 3.7,
      topTags: tagCounts,
      entriesByMonth: {
        '2026-07': 4,
        '2026-08': 5,
        '2026-09': 4,
      },
      entriesByLane: laneCounts,
    );
  }

  @override
  Future<List<MoodDataPoint>> loadMoodTimeline() async {
    await Future.delayed(const Duration(milliseconds: 170));
    return _generateMoodTimeline();
  }

  @override
  Future<VaultEntry> createEntry(VaultEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 220));
    _entries.add(entry);
    return entry;
  }

  @override
  Future<VaultEntry> updateEntry(VaultEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
    }
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 180));
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<VaultEntry> toggleBookmark(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _entries.indexWhere((e) => e.id == id);
    final entry = _entries[index];
    final updated = entry.copyWith(isBookmarked: !entry.isBookmarked);
    _entries[index] = updated;
    return updated;
  }

  @override
  Future<VaultEntry> toggleFavorite(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _entries.indexWhere((e) => e.id == id);
    final entry = _entries[index];
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    _entries[index] = updated;
    return updated;
  }
}

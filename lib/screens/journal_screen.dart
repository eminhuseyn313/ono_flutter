import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  List<Map<String, dynamic>> _entries = [];
  String _selectedMoodFilter = 'All';

  static const _moods = ['😤', '😐', '🙂', '😊', '🔥'];
  static const _lanes = [
    {'id': 'mind', 'emoji': '🧠', 'label': 'Mind'},
    {'id': 'body', 'emoji': '💪', 'label': 'Body'},
    {'id': 'social', 'emoji': '🗣', 'label': 'Social'},
    {'id': 'skill', 'emoji': '📚', 'label': 'Skill'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _loadEntries();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('journal_entries');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list.cast<Map<String, dynamic>>();
      _entries.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_entries', jsonEncode(_entries));
  }

  int get _weekEntries {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _entries.where((e) {
      final d = DateTime.tryParse(e['date'] ?? '');
      return d != null && d.isAfter(weekAgo);
    }).length;
  }

  int get _streak {
    int streak = 0;
    final today = DateTime.now();
    final dates = _entries
        .map((e) => DateTime.tryParse(e['date'] ?? ''))
        .whereType<DateTime>()
        .map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
        .toSet();

    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (dates.contains(key)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _openNewEntry() {
    HapticFeedback.mediumImpact();
    String mood = '🙂';
    String? lane;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: const EdgeInsets.only(top: 80),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'New Reflection',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mood selector
                    const Text(
                      'How are you feeling?',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _moods.map((m) {
                        final selected = mood == m;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => mood = m);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.purple.withValues(alpha: 0.2)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.purple
                                    : AppColors.divider,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(m, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Lane tag
                    const Text(
                      'Tag a lane (optional)',
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _lanes.map((l) {
                        final selected = lane == l['id'];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() =>
                                lane = selected ? null : l['id'] as String);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.purple.withValues(alpha: 0.2)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.purple
                                    : AppColors.divider,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l['emoji']!,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  l['label']!,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.white
                                        : AppColors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Text field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: textController,
                        maxLines: 5,
                        maxLength: 500,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind?',
                          hintStyle: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle:
                              const TextStyle(color: AppColors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (textController.text.trim().isEmpty) return;
                          HapticFeedback.mediumImpact();
                          final entry = {
                            'id': DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            'date': DateTime.now().toIso8601String(),
                            'mood': mood,
                            'text': textController.text.trim(),
                            if (lane != null) 'lane': lane,
                          };
                          _entries.insert(0, entry);
                          _saveEntries();
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Reflection',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedMoodFilter == 'All'
        ? _entries
        : _entries.where((e) => e['mood'] == _selectedMoodFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111214), Color(0xFF0C0D0F), Color(0xFF0E1012)],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Journal',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: _openNewEntry,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.purple,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      color: AppColors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your thoughts & reflections',
                            style: TextStyle(
                                color: AppColors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          // Stats
                          Row(
                            children: [
                              _buildMiniStat(
                                  '📝', '${_entries.length}', 'Total'),
                              const SizedBox(width: 12),
                              _buildMiniStat(
                                  '📅', '$_weekEntries', 'This Week'),
                              const SizedBox(width: 12),
                              _buildMiniStat('🔥', '$_streak', 'Streak'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Mood filter
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildFilterChip('All', null),
                                ..._moods.map((m) => _buildFilterChip(m, m)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Entries
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 0, 24, 120),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildEntryCard(filtered[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? mood) {
    final selected = _selectedMoodFilter == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMoodFilter = label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.2)
              : AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.grey,
            fontSize: mood != null ? 18 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '📖',
            style: TextStyle(
              fontSize: 56,
              color: AppColors.grey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your journal is empty',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to write your first reflection.\nIt only takes a minute.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final date = DateTime.tryParse(entry['date'] ?? '');
    final mood = entry['mood'] ?? '🙂';
    final text = entry['text'] ?? '';
    final lane = entry['lane'] as String?;

    String dateStr = '';
    if (date != null) {
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dateStr = '${months[date.month]} ${date.day}, ${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(mood, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (lane != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _laneColor(lane).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _laneLabel(lane),
                          style: TextStyle(
                            color: _laneColor(lane),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.greyLight,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _laneColor(String lane) {
    switch (lane) {
      case 'mind':
        return AppColors.purple;
      case 'body':
        return AppColors.green;
      case 'social':
        return AppColors.warning;
      case 'skill':
        return AppColors.cyan;
      default:
        return AppColors.purple;
    }
  }

  String _laneLabel(String lane) {
    switch (lane) {
      case 'mind':
        return '🧠 Mind';
      case 'body':
        return '💪 Body';
      case 'social':
        return '🗣 Social';
      case 'skill':
        return '📚 Skill';
      default:
        return lane;
    }
  }
}

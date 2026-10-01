import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/weekly_review.dart';
import '../providers/weekly_review_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/review_goal_card.dart';
import '../widgets/review_lane_card.dart';

class WeeklyReviewFlowScreen extends StatefulWidget {
  const WeeklyReviewFlowScreen({super.key});

  @override
  State<WeeklyReviewFlowScreen> createState() =>
      _WeeklyReviewFlowScreenState();
}

class _WeeklyReviewFlowScreenState extends State<WeeklyReviewFlowScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;
  bool _showCelebration = false;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationOpacity;

  final _reflectionController = TextEditingController();
  final _winTitleController = TextEditingController();
  final _lessonContentController = TextEditingController();
  final _goalTitleController = TextEditingController();

  String _selectedWinLane = 'Mind';
  String _selectedLessonCategory = 'habit';
  String _selectedGoalLane = 'Mind';
  int _selectedGoalPriority = 2;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _celebrationOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeeklyReviewProvider>().loadCurrentReview();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _celebrationController.dispose();
    _reflectionController.dispose();
    _winTitleController.dispose();
    _lessonContentController.dispose();
    _goalTitleController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onCompleteReview() async {
    final provider = context.read<WeeklyReviewProvider>();
    await provider.completeReview();

    if (!mounted) return;

    setState(() => _showCelebration = true);
    _celebrationController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showAddWinDialog() {
    _winTitleController.clear();
    _selectedWinLane = 'Mind';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildBottomSheet(
          title: 'Add a Win',
          children: [
            _buildTextField(
              controller: _winTitleController,
              hint: 'What did you accomplish?',
            ),
            const SizedBox(height: 16),
            _buildLaneSelector(
              selected: _selectedWinLane,
              onChanged: (lane) => setSheetState(() => _selectedWinLane = lane),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              label: 'Add Win',
              onTap: () {
                if (_winTitleController.text.trim().isNotEmpty) {
                  context.read<WeeklyReviewProvider>().addWin(
                        _winTitleController.text.trim(),
                        _selectedWinLane,
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLessonDialog() {
    _lessonContentController.clear();
    _selectedLessonCategory = 'habit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildBottomSheet(
          title: 'Add a Lesson',
          children: [
            _buildTextField(
              controller: _lessonContentController,
              hint: 'What did you learn this week?',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(
              selected: _selectedLessonCategory,
              onChanged: (cat) =>
                  setSheetState(() => _selectedLessonCategory = cat),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              label: 'Add Lesson',
              onTap: () {
                if (_lessonContentController.text.trim().isNotEmpty) {
                  context.read<WeeklyReviewProvider>().addLesson(
                        _lessonContentController.text.trim(),
                        _selectedLessonCategory,
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    _goalTitleController.clear();
    _selectedGoalLane = 'Mind';
    _selectedGoalPriority = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildBottomSheet(
          title: 'Add a Goal',
          children: [
            _buildTextField(
              controller: _goalTitleController,
              hint: 'What do you want to achieve next week?',
            ),
            const SizedBox(height: 16),
            _buildLaneSelector(
              selected: _selectedGoalLane,
              onChanged: (lane) =>
                  setSheetState(() => _selectedGoalLane = lane),
            ),
            const SizedBox(height: 16),
            _buildPrioritySelector(
              selected: _selectedGoalPriority,
              onChanged: (p) =>
                  setSheetState(() => _selectedGoalPriority = p),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              label: 'Add Goal',
              onTap: () {
                if (_goalTitleController.text.trim().isNotEmpty) {
                  context.read<WeeklyReviewProvider>().addGoal(
                        _goalTitleController.text.trim(),
                        _selectedGoalLane,
                        _selectedGoalPriority,
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goToStep(_currentStep - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<WeeklyReviewProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.currentReview == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.purple,
                ),
              );
            }

            if (provider.error != null && provider.currentReview == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load review',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => provider.loadCurrentReview(),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.currentReview == null) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildProgressBar(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentStep = index);
                          },
                          children: [
                            _buildMoodAndWinsStep(provider),
                            _buildLaneScoresStep(provider),
                            _buildLessonsStep(provider),
                            _buildGoalsStep(provider),
                          ],
                        ),
                      ),
                      _buildNavigationBar(),
                    ],
                  ),
                ),
                if (_showCelebration) _buildCelebrationOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep == 0) {
                Navigator.of(context).pop();
              } else {
                _goToStep(_currentStep - 1);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Sep 15 - 21, 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Step ${_currentStep + 1}/$_totalSteps',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.purpleSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.purple : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: () => _goToStep(_currentStep - 1),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: GestureDetector(
              onTap: () {
                if (_currentStep < _totalSteps - 1) {
                  _goToStep(_currentStep + 1);
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: _currentStep < _totalSteps - 1
                      ? const LinearGradient(
                          colors: [AppColors.purple, AppColors.purpleDark],
                        )
                      : null,
                  color: _currentStep >= _totalSteps - 1
                      ? AppColors.card
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _currentStep < _totalSteps - 1 ? 'Next' : '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────── Step 1: Mood & Wins ──────────

  Widget _buildMoodAndWinsStep(WeeklyReviewProvider provider) {
    final review = provider.currentReview!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'How was your week?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildMoodSelector(review.mood, provider),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Wins This Week',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            GestureDetector(
              onTap: _showAddWinDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: AppColors.purple, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Win',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...review.wins.map((win) => _buildWinCard(win, provider)),
        if (review.wins.isEmpty)
          _buildEmptyState('No wins yet. Add your first win!'),
      ],
    );
  }

  Widget _buildMoodSelector(ReviewMood currentMood, WeeklyReviewProvider provider) {
    final moods = [
      (ReviewMood.terrible, '😫', 'Terrible'),
      (ReviewMood.bad, '😔', 'Bad'),
      (ReviewMood.neutral, '😐', 'Neutral'),
      (ReviewMood.good, '😊', 'Good'),
      (ReviewMood.amazing, '🤩', 'Amazing'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: moods.map((entry) {
          final isSelected = entry.$1 == currentMood;
          return GestureDetector(
            onTap: () => provider.updateMood(entry.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purple
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    entry.$2,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.$3,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.purpleSoft
                          : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWinCard(WeeklyWin win, WeeklyReviewProvider provider) {
    final laneColor = _laneColor(win.lane);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: laneColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    win.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: laneColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          win.lane,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: laneColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${win.date.month}/${win.date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => provider.removeWin(win.id),
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.grey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Step 2: Lane Scores ──────────

  Widget _buildLaneScoresStep(WeeklyReviewProvider provider) {
    final review = provider.currentReview!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Rate Your Lanes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How did you do in each area this week?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _DiamondChartPainter(
              scores: review.laneScores,
            ),
            size: const Size(double.infinity, 220),
          ),
        ),
        const SizedBox(height: 20),
        ...review.laneScores.map(
          (score) => ReviewLaneCard(
            laneScore: score,
            onScoreChanged: (value) =>
                provider.updateLaneScore(score.laneName, value),
          ),
        ),
      ],
    );
  }

  // ────────── Step 3: Lessons & Reflection ──────────

  Widget _buildLessonsStep(WeeklyReviewProvider provider) {
    final review = provider.currentReview!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'What Did You Learn?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            GestureDetector(
              onTap: _showAddLessonDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: AppColors.cyan, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Lesson',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...review.lessons.map((lesson) => _buildLessonCard(lesson)),
        if (review.lessons.isEmpty)
          _buildEmptyState('No lessons yet. What did you learn?'),
        const SizedBox(height: 28),
        Text(
          'Weekly Reflection',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Free-form thoughts about your week',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _reflectionController,
            maxLines: 5,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              hintText: 'What stood out to you this week? What would you do differently?',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.grey.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (text) => provider.setReflection(text),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(WeeklyLesson lesson) {
    final categoryColors = {
      'mindset': AppColors.purple,
      'habit': AppColors.green,
      'relationship': AppColors.cyan,
      'skill': AppColors.warning,
    };
    final color = categoryColors[lesson.category] ?? AppColors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lesson.category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                if (lesson.isActionable) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Actionable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────── Step 4: Goals & Complete ──────────

  Widget _buildGoalsStep(WeeklyReviewProvider provider) {
    final review = provider.currentReview!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Next Week's Goals",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            GestureDetector(
              onTap: _showAddGoalDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: AppColors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Add Goal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...review.nextWeekGoals.map(
          (goal) => ReviewGoalCard(
            goal: goal,
            onCompletionChanged: (value) {
              // Toggle is visual only in review context
            },
            onDismissed: () {
              final updatedGoals = review.nextWeekGoals
                  .where((g) => g.id != goal.id)
                  .toList();
              final updatedReview =
                  review.copyWith(nextWeekGoals: updatedGoals);
              provider.setReflection(
                  updatedReview.reflectionNote ?? '');
            },
          ),
        ),
        if (review.nextWeekGoals.isEmpty)
          _buildEmptyState('No goals yet. Set your targets!'),
        const SizedBox(height: 28),
        Text(
          'Overall Rating',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How would you rate this week overall?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildStarRating(review.overallRating, provider),
        const SizedBox(height: 28),
        _buildSummaryStats(review),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: provider.isLoading ? null : _onCompleteReview,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Complete Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStarRating(int currentRating, WeeklyReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          final isFilled = starIndex <= currentRating;
          return GestureDetector(
            onTap: () => provider.setOverallRating(starIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.warning : AppColors.grey,
                size: 40,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryStats(WeeklyReviewData review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${review.wins.length}',
            'Wins',
            AppColors.green,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _buildStatItem(
            '${review.lessons.length}',
            'Lessons',
            AppColors.cyan,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _buildStatItem(
            review.overallRating > 0 ? '${review.overallRating}/5' : '-',
            'Rating',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  // ────────── Celebration Overlay ──────────

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Container(
          color: AppColors.background.withValues(
            alpha: 0.9 * _celebrationOpacity.value,
          ),
          child: Center(
            child: Opacity(
              opacity: _celebrationOpacity.value,
              child: Transform.scale(
                scale: _celebrationScale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple,
                            AppColors.cyan,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.celebration_outlined,
                        color: AppColors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Week Reviewed!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep the momentum going',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────── Shared Helpers ──────────

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
      ),
    );
  }

  Color _laneColor(String lane) {
    switch (lane) {
      case 'Mind':
        return AppColors.purple;
      case 'Body':
        return AppColors.green;
      case 'Social':
        return AppColors.cyan;
      case 'Skill':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildBottomSheet({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.grey.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildLaneSelector({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final lanes = ['Mind', 'Body', 'Social', 'Skill'];
    return Wrap(
      spacing: 8,
      children: lanes.map((lane) {
        final isSelected = lane == selected;
        final color = _laneColor(lane);
        return GestureDetector(
          onTap: () => onChanged(lane),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
              ),
            ),
            child: Text(
              lane,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppColors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final categories = ['mindset', 'habit', 'relationship', 'skill'];
    final colors = {
      'mindset': AppColors.purple,
      'habit': AppColors.green,
      'relationship': AppColors.cyan,
      'skill': AppColors.warning,
    };

    return Wrap(
      spacing: 8,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        final color = colors[cat]!;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppColors.divider,
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppColors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector({
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    final priorities = [
      (1, 'High', const Color(0xFFEF4444)),
      (2, 'Medium', AppColors.warning),
      (3, 'Low', AppColors.grey),
    ];

    return Wrap(
      spacing: 8,
      children: priorities.map((entry) {
        final isSelected = entry.$1 == selected;
        return GestureDetector(
          onTap: () => onChanged(entry.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? entry.$3.withValues(alpha: 0.2)
                  : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? entry.$3 : AppColors.divider,
              ),
            ),
            child: Text(
              entry.$2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? entry.$3 : AppColors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.purple, AppColors.purpleDark],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ────────── Diamond Chart CustomPainter ──────────

class _DiamondChartPainter extends CustomPainter {
  final List<LaneReviewScore> scores;

  _DiamondChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 4) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 24;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF202B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 5; i++) {
      final r = maxRadius * (i / 5);
      final gridPath = Path();
      for (int j = 0; j < 4; j++) {
        final angle = (j * pi / 2) - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (j == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // Draw axis lines
    for (int j = 0; j < 4; j++) {
      final angle = (j * pi / 2) - pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + maxRadius * cos(angle),
          center.dy + maxRadius * sin(angle),
        ),
        gridPaint,
      );
    }

    // Draw score polygon
    final scorePath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) - pi / 2;
      final r = maxRadius * (scores[i].score / 10);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        scorePath.moveTo(x, y);
      } else {
        scorePath.lineTo(x, y);
      }
    }
    scorePath.close();

    // Fill
    final fillPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(scorePath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(scorePath, strokePaint);

    // Draw dots and labels
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2) - pi / 2;
      final r = maxRadius * (scores[i].score / 10);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      // Dot
      final dotPaint = Paint()
        ..color = Color(scores[i].colorValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      // Label
      final labelX = center.dx + (maxRadius + 16) * cos(angle);
      final labelY = center.dy + (maxRadius + 16) * sin(angle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: scores[i].laneName,
          style: TextStyle(
            color: Color(scores[i].colorValue),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondChartPainter oldDelegate) {
    return true;
  }
}

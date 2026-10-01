import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/daily_checkin.dart';
import '../providers/daily_checkin_provider.dart';
import '../widgets/mood_selector.dart';
import '../widgets/energy_slider.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final _gratitudeController = TextEditingController();
  final _intentionController = TextEditingController();
  final _reflectionController = TextEditingController();
  bool _isMorningFlow = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DailyCheckinProvider>();
      provider.loadToday();
      provider.loadHistory();
      _isMorningFlow = provider.suggestedTime == CheckinTime.morning;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gratitudeController.dispose();
    _intentionController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  int get _totalPages => _isMorningFlow ? 4 : 3;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _previousPage();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () {
              if (_currentPage > 0) {
                _previousPage();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Consumer<DailyCheckinProvider>(
            builder: (context, provider, _) {
              return Text(
                _isMorningFlow ? 'Morning Check-in' : 'Evening Check-in',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              );
            },
          ),
          actions: [
            // Toggle morning/evening
            Consumer<DailyCheckinProvider>(
              builder: (context, provider, _) {
                if (provider.isMorningComplete && _isMorningFlow) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _isMorningFlow = false;
                        _currentPage = 0;
                        _pageController.jumpToPage(0);
                      });
                    },
                    child: Text(
                      'Evening',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.purple
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: _isMorningFlow
                    ? [
                        _buildMoodEnergyPage(),
                        _buildGratitudePage(),
                        _buildIntentionFocusPage(),
                        _buildMorningSummaryPage(),
                      ]
                    : [
                        _buildEveningMoodPage(),
                        _buildReflectionRatingPage(),
                        _buildEveningSummaryPage(),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ MORNING PAGES ============

  Widget _buildMoodEnergyPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Good morning! ☀️',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s set the tone for your day.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Mood selector
              MoodSelector(
                selectedMood: provider.selectedMood,
                onMoodSelected: (mood) => provider.setMood(mood),
              ),

              const SizedBox(height: 28),

              // Energy slider
              EnergySlider(
                value: provider.energyLevel,
                onChanged: (val) => provider.setEnergy(val),
              ),

              const SizedBox(height: 32),

              // Next button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.selectedMood != null ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.cardLight,
                    disabledForegroundColor: AppColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGratitudePage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you grateful for?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Name 1-3 things. Gratitude rewires your brain.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Gratitude input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gratitudeController,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'I\'m grateful for...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          provider.addGratitude(val);
                          _gratitudeController.clear();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppColors.purple, size: 28),
                      onPressed: () {
                        provider.addGratitude(_gratitudeController.text);
                        _gratitudeController.clear();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gratitude list
              ...List.generate(provider.gratitudes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.favorite,
                            color: AppColors.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            provider.gratitudes[index],
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => provider.removeGratitude(index),
                          child: Icon(Icons.close,
                              color: AppColors.grey, size: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              if (provider.gratitudes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border,
                          color: AppColors.grey, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Add something you\'re grateful for',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntentionFocusPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set your intention',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What will you focus on today?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Intention text field
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _intentionController,
                  maxLines: 3,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Today, I will focus on...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (val) => provider.setIntention(val),
                ),
              ),

              const SizedBox(height: 28),

              // Primary focus lane
              Text(
                'Primary Lane Focus',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Which area will you prioritize?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: FocusArea.values.map((focus) {
                  final isSelected = provider.primaryFocus == focus;
                  final color = Color(focus.colorValue);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: focus != FocusArea.skill ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => provider.setFocus(focus),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : AppColors.card.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                IconData(focus.iconCodePoint,
                                    fontFamily: 'MaterialIcons'),
                                color: isSelected ? color : AppColors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                focus.label,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? color
                                      : AppColors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMorningSummaryPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        final mood = provider.selectedMood;
        final moodColor = mood != null ? Color(mood.colorValue) : AppColors.grey;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Morning Summary',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review and lock in your morning check-in.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Mood & Energy summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: moodColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(mood?.emoji ?? '?', style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feeling ${mood?.label ?? 'Unknown'}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Energy: ${(provider.energyLevel * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gratitudes summary
              if (provider.gratitudes.isNotEmpty) ...[
                _summarySection(
                  'Gratitudes',
                  Icons.favorite,
                  AppColors.green,
                  provider.gratitudes
                      .map((g) => '• $g')
                      .join('\n'),
                ),
                const SizedBox(height: 12),
              ],

              // Intention
              if (provider.intention.isNotEmpty) ...[
                _summarySection(
                  'Intention',
                  Icons.flag,
                  AppColors.cyan,
                  provider.intention,
                ),
                const SizedBox(height: 12),
              ],

              // Focus lane
              if (provider.primaryFocus != null) ...[
                _summarySection(
                  'Focus Lane',
                  IconData(provider.primaryFocus!.iconCodePoint,
                      fontFamily: 'MaterialIcons'),
                  Color(provider.primaryFocus!.colorValue),
                  provider.primaryFocus!.label,
                ),
                const SizedBox(height: 12),
              ],

              // History stats
              if (provider.history != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('Morning Streak',
                          '${provider.history!.morningStreak}', AppColors.warning),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      _miniStat('Avg Mood',
                          provider.history!.averageMood.toStringAsFixed(1),
                          AppColors.green),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      _miniStat('Total',
                          '${provider.history!.totalCheckins}', AppColors.purple),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.completeMorning();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.cardLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Complete Morning Check-in',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ EVENING PAGES ============

  Widget _buildEveningMoodPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening! 🌙',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Time to reflect on your day.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              MoodSelector(
                selectedMood: provider.eveningMood,
                onMoodSelected: (mood) => provider.setEveningMood(mood),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      provider.eveningMood != null ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.cardLight,
                    disabledForegroundColor: AppColors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReflectionRatingPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reflect on your day',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What stood out? What did you learn?',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _reflectionController,
                  maxLines: 5,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Today I learned... I\'m proud of... Tomorrow I want to...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (val) => provider.setEveningReflection(val),
                ),
              ),

              const SizedBox(height: 28),

              // Day rating
              Text(
                'Rate your day',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Text(
                      provider.dayRating.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ratingLabel(provider.dayRating),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        final isFilled = provider.dayRating >= starValue;
                        final isHalf = !isFilled &&
                            provider.dayRating >= starValue - 0.5;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => provider.setDayRating(starValue),
                            child: Icon(
                              isHalf
                                  ? Icons.star_half
                                  : isFilled
                                      ? Icons.star
                                      : Icons.star_border,
                              color: isFilled || isHalf
                                  ? AppColors.warning
                                  : AppColors.grey,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEveningSummaryPage() {
    return Consumer<DailyCheckinProvider>(
      builder: (context, provider, _) {
        final mood = provider.eveningMood;
        final moodColor = mood != null ? Color(mood.colorValue) : AppColors.grey;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evening Summary',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Great work reflecting today!',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Evening mood
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: moodColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(mood?.emoji ?? '?', style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feeling ${mood?.label ?? 'Unknown'}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Day rating: ${provider.dayRating.toStringAsFixed(1)} / 5.0',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (provider.eveningReflection.isNotEmpty) ...[
                _summarySection(
                  'Reflection',
                  Icons.edit_note,
                  AppColors.purple,
                  provider.eveningReflection,
                ),
                const SizedBox(height: 12),
              ],

              // History stats
              if (provider.history != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('Evening Streak',
                          '${provider.history!.eveningStreak}', AppColors.cyan),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      _miniStat('Avg Mood',
                          provider.history!.averageMood.toStringAsFixed(1),
                          AppColors.green),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      _miniStat('Total',
                          '${provider.history!.totalCheckins}', AppColors.purple),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          await provider.completeEvening();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.cardLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Complete Evening Check-in',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ HELPERS ============

  Widget _summarySection(
      String title, IconData icon, Color color, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _ratingLabel(double rating) {
    if (rating <= 1) return 'Rough day';
    if (rating <= 2) return 'Below average';
    if (rating <= 3) return 'Decent';
    if (rating <= 4) return 'Good day';
    return 'Amazing day!';
  }
}

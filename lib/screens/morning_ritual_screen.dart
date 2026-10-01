import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// 5-step morning ritual: Gratitude → Intention → Breathwork (4-7-8)
/// → Visualization countdown → Commitment chips.
class MorningRitualScreen extends StatefulWidget {
  const MorningRitualScreen({super.key});

  @override
  State<MorningRitualScreen> createState() => _MorningRitualScreenState();
}

class _MorningRitualScreenState extends State<MorningRitualScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Gratitude
  final _gratitudeControllers = List.generate(3, (_) => TextEditingController());

  // Step 2: Intention
  final _intentionController = TextEditingController();

  // Step 3: Breathwork 4-7-8
  String _breathPhase = 'Ready';
  int _breathCount = 0;
  int _breathSeconds = 0;
  Timer? _breathTimer;
  bool _breathActive = false;

  // Step 4: Visualization
  int _vizSeconds = 60;
  Timer? _vizTimer;
  bool _vizActive = false;

  // Step 5: Commitments
  final Set<String> _selectedCommitments = {};
  static const _commitments = [
    '💪 Work out',
    '📖 Read 20 pages',
    '🧘 Meditate',
    '📝 Journal tonight',
    '🥗 Eat clean',
    '🚫 No phone first hour',
    '💧 Drink 3L water',
    '🎯 Deep work 2h',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _gratitudeControllers) {
      c.dispose();
    }
    _intentionController.dispose();
    _breathTimer?.cancel();
    _vizTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      HapticFeedback.mediumImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeRitual() async {
    HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setBool('morning_ritual_$key', true);

    // Save gratitude entries
    final gratitudes = _gratitudeControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (gratitudes.isNotEmpty) {
      await prefs.setStringList('gratitude_$key', gratitudes);
    }

    // Save intention
    if (_intentionController.text.trim().isNotEmpty) {
      await prefs.setString('intention_$key', _intentionController.text.trim());
    }

    if (mounted) {
      Navigator.of(context).pop(true); // true = completed
    }
  }

  // ── Breathwork logic ──
  void _startBreathwork() {
    setState(() {
      _breathActive = true;
      _breathCount = 0;
      _breathPhase = 'Inhale';
      _breathSeconds = 4;
    });

    _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _breathSeconds--;
        if (_breathSeconds <= 0) {
          if (_breathPhase == 'Inhale') {
            _breathPhase = 'Hold';
            _breathSeconds = 7;
          } else if (_breathPhase == 'Hold') {
            _breathPhase = 'Exhale';
            _breathSeconds = 8;
          } else {
            _breathCount++;
            if (_breathCount >= 4) {
              _breathPhase = 'Done';
              _breathActive = false;
              timer.cancel();
              HapticFeedback.mediumImpact();
            } else {
              _breathPhase = 'Inhale';
              _breathSeconds = 4;
            }
          }
        }
      });
    });
  }

  // ── Visualization timer ──
  void _startVisualization() {
    setState(() {
      _vizActive = true;
      _vizSeconds = 60;
    });
    _vizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _vizSeconds--;
        if (_vizSeconds <= 0) {
          _vizActive = false;
          timer.cancel();
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111214), Color(0xFF0C0D0F), Color(0xFF0D0B1A)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildProgress(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildGratitudePage(),
                      _buildIntentionPage(),
                      _buildBreathworkPage(),
                      _buildVisualizationPage(),
                      _buildCommitmentPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.greyLight, size: 16),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Morning Ritual',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          '${_currentPage + 1}/5',
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(5, (i) {
        final isActive = i <= _currentPage;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? AppColors.purple
                  : AppColors.card.withValues(alpha: 0.6),
            ),
          ),
        );
      }),
    );
  }

  // ── Step 1: Gratitude ──
  Widget _buildGratitudePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🙏', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Three things you\'re\ngrateful for',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your day grounded in appreciation.',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          for (int i = 0; i < 3; i++) ...[
            _RitualTextField(
              controller: _gratitudeControllers[i],
              hint: i == 0
                  ? 'I\'m grateful for...'
                  : i == 1
                      ? 'I appreciate...'
                      : 'I\'m thankful that...',
              index: i + 1,
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 24),
          _buildNavButtons(canProceed: true),
        ],
      ),
    );
  }

  // ── Step 2: Intention ──
  Widget _buildIntentionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Set your intention',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to accomplish today?',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _RitualTextField(
            controller: _intentionController,
            hint: 'Today I will...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),
          _buildNavButtons(canProceed: true),
        ],
      ),
    );
  }

  // ── Step 3: Breathwork ──
  Widget _buildBreathworkPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌬️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            '4-7-8 Breathwork',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inhale 4s → Hold 7s → Exhale 8s.\nFour cycles to center your mind.',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: _breathPhase == 'Inhale'
                      ? 200
                      : _breathPhase == 'Exhale'
                          ? 120
                          : 160,
                  height: _breathPhase == 'Inhale'
                      ? 200
                      : _breathPhase == 'Exhale'
                          ? 120
                          : 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.3),
                        AppColors.purpleDark.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _breathActive ? '$_breathSeconds' : '',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _breathPhase,
                          style: TextStyle(
                            color: AppColors.cyan.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_breathActive)
            Center(
              child: Text(
                'Cycle ${_breathCount + 1} of 4',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 28),
          if (!_breathActive && _breathPhase != 'Done')
            Center(
              child: GestureDetector(
                onTap: _startBreathwork,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC8894A), Color(0xFFA86D35)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Start Breathing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildNavButtons(canProceed: true),
        ],
      ),
    );
  }

  // ── Step 4: Visualization ──
  Widget _buildVisualizationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧘', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Visualize your\nbest self',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Close your eyes. See yourself succeeding today.\n60 seconds of focused visualization.',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text(
                  _vizActive
                      ? '${_vizSeconds}s'
                      : _vizSeconds <= 0
                          ? 'Done ✓'
                          : '60s',
                  style: TextStyle(
                    color: _vizSeconds <= 0
                        ? AppColors.green
                        : AppColors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_vizActive && _vizSeconds > 0)
                  GestureDetector(
                    onTap: _startVisualization,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC8894A), Color(0xFFA86D35)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Begin Visualization',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildNavButtons(canProceed: true),
        ],
      ),
    );
  }

  // ── Step 5: Commitments ──
  Widget _buildCommitmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Lock in your\ncommitments',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose what you\'ll hold yourself to today.',
            style: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commitments.map((c) {
              final selected = _selectedCommitments.contains(c);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedCommitments.remove(c);
                    } else {
                      _selectedCommitments.add(c);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.purple.withValues(alpha: 0.15)
                        : AppColors.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.purple.withValues(alpha: 0.5)
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      color: selected ? AppColors.purpleSoft : AppColors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Complete button
          GestureDetector(
            onTap: _completeRitual,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC8894A), Color(0xFFA86D35), Color(0xFFA86D35)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Complete Ritual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNavButtons({required bool canProceed}) {
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: GestureDetector(
              onTap: _prevPage,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 12),
        if (_currentPage < 4)
          Expanded(
            child: GestureDetector(
              onTap: canProceed ? _nextPage : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8894A), Color(0xFFA86D35)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RitualTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? index;
  final int maxLines;

  const _RitualTextField({
    required this.controller,
    required this.hint,
    this.index,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.white, fontSize: 15),
            cursorColor: AppColors.purple,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.5),
              ),
              prefixIcon: index != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Text(
                        '$index.',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

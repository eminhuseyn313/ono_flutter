import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ono_button.dart';
import '../models/models.dart';
import '../providers/user_profile_provider.dart';

class AssessmentScreen extends StatefulWidget {
  final String archetypeId;
  const AssessmentScreen({super.key, required this.archetypeId});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  final questions = AppData.questions;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentIndex < questions.length - 1) {
      _animController.reset();
      setState(() => _currentIndex++);
      _animController.forward();
    } else {
      // Store answers in provider before navigating
      context.read<UserProfileProvider>().setAssessmentAnswers(_answers);
      context.go(
        '/loading/${widget.archetypeId}',
        extra: _answers,
      );
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: _currentIndex > 0
                        ? _prevQuestion
                        : () => context.go('/archetype'),
                    child: const Icon(Icons.arrow_back_ios,
                        color: AppColors.grey, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of ${questions.length}',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.card,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.purple),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Question
              SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 2 of 3 tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purpleDark.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Step 2 of 3',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      q.question,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Options
                    ...q.options.asMap().entries.map((entry) {
                      final i = entry.key;
                      final opt = entry.value;
                      final selected = _answers[_currentIndex] == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _answers[_currentIndex] = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.purple.withValues(alpha: 0.15)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.purple
                                    : AppColors.divider,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.white
                                          : AppColors.greyLight,
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle,
                                      color: AppColors.purple, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Spacer(),
              OnoButton(
                label: _currentIndex < questions.length - 1
                    ? 'Next question'
                    : 'Build my blueprint',
                onPressed:
                    _answers[_currentIndex] == null ? null : _nextQuestion,
                icon: _currentIndex < questions.length - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.auto_awesome,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/forge.dart';
import '../providers/forge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/forge_block_widget.dart';

/// Interactive lesson viewer — walks through ForgeBlocks one at a time
/// with a PageView, then marks the lesson complete on finish.
class ForgeLessonScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const ForgeLessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<ForgeLessonScreen> createState() => _ForgeLessonScreenState();
}

class _ForgeLessonScreenState extends State<ForgeLessonScreen> {
  late PageController _pageController;
  int _currentBlock = 0;
  bool _finished = false;

  ForgeLesson? _lesson;
  ForgeCourse? _course;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLesson());
  }

  void _loadLesson() {
    final provider = context.read<ForgeProvider>();
    final course =
        provider.allCourses.where((c) => c.id == widget.courseId).firstOrNull;
    if (course == null) return;

    final lesson =
        course.lessons.where((l) => l.id == widget.lessonId).firstOrNull;
    if (lesson == null) return;

    setState(() {
      _course = course;
      _lesson = lesson;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_lesson == null) return;

    if (_currentBlock < _lesson!.blocks.length - 1) {
      setState(() => _currentBlock++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeLesson();
    }
  }

  Future<void> _completeLesson() async {
    final provider = context.read<ForgeProvider>();
    await provider.completeLesson(widget.courseId, widget.lessonId);
    if (!mounted) return;
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _lesson?.title ?? 'Lesson',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_lesson != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentBlock + 1}/${_lesson!.blocks.length}',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _lesson == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _finished
              ? _buildCompleted()
              : _buildLessonContent(),
    );
  }

  Widget _buildLessonContent() {
    final blocks = _lesson!.blocks;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((_currentBlock + 1) / blocks.length),
              backgroundColor: AppColors.divider,
              color: AppColors.purple,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Block content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: blocks.length,
            itemBuilder: (_, i) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ForgeBlockWidget(
                block: blocks[i],
                onAnswer: (_) {},
              ),
            ),
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _currentBlock < _lesson!.blocks.length - 1
                    ? 'Continue'
                    : 'Complete Lesson ✓',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Lesson Complete!',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lesson!.title,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
            if (_course != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_course!.completedCount}/${_course!.lessonCount} lessons done in "${_course!.title}"',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Back to Course',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

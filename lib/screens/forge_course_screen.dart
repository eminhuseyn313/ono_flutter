import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/forge.dart';
import '../providers/forge_provider.dart';
import '../theme/app_theme.dart';

/// Lesson list for a single ForgeCourse.
class ForgeCourseScreen extends StatelessWidget {
  final String courseId;

  const ForgeCourseScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ForgeProvider>(
        builder: (context, provider, _) {
          final course = provider.allCourses
              .where((c) => c.id == courseId)
              .firstOrNull;

          if (course == null) {
            return Center(
              child: Text(
                'Course not found.',
                style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6)),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // ── Course header ──
              _buildHeader(course),
              const SizedBox(height: 24),

              // ── Progress ──
              _buildProgress(course),
              const SizedBox(height: 24),

              // ── Lessons ──
              Text(
                'LESSONS',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(course.lessons.length, (i) {
                final lesson = course.lessons[i];
                return _buildLessonTile(context, course, lesson, i);
              }),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ForgeCourse course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(course.roleModelEmoji,
                style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.roleModelName,
                    style: TextStyle(
                      color: AppColors.purple.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          course.description,
          style: TextStyle(
            color: AppColors.grey.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(ForgeCourse course) {
    final laneColor = _laneColor(course.lane);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _laneLabel(course.lane),
                style: TextStyle(
                  color: laneColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${course.completedCount}/${course.lessonCount} lessons',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.totalMinutes} min',
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: course.progress,
              backgroundColor: AppColors.divider,
              color: course.isComplete ? AppColors.green : laneColor,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(
      BuildContext context, ForgeCourse course, ForgeLesson lesson, int index) {
    final done = lesson.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () =>
            context.push('/forge/${course.id}/lesson/${lesson.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: done
                ? AppColors.green.withValues(alpha: 0.05)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done
                  ? AppColors.green.withValues(alpha: 0.25)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              // Number or check
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.green.withValues(alpha: 0.15)
                      : AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check,
                          color: AppColors.green, size: 18)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        color: done
                            ? AppColors.grey.withValues(alpha: 0.6)
                            : AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${lesson.estimatedMinutes} min · ${lesson.blocks.length} blocks',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.grey.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _laneColor(String lane) => switch (lane) {
        'mind' => AppColors.purple,
        'body' => AppColors.green,
        'social' => AppColors.cyan,
        'skill' => AppColors.warning,
        _ => AppColors.grey,
      };

  String _laneLabel(String lane) => switch (lane) {
        'mind' => '🧠 Mind',
        'body' => '💪 Body',
        'social' => '👥 Social',
        'skill' => '🎯 Skill',
        _ => lane,
      };
}

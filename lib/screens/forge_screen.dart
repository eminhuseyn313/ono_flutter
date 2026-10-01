import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/forge.dart';
import '../providers/forge_provider.dart';
import '../theme/app_theme.dart';

class ForgeScreen extends StatefulWidget {
  const ForgeScreen({super.key});

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForgeProvider>().load();
    });
  }

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
        title: const Text(
          'The Forge',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<ForgeProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.allCourses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // ── Progress hero ──
              _buildProgressHero(provider),
              const SizedBox(height: 20),

              // ── Lane filter chips ──
              _buildLaneFilters(provider),
              const SizedBox(height: 16),

              // ── Role model filter ──
              _buildRoleModelFilters(provider),
              const SizedBox(height: 20),

              // ── Course list ──
              ...provider.courses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCourseCard(c),
                  )),

              if (provider.courses.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No courses match your filters.',
                      style: TextStyle(
                        color: AppColors.grey.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHero(ForgeProvider provider) {
    final progress = provider.progress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚒️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Skill Building',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${provider.totalLessonsCompleted}/${provider.totalLessons}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.lessonProgress,
                backgroundColor: AppColors.divider,
                color: AppColors.warning,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.totalMinutesSpent} min spent · '
              '${progress.completedCourses} courses done',
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLaneFilters(ForgeProvider provider) {
    const lanes = [
      (null, 'All', '📋'),
      ('mind', 'Mind', '🧠'),
      ('body', 'Body', '💪'),
      ('social', 'Social', '👥'),
      ('skill', 'Skill', '🎯'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: lanes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (lane, label, emoji) = lanes[i];
          final selected = provider.selectedLane == lane;
          return GestureDetector(
            onTap: () => provider.filterByLane(lane),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.purple.withValues(alpha: 0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.purple
                      : AppColors.divider,
                ),
              ),
              child: Center(
                child: Text(
                  '$emoji $label',
                  style: TextStyle(
                    color: selected ? AppColors.purple : AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleModelFilters(ForgeProvider provider) {
    final rms = provider.roleModels;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rms.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            final selected = provider.selectedRoleModel == null;
            return GestureDetector(
              onTap: () => provider.filterByRoleModel(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.cyan.withValues(alpha: 0.2)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? AppColors.cyan : AppColors.divider,
                  ),
                ),
                child: Center(
                  child: Text(
                    'All Mentors',
                    style: TextStyle(
                      color: selected ? AppColors.cyan : AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final rm = rms[i - 1];
          final selected = provider.selectedRoleModel == rm.id;
          return GestureDetector(
            onTap: () => provider.filterByRoleModel(rm.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.cyan.withValues(alpha: 0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.cyan : AppColors.divider,
                ),
              ),
              child: Center(
                child: Text(
                  '${rm.emoji} ${rm.name.split(' ').last}',
                  style: TextStyle(
                    color: selected ? AppColors.cyan : AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(ForgeCourse course) {
    final laneColor = _laneColor(course.lane);

    return GestureDetector(
      onTap: () => context.push('/forge/${course.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: course.isComplete
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(course.roleModelEmoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course.roleModelName,
                        style: TextStyle(
                          color: AppColors.grey.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lane badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: laneColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _laneLabel(course.lane),
                    style: TextStyle(
                      color: laneColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              course.description,
              style: TextStyle(
                color: AppColors.grey.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Progress
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      backgroundColor: AppColors.divider,
                      color: course.isComplete ? AppColors.green : laneColor,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${course.completedCount}/${course.lessonCount}',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.timer_outlined,
                  color: AppColors.grey.withValues(alpha: 0.4),
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  '${course.totalMinutes}m',
                  style: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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

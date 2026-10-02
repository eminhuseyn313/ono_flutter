// screens/trending_screen.dart — Trending v2 (automated pipeline)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trending.dart';
import '../providers/trending_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/trending_pipeline_bar.dart';
import '../widgets/trending_source_badge.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  bool _showArchive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TrendingProvider>();
      provider.loadFeed();
      provider.loadPipelineStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Trending',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<TrendingProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<TrendingSortOption>(
                icon: const Icon(Icons.sort, color: AppColors.greyLight),
                color: AppColors.card,
                onSelected: provider.sortBy,
                itemBuilder: (_) => TrendingSortOption.values.map((option) {
                  return PopupMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        if (provider.sortOption == option)
                          Icon(Icons.check, size: 16, color: AppColors.purple)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(
                          option.label,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      body: Consumer<TrendingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.feed == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.error != null && provider.feed == null) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            color: AppColors.purple,
            backgroundColor: AppColors.card,
            onRefresh: provider.refreshFeed,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Pipeline status bar
                TrendingPipelineBar(
                  status: provider.pipelineStatus,
                  isRefreshing: provider.isRefreshing,
                  onRefresh: provider.refreshFeed,
                ),

                // Feed stats row
                _buildStatsRow(provider),

                // Profile cards
                ...provider.sortedProfiles.map(
                  (profile) => _TrendingCard(
                    profile: profile,
                    activeChallenges: provider.activeChallenges,
                    challengeProgress: provider.challengeProgress,
                    onStartChallenge: () =>
                        provider.startChallenge(profile.id),
                    onCompleteChallenge: (challengeId) =>
                        provider.completeChallenge(profile.id, challengeId),
                    onDismiss: () => provider.dismissProfile(profile.id),
                  ),
                ),

                // Archive section
                const SizedBox(height: 16),
                _buildArchiveSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(TrendingProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48,
              color: const Color(0xFFE0605A).withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? '',
            style: TextStyle(color: AppColors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: provider.loadFeed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(TrendingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatChip(
            label: '${provider.sortedProfiles.length} Trending',
            color: AppColors.purple,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '${provider.autoGeneratedCount} AI-Curated',
            color: AppColors.cyan,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '${provider.manualCount} Manual',
            color: AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveSection(TrendingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _showArchive = !_showArchive);
              if (_showArchive && provider.archive.isEmpty) {
                provider.loadArchive();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 18,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'View expired profiles',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showArchive
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_showArchive) ...[
            const SizedBox(height: 8),
            if (provider.isLoadingArchive)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.purple,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              ...provider.archive.map(
                (profile) => _ArchivedCard(profile: profile),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Stat chip ──

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Trending card ──

class _TrendingCard extends StatelessWidget {
  final TrendingProfile profile;
  final List<TrendingChallenge> activeChallenges;
  final double Function(String) challengeProgress;
  final VoidCallback onStartChallenge;
  final void Function(String) onCompleteChallenge;
  final VoidCallback onDismiss;

  const _TrendingCard({
    required this.profile,
    required this.activeChallenges,
    required this.challengeProgress,
    required this.onStartChallenge,
    required this.onCompleteChallenge,
    required this.onDismiss,
  });

  String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Expired';
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  bool get _isChallengeActive {
    return activeChallenges.any(
      (c) => profile.miniChallenges.any((mc) => mc.id == c.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ttl = profile.timeUntilExpiry;
    final progress = _isChallengeActive ? challengeProgress(profile.id) : 0.0;

    return Dismissible(
      key: Key(profile.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE0605A).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.close, color: Color(0xFFE0605A)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: emoji + name + badges
            Row(
              children: [
                // Emoji avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + reason
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.trendingReason.emoji} ${profile.trendingReason.label}',
                        style: TextStyle(
                          color: AppColors.greyLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badges column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // AI-Curated badge
                    if (profile.isAutoGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 10, color: AppColors.cyan),
                            const SizedBox(width: 3),
                            Text(
                              'AI-Curated',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Source badge
                    if (profile.source != null)
                      TrendingSourceBadge(
                        source: profile.source!,
                        sourceUrl: profile.sourceUrl,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              profile.title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 6),

            // Reason text
            Text(
              profile.reasonText,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Bottom row: TTL, score, views, engagement
            Row(
              children: [
                // TTL countdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ttl.inHours < 24
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.purpleSoft.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: ttl.inHours < 24
                            ? AppColors.warning
                            : AppColors.purpleSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCountdown(ttl),
                        style: TextStyle(
                          color: ttl.inHours < 24
                              ? AppColors.warning
                              : AppColors.purpleSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trend score
                if (profile.trendScore > 0)
                  _MetricPill(
                    icon: Icons.trending_up,
                    value: profile.trendScore.toStringAsFixed(0),
                    color: AppColors.purple,
                  ),

                const Spacer(),

                // Views
                _MetricPill(
                  icon: Icons.visibility_outlined,
                  value: _formatNumber(profile.viewCount),
                  color: AppColors.grey,
                ),

                const SizedBox(width: 6),

                // Engagement
                _MetricPill(
                  icon: Icons.favorite_outline,
                  value: '${profile.engagementScore.toStringAsFixed(0)}%',
                  color: AppColors.green,
                ),
              ],
            ),

            // Tags
            if (profile.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: profile.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Challenges section
            if (profile.miniChallenges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              if (!_isChallengeActive)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onStartChallenge,
                    icon: Icon(Icons.play_arrow,
                        size: 16, color: AppColors.purple),
                    label: Text(
                      'Start ${profile.miniChallenges.length}-day challenge',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.purple.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                )
              else ...[
                // Progress bar
                Row(
                  children: [
                    Text(
                      'Challenge Progress',
                      style: TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.cardLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.purple),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),

                // Challenge items
                ...profile.miniChallenges.map((challenge) {
                  final isCompleted = activeChallenges.any(
                    (c) => c.id == challenge.id && c.isCompleted,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: isCompleted
                          ? null
                          : () => onCompleteChallenge(challenge.id),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.title,
                                  style: TextStyle(
                                    color: isCompleted
                                        ? AppColors.grey
                                        : AppColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Day ${challenge.dayNumber}',
                                  style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Metric pill ──

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Archived card (compact) ──

class _ArchivedCard extends StatelessWidget {
  final TrendingProfile profile;

  const _ArchivedCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(profile.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: AppColors.greyLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.title,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (profile.trendScore > 0)
                Text(
                  '${profile.trendScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.purple.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                '${_formatNumber(profile.viewCount)} views',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

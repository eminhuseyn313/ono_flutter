// widgets/trending_source_badge.dart — Source platform badge (~60 lines)

import 'package:flutter/material.dart';
import '../models/trending.dart';
import '../theme/app_theme.dart';

class TrendingSourceBadge extends StatelessWidget {
  final TrendingSource source;
  final String? sourceUrl;
  final VoidCallback? onTap;

  const TrendingSourceBadge({
    super.key,
    required this.source,
    this.sourceUrl,
    this.onTap,
  });

  Color _backgroundColor() {
    switch (source) {
      case TrendingSource.twitter:
        return const Color(0xFF1DA1F2).withValues(alpha: 0.15);
      case TrendingSource.youtube:
        return const Color(0xFFFF0000).withValues(alpha: 0.15);
      case TrendingSource.tiktok:
        return AppColors.cyan.withValues(alpha: 0.15);
      case TrendingSource.googleTrends:
        return AppColors.green.withValues(alpha: 0.15);
      case TrendingSource.news:
        return AppColors.purple.withValues(alpha: 0.15);
      case TrendingSource.manual:
        return AppColors.grey.withValues(alpha: 0.15);
    }
  }

  Color _textColor() {
    switch (source) {
      case TrendingSource.twitter:
        return const Color(0xFF1DA1F2);
      case TrendingSource.youtube:
        return const Color(0xFFFF4444);
      case TrendingSource.tiktok:
        return AppColors.cyan;
      case TrendingSource.googleTrends:
        return AppColors.green;
      case TrendingSource.news:
        return AppColors.purple;
      case TrendingSource.manual:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sourceUrl != null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _backgroundColor(),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              source.emoji,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(width: 4),
            Text(
              source.label,
              style: TextStyle(
                color: _textColor(),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

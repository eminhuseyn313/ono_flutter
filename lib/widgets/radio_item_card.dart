import 'package:flutter/material.dart';

import '../models/radio.dart';
import '../theme/app_theme.dart';

/// Card for a single radio item (podcast, song, book).
class RadioItemCard extends StatelessWidget {
  final RadioItem item;
  final bool isListened;
  final VoidCallback onTap;

  const RadioItemCard({
    super.key,
    required this.item,
    required this.isListened,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isListened
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Platform icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _platformColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _platformIcon,
                  color: _platformColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isListened
                          ? AppColors.grey
                          : AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.duration != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(item.duration!),
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Context tags + listened
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.isMorning || item.isEvening)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (item.isMorning
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF7C9CC4))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isMorning ? '🌅' : '🌙',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (isListened) ...[
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.green,
                    size: 18,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _platformColor => switch (item.platform) {
        RadioPlatform.spotify => const Color(0xFF1DB954),
        RadioPlatform.youtube => const Color(0xFFFF0000),
        RadioPlatform.applePodcasts => const Color(0xFFC49AC0),
        RadioPlatform.amazon => const Color(0xFFFF9900),
        RadioPlatform.web => AppColors.cyan,
      };

  IconData get _platformIcon => switch (item.platform) {
        RadioPlatform.spotify => Icons.music_note,
        RadioPlatform.youtube => Icons.play_circle_filled,
        RadioPlatform.applePodcasts => Icons.podcasts,
        RadioPlatform.amazon => Icons.menu_book,
        RadioPlatform.web => Icons.language,
      };

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

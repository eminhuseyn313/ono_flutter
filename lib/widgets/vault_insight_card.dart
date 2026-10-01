import 'package:flutter/material.dart';
import '../models/vault.dart';
import '../theme/app_theme.dart';

class VaultInsightCard extends StatelessWidget {
  final VaultInsight insight;
  final VoidCallback? onViewRelated;

  const VaultInsightCard({
    super.key,
    required this.insight,
    this.onViewRelated,
  });

  List<Color> get _gradientColors {
    switch (insight.type) {
      case InsightType.pattern:
        return [
          AppColors.purpleSoft.withValues(alpha: 0.3),
          AppColors.purple.withValues(alpha: 0.1),
        ];
      case InsightType.milestone:
        return [
          AppColors.green.withValues(alpha: 0.3),
          AppColors.cyan.withValues(alpha: 0.1),
        ];
      case InsightType.suggestion:
        return [
          AppColors.purple.withValues(alpha: 0.3),
          AppColors.purpleDark.withValues(alpha: 0.1),
        ];
      case InsightType.streak:
        return [
          const Color(0xFFE0605A).withValues(alpha: 0.3),
          AppColors.warning.withValues(alpha: 0.1),
        ];
    }
  }

  Color get _borderColor {
    switch (insight.type) {
      case InsightType.pattern:
        return AppColors.purple.withValues(alpha: 0.4);
      case InsightType.milestone:
        return AppColors.green.withValues(alpha: 0.4);
      case InsightType.suggestion:
        return AppColors.cyan.withValues(alpha: 0.4);
      case InsightType.streak:
        return const Color(0xFFE0605A).withValues(alpha: 0.4);
    }
  }

  Color get _typeColor {
    switch (insight.type) {
      case InsightType.pattern:
        return AppColors.purple;
      case InsightType.milestone:
        return AppColors.green;
      case InsightType.suggestion:
        return AppColors.cyan;
      case InsightType.streak:
        return const Color(0xFFE0605A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + type badge row
              Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _borderColor,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        insight.iconEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            insight.type.label.toUpperCase(),
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Description
              Text(
                insight.description,
                style: TextStyle(
                  color: AppColors.grey.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              // View Related button
              GestureDetector(
                onTap: onViewRelated,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: _typeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View Related (${insight.relatedEntryIds.length})',
                        style: TextStyle(
                          color: _typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

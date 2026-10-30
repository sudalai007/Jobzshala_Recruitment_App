import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MatchScoreBadge extends StatelessWidget {
  final double score;
  final bool compact;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedScore = score.toStringAsFixed(1);
    final isHigh = score >= 90.0;

    final badgeColor = isHigh ? AppColors.highMatch : AppColors.medMatch;
    final bgColor = isHigh ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 13 : 15,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$formattedScore% Match',
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}


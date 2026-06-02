import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/case_entity.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty, this.compact = false});

  final CaseDifficulty difficulty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = difficulty.color;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 0.8),
        borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 6, spreadRadius: 0.5),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            difficulty.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 2,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 2,
            ),
      ),
    );
  }
}

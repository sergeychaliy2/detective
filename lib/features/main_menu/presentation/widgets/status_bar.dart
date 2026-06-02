import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Верхняя HUD-полоса: статус соединения, ник агента, текущая дата/время.
class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.agent,
    required this.session,
  });

  final String agent;
  final String session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          const _StatusDot(color: AppColors.jadeSuccess, label: 'ONLINE'),
          const SizedBox(width: 24),
          Text('AGENT // ', style: label),
          Text(
            agent.toUpperCase(),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: AppColors.neonCyan),
          ),
          const Spacer(),
          Text('SESSION ${session.toUpperCase()}', style: label),
          const SizedBox(width: 28),
          const _StatusDot(color: AppColors.magenta, label: 'SECURE LINK'),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 10, spreadRadius: 0.5),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.45, end: 1, duration: 900.ms),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 2,
              ),
        ),
      ],
    );
  }
}

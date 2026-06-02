import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/investigation_stage.dart';

/// Горизонтальная шкала этапов следствия: каждый шаг — точка с
/// иконкой и кодом этапа, между ними анимированные коннекторы.
class StageTrack extends StatelessWidget {
  const StageTrack({
    super.key,
    required this.current,
    required this.completed,
  });

  final InvestigationStage current;
  final Set<InvestigationStage> completed;

  @override
  Widget build(BuildContext context) {
    final stages = InvestigationStage.values;
    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          _StageNode(
            stage: stages[i],
            isCurrent: stages[i] == current,
            isDone: completed.contains(stages[i]),
            index: i,
          ),
          if (i < stages.length - 1)
            Expanded(
              child: _Connector(
                done: completed.contains(stages[i]),
              ),
            ),
        ],
      ],
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.isCurrent,
    required this.isDone,
    required this.index,
  });

  final InvestigationStage stage;
  final bool isCurrent;
  final bool isDone;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? stage.color
        : isDone
            ? AppColors.jadeSuccess
            : AppColors.textMuted;
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMetrics.normal,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isCurrent ? 0.2 : 0.06),
              border: Border.all(color: color, width: isCurrent ? 1.6 : 1),
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              isDone ? Icons.check_rounded : stage.icon,
              color: color,
              size: 20,
            ),
          )
              .animate(target: isCurrent ? 1 : 0)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          const SizedBox(height: 6),
          Text(
            stage.code,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stage.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isCurrent || isDone
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(bottom: 38),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: done
              ? [AppColors.jadeSuccess.withValues(alpha: 0.7),
                  AppColors.jadeSuccess.withValues(alpha: 0.7)]
              : [
                  AppColors.neonCyan.withValues(alpha: 0.3),
                  AppColors.neonCyan.withValues(alpha: 0.05),
                ],
        ),
      ),
    );
  }
}

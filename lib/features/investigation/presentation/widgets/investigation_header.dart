import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../domain/entities/investigation_stage.dart';
import '../../domain/entities/investigation_state.dart';
import 'stage_track.dart';

class InvestigationHeader extends StatelessWidget {
  const InvestigationHeader({
    super.key,
    required this.state,
    required this.onAdvance,
  });

  final InvestigationState state;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = state.caseInfo;
    final isVerdict = state.currentStage == InvestigationStage.verdict;
    final ready = state.canAdvance || isVerdict;
    return NeonPanel(
      borderColor: state.currentStage.color,
      glow: 14,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/cases'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          color: AppColors.neonCyan, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'КАРТОТЕКА',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.neonCyan,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Container(
                width: 1,
                height: 18,
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 22),
              Text(c.code,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: state.currentStage.color, letterSpacing: 4)),
              const SizedBox(width: 14),
              Text(c.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(letterSpacing: 1.4)),
              if (state.isExam) ...[
                const SizedBox(width: 14),
                _ExamBadge(),
              ],
              const Spacer(),
              _AdvanceButton(
                color: state.currentStage.color,
                label: isVerdict ? 'ВЫНЕСТИ ВЕРДИКТ' : 'СЛЕДУЮЩИЙ ЭТАП',
                onTap: ready ? onAdvance : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          StageTrack(
            current: state.currentStage,
            completed: state.completedStages,
          ),
          if (!isVerdict) _GateRequirements(state: state),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: -0.04, end: 0);
  }
}

class _ExamBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.crimsonError.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.crimsonError, width: 1),
      ),
      child: Text(
        'EXAM MODE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.crimsonError,
              letterSpacing: 3,
            ),
      ),
    );
  }
}

class _GateRequirements extends StatelessWidget {
  const _GateRequirements({required this.state});
  final InvestigationState state;

  @override
  Widget build(BuildContext context) {
    final reqs = state.currentStageProgress();
    if (reqs.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ready = state.canAdvance;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_outline : Icons.lock_outline,
            size: 14,
            color: ready ? AppColors.jadeSuccess : AppColors.amberWarning,
          ),
          const SizedBox(width: 8),
          Text(
            ready ? 'УСЛОВИЯ ВЫПОЛНЕНЫ:' : 'ДЛЯ ПЕРЕХОДА ТРЕБУЕТСЯ:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: ready ? AppColors.jadeSuccess : AppColors.amberWarning,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 14),
          for (final pair in reqs) ...[
            _GatePill(
              label: pair.$1.label,
              current: pair.$2,
              target: pair.$1.target,
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _GatePill extends StatelessWidget {
  const _GatePill({
    required this.label,
    required this.current,
    required this.target,
  });

  final String label;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = current >= target;
    final color = done ? AppColors.jadeSuccess : AppColors.amberWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$current / $target',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvanceButton extends StatefulWidget {
  const _AdvanceButton({
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends State<_AdvanceButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final c = disabled ? AppColors.textMuted : widget.color;
    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: c.withValues(alpha: _hover && !disabled ? 0.18 : 0.08),
              border: Border.all(color: c, width: 1),
              boxShadow: [
                BoxShadow(
                  color:
                      c.withValues(alpha: _hover && !disabled ? 0.6 : 0.3),
                  blurRadius: _hover && !disabled ? 18 : 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: c,
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: c, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

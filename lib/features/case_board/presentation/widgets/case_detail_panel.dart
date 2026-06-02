import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/glow_button.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../domain/entities/case_entity.dart';
import 'difficulty_badge.dart';

class CaseDetailPanel extends StatelessWidget {
  const CaseDetailPanel({
    super.key,
    required this.caseInfo,
    this.onStart,
  });

  final CaseEntity? caseInfo;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = caseInfo;

    if (c == null) {
      return NeonPanel(
        child: Center(
          child: Text(
            'Выберите дело слева',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final accent = c.difficulty.color;

    return NeonPanel(
      borderColor: accent,
      glow: 18,
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      child: AnimatedSwitcher(
        duration: AppMetrics.normal,
        switchInCurve: AppMetrics.easeOutExpo,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: SingleChildScrollView(
          key: ValueKey(c.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c.code,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: accent, letterSpacing: 4),
                  ),
                  const Spacer(),
                  DifficultyBadge(difficulty: c.difficulty),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                c.title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${c.theme.label}  //  ${c.theme.tagline}',
                style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 22),
              Text(c.brief, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
              const SizedBox(height: 24),
              _MetricRow(
                label: 'DATAPOINTS',
                value: c.dataPoints.toString(),
                color: AppColors.hologramBlue,
              ),
              const SizedBox(height: 10),
              _MetricRow(
                label: 'SUSPECTS',
                value: '${c.suspects}',
                color: AppColors.violet,
              ),
              const SizedBox(height: 10),
              _MetricRow(
                label: 'EST. DURATION',
                value: c.difficulty.duration,
                color: accent,
              ),
              const SizedBox(height: 10),
              _MetricRow(
                label: 'REWARD',
                value: '+${c.rewardXp} XP',
                color: AppColors.jadeSuccess,
              ),
              const SizedBox(height: 22),
              Text(
                'EVIDENCE TYPES',
                style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 3),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ev in c.evidenceTypes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.panelBg,
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        ev,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              StatusBadge(status: c.status),
              const SizedBox(height: 18),
              GlowButton(
                label: c.status == CaseStatus.solved
                    ? 'ПЕРЕОТКРЫТЬ ДЕЛО'
                    : c.status == CaseStatus.inProgress
                        ? 'ПРОДОЛЖИТЬ'
                        : 'ОТКРЫТЬ ДОСЬЕ',
                icon: Icons.east_rounded,
                color: accent,
                onPressed: c.status == CaseStatus.locked ? null : onStart,
                height: 58,
              ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(width: 3, height: 16, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 2.5)),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

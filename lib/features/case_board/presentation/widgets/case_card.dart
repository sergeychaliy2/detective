import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../domain/entities/case_entity.dart';
import 'difficulty_badge.dart';

/// Карточка дела на доске. Hover — рост glow и проявление акцентной линии,
/// selected — заполненный фон. Анимации плавные, через AnimatedContainer.
class CaseCard extends StatefulWidget {
  const CaseCard({
    super.key,
    required this.caseInfo,
    required this.selected,
    required this.onTap,
    this.index = 0,
  });

  final CaseEntity caseInfo;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.caseInfo.difficulty.color;
    final locked = widget.caseInfo.status == CaseStatus.locked;
    final active = widget.selected || _hover;

    return MouseRegion(
      cursor: locked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: locked ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.normal,
          curve: AppMetrics.easeOutExpo,
          transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
          child: Opacity(
            opacity: locked ? 0.55 : 1,
            child: NeonPanel(
              borderColor: widget.selected ? accent : AppColors.panelBorder,
              glow: active ? 18 : 8,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              background: widget.selected
                  ? accent.withValues(alpha: 0.08)
                  : AppColors.panelBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.caseInfo.code,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: accent, letterSpacing: 3),
                      ),
                      const Spacer(),
                      DifficultyBadge(
                        difficulty: widget.caseInfo.difficulty,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.caseInfo.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.caseInfo.theme.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.caseInfo.brief,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MetaPill(
                        icon: Icons.dataset_outlined,
                        label: _compact(widget.caseInfo.dataPoints),
                        color: AppColors.hologramBlue,
                      ),
                      const SizedBox(width: 8),
                      _MetaPill(
                        icon: Icons.person_search,
                        label: '${widget.caseInfo.suspects}',
                        color: AppColors.violet,
                      ),
                      const Spacer(),
                      Text(
                        '+${widget.caseInfo.rewardXp} XP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(status: widget.caseInfo.status),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (60 * widget.index).ms, duration: 420.ms)
            .slideY(
              begin: 0.06,
              end: 0,
              delay: (60 * widget.index).ms,
              duration: 480.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }

  String _compact(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

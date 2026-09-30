import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../../domain/entities/suspect_entity.dart';

class SuspectsTab extends StatelessWidget {
  const SuspectsTab({
    super.key,
    required this.state,
    required this.onLink,
    required this.onAccuse,
    required this.onClear,
  });

  final InvestigationState state;

  /// Привязать выделенную в DATA улику к данному подозреваемому (обоснование).
  final ValueChanged<String> onLink;

  /// Обвинить фигуранта (нужна ≥1 привязанная улика).
  final ValueChanged<String> onAccuse;

  /// Снять/вернуть подозрение с фигуранта.
  final ValueChanged<String> onClear;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedEvidenceId;
    final linkedCounts = <String, int>{};
    for (final s in state.suspects) {
      linkedCounts[s.id] = state.evidenceLinks.entries
          .where((e) => e.value == s.id)
          .length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccusationBar(state: state),
        const SizedBox(height: 10),
        _SelectionBar(selectedId: selected),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemCount: state.suspects.length,
            itemBuilder: (context, i) {
              final s = state.suspects[i];
              return _SuspectCard(
                s: s,
                index: i,
                linkedCount: linkedCounts[s.id] ?? 0,
                hasSelection: selected != null,
                isAccused: state.accusedSuspectId == s.id,
                isCleared: state.clearedSuspectIds.contains(s.id),
                onLink: () => onLink(s.id),
                onAccuse: () => onAccuse(s.id),
                onClear: () => onClear(s.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Шапка: объясняет финал «обвинить виновного + оправдать остальных» и
/// показывает прогресс.
class _AccusationBar extends StatelessWidget {
  const _AccusationBar({required this.state});
  final InvestigationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final built = state.accusationBuilt;
    final accused = state.accusedSuspectId;
    final color = built ? AppColors.jadeSuccess : AppColors.amberWarning;
    final accusedName = accused == null
        ? '—'
        : state.suspects
            .firstWhere((s) => s.id == accused,
                orElse: () => state.suspects.first)
            .codename;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(built ? Icons.balance : Icons.gavel_outlined,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              built
                  ? 'Обвинение готово: $accusedName под обвинением, с остальных снято подозрение.'
                  : 'Финал: привяжите улику к виновному и ОБВИНИТЕ его, а с остальных СНИМИТЕ ПОДОЗРЕНИЕ (алиби/логи).',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ОБВИНЯЕМЫЙ: $accusedName',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = selectedId != null;
    final color = has ? AppColors.neonCyan : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(has ? Icons.fingerprint : Icons.touch_app_outlined,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              has
                  ? 'Улика $selectedId готова. Нажмите ПРИВЯЗАТЬ у фигуранта — это обоснование обвинения.'
                  : 'Выберите улику в DATA или в протоколе, затем нажмите ПРИВЯЗАТЬ у фигуранта.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuspectCard extends StatefulWidget {
  const _SuspectCard({
    required this.s,
    required this.index,
    required this.linkedCount,
    required this.hasSelection,
    required this.isAccused,
    required this.isCleared,
    required this.onLink,
    required this.onAccuse,
    required this.onClear,
  });
  final SuspectEntity s;
  final int index;
  final int linkedCount;
  final bool hasSelection;
  final bool isAccused;
  final bool isCleared;
  final VoidCallback onLink;
  final VoidCallback onAccuse;
  final VoidCallback onClear;

  @override
  State<_SuspectCard> createState() => _SuspectCardState();
}

class _SuspectCardState extends State<_SuspectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      AppColors.neonCyan,
      AppColors.electricBlue,
      AppColors.violet,
      AppColors.magenta,
      AppColors.amberWarning,
    ];
    final base = palette[widget.index % palette.length];
    final borderColor = widget.isAccused
        ? AppColors.magenta
        : widget.isCleared
            ? AppColors.jadeSuccess
            : base;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Opacity(
        opacity: widget.isCleared ? 0.7 : 1,
        child: NeonPanel(
          borderColor: borderColor,
          glow: _hover ? 22 : 10,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: 0.12),
                      border: Border.all(color: base),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text(
                        widget.s.codename.characters.first,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: base,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.s.codename,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: base,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(widget.s.role, style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                  if (widget.isAccused) _StatusChip.accused(),
                  if (widget.isCleared) _StatusChip.cleared(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.s.bio,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text('ALIBI', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                widget.s.alibi,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text('THREAT', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  for (var k = 1; k <= 5; k++)
                    Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 14,
                      height: 4,
                      color: k <= widget.s.threatLevel
                          ? base
                          : AppColors.panelBorder,
                    ),
                  const Spacer(),
                  Text(
                    '${widget.linkedCount} LINKS',
                    style: theme.textTheme.labelMedium?.copyWith(color: base),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _LinkButton(
                color: base,
                enabled: widget.hasSelection,
                onTap: widget.hasSelection ? widget.onLink : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: widget.isAccused ? 'ОБВИНЯЕТСЯ' : 'ОБВИНИТЬ',
                      icon: Icons.gavel,
                      color: AppColors.magenta,
                      active: widget.isAccused,
                      enabled: widget.linkedCount > 0,
                      onTap: widget.linkedCount > 0 ? widget.onAccuse : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: widget.isCleared ? 'ОПРАВДАН' : 'СНЯТЬ ПОДОЗР.',
                      icon: Icons.verified_user_outlined,
                      color: AppColors.jadeSuccess,
                      active: widget.isCleared,
                      enabled: true,
                      onTap: widget.onClear,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (80 * widget.index).ms, duration: 500.ms)
            .slideY(
              begin: 0.05,
              end: 0,
              delay: (80 * widget.index).ms,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip._({required this.label, required this.color});

  factory _StatusChip.accused() =>
      const _StatusChip._(label: 'ОБВИНЯЕТСЯ', color: AppColors.magenta);
  factory _StatusChip.cleared() =>
      const _StatusChip._(label: 'ВНЕ ПОДОЗРЕНИЙ', color: AppColors.jadeSuccess);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 1.5,
              fontSize: 9,
            ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.color,
    required this.enabled,
    required this.onTap,
  });
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = enabled ? color : AppColors.textMuted;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              border: Border.all(color: c, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare_arrows, color: c, size: 16),
                const SizedBox(width: 8),
                Text(
                  'ПРИВЯЗАТЬ УЛИКУ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: c,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.enabled ? widget.color : AppColors.textMuted;
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AppMetrics.fast,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              color: widget.active
                  ? c.withValues(alpha: 0.2)
                  : c.withValues(alpha: _hover ? 0.12 : 0.05),
              border: Border.all(
                color: c.withValues(alpha: widget.active ? 1 : 0.5),
                width: widget.active ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: c, size: 13),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: c,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

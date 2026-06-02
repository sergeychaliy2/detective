import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../../domain/entities/suspect_entity.dart';

class SuspectsTab extends StatelessWidget {
  const SuspectsTab({
    super.key,
    required this.state,
    required this.onLink,
  });

  final InvestigationState state;

  /// Привязать выделенную в DATA улику к данному подозреваемому.
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        _SelectionBar(selectedId: selected, theme: theme),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: state.suspects.length,
            itemBuilder: (context, i) {
              final s = state.suspects[i];
              return _SuspectCard(
                s: s,
                index: i,
                linkedCount: linkedCounts[s.id] ?? 0,
                hasSelection: selected != null,
                onLink: () => onLink(s.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.selectedId, required this.theme});
  final String? selectedId;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
                  ? 'Готова к привязке улика $selectedId. Выберите фигуранта ниже.'
                  : 'Выберите улику в DATA, затем нажмите «ПРИВЯЗАТЬ» у фигуранта.',
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
    required this.onLink,
  });
  final SuspectEntity s;
  final int index;
  final int linkedCount;
  final bool hasSelection;
  final VoidCallback onLink;

  @override
  State<_SuspectCard> createState() => _SuspectCardState();
}

class _SuspectCardState extends State<_SuspectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      AppColors.neonCyan,
      AppColors.electricBlue,
      AppColors.violet,
      AppColors.magenta,
      AppColors.amberWarning,
    ];
    final color = colors[widget.index % colors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: NeonPanel(
        borderColor: color,
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
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      widget.s.codename.characters.first,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
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
                          color: color,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(widget.s.role, style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.s.bio,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text('ALIBI', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              widget.s.alibi,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
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
                        ? color
                        : AppColors.panelBorder,
                  ),
                const Spacer(),
                Text(
                  '${widget.linkedCount} LINKS',
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LinkButton(
              color: color,
              enabled: widget.hasSelection,
              onTap: widget.hasSelection ? widget.onLink : null,
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
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                  'ПРИВЯЗАТЬ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: c,
                    letterSpacing: 3,
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

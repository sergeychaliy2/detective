import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../domain/entities/protocol_entry.dart';

/// Лента протокола расследования: что и почему сделал игрок.
/// Показывается в правой колонке (тонкая, всегда на виду).
class ProtocolPanel extends StatelessWidget {
  const ProtocolPanel({
    super.key,
    required this.entries,
    this.onSelectEvidence,
  });

  final List<ProtocolEntry> entries;

  /// Клик по записи, относящейся к улике, выделяет её — затем можно
  /// перейти в SUSPECTS и привязать.
  final ValueChanged<String>? onSelectEvidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm:ss');
    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PROTOCOL',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              Text(
                '${entries.length} ENTRIES',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.panelBorder),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Действий пока не зафиксировано',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _Entry(
                      entry: entries[i],
                      fmt: fmt,
                      onSelectEvidence: onSelectEvidence,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entry,
    required this.fmt,
    required this.onSelectEvidence,
  });
  final ProtocolEntry entry;
  final DateFormat fmt;
  final ValueChanged<String>? onSelectEvidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _color(entry.kind);
    final eid = entry.evidenceId;
    final clickable = eid != null && onSelectEvidence != null;

    final body = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c, width: 2)),
        color: c.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.kind.glyph,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: c,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.kind.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: c,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${entry.stage.code} · ${fmt.format(entry.timestamp)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            entry.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (clickable) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.ads_click, size: 11,
                    color: AppColors.neonCyan.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  'выделить $eid → привязать',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.neonCyan.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    final wrapped = clickable
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onSelectEvidence!(eid),
              child: body,
            ),
          )
        : body;

    return wrapped.animate().fadeIn(duration: 280.ms);
  }

  Color _color(ProtocolKind k) {
    switch (k) {
      case ProtocolKind.whatif:
        return AppColors.jadeSuccess;
      case ProtocolKind.link:
        return AppColors.violet;
      case ProtocolKind.accuse:
        return AppColors.magenta;
      case ProtocolKind.clear:
        return AppColors.jadeSuccess;
      case ProtocolKind.reveal:
        return AppColors.amberWarning;
      case ProtocolKind.hint:
        return AppColors.amberWarning;
      case ProtocolKind.lifehack:
        return AppColors.magenta;
      case ProtocolKind.stage:
        return AppColors.neonCyan;
      case ProtocolKind.method:
        return AppColors.electricBlue;
      case ProtocolKind.filter:
        return AppColors.hologramBlue;
      case ProtocolKind.derived:
        return AppColors.amberWarning;
      case ProtocolKind.path:
        return AppColors.violet;
      case ProtocolKind.verdict:
        return AppColors.jadeSuccess;
    }
  }
}

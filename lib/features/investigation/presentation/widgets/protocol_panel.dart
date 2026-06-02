import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../domain/entities/protocol_entry.dart';

/// Лента протокола расследования: что и почему сделал игрок.
/// Показывается в правой колонке (тонкая, всегда на виду).
class ProtocolPanel extends StatelessWidget {
  const ProtocolPanel({super.key, required this.entries});

  final List<ProtocolEntry> entries;

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
                    itemBuilder: (context, i) =>
                        _Entry(entry: entries[i], fmt: fmt),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry, required this.fmt});
  final ProtocolEntry entry;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _color(entry.kind);
    return Container(
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
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }

  Color _color(ProtocolKind k) {
    switch (k) {
      case ProtocolKind.flag:
        return AppColors.crimsonError;
      case ProtocolKind.link:
        return AppColors.violet;
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

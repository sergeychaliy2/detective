import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/investigation_stage.dart';

/// Левый рейл с вкладками рабочего пространства. В экзаменационном
/// режиме (exam) скрыты вкладка MENTOR и кнопка TIME MACHINE.
class SideRail extends StatelessWidget {
  const SideRail({
    super.key,
    required this.active,
    required this.onSelect,
    required this.onRollback,
    required this.examMode,
  });

  final WorkspaceTab active;
  final ValueChanged<WorkspaceTab> onSelect;
  final VoidCallback onRollback;
  final bool examMode;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final t in WorkspaceTab.values)
        if (!(examMode && t == WorkspaceTab.mentor)) t,
    ];

    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.18),
            width: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          for (final tab in tabs)
            _RailItem(
              tab: tab,
              active: tab == active,
              onTap: () => onSelect(tab),
            ),
          const Spacer(),
          if (examMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: _ExamLockChip(),
            )
          else
            _TimeMachineButton(onTap: onRollback),
        ],
      ),
    );
  }
}

class _ExamLockChip extends StatelessWidget {
  const _ExamLockChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.crimsonError.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.crimsonError.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline,
              size: 18, color: AppColors.crimsonError),
          const SizedBox(height: 6),
          Text(
            'EXAM\nLOCK',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.crimsonError,
                  letterSpacing: 1.5,
                  height: 1.2,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _TimeMachineButton extends StatefulWidget {
  const _TimeMachineButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_TimeMachineButton> createState() => _TimeMachineButtonState();
}

class _TimeMachineButtonState extends State<_TimeMachineButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.magenta.withValues(alpha: _hover ? 0.18 : 0.08),
            border: Border.all(
              color: AppColors.magenta.withValues(alpha: _hover ? 1 : 0.55),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
            boxShadow: _hover
                ? const [
                    BoxShadow(
                      color: AppColors.magenta,
                      blurRadius: 16,
                      spreadRadius: -3,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            children: [
              const Icon(Icons.history, size: 18, color: AppColors.magenta),
              const SizedBox(height: 6),
              Text(
                'TIME\nMACHINE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.magenta,
                      letterSpacing: 1.5,
                      height: 1.2,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final WorkspaceTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = widget.active || _hover;
    final color =
        widget.active ? AppColors.neonCyan : AppColors.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.neonCyan.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.active ? AppColors.neonCyan : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(widget.tab.icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                widget.tab.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: on ? AppColors.textPrimary : AppColors.textSecondary,
                  letterSpacing: 2,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

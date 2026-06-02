import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/case_entity.dart';
import '../providers/case_board_providers.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(difficultyFilterProvider);
    return Row(
      children: [
        Text(
          'FILTER //',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(width: 16),
        _Chip(
          label: 'ВСЕ',
          active: selected == null,
          color: AppColors.textSecondary,
          onTap: () =>
              ref.read(difficultyFilterProvider.notifier).state = null,
        ),
        const SizedBox(width: 10),
        for (final d in CaseDifficulty.values) ...[
          _Chip(
            label: d.label,
            active: selected == d,
            color: d.color,
            onTap: () =>
                ref.read(difficultyFilterProvider.notifier).state = d,
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOn = widget.active || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.color.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: widget.color.withValues(alpha: isOn ? 1 : 0.35),
              width: widget.active ? 1.2 : 0.8,
            ),
            borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : const [],
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: widget.color,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

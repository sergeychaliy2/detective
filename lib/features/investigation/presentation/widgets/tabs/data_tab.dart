import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/analysis_method.dart';
import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/evidence_entity.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../../domain/services/statistical_methods.dart';

/// Вкладка "DATA" — таблица улик с сортировкой, выделением, флагами,
/// value-фильтром и опциональными производными колонками (z, log, Δmed).
class DataTab extends StatelessWidget {
  const DataTab({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onToggleFlag,
    required this.onToggleSort,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.onToggleDerived,
  });

  final InvestigationState state;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggleFlag;
  final VoidCallback onToggleSort;
  final void Function(num min, num max) onApplyFilter;
  final VoidCallback onClearFilter;
  final ValueChanged<DerivedColumn> onToggleDerived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy-MM-dd  HH:mm');

    final desc = StatisticalMethods.describe(state.evidence);
    final visible = state.filteredEvidence
        .toList()
      ..sort((a, b) => state.sortDescending
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp));

    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RAW EVIDENCE TABLE',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              Text(
                '${visible.length} / ${state.evidence.length} ENTRIES  //  '
                '${state.flaggedCount} FLAGGED  //  '
                '${state.viewedEvidenceIds.length} VIEWED',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterAndDerivedBar(
            state: state,
            desc: desc,
            onApply: onApplyFilter,
            onClear: onClearFilter,
            onToggleDerived: onToggleDerived,
          ),
          const SizedBox(height: 10),
          _HeaderRow(
            sortDescending: state.sortDescending,
            onToggleSort: onToggleSort,
            derived: state.derivedColumns,
          ),
          const Divider(height: 1, color: AppColors.panelBorder),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      state.valueFilter == null
                          ? 'НЕТ ДАННЫХ'
                          : 'ВСЕ УЛИКИ ОТФИЛЬТРОВАНЫ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _Row(
                      index: i,
                      e: visible[i],
                      fmt: fmt,
                      mean: desc.mean,
                      std: desc.std,
                      median: desc.median,
                      derived: state.derivedColumns,
                      isSelected: state.selectedEvidenceId == visible[i].id,
                      isViewed: state.viewedEvidenceIds.contains(visible[i].id),
                      showSmokingGun: state.lifehackUsed,
                      onTap: () => onSelect(visible[i].id),
                      onToggleFlag: () => onToggleFlag(visible[i].id),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            state.selectedEvidenceId == null
                ? 'Кликните по строке, чтобы выделить улику; затем перейдите в SUSPECTS для привязки.'
                : 'Выделено: ${state.selectedEvidenceId}. Перейдите в SUSPECTS и нажмите ПРИВЯЗАТЬ у нужного фигуранта.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterAndDerivedBar extends StatefulWidget {
  const _FilterAndDerivedBar({
    required this.state,
    required this.desc,
    required this.onApply,
    required this.onClear,
    required this.onToggleDerived,
  });

  final InvestigationState state;
  final DescriptiveStats desc;
  final void Function(num min, num max) onApply;
  final VoidCallback onClear;
  final ValueChanged<DerivedColumn> onToggleDerived;

  @override
  State<_FilterAndDerivedBar> createState() => _FilterAndDerivedBarState();
}

class _FilterAndDerivedBarState extends State<_FilterAndDerivedBar> {
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    final f = widget.state.valueFilter;
    if (f != null) {
      _range = RangeValues(f.min.toDouble(), f.max.toDouble());
    } else {
      _range = RangeValues(
        widget.desc.min.toDouble(),
        widget.desc.max.toDouble(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _FilterAndDerivedBar old) {
    super.didUpdateWidget(old);
    final f = widget.state.valueFilter;
    if (f == null && old.state.valueFilter != null) {
      // Снаружи фильтр сбросили — синхронизируем слайдер.
      setState(() {
        _range = RangeValues(
          widget.desc.min.toDouble(),
          widget.desc.max.toDouble(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilter = widget.state.valueFilter != null;
    final lo = widget.desc.min.toDouble();
    final hi = widget.desc.max.toDouble();
    if (hi <= lo) {
      return _DerivedRow(
        derived: widget.state.derivedColumns,
        onToggle: widget.onToggleDerived,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Text('FILTER value ∈',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '[${_range.start.round()}',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.neonCyan,
                inactiveTrackColor:
                    AppColors.neonCyan.withValues(alpha: 0.18),
                thumbColor: AppColors.magenta,
                overlayColor: AppColors.magenta.withValues(alpha: 0.18),
                rangeThumbShape:
                    const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: RangeSlider(
                values: _range,
                min: lo,
                max: hi,
                onChanged: (v) => setState(() => _range = v),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${_range.end.round()}]',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PillButton(
            label: hasFilter ? 'ПРИМЕНИТЬ' : 'ПРИМЕНИТЬ',
            color: AppColors.neonCyan,
            onTap: () => widget.onApply(_range.start, _range.end),
          ),
          const SizedBox(width: 8),
          _PillButton(
            label: 'СБРОС',
            color: AppColors.crimsonError,
            enabled: hasFilter,
            onTap: widget.onClear,
          ),
          const SizedBox(width: 18),
          Container(
            width: 1,
            height: 22,
            color: AppColors.neonCyan.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 14),
          _DerivedRow(
            derived: widget.state.derivedColumns,
            onToggle: widget.onToggleDerived,
          ),
        ],
      ),
    );
  }
}

class _DerivedRow extends StatelessWidget {
  const _DerivedRow({required this.derived, required this.onToggle});

  final Set<DerivedColumn> derived;
  final ValueChanged<DerivedColumn> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('DERIVED:',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
        const SizedBox(width: 8),
        for (final c in DerivedColumn.values) ...[
          _DerivedChip(
            col: c,
            active: derived.contains(c),
            onTap: () => onToggle(c),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _DerivedChip extends StatelessWidget {
  const _DerivedChip({
    required this.col,
    required this.active,
    required this.onTap,
  });
  final DerivedColumn col;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? col.color.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: col.color.withValues(alpha: active ? 1 : 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                col.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: col.color,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                col.formula,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = enabled ? color : AppColors.textMuted;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              border: Border.all(color: c, width: 1),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c, letterSpacing: 2.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.sortDescending,
    required this.onToggleSort,
    required this.derived,
  });

  final bool sortDescending;
  final VoidCallback onToggleSort;
  final Set<DerivedColumn> derived;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 2,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('ID', style: s)),
          SizedBox(
            width: 160,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggleSort,
                child: Row(
                  children: [
                    Text('TIMESTAMP', style: s),
                    const SizedBox(width: 4),
                    Icon(
                      sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12,
                      color: AppColors.neonCyan,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 110, child: Text('KIND', style: s)),
          SizedBox(width: 120, child: Text('SOURCE', style: s)),
          Expanded(child: Text('SUMMARY', style: s)),
          SizedBox(width: 80, child: Text('VALUE', style: s)),
          for (final c in derived)
            SizedBox(
              width: 70,
              child: Text(
                c.label,
                style: s?.copyWith(color: c.color),
              ),
            ),
          SizedBox(width: 70, child: Text('LINK', style: s)),
          SizedBox(width: 36, child: Text('FLAG', style: s)),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.index,
    required this.e,
    required this.fmt,
    required this.mean,
    required this.std,
    required this.median,
    required this.derived,
    required this.isSelected,
    required this.isViewed,
    required this.showSmokingGun,
    required this.onTap,
    required this.onToggleFlag,
  });

  final int index;
  final EvidenceEntity e;
  final DateFormat fmt;
  final double mean;
  final double std;
  final double median;
  final Set<DerivedColumn> derived;
  final bool isSelected;
  final bool isViewed;
  final bool showSmokingGun;
  final VoidCallback onTap;
  final VoidCallback onToggleFlag;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  String _derivedValue(DerivedColumn col) {
    final v = widget.e.value.toDouble();
    switch (col) {
      case DerivedColumn.zScore:
        if (widget.std == 0) return '—';
        return ((v - widget.mean) / widget.std).toStringAsFixed(2);
      case DerivedColumn.log10:
        if (v <= 0) return '—';
        return (math.log(v) / math.ln10).toStringAsFixed(2);
      case DerivedColumn.diffMedian:
        return (v - widget.median).toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGun = widget.showSmokingGun && widget.e.isSmokingGun;
    final base = widget.index.isEven
        ? Colors.transparent
        : AppColors.neonCyan.withValues(alpha: 0.025);
    final bg = isGun
        ? AppColors.magenta.withValues(alpha: 0.18)
        : widget.isSelected
            ? AppColors.neonCyan.withValues(alpha: 0.12)
            : _hover
                ? AppColors.neonCyan.withValues(alpha: 0.06)
                : base;
    final cellStyle = theme.textTheme.labelMedium?.copyWith(
      color: widget.isViewed
          ? AppColors.textPrimary
          : AppColors.textPrimary.withValues(alpha: 0.75),
      letterSpacing: 1,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                child: Row(
                  children: [
                    if (widget.isSelected || isGun)
                      Container(
                        width: 3,
                        height: 14,
                        margin: const EdgeInsets.only(right: 6),
                        color: isGun ? AppColors.magenta : AppColors.neonCyan,
                      ),
                    Expanded(
                      child: Text(
                        widget.e.id,
                        style: cellStyle?.copyWith(
                          color: isGun
                              ? AppColors.magenta
                              : AppColors.hologramBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  width: 160,
                  child: Text(widget.fmt.format(widget.e.timestamp),
                      style: cellStyle)),
              SizedBox(
                width: 110,
                child: Text(
                  widget.e.kind.label,
                  style: cellStyle?.copyWith(color: AppColors.electricBlue),
                ),
              ),
              SizedBox(width: 120, child: Text(widget.e.source, style: cellStyle)),
              Expanded(
                child: Text(
                  widget.e.summary,
                  style: cellStyle?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '${widget.e.value}',
                  style: cellStyle?.copyWith(
                    color: isGun ? AppColors.magenta : AppColors.neonCyan,
                  ),
                ),
              ),
              for (final c in widget.derived)
                SizedBox(
                  width: 70,
                  child: Text(
                    _derivedValue(c),
                    style: cellStyle?.copyWith(color: c.color),
                  ),
                ),
              SizedBox(
                width: 70,
                child: Text(
                  widget.e.suspectId ?? '—',
                  style: cellStyle?.copyWith(
                    color: AppColors.violet,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onToggleFlag,
                    child: Icon(
                      widget.e.flagged ? Icons.flag : Icons.flag_outlined,
                      size: 14,
                      color: widget.e.flagged
                          ? AppColors.crimsonError
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isGun ? 1 : 0).shimmer(
          duration: AppMetrics.cinematic,
          color: AppColors.magenta.withValues(alpha: 0.4),
        );
  }
}

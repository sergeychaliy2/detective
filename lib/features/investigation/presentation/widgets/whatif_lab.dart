import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/evidence_entity.dart';
import '../../domain/entities/investigation_stage.dart';
import '../../domain/entities/investigation_state.dart';

/// Лаборатория устойчивости (этап «Сопротивление среды»).
///
/// Игрок подменяет одно значение крупным числом и в реальном времени видит,
/// как среднее «улетает», а медиана почти не двигается — наглядный урок о
/// точке слома. Расчёт локальный, реальные улики не меняются.
///
/// Сворачивается, чтобы не занимать место в таблице DATA: по умолчанию
/// раскрыта только на своём этапе (cleanup), на остальных — компактная полоса.
class WhatIfLab extends StatefulWidget {
  const WhatIfLab({super.key, required this.state, required this.onTried});

  final InvestigationState state;

  /// Зовётся при первом взаимодействии — открывает гейт этапа CLEANUP.
  final VoidCallback onTried;

  @override
  State<WhatIfLab> createState() => _WhatIfLabState();
}

class _WhatIfLabState extends State<WhatIfLab> {
  double? _replacement;
  bool? _expandedOverride;

  bool get _expanded =>
      _expandedOverride ??
      (widget.state.currentStage == InvestigationStage.cleanup &&
          !widget.state.whatIfTried);

  int _targetIndex(List<double> values) {
    final sel = widget.state.selectedEvidenceId;
    if (sel != null) {
      final i = widget.state.evidence.indexWhere((e) => e.id == sel);
      if (i >= 0) return i;
    }
    final order = List<int>.generate(values.length, (i) => i)
      ..sort((a, b) => values[a].compareTo(values[b]));
    return order[order.length ~/ 2];
  }

  void _onChanged(double v) {
    setState(() {
      _replacement = v;
      // После взаимодействия остаёмся раскрытыми (иначе whatIfTried свернёт нас).
      _expandedOverride = true;
    });
    widget.onTried();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evidence = widget.state.evidence;
    if (evidence.length < 3) return const SizedBox.shrink();
    final tried = widget.state.whatIfTried;
    final expanded = _expanded;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 9, 14, expanded ? 12 : 9),
      decoration: BoxDecoration(
        color: AppColors.jadeSuccess.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.jadeSuccess.withValues(alpha: tried ? 0.55 : 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme, expanded, tried),
          if (expanded) ...[
            const SizedBox(height: 10),
            _body(theme, evidence),
          ],
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, bool expanded, bool tried) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _expandedOverride = !expanded),
        child: Row(
          children: [
            const Icon(Icons.science_outlined,
                color: AppColors.jadeSuccess, size: 16),
            const SizedBox(width: 8),
            Text(
              'ЛАБОРАТОРИЯ WHAT-IF',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.jadeSuccess,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                expanded
                    ? 'подмени одно значение огромным — посмотри, кто устойчив'
                    : 'нажмите, чтобы развернуть демонстрацию устойчивости',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tried)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle_outline,
                    color: AppColors.jadeSuccess, size: 16),
              ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.jadeSuccess,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, List<EvidenceEntity> evidence) {
    final values = [for (final e in evidence) e.value.toDouble()];
    final ti = _targetIndex(values);
    final target = evidence[ti];

    final origMean = _mean(values);
    final origMedian = _median(values);

    final ceil = math.max(values.reduce(math.max) * 5, origMedian * 100);
    final repl =
        (_replacement ?? math.max(ceil * 0.4, target.value.toDouble()))
            .clamp(0.0, ceil);

    final modified = [...values]..[ti] = repl;
    final newMean = _mean(modified);
    final newMedian = _median(modified);
    final newStd = _std(modified, newMean);
    final newZ = newStd == 0 ? 0.0 : (repl - newMean) / newStd;
    final meanFactor = origMean == 0 ? 0.0 : newMean / origMean;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 220,
              child: Text(
                'Заменить ${target.id} (${_fmt(target.value.toDouble())}) на:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.jadeSuccess,
                  inactiveTrackColor:
                      AppColors.jadeSuccess.withValues(alpha: 0.18),
                  thumbColor: AppColors.magenta,
                  overlayColor: AppColors.magenta.withValues(alpha: 0.18),
                  trackHeight: 2,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: repl.toDouble(),
                  min: 0,
                  max: ceil,
                  onChanged: _onChanged,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: Text(
                _fmt(repl.toDouble()),
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.magenta,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCell(
              label: 'СРЕДНЕЕ',
              before: _fmt(origMean),
              after: _fmt(newMean),
              note: meanFactor >= 1.1
                  ? '×${meanFactor.toStringAsFixed(1)}'
                  : 'стабильно',
              color: AppColors.crimsonError,
              alarmed: meanFactor >= 1.5,
            ),
            const SizedBox(width: 8),
            _StatCell(
              label: 'МЕДИАНА',
              before: _fmt(origMedian),
              after: _fmt(newMedian),
              note: 'устойчива',
              color: AppColors.jadeSuccess,
              alarmed: false,
            ),
            const SizedBox(width: 8),
            _StatCell(
              label: 'z ПОДМЕНЫ',
              before: '—',
              after: newZ.toStringAsFixed(1),
              note: newZ.abs() > 3 ? '> 3σ' : 'в норме',
              color: AppColors.neonCyan,
              alarmed: newZ.abs() > 3,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          meanFactor >= 1.5
              ? 'Одно число утащило среднее ×${meanFactor.toStringAsFixed(1)}, '
                  'а медиана почти не сдвинулась. Среднее ломается от выброса — '
                  'медиана устойчива. Вот почему детективу нужна медиана.'
              : 'Двигай ползунок вправо: чем крупнее подмена, тем сильнее '
                  'среднее отрывается от медианы. Медиана держит «типичное» значение.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ── Локальная статистика по значениям ───────────────────────────────
  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  static double _median(List<double> xs) {
    if (xs.isEmpty) return 0;
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  }

  static double _std(List<double> xs, double mean) {
    if (xs.isEmpty) return 0;
    final v = xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        xs.length;
    return math.sqrt(v);
  }

  static String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v.abs() >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(v.abs() < 100 ? 1 : 0);
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.before,
    required this.after,
    required this.note,
    required this.color,
    required this.alarmed,
  });

  final String label;
  final String before;
  final String after;
  final String note;
  final Color color;
  final bool alarmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withValues(alpha: 0.45),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  before,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_right_alt,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  after,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: alarmed ? color : AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  note,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: alarmed ? color : AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

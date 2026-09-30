import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/analysis_method.dart';
import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/evidence_entity.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../../domain/services/statistical_methods.dart';
import '../charts/benford_chart.dart';

/// Вкладка ANALYSIS — переключатель аналитических методов и панель
/// результата. Слева — методы, справа — выбранный/последний применённый
/// результат с outliers, формулой и интерпретацией.
class AnalysisTab extends StatelessWidget {
  const AnalysisTab({
    super.key,
    required this.state,
    required this.onApplyMethod,
    required this.onSelectMethod,
    required this.onRemoveMethod,
    required this.onSelectEvidence,
    required this.onReveal,
  });

  final InvestigationState state;
  final ValueChanged<AnalysisMethod> onApplyMethod;
  final ValueChanged<AnalysisMethod> onSelectMethod;
  final ValueChanged<AnalysisMethod> onRemoveMethod;
  final ValueChanged<String> onSelectEvidence;
  final ValueChanged<AnalysisMethod> onReveal;

  @override
  Widget build(BuildContext context) {
    final desc = StatisticalMethods.describe(state.evidence);
    final active = state.activeMethod;
    final result = active == null ? null : state.methodResults[active];
    // Подсветку «оптимального» метода даём только в обучении.
    final showOptimal = state.isTraining;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: _MethodListPanel(
                  state: state,
                  showOptimal: showOptimal,
                  onApply: onApplyMethod,
                  onSelect: onSelectMethod,
                  onRemove: onRemoveMethod,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: result == null
                    ? _EmptyResultPanel(state: state, desc: desc)
                    : _ResultPanel(
                        result: result,
                        evidence: state.evidence,
                        isSolutionMethod:
                            showOptimal && active == state.caseInfo.solutionMethod,
                        revealed: active != null &&
                            state.revealedConclusions.contains(active),
                        canReveal: !state.isExam,
                        costsRating: state.isPractice,
                        onReveal: () => onReveal(active!),
                        onSelectEvidence: onSelectEvidence,
                        onRemove: () => onRemoveMethod(active!),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DescriptiveStrip(desc: desc),
      ],
    );
  }
}

class _MethodListPanel extends StatelessWidget {
  const _MethodListPanel({
    required this.state,
    required this.showOptimal,
    required this.onApply,
    required this.onSelect,
    required this.onRemove,
  });

  final InvestigationState state;
  final bool showOptimal;
  final ValueChanged<AnalysisMethod> onApply;
  final ValueChanged<AnalysisMethod> onSelect;
  final ValueChanged<AnalysisMethod> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'МЕТОДЫ',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4),
              ),
              const Spacer(),
              Text(
                '${state.methodResults.length} / ${AnalysisMethod.values.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: AnalysisMethod.values.length,
              itemBuilder: (context, i) {
                final m = AnalysisMethod.values[i];
                final result = state.methodResults[m];
                return _MethodCard(
                  method: m,
                  result: result,
                  isActive: state.activeMethod == m,
                  isSolution: showOptimal && m == state.caseInfo.solutionMethod,
                  onApply: () => onApply(m),
                  onSelect: () => onSelect(m),
                  onRemove: () => onRemove(m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatefulWidget {
  const _MethodCard({
    required this.method,
    required this.result,
    required this.isActive,
    required this.isSolution,
    required this.onApply,
    required this.onSelect,
    required this.onRemove,
  });

  final AnalysisMethod method;
  final AnalysisResult? result;
  final bool isActive;
  final bool isSolution;
  final VoidCallback onApply;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applied = widget.result != null;
    final color = widget.method.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: applied ? widget.onSelect : widget.onApply,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? color.withValues(alpha: 0.18)
                : _hover
                    ? color.withValues(alpha: 0.07)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isActive
                    ? color
                    : applied
                        ? color.withValues(alpha: 0.7)
                        : color.withValues(alpha: 0.3),
                width: widget.isActive ? 4 : 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.method.code,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.isSolution)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.jadeSuccess.withValues(alpha: 0.18),
                        border: Border.all(
                          color: AppColors.jadeSuccess.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'OPTIMAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.jadeSuccess,
                          letterSpacing: 1.5,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (applied) ...[
                    Text(
                      '${widget.result!.metricLabel} = ${widget.result!.metric.toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onRemove,
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'TAP → APPLY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.method.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.method.short,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              if (applied) ...[
                const SizedBox(height: 4),
                Text(
                  '${widget.result!.outliers.length} outlier(s)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.result!.hasOutliers
                        ? AppColors.crimsonError
                        : AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.evidence,
    required this.isSolutionMethod,
    required this.revealed,
    required this.canReveal,
    required this.costsRating,
    required this.onReveal,
    required this.onSelectEvidence,
    required this.onRemove,
  });

  final AnalysisResult result;
  final List<EvidenceEntity> evidence;
  final bool isSolutionMethod;
  final bool revealed;
  final bool canReveal;
  final bool costsRating;
  final VoidCallback onReveal;
  final ValueChanged<String> onSelectEvidence;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = result.method;
    return NeonPanel(
      borderColor: m.color,
      glow: 16,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                m.code,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: m.color,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                m.title,
                style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 1.4),
              ),
              const Spacer(),
              if (isSolutionMethod)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.jadeSuccess.withValues(alpha: 0.14),
                    border: Border.all(color: AppColors.jadeSuccess),
                  ),
                  child: Text(
                    'OPTIMAL  +25% XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.jadeSuccess,
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.metricLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.metric.toStringAsFixed(2),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: m.color,
                  fontSize: 48,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.08),
                  border: Border.all(color: m.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${result.outliers.length} OUTLIER${result.outliers.length == 1 ? "" : "S"}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: m.color,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormulaBox(formula: m.formula, color: m.color),
          const SizedBox(height: 10),
          // ПОСЧИТАНО — нейтральные числа, видно всегда.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.4),
              border: Border(
                left: BorderSide(
                    color: m.color.withValues(alpha: 0.5), width: 2),
              ),
            ),
            child: Text(
              result.readout,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ConclusionReveal(
            conclusion: result.conclusion,
            revealed: revealed,
            canReveal: canReveal,
            costsRating: costsRating,
            onReveal: onReveal,
          ),
          if (m == AnalysisMethod.benford) ...[
            const SizedBox(height: 16),
            BenfordChart(
              distribution:
                  StatisticalMethods.firstDigitDistribution(evidence),
              barColor: m.color,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'OUTLIERS — кликни строку, чтобы выделить улику в DATA / SUSPECTS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: result.outliers.isEmpty
                ? Center(
                    child: Text(
                      '— нет выбросов по этому методу —',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: result.outliers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) => _OutlierRow(
                      hit: result.outliers[i],
                      color: m.color,
                      onTap: () =>
                          onSelectEvidence(result.outliers[i].evidence.id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormulaBox extends StatelessWidget {
  const _FormulaBox({required this.formula, required this.color});
  final String formula;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: SelectableText(
        formula,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontFamily: 'JetBrainsMono',
          height: 1.4,
        ),
      ),
    );
  }
}

/// Блок ВЫВОДА: числа метод выдаёт всегда, а словесную интерпретацию игрок
/// раскрывает сам (бесплатно в обучении, со штрафом в практике, никак на экзамене).
class _ConclusionReveal extends StatelessWidget {
  const _ConclusionReveal({
    required this.conclusion,
    required this.revealed,
    required this.canReveal,
    required this.costsRating,
    required this.onReveal,
  });

  final String conclusion;
  final bool revealed;
  final bool canReveal;
  final bool costsRating;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (revealed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.amberWarning.withValues(alpha: 0.08),
          border: const Border(
            left: BorderSide(color: AppColors.amberWarning, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ВЫВОД',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.amberWarning,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              conclusion,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 280.ms);
    }
    if (!canReveal) {
      return Row(
        children: [
          const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'ВЫВОД НЕДОСТУПЕН В ЭКЗАМЕНЕ — интерпретируй числа сам',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      );
    }
    return _RevealButton(costsRating: costsRating, onReveal: onReveal);
  }
}

class _RevealButton extends StatefulWidget {
  const _RevealButton({required this.costsRating, required this.onReveal});

  final bool costsRating;
  final VoidCallback onReveal;

  @override
  State<_RevealButton> createState() => _RevealButtonState();
}

class _RevealButtonState extends State<_RevealButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const c = AppColors.amberWarning;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onReveal,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: _hover ? 0.16 : 0.07),
            border: Border.all(color: c.withValues(alpha: _hover ? 0.9 : 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_outlined, size: 15, color: c),
              const SizedBox(width: 8),
              Text(
                widget.costsRating
                    ? 'РАСКРЫТЬ ВЫВОД  (−8 XP / −1 РЕП)'
                    : 'РАСКРЫТЬ ВЫВОД',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: c,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlierRow extends StatefulWidget {
  const _OutlierRow({
    required this.hit,
    required this.color,
    required this.onTap,
  });
  final OutlierHit hit;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_OutlierRow> createState() => _OutlierRowState();
}

class _OutlierRowState extends State<_OutlierRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.hit.evidence;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? widget.color.withValues(alpha: 0.12)
                : widget.color.withValues(alpha: 0.04),
            border: Border.all(
              color: widget.color.withValues(alpha: _hover ? 0.7 : 0.3),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  e.id,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.hologramBlue,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  e.kind.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.electricBlue,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'value=${e.value}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  e.suspectId == null ? '—' : 'owner=${e.suspectId}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.violet,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.hit.scoreLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: widget.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResultPanel extends StatelessWidget {
  const _EmptyResultPanel({required this.state, required this.desc});

  final InvestigationState state;
  final DescriptiveStats desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ВЫБЕРИТЕ МЕТОД',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 24,
              letterSpacing: 4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Нажмите TAP→APPLY на любом методе слева. Каждый метод применяется ко всем '
            '${state.evidence.length} уликам и возвращает основную метрику + список '
            'выбросов с обоснованием. Метод с тегом OPTIMAL даёт +25% XP за вердикт.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Подсказка по выбору:',
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
          ),
          const SizedBox(height: 8),
          for (final m in AnalysisMethod.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      m.code,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: m.color,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      m.when,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms);
  }
}

class _DescriptiveStrip extends StatelessWidget {
  const _DescriptiveStrip({required this.desc});
  final DescriptiveStats desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, String value, {Color? color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withValues(alpha: 0.45),
          border: Border(
            left: BorderSide(color: color ?? AppColors.neonCyan, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 2),
            Text(value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color ?? AppColors.neonCyan,
                  letterSpacing: 1,
                )),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: cell('n', '${desc.n}')),
        const SizedBox(width: 6),
        Expanded(child: cell('mean', desc.mean.toStringAsFixed(1))),
        const SizedBox(width: 6),
        Expanded(child: cell('median', desc.median.toStringAsFixed(1))),
        const SizedBox(width: 6),
        Expanded(child: cell('std', desc.std.toStringAsFixed(1),
            color: AppColors.violet)),
        const SizedBox(width: 6),
        Expanded(child: cell('Q1', desc.q1.toStringAsFixed(1))),
        const SizedBox(width: 6),
        Expanded(child: cell('Q3', desc.q3.toStringAsFixed(1))),
        const SizedBox(width: 6),
        Expanded(child: cell('IQR', desc.iqr.toStringAsFixed(1),
            color: AppColors.electricBlue)),
        const SizedBox(width: 6),
        Expanded(child: cell('min', desc.min.toStringAsFixed(0))),
        const SizedBox(width: 6),
        Expanded(child: cell('max', desc.max.toStringAsFixed(0))),
      ],
    );
  }
}

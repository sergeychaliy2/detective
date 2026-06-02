import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/buttons/glow_button.dart';
import '../../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../../../core/widgets/text/glitch_text.dart';
import '../../../../profile/domain/entities/player_state.dart';
import '../../../domain/entities/analysis_method.dart';
import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/investigation_state.dart';

/// Полноэкранный экран исхода. Показывает цепочку вывода игрока
/// (применённые методы + финальный выбор) и XP-дельту с бонусом за
/// «оптимальный метод».
class OutcomeOverlay extends StatelessWidget {
  const OutcomeOverlay({
    super.key,
    required this.state,
    required this.xpDelta,
    required this.onBackToMenu,
    this.onRollback,
  });

  final InvestigationState state;
  final int xpDelta;
  final VoidCallback onBackToMenu;
  final VoidCallback? onRollback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = state.outcome;
    final solved = outcome == CaseOutcome.solved;
    final color = solved ? AppColors.jadeSuccess : AppColors.crimsonError;
    final headline = solved ? 'СПРАВЕДЛИВЫЙ ВЕРДИКТ' : 'СУДЕБНАЯ ОШИБКА';
    final body = solved
        ? 'Расчёты точны. Настоящий преступник найден, невиновный спасён.'
        : 'Шум принят за улику или формула применена не туда. Это станет уроком.';
    final usedOptimal = state.methodResults.containsKey(state.caseInfo.solutionMethod);

    return ColoredBox(
      color: AppColors.voidBlack.withValues(alpha: 0.94),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: NeonPanel(
              borderColor: color,
              glow: 28,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HolographicGlow(
                    radius: 240,
                    color: color.withValues(alpha: 0.55),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.16),
                        border: Border.all(color: color),
                      ),
                      child: Icon(
                        solved
                            ? Icons.verified_rounded
                            : Icons.gavel_rounded,
                        color: color,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${state.caseInfo.code}  //  ${state.caseInfo.title}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: color, letterSpacing: 4),
                  ),
                  const SizedBox(height: 10),
                  GlitchText(
                    headline,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 34,
                      color: color,
                      letterSpacing: 5,
                    ),
                    cyan: color,
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          border: Border.all(color: color, width: 1),
                        ),
                        child: Text(
                          'XP DELTA  //  ${xpDelta >= 0 ? '+' : ''}$xpDelta',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: color,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      if (solved && usedOptimal) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.jadeSuccess.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.jadeSuccess),
                          ),
                          child: Text(
                            '+25% «ЭЛЕГАНТНОЕ РЕШЕНИЕ»',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.jadeSuccess,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: _ReasoningChain(
                      methodResults: state.methodResults,
                      solutionMethod: state.caseInfo.solutionMethod,
                      finalSuspect: _finalSuspect(),
                      finalValue: _finalValue(),
                      rationale: state.caseInfo.solutionRationale,
                      correct: solved,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlowButton(
                        label: 'В МЕНЮ',
                        icon: Icons.home_outlined,
                        color: AppColors.neonCyan,
                        onPressed: onBackToMenu,
                        width: 220,
                      ),
                      if (!solved && onRollback != null) ...[
                        const SizedBox(width: 14),
                        GlowButton(
                          label: 'МАШИНА ВРЕМЕНИ',
                          icon: Icons.history,
                          color: AppColors.magenta,
                          onPressed: onRollback,
                          width: 280,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutExpo,
        );
  }

  String? _finalSuspect() {
    for (final p in state.protocol) {
      if (p.message.startsWith('VERDICT')) {
        // Парсим из строки "VERDICT // suspect=Sx, value=Y → ..."
        final m = RegExp(r'suspect=([^,]+)').firstMatch(p.message);
        return m?.group(1);
      }
    }
    return null;
  }

  String? _finalValue() {
    for (final p in state.protocol) {
      if (p.message.startsWith('VERDICT')) {
        final m = RegExp(r'value=([^\s]+)').firstMatch(p.message);
        return m?.group(1);
      }
    }
    return null;
  }
}

class _ReasoningChain extends StatelessWidget {
  const _ReasoningChain({
    required this.methodResults,
    required this.solutionMethod,
    required this.finalSuspect,
    required this.finalValue,
    required this.rationale,
    required this.correct,
  });

  final Map<AnalysisMethod, AnalysisResult> methodResults;
  final AnalysisMethod solutionMethod;
  final String? finalSuspect;
  final String? finalValue;
  final String rationale;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined,
                  color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'ЦЕПОЧКА ВЫВОДА',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4),
              ),
              const Spacer(),
              if (methodResults.isEmpty)
                Text(
                  'методы не применены',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.amberWarning, letterSpacing: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (methodResults.isEmpty)
            Text(
              'Подал вердикт без статистической поддержки. В будущем применяй '
              'хотя бы один метод в ANALYSIS — это поднимает точность и даёт '
              '+25% XP за «элегантное решение».',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in methodResults.entries)
                      _MethodLine(
                        method: entry.key,
                        result: entry.value,
                        isOptimal: entry.key == solutionMethod,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.panelBorder),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 22,
                margin: const EdgeInsets.only(top: 2, right: 10),
                color: correct ? AppColors.jadeSuccess : AppColors.crimsonError,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ВЕРДИКТ:  suspect = ${finalSuspect ?? "—"},  '
                      'value = ${finalValue ?? "—"}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: correct
                            ? AppColors.jadeSuccess
                            : AppColors.crimsonError,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rationale,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodLine extends StatelessWidget {
  const _MethodLine({
    required this.method,
    required this.result,
    required this.isOptimal,
  });

  final AnalysisMethod method;
  final AnalysisResult result;
  final bool isOptimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(top: 3, right: 10),
            color: method.color,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.code,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: method.color,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${result.metricLabel} = ${result.metric.toStringAsFixed(2)}  ·  '
                      '${result.outliers.length} outlier(s)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isOptimal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.jadeSuccess.withValues(alpha: 0.18),
                          border: Border.all(color: AppColors.jadeSuccess),
                        ),
                        child: Text(
                          'OPTIMAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.jadeSuccess,
                            letterSpacing: 1.5,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (result.outliers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '→ топ outlier: ${result.outliers.first.evidence.id} '
                      '(${result.outliers.first.scoreLabel})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

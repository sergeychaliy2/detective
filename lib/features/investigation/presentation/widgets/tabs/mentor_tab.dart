import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/buttons/glow_button.dart';
import '../../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/investigation_stage.dart';
import '../../../domain/entities/investigation_state.dart';

class MentorTab extends StatelessWidget {
  const MentorTab({
    super.key,
    required this.state,
    required this.onHint,
    required this.onLifehack,
  });

  final InvestigationState state;

  /// Возвращает текст подсказки или null (если экзамен / уже раскрыта).
  final String? Function() onHint;

  /// Подсвечивает smoking-gun-улику. Возвращает её ID или null.
  final String? Function() onLifehack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = state.currentStage;
    final hintRevealed = state.revealedHintStages.contains(stage);
    final lifehackUsed = state.lifehackUsed;
    final exam = state.isExam;
    final hintIndex = InvestigationStage.values.indexOf(stage);
    final hintText = (hintIndex >= 0 && hintIndex < state.caseInfo.theoryHints.length)
        ? state.caseInfo.theoryHints[hintIndex]
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: NeonPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                HolographicGlow(
                  radius: 240,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.neonCyan),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_outlined,
                      color: AppColors.neonCyan,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('НАСТАВНИК', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  exam ? 'EXAM MODE — БЕЗ ПОДСКАЗОК' : 'JUST-IN-TIME GUIDANCE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: exam ? AppColors.crimsonError : null,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: NeonPanel(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// CONTEXTUAL THEORY',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  stage.title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 26,
                    letterSpacing: 2,
                    color: stage.color,
                  ),
                ),
                const SizedBox(height: 16),
                DefaultTextStyle(
                  style: theme.textTheme.bodyLarge!.copyWith(
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                  child: AnimatedTextKit(
                    isRepeatingAnimation: false,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        _theory(stage),
                        speed: const Duration(milliseconds: 18),
                      ),
                    ],
                  ),
                ),
                if (hintRevealed && hintText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RevealedBox(
                    title: 'ПОДСКАЗКА К ЭТАПУ',
                    text: hintText,
                    color: AppColors.amberWarning,
                  ),
                ],
                if (lifehackUsed) ...[
                  const SizedBox(height: 12),
                  const _RevealedBox(
                    title: 'ЛАЙФХАК ИСПОЛЬЗОВАН',
                    text:
                        'Smoking-gun подсвечена в DATA. Сверьтесь с её значением и suspectId — это ответ.',
                    color: AppColors.magenta,
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    GlowButton(
                      label: hintRevealed ? 'ПОДСКАЗКА ВЫДАНА' : 'ПОДСКАЗКА',
                      icon: Icons.tips_and_updates_outlined,
                      onPressed: (exam || hintRevealed) ? null : onHint,
                      color: AppColors.amberWarning,
                      width: 220,
                    ),
                    const SizedBox(width: 14),
                    GlowButton(
                      label: lifehackUsed ? 'ЛАЙФХАК ИСПОЛЬЗОВАН' : 'ЛАЙФХАК',
                      icon: Icons.bolt,
                      onPressed: (exam || lifehackUsed) ? null : onLifehack,
                      color: AppColors.magenta,
                      width: 240,
                    ),
                    const Spacer(),
                    Text(
                      '−10 XP / −25 XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 380.ms);
  }

  String _theory(InvestigationStage s) {
    switch (s) {
      case InvestigationStage.intake:
        return 'На первом шаге твоя задача — оценить размер выборки и понять, какие признаки доступны. '
            'Не торопись считать средние. Сначала прочти "паспорт" данных: типы полей, диапазоны, пропуски. '
            'Грязные данные превращают красивые формулы в ложные доказательства.';
      case InvestigationStage.cleanup:
        return 'Сопротивление среды — это шум, дубликаты и аномалии форматов. '
            'Применяй преобразования с подтверждением: после каждой чистки сравнивай распределение «до/после». '
            'Если форма изменилась радикально — ты выбросил сигнал вместе с шумом.';
      case InvestigationStage.analysis:
        return 'Здесь работает арсенал: статистика, графы, криптография. '
            'Выбирай метод под вопрос, а не наоборот. Дисперсия отвечает на "насколько разброс?", '
            'а корреляция Спирмена — на "есть ли монотонная связь?". Это не одно и то же.';
      case InvestigationStage.suspects:
        return 'Сопоставь улики с фигурантами. Сильная связь ≠ виновность: учитывай мотив, доступ и алиби. '
            'Используй принцип "минимального объяснения": если шум объясняет данные так же хорошо — у тебя нет улики.';
      case InvestigationStage.verdict:
        return 'Финальный этап. Подсказок больше нет. Ты должен сформулировать обвинение одной "уликой-цифрой": '
            'число и интервал доверия, отделяющие подозреваемого от всех остальных. Ошибка стоит репутации.';
    }
  }
}

class _RevealedBox extends StatelessWidget {
  const _RevealedBox({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.04, end: 0);
  }
}

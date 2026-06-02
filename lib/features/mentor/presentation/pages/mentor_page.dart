import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../../../core/widgets/text/glitch_text.dart';
import '../../../investigation/domain/entities/investigation_stage.dart';
import '../../../main_menu/presentation/widgets/status_bar.dart';

/// Страница «общая теория наставника» (OP/04). Показывает 5 карточек
/// этапов следствия с принципами — без привязки к конкретному делу.
class MentorPage extends StatelessWidget {
  const MentorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              const StatusBar(agent: 'KASHIRINA.K', session: 'A-001'),
              _Header(onBack: () => context.go('/menu')),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '«Не выбирай метод — выбери вопрос. Метод родится сам».',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 480.ms),
                      const SizedBox(height: 20),
                      Text(
                        'ПЯТЬ ЭТАПОВ СЛЕДСТВИЯ',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 160.ms, duration: 480.ms),
                      const SizedBox(height: 18),
                      for (var i = 0;
                          i < InvestigationStage.values.length;
                          i++) ...[
                        _StageCard(
                          stage: InvestigationStage.values[i],
                          index: i,
                          principle: _principle(InvestigationStage.values[i]),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _principle(InvestigationStage s) {
    switch (s) {
      case InvestigationStage.intake:
        return 'На первом шаге — оценить размер выборки, типы и диапазоны полей. '
            'Грязные данные превращают красивые формулы в ложные доказательства. '
            'Не считайте средние раньше, чем построите паспорт колонок.';
      case InvestigationStage.cleanup:
        return 'Сопротивление среды — шум, дубликаты, аномалии форматов. '
            'Применяйте преобразования с подтверждением: после каждой чистки '
            'сравнивайте распределение «до/после». Если форма изменилась радикально — '
            'вы выбросили сигнал вместе с шумом.';
      case InvestigationStage.analysis:
        return 'Здесь работает арсенал: статистика, графы, криптография. '
            'Выбирайте метод под вопрос, а не наоборот. Дисперсия отвечает на '
            '«насколько разброс?», корреляция Спирмена — на «есть ли монотонная связь?». '
            'Это разные вопросы.';
      case InvestigationStage.suspects:
        return 'Сильная связь ≠ виновность. Учитывайте мотив, доступ и алиби. '
            'Принцип минимального объяснения: если шум объясняет данные так же '
            'хорошо — у вас нет улики.';
      case InvestigationStage.verdict:
        return 'Финальный этап. Подсказок больше нет. Вы должны сформулировать '
            'обвинение одной «уликой-цифрой»: число и интервал доверия, '
            'отделяющие подозреваемого от всех остальных. Ошибка стоит репутации.';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          color: AppColors.neonCyan, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        'МЕНЮ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.neonCyan,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Container(
                width: 1,
                height: 18,
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 28),
              Text(
                '// MENTOR PROTOCOL',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4),
              ),
            ],
          ),
          const SizedBox(height: 18),
          HolographicGlow(
            radius: 320,
            color: AppColors.magenta.withValues(alpha: 0.5),
            child: GlitchText(
              'НАСТАВНИК',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 56,
                letterSpacing: 8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Контекстная теория для аналитика. JUST-IN-TIME GUIDANCE.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.index,
    required this.principle,
  });

  final InvestigationStage stage;
  final int index;
  final String principle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      borderColor: stage.color,
      glow: 12,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.12),
              border: Border.all(color: stage.color),
            ),
            child: Icon(stage.icon, color: stage.color, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stage.code,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: stage.color,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      stage.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(letterSpacing: 1.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  child: AnimatedTextKit(
                    isRepeatingAnimation: false,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        principle,
                        speed: const Duration(milliseconds: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (200 + 80 * index).ms, duration: 480.ms)
        .slideY(
          begin: 0.04,
          end: 0,
          delay: (200 + 80 * index).ms,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

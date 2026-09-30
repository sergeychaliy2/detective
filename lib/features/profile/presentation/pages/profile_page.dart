import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../../../core/widgets/text/glitch_text.dart';
import '../../../main_menu/presentation/widgets/status_bar.dart';
import '../../domain/entities/player_state.dart';
import '../providers/player_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              StatusBar(agent: p.agent, session: 'A-001'),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.go('/menu'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chevron_left,
                                        color: AppColors.neonCyan, size: 20),
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
                            const SizedBox(width: 24),
                            Container(
                              width: 1,
                              height: 18,
                              color: AppColors.neonCyan.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 24),
                            Text(
                              '// AGENT PROFILE',
                              style: theme.textTheme.labelLarge?.copyWith(
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 360.ms),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _IdentityCard(player: p)),
                            const SizedBox(width: 20),
                            Expanded(flex: 6, child: _StatsCard(player: p)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _HistoryPanel(player: p),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.player});
  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('IDENTITY //', style: theme.textTheme.labelMedium),
          const SizedBox(height: 16),
          HolographicGlow(
            radius: 200,
            color: AppColors.neonCyan.withValues(alpha: 0.6),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.neonCyan),
              ),
              child: Center(
                child: Text(
                  player.agent.characters.first,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 44,
                    letterSpacing: 0,
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlitchText(
            player.agent,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 24,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RANK  //  ${player.rank}',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: AppColors.magenta, letterSpacing: 3),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '"Математика не лжёт — лжёт тот, кто не умеет её слушать"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.player});
  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('МЕТРИКИ //', style: theme.textTheme.labelMedium),
              const SizedBox(width: 10),
              Icon(
                Icons.touch_app_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'нажмите, чтобы узнать подробнее',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.6,
            children: [
              _Stat(
                label: 'ОПЫТ',
                value: '${player.xp}',
                color: AppColors.neonCyan,
                icon: Icons.bolt,
                description:
                    'Опыт (XP) — мера глубины ваших аналитических навыков. '
                    'Начисляется за каждое раскрытое дело: чем выше сложность, тем больше XP. '
                    'Если использовали правильный математический метод — бонус +25%. '
                    'Тратится на подсказки (−10 XP) и лайфхаки (−25 XP).',
              ),
              _Stat(
                label: 'РЕПУТАЦИЯ',
                value: '${player.reputation}',
                color: AppColors.magenta,
                icon: Icons.workspace_premium,
                description:
                    'Репутация (0–100) — доверие к вам как к аналитику. '
                    'Растёт за раскрытые дела (+6 за обычное, +25% бонус за верный метод). '
                    'Падает за судебные ошибки (−10) и откаты (−2). '
                    'Влияет на доступность дел повышенного уровня.',
              ),
              _Stat(
                label: 'ДЕЛ РАСКРЫТО',
                value: '${player.solvedCount}',
                color: AppColors.jadeSuccess,
                icon: Icons.verified,
                description:
                    'Количество дел, где вы верно назвали подозреваемого и '
                    'предъявили корректную улику-цифру в пределах допустимого отклонения. '
                    'Это главный показатель компетентности аналитика.',
              ),
              _Stat(
                label: 'СУДЕБНЫЕ ОШИБКИ',
                value: '${player.failedCount}',
                color: AppColors.crimsonError,
                icon: Icons.gavel,
                description:
                    'Провальные расследования: неверно названный подозреваемый '
                    'или улика-цифра за пределами допустимого отклонения. '
                    'Каждая ошибка стоит половины наградного XP дела и −10 репутации. '
                    'Если не в режиме EXAM — можно активировать откат.',
              ),
              _Stat(
                label: 'ТОЧНОСТЬ',
                value: '${player.accuracy}%',
                color: AppColors.hologramBlue,
                icon: Icons.center_focus_strong,
                description:
                    'Процент верно закрытых дел от всех завершённых расследований. '
                    '100% означает, что ни одного обвинения не было предъявлено '
                    'ошибочно. Главный показатель при отборе в дела уровня EXAM.',
              ),
              _Stat(
                label: 'ОТКАТЫ',
                value: '${player.rollbackCount}',
                color: AppColors.amberWarning,
                icon: Icons.history,
                description:
                    'Сколько раз вы активировали TIME MACHINE — возврат '
                    'к предыдущему этапу расследования. '
                    'Каждый откат стоит 30 XP и 2 единицы репутации. '
                    'В режиме EXAM откаты недоступны.',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms, duration: 500.ms);
  }
}

class _Stat extends StatefulWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.description,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String description;

  @override
  State<_Stat> createState() => _StatState();
}

class _StatState extends State<_Stat> {
  bool _hover = false;

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.voidBlack.withValues(alpha: 0.75),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.panelBg,
              border: Border.all(color: widget.color.withValues(alpha: 0.8), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.color, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            color: widget.color,
                            letterSpacing: 3,
                          ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: widget.color.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  widget.description,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.65,
                      ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          border: Border.all(
                              color: widget.color.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          'ПОНЯТНО',
                          style:
                              Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                    color: widget.color,
                                    letterSpacing: 2.5,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _showInfo(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hover ? 0.12 : 0.06),
            border: Border(left: BorderSide(color: widget.color, width: 3)),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 10,
                          color: AppColors.textMuted
                              .withValues(alpha: _hover ? 0.9 : 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: widget.color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.player});
  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy-MM-dd  HH:mm');

    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CASE LOG  //  ${player.history.length} ENTRIES',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              Text('последние сверху', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (player.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'ПОКА НЕТ ЗАКРЫТЫХ ДЕЛ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 3,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < player.history.length; i++)
              _HistoryRow(entry: player.history[i], fmt: fmt, index: i),
        ],
      ),
    ).animate().fadeIn(delay: 260.ms, duration: 500.ms);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.fmt,
    required this.index,
  });

  final CaseHistoryEntry entry;
  final DateFormat fmt;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (entry.outcome) {
      CaseOutcome.solved => AppColors.jadeSuccess,
      CaseOutcome.failed => AppColors.crimsonError,
      CaseOutcome.rolledBack => AppColors.magenta,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              entry.caseCode,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.caseTitle,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 220,
            child: Text(
              entry.outcome.label,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '${entry.xpDelta >= 0 ? '+' : ''}${entry.xpDelta} XP',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              fmt.format(entry.timestamp),
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (40 * index).ms, duration: 320.ms);
  }
}

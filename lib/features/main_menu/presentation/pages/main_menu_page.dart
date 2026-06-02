import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../../../core/widgets/text/glitch_text.dart';
import '../../../profile/presentation/providers/player_provider.dart';
import '../widgets/menu_button.dart';
import '../widgets/status_bar.dart';

class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final player = ref.watch(playerProvider);

    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              const StatusBar(agent: 'KASHIRINA.K', session: 'A-001'),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '// SHADOW OF NUMBER',
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(letterSpacing: 4),
                                ).animate().fadeIn(duration: 700.ms),
                                const SizedBox(height: 12),
                                HolographicGlow(
                                  radius: 360,
                                  child: GlitchText(
                                    'ТЕНЬ\nЧИСЛА',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          fontSize: 88,
                                          height: 1.0,
                                          letterSpacing: 10,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 440),
                                  child: Text(
                                    'Преврати сухую статистику в неопровержимое доказательство. Веди нелинейное следствие, применяй математику как единственный инструмент истины.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.7,
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 600.ms, duration: 700.ms),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    _Stat(
                                      label: 'EXPERIENCE',
                                      value: '${player.xp}',
                                      color: AppColors.neonCyan,
                                    ),
                                    const SizedBox(width: 28),
                                    _Stat(
                                      label: 'CASES SOLVED',
                                      value: '${player.solvedCount}',
                                      color: AppColors.jadeSuccess,
                                    ),
                                    const SizedBox(width: 28),
                                    _Stat(
                                      label: 'RANK',
                                      value: player.rank,
                                      color: AppColors.magenta,
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(delay: 800.ms, duration: 700.ms),
                              ],
                            ),
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            flex: 5,
                            child: NeonPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 20,
                              ),
                              child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 6, 24, 16),
                                    child: Text(
                                      'OPERATIONS // выберите действие',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ),
                                  MenuButton(
                                    index: 0,
                                    code: 'OP/01',
                                    title: 'НОВОЕ РАССЛЕДОВАНИЕ',
                                    subtitle:
                                        'Выбрать дело и начать слежение за уликами',
                                    icon: Icons.search,
                                    accent: AppColors.neonCyan,
                                    onTap: () => context.go('/cases'),
                                  ),
                                  MenuButton(
                                    index: 1,
                                    code: 'OP/02',
                                    title: 'ПРОДОЛЖИТЬ',
                                    subtitle: player.lastCaseId == null
                                        ? 'Активного расследования пока нет'
                                        : 'Вернуться к активному расследованию',
                                    icon: Icons.play_arrow_rounded,
                                    accent: AppColors.electricBlue,
                                    enabled: player.lastCaseId != null,
                                    onTap: () {
                                      final id = player.lastCaseId;
                                      if (id != null) context.go('/case/$id');
                                    },
                                  ),
                                  MenuButton(
                                    index: 2,
                                    code: 'OP/03',
                                    title: 'АРХИВ ДЕЛ',
                                    subtitle:
                                        'История закрытых и провальных операций',
                                    icon: Icons.folder_open,
                                    accent: AppColors.violet,
                                    onTap: () => context.go('/cases'),
                                  ),
                                  MenuButton(
                                    index: 3,
                                    code: 'OP/04',
                                    title: 'НАСТАВНИК',
                                    subtitle:
                                        'Теория и подсказки в контексте дела',
                                    icon: Icons.psychology_alt,
                                    accent: AppColors.magenta,
                                    onTap: () => context.go('/mentor'),
                                  ),
                                  MenuButton(
                                    index: 4,
                                    code: 'OP/05',
                                    title: 'ПРОФИЛЬ АГЕНТА',
                                    subtitle:
                                        'Цифровой паспорт навыков и репутации',
                                    icon: Icons.account_circle_outlined,
                                    accent: AppColors.amberWarning,
                                    onTap: () => context.go('/profile'),
                                  ),
                                ],
                              ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
                child: Row(
                  children: [
                    Text(
                      'BUILD 0.1.0  //  MENTOR PROTOCOL v3  //  ENCRYPTED CHANNEL',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(letterSpacing: 3),
                    ),
                    const Spacer(),
                    Text(
                      '"Доказательства собраны. Цифры не оставили шанса."',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

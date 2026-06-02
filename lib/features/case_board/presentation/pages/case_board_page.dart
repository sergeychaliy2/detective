import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../main_menu/presentation/widgets/status_bar.dart';
import '../providers/case_board_providers.dart';
import '../widgets/case_card.dart';
import '../widgets/case_detail_panel.dart';
import '../widgets/filter_bar.dart';

class CaseBoardPage extends ConsumerWidget {
  const CaseBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(filteredCasesProvider);
    final selected = ref.watch(selectedCaseProvider);

    return Scaffold(
      body: HudBackground(
        showParticles: true,
        child: SafeArea(
          child: Column(
            children: [
              const StatusBar(agent: 'KASHIRINA.K', session: 'A-001'),
              _Header(
                onBack: () => context.go('/menu'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: async.when(
                          loading: () => const _LoadingGrid(),
                          error: (e, _) => Center(
                            child: Text(
                              'ОШИБКА ЗАГРУЗКИ КАРТОТЕКИ\n$e',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.crimsonError,
                              ),
                            ),
                          ),
                          data: (cases) {
                            if (cases.isEmpty) {
                              return Center(
                                child: Text(
                                  'НЕТ ДЕЛ ПО ВЫБРАННОМУ ФИЛЬТРУ',
                                  style: theme.textTheme.labelMedium,
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.only(top: 4),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 340,
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 18,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: cases.length,
                              itemBuilder: (context, i) {
                                final c = cases[i];
                                return CaseCard(
                                  caseInfo: c,
                                  selected: selected?.id == c.id,
                                  index: i,
                                  onTap: () => ref
                                      .read(selectedCaseIdProvider.notifier)
                                      .state = c.id,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: CaseDetailPanel(
                          caseInfo: selected,
                          onStart: selected == null
                              ? null
                              : () => context.go('/case/${selected.id}'),
                        ),
                      ),
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
                        'НАЗАД',
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
                '// CASE BOARD',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.05, end: 0, duration: 400.ms),
          const SizedBox(height: 12),
          Text(
            'ОПЕРАТИВНАЯ КАРТОТЕКА',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 36,
              letterSpacing: 4,
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 500.ms),
          const SizedBox(height: 6),
          Text(
            'Выберите дело и начните расследование',
            style: theme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 20),
          const FilterBar(),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.panelBg,
        highlightColor: AppColors.neonCyan.withValues(alpha: 0.15),
        period: AppMetrics.cinematic,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBg,
            border: Border.all(color: AppColors.panelBorder),
          ),
        ),
      ),
    );
  }
}

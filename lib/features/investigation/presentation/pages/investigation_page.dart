import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../main_menu/presentation/widgets/status_bar.dart';
import '../../../profile/domain/entities/player_state.dart';
import '../../domain/entities/investigation_stage.dart';
import '../../domain/entities/investigation_state.dart';
import '../providers/investigation_provider.dart';
import '../widgets/investigation_header.dart';
import '../widgets/overlays/outcome_overlay.dart';
import '../widgets/overlays/verdict_overlay.dart';
import '../widgets/protocol_panel.dart';
import '../widgets/side_rail.dart';
import '../widgets/tabs/analysis_tab.dart';
import '../widgets/tabs/data_tab.dart';
import '../widgets/tabs/mentor_tab.dart';
import '../widgets/tabs/network_tab.dart';
import '../widgets/tabs/suspects_tab.dart';

class InvestigationPage extends ConsumerWidget {
  const InvestigationPage({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(investigationProvider(caseId));
    final notifier = ref.read(investigationProvider(caseId).notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          HudBackground(
            showParticles: true,
            child: SafeArea(
              child: state == null
                  ? Center(
                      child: Text(
                        'ДЕЛО НЕ НАЙДЕНО',
                        style: theme.textTheme.titleLarge,
                      ),
                    )
                  : Column(
                      children: [
                        const StatusBar(
                            agent: 'KASHIRINA.K', session: 'A-001'),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 22, 24, 12),
                          child: InvestigationHeader(
                            state: state,
                            onAdvance: notifier.advanceStage,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              SideRail(
                                active: state.activeTab,
                                onSelect: notifier.setTab,
                                onRollback: () =>
                                    _confirmRollback(context, notifier),
                                examMode: state.isExam,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 12, 24, 24),
                                  child: AnimatedSwitcher(
                                    duration: AppMetrics.normal,
                                    switchInCurve: AppMetrics.easeOutExpo,
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.02),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    ),
                                    child: KeyedSubtree(
                                      key: ValueKey(state.activeTab),
                                      child: _tabContent(state, notifier),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 280,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      0, 12, 24, 24),
                                  child: ProtocolPanel(entries: state.protocol),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Footer(stage: state.currentStage),
                      ],
                    ),
            ),
          ),
          if (state != null && state.verdictRequested && state.outcome == null)
            VerdictOverlay(
              caseInfo: state.caseInfo,
              suspects: state.suspects,
              evidence: state.evidence,
              evidenceLinks: state.evidenceLinks,
              methodResults: state.methodResults,
              onCancel: notifier.cancelVerdict,
              onSubmit: (suspectId, value) {
                notifier.submitVerdict(suspectId: suspectId, value: value);
              },
            ),
          if (state != null && state.outcome != null)
            OutcomeOverlay(
              state: state,
              xpDelta: state.outcome == CaseOutcome.solved
                  ? (state.methodResults
                              .containsKey(state.caseInfo.solutionMethod)
                          ? (state.caseInfo.rewardXp * 1.25).round()
                          : state.caseInfo.rewardXp)
                  : -(state.caseInfo.rewardXp ~/ 2),
              onBackToMenu: () => context.go('/menu'),
              onRollback: state.outcome == CaseOutcome.failed && !state.isExam
                  ? () => notifier.rollback()
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _tabContent(
    InvestigationState state,
    InvestigationController notifier,
  ) {
    switch (state.activeTab) {
      case WorkspaceTab.data:
        return DataTab(
          state: state,
          onSelect: notifier.touchEvidence,
          onToggleFlag: notifier.toggleFlag,
          onToggleSort: notifier.toggleSort,
          onApplyFilter: (min, max) =>
              notifier.setValueFilter(min: min, max: max),
          onClearFilter: notifier.clearValueFilter,
          onToggleDerived: notifier.toggleDerivedColumn,
        );
      case WorkspaceTab.analysis:
        return AnalysisTab(
          state: state,
          onApplyMethod: notifier.applyMethod,
          onSelectMethod: notifier.selectMethod,
          onRemoveMethod: notifier.removeMethod,
          onSelectEvidence: notifier.touchEvidence,
        );
      case WorkspaceTab.network:
        return NetworkTab(
          state: state,
          onSetPath: ({String? from, String? to}) =>
              notifier.setPathEndpoints(from: from, to: to),
          onClearPath: notifier.clearPath,
        );
      case WorkspaceTab.suspects:
        return SuspectsTab(
          state: state,
          onLink: notifier.linkSelectedEvidenceTo,
        );
      case WorkspaceTab.mentor:
        return MentorTab(
          state: state,
          onHint: notifier.requestHint,
          onLifehack: notifier.requestLifehack,
        );
    }
  }

  Future<void> _confirmRollback(
      BuildContext context, InvestigationController notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.voidBlack.withValues(alpha: 0.7),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                border: Border.all(color: AppColors.magenta, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.magenta,
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// TIME MACHINE',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: AppColors.magenta,
                          letterSpacing: 4,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'АКТИВИРОВАТЬ ОТКАТ',
                    style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          letterSpacing: 3,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Расследование вернётся на предыдущий этап. Цена ретроспективы: '
                    '−30 XP и −2 единицы репутации. Система не даст ответ, но покажет '
                    'этап, где вы свернули не туда.',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.panelBorder),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('ОТМЕНА'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.magenta.withValues(alpha: 0.18),
                            foregroundColor: AppColors.magenta,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                              side: const BorderSide(
                                  color: AppColors.magenta, width: 1),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('ОТКАТИТЬ'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirmed == true) notifier.rollback();
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.stage});
  final InvestigationStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: stage.color),
          const SizedBox(width: 10),
          Text(
            'CURRENT STAGE  //  ${stage.code}.  ${stage.title}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: stage.color,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              stage.description,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '"От гипотезы до приговора"',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

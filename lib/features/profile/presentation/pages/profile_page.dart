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
              '"Сильный аналитик ценится не количеством, '
              'а тем, скольких он защитил от шумовых выводов."',
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
          Text('METRICS //', style: theme.textTheme.labelMedium),
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
                label: 'EXPERIENCE',
                value: '${player.xp}',
                color: AppColors.neonCyan,
                icon: Icons.bolt,
              ),
              _Stat(
                label: 'REPUTATION',
                value: '${player.reputation}',
                color: AppColors.magenta,
                icon: Icons.workspace_premium,
              ),
              _Stat(
                label: 'CASES SOLVED',
                value: '${player.solvedCount}',
                color: AppColors.jadeSuccess,
                icon: Icons.verified,
              ),
              _Stat(
                label: 'JUDICIAL ERRORS',
                value: '${player.failedCount}',
                color: AppColors.crimsonError,
                icon: Icons.gavel,
              ),
              _Stat(
                label: 'ACCURACY',
                value: '${player.accuracy}%',
                color: AppColors.hologramBlue,
                icon: Icons.center_focus_strong,
              ),
              _Stat(
                label: 'ROLLBACKS',
                value: '${player.rollbackCount}',
                color: AppColors.amberWarning,
                icon: Icons.history,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms, duration: 500.ms);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
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

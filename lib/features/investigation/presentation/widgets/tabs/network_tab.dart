import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../../domain/entities/suspect_entity.dart';
import '../../../domain/services/graph_metrics.dart';

/// Вкладка "NETWORK" — граф подозреваемых с настоящими метриками:
/// размер узла = degree, толщина связи = вес ребра, можно искать
/// shortest-path между парой узлов.
class NetworkTab extends StatelessWidget {
  const NetworkTab({
    super.key,
    required this.state,
    required this.onSetPath,
    required this.onClearPath,
  });

  final InvestigationState state;
  final void Function({String? from, String? to}) onSetPath;
  final VoidCallback onClearPath;

  String? get _highlightSuspectId {
    final id = state.selectedEvidenceId;
    if (id == null) return null;
    for (final e in state.evidence) {
      if (e.id == id) return e.suspectId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = _highlightSuspectId;
    final graph = SuspectGraph.build(
      suspects: state.suspects,
      evidence: state.evidence,
      evidenceLinks: state.evidenceLinks,
    );
    final degree = graph.degree();
    final betweenness = graph.betweenness();

    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NETWORK GRAPH',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              Text(
                '${state.suspects.length} NODES  //  '
                '${state.evidenceLinks.length} LINKS  //  '
                '${graph.weights.values.fold<int>(0, (a, b) => a + b)} EDGES',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PathBar(
            suspects: state.suspects,
            from: state.pathFrom,
            to: state.pathTo,
            shortestPath: state.shortestPath,
            onSetFrom: (v) => onSetPath(from: v),
            onSetTo: (v) => onSetPath(to: v),
            onClear: onClearPath,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Graph(
                    suspects: state.suspects,
                    highlightSuspectId: highlight,
                    degree: degree,
                    edgeWeights: graph.weights,
                    shortestPath: state.shortestPath,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: _CentralityPanel(
                    suspects: state.suspects,
                    degree: degree,
                    betweenness: betweenness,
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

class _PathBar extends StatelessWidget {
  const _PathBar({
    required this.suspects,
    required this.from,
    required this.to,
    required this.shortestPath,
    required this.onSetFrom,
    required this.onSetTo,
    required this.onClear,
  });

  final List<SuspectEntity> suspects;
  final String? from;
  final String? to;
  final List<String>? shortestPath;
  final ValueChanged<String?> onSetFrom;
  final ValueChanged<String?> onSetTo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showResult = from != null && to != null;
    String resultText;
    Color resultColor;
    if (!showResult) {
      resultText = 'Выберите FROM и TO, чтобы найти кратчайший путь.';
      resultColor = AppColors.textMuted;
    } else if (shortestPath == null) {
      resultText = 'Между $from и $to нет связи через имеющиеся улики.';
      resultColor = AppColors.crimsonError;
    } else {
      resultText =
          'Кратчайший путь: ${shortestPath!.join(' → ')}  (длина ${shortestPath!.length - 1})';
      resultColor = AppColors.magenta;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Text('FROM',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(width: 8),
          _SuspectDropdown(
            suspects: suspects,
            value: from,
            onChanged: onSetFrom,
          ),
          const SizedBox(width: 14),
          const Icon(Icons.arrow_forward,
              size: 14, color: AppColors.neonCyan),
          const SizedBox(width: 14),
          Text('TO',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(width: 8),
          _SuspectDropdown(
            suspects: suspects,
            value: to,
            onChanged: onSetTo,
          ),
          const SizedBox(width: 14),
          if (from != null || to != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonError.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.crimsonError),
                  ),
                  child: Text(
                    'СБРОС',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.crimsonError,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 14),
          Container(
            width: 1,
            height: 22,
            color: AppColors.neonCyan.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              resultText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: resultColor,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuspectDropdown extends StatelessWidget {
  const _SuspectDropdown({
    required this.suspects,
    required this.value,
    required this.onChanged,
  });

  final List<SuspectEntity> suspects;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          '— выбрать —',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: AppColors.textMuted, letterSpacing: 1.5),
        ),
        items: [
          for (final s in suspects)
            DropdownMenuItem(
              value: s.id,
              child: Text(
                '${s.id}  ·  ${s.codename}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
        onChanged: onChanged,
        dropdownColor: AppColors.deepNavy,
        iconEnabledColor: AppColors.neonCyan,
        focusColor: Colors.transparent,
      ),
    );
  }
}

class _CentralityPanel extends StatelessWidget {
  const _CentralityPanel({
    required this.suspects,
    required this.degree,
    required this.betweenness,
  });

  final List<SuspectEntity> suspects;
  final Map<String, int> degree;
  final Map<String, double> betweenness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDeg = (degree.values.fold<int>(0, (a, b) => b > a ? b : a))
        .clamp(1, 9999);
    final maxBw = (betweenness.values.fold<double>(0, (a, b) => b > a ? b : a))
        .clamp(0.001, 9999);

    return NeonPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CENTRALITIES',
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
          ),
          const SizedBox(height: 10),
          Text(
            'degree (степень)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.neonCyan,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          for (final s in suspects)
            _Bar(
              label: s.codename,
              value: '${degree[s.id] ?? 0}',
              fraction: (degree[s.id] ?? 0) / maxDeg,
              color: AppColors.neonCyan,
            ),
          const SizedBox(height: 12),
          Text(
            'betweenness (промежуточность)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.violet,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          for (final s in suspects)
            _Bar(
              label: s.codename,
              value: (betweenness[s.id] ?? 0).toStringAsFixed(2),
              fraction: (betweenness[s.id] ?? 0) / maxBw,
              color: AppColors.violet,
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth * fraction.clamp(0, 1)).clamp(2, c.maxWidth);
                return Stack(
                  children: [
                    Container(
                      height: 6,
                      color: AppColors.panelBorder.withValues(alpha: 0.4),
                    ),
                    Container(
                      height: 6,
                      width: w.toDouble(),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.7),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Graph extends StatefulWidget {
  const _Graph({
    required this.suspects,
    required this.highlightSuspectId,
    required this.degree,
    required this.edgeWeights,
    required this.shortestPath,
  });

  final List<SuspectEntity> suspects;
  final String? highlightSuspectId;
  final Map<String, int> degree;
  final Map<String, int> edgeWeights;
  final List<String>? shortestPath;

  @override
  State<_Graph> createState() => _GraphState();
}

class _GraphState extends State<_Graph> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxDeg = widget.degree.values
        .fold<int>(0, (a, b) => b > a ? b : a)
        .clamp(1, 9999);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _GraphPainter(
            suspects: widget.suspects,
            t: _c.value,
            highlightSuspectId: widget.highlightSuspectId,
            edgeWeights: widget.edgeWeights,
            shortestPath: widget.shortestPath,
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
              final radius = min(c.maxWidth, c.maxHeight) / 2 - 80;
              final n = widget.suspects.length;
              return Stack(
                children: [
                  for (var i = 0; i < n; i++)
                    Positioned(
                      left: center.dx +
                          radius * cos(2 * pi * i / n - pi / 2) -
                          54,
                      top: center.dy +
                          radius * sin(2 * pi * i / n - pi / 2) -
                          36,
                      child: _NodeChip(
                        suspect: widget.suspects[i],
                        index: i,
                        highlighted: widget.highlightSuspectId ==
                            widget.suspects[i].id,
                        onPath: widget.shortestPath?.contains(
                                widget.suspects[i].id) ==
                            true,
                        degree: widget.degree[widget.suspects[i].id] ?? 0,
                        maxDegree: maxDeg,
                      ),
                    ),
                  Positioned(
                    left: center.dx - 38,
                    top: center.dy - 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.magenta.withValues(alpha: 0.18),
                        border: Border.all(color: AppColors.magenta),
                      ),
                      child: Text(
                        'CASE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.magenta,
                              letterSpacing: 3,
                            ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                          begin: 0.55,
                          end: 1,
                          duration: 1200.ms,
                        ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _NodeChip extends StatelessWidget {
  const _NodeChip({
    required this.suspect,
    required this.index,
    required this.highlighted,
    required this.onPath,
    required this.degree,
    required this.maxDegree,
  });

  final SuspectEntity suspect;
  final int index;
  final bool highlighted;
  final bool onPath;
  final int degree;
  final int maxDegree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      AppColors.neonCyan,
      AppColors.electricBlue,
      AppColors.violet,
      AppColors.hologramBlue,
      AppColors.amberWarning,
      AppColors.magenta,
    ];
    final base = colors[index % colors.length];
    final color = onPath ? AppColors.magenta : (highlighted ? AppColors.magenta : base);
    final scale = 0.8 + 0.4 * (degree / maxDegree).clamp(0, 1);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.panelBg,
          border: Border.all(
            color: color,
            width: highlighted || onPath ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: highlighted || onPath ? 0.85 : 0.55),
              blurRadius: highlighted || onPath ? 18 : 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suspect.codename,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'deg $degree',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      )
          .animate(target: highlighted || onPath ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 320.ms,
          ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.suspects,
    required this.t,
    required this.highlightSuspectId,
    required this.edgeWeights,
    required this.shortestPath,
  });

  final List<SuspectEntity> suspects;
  final double t;
  final String? highlightSuspectId;
  final Map<String, int> edgeWeights;
  final List<String>? shortestPath;

  static String _key(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  bool _onPath(String a, String b) {
    final p = shortestPath;
    if (p == null || p.length < 2) return false;
    for (var i = 0; i < p.length - 1; i++) {
      if ((p[i] == a && p[i + 1] == b) || (p[i] == b && p[i + 1] == a)) {
        return true;
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = suspects.length;
    if (n == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 80;
    final points = List.generate(
      n,
      (i) => Offset(
        center.dx + radius * cos(2 * pi * i / n - pi / 2),
        center.dy + radius * sin(2 * pi * i / n - pi / 2),
      ),
    );

    // Линии каждый-каждый, толщина = вес ребра.
    final linePaint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final w = edgeWeights[_key(suspects[i].id, suspects[j].id)] ?? 0;
        if (w == 0) continue;
        final onPath = _onPath(suspects[i].id, suspects[j].id);
        linePaint
          ..color = onPath
              ? AppColors.magenta.withValues(alpha: 0.95)
              : AppColors.neonCyan.withValues(alpha: 0.18 + (w * 0.12).clamp(0, 0.55))
          ..strokeWidth = onPath ? 3 : (0.8 + w * 0.4).clamp(0.8, 3.5);
        canvas.drawLine(points[i], points[j], linePaint);
      }
    }

    // Радиальные линии к центру (для узлов с подсветкой).
    final radial = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 0; i < n; i++) {
      final highlighted = suspects[i].id == highlightSuspectId;
      final intensity = 0.45 + 0.45 * sin(t * 2 * pi + i);
      radial.color = (highlighted ? AppColors.magenta : AppColors.neonCyan)
          .withValues(alpha: 0.10 + intensity * 0.18);
      canvas.drawLine(points[i], center, radial);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.t != t ||
      old.suspects != suspects ||
      old.highlightSuspectId != highlightSuspectId ||
      old.edgeWeights != edgeWeights ||
      old.shortestPath != shortestPath;
}

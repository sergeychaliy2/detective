import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/analysis_result.dart';

/// Bar-chart распределения первых цифр с наложенной эталонной кривой
/// Закона Бенфорда. Бары — наблюдаемая доля (ФАКТ), линия с точками —
/// теоретический идеал. Резкое расхождение = подделка.
class BenfordChart extends StatelessWidget {
  const BenfordChart({
    super.key,
    required this.distribution,
    required this.barColor,
  });

  final BenfordDistribution distribution;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendChip(color: barColor, label: 'ФАКТ', filled: true),
            const SizedBox(width: 16),
            const _LegendChip(
              color: AppColors.jadeSuccess,
              label: 'ИДЕАЛ — ЗАКОН БЕНФОРДА',
              filled: false,
            ),
            if (distribution.hasSuspect) ...[
              const SizedBox(width: 16),
              const _LegendChip(
                color: AppColors.crimsonError,
                label: 'ИЗБЫТОК НАД НОРМОЙ',
                filled: true,
              ),
            ],
            const Spacer(),
            Text(
              'first digit · n = ${distribution.n}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 152,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMetrics.slow,
            curve: AppMetrics.easeOutExpo,
            builder: (context, t, _) => CustomPaint(
              size: Size.infinite,
              painter: _BenfordPainter(
                observed: distribution.observed,
                expected: distribution.expected,
                suspect: distribution.suspect,
                barColor: barColor,
                t: t,
                labelStyle: theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.filled,
  });

  final Color color;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        filled
            ? Container(width: 12, height: 12, color: color)
            : SizedBox(
                width: 14,
                height: 12,
                child: Center(
                  child: Container(width: 14, height: 2.5, color: color),
                ),
              ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 1.5,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

class _BenfordPainter extends CustomPainter {
  _BenfordPainter({
    required this.observed,
    required this.expected,
    required this.suspect,
    required this.barColor,
    required this.t,
    required this.labelStyle,
  });

  final List<double> observed;
  final List<double> expected;
  final List<bool> suspect;
  final Color barColor;
  final double t;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 18.0;
    const topPad = 6.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;
    if (chartW <= 0 || chartH <= 0) return;
    final originY = topPad + chartH;

    var maxFreq = 0.0;
    for (var i = 0; i < 9; i++) {
      if (observed[i] > maxFreq) maxFreq = observed[i];
      if (expected[i] > maxFreq) maxFreq = expected[i];
    }
    maxFreq = (maxFreq * 1.2).clamp(0.1, 1.0);

    // Сетка + проценты по оси Y.
    final gridPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;
    for (final frac in const [0.0, 0.5, 1.0]) {
      final y = originY - frac * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _label(
        canvas,
        '${(maxFreq * frac * 100).round()}%',
        Offset(leftPad - 6, y),
        color: AppColors.textMuted,
        anchorRight: true,
        vCenter: true,
      );
    }

    final slotW = chartW / 9;
    final barW = slotW * 0.46;

    // Бары — наблюдаемые доли. У «избыточной» цифры часть выше эталонной
    // кривой (зелёные точки) окрашена в crimson — это буквально лишние,
    // несуществующие записи: то, что метод считает выбросами.
    for (var i = 0; i < 9; i++) {
      final cx = leftPad + slotW * (i + 0.5);
      final left = cx - barW / 2;
      final h = (observed[i] / maxFreq) * chartH * t;
      final top = originY - h;
      final isSuspect = suspect[i];
      // Уровень эталона = шов между «нормой» и «избытком».
      final hExp = (expected[i] / maxFreq) * chartH * t;
      final splitH = isSuspect && hExp < h ? hExp : h;

      if (h > 0.5) {
        // Базовая часть (в пределах нормы) — цвет метода.
        final baseRect = Rect.fromLTWH(left, originY - splitH, barW, splitH);
        canvas.drawRect(baseRect, _barFill(baseRect, barColor));

        if (isSuspect && hExp < h) {
          // Избыток над эталоном — crimson.
          final surplusRect = Rect.fromLTWH(left, top, barW, h - splitH);
          canvas.drawRect(surplusRect, _barFill(surplusRect, AppColors.crimsonError));
          canvas.drawRect(
            Rect.fromLTWH(left, top, barW, 2),
            Paint()..color = AppColors.crimsonError,
          );
          // Обводка всего столбца — акцент на аномалии.
          canvas.drawRect(
            Rect.fromLTWH(left, top, barW, h),
            Paint()
              ..color = AppColors.crimsonError.withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTWH(left, top, barW, 2),
            Paint()..color = barColor,
          );
        }
      }
      _label(
        canvas,
        '${i + 1}',
        Offset(cx, originY + 4),
        color: isSuspect ? AppColors.crimsonError : barColor,
        center: true,
      );
    }

    // Эталонная кривая Бенфорда (точки + линия).
    final pts = <Offset>[
      for (var i = 0; i < 9; i++)
        Offset(
          leftPad + slotW * (i + 0.5),
          originY - (expected[i] / maxFreq) * chartH * t,
        ),
    ];
    final glow = Paint()
      ..color = AppColors.jadeSuccess.withValues(alpha: 0.25 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..color = AppColors.jadeSuccess.withValues(alpha: 0.95 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.jadeSuccess.withValues(alpha: t);
    final dotCore = Paint()..color = AppColors.voidBlack;
    for (final p in pts) {
      canvas.drawCircle(p, 3.2, dot);
      canvas.drawCircle(p, 1.3, dotCore);
    }
  }

  Paint _barFill(Rect rect, Color color) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color.withValues(alpha: 0.30),
        color.withValues(alpha: 0.85),
      ],
    ).createShader(rect);

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required Color color,
    bool anchorRight = false,
    bool vCenter = false,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(
          color: color,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    var dy = at.dy;
    if (center) dx -= tp.width / 2;
    if (anchorRight) dx -= tp.width;
    if (vCenter) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_BenfordPainter old) =>
      old.t != t ||
      old.barColor != barColor ||
      old.observed != observed ||
      old.expected != expected ||
      old.suspect != suspect;
}

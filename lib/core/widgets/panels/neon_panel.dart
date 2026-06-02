import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Стеклянная панель с неоновой обводкой и угловыми засечками.
/// Базовый блок HUD-интерфейса.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor = AppColors.neonCyan,
    this.glow = 12,
    this.cornerNotch = true,
    this.background = AppColors.panelBg,
    this.borderRadius = AppMetrics.radiusMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final double glow;
  final bool cornerNotch;
  final Color background;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PanelPainter(
        borderColor: borderColor,
        glow: glow,
        background: background,
        radius: borderRadius,
        notch: cornerNotch,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({
    required this.borderColor,
    required this.glow,
    required this.background,
    required this.radius,
    required this.notch,
  });

  final Color borderColor;
  final double glow;
  final Color background;
  final double radius;
  final bool notch;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Заливка
    final fill = Paint()..color = background;
    canvas.drawRRect(rrect, fill);

    // Тонкая внешняя обводка с glow
    final glowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glow);
    canvas.drawRRect(rrect, glowPaint);

    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, stroke);

    if (!notch) return;

    // Угловые засечки — характерная деталь HUD.
    const notchLen = 14.0;
    final notchPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(notchLen, 0), notchPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, notchLen), notchPaint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - notchLen, 0), Offset(size.width, 0), notchPaint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, notchLen), notchPaint);
    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - notchLen), Offset(0, size.height), notchPaint);
    canvas.drawLine(
        Offset(0, size.height), Offset(notchLen, size.height), notchPaint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - notchLen, size.height),
        Offset(size.width, size.height), notchPaint);
    canvas.drawLine(Offset(size.width, size.height - notchLen),
        Offset(size.width, size.height), notchPaint);
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) =>
      old.borderColor != borderColor ||
      old.glow != glow ||
      old.background != background ||
      old.notch != notch;
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Тёмный фон с тонкой неоновой сеткой и точечным шумом. Используется
/// как подложка под HUD. Сетка медленно дрейфует — даёт ощущение живой
/// "цифровой комнаты".
class GridBackground extends StatefulWidget {
  const GridBackground({
    super.key,
    this.child,
    this.cellSize = 56,
    this.lineColor = const Color(0x1A49E0FF),
    this.accentColor = const Color(0x4D49E0FF),
    this.driftSpeed = 0.04,
  });

  final Widget? child;
  final double cellSize;
  final Color lineColor;
  final Color accentColor;
  final double driftSpeed;

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GridPainter(
              progress: _controller.value,
              cellSize: widget.cellSize,
              lineColor: widget.lineColor,
              accentColor: widget.accentColor,
              speed: widget.driftSpeed,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.progress,
    required this.cellSize,
    required this.lineColor,
    required this.accentColor,
    required this.speed,
  });

  final double progress;
  final double cellSize;
  final Color lineColor;
  final Color accentColor;
  final double speed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.6;

    final offsetX = (progress * cellSize * speed * 100) % cellSize;
    final offsetY = (progress * cellSize * speed * 70) % cellSize;

    for (double x = -offsetX; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -offsetY; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Акцентные узлы — редкая сетка крупных точек с glow.
    final accentPaint = Paint()
      ..color = accentColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final step = cellSize * 4;
    for (double x = -offsetX; x < size.width; x += step) {
      for (double y = -offsetY; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.progress != progress ||
      old.cellSize != cellSize ||
      old.lineColor != lineColor;
}

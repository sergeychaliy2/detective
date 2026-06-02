import 'package:flutter/material.dart';

/// Накладка-сканлайн: тонкая горизонтальная полоса медленно проезжает
/// сверху вниз, имитируя CRT/HUD-экран. Не перехватывает ввод.
class ScanlineOverlay extends StatefulWidget {
  const ScanlineOverlay({
    super.key,
    this.color = const Color(0x1A49E0FF),
    this.thickness = 60,
    this.duration = const Duration(seconds: 6),
  });

  final Color color;
  final double thickness;
  final Duration duration;

  @override
  State<ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<ScanlineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final y = constraints.maxHeight * _controller.value -
                  widget.thickness / 2;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    height: widget.thickness,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.color.withValues(alpha: 0),
                            widget.color,
                            widget.color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Радиальная пульсация — голографическая аура. Подкладывается под
/// логотипы / ключевые элементы для ощущения "света изнутри".
class HolographicGlow extends StatefulWidget {
  const HolographicGlow({
    super.key,
    required this.child,
    this.color = const Color(0x8849E0FF),
    this.radius = 220,
    this.duration = const Duration(seconds: 4),
  });

  final Widget child;
  final Color color;
  final double radius;
  final Duration duration;

  @override
  State<HolographicGlow> createState() => _HolographicGlowState();
}

class _HolographicGlowState extends State<HolographicGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                width: widget.radius * (1 + t * 0.15),
                height: widget.radius * (1 + t * 0.15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.5 + t * 0.3),
                      widget.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

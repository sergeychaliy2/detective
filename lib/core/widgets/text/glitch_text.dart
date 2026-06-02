import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Глитч-текст: RGB-сдвиг + случайные подёргивания. Дешёвый эффект —
/// два дополнительных слоя текста + микро-смещение.
class GlitchText extends StatefulWidget {
  const GlitchText(
    this.text, {
    super.key,
    this.style,
    this.intensity = 1.2,
    this.cyan = AppColors.neonCyan,
    this.magenta = AppColors.magenta,
  });

  final String text;
  final TextStyle? style;
  final double intensity;
  final Color cyan;
  final Color magenta;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.displayLarge;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Случайный "выстрел" глитча 2-3 раза за цикл.
        final isGlitching = (t * 5).floor() % 2 == 0 && _rng.nextDouble() < 0.55;
        final dx = isGlitching ? (_rng.nextDouble() - 0.5) * widget.intensity * 6 : 0.0;
        final dy = isGlitching ? (_rng.nextDouble() - 0.5) * widget.intensity * 2 : 0.0;

        return SizedBox(
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(-dx, -dy),
                child: Text(
                  widget.text,
                  style: style?.copyWith(
                    color: widget.magenta.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx, dy),
                child: Text(
                  widget.text,
                  style: style?.copyWith(
                    color: widget.cyan.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Text(widget.text, style: style),
            ],
          ),
        );
      },
    );
  }
}

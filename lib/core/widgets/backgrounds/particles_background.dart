import 'dart:math';

import 'package:flutter/material.dart';

/// Лёгкие "цифры в воздухе" — медленно дрейфующие частицы цифр и точек
/// для атмосферы цифрового хаоса. Производительный CustomPainter без
/// аллокаций в кадре.
class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({
    super.key,
    this.particleCount = 60,
    this.color = const Color(0x6649E0FF),
    this.accentColor = const Color(0x80FF3DCD),
  });

  final int particleCount;
  final Color color;
  final Color accentColor;

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _particles = List.generate(widget.particleCount, (i) => _spawn(i));
  }

  _Particle _spawn(int seed) {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      speed: 0.02 + _rng.nextDouble() * 0.05,
      size: 1 + _rng.nextDouble() * 2.5,
      glyph: _rng.nextBool() ? null : '${_rng.nextInt(10)}',
      isAccent: _rng.nextDouble() < 0.18,
      drift: (_rng.nextDouble() - 0.5) * 0.0008,
    );
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
          return CustomPaint(
            painter: _ParticlesPainter(
              particles: _particles,
              t: _controller.value,
              color: widget.color,
              accent: widget.accentColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.glyph,
    required this.isAccent,
    required this.drift,
  });

  final double x;
  final double y;
  final double speed;
  final double size;
  final String? glyph;
  final bool isAccent;
  final double drift;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.particles,
    required this.t,
    required this.color,
    required this.accent,
  });

  final List<_Particle> particles;
  final double t;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final dy = ((p.y + t * p.speed) % 1.0);
      final dx = (p.x + sin(t * 6.28 + p.y * 8) * 0.02 + p.drift * t * 100) % 1.0;
      final offset = Offset(dx * size.width, (1 - dy) * size.height);
      final c = p.isAccent ? accent : color;
      if (p.glyph != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.glyph,
            style: TextStyle(
              color: c,
              fontSize: 10 + p.size * 2,
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, offset);
      } else {
        dotPaint.color = c;
        canvas.drawCircle(offset, p.size, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => old.t != t;
}

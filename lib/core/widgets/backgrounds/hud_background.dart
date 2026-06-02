import 'package:flutter/material.dart';

import 'grid_background.dart';
import 'particles_background.dart';
import 'scanline_overlay.dart';

/// Композитный фон: градиент + сетка + частицы + сканлайн.
/// Используется как корневой фон большинства экранов.
class HudBackground extends StatelessWidget {
  const HudBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showScanline = true,
  });

  final Widget child;
  final bool showParticles;
  final bool showScanline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const GridBackground(),
        if (showParticles) const ParticlesBackground(),
        if (showScanline) const ScanlineOverlay(),
        child,
      ],
    );
  }
}

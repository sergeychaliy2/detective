import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Голографическая кнопка с растущим glow по hover/press и
/// "пробегающей" неоновой линией по нижней грани.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.neonCyan,
    this.accent = AppColors.magenta,
    this.width,
    this.height = 56,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color accent;
  final double? width;
  final double height;
  final bool primary;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  bool _pressed = false;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final glow = _pressed
        ? 24.0
        : _hover
            ? 18.0
            : 8.0;
    final scale = _pressed ? 0.98 : 1.0;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: AppMetrics.fast,
          scale: scale,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppMetrics.normal,
            curve: AppMetrics.easeOutExpo,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.primary
                  ? widget.color.withValues(alpha: _hover ? 0.16 : 0.08)
                  : Colors.transparent,
              border: Border.all(
                color: widget.color.withValues(alpha: enabled ? 1 : 0.3),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _hover ? 0.6 : 0.3),
                  blurRadius: glow,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.color, size: 18),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        widget.label.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: widget.color, letterSpacing: 2.5),
                      ),
                    ],
                  ),
                ),
                // Бегущая линия по нижней грани.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 1.5,
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) {
                      return ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) {
                          final t = _shine.value;
                          return LinearGradient(
                            begin: Alignment(-1 + t * 2.5, 0),
                            end: Alignment(-0.3 + t * 2.5, 0),
                            colors: [
                              widget.accent.withValues(alpha: 0),
                              widget.accent,
                              widget.accent.withValues(alpha: 0),
                            ],
                          ).createShader(rect);
                        },
                        child: Container(color: Colors.white),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

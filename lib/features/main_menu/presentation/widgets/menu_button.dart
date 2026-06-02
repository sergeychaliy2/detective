import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Большая HUD-кнопка пункта меню: код + название + описание,
/// с расширяющимся неоновым подчёркиванием по hover.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.neonCyan,
    this.index = 0,
    this.enabled = true,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final int index;
  final bool enabled;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !widget.enabled;
    final accent = disabled ? AppColors.textMuted : widget.accent;
    final hover = _hover && !disabled;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: AnimatedContainer(
            duration: AppMetrics.normal,
            curve: AppMetrics.easeOutExpo,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: hover ? accent.withValues(alpha: 0.08) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: accent.withValues(alpha: hover ? 1 : 0.35),
                  width: hover ? 4 : 2,
                ),
              ),
            ),
            transform: Matrix4.translationValues(hover ? 8 : 0, 0, 0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    border: Border.all(
                      color: accent.withValues(alpha: hover ? 1 : 0.5),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(widget.icon, color: accent, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.code,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 1,
                            width: hover ? 80 : 32,
                            color: accent.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: hover
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: AppMetrics.normal,
                  opacity: hover ? 1 : 0.3,
                  child: Icon(Icons.chevron_right, color: accent, size: 22),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (120 * widget.index).ms, duration: 500.ms)
              .slideX(
                begin: -0.05,
                end: 0,
                delay: (120 * widget.index).ms,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}
